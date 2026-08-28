-- Tests for the two TEST engines, which exist to measure the others.
--
-- TEST_ZombieHunter sizes its bets against the opponents' fold rule, so it is
-- checked by measuring how often opponents actually fold to it: rarely on the
-- streets where it wants calls, and much more often on the street where it is
-- trying to end the hand.
--
-- TEST_Cheater sees every hole card, so on the river its call/fold is not an
-- estimate and can be asserted against hands dealt on purpose.

math.randomseed(4711)

ZombRand = function(a, b)
    if b then return math.random(a, b - 1) end
    return math.random(0, a - 1)
end

PZLinuxGetPlayer = function(player) return player end
PZLinuxGetPlayerKey = function() return "test" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
PZLinuxLoadBankBalance = function() return 1000000 end
PZLinuxApplyBankDebit = function(_, amount) return { ok = true, amount = amount, balance = 1000000 - amount } end
PZLinuxApplyBankCredit = function(_, amount) return { ok = true, amount = amount, balance = 1000000 + amount } end
PZLinuxNextRequestId = function(prefix) return tostring(prefix) .. "-1" end
PZLinuxRegisterInterruptedSession = function() end
PZLinuxClearInterruptedSession = function() end

local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIRegistry.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerConfig.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAISkill.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIReads.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIZombieBrain.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAITestZombieHunter.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAITestCheater.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerEngine.lua")

for _, id in ipairs({ "test_zombiehunter", "test_cheater" }) do
    local engine = PZLinuxPokerGetAI(id)
    assert(engine, id .. " must register itself on load")
    assert(engine.testOnly, id .. " must be flagged as a test engine")
    assert(engine.name:find("TEST"), id .. " must carry TEST in its display name")
end

local function card(label)
    local rank = label:sub(1, 1)
    local suit = label:sub(2, 2)
    local values = { T = 10, J = 11, Q = 12, K = 13, A = 14 }
    return { rank = rank, suit = suit, value = values[rank] or tonumber(rank), label = label }
end

local function cards(labels)
    local list = {}
    for token in labels:gmatch("%S+") do table.insert(list, card(token)) end
    return list
end

-- ------------------------------------------------------ TEST_ZombieHunter

-- The sizing is the whole engine, so check the arithmetic it is built on:
-- the bet it chooses must produce the pot odds it was aiming at.
local function hunterContext(phase, pot, stack)
    local seats = {
        { name = "S1", stack = stack, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "S2", stack = stack, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
    }
    local ctx = {
        session = { handNumber = 1, phase = phase, currentBet = 0, seats = seats, community = {} },
        seat = seats[2], seatIndex = 2,
        toCall = 0, pot = pot, potOdds = 0, currentBet = 0, minRaise = 10, bigBlind = 10,
        strength = 0.5, memory = {},
        random = function(n) return math.floor(n / 2) end,
        randomRange = function(a) return a end,
        equity = function() error("the ZombieHunter must never ask for equity") end,
    }
    ctx.params = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI("test_zombiehunter"), nil)
    return ctx
end

-- Pot odds an opponent yet to act would face after a bet of `amount`.
local function potOddsFacing(pot, amount)
    return amount / (pot + amount + amount)
end

local keepIn = PZLinuxPokerGetAI("test_zombiehunter"):decide(hunterContext("flop", 100, 100000))
assert(keepIn.action == "raise", "the ZombieHunter must bet to build the pot")
local keepInOdds = potOddsFacing(100, keepIn.amount)
assert(math.abs(keepInOdds - 0.30) < 0.02,
    string.format("the keep-in bet must offer about 0.30 pot odds, offered %.3f", keepInOdds))

local forceFold = PZLinuxPokerGetAI("test_zombiehunter"):decide(hunterContext("river", 100, 100000))
assert(forceFold.action == "raise", "the ZombieHunter must bet on the last street")
local forceFoldOdds = potOddsFacing(100, forceFold.amount)
assert(forceFoldOdds > keepInOdds,
    "the last-street bet must demand a worse price than the earlier ones")
assert(math.abs(forceFoldOdds - 0.45) < 0.02,
    string.format("the force-fold bet must offer about 0.45 pot odds, offered %.3f", forceFoldOdds))

-- A short stack cannot make the bet the maths asks for, so it shoves instead
-- of asking for chips it does not have.
local shortStack = PZLinuxPokerGetAI("test_zombiehunter"):decide(hunterContext("river", 100, 50))
assert(shortStack.amount <= 50, "the ZombieHunter must never bet more than its stack")

-- What it is actually for: opponents must fold to it far more on the last
-- street than before it. This drives real hands rather than asserting on the
-- formula, so a change to the fold rule shows up here.
local foldsByPhase = { preflop = 0, flop = 0, turn = 0, river = 0 }
local actionsByPhase = { preflop = 0, flop = 0, turn = 0, river = 0 }

PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = "zombiebrain", chance = 1.0 } }
for round = 1, 25 do
    PZLinux.Poker.Sessions = {}
    local player = {}
    assert(PZLinuxPokerCreateSession(player, "micro", 200, "hunt-" .. round).ok, "the hunter table must open")
    local session = PZLinuxPokerGetSession(player)
    -- One hunter, the rest ordinary opponents, and deep enough that the
    -- force-fold bet is affordable.
    session.seats[2].aiEngine = "test_zombiehunter"
    session.seats[2].aiParams = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI("test_zombiehunter"), nil)
    for index = 2, #session.seats do session.seats[index].stack = 5000 end

    for _ = 1, 60 do
        session = PZLinuxPokerGetSession(player)
        if not session then break end
        local snapshot = PZLinuxPokerBuildSnapshot(session)
        if snapshot.phase == "finished" then break end
        if snapshot.phase == "hand_complete" then
            if snapshot.handNumber >= 8 then break end
            PZLinuxPokerAction(player, "next", 0, snapshot.sessionId, "next")
        else
            local phase = session.phase
            for index = 3, #session.seats do
                local seat = session.seats[index]
                local signature = tostring(session.handNumber) .. phase .. tostring(seat.lastAction) .. tostring(seat.committed)
                if seat.lastAction ~= "" and seat.observed ~= signature then
                    seat.observed = signature
                    if actionsByPhase[phase] then
                        actionsByPhase[phase] = actionsByPhase[phase] + 1
                        if seat.lastAction == "FOLD" then foldsByPhase[phase] = foldsByPhase[phase] + 1 end
                    end
                end
            end
            local legal = snapshot.legalActions or {}
            PZLinuxPokerAction(player, legal.check and "check" or "call", 0, snapshot.sessionId, "act")
        end
    end
end

local function foldRate(phase)
    if actionsByPhase[phase] == 0 then return 0 end
    return foldsByPhase[phase] / actionsByPhase[phase]
end
assert(actionsByPhase.river > 20,
    "the hunter tables must reach the river often enough to measure, got " .. actionsByPhase.river)
assert(foldRate("river") > foldRate("flop"),
    string.format("opponents must fold to the last-street bet more than to the earlier ones, river %.2f vs flop %.2f",
        foldRate("river"), foldRate("flop")))

-- ----------------------------------------------------------- TEST_Cheater

-- On the river it can see it is beaten, so calling any price is wrong.
local function cheaterRiver(mine, theirs, board, toCall, pot)
    local seats = {
        { name = "S1", stack = 1000, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "S2", stack = 1000, bet = 0, committed = 0, folded = false, inHand = true, cards = cards(mine), lastAction = "" },
        { name = "S3", stack = 1000, bet = toCall, committed = toCall, folded = false, inHand = true, cards = cards(theirs), lastAction = "" },
    }
    local ctx = {
        session = { handNumber = 1, phase = "river", currentBet = toCall, seats = seats, community = cards(board) },
        seat = seats[2], seatIndex = 2,
        toCall = toCall, pot = pot, potOdds = toCall / (pot + toCall),
        currentBet = toCall, minRaise = 10, bigBlind = 10, strength = 0.5, memory = {},
        random = function(n) return 0 end, randomRange = function(a) return a end,
        equity = function() return nil end,
    }
    ctx.params = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI("test_cheater"), nil)
    return PZLinuxPokerGetAI("test_cheater"):decide(ctx)
end

-- Two pair against a made flush: beaten, and it can see that.
assert(cheaterRiver("AH KH", "7S 8S", "2S 5S 9S AC KD", 10, 1000).action == "fold",
    "the Cheater must fold a hand it can see is beaten, however cheap")

-- The nuts: it calls, however expensive.
assert(cheaterRiver("AS KS", "AH KH", "QS JS TS 2C 3D", 900, 100).action == "call",
    "the Cheater must call with a hand it can see cannot lose")

-- A chopped pot is worth exactly half, so the price decides it.
local chopCheap = cheaterRiver("AH KD", "AS KC", "AC KH 2D 5S 9C", 10, 1000)
assert(chopCheap.action == "call", "the Cheater must call a cheap price on a certain chop")

-- It must never volunteer a chip: no bets, no raises, ever.
PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = "test_cheater", chance = 1.0 } }
local cheaterActions = 0
for round = 1, 12 do
    PZLinux.Poker.Sessions = {}
    local player = {}
    assert(PZLinuxPokerCreateSession(player, "micro", 200, "cheat-" .. round).ok, "the cheater table must open")
    local session = PZLinuxPokerGetSession(player)
    for _ = 1, 60 do
        session = PZLinuxPokerGetSession(player)
        if not session then break end
        local snapshot = PZLinuxPokerBuildSnapshot(session)
        if snapshot.phase == "finished" then break end
        if snapshot.phase == "hand_complete" then
            if snapshot.handNumber >= 8 then break end
            PZLinuxPokerAction(player, "next", 0, snapshot.sessionId, "next")
        else
            for index = 2, #session.seats do
                local action = tostring(session.seats[index].lastAction or "")
                if action ~= "" then cheaterActions = cheaterActions + 1 end
                assert(action:sub(1, 5) ~= "RAISE",
                    "the Cheater must never raise, saw " .. action)
            end
            local legal = snapshot.legalActions or {}
            PZLinuxPokerAction(player, legal.check and "check" or "call", 0, snapshot.sessionId, "act")
        end
    end
end
assert(cheaterActions > 50, "the cheater tables must actually play, saw " .. cheaterActions .. " actions")

print("PZLinux poker TEST bot tests OK")
