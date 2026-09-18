PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.Sessions = PZLinux.Poker.Sessions or {}

local PZLINUX_POKER_RANKS = { "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A" }
local PZLINUX_POKER_SUITS = { "C", "D", "H", "S" }
local PZLINUX_POKER_RANK_LABELS = { A = "A", T = "10", J = "J", Q = "Q", K = "K" }
local PZLINUX_POKER_SUIT_LABELS = { C = "C", D = "D", H = "H", S = "S" }
local PZLINUX_POKER_RANK_VALUE = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7,
    ["8"] = 8, ["9"] = 9, T = 10, J = 11, Q = 12, K = 13, A = 14,
}
local PZLINUX_POKER_HAND_NAMES = {
    [9] = "royal_flush",
    [8] = "straight_flush",
    [7] = "four_kind",
    [6] = "full_house",
    [5] = "flush",
    [4] = "straight",
    [3] = "three_kind",
    [2] = "two_pair",
    [1] = "pair",
    [0] = "high_card",
}

local function PZLinuxPokerRandom(maxExclusive)
    if ZombRand then return ZombRand(maxExclusive) end
    return math.random(0, maxExclusive - 1)
end

local function PZLinuxPokerRandomRange(minInclusive, maxExclusive)
    if ZombRand then return ZombRand(minInclusive, maxExclusive) end
    return math.random(minInclusive, maxExclusive - 1)
end

-- Global so that engines can rebuild the 52-card set and subtract what they
-- can see. That is not a leak: it is a constant, and every engine already
-- knows what a deck of cards contains. The live, shuffled deck stays out of
-- the engine view.
function PZLinuxPokerCreateOrderedDeck()
    local deck = {}
    for _, suit in ipairs(PZLINUX_POKER_SUITS) do
        for _, rank in ipairs(PZLINUX_POKER_RANKS) do
            table.insert(deck, {
                rank = rank,
                suit = suit,
                value = PZLINUX_POKER_RANK_VALUE[rank],
                label = (PZLINUX_POKER_RANK_LABELS[rank] or rank) .. (PZLINUX_POKER_SUIT_LABELS[suit] or suit),
            })
        end
    end
    return deck
end

function PZLinuxPokerCreateDeck()
    local deck = PZLinuxPokerCreateOrderedDeck()
    for index = #deck, 2, -1 do
        local swapIndex = PZLinuxPokerRandomRange(1, index + 1)
        deck[index], deck[swapIndex] = deck[swapIndex], deck[index]
    end
    return deck
end

function PZLinuxPokerDraw(deck)
    return table.remove(deck, #deck)
end

local function PZLinuxPokerCopyCards(cards, hidden)
    local copy = {}
    for _, card in ipairs(cards or {}) do
        if hidden then
            table.insert(copy, { label = "??", hidden = true })
        else
            table.insert(copy, { rank = card.rank, suit = card.suit, value = card.value, label = card.label })
        end
    end
    return copy
end

local function PZLinuxPokerCompareKickers(a, b)
    for index = 1, math.max(#(a or {}), #(b or {})) do
        local left = a[index] or 0
        local right = b[index] or 0
        if left ~= right then return left - right end
    end
    return 0
end

function PZLinuxPokerCompareHands(a, b)
    if (a.rank or 0) ~= (b.rank or 0) then
        return (a.rank or 0) - (b.rank or 0)
    end
    return PZLinuxPokerCompareKickers(a.kickers or {}, b.kickers or {})
end

local function PZLinuxPokerSortedValuesDescending(values)
    table.sort(values, function(a, b) return a > b end)
    return values
end

local function PZLinuxPokerFindStraight(values)
    local present = {}
    for _, value in ipairs(values) do
        present[value] = true
        if value == 14 then present[1] = true end
    end
    for high = 14, 5, -1 do
        if present[high] and present[high - 1] and present[high - 2] and present[high - 3] and present[high - 4] then
            return high
        end
    end
    return nil
end

function PZLinuxPokerEvaluateHand(cards)
    local byRank = {}
    local bySuit = {}
    local uniqueValues = {}
    local seenValues = {}
    for _, card in ipairs(cards or {}) do
        byRank[card.value] = byRank[card.value] or {}
        table.insert(byRank[card.value], card)
        bySuit[card.suit] = bySuit[card.suit] or {}
        table.insert(bySuit[card.suit], card)
        if not seenValues[card.value] then
            seenValues[card.value] = true
            table.insert(uniqueValues, card.value)
        end
    end
    PZLinuxPokerSortedValuesDescending(uniqueValues)

    local flushCards = nil
    for _, suited in pairs(bySuit) do
        if #suited >= 5 then
            flushCards = suited
            break
        end
    end

    if flushCards then
        local flushValues = {}
        local flushSeen = {}
        for _, card in ipairs(flushCards) do
            if not flushSeen[card.value] then
                flushSeen[card.value] = true
                table.insert(flushValues, card.value)
            end
        end
        local straightFlushHigh = PZLinuxPokerFindStraight(flushValues)
        if straightFlushHigh then
            if straightFlushHigh == 14 then
                return { rank = 9, name = PZLINUX_POKER_HAND_NAMES[9], kickers = { 14 } }
            end
            return { rank = 8, name = PZLINUX_POKER_HAND_NAMES[8], kickers = { straightFlushHigh } }
        end
    end

    local groups = {}
    for value, group in pairs(byRank) do
        table.insert(groups, { value = value, count = #group })
    end
    table.sort(groups, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.value > b.value
    end)

    if groups[1] and groups[1].count == 4 then
        local kicker = 0
        for _, value in ipairs(uniqueValues) do
            if value ~= groups[1].value then kicker = value break end
        end
        return { rank = 7, name = PZLINUX_POKER_HAND_NAMES[7], kickers = { groups[1].value, kicker } }
    end

    local trips = {}
    local pairs = {}
    for _, group in ipairs(groups) do
        if group.count >= 3 then table.insert(trips, group.value) end
        if group.count >= 2 then table.insert(pairs, group.value) end
    end
    PZLinuxPokerSortedValuesDescending(trips)
    PZLinuxPokerSortedValuesDescending(pairs)
    if trips[1] then
        local pairValue = nil
        for _, value in ipairs(pairs) do
            if value ~= trips[1] then pairValue = value break end
        end
        if not pairValue and trips[2] then pairValue = trips[2] end
        if pairValue then
            return { rank = 6, name = PZLINUX_POKER_HAND_NAMES[6], kickers = { trips[1], pairValue } }
        end
    end

    if flushCards then
        local values = {}
        for _, card in ipairs(flushCards) do table.insert(values, card.value) end
        PZLinuxPokerSortedValuesDescending(values)
        while #values > 5 do table.remove(values) end
        return { rank = 5, name = PZLINUX_POKER_HAND_NAMES[5], kickers = values }
    end

    local straightHigh = PZLinuxPokerFindStraight(uniqueValues)
    if straightHigh then
        return { rank = 4, name = PZLINUX_POKER_HAND_NAMES[4], kickers = { straightHigh } }
    end

    if trips[1] then
        local kickers = { trips[1] }
        for _, value in ipairs(uniqueValues) do
            if value ~= trips[1] then table.insert(kickers, value) end
            if #kickers == 3 then break end
        end
        return { rank = 3, name = PZLINUX_POKER_HAND_NAMES[3], kickers = kickers }
    end

    if pairs[1] and pairs[2] then
        local kicker = 0
        for _, value in ipairs(uniqueValues) do
            if value ~= pairs[1] and value ~= pairs[2] then kicker = value break end
        end
        return { rank = 2, name = PZLINUX_POKER_HAND_NAMES[2], kickers = { pairs[1], pairs[2], kicker } }
    end

    if pairs[1] then
        local kickers = { pairs[1] }
        for _, value in ipairs(uniqueValues) do
            if value ~= pairs[1] then table.insert(kickers, value) end
            if #kickers == 4 then break end
        end
        return { rank = 1, name = PZLINUX_POKER_HAND_NAMES[1], kickers = kickers }
    end

    local highCards = {}
    for _, value in ipairs(uniqueValues) do
        table.insert(highCards, value)
        if #highCards == 5 then break end
    end
    return { rank = 0, name = PZLINUX_POKER_HAND_NAMES[0], kickers = highCards }
end

local function PZLinuxPokerEquityStateKey(session, seatIndex)
    local parts = { tostring(session.handNumber or 0), tostring(session.phase or ""), tostring(seatIndex) }
    for _, card in ipairs((session.seats[seatIndex] and session.seats[seatIndex].cards) or {}) do
        table.insert(parts, tostring(card.label))
    end
    for _, card in ipairs(session.community or {}) do table.insert(parts, tostring(card.label)) end
    for index, seat in ipairs(session.seats or {}) do
        table.insert(parts, tostring(index) .. ":" .. tostring(seat.inHand) .. ":" .. tostring(seat.folded))
    end
    return table.concat(parts, "|")
end

local function PZLinuxPokerEquitySeed(key)
    local seed = 104729
    for index = 1, #key do
        seed = (seed * 31 + string.byte(key, index)) % 2147483647
    end
    return math.max(1, seed)
end

local function PZLinuxPokerEquityRandom(seed, maxInclusive)
    seed = (seed * 48271) % 2147483647
    return seed, (seed % maxInclusive) + 1
end

local function PZLinuxPokerEquityDraw(deck, seed)
    local index
    seed, index = PZLinuxPokerEquityRandom(seed, #deck)
    local card = deck[index]
    deck[index] = deck[#deck]
    deck[#deck] = nil
    return card, seed
end

-- Monte Carlo equity for any seat, not just the human's. The player's own
-- display still calls this through PZLinuxPokerEstimateEquity below; engines
-- reach it through context.equity, which pins the seat to whoever is acting.
-- Each seat caches its own answer, because the board state alone does not
-- identify a result that depends on which hole cards it was computed from.
function PZLinuxPokerEstimateEquityForSeat(session, seatIndex, simulationCount)
    local playerSeat = session and session.seats and session.seats[seatIndex]
    if not playerSeat or not playerSeat.inHand or playerSeat.folded or #(playerSeat.cards or {}) ~= 2 then return nil end
    if session.phase == "finished" or session.phase == "hand_complete" then return nil end

    local opponentCount = 0
    for index, seat in ipairs(session.seats or {}) do
        if index ~= seatIndex and seat.inHand and not seat.folded then opponentCount = opponentCount + 1 end
    end
    if opponentCount == 0 then return 100 end

    local known = {}
    for _, card in ipairs(playerSeat.cards or {}) do known[card.label] = true end
    for _, card in ipairs(session.community or {}) do known[card.label] = true end

    local available = {}
    for _, card in ipairs(PZLinuxPokerCreateOrderedDeck()) do
        if not known[card.label] then table.insert(available, card) end
    end

    local missingBoardCards = math.max(0, 5 - #(session.community or {}))
    if opponentCount * 2 + missingBoardCards > #available then return nil end

    simulationCount = math.max(50, math.floor(tonumber(simulationCount) or 300))
    local stateKey = PZLinuxPokerEquityStateKey(session, seatIndex)
    session.equityCache = session.equityCache or {}
    local cache = session.equityCache[seatIndex]
    if cache and cache.key == stateKey and cache.samples == simulationCount then return cache.equity end

    local equity = 0
    local seed = PZLinuxPokerEquitySeed(stateKey)
    for _ = 1, simulationCount do
        local deck = {}
        for index, card in ipairs(available) do deck[index] = card end

        local opponentHands = {}
        for opponent = 1, opponentCount do
            local first, second
            first, seed = PZLinuxPokerEquityDraw(deck, seed)
            second, seed = PZLinuxPokerEquityDraw(deck, seed)
            opponentHands[opponent] = { first, second }
        end

        local board = {}
        for _, card in ipairs(session.community or {}) do table.insert(board, card) end
        while #board < 5 do
            local card
            card, seed = PZLinuxPokerEquityDraw(deck, seed)
            table.insert(board, card)
        end

        local playerCards = { playerSeat.cards[1], playerSeat.cards[2] }
        for _, card in ipairs(board) do table.insert(playerCards, card) end
        local playerValue = PZLinuxPokerEvaluateHand(playerCards)
        local tiedWinners = 1
        local beaten = false
        for _, opponentHand in ipairs(opponentHands) do
            local opponentCards = { opponentHand[1], opponentHand[2] }
            for _, card in ipairs(board) do table.insert(opponentCards, card) end
            local comparison = PZLinuxPokerCompareHands(PZLinuxPokerEvaluateHand(opponentCards), playerValue)
            if comparison > 0 then
                beaten = true
                break
            elseif comparison == 0 then
                tiedWinners = tiedWinners + 1
            end
        end
        if not beaten then equity = equity + 1 / tiedWinners end
    end

    equity = math.floor(equity * 1000 / simulationCount + 0.5) / 10
    session.equityCache[seatIndex] = { key = stateKey, samples = simulationCount, equity = equity }
    return equity
end

function PZLinuxPokerEstimateEquity(session, simulationCount)
    return PZLinuxPokerEstimateEquityForSeat(session, 1, simulationCount)
end

local function PZLinuxPokerAddHistory(session, text)
    session.history = session.history or {}
    table.insert(session.history, 1, text)
    while #session.history > (PZLinux.Poker.Config.maxActionHistory or 12) do
        table.remove(session.history)
    end
end

local PZLINUX_POKER_LOG_FIELD_ORDER = {
    "player", "requestId", "session", "lobby", "hand", "phase", "actor",
    "seat", "seatName", "engine", "requestedAction", "requestedAmount",
    "appliedAction", "label", "fallback", "result", "reason", "error",
    "amount", "paid", "toCall", "stackBefore", "stackAfter", "betBefore",
    "betAfter", "committedBefore", "committedAfter", "currentBetBefore",
    "currentBetAfter", "minRaiseBefore", "minRaiseAfter", "potBefore",
    "potAfter", "folded", "allIn", "turnBefore", "turnAfter", "dealer",
    "smallBlindSeat", "bigBlindSeat", "smallBlind", "bigBlind", "activeSeats",
    "contenders", "status", "communityCards", "buyIn", "balance",
}

local function PZLinuxPokerLogValue(value)
    if value == nil then return "nil" end
    local text = tostring(value)
    if text == "" or string.find(text, "%s") or string.find(text, "\"", 1, true) then
        text = string.gsub(text, "\\", "\\\\")
        text = string.gsub(text, "\"", "\\\"")
        return "\"" .. text .. "\""
    end
    return text
end

local function PZLinuxPokerLogActionsEnabled()
    return not (PZLinux and PZLinux.Poker and PZLinux.Poker.Config
        and PZLinux.Poker.Config.logActions == false)
end

local function PZLinuxPokerLog(kind, fields)
    if not PZLinuxPokerLogActionsEnabled() then return end
    fields = fields or {}
    local parts = { "[PZLinux Poker] " .. tostring(kind) }
    for _, key in ipairs(PZLINUX_POKER_LOG_FIELD_ORDER) do
        if fields[key] ~= nil then
            table.insert(parts, key .. "=" .. PZLinuxPokerLogValue(fields[key]))
        end
    end
    print(table.concat(parts, " "))
end

local function PZLinuxPokerCommittedTotal(session)
    local total = 0
    for _, seat in ipairs((session and session.seats) or {}) do
        total = total + (tonumber(seat.committed) or 0)
    end
    return total
end

local function PZLinuxPokerSafePlayerKey(player)
    local ok, key = pcall(function()
        local playerObj = PZLinuxGetPlayer and PZLinuxGetPlayer(player) or player
        return PZLinuxGetPlayerKey and PZLinuxGetPlayerKey(playerObj) or nil
    end)
    if ok and key then return key end
    return tostring(player)
end

local function PZLinuxPokerActionState(session, seat)
    return {
        phase = session and session.phase or nil,
        turn = session and session.turn or nil,
        stack = seat and seat.stack or 0,
        bet = seat and seat.bet or 0,
        committed = seat and seat.committed or 0,
        currentBet = session and session.currentBet or 0,
        minRaise = session and session.minRaise or 0,
        pot = PZLinuxPokerCommittedTotal(session),
    }
end

local function PZLinuxPokerLogActionResult(session, seatIndex, actor, requestedAction, requestedAmount, requestId, before, extra)
    local seat = session and session.seats and session.seats[seatIndex]
    if not seat then return end
    before = before or PZLinuxPokerActionState(session, seat)
    extra = extra or {}
    local paid = (before.stack or 0) - (seat.stack or 0)
    if paid < 0 then paid = 0 end
    PZLinuxPokerLog("ACTION", {
        player = session.playerKey,
        requestId = requestId,
        session = session.sessionId,
        lobby = session.lobbyId,
        hand = session.handNumber,
        phase = before.phase or session.phase,
        actor = actor,
        seat = seatIndex,
        seatName = seat.name,
        engine = extra.engine,
        requestedAction = requestedAction,
        requestedAmount = requestedAmount,
        appliedAction = seat.lastActionKind,
        label = seat.lastAction,
        fallback = extra.fallback,
        result = extra.result,
        paid = paid,
        toCall = math.max(0, (before.currentBet or 0) - (before.bet or 0)),
        stackBefore = before.stack,
        stackAfter = seat.stack,
        betBefore = before.bet,
        betAfter = seat.bet,
        committedBefore = before.committed,
        committedAfter = seat.committed,
        currentBetBefore = before.currentBet,
        currentBetAfter = session.currentBet,
        minRaiseBefore = before.minRaise,
        minRaiseAfter = session.minRaise,
        potBefore = before.pot,
        potAfter = PZLinuxPokerCommittedTotal(session),
        folded = seat.folded == true,
        allIn = seat.allIn == true,
        turnBefore = before.turn,
        turnAfter = session.turn,
        status = session.status,
    })
end

local function PZLinuxPokerLogActionRejected(player, session, action, amount, requestId, reason, legal, requestedSessionId)
    legal = legal or {}
    PZLinuxPokerLog("ACTION REJECT", {
        player = session and session.playerKey or PZLinuxPokerSafePlayerKey(player),
        requestId = requestId,
        session = session and session.sessionId or requestedSessionId,
        lobby = session and session.lobbyId or nil,
        hand = session and session.handNumber or nil,
        phase = session and session.phase or nil,
        actor = "player",
        seat = 1,
        requestedAction = action,
        requestedAmount = amount,
        reason = reason,
        toCall = legal.toCall,
        currentBetBefore = session and session.currentBet or nil,
        minRaiseBefore = session and session.minRaise or nil,
        status = session and session.status or nil,
    })
end

local function PZLinuxPokerActivePlayers(session)
    local active = {}
    for index, seat in ipairs(session.seats or {}) do
        if not seat.eliminated and seat.stack > 0 then
            table.insert(active, index)
        end
    end
    return active
end

local function PZLinuxPokerHandContenders(session)
    local active = {}
    for index, seat in ipairs(session.seats or {}) do
        if not seat.eliminated and not seat.folded and seat.inHand then
            table.insert(active, index)
        end
    end
    return active
end

local function PZLinuxPokerGenerateAIName(used)
    local first = PZLinux.Poker.Config.names.first
    local last = PZLinux.Poker.Config.names.last
    for _ = 1, 48 do
        local name = first[PZLinuxPokerRandom(#first) + 1] .. " " .. last[PZLinuxPokerRandom(#last) + 1]
        if not used[name] then
            used[name] = true
            return name
        end
    end
    return "Player " .. tostring(PZLinuxPokerRandom(999) + 1)
end

local function PZLinuxPokerNextOccupiedSeat(session, fromIndex)
    local count = #session.seats
    for offset = 1, count do
        local index = ((fromIndex - 1 + offset) % count) + 1
        local seat = session.seats[index]
        if seat and not seat.eliminated and seat.stack > 0 then
            return index
        end
    end
    return fromIndex
end

local function PZLinuxPokerSetLastAction(session, seat, label, kind)
    if not seat then return end
    seat.lastAction = label or ""
    seat.lastActionKind = kind or ""
    seat.lastActionPhase = label and label ~= "" and session and session.phase or nil
end

local function PZLinuxPokerPostBlind(session, seatIndex, amount, label, requestId)
    local seat = session.seats[seatIndex]
    local before = PZLinuxPokerActionState(session, seat)
    local posted = math.min(seat.stack, amount)
    seat.stack = seat.stack - posted
    seat.bet = seat.bet + posted
    seat.committed = seat.committed + posted
    if seat.stack == 0 then seat.allIn = true end
    PZLinuxPokerSetLastAction(session, seat,
        label == "posts SB" and ("SB $" .. tostring(posted)) or ("BB $" .. tostring(posted)), "blind")
    session.currentBet = math.max(session.currentBet, seat.bet)
    PZLinuxPokerAddHistory(session, seat.name .. " " .. label .. " $" .. tostring(posted))
    PZLinuxPokerLogActionResult(session, seatIndex, "system",
        label == "posts SB" and "small_blind" or "big_blind", posted, requestId, before, { result = "posted" })
end

local function PZLinuxPokerDealCommunity(session, count)
    for _ = 1, count do
        table.insert(session.community, PZLinuxPokerDraw(session.deck))
    end
end

local function PZLinuxPokerOpenBettingRound(session, phase, requestId)
    session.phase = phase
    session.currentBet = 0
    session.minRaise = session.bigBlind
    session.awaitingPlayer = false
    for _, seat in ipairs(session.seats) do
        seat.bet = 0
        seat.acted = seat.folded or seat.allIn or seat.eliminated or not seat.inHand
    end
    session.turn = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
    PZLinuxPokerLog("ROUND", {
        player = session.playerKey,
        requestId = requestId,
        session = session.sessionId,
        lobby = session.lobbyId,
        hand = session.handNumber,
        phase = session.phase,
        turnAfter = session.turn,
        dealer = session.dealer,
        currentBetAfter = session.currentBet,
        minRaiseAfter = session.minRaise,
        potAfter = PZLinuxPokerCommittedTotal(session),
        communityCards = #(session.community or {}),
    })
end

local function PZLinuxPokerNeedMoreActions(session)
    local contenders = PZLinuxPokerHandContenders(session)
    if #contenders <= 1 then return false end
    for _, index in ipairs(contenders) do
        local seat = session.seats[index]
        if not seat.allIn and (not seat.acted or seat.bet < session.currentBet) then
            return true
        end
    end
    return false
end

-- Bounded scan over every seat exactly once (v1.0.16). The previous version
-- walked with PZLinuxPokerNextOccupiedSeat and stopped only when it came back
-- around to the seat it started on. That helper skips any seat with stack 0,
-- so once the seat we started from was all-in it could never be returned, the
-- "until session.turn == start" condition never became true, and the loop
-- spun forever -- freezing the game the moment a player shoved all-in and the
-- only other live hand was also all-in (every other seat folded). Scanning a
-- fixed number of offsets terminates unconditionally, and leaving session.turn
-- untouched when nobody can act lets the callers fall through to the
-- betting-round/showdown logic that already handles an all-in runout.
local function PZLinuxPokerMoveTurn(session)
    local count = #(session.seats or {})
    if count == 0 then return end
    for offset = 1, count do
        local index = ((session.turn - 1 + offset) % count) + 1
        local seat = session.seats[index]
        if seat and seat.inHand and not seat.folded and not seat.allIn and not seat.eliminated then
            session.turn = index
            return
        end
    end
end

local function PZLinuxPokerLegalActions(session)
    local seat = session.seats[1]
    if not session.awaitingPlayer or session.turn ~= 1 or not seat or seat.folded or seat.allIn then
        return {}
    end
    local toCall = math.max(0, session.currentBet - seat.bet)
    local minBet = session.currentBet == 0 and session.bigBlind or (toCall + session.minRaise)
    local maxBet = seat.stack
    local actions = { fold = toCall > 0, check = toCall == 0, call = toCall > 0 and seat.stack > 0, allin = seat.stack > 0 }
    actions.bet = toCall == 0 and minBet <= maxBet
    actions.raise = toCall > 0 and minBet <= maxBet
    actions.toCall = toCall
    actions.minBet = minBet
    actions.maxBet = maxBet
    return actions
end

local function PZLinuxPokerResolvePots(session)
    local levels = {}
    local seenLevels = {}
    for _, seat in ipairs(session.seats) do
        if seat.committed > 0 and not seenLevels[seat.committed] then
            seenLevels[seat.committed] = true
            table.insert(levels, seat.committed)
        end
    end
    table.sort(levels)

    local previous = 0
    local payouts = {}
    session.pots = {}
    for _, level in ipairs(levels) do
        local participants = {}
        local eligible = {}
        for index, seat in ipairs(session.seats) do
            if seat.committed >= level then
                table.insert(participants, index)
                if not seat.folded and seat.inHand then
                    table.insert(eligible, index)
                end
            end
        end
        local potAmount = (level - previous) * #participants
        previous = level
        if potAmount > 0 and #eligible > 0 then
            table.insert(session.pots, { amount = potAmount, eligible = eligible })
        end
    end

    for _, pot in ipairs(session.pots) do
        local best = nil
        local winners = {}
        for _, index in ipairs(pot.eligible) do
            local seat = session.seats[index]
            local cards = {}
            for _, card in ipairs(seat.cards) do table.insert(cards, card) end
            for _, card in ipairs(session.community) do table.insert(cards, card) end
            local value = PZLinuxPokerEvaluateHand(cards)
            seat.handValue = value
            local cmp = best and PZLinuxPokerCompareHands(value, best) or 1
            if cmp > 0 then
                best = value
                winners = { index }
            elseif cmp == 0 then
                table.insert(winners, index)
            end
        end
        local share = math.floor(pot.amount / #winners)
        local remainder = pot.amount - share * #winners
        for winnerOrder, index in ipairs(winners) do
            local win = share
            if winnerOrder <= remainder then win = win + 1 end
            session.seats[index].stack = session.seats[index].stack + win
            PZLinuxPokerSetLastAction(session, session.seats[index], "WIN $" .. tostring(win), "win")
            payouts[index] = (payouts[index] or 0) + win
        end
    end
    for index, amount in pairs(payouts) do
        PZLinuxPokerAddHistory(session, session.seats[index].name .. " wins $" .. tostring(amount))
    end
end

local function PZLinuxPokerFinishHand(session, requestId)
    local contenders = PZLinuxPokerHandContenders(session)
    local potBeforePayout = PZLinuxPokerCommittedTotal(session)
    local contenderLabels = {}
    for index, seatIndex in ipairs(contenders) do contenderLabels[index] = tostring(seatIndex) end
    if #contenders == 1 then
        local winner = session.seats[contenders[1]]
        local pot = 0
        for _, seat in ipairs(session.seats) do pot = pot + (seat.committed or 0) end
        winner.stack = winner.stack + pot
        PZLinuxPokerSetLastAction(session, winner, "WIN $" .. tostring(pot), "win")
        session.pots = { { amount = pot, eligible = contenders } }
        PZLinuxPokerAddHistory(session, winner.name .. " wins $" .. tostring(pot))
    else
        session.showdown = true
        PZLinuxPokerResolvePots(session)
    end

    for _, seat in ipairs(session.seats) do
        if seat.stack <= 0 then
            seat.eliminated = true
            seat.state = "eliminated"
        else
            seat.state = "active"
        end
    end

    local active = PZLinuxPokerActivePlayers(session)
    if session.seats[1].eliminated then
        session.status = "lost"
        session.phase = "finished"
    elseif #active == 1 and active[1] == 1 then
        session.status = "won"
        session.phase = "finished"
    else
        session.phase = "hand_complete"
        session.awaitingPlayer = true
    end
    PZLinuxPokerLog("HAND END", {
        player = session.playerKey,
        requestId = requestId,
        session = session.sessionId,
        lobby = session.lobbyId,
        hand = session.handNumber,
        phase = session.phase,
        status = session.status,
        potBefore = potBeforePayout,
        potAfter = PZLinuxPokerCommittedTotal(session),
        contenders = table.concat(contenderLabels, ","),
        activeSeats = #active,
        communityCards = #(session.community or {}),
    })
end

local function PZLinuxPokerAdvancePhase(session, requestId)
    if session.phase == "preflop" then
        PZLinuxPokerDealCommunity(session, 3)
        PZLinuxPokerOpenBettingRound(session, "flop", requestId)
    elseif session.phase == "flop" then
        PZLinuxPokerDealCommunity(session, 1)
        PZLinuxPokerOpenBettingRound(session, "turn", requestId)
    elseif session.phase == "turn" then
        PZLinuxPokerDealCommunity(session, 1)
        PZLinuxPokerOpenBettingRound(session, "river", requestId)
    else
        PZLinuxPokerFinishHand(session, requestId)
    end
end

local function PZLinuxPokerRollbackFailedOpen(playerObj, playerKey, createdSession, buyIn, requestId, errorMessage)
    if createdSession and PZLinux.Poker.Sessions[playerKey] == createdSession then
        PZLinux.Poker.Sessions[playerKey] = nil
    end
    PZLinuxClearInterruptedSession(playerObj, "poker")

    local credit = PZLinuxApplyBankCredit(playerObj, buyIn, "poker-buyin-rollback", requestId)
    print(string.format(
        "[PZLinux Poker] JOIN ROLLBACK player=%s requestId=%s session=%s buyIn=%d refunded=%d error=%s",
        tostring(playerKey), tostring(requestId), tostring(createdSession and createdSession.sessionId),
        buyIn, credit and credit.amount or 0, tostring(errorMessage)))

    return {
        ok = false,
        error = "poker_setup_failed",
        requestId = requestId,
        buyIn = buyIn,
        refunded = credit and credit.amount or 0,
        balance = credit and credit.balance or PZLinuxLoadBankBalance(playerObj),
    }
end

-- Shared hand-strength helper, available to every registered AI engine.
-- Deliberately crude: a five-card evaluation scaled to 0..1 once the board
-- allows one, and a preflop heuristic before that.
function PZLinuxPokerSeatStrength(session, seat)
    local cards = {}
    for _, card in ipairs(seat.cards or {}) do table.insert(cards, card) end
    for _, card in ipairs(session.community or {}) do table.insert(cards, card) end
    if #cards >= 5 then
        return (PZLinuxPokerEvaluateHand(cards).rank or 0) / 9
    end
    local high = math.max(seat.cards[1].value, seat.cards[2].value)
    local pair = seat.cards[1].value == seat.cards[2].value
    local suited = seat.cards[1].suit == seat.cards[2].suit
    local score = high / 14 * 0.45
    if pair then score = score + 0.35 end
    if suited then score = score + 0.08 end
    if math.abs(seat.cards[1].value - seat.cards[2].value) <= 2 then score = score + 0.08 end
    return math.min(1, score)
end

-- Every chip an AI moves, moves here. Engines only return an intent, so a
-- badly written or third-party engine can play badly but cannot corrupt a
-- stack, a pot or the raise bookkeeping. Anything unrecognised or illegal for
-- the current state degrades to fold when chips are owed, and check when the
-- seat can stay in for free.
local function PZLinuxPokerAIFold(session, seat)
    seat.folded = true
    seat.acted = true
    seat.state = "folded"
    PZLinuxPokerSetLastAction(session, seat, "FOLD", "fold")
    PZLinuxPokerAddHistory(session, seat.name .. " folds")
end

local function PZLinuxPokerAICheckOrCall(session, seat, toCall)
    local paid = math.min(seat.stack, toCall)
    seat.stack = seat.stack - paid
    seat.bet = seat.bet + paid
    seat.committed = seat.committed + paid
    seat.acted = true
    if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
    if paid > 0 then
        PZLinuxPokerSetLastAction(session, seat, seat.allIn and "ALL-IN" or ("CALL $" .. tostring(paid)), "call")
        PZLinuxPokerAddHistory(session, seat.name .. " calls $" .. tostring(paid))
    else
        PZLinuxPokerSetLastAction(session, seat, "CHECK", "check")
        PZLinuxPokerAddHistory(session, seat.name .. " checks")
    end
end

local function PZLinuxPokerApplyAIDecision(session, seatIndex, decision, requestId, engine, fallbackReason)
    local seat = session.seats[seatIndex]
    local before = PZLinuxPokerActionState(session, seat)
    local toCall = math.max(0, session.currentBet - seat.bet)
    local action = type(decision) == "table" and string.lower(tostring(decision.action or "")) or ""
    local requestedAmount = type(decision) == "table" and decision.amount or nil

    local function finish(result, fallback)
        PZLinuxPokerLogActionResult(session, seatIndex, "ai", action, requestedAmount, requestId, before, {
            engine = engine and engine.id or seat.aiEngine,
            fallback = fallback or fallbackReason,
            result = result,
        })
    end

    if action == "fold" then
        if toCall > 0 then
            PZLinuxPokerAIFold(session, seat)
            finish("accepted", nil)
        else
            PZLinuxPokerAICheckOrCall(session, seat, toCall)
            finish("normalized", "free_fold_to_check")
        end
        return
    end

    if action == "check" then
        if toCall == 0 then
            PZLinuxPokerAICheckOrCall(session, seat, toCall)
            finish("accepted", nil)
        else
            PZLinuxPokerAIFold(session, seat)
            finish("normalized", "illegal_check_to_fold")
        end
        return
    end

    if action ~= "call" and action ~= "raise" then
        if toCall > 0 then
            PZLinuxPokerAIFold(session, seat)
        else
            PZLinuxPokerAICheckOrCall(session, seat, toCall)
        end
        finish("normalized", fallbackReason or "invalid_decision")
        return
    end

    if action == "raise" then
        local requestedRaiseAmount = math.floor(tonumber(decision.amount) or 0)
        local raiseAmount = requestedRaiseAmount
        raiseAmount = math.min(seat.stack, math.max(raiseAmount, toCall + session.minRaise))
        if raiseAmount > toCall then
            seat.stack = seat.stack - raiseAmount
            seat.bet = seat.bet + raiseAmount
            seat.committed = seat.committed + raiseAmount
            session.currentBet = seat.bet
            session.minRaise = math.max(session.minRaise, raiseAmount - toCall)
            seat.acted = true
            if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
            PZLinuxPokerSetLastAction(session, seat, seat.allIn and "ALL-IN" or ("RAISE $" .. tostring(raiseAmount)), "raise")
            PZLinuxPokerAddHistory(session, seat.name .. " raises $" .. tostring(raiseAmount))
            finish(raiseAmount == requestedRaiseAmount and "accepted" or "clamped", nil)
            return
        end
        -- Not enough chips behind for a legal raise: fall through and call.
        fallbackReason = fallbackReason or "raise_to_call"
    end

    PZLinuxPokerAICheckOrCall(session, seat, toCall)
    if action == "call" and toCall <= 0 then
        finish("normalized", "free_call_to_check")
    else
        finish(action == "call" and "accepted" or "normalized", action == "call" and nil or fallbackReason)
    end
end

-- Builds the read-only view of the table an engine gets, asks the seat's
-- engine what it wants to do, and hands the answer to the applier above.
-- Seats whose engine is missing (a mod that added it was removed
-- mid-session) fall back to the registry default rather than freezing the
-- table.
-- Engines get a copy of the table, never the table itself.
--
-- Lua hands tables over by reference, so before this existed an engine could
-- simply write to what it was given: add 5000 to its own stack, swap its hole
-- cards for aces, rewrite a community card, all while returning a perfectly
-- legal action for the applier to approve. The applier validates the decision
-- an engine returns; it cannot see damage done before the return.
--
-- So decide() receives this instead. Anything an engine writes lands on a
-- throwaway and is collected with it. Seeing everything, including opponents'
-- hole cards, remains deliberate -- a bot that peeks is a feature here, and a
-- shady one fits the mod. Changing what it sees is not.
--
-- The undealt deck is the one thing withheld. Reading it is not peeking, it
-- is knowing every future card, which no tell could ever betray to a player.
local function PZLinuxPokerCopyEngineSeat(seat)
    local copy = {}
    for key, value in pairs(seat) do
        -- Scalars copy by value; the tables worth exposing are rebuilt below,
        -- and aiMemory is deliberately left out -- see context.memory.
        if type(value) ~= "table" and type(value) ~= "function" then
            copy[key] = value
        end
    end
    copy.cards = PZLinuxPokerCopyCards(seat.cards, false)
    copy.aiParams = PZLinuxPokerCopyEngineParams(seat.aiParams)
    if seat.handValue then
        local kickers = {}
        for index, value in ipairs(seat.handValue.kickers or {}) do kickers[index] = value end
        copy.handValue = { rank = seat.handValue.rank, name = seat.handValue.name, kickers = kickers }
    end
    return copy
end

function PZLinuxPokerBuildEngineView(session)
    local seats = {}
    for index, seat in ipairs(session.seats or {}) do
        seats[index] = PZLinuxPokerCopyEngineSeat(seat)
    end
    local pots = {}
    for index, pot in ipairs(session.pots or {}) do
        local eligible = {}
        for order, seatIndex in ipairs(pot.eligible or {}) do eligible[order] = seatIndex end
        pots[index] = { amount = pot.amount, eligible = eligible }
    end
    local history = {}
    for index, line in ipairs(session.history or {}) do history[index] = line end
    return {
        phase = session.phase,
        handNumber = session.handNumber,
        lobbyId = session.lobbyId,
        smallBlind = session.smallBlind,
        bigBlind = session.bigBlind,
        currentBet = session.currentBet,
        minRaise = session.minRaise,
        dealer = session.dealer,
        turn = session.turn,
        showdown = session.showdown,
        community = PZLinuxPokerCopyCards(session.community, false),
        seats = seats,
        pots = pots,
        history = history,
    }
end

local PZLINUX_POKER_CREATE_SEAT_PROTECTED_FIELDS = {
    name = true,
    stack = true,
    isHuman = true,
    aiEngine = true,
    aiParams = true,
    aiMemory = true,
    cards = true,
    bet = true,
    committed = true,
    folded = true,
    allIn = true,
    acted = true,
    handValue = true,
    lastAction = true,
    lastActionKind = true,
    lastActionPhase = true,
    inHand = true,
    state = true,
    eliminated = true,
    deck = true,
    community = true,
    pots = true,
    history = true,
}

local function PZLinuxPokerCopyAISetupValue(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, nested in pairs(value) do
        if type(nested) ~= "function" then
            copy[key] = PZLinuxPokerCopyAISetupValue(nested, seen)
        end
    end
    return copy
end

local function PZLinuxPokerBuildAISetupSessionView(session)
    local view = {}
    for key, value in pairs(session or {}) do
        if type(value) ~= "table" and type(value) ~= "function" then
            view[key] = value
        end
    end
    view.seats = {}
    for index, seat in ipairs((session and session.seats) or {}) do
        view.seats[index] = PZLinuxPokerCopyEngineSeat(seat)
    end
    view.community = PZLinuxPokerCopyCards(session and session.community, false)
    view.pots = {}
    for index, pot in ipairs((session and session.pots) or {}) do
        local eligible = {}
        for order, seatIndex in ipairs(pot.eligible or {}) do eligible[order] = seatIndex end
        view.pots[index] = { amount = pot.amount, eligible = eligible }
    end
    view.history = {}
    for index, line in ipairs((session and session.history) or {}) do view.history[index] = line end
    return view
end

local function PZLinuxPokerApplyAISeatSetup(liveSeat, setupSeat)
    for key, value in pairs(setupSeat or {}) do
        if not PZLINUX_POKER_CREATE_SEAT_PROTECTED_FIELDS[key] and type(value) ~= "function" then
            liveSeat[key] = PZLinuxPokerCopyAISetupValue(value)
        end
    end
end

function PZLinuxPokerConfigureAISeat(engine, seat, lobby, session)
    if not seat or not engine or type(engine.createSeat) ~= "function" then return end
    local setupSeat = PZLinuxPokerCopyEngineSeat(seat)
    local setupLobby = type(lobby) == "table" and PZLinuxPokerCopyEngineParams(lobby) or lobby
    engine:createSeat(setupSeat, setupLobby, {
        session = PZLinuxPokerBuildAISetupSessionView(session),
        seat = setupSeat,
        lobby = setupLobby,
        params = PZLinuxPokerCopyEngineParams(seat.aiParams),
        random = PZLinuxPokerRandom,
        randomRange = PZLinuxPokerRandomRange,
    })
    PZLinuxPokerApplyAISeatSetup(seat, setupSeat)
end

local function PZLinuxPokerAIAct(session, seatIndex, requestId)
    local seat = session.seats[seatIndex]
    local engine = PZLinuxPokerGetAI(seat.aiEngine) or PZLinuxPokerGetFallbackAI()
    local toCall = math.max(0, session.currentBet - seat.bet)
    local pot = PZLinuxPokerCommittedTotal(session)

    local decision
    local fallbackReason = nil
    if engine then
        local view = PZLinuxPokerBuildEngineView(session)
        -- The one surface an engine may legitimately write to and have the
        -- writes survive: a scratch table of its own, per seat, for things
        -- like an opponent model built up over a session. It holds no chips
        -- and no cards, so nothing an engine puts here can move money.
        seat.aiMemory = seat.aiMemory or {}
        local ok, result = pcall(function()
            return engine:decide({
                session = view,
                seat = view.seats[seatIndex],
                memory = seat.aiMemory,
                seatIndex = seatIndex,
                toCall = toCall,
                pot = pot,
                potOdds = toCall > 0 and (toCall / math.max(1, pot + toCall)) or 0,
                currentBet = session.currentBet,
                minRaise = session.minRaise,
                bigBlind = session.bigBlind,
                strength = PZLinuxPokerSeatStrength(session, seat),
                -- Real hand odds, on request and at the engine's own sample
                -- budget: the simulation is the expensive part of a decision, so
                -- an engine that does not ask never pays for it. Results are
                -- cached per seat per board state, so asking twice in one
                -- decision is free.
                equity = function(simulationCount)
                    return PZLinuxPokerEstimateEquityForSeat(session, seatIndex, simulationCount)
                end,
                params = view.seats[seatIndex] and view.seats[seatIndex].aiParams or {},
                random = PZLinuxPokerRandom,
                randomRange = PZLinuxPokerRandomRange,
            })
        end)
        if ok then
            decision = result
        else
            fallbackReason = "decide_error"
            print(string.format(
                "[PZLinux Poker] AI ERROR player=%s requestId=%s session=%s hand=%s phase=%s seat=%s engine=%s: %s; falling back to invalid-decision fold/check",
                tostring(session.playerKey), tostring(requestId), tostring(session.sessionId),
                tostring(session.handNumber), tostring(session.phase), tostring(seatIndex),
                tostring(engine.id or seat.aiEngine or "unknown"), tostring(result)))
        end
    end

    PZLinuxPokerApplyAIDecision(session, seatIndex, decision, requestId, engine, fallbackReason)
end

local function PZLinuxPokerRunAIUntilPlayer(session, requestId)
    local guard = 0
    while session.phase ~= "finished" and session.phase ~= "hand_complete" and PZLinuxPokerNeedMoreActions(session) and guard < 128 do
        guard = guard + 1
        local turnSeat = session.seats[session.turn]
        local canAct = turnSeat and turnSeat.inHand and not turnSeat.folded and not turnSeat.allIn and not turnSeat.eliminated
        if session.turn == 1 and canAct then
            session.awaitingPlayer = true
            return
        end
        if canAct then
            PZLinuxPokerAIAct(session, session.turn, requestId)
        end
        if #PZLinuxPokerHandContenders(session) <= 1 then break end
        PZLinuxPokerMoveTurn(session)
    end
    session.awaitingPlayer = false
    if #PZLinuxPokerHandContenders(session) <= 1 or not PZLinuxPokerNeedMoreActions(session) then
        PZLinuxPokerAdvancePhase(session, requestId)
        if session.phase ~= "finished" and session.phase ~= "hand_complete" then
            PZLinuxPokerRunAIUntilPlayer(session, requestId)
        end
    end
end

function PZLinuxPokerStartHand(session, requestId)
    session.handNumber = (session.handNumber or 0) + 1
    session.dealer = PZLinuxPokerNextOccupiedSeat(session, session.dealer or #session.seats)
    session.deck = PZLinuxPokerCreateDeck()
    session.community = {}
    session.pots = {}
    session.showdown = false
    session.currentBet = 0
    session.minRaise = session.bigBlind
    session.awaitingPlayer = false
    session.equityCache = nil
    for _, seat in ipairs(session.seats) do
        seat.cards = {}
        seat.bet = 0
        seat.committed = 0
        seat.folded = false
        seat.allIn = false
        seat.acted = false
        seat.handValue = nil
        PZLinuxPokerSetLastAction(session, seat, "", "")
        seat.inHand = not seat.eliminated and seat.stack > 0
        seat.state = seat.inHand and "active" or "eliminated"
    end

    session.phase = "preflop"
    local smallBlindSeat = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
    local bigBlindSeat = PZLinuxPokerNextOccupiedSeat(session, smallBlindSeat)
    if #PZLinuxPokerActivePlayers(session) == 2 then
        smallBlindSeat = session.dealer
        bigBlindSeat = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
    end
    PZLinuxPokerPostBlind(session, smallBlindSeat, session.smallBlind, "posts SB", requestId)
    PZLinuxPokerPostBlind(session, bigBlindSeat, session.bigBlind, "posts BB", requestId)

    for _ = 1, 2 do
        for _, seat in ipairs(session.seats) do
            if seat.inHand then
                table.insert(seat.cards, PZLinuxPokerDraw(session.deck))
            end
        end
    end

    session.turn = PZLinuxPokerNextOccupiedSeat(session, bigBlindSeat)
    for _, seat in ipairs(session.seats) do
        seat.acted = seat.folded or seat.allIn or seat.eliminated or not seat.inHand
    end
    PZLinuxPokerAddHistory(session, "Hand #" .. tostring(session.handNumber))
    PZLinuxPokerLog("HAND START", {
        player = session.playerKey,
        requestId = requestId,
        session = session.sessionId,
        lobby = session.lobbyId,
        hand = session.handNumber,
        phase = session.phase,
        dealer = session.dealer,
        smallBlindSeat = smallBlindSeat,
        bigBlindSeat = bigBlindSeat,
        smallBlind = session.smallBlind,
        bigBlind = session.bigBlind,
        activeSeats = #PZLinuxPokerActivePlayers(session),
        potAfter = PZLinuxPokerCommittedTotal(session),
        communityCards = #(session.community or {}),
    })
    PZLinuxPokerRunAIUntilPlayer(session, requestId)
end

function PZLinuxPokerBuildSnapshot(session)
    if not session then return nil end
    local playerCards = {}
    for _, card in ipairs((session.seats[1] and session.seats[1].cards) or {}) do table.insert(playerCards, card) end
    for _, card in ipairs(session.community or {}) do table.insert(playerCards, card) end
    local playerHand = #playerCards > 0 and PZLinuxPokerEvaluateHand(playerCards) or nil
    local playerEquity = PZLinuxPokerEstimateEquity(session, PZLinux.Poker.Config.equitySimulationCount)
    local seats = {}
    for index, seat in ipairs(session.seats or {}) do
        local reveal = index == 1 or session.showdown or session.phase == "finished" or session.phase == "hand_complete"
        table.insert(seats, {
            index = index,
            name = seat.name,
            stack = seat.stack,
            bet = seat.bet,
            committed = seat.committed,
            lastAction = seat.lastAction,
            state = seat.state,
            isHuman = seat.isHuman,
            dealer = index == session.dealer,
            turn = index == session.turn,
            cards = PZLinuxPokerCopyCards(seat.cards, not reveal),
            hand = index == 1 and playerHand and playerHand.name or (seat.handValue and seat.handValue.name or nil),
        })
    end
    return {
        ok = true,
        sessionId = session.sessionId,
        saveVersion = PZLinux.Poker.SaveVersion,
        status = session.status,
        phase = session.phase,
        lobbyId = session.lobbyId,
        smallBlind = session.smallBlind,
        bigBlind = session.bigBlind,
        buyIn = session.buyIn,
        balance = session.balance,
        community = PZLinuxPokerCopyCards(session.community, false),
        seats = seats,
        showdown = session.showdown,
        legalActions = PZLinuxPokerLegalActions(session),
        history = session.history or {},
        handNumber = session.handNumber,
        awaitingPlayer = session.awaitingPlayer,
        playerHand = playerHand and playerHand.name or nil,
        playerEquity = playerEquity,
        equitySamples = playerEquity and PZLinux.Poker.Config.equitySimulationCount or nil,
    }
end

-- Belt and suspenders (v1.0.9), found while auditing for the same bug
-- class as the Hacking exploit fixed just above in this same release: this
-- used to overwrite PZLinux.Poker.Sessions[playerKey] unconditionally, with
-- no check for an existing, still-active table. A player already seated
-- with real chips at risk (won hands, stack above their buy-in) who
-- somehow triggers another
-- "join table" -- a stale lobby-select screen still reachable without
-- properly leaving the current table, a double click, a UI desync -- would
-- have their entire current stack silently discarded (not refunded, not
-- credited anywhere) the instant the new session overwrote the old one in
-- memory. A genuine money-LOSS bug, the mirror image of the Hacking
-- exploit, but the same root mistake: state that can be silently replaced
-- instead of requiring the player to resolve it first.
function PZLinuxPokerCreateSession(player, lobbyId, buyIn, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local existingSession = PZLinuxPokerGetSession(playerObj)
    if existingSession then
        return { ok = false, error = "session_already_active", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local lobby = PZLinuxPokerGetLobby(lobbyId)
    if not lobby then return { ok = false, error = "invalid_lobby", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) } end
    buyIn = PZLinuxNormalizeMoney(buyIn)
    local minBuyIn, maxBuyIn = PZLinuxPokerGetBuyInLimits(lobby)
    if buyIn < minBuyIn or buyIn > maxBuyIn then
        return { ok = false, error = "invalid_buyin", minBuyIn = minBuyIn, maxBuyIn = maxBuyIn, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local debit = PZLinuxApplyBankDebit(playerObj, buyIn, "poker-buyin", requestId)
    if not debit.ok then
        debit.error = debit.error or "not_enough_money"
        debit.minBuyIn = minBuyIn
        debit.maxBuyIn = maxBuyIn
        return debit
    end

    local createdSession = nil
    local openedOk, snapshotOrError = pcall(function()
        local usedNames = {}
        local session = {
            sessionId = PZLinuxNextRequestId("poker-session"),
            playerKey = playerKey,
            lobbyId = lobby.id,
            smallBlind = lobby.smallBlind,
            bigBlind = lobby.bigBlind,
            buyIn = buyIn,
            balance = debit.balance,
            status = "active",
            dealer = 0,
            seats = {
                { name = "You", stack = buyIn, isHuman = true, difficulty = 0 },
            },
            history = {},
        }
        createdSession = session

        local aiMin = (PZLinux.Poker.Config.aiStackMinBigBlinds or 50) * lobby.bigBlind
        local aiMax = (PZLinux.Poker.Config.aiStackMaxBigBlinds or 100) * lobby.bigBlind
        for _ = 1, PZLinux.Poker.Config.opponentCount or 6 do
            local entry = PZLinuxPokerPickAIEngineEntry(lobby, PZLinuxPokerRandom)
            local engine = PZLinuxPokerGetAI(entry and entry.id)
            local seat = {
                name = PZLinuxPokerGenerateAIName(usedNames),
                stack = PZLinuxPokerRandomRange(aiMin, aiMax + 1),
                isHuman = false,
                aiEngine = entry and entry.id or nil,
                -- Resolved once, here: missing and malformed params fall back to
                -- the engine's declared defaults, and the result is this seat's
                -- own copy rather than a reference into shared lobby config.
                aiParams = PZLinuxPokerResolveEngineParams(engine, entry and entry.params),
            }
            PZLinuxPokerConfigureAISeat(engine, seat, lobby, session)
            -- Kept populated for engines that do not use a skill level: the
            -- field predates the registry and existing tools read it.
            seat.difficulty = tonumber(seat.difficulty) or 3
            table.insert(session.seats, seat)
        end
        PZLinux.Poker.Sessions[session.playerKey] = session
        PZLinuxRegisterInterruptedSession(playerObj, "poker", { sessionId = session.sessionId, stack = buyIn, buyIn = buyIn, requestId = requestId })
        print(string.format(
            "[PZLinux Poker] JOIN player=%s requestId=%s session=%s lobby=%s buyIn=%d balance=%d",
            tostring(session.playerKey), tostring(requestId), tostring(session.sessionId),
            tostring(lobby.id), buyIn, PZLinuxLoadBankBalance(playerObj)))
        PZLinuxPokerStartHand(session, requestId)
        local snapshot = PZLinuxPokerBuildSnapshot(session)
        snapshot.requestId = requestId
        return snapshot
    end)

    if not openedOk then
        return PZLinuxPokerRollbackFailedOpen(playerObj, playerKey, createdSession, buyIn, requestId, snapshotOrError)
    end

    return snapshotOrError
end

-- Companion to the session_already_active guard above: lets a client that
-- lost track of its own active table (see PZLinuxBettingUI:onSelectBet /
-- showPokerLobby) get back to it -- and see its real stack -- instead of
-- being stuck looking at a rejected join attempt with no way forward
-- short of reconnecting.
function PZLinuxPokerRestoreSession(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local session = PZLinuxPokerGetSession(playerObj)
    if not session then
        return { ok = false, error = "no_active_session", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local snapshot = PZLinuxPokerBuildSnapshot(session)
    snapshot.requestId = requestId
    return snapshot
end

function PZLinuxPokerGetSession(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return nil end
    return PZLinux.Poker.Sessions[PZLinuxGetPlayerKey(playerObj)]
end

function PZLinuxPokerSyncInterruptedSession(player, session)
    if session and session.status == "active" then
        PZLinuxRegisterInterruptedSession(player, "poker", { sessionId = session.sessionId, stack = session.seats[1].stack, buyIn = session.buyIn })
    end
end

function PZLinuxPokerAction(player, action, amount, sessionId, requestId)
    local session = PZLinuxPokerGetSession(player)
    if not session or session.sessionId ~= sessionId then
        PZLinuxPokerLogActionRejected(player, session, action, amount, requestId, "invalid_session", nil, sessionId)
        return { ok = false, error = "invalid_session", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if session.phase == "hand_complete" and action == "next" then
        PZLinuxPokerLog("HAND NEXT", {
            player = session.playerKey,
            requestId = requestId,
            session = session.sessionId,
            lobby = session.lobbyId,
            hand = session.handNumber,
            phase = session.phase,
            actor = "player",
            seat = 1,
        })
        PZLinuxPokerStartHand(session, requestId)
        PZLinuxPokerSyncInterruptedSession(player, session)
        local snapshot = PZLinuxPokerBuildSnapshot(session)
        snapshot.requestId = requestId
        return snapshot
    end
    if session.phase == "finished" then
        local snapshot = PZLinuxPokerBuildSnapshot(session)
        snapshot.requestId = requestId
        return snapshot
    end
    if not session.awaitingPlayer or session.turn ~= 1 then
        PZLinuxPokerLogActionRejected(player, session, action, amount, requestId, "not_your_turn", nil)
        return { ok = false, error = "not_your_turn", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    local seat = session.seats[1]
    local legal = PZLinuxPokerLegalActions(session)
    local toCall = legal.toCall or 0
    amount = PZLinuxNormalizeMoney(amount)
    local playerBefore = PZLinuxPokerActionState(session, seat)
    if action == "fold" and legal.fold then
        seat.folded = true
        seat.acted = true
        seat.state = "folded"
        PZLinuxPokerSetLastAction(session, seat, "FOLD", "fold")
        PZLinuxPokerAddHistory(session, "You fold")
    elseif action == "check" and legal.check then
        seat.acted = true
        PZLinuxPokerSetLastAction(session, seat, "CHECK", "check")
        PZLinuxPokerAddHistory(session, "You check")
    elseif action == "call" and legal.call then
        local paid = math.min(seat.stack, toCall)
        seat.stack = seat.stack - paid
        seat.bet = seat.bet + paid
        seat.committed = seat.committed + paid
        seat.acted = true
        if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
        PZLinuxPokerSetLastAction(session, seat, seat.allIn and "ALL-IN" or ("CALL $" .. tostring(paid)), "call")
        PZLinuxPokerAddHistory(session, "You call $" .. tostring(paid))
    elseif (action == "bet" or action == "raise") and (legal.bet or legal.raise) then
        local minAmount = legal.minBet or session.bigBlind
        if amount < minAmount or amount > seat.stack then
            PZLinuxPokerLogActionRejected(player, session, action, amount, requestId, "invalid_amount", legal)
            return { ok = false, error = "invalid_amount", requestId = requestId, legalActions = legal, balance = PZLinuxLoadBankBalance(player) }
        end
        seat.stack = seat.stack - amount
        seat.bet = seat.bet + amount
        seat.committed = seat.committed + amount
        session.minRaise = math.max(session.minRaise, seat.bet - session.currentBet)
        session.currentBet = seat.bet
        seat.acted = true
        if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
        PZLinuxPokerSetLastAction(session, seat, seat.allIn and "ALL-IN" or (string.upper(action) .. " $" .. tostring(amount)), "raise")
        PZLinuxPokerAddHistory(session, "You " .. action .. " $" .. tostring(amount))
    elseif action == "allin" and legal.allin then
        local allin = seat.stack
        seat.stack = 0
        seat.bet = seat.bet + allin
        seat.committed = seat.committed + allin
        if seat.bet > session.currentBet then
            session.minRaise = math.max(session.minRaise, seat.bet - session.currentBet)
            session.currentBet = seat.bet
        end
        seat.allIn = true
        seat.state = "allin"
        seat.acted = true
        PZLinuxPokerSetLastAction(session, seat, "ALL-IN", allin > toCall and "raise" or "call")
        PZLinuxPokerAddHistory(session, "You all-in $" .. tostring(allin))
    else
        PZLinuxPokerLogActionRejected(player, session, action, amount, requestId, "illegal_action", legal)
        return { ok = false, error = "illegal_action", requestId = requestId, legalActions = legal, balance = PZLinuxLoadBankBalance(player) }
    end

    PZLinuxPokerLogActionResult(session, 1, "player", action, amount, requestId, playerBefore, { result = "accepted" })
    session.awaitingPlayer = false
    if #PZLinuxPokerHandContenders(session) <= 1 then
        PZLinuxPokerFinishHand(session, requestId)
    else
        PZLinuxPokerMoveTurn(session)
        PZLinuxPokerRunAIUntilPlayer(session, requestId)
    end
    PZLinuxPokerSyncInterruptedSession(player, session)
    local snapshot = PZLinuxPokerBuildSnapshot(session)
    if session.phase == "finished" then
        snapshot.balance = PZLinuxPokerSettleFinished(player, session, requestId)
    end
    snapshot.requestId = requestId
    return snapshot
end

function PZLinuxPokerCashOut(player, sessionId, requestId)
    local session = PZLinuxPokerGetSession(player)
    if not session or session.sessionId ~= sessionId then
        return { ok = false, error = "invalid_session", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    local playerObj = PZLinuxGetPlayer(player)
    local refund = PZLinuxNormalizeMoney(session.seats[1].stack)
    PZLinux.Poker.Sessions[session.playerKey] = nil
    PZLinuxClearInterruptedSession(playerObj, "poker")
    local credit = nil
    if refund > 0 then
        credit = PZLinuxApplyBankCredit(playerObj, refund, "poker-cashout", requestId)
    end
    print(string.format(
        "[PZLinux Poker] CASHOUT player=%s requestId=%s session=%s buyIn=%d refund=%d net=%d balance=%d",
        tostring(session.playerKey), tostring(requestId), tostring(sessionId), session.buyIn, refund, refund - session.buyIn,
        credit and credit.balance or PZLinuxLoadBankBalance(playerObj)))
    return {
        ok = true,
        requestId = requestId,
        sessionId = sessionId,
        status = "closed",
        buyIn = session.buyIn,
        refund = refund,
        net = refund - session.buyIn,
        balance = credit and credit.balance or PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxPokerSettleFinished(player, session, requestId)
    if not session or session.phase ~= "finished" then return nil end
    local playerObj = PZLinuxGetPlayer(player)
    local finalStack = PZLinuxNormalizeMoney(session.seats[1].stack)
    PZLinux.Poker.Sessions[session.playerKey] = nil
    PZLinuxClearInterruptedSession(playerObj, "poker")
    local credit = nil
    if session.status == "won" and finalStack > 0 then
        credit = PZLinuxApplyBankCredit(playerObj, finalStack, "poker-win", requestId)
    end
    print(string.format(
        "[PZLinux Poker] TABLE FINISHED player=%s requestId=%s session=%s hand=%s buyIn=%d status=%s finalStack=%d balance=%d",
        tostring(session.playerKey), tostring(requestId), tostring(session.sessionId),
        tostring(session.handNumber), session.buyIn, tostring(session.status), finalStack,
        credit and credit.balance or PZLinuxLoadBankBalance(playerObj)))
    return credit and credit.balance or PZLinuxLoadBankBalance(playerObj)
end
