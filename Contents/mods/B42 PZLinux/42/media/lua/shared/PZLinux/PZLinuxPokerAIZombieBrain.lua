-- "Zombie Brain" poker AI.
--
-- This is the original PZLinux poker opponent, lifted out of
-- PZLinuxPokerEngine.lua unchanged so that it becomes one engine among
-- many rather than the only way an AI seat can think. Its behaviour is
-- deliberately identical to what shipped before the registry existed: the
-- same skill roll, the same confidence maths, the same order of random
-- draws.
--
-- How it plays: it grades its own cards, adds noise inversely proportional
-- to its skill level, occasionally bluffs, folds when its confidence does
-- not beat the pot odds, and otherwise min-raises or calls. It never reads
-- the board texture, never considers position, and never remembers what
-- anyone did last hand -- hence the name.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local ZombieBrain = {
    id = "zombiebrain",
    name = "Zombie Brain",
}

-- Params this engine understands, all optional, all per lobby:
--
--   difficultyWeights  five relative weights for skill levels 1..5, e.g.
--                      { 5, 10, 25, 35, 25 } to seat mostly strong players
--   bluffChance        per-level bluff percentages, keyed [1]..[5]
--
-- Declared as a function rather than a table because these track the live
-- values in PZLinuxPokerConfig.lua, which a server may change after this file
-- has loaded. The registry merges a lobby's params over whatever this returns
-- and hands the engine a complete, correctly typed table, so nothing below
-- has to re-check what it was given -- a lobby naming no params plays exactly
-- as it always has.
function ZombieBrain:defaults()
    return {
        difficultyWeights = PZLinux.Poker.Config.aiDifficultyWeights,
        bluffChance = PZLinux.Poker.Config.aiBluffChance,
    }
end

-- Type-correct is not the same as usable: a five-entry weight list is still
-- unusable if it is empty or sums to zero, and every seat would silently come
-- out at the middle skill level. Fall back rather than seat a table of
-- identical opponents nobody asked for.
local ZOMBIEBRAIN_FALLBACK_WEIGHTS = { 25, 25, 25, 15, 10 }

local function ZombieBrainUsableWeights(weights)
    local total = 0
    for _, weight in ipairs(weights or {}) do
        if type(weight) ~= "number" or weight < 0 then return ZOMBIEBRAIN_FALLBACK_WEIGHTS end
        total = total + weight
    end
    if total <= 0 then return ZOMBIEBRAIN_FALLBACK_WEIGHTS end
    return weights
end

-- Skill levels run 1 (worst) to 5 (best). Kept as seat.difficulty rather
-- than an engine-private field because the value predates the registry and
-- older saves and tools already read it under that name.
-- Weights are relative, so a list that does not sum to 100 still works: the
-- roll is scaled to the total rather than assuming percentages.
local function ZombieBrainRandomDifficulty(random, weights)
    local total = 0
    for _, weight in ipairs(weights) do total = total + weight end
    local roll = (random(100) + 1) / 100 * total
    local running = 0
    for level, weight in ipairs(weights) do
        running = running + weight
        if roll <= running then return level end
    end
    return math.min(#weights, 3)
end

function ZombieBrain:createSeat(seat, lobby, context)
    local weights = ZombieBrainUsableWeights((context.params or {}).difficultyWeights)
    seat.difficulty = ZombieBrainRandomDifficulty(context.random, weights)
end

function ZombieBrain:decide(context)
    local session = context.session
    local seat = context.seat
    local toCall = context.toCall
    local strength = context.strength
    local difficulty = tonumber(seat.difficulty) or 3

    local noise = (6 - difficulty) * (context.random(30) - 15) / 100
    local bluffChance = (context.params or {}).bluffChance or {}
    local bluff = context.random(100) < (bluffChance[difficulty] or 10)
    local confidence = math.max(0, math.min(1, strength + noise + (bluff and 0.18 or 0)))

    if toCall > 0 and confidence < context.potOdds + 0.12 then
        return { action = "fold" }
    end

    local raiseChance = confidence * 100 - 55 + difficulty * 4
    if seat.stack > toCall + context.minRaise and context.random(100) < raiseChance then
        local raiseAmount = math.min(
            seat.stack,
            toCall + context.minRaise + context.randomRange(0, context.bigBlind + 1))
        return { action = "raise", amount = raiseAmount }
    end

    return { action = "call" }
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(ZombieBrain)
else
    PZLinux.Poker.AI.Engines[ZombieBrain.id] = ZombieBrain
end
