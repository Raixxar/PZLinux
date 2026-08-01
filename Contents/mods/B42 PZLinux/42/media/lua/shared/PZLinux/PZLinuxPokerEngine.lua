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

local function PZLinuxPokerCreateOrderedDeck()
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

local function PZLinuxPokerEquityStateKey(session)
    local parts = { tostring(session.handNumber or 0), tostring(session.phase or "") }
    for _, card in ipairs((session.seats[1] and session.seats[1].cards) or {}) do
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

function PZLinuxPokerEstimateEquity(session, simulationCount)
    local playerSeat = session and session.seats and session.seats[1]
    if not playerSeat or not playerSeat.inHand or playerSeat.folded or #(playerSeat.cards or {}) ~= 2 then return nil end
    if session.phase == "finished" or session.phase == "hand_complete" then return nil end

    local opponentCount = 0
    for index, seat in ipairs(session.seats or {}) do
        if index ~= 1 and seat.inHand and not seat.folded then opponentCount = opponentCount + 1 end
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
    local stateKey = PZLinuxPokerEquityStateKey(session)
    local cache = session.playerEquityCache
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
    session.playerEquityCache = { key = stateKey, samples = simulationCount, equity = equity }
    return equity
end

local function PZLinuxPokerAddHistory(session, text)
    session.history = session.history or {}
    table.insert(session.history, 1, text)
    while #session.history > (PZLinux.Poker.Config.maxActionHistory or 12) do
        table.remove(session.history)
    end
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

local function PZLinuxPokerRandomDifficulty()
    local roll = PZLinuxPokerRandom(100) + 1
    local total = 0
    for level, weight in ipairs(PZLinux.Poker.Config.aiDifficultyWeights or {}) do
        total = total + weight
        if roll <= total then return level end
    end
    return 3
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

local function PZLinuxPokerPostBlind(session, seatIndex, amount, label)
    local seat = session.seats[seatIndex]
    local posted = math.min(seat.stack, amount)
    seat.stack = seat.stack - posted
    seat.bet = seat.bet + posted
    seat.committed = seat.committed + posted
    if seat.stack == 0 then seat.allIn = true end
    seat.lastAction = label == "posts SB" and ("SB $" .. tostring(posted)) or ("BB $" .. tostring(posted))
    session.currentBet = math.max(session.currentBet, seat.bet)
    PZLinuxPokerAddHistory(session, seat.name .. " " .. label .. " $" .. tostring(posted))
end

local function PZLinuxPokerDealCommunity(session, count)
    for _ = 1, count do
        table.insert(session.community, PZLinuxPokerDraw(session.deck))
    end
end

local function PZLinuxPokerOpenBettingRound(session, phase)
    session.phase = phase
    session.currentBet = 0
    session.minRaise = session.bigBlind
    session.awaitingPlayer = false
    for _, seat in ipairs(session.seats) do
        seat.bet = 0
        seat.acted = seat.folded or seat.allIn or seat.eliminated or not seat.inHand
    end
    session.turn = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
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

local function PZLinuxPokerMoveTurn(session)
    local start = session.turn
    repeat
        session.turn = PZLinuxPokerNextOccupiedSeat(session, session.turn)
        local seat = session.seats[session.turn]
        if seat and seat.inHand and not seat.folded and not seat.allIn and not seat.eliminated then
            return
        end
    until session.turn == start
end

local function PZLinuxPokerLegalActions(session)
    local seat = session.seats[1]
    if not session.awaitingPlayer or session.turn ~= 1 or not seat or seat.folded or seat.allIn then
        return {}
    end
    local toCall = math.max(0, session.currentBet - seat.bet)
    local actions = { fold = toCall > 0, check = toCall == 0, call = toCall > 0 and seat.stack > 0, allin = seat.stack > 0 }
    actions.bet = toCall == 0 and seat.stack >= session.bigBlind
    actions.raise = toCall > 0 and seat.stack > toCall
    actions.toCall = toCall
    actions.minBet = session.currentBet == 0 and session.bigBlind or (toCall + session.minRaise)
    actions.maxBet = seat.stack
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
            session.seats[index].lastAction = "WIN $" .. tostring(win)
            payouts[index] = (payouts[index] or 0) + win
        end
    end
    for index, amount in pairs(payouts) do
        PZLinuxPokerAddHistory(session, session.seats[index].name .. " wins $" .. tostring(amount))
    end
end

local function PZLinuxPokerFinishHand(session)
    local contenders = PZLinuxPokerHandContenders(session)
    if #contenders == 1 then
        local winner = session.seats[contenders[1]]
        local pot = 0
        for _, seat in ipairs(session.seats) do pot = pot + (seat.committed or 0) end
        winner.stack = winner.stack + pot
        winner.lastAction = "WIN $" .. tostring(pot)
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
        return
    end
    if #active == 1 and active[1] == 1 then
        session.status = "won"
        session.phase = "finished"
        return
    end
    session.phase = "hand_complete"
    session.awaitingPlayer = true
end

local function PZLinuxPokerAdvancePhase(session)
    if session.phase == "preflop" then
        PZLinuxPokerDealCommunity(session, 3)
        PZLinuxPokerOpenBettingRound(session, "flop")
    elseif session.phase == "flop" then
        PZLinuxPokerDealCommunity(session, 1)
        PZLinuxPokerOpenBettingRound(session, "turn")
    elseif session.phase == "turn" then
        PZLinuxPokerDealCommunity(session, 1)
        PZLinuxPokerOpenBettingRound(session, "river")
    else
        PZLinuxPokerFinishHand(session)
    end
end

local function PZLinuxPokerSeatStrength(session, seat)
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

local function PZLinuxPokerAIAct(session, seatIndex)
    local seat = session.seats[seatIndex]
    local toCall = math.max(0, session.currentBet - seat.bet)
    local strength = PZLinuxPokerSeatStrength(session, seat)
    local difficulty = tonumber(seat.difficulty) or 3
    local noise = (6 - difficulty) * (PZLinuxPokerRandom(30) - 15) / 100
    local bluff = PZLinuxPokerRandom(100) < (PZLinux.Poker.Config.aiBluffChance[difficulty] or 10)
    local confidence = math.max(0, math.min(1, strength + noise + (bluff and 0.18 or 0)))
    local pot = 0
    for _, other in ipairs(session.seats) do pot = pot + (other.committed or 0) end
    local potOdds = toCall > 0 and (toCall / math.max(1, pot + toCall)) or 0

    if toCall > 0 and confidence < potOdds + 0.12 then
        seat.folded = true
        seat.acted = true
        seat.state = "folded"
        seat.lastAction = "FOLD"
        PZLinuxPokerAddHistory(session, seat.name .. " folds")
        return
    end

    local raiseChance = confidence * 100 - 55 + difficulty * 4
    if seat.stack > toCall + session.minRaise and PZLinuxPokerRandom(100) < raiseChance then
        local raiseAmount = math.min(seat.stack, toCall + session.minRaise + PZLinuxPokerRandomRange(0, session.bigBlind + 1))
        seat.stack = seat.stack - raiseAmount
        seat.bet = seat.bet + raiseAmount
        seat.committed = seat.committed + raiseAmount
        session.currentBet = seat.bet
        session.minRaise = math.max(session.minRaise, raiseAmount - toCall)
        seat.acted = true
        if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
        seat.lastAction = seat.allIn and "ALL-IN" or ("RAISE $" .. tostring(raiseAmount))
        PZLinuxPokerAddHistory(session, seat.name .. " raises $" .. tostring(raiseAmount))
        return
    end

    local paid = math.min(seat.stack, toCall)
    seat.stack = seat.stack - paid
    seat.bet = seat.bet + paid
    seat.committed = seat.committed + paid
    seat.acted = true
    if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
    if paid > 0 then
        seat.lastAction = seat.allIn and "ALL-IN" or ("CALL $" .. tostring(paid))
        PZLinuxPokerAddHistory(session, seat.name .. " calls $" .. tostring(paid))
    else
        seat.lastAction = "CHECK"
        PZLinuxPokerAddHistory(session, seat.name .. " checks")
    end
end

local function PZLinuxPokerRunAIUntilPlayer(session)
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
            PZLinuxPokerAIAct(session, session.turn)
        end
        if #PZLinuxPokerHandContenders(session) <= 1 then break end
        PZLinuxPokerMoveTurn(session)
    end
    session.awaitingPlayer = false
    if #PZLinuxPokerHandContenders(session) <= 1 or not PZLinuxPokerNeedMoreActions(session) then
        PZLinuxPokerAdvancePhase(session)
        if session.phase ~= "finished" and session.phase ~= "hand_complete" then
            PZLinuxPokerRunAIUntilPlayer(session)
        end
    end
end

function PZLinuxPokerStartHand(session)
    session.handNumber = (session.handNumber or 0) + 1
    session.dealer = PZLinuxPokerNextOccupiedSeat(session, session.dealer or #session.seats)
    session.deck = PZLinuxPokerCreateDeck()
    session.community = {}
    session.pots = {}
    session.showdown = false
    session.currentBet = 0
    session.minRaise = session.bigBlind
    session.awaitingPlayer = false
    session.playerEquityCache = nil
    for _, seat in ipairs(session.seats) do
        seat.cards = {}
        seat.bet = 0
        seat.committed = 0
        seat.folded = false
        seat.allIn = false
        seat.acted = false
        seat.handValue = nil
        seat.lastAction = ""
        seat.inHand = not seat.eliminated and seat.stack > 0
        seat.state = seat.inHand and "active" or "eliminated"
    end

    local smallBlindSeat = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
    local bigBlindSeat = PZLinuxPokerNextOccupiedSeat(session, smallBlindSeat)
    if #PZLinuxPokerActivePlayers(session) == 2 then
        smallBlindSeat = session.dealer
        bigBlindSeat = PZLinuxPokerNextOccupiedSeat(session, session.dealer)
    end
    PZLinuxPokerPostBlind(session, smallBlindSeat, session.smallBlind, "posts SB")
    PZLinuxPokerPostBlind(session, bigBlindSeat, session.bigBlind, "posts BB")

    for _ = 1, 2 do
        for _, seat in ipairs(session.seats) do
            if seat.inHand then
                table.insert(seat.cards, PZLinuxPokerDraw(session.deck))
            end
        end
    end

    session.phase = "preflop"
    session.turn = PZLinuxPokerNextOccupiedSeat(session, bigBlindSeat)
    for _, seat in ipairs(session.seats) do
        seat.acted = seat.folded or seat.allIn or seat.eliminated or not seat.inHand
    end
    PZLinuxPokerAddHistory(session, "Hand #" .. tostring(session.handNumber))
    PZLinuxPokerRunAIUntilPlayer(session)
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
            difficulty = seat.difficulty,
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

function PZLinuxPokerCreateSession(player, lobbyId, buyIn, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
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

    local usedNames = {}
    local session = {
        sessionId = PZLinuxNextRequestId("poker-session"),
        playerKey = PZLinuxGetPlayerKey(playerObj),
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
    local aiMin = (PZLinux.Poker.Config.aiStackMinBigBlinds or 50) * lobby.bigBlind
    local aiMax = (PZLinux.Poker.Config.aiStackMaxBigBlinds or 100) * lobby.bigBlind
    for _ = 1, PZLinux.Poker.Config.opponentCount or 6 do
        table.insert(session.seats, {
            name = PZLinuxPokerGenerateAIName(usedNames),
            stack = PZLinuxPokerRandomRange(aiMin, aiMax + 1),
            isHuman = false,
            difficulty = PZLinuxPokerRandomDifficulty(),
        })
    end
    PZLinux.Poker.Sessions[session.playerKey] = session
    PZLinuxRegisterInterruptedSession(playerObj, "poker", { sessionId = session.sessionId, stack = buyIn, buyIn = buyIn, requestId = requestId })
    PZLinuxPokerStartHand(session)
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
        return { ok = false, error = "invalid_session", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if session.phase == "hand_complete" and action == "next" then
        PZLinuxPokerStartHand(session)
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
        return { ok = false, error = "not_your_turn", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    local seat = session.seats[1]
    local legal = PZLinuxPokerLegalActions(session)
    local toCall = legal.toCall or 0
    amount = PZLinuxNormalizeMoney(amount)
    if action == "fold" and legal.fold then
        seat.folded = true
        seat.acted = true
        seat.state = "folded"
        seat.lastAction = "FOLD"
        PZLinuxPokerAddHistory(session, "You fold")
    elseif action == "check" and legal.check then
        seat.acted = true
        seat.lastAction = "CHECK"
        PZLinuxPokerAddHistory(session, "You check")
    elseif action == "call" and legal.call then
        local paid = math.min(seat.stack, toCall)
        seat.stack = seat.stack - paid
        seat.bet = seat.bet + paid
        seat.committed = seat.committed + paid
        seat.acted = true
        if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
        seat.lastAction = seat.allIn and "ALL-IN" or ("CALL $" .. tostring(paid))
        PZLinuxPokerAddHistory(session, "You call $" .. tostring(paid))
    elseif (action == "bet" or action == "raise") and (legal.bet or legal.raise) then
        local minAmount = legal.minBet or session.bigBlind
        if amount < minAmount or amount > seat.stack then
            return { ok = false, error = "invalid_amount", requestId = requestId, legalActions = legal, balance = PZLinuxLoadBankBalance(player) }
        end
        seat.stack = seat.stack - amount
        seat.bet = seat.bet + amount
        seat.committed = seat.committed + amount
        session.minRaise = math.max(session.minRaise, seat.bet - session.currentBet)
        session.currentBet = seat.bet
        seat.acted = true
        if seat.stack == 0 then seat.allIn = true seat.state = "allin" end
        seat.lastAction = seat.allIn and "ALL-IN" or (string.upper(action) .. " $" .. tostring(amount))
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
        seat.lastAction = "ALL-IN"
        PZLinuxPokerAddHistory(session, "You all-in $" .. tostring(allin))
    else
        return { ok = false, error = "illegal_action", requestId = requestId, legalActions = legal, balance = PZLinuxLoadBankBalance(player) }
    end

    session.awaitingPlayer = false
    if #PZLinuxPokerHandContenders(session) <= 1 then
        PZLinuxPokerFinishHand(session)
    else
        PZLinuxPokerMoveTurn(session)
        PZLinuxPokerRunAIUntilPlayer(session)
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
    return credit and credit.balance or PZLinuxLoadBankBalance(playerObj)
end
