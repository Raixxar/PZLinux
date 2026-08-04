PZLinux = PZLinux or {}
PZLinux.RaceSchedule = PZLinux.RaceSchedule or {}

local PZLINUX_RACE_SCHEDULE_DATA = "PZLinuxRaceSchedule"
local PZLINUX_RACE_MARKET_VERSION = 2
local PZLINUX_RACE_HOURS = { 8, 10, 12, 14, 16 }
local PZLINUX_RACE_VISIBLE_SLOTS = 5
local PZLINUX_RACE_MAXIMUM_UNREAD_RESULTS = 5
local PZLINUX_RACE_JACKPOT_HOUR = 16
local PZLINUX_RACE_JACKPOT_AMOUNT = 50000
local PZLINUX_RACE_JACKPOT_MAXIMUM_BET = 500
local PZLINUX_RACE_HISTORY_HOURS = 48
local PZLINUX_RACE_PAYMENT_LEDGER_HOURS = 168

local function PZLinuxRaceScheduleGetState()
    local state
    if ModData and ModData.getOrCreate then
        state = ModData.getOrCreate(PZLINUX_RACE_SCHEDULE_DATA)
    else
        PZLinux.RaceSchedule.memoryState = PZLinux.RaceSchedule.memoryState or {}
        state = PZLinux.RaceSchedule.memoryState
    end
    state.races = state.races or {}
    state.tickets = state.tickets or {}
    state.latestResults = state.latestResults or {}
    state.unreadResults = state.unreadResults or {}
    return state
end

local function PZLinuxRaceScheduleIsLeapYear(year)
    return year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
end

local function PZLinuxRaceScheduleNextDate(year, month, day)
    local monthDays = { 31, PZLinuxRaceScheduleIsLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    day = day + 1
    if day > monthDays[month] then
        day = 1
        month = month + 1
        if month > 12 then
            month = 1
            year = year + 1
        end
    end
    return year, month, day
end

function PZLinuxRaceScheduleDayOfWeek(year, month, day)
    local offsets = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
    if month < 3 then year = year - 1 end
    return (year + math.floor(year / 4) - math.floor(year / 100)
        + math.floor(year / 400) + offsets[month] + day) % 7
end

local function PZLinuxRaceScheduleGetClock()
    local gameTime = getGameTime and getGameTime()
    if not gameTime then
        return { worldHour = 0, dayStartWorldHour = 0, year = 1993, month = 7, day = 9, hour = 0, minute = 0 }
    end
    local hour = gameTime:getHour()
    local minute = gameTime:getMinutes()
    local worldHour = gameTime:getWorldAgeHours()
    local day = gameTime.getDayPlusOne and gameTime:getDayPlusOne() or gameTime:getDay() + 1
    return {
        worldHour = worldHour,
        dayStartWorldHour = worldHour - hour - minute / 60,
        year = gameTime:getYear(),
        month = gameTime:getMonth() + 1,
        day = day,
        hour = hour,
        minute = minute,
    }
end

local function PZLinuxRaceScheduleDateKey(year, month, day)
    return string.format("%04d-%02d-%02d", year, month, day)
end

local function PZLinuxRaceScheduleCreateRace(state, year, month, day, dayStartWorldHour, hour)
    local dateKey = PZLinuxRaceScheduleDateKey(year, month, day)
    local raceId = dateKey .. "-" .. string.format("%02d", hour)
    if state.races[raceId] then return state.races[raceId] end

    local isJackpot = PZLinuxRaceScheduleDayOfWeek(year, month, day) == 0
        and hour == PZLINUX_RACE_JACKPOT_HOUR
    local poolOptions
    if isJackpot then
        poolOptions = {
            minimumBettors = 500,
            maximumBettors = 1300,
            maximumPlayerPoolShare = 0.02,
            serverLiquidityRate = 0,
            fixedServerLiquidity = PZLINUX_RACE_JACKPOT_AMOUNT,
            liquidityAfterCommission = true,
        }
    end

    local runners = PZLinuxRaceGenerateCard(PZLinuxRaceRunnerPool, PZLinux.Race.runnerCount)
    local pool = PZLinuxRaceCreateBettingPool(runners, nil, poolOptions)
    if isJackpot then pool.maximumBet = PZLINUX_RACE_JACKPOT_MAXIMUM_BET end
    local race = {
        id = raceId,
        marketVersion = PZLINUX_RACE_MARKET_VERSION,
        dateKey = dateKey,
        label = dateKey .. " " .. string.format("%02d:00", hour),
        hour = hour,
        worldHour = dayStartWorldHour + hour,
        status = "open",
        jackpot = isJackpot,
        jackpotAmount = isJackpot and PZLINUX_RACE_JACKPOT_AMOUNT or 0,
        runners = runners,
        pool = pool,
        realPoolTotal = 0,
        realBettorCount = 0,
        realStakeByRunner = {},
        realBettorsByRunner = {},
    }
    for index = 1, #runners do
        race.realStakeByRunner[index] = 0
        race.realBettorsByRunner[index] = 0
    end
    state.races[raceId] = race
    return race
end

local function PZLinuxRaceScheduleRefreshOpenMarkets(state)
    local racesWithTickets = {}
    for _, tickets in pairs(state.tickets) do
        for raceId in pairs(tickets) do racesWithTickets[raceId] = true end
    end

    for raceId, race in pairs(state.races) do
        if race.status == "open"
            and race.marketVersion ~= PZLINUX_RACE_MARKET_VERSION
            and not racesWithTickets[raceId]
        then
            state.races[raceId] = nil
        end
    end
end

local function PZLinuxRaceScheduleEnsureRaces(state)
    local clock = PZLinuxRaceScheduleGetClock()
    PZLinuxRaceScheduleRefreshOpenMarkets(state)
    for _, hour in ipairs(PZLINUX_RACE_HOURS) do
        PZLinuxRaceScheduleCreateRace(
            state,
            clock.year,
            clock.month,
            clock.day,
            clock.dayStartWorldHour,
            hour
        )
    end

    local nextYear, nextMonth, nextDay = PZLinuxRaceScheduleNextDate(clock.year, clock.month, clock.day)
    for _, hour in ipairs(PZLINUX_RACE_HOURS) do
        PZLinuxRaceScheduleCreateRace(
            state,
            nextYear,
            nextMonth,
            nextDay,
            clock.dayStartWorldHour + 24,
            hour
        )
    end
    return clock
end

local function PZLinuxRaceScheduleSettleDue(state, worldHour)
    for _, race in pairs(state.races) do
        if race.status == "open" and race.worldHour <= worldHour then
            local winnerId = PZLinuxRaceSimulateWinner(race.runners)
            local winner = race.runners[winnerId]
            race.status = "settled"
            race.winnerId = winnerId
            race.winnerName = winner.name
            race.settledWorldHour = worldHour
            race.settlementPoolTotal = race.pool.poolTotal + race.realPoolTotal
            race.settlementWinningStake = winner.poolStake + (race.realStakeByRunner[winnerId] or 0)
            race.takeoutRate = race.pool.takeoutRate
            race.postCommissionLiquidity = race.pool.postCommissionLiquidity or 0
            race.runners = nil
            race.pool = nil
            race.realStakeByRunner = nil
            race.realBettorsByRunner = nil
        end
    end
end

local function PZLinuxRaceSchedulePrune(state, worldHour)
    local racesWithPendingTickets = {}
    for _, tickets in pairs(state.tickets) do
        for raceId in pairs(tickets) do
            racesWithPendingTickets[raceId] = true
        end
    end

    for raceId, race in pairs(state.races) do
        if race.status == "settled"
            and worldHour - race.worldHour > PZLINUX_RACE_HISTORY_HOURS
            and not racesWithPendingTickets[raceId]
        then
            state.races[raceId] = nil
        end
    end
end

local function PZLinuxRaceScheduleGetPlayerTickets(state, playerKey)
    state.tickets[playerKey] = state.tickets[playerKey] or {}
    return state.tickets[playerKey]
end

local function PZLinuxRaceScheduleCreditOnce(player, raceId, payout)
    local modData, pzlinux, playerObj = PZLinuxGetModData(player)
    if not modData or not pzlinux or not playerObj then return false end
    pzlinux.racePaid = pzlinux.racePaid or {}
    if pzlinux.racePaid[raceId] then return true end
    local paidAtWorldHour = PZLinuxRaceScheduleGetClock().worldHour
    for paidRaceId, paidWorldHour in pairs(pzlinux.racePaid) do
        if type(paidWorldHour) == "number"
            and paidAtWorldHour - paidWorldHour > PZLINUX_RACE_PAYMENT_LEDGER_HOURS
        then
            pzlinux.racePaid[paidRaceId] = nil
        end
    end
    if payout > 0 then
        modData.PZLinuxBank = PZLinuxLoadBankBalance(playerObj) + payout
    end
    pzlinux.racePaid[raceId] = paidAtWorldHour
    PZLinuxTransmitPlayerModData(playerObj)
    return true
end

local function PZLinuxRaceScheduleProcessPlayerTickets(state, player)
    local playerKey = PZLinuxGetPlayerKey(player)
    local tickets = PZLinuxRaceScheduleGetPlayerTickets(state, playerKey)
    local due = {}
    for raceId, ticket in pairs(tickets) do
        local race = state.races[raceId]
        if race and race.status == "settled" then
            table.insert(due, { race = race, ticket = ticket })
        end
    end
    table.sort(due, function(left, right) return left.race.worldHour < right.race.worldHour end)

    for _, entry in ipairs(due) do
        local race = entry.race
        local ticket = entry.ticket
        local won = ticket.selectedRunner == race.winnerId
        local payout = PZLinuxRaceCalculateSettledPayout(
            ticket.amount,
            race.settlementPoolTotal,
            race.settlementWinningStake,
            won,
            race.takeoutRate,
            race.postCommissionLiquidity
        )
        if PZLinuxRaceScheduleCreditOnce(player, race.id, payout) then
            local result = {
                raceId = race.id,
                label = race.label,
                jackpot = race.jackpot,
                winnerId = race.winnerId,
                winnerName = race.winnerName,
                selectedRunner = ticket.selectedRunner,
                selectedName = ticket.selectedName,
                amount = ticket.amount,
                payout = payout,
                profit = payout - ticket.amount,
                won = won,
            }
            state.latestResults[playerKey] = result
            local unreadResults = state.unreadResults[playerKey] or {}
            table.insert(unreadResults, result)
            while #unreadResults > PZLINUX_RACE_MAXIMUM_UNREAD_RESULTS do
                table.remove(unreadResults, 1)
            end
            state.unreadResults[playerKey] = unreadResults
            tickets[race.id] = nil
        end
    end
end

local function PZLinuxRaceScheduleBuildRaceSnapshot(race, ticket)
    local runners = {}
    local totalPool = race.pool.poolTotal + race.realPoolTotal
    for index, runner in ipairs(race.runners) do
        local stake = runner.poolStake + (race.realStakeByRunner[index] or 0)
        local multiplier = PZLinuxRaceGetPoolMultiplier(
            totalPool,
            stake,
            race.pool.takeoutRate,
            race.pool.postCommissionLiquidity
        )
        runners[index] = {
            name = runner.name,
            bettorCount = runner.bettorCount + (race.realBettorsByRunner[index] or 0),
            odds = math.max(0, multiplier - 1),
        }
    end
    return {
        id = race.id,
        label = race.label,
        hour = race.hour,
        jackpot = race.jackpot,
        jackpotAmount = race.jackpotAmount,
        runners = runners,
        ticket = ticket,
        pool = {
            bettorCount = race.pool.bettorCount + race.realBettorCount,
            poolTotal = totalPool + (race.pool.postCommissionLiquidity or 0),
            maximumBet = race.pool.maximumBet,
            takeoutRate = race.pool.takeoutRate,
        },
    }
end

function PZLinuxRaceScheduleTick()
    local state = PZLinuxRaceScheduleGetState()
    local clock = PZLinuxRaceScheduleEnsureRaces(state)
    PZLinuxRaceScheduleSettleDue(state, clock.worldHour)
    PZLinuxRaceSchedulePrune(state, clock.worldHour)
    return state
end

function PZLinuxRaceScheduleProcessPlayer(player)
    local state = PZLinuxRaceScheduleTick()
    PZLinuxRaceScheduleProcessPlayerTickets(state, player)
end

function PZLinuxRaceScheduleSnapshot(player, requestId)
    local state = PZLinuxRaceScheduleTick()
    PZLinuxRaceScheduleProcessPlayerTickets(state, player)
    local playerKey = PZLinuxGetPlayerKey(player)
    local tickets = PZLinuxRaceScheduleGetPlayerTickets(state, playerKey)
    local clock = PZLinuxRaceScheduleGetClock()
    local future = {}
    for _, race in pairs(state.races) do
        if race.status == "open" and race.worldHour > clock.worldHour then
            table.insert(future, race)
        end
    end
    table.sort(future, function(left, right) return left.worldHour < right.worldHour end)

    local races = {}
    for index = 1, math.min(PZLINUX_RACE_VISIBLE_SLOTS, #future) do
        local race = future[index]
        races[index] = PZLinuxRaceScheduleBuildRaceSnapshot(race, tickets[race.id])
    end
    local unreadResults = state.unreadResults[playerKey] or {}
    state.unreadResults[playerKey] = {}
    return {
        ok = true,
        requestId = requestId,
        races = races,
        latestResult = unreadResults[#unreadResults],
        unreadResults = unreadResults,
        balance = PZLinuxLoadBankBalance(player),
    }
end

function PZLinuxRaceSchedulePlaceBet(player, raceId, selectedRunner, amount, requestId)
    local state = PZLinuxRaceScheduleTick()
    PZLinuxRaceScheduleProcessPlayerTickets(state, player)
    local race = state.races[tostring(raceId or "")]
    local clock = PZLinuxRaceScheduleGetClock()
    selectedRunner = tonumber(selectedRunner)
    amount = PZLinuxNormalizeMoney(amount)
    if not race or race.status ~= "open" or race.worldHour <= clock.worldHour then
        return { ok = false, error = "race_closed", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if not selectedRunner or selectedRunner < 1 or selectedRunner > #race.runners then
        return { ok = false, error = "invalid_runner", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if amount <= 0 or amount > race.pool.maximumBet then
        return {
            ok = false,
            error = "bet_above_pool_limit",
            maximumBet = race.pool.maximumBet,
            requestId = requestId,
            balance = PZLinuxLoadBankBalance(player),
        }
    end

    local playerKey = PZLinuxGetPlayerKey(player)
    local tickets = PZLinuxRaceScheduleGetPlayerTickets(state, playerKey)
    if tickets[race.id] then
        return { ok = false, error = "ticket_exists", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    local debit = PZLinuxApplyBankDebit(player, amount, "zombie-race-ticket", requestId)
    if not debit.ok then return debit end
    race.realPoolTotal = race.realPoolTotal + amount
    race.realBettorCount = race.realBettorCount + 1
    race.realStakeByRunner[selectedRunner] = race.realStakeByRunner[selectedRunner] + amount
    race.realBettorsByRunner[selectedRunner] = race.realBettorsByRunner[selectedRunner] + 1
    tickets[race.id] = {
        raceId = race.id,
        selectedRunner = selectedRunner,
        selectedName = race.runners[selectedRunner].name,
        amount = amount,
        placedWorldHour = clock.worldHour,
    }
    state.latestResults[playerKey] = nil

    local snapshot = PZLinuxRaceScheduleSnapshot(player, requestId)
    snapshot.placed = true
    return snapshot
end

function PZLinuxRequestRaceSchedule(player, callback)
    local requestId = PZLinuxNextRequestId("race-schedule")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRaceSchedule", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRaceScheduleSnapshot(player, requestId))
    return requestId
end

function PZLinuxRequestRaceScheduleBet(player, raceId, selectedRunner, amount, callback)
    local requestId = PZLinuxNextRequestId("race-schedule-bet")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRaceScheduleBet", {
        requestId = requestId,
        raceId = raceId,
        selectedRunner = selectedRunner,
        amount = amount,
    }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRaceSchedulePlaceBet(player, raceId, selectedRunner, amount, requestId))
    return requestId
end
