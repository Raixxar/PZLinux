ZombRand = function(a, b)
    if b then return math.random(a, b - 1) end
    return math.random(0, a - 1)
end

PZLinuxGetPlayer = function(player) return player end
PZLinuxGetPlayerKey = function() return "test" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
PZLinuxLoadBankBalance = function() return 100000 end
PZLinuxApplyBankDebit = function(_, amount) return { ok = true, amount = amount, balance = 100000 - amount } end
PZLinuxApplyBankCredit = function(_, amount) return { ok = true, amount = amount, balance = 100000 + amount } end
PZLinuxNextRequestId = function(prefix) return tostring(prefix) .. "-1" end
PZLinuxRegisterInterruptedSession = function() end
PZLinuxClearInterruptedSession = function() end

-- Local test harness only. Project Zomboid loads the mod with require paths from media/lua.
dofile("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerConfig.lua")
dofile("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerEngine.lua")

local function card(label)
    local rank = label:sub(1, 1)
    local suit = label:sub(2, 2)
    local values = { T = 10, J = 11, Q = 12, K = 13, A = 14 }
    local value = values[rank] or tonumber(rank)
    return { rank = rank, suit = suit, value = value, label = label }
end

local function hand(labels)
    local cards = {}
    for token in labels:gmatch("%S+") do
        table.insert(cards, card(token))
    end
    return PZLinuxPokerEvaluateHand(cards)
end

local function assertName(labels, expected)
    local result = hand(labels)
    assert(result.name == expected, labels .. " expected " .. expected .. " got " .. tostring(result.name))
end

math.randomseed(42)

local deck = PZLinuxPokerCreateDeck()
assert(#deck == 52, "deck must contain 52 cards")
local seen = {}
for _, c in ipairs(deck) do
    assert(not seen[c.label], "duplicate card " .. c.label)
    seen[c.label] = true
end

assertName("AH KH QH JH TH 2C 3D", "royal_flush")
assertName("9H 8H 7H 6H 5H AC KD", "straight_flush")
assertName("AH AD AC AS 2C 3D 4H", "four_kind")
assertName("AH AD AC KC KD 2S 3H", "full_house")
assertName("AH JH 8H 4H 2H KC QD", "flush")
assertName("AH 2D 3C 4S 5H KC QD", "straight")
assertName("AH AD AC KS QD 2C 3H", "three_kind")
assertName("AH AD KC KD QS 2C 3H", "two_pair")
assertName("AH AD KC QS 9D 2C 3H", "pair")
assertName("AH KD QC 9S 7D 4C 2H", "high_card")

local pairAces = hand("AH AD KC QS 9D 2C 3H")
local pairKings = hand("KH KD AC QS 9D 2C 3H")
assert(PZLinuxPokerCompareHands(pairAces, pairKings) > 0, "pair aces should beat pair kings")

local equitySession = {
    handNumber = 1,
    phase = "preflop",
    community = {},
    seats = {
        { inHand = true, folded = false, cards = { card("AH"), card("AD") } },
        { inHand = true, folded = false, cards = {} },
    },
}
local acesEquity = PZLinuxPokerEstimateEquity(equitySession, 1000)
assert(acesEquity > 75 and acesEquity < 95, "pocket aces heads-up equity should be plausible, got " .. tostring(acesEquity))
assert(PZLinuxPokerEstimateEquity(equitySession, 1000) == acesEquity, "equity estimate must be deterministic and cached")

equitySession.phase = "river"
equitySession.community = { card("QH"), card("JH"), card("TH"), card("2C"), card("3D") }
equitySession.seats[1].cards = { card("AH"), card("KH") }
equitySession.playerEquityCache = nil
assert(PZLinuxPokerEstimateEquity(equitySession, 500) == 100, "a private royal flush must have 100 percent equity")

PZLinux.Poker.Sessions = {}
local foldPlayer = {}
local foldSnapshot = PZLinuxPokerCreateSession(foldPlayer, "micro", 150, "fold-start")
assert(foldSnapshot.ok and foldSnapshot.legalActions.fold, "the regression hand must allow the player to fold")
assert(#foldSnapshot.seats == 6, "the Poker table must contain the player and five opponents")
for index = 2, #foldSnapshot.seats do
    assert(foldSnapshot.seats[index].difficulty == nil, "AI difficulty must remain server-only")
end
local foldedResult = PZLinuxPokerAction(foldPlayer, "fold", 0, foldSnapshot.sessionId, "fold-action")
assert(foldedResult.phase == "hand_complete", "AI must finish the hand after the player folds, got " .. tostring(foldedResult.phase))
assert(not foldedResult.legalActions.fold and not foldedResult.legalActions.check, "a folded player must not receive another betting action")
assert(foldedResult.seats[1].lastAction == "FOLD", "the snapshot must expose the player's latest table action")

-- Design goal confirmed with the mod's author: gambling must stay a fun
-- distraction, never a substitute for Contracts as the mod's one reliable
-- income source. The top lobby's max buy-in (100x its big blind) is the
-- most a player can ever bring to a single hand, so it must stay below
-- the single best-paying contract, or a lucky session at the tables could
-- out-earn actually playing the game.
local contractsFile = assert(io.open("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxContractsData.lua", "rb"))
local contractsSource = contractsFile:read("*a")
contractsFile:close()
local bestContractReward = 0
for reward in contractsSource:gmatch("reward%s*=%s*(%d+)") do
    bestContractReward = math.max(bestContractReward, tonumber(reward))
end
assert(bestContractReward > 0, "must find at least one contract reward to compare against")

local highestBigBlind = 0
for _, lobby in ipairs(PZLinux.Poker.Config.lobbies) do
    highestBigBlind = math.max(highestBigBlind, lobby.bigBlind)
end
local _, topMaxBuyIn = PZLinuxPokerGetBuyInLimits({ bigBlind = highestBigBlind })
assert(topMaxBuyIn < bestContractReward,
    string.format(
        "the top Poker lobby's max buy-in ($%d) must stay below the best contract reward ($%d), " ..
        "or gambling can out-earn actually playing",
        topMaxBuyIn, bestContractReward))

-- Regression (v1.0.16): the player shoves all-in, every opponent folds
-- except one who is also all-in for less. Both survivors have stack 0, so
-- PZLinuxPokerNextOccupiedSeat -- which only ever returns a seat holding
-- chips -- could never return the seat the turn started on, and the old
-- "repeat ... until session.turn == start" walk in PZLinuxPokerMoveTurn
-- span forever. In game that is a hard freeze the instant a shove puts a
-- short-stacked opponent all-in for their last chips. The hand below is
-- dealt by hand so the shape is exact rather than fished for with a seed.
PZLinux.Poker.Sessions = {}
local shovePlayer = {}
local shoveSnapshot = PZLinuxPokerCreateSession(shovePlayer, "micro", 150, "shove-start")
assert(shoveSnapshot.ok, "the all-in regression table must open")
local shoveSession = PZLinuxPokerGetSession(shovePlayer)

shoveSession.phase = "preflop"
shoveSession.community = {}
shoveSession.pots = {}
shoveSession.showdown = false
shoveSession.dealer = 1
shoveSession.turn = 1
shoveSession.currentBet = 60
shoveSession.minRaise = shoveSession.bigBlind
shoveSession.awaitingPlayer = true
shoveSession.playerEquityCache = nil
shoveSession.deck = PZLinuxPokerCreateDeck()
for index, seat in ipairs(shoveSession.seats) do
    seat.folded = index ~= 1 and index ~= #shoveSession.seats
    seat.inHand = true
    seat.eliminated = false
    seat.allIn = false
    seat.acted = true
    seat.handValue = nil
    seat.lastAction = ""
    seat.cards = { PZLinuxPokerDraw(shoveSession.deck), PZLinuxPokerDraw(shoveSession.deck) }
    if index == 1 then
        seat.stack = 200
        seat.bet = 0
        seat.committed = 0
        seat.state = "active"
    elseif seat.folded then
        seat.stack = 100
        seat.bet = 0
        seat.committed = 2
        seat.state = "folded"
    else
        -- The short stack: already all-in for less than the player's shove.
        seat.stack = 0
        seat.bet = 60
        seat.committed = 60
        seat.allIn = true
        seat.state = "allin"
    end
end

local shoveResult = PZLinuxPokerAction(shovePlayer, "allin", 0, shoveSession.sessionId, "shove-action")
assert(shoveResult.ok, "the all-in must be accepted, got " .. tostring(shoveResult.error))
assert(shoveResult.phase == "hand_complete" or shoveResult.phase == "finished",
    "an all-in against an all-in short stack must run out to showdown, got " .. tostring(shoveResult.phase))
assert(#shoveResult.community == 5, "the board must be completed for the all-in runout, got " .. tostring(#shoveResult.community))

local shovedChips = 0
for _, seat in ipairs(shoveSession.seats) do shovedChips = shovedChips + seat.stack end
-- 200 behind for the player, 60 already committed by the short stack, and
-- 100 behind plus the 2 posted by each of the folded seats.
assert(shovedChips == 200 + 60 + 102 * (#shoveSession.seats - 2),
    "chips must be conserved across the all-in showdown, got " .. tostring(shovedChips))

-- A short stack facing a bet can still call or shove, but must not be
-- offered a normal raise when they cannot cover the minimum raise amount.
-- The UI builds its buttons from legalActions, so exposing raise=true with
-- minBet > maxBet produced a button that always came back invalid_amount.
PZLinux.Poker.Sessions = {}
local shortRaisePlayer = {}
local shortRaiseSnapshot = PZLinuxPokerCreateSession(shortRaisePlayer, "micro", 150, "short-raise-start")
assert(shortRaiseSnapshot.ok, "the short-stack raise regression table must open")
local shortRaiseSession = PZLinuxPokerGetSession(shortRaisePlayer)
shortRaiseSession.phase = "preflop"
shortRaiseSession.turn = 1
shortRaiseSession.awaitingPlayer = true
shortRaiseSession.currentBet = 60
shortRaiseSession.minRaise = shortRaiseSession.bigBlind
shortRaiseSession.seats[1].stack = shortRaiseSession.bigBlind + 1
shortRaiseSession.seats[1].bet = 60 - shortRaiseSession.bigBlind
shortRaiseSession.seats[1].committed = shortRaiseSession.seats[1].bet
shortRaiseSession.seats[1].folded = false
shortRaiseSession.seats[1].allIn = false
shortRaiseSession.seats[1].inHand = true
shortRaiseSession.seats[1].eliminated = false
local shortRaiseLegal = PZLinuxPokerBuildSnapshot(shortRaiseSession).legalActions
assert(shortRaiseLegal.call, "a short stack facing a call amount must still be able to call")
assert(shortRaiseLegal.allin, "a short stack with chips must still be able to go all-in")
assert(not shortRaiseLegal.raise,
    "raise must be hidden when the minimum raise is larger than the player's stack")
assert(shortRaiseLegal.minBet > shortRaiseLegal.maxBet,
    "the regression fixture must prove min raise is unaffordable")

print("PZLinux poker engine tests OK")
