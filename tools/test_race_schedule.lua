local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

math.randomseed(42020)
function ZombRand(minimum, maximumExclusive)
    return math.random(minimum, maximumExclusive - 1)
end

local clock = {
    worldHour = 0,
    year = 1993,
    month = 6,
    day = 10,
    hour = 7,
    minute = 0,
}
local gameTime = {}
function gameTime:getWorldAgeHours() return clock.worldHour end
function gameTime:getYear() return clock.year end
function gameTime:getMonth() return clock.month end
function gameTime:getDayPlusOne() return clock.day + 1 end
function gameTime:getHour() return clock.hour end
function gameTime:getMinutes() return clock.minute end
function getGameTime() return gameTime end

local globalData = {}
ModData = {}
function ModData.getOrCreate(key)
    globalData[key] = globalData[key] or {}
    return globalData[key]
end

local player = { modData = { PZLinuxBank = 10000 } }
function player:getUsername() return "schedule-test" end
function player:getModData() return self.modData end
function player:transmitModData() end
local playerTwo = { modData = { PZLinuxBank = 10000 } }
function playerTwo:getUsername() return "schedule-test-two" end
function playerTwo:getModData() return self.modData end
function playerTwo:transmitModData() end
local playerThree = { modData = { PZLinuxBank = 10000 } }
function playerThree:getUsername() return "schedule-test-three" end
function playerThree:getModData() return self.modData end
function playerThree:transmitModData() end

PZLinux = {}
function PZLinuxGetPlayer(candidate) return candidate or player end
function PZLinuxGetPlayerKey(candidate) return (candidate or player):getUsername() end
function PZLinuxGetModData(candidate)
    local playerObj = candidate or player
    local modData = playerObj:getModData()
    modData.pzlinux = modData.pzlinux or {}
    return modData, modData.pzlinux, playerObj
end
function PZLinuxTransmitPlayerModData() end
function PZLinuxNormalizeMoney(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
function PZLinuxLoadBankBalance(candidate) return (candidate or player):getModData().PZLinuxBank end
function PZLinuxApplyBankDebit(candidate, amount, reason, requestId)
    local playerObj = candidate or player
    amount = PZLinuxNormalizeMoney(amount)
    local previous = playerObj:getModData().PZLinuxBank
    if amount <= 0 then return { ok = false, error = "invalid_amount", balance = previous } end
    if previous < amount then return { ok = false, error = "not_enough_money", balance = previous } end
    playerObj:getModData().PZLinuxBank = previous - amount
    return { ok = true, amount = amount, previousBalance = previous, balance = previous - amount, reason = reason, requestId = requestId }
end

dofile(luaRoot .. "/shared/PZLinux/PZLinuxGamblingData.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxRaceEngine.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxRaceSchedule.lua")

PZLinuxTestAssert(PZLinuxRaceScheduleDayOfWeek(1993, 7, 11) == 0, "1993-07-11 must be detected as Sunday")

local firstSnapshot = PZLinuxRaceScheduleSnapshot(player, "snapshot-1")
PZLinuxTestAssert(firstSnapshot.ok and #firstSnapshot.races == 5, "the morning schedule must expose five races")
PZLinuxTestAssert(firstSnapshot.races[1].hour == 8 and firstSnapshot.races[5].hour == 16,
    "daily departures must run from 08:00 to 16:00 every two hours")
PZLinuxTestAssert(firstSnapshot.races[5].jackpot and firstSnapshot.races[5].jackpotAmount == 50000,
    "Sunday 16:00 must be the super jackpot race")
PZLinuxTestAssert(firstSnapshot.races[5].pool.bettorCount >= 500,
    "the jackpot race must use the larger virtual crowd")
PZLinuxTestAssert(firstSnapshot.races[5].pool.bettorCount <= 1300,
    "the jackpot virtual crowd must remain inside its configured range")
PZLinuxTestAssert(firstSnapshot.races[5].pool.maximumBet == 500,
    "the positive-expectation jackpot must cap each player ticket at $500")
PZLinuxTestAssert(firstSnapshot.races[1].pool.bettorCount >= 200
    and firstSnapshot.races[1].pool.bettorCount <= 800,
    "ordinary races must draw between 200 and 800 virtual bettors")
PZLinuxTestAssert(firstSnapshot.races[1].pool.maximumBet <= 2000,
    "ordinary races must cap each player ticket at $2,000")
local ordinaryBettorCounts = {}
for raceIndex = 1, 4 do
    ordinaryBettorCounts[firstSnapshot.races[raceIndex].pool.bettorCount] = true
end
local distinctOrdinaryBettorCounts = 0
for _ in pairs(ordinaryBettorCounts) do distinctOrdinaryBettorCounts = distinctOrdinaryBettorCounts + 1 end
PZLinuxTestAssert(distinctOrdinaryBettorCounts > 1,
    "each ordinary race must generate its own virtual crowd")
local staleRaceId = firstSnapshot.races[4].id
local staleRace = globalData.PZLinuxRaceSchedule.races[staleRaceId]
staleRace.marketVersion = 1
local refreshedSnapshot = PZLinuxRaceScheduleSnapshot(player, "snapshot-market-refresh")
PZLinuxTestAssert(globalData.PZLinuxRaceSchedule.races[staleRaceId] ~= staleRace
    and refreshedSnapshot.races[4].id == staleRaceId,
    "an obsolete open market without tickets must be regenerated")

local firstRaceId = firstSnapshot.races[1].id
local secondRaceId = firstSnapshot.races[2].id
local firstBet = PZLinuxRaceSchedulePlaceBet(player, firstRaceId, 1, 100, "bet-1")
PZLinuxTestAssert(firstBet.ok and firstBet.placed, "the first scheduled ticket must be accepted")
local ticketedRace = globalData.PZLinuxRaceSchedule.races[firstRaceId]
ticketedRace.marketVersion = 1
PZLinuxRaceScheduleSnapshot(player, "snapshot-preserve-ticketed-market")
PZLinuxTestAssert(globalData.PZLinuxRaceSchedule.races[firstRaceId] == ticketedRace,
    "an obsolete market with a player ticket must never be regenerated")
ticketedRace.marketVersion = 2
local secondBet = PZLinuxRaceSchedulePlaceBet(player, secondRaceId, 2, 150, "bet-2")
PZLinuxTestAssert(secondBet.ok and secondBet.placed, "the player must be able to program several races")
PZLinuxTestAssert(player.modData.PZLinuxBank == 9750, "scheduled stakes must be debited immediately")
local sharedSnapshot = PZLinuxRaceScheduleSnapshot(playerTwo, "snapshot-shared")
PZLinuxTestAssert(sharedSnapshot.races[1].id == firstRaceId,
    "all multiplayer clients must receive the same scheduled race")
local sharedBet = PZLinuxRaceSchedulePlaceBet(playerTwo, firstRaceId, 1, 200, "bet-shared")
PZLinuxTestAssert(sharedBet.ok and playerTwo.modData.PZLinuxBank == 9800,
    "another player must be able to join the same global pool")
PZLinuxTestAssert(PZLinuxRaceSchedulePlaceBet(playerThree, firstRaceId, 1, 100, "bet-unread-1").ok,
    "the unread-results player must place the 08:00 ticket")
PZLinuxTestAssert(PZLinuxRaceSchedulePlaceBet(playerThree, secondRaceId, 1, 100, "bet-unread-2").ok,
    "the unread-results player must place the 10:00 ticket")
PZLinuxTestAssert(PZLinuxRaceSchedulePlaceBet(playerThree, firstSnapshot.races[3].id, 1, 100, "bet-unread-3").ok,
    "the unread-results player must place the 12:00 ticket")

local duplicate = PZLinuxRaceSchedulePlaceBet(player, firstRaceId, 1, 100, "bet-duplicate")
PZLinuxTestAssert(not duplicate.ok and duplicate.error == "ticket_exists", "only one ticket per player and race is allowed")

clock.worldHour = 1.1
clock.hour = 8
clock.minute = 6
local afterFirstRace = PZLinuxRaceScheduleSnapshot(player, "snapshot-2")
PZLinuxTestAssert(afterFirstRace.latestResult and afterFirstRace.latestResult.raceId == firstRaceId,
    "the server must settle the first ticket without opening the betting UI")
local secondPlayerResult = PZLinuxRaceScheduleSnapshot(playerTwo, "snapshot-shared-result")
PZLinuxTestAssert(secondPlayerResult.latestResult
    and secondPlayerResult.latestResult.winnerId == afterFirstRace.latestResult.winnerId,
    "every player must receive the same authoritative winner")
if afterFirstRace.latestResult.won then
    PZLinuxTestAssert(secondPlayerResult.latestResult.payout >= afterFirstRace.latestResult.payout * 2 - 1,
        "shared-pool payouts must remain proportional to each winning stake")
end

local thirdRaceId = afterFirstRace.races[2].id
local thirdBet = PZLinuxRaceSchedulePlaceBet(player, thirdRaceId, 1, 100, "bet-3")
PZLinuxTestAssert(thirdBet.ok and thirdBet.latestResult == nil,
    "placing a new ticket must clear the previous recap")

clock.worldHour = 3.1
clock.hour = 10
clock.minute = 6
local afterSecondRace = PZLinuxRaceScheduleSnapshot(player, "snapshot-3")
PZLinuxTestAssert(afterSecondRace.latestResult and afterSecondRace.latestResult.raceId == secondRaceId,
    "the newest settled race must replace the previous recap")

clock.worldHour = 5.1
clock.hour = 12
clock.minute = 6
local unreadSnapshot = PZLinuxRaceScheduleSnapshot(playerThree, "snapshot-unread")
PZLinuxTestAssert(#unreadSnapshot.unreadResults == 3,
    "the next visit must return every unseen result, not only the latest race")
PZLinuxTestAssert(unreadSnapshot.unreadResults[1].raceId == firstRaceId
    and unreadSnapshot.unreadResults[3].raceId == firstSnapshot.races[3].id,
    "unseen race results must be returned in chronological order")
local readAgain = PZLinuxRaceScheduleSnapshot(playerThree, "snapshot-read-again")
PZLinuxTestAssert(#readAgain.unreadResults == 0,
    "race results must be marked as read after they are returned to the terminal")

clock.worldHour = 243.1
clock.day = 20
clock.hour = 10
clock.minute = 6
PZLinuxRaceScheduleSnapshot(player, "snapshot-prune-player")
PZLinuxRaceScheduleTick()
local storedRaceCount = 0
for _ in pairs(globalData.PZLinuxRaceSchedule.races) do storedRaceCount = storedRaceCount + 1 end
PZLinuxTestAssert(storedRaceCount <= 10,
    "settled races without pending offline tickets must not accumulate forever")

print("Zombie Race schedule tests OK")
