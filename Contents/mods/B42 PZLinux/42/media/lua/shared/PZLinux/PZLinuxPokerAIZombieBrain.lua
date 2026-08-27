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

-- Skill levels run 1 (worst) to 5 (best) and are drawn from the weights in
-- PZLinuxPokerConfig.lua. Kept as seat.difficulty rather than an
-- engine-private field because the value predates the registry and older
-- saves and tools already read it under that name.
local function ZombieBrainRandomDifficulty(random)
    local roll = random(100) + 1
    local total = 0
    for level, weight in ipairs(PZLinux.Poker.Config.aiDifficultyWeights or {}) do
        total = total + weight
        if roll <= total then return level end
    end
    return 3
end

function ZombieBrain:createSeat(seat, lobby, context)
    seat.difficulty = ZombieBrainRandomDifficulty(context.random)
end

function ZombieBrain:decide(context)
    local session = context.session
    local seat = context.seat
    local toCall = context.toCall
    local strength = context.strength
    local difficulty = tonumber(seat.difficulty) or 3

    local noise = (6 - difficulty) * (context.random(30) - 15) / 100
    local bluff = context.random(100) < (PZLinux.Poker.Config.aiBluffChance[difficulty] or 10)
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
