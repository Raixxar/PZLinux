-- Behaviour tests for the Drunkard, Survivor and Shark engines.
--
-- Two layers. First, each engine is driven directly with a hand-built context
-- so its decisions can be asserted exactly -- no dealing, no shuffling, no
-- flake. Then all three are seated at real tables for a few hundred hands to
-- prove they survive contact with the rules engine and never break the chip
-- count.

math.randomseed(90210)

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
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIDrunkard.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAISurvivor.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIShark.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerEngine.lua")

for _, id in ipairs({ "drunkard", "survivor", "shark" }) do
    assert(PZLinuxPokerGetAI(id), id .. " must register itself on load")
    assert(type(PZLinuxPokerGetAI(id).defaults) == "function", id .. " must declare its params")
end

-- A table built by hand. Everything an engine reads is set explicitly, so a
-- decision below is a statement about the engine and nothing else.
local function context(overrides)
    local seats = {}
    for index = 1, 3 do
        seats[index] = {
            name = "Seat" .. index, stack = 1000, bet = 0, committed = 0,
            folded = false, inHand = true, allIn = false, lastAction = "",
            cards = {}, isHuman = index == 1,
        }
    end
    local built = {
        session = { handNumber = 1, phase = "flop", currentBet = 0, seats = seats, community = {} },
        seat = seats[2],
        seatIndex = 2,
        toCall = 0,
        pot = 100,
        potOdds = 0,
        currentBet = 0,
        minRaise = 10,
        bigBlind = 10,
        strength = 0.5,
        memory = {},
        equityValue = 50,
        random = function(maxExclusive) return math.floor(maxExclusive / 2) end,
        randomRange = function(minInclusive) return minInclusive end,
    }
    for key, value in pairs(overrides or {}) do built[key] = value end
    built.seat = built.session.seats[built.seatIndex]
    built.equity = function() return built.equityValue end
    built.params = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI(built.engineId), built.paramOverrides)
    return built
end

local function decide(engineId, overrides)
    overrides = overrides or {}
    overrides.engineId = engineId
    local ctx = context(overrides)
    return PZLinuxPokerGetAI(engineId):decide(ctx), ctx
end

-- ---------------------------------------------------------------- Drunkard

-- It must not consult the cards. If it ever starts calling context.equity,
-- this trips -- that is the entire premise of the engine.
local peeked = false
local drunkCtx = context({ engineId = "drunkard" })
drunkCtx.equity = function() peeked = true return 99 end
PZLinuxPokerGetAI("drunkard"):decide(drunkCtx)
assert(not peeked, "the Drunkard must never look at its equity")

-- Whatever it does, it must not shove. Its raise is capped in big blinds, so
-- across every roll of the dice the amount stays small.
for roll = 0, 99 do
    local decision = decide("drunkard", {
        toCall = 20, minRaise = 10, bigBlind = 10, pot = 200,
        random = function() return roll end,
        randomRange = function(_, maxExclusive) return maxExclusive - 1 end,
    })
    if decision.action == "raise" then
        assert(decision.amount <= 20 + 10 + 3 * 10,
            "the Drunkard must never raise beyond its big-blind ceiling, got " .. decision.amount)
    end
end

-- It notices size even though it never computes odds: most of its stack is
-- "a lot of money" and usually gets passed on.
local drunkFolds = 0
for roll = 0, 99 do
    local decision = decide("drunkard", {
        toCall = 900, pot = 1000,
        random = function() return roll end,
    })
    if decision.action == "fold" then drunkFolds = drunkFolds + 1 end
end
assert(drunkFolds > 50, "the Drunkard should usually decline a bet worth most of its stack, folded " .. drunkFolds)

-- Facing a small bet it is mostly along for the ride.
local drunkContinues = 0
for roll = 0, 99 do
    local decision = decide("drunkard", { toCall = 20, pot = 200, random = function() return roll end })
    if decision.action ~= "fold" then drunkContinues = drunkContinues + 1 end
end
assert(drunkContinues > 80, "the Drunkard should call small bets nearly always, continued " .. drunkContinues)

-- ---------------------------------------------------------------- Survivor

-- Ahead, with nothing owed, it bets. Behind, it takes the free card.
assert(decide("survivor", { equityValue = 90 }).action == "raise",
    "the Survivor must bet when it is clearly ahead")
assert(decide("survivor", { equityValue = 30 }).action == "check",
    "the Survivor must take a free card rather than bluff")

-- Marginal spot, priced at 33%: it needs more than the pot odds and folds.
assert(decide("survivor", { toCall = 50, pot = 100, potOdds = 0.33, equityValue = 35 }).action == "fold",
    "the Survivor must fold a spot that only just breaks even")

-- Tit for tat. Same hand, same price, different opponent history.
local function survivorVersus(read)
    local ctx = context({ engineId = "survivor", toCall = 50, pot = 100, potOdds = 0.33, equityValue = 36 })
    ctx.session.seats[3].bet = 50
    ctx.session.currentBet = 50
    ctx.memory.reads = { Seat3 = read }
    ctx.memory.hand = { number = 1, raised = {}, folded = {}, seen = {} }
    return PZLinuxPokerGetAI("survivor"):decide(ctx)
end

local knownBluffer = {
    name = "Seat3", actions = 40, raises = 20, calls = 10, checks = 10, folds = 0,
    aggressiveHands = 10, foldedAfterRaising = 8, handsSeen = 10,
}
local honestPlayer = {
    name = "Seat3", actions = 40, raises = 2, calls = 18, checks = 20, folds = 0,
    aggressiveHands = 8, foldedAfterRaising = 0, handsSeen = 10,
}
assert(survivorVersus(knownBluffer).action == "call",
    "the Survivor must call down someone it has caught giving up hands")
assert(survivorVersus(honestPlayer).action == "fold",
    "the Survivor must believe someone who almost never raises")

-- The risk cap: a hand that would eat most of the stack needs more than a
-- price to justify it.
assert(decide("survivor", {
    toCall = 400, pot = 500, potOdds = 0.44, equityValue = 60,
    session = { handNumber = 1, phase = "flop", currentBet = 400, community = {}, seats = {
        { name = "Seat1", stack = 1000, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "Seat2", stack = 600, bet = 0, committed = 200, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "Seat3", stack = 600, bet = 400, committed = 400, folded = false, inHand = true, cards = {}, lastAction = "" },
    } },
}).action == "fold", "the Survivor must fold rather than commit past its risk cap on a decent-not-great hand")

-- ------------------------------------------------------------------ Shark

-- Ahead, it charges, and it charges properly rather than min-raising.
local sharkValue = decide("shark", { equityValue = 75, pot = 200, toCall = 0, minRaise = 10 })
assert(sharkValue.action == "raise", "the Shark must bet when ahead")
assert(sharkValue.amount >= 100, "the Shark must size to the pot, got " .. tostring(sharkValue.amount))

-- Way ahead and shallow relative to the pot: it stops sizing and jams.
local sharkShove = decide("shark", {
    equityValue = 92, pot = 800, toCall = 0,
    session = { handNumber = 1, phase = "turn", currentBet = 0, community = {}, seats = {
        { name = "Seat1", stack = 1000, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "Seat2", stack = 900, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
        { name = "Seat3", stack = 900, bet = 0, committed = 0, folded = false, inHand = true, cards = {}, lastAction = "" },
    } },
})
assert(sharkShove.action == "raise" and sharkShove.amount == 900,
    "the Shark must jam when the pot is worth its stack")

-- Fold equity. Identical junk hand, two different tables.
local function sharkVersusTable(foldRate)
    local ctx = context({ engineId = "shark", equityValue = 20, pot = 200, toCall = 0 })
    ctx.random = function() return 0 end   -- always take an offered bluff
    ctx.memory.reads = {
        Seat1 = { name = "Seat1", actions = 40, raises = 4, calls = 8, checks = 8, folds = math.floor(40 * foldRate),
                  aggressiveHands = 4, foldedAfterRaising = 1, handsSeen = 10 },
        Seat3 = { name = "Seat3", actions = 40, raises = 4, calls = 8, checks = 8, folds = math.floor(40 * foldRate),
                  aggressiveHands = 4, foldedAfterRaising = 1, handsSeen = 10 },
    }
    ctx.memory.hand = { number = 1, raised = {}, folded = {}, seen = {} }
    return PZLinuxPokerGetAI("shark"):decide(ctx)
end

assert(sharkVersusTable(0.8).action == "raise",
    "the Shark must bluff a table that folds too much")
assert(sharkVersusTable(0.05).action == "check",
    "the Shark must stop bluffing a table that never folds")

-- An unread table is not assumed exploitable: no bluffing until it knows.
assert(decide("shark", { equityValue = 20, pot = 200, toCall = 0 }).action == "check",
    "the Shark must not bluff a table it has not read yet")

-- ------------------------------------------------------------ skill knobs

-- Level 5 must be a perfect passthrough, or adding the knobs would silently
-- have changed how these engines already played.
for _, id in ipairs({ "survivor", "shark" }) do
    local params = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI(id), nil)
    assert(params.skill == 5, id .. " must default to the top skill level")
    local ctx = context({ engineId = id })
    assert(PZLinuxPokerAIPerceivedEquity(ctx, 60) == 60, id .. " at level 5 must see equity exactly")
    assert(not PZLinuxPokerAITilted(ctx), id .. " at level 5 must never tilt")
    assert(PZLinuxPokerAISizing(ctx, 0.75) == 0.75, id .. " at level 5 must size exactly")
end

-- Lower levels misjudge, and the error grows as the level drops.
local function equitySpread(level, truth)
    local lo, hi = 101, -1
    for roll = 0, 99 do
        local ctx = context({ engineId = "shark", paramOverrides = { skill = level },
                              random = function() return roll end })
        local seen = PZLinuxPokerAIPerceivedEquity(ctx, truth)
        lo = math.min(lo, seen)
        hi = math.max(hi, seen)
    end
    return hi - lo
end
assert(equitySpread(1, 50) > equitySpread(3, 50), "a level 1 read must be noisier than a level 3 read")
assert(equitySpread(3, 50) > equitySpread(5, 50), "a level 3 read must be noisier than a level 5 read")
assert(equitySpread(5, 50) == 0, "a level 5 read must have no spread at all")

-- The bias is directional: weak players overvalue their hands rather than
-- misjudging them evenly, which is what makes them pay off.
local biasedTotal, trueTotal = 0, 0
for roll = 0, 99 do
    local ctx = context({ engineId = "shark", paramOverrides = { skill = 1 },
                          random = function() return roll end })
    biasedTotal = biasedTotal + PZLinuxPokerAIPerceivedEquity(ctx, 50)
    trueTotal = trueTotal + 50
end
assert(biasedTotal > trueTotal, "a level 1 engine must overestimate on average, not just wobble")

-- Tilt: it cannot always fold, and the failure rate tracks the level.
local function tiltRate(level)
    local tilts = 0
    for roll = 0, 99 do
        local ctx = context({ engineId = "survivor", paramOverrides = { skill = level },
                              random = function() return roll end })
        if PZLinuxPokerAITilted(ctx) then tilts = tilts + 1 end
    end
    return tilts
end
assert(tiltRate(1) > tiltRate(3) and tiltRate(3) > tiltRate(5), "tilt must fall as skill rises")
assert(tiltRate(5) == 0, "a level 5 engine must never tilt")

-- A tilted engine turns a fold into a call rather than inventing a raise.
local tiltedCtx = context({ engineId = "survivor", toCall = 50, pot = 100, potOdds = 0.33,
                            equityValue = 5, paramOverrides = { skill = 1, equityError = 0, equityBias = 0,
                                                                tiltChance = 100 } })
assert(PZLinuxPokerGetAI("survivor"):decide(tiltedCtx).action == "call",
    "a tilted Survivor must call the hand it meant to fold")

-- Any single knob can be named directly, overriding the preset it came from.
local mixedCtx = context({ engineId = "shark", paramOverrides = { skill = 1, tiltChance = 0 } })
assert(not PZLinuxPokerAITilted(mixedCtx), "an explicit knob must beat the skill preset")
assert(PZLinuxPokerAISkillValue(mixedCtx.params, "equityError") > 0,
    "knobs left unnamed must still come from the skill preset")

-- Memory: a forgetful engine files fewer of the actions it sees.
local function recordedActions(accuracy)
    local ctx = context({ engineId = "shark" })
    ctx.session.seats[1].lastAction = "RAISE $50"
    ctx.session.seats[3].lastAction = "FOLD"
    local total = 0
    for hand = 1, 60 do
        ctx.session.handNumber = hand
        ctx.session.seats[1].committed = hand
        ctx.session.seats[3].committed = hand
        PZLinuxPokerAIObserve(ctx, { accuracy = accuracy, window = 0,
                                     random = function(n) return math.floor(n * 0.5) end })
    end
    for _, read in pairs(ctx.memory.reads) do total = total + read.actions end
    return total
end
assert(recordedActions(1.0) > recordedActions(0.25),
    "an inaccurate memory must record fewer actions than a perfect one")

-- The window fades old evidence rather than accumulating forever.
local fadeCtx = context({ engineId = "shark" })
fadeCtx.memory.reads = { Seat1 = { name = "Seat1", actions = 100, raises = 50, calls = 20,
                                   checks = 20, folds = 10, aggressiveHands = 10,
                                   foldedAfterRaising = 5, handsSeen = 100 } }
fadeCtx.memory.hand = { number = 0, raised = {}, folded = {}, seen = {} }
fadeCtx.session.handNumber = 1
PZLinuxPokerAIObserve(fadeCtx, { accuracy = 1, window = 10, random = function() return 0 end })
assert(fadeCtx.memory.reads.Seat1.actions < 100,
    "a windowed memory must fade what it already knew")

-- ------------------------------------------------------------ sizing tell

-- A tell has to be readable, which means monotonic and repeatable: bigger bet
-- must always mean stronger hand, for the same seat, every time.
local function tellSize(equity, tell, jitter)
    local ctx = context({ engineId = "shark",
                          paramOverrides = { sizingTell = tell, sizingError = jitter or 0 } })
    return PZLinuxPokerAISizing(ctx, 0.75, equity)
end

assert(tellSize(20, 0.6) < tellSize(50, 0.6), "a tell must bet smaller with a weak hand")
assert(tellSize(50, 0.6) < tellSize(90, 0.6), "a tell must bet bigger with a strong hand")
assert(math.abs(tellSize(50, 0.6) - 0.75) < 0.001,
    "a middling hand must bet the ordinary size, so the tell reads off neutral")
assert(tellSize(90, 0.6) == tellSize(90, 0.6), "a tell must be repeatable, not sampled")

-- Without a tell the size says nothing about the hand.
assert(tellSize(20, 0) == tellSize(90, 0), "with no tell, bet size must not track strength")

-- Strength of the tell is what the lobby dials.
local weakTell = tellSize(90, 0.2) - tellSize(20, 0.2)
local strongTell = tellSize(90, 0.8) - tellSize(20, 0.8)
assert(strongTell > weakTell, "a bigger sizingTell must produce a more obvious leak")

-- Jitter is noise laid over the signal, so a seat meant to be read wants a low
-- sizingError. At a level-1 seat's 0.45 jitter the noise does not erase the
-- tell, but it does put a large band around every observation -- one bet stops
-- being evidence and the player needs several to read the seat.
local cleanGap = tellSize(90, 0.6) - tellSize(20, 0.6)
local noisyLow, noisyHigh = 1e9, -1e9
for roll = 0, 200 do
    local ctx = context({ engineId = "shark",
                          paramOverrides = { sizingTell = 0.6, sizingError = 0.45 },
                          random = function() return roll end })
    local size = PZLinuxPokerAISizing(ctx, 0.75, 20)
    noisyLow = math.min(noisyLow, size)
    noisyHigh = math.max(noisyHigh, size)
end
assert((noisyHigh - noisyLow) > cleanGap * 0.5,
    string.format("heavy jitter must blur the tell substantially, spread %.3f vs gap %.3f",
        noisyHigh - noisyLow, cleanGap))
assert((noisyHigh - noisyLow) < cleanGap,
    "...but at these settings it must not erase it outright")

-- The tell rides on what the seat believes, not on the truth, so a low-skill
-- reader with a tell broadcasts its own misjudgements. That is a feature: the
-- seat is honestly telling you what it thinks it has.
local confusedCtx = context({ engineId = "shark", equityValue = 20, pot = 200, toCall = 0,
                              paramOverrides = { skill = 1, sizingTell = 0.8, sizingError = 0,
                                                 equityError = 0, equityBias = 30 } })
local honestCtx = context({ engineId = "shark", equityValue = 20, pot = 200, toCall = 0,
                            paramOverrides = { skill = 5, sizingTell = 0.8, sizingError = 0 } })
assert(PZLinuxPokerAISizing(confusedCtx, 0.75, PZLinuxPokerAIPerceivedEquity(confusedCtx, 20))
     > PZLinuxPokerAISizing(honestCtx, 0.75, PZLinuxPokerAIPerceivedEquity(honestCtx, 20)),
    "an overconfident seat with a tell must bet its belief, not its actual equity")

-- ------------------------------------------------------- at a real table

-- Every engine, seated for real, against the rules engine rather than a
-- hand-built table. What matters here is that nothing errors and the chips
-- still add up -- the personalities were asserted above.
local personalities = { "drunkard", "survivor", "shark", "zombiebrain" }
local totalHands = 0
for _, engineId in ipairs(personalities) do
    for round = 1, 6 do
        PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = engineId, chance = 1.0 } }
        PZLinux.Poker.Sessions = {}
        local player = {}
        local opened = PZLinuxPokerCreateSession(player, "micro", 200, engineId .. "-" .. round)
        assert(opened.ok, engineId .. " must be able to fill a table")
        local startSession = PZLinuxPokerGetSession(player)
        local chipsDealt = 0
        for _, seat in ipairs(startSession.seats) do
            chipsDealt = chipsDealt + seat.stack + (seat.committed or 0)
        end

        for _ = 1, 200 do
            local session = PZLinuxPokerGetSession(player)
            if not session then break end
            local snapshot = PZLinuxPokerBuildSnapshot(session)
            if snapshot.phase == "finished" then break end
            if snapshot.phase == "hand_complete" then
                totalHands = totalHands + 1
                local chips = 0
                for _, seat in ipairs(session.seats) do
                    assert(seat.stack >= 0, engineId .. " drove a stack negative")
                    chips = chips + seat.stack
                end
                assert(chips == chipsDealt,
                    string.format("%s broke the chip count: %d chips for %d dealt",
                        engineId, chips, chipsDealt))
                if snapshot.handNumber >= 12 then break end
                PZLinuxPokerAction(player, "next", 0, snapshot.sessionId, "next")
            else
                local legal = snapshot.legalActions or {}
                PZLinuxPokerAction(player, legal.check and "check" or "call", 0, snapshot.sessionId, "act")
            end
        end
    end
end
assert(totalHands > 150, "the personality tables must actually play out, only " .. totalHands .. " hands")

print(string.format("PZLinux poker AI personality tests OK (%d hands played)", totalHands))
