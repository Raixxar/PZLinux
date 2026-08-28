-- Skill knobs shared by the reading engines (Survivor, Shark).
--
-- The wrong way to make a weaker opponent is to move its thresholds: a Shark
-- told to value-bet at 80 instead of 60 is not a worse Shark, it is a rock,
-- and it stops feeling like the engine it is meant to be. What separates a
-- strong player from a weak one is not the rules they follow but the quality
-- of what they feed into them -- how well they read a hand, how much of the
-- table they remember, whether they can stop themselves calling.
--
-- So every knob here degrades an input, never a rule. A level-1 Shark still
-- hunts fold equity, still value-bets, still respects a tight raiser; it just
-- misjudges its equity, forgets what it saw two hands ago, and cannot always
-- fold. It stays recognisably a Shark, and it loses.
--
-- The knobs:
--
--   equityError     +/- percentage points of noise on every equity estimate.
--                   Symmetric, so it does not bias the play by itself -- it
--                   just makes the decisions less reliable.
--   equityBias      percentage points added to every estimate. Positive is
--                   overconfidence, which is what weak players actually do:
--                   they do not misjudge hands at random, they overvalue
--                   them, and that produces the specific leak of paying off
--                   too often.
--   memoryAccuracy  0..1 chance that an observed action gets recorded at all.
--                   A forgetful engine's reads are built from a fraction of
--                   the evidence, so they stay noisy no matter how long it
--                   sits at the table.
--   memoryWindow    hands over which the reads fade, so old evidence stops
--                   counting. Zero means perfect recall, forever.
--   tiltChance      percent of decisions where discipline fails and it cannot
--                   fold. The classic weak-player leak, and an exploitable
--                   one -- it pays off exactly when it should not.
--   sizingError     relative jitter on bet sizing. A strong player's bets are
--                   consistent; a weak one's wobble, which both costs value
--                   and telegraphs.
--   sizingTell      how far bet size follows hand strength, 0 to 1. This one
--                   is not a handicap, it is a gift to the player: a seat with
--                   a tell bets big when it is strong and small when it is
--                   weak, every time, so a person who watches can read it and
--                   act on the read. It is deliberately outside the skill
--                   presets -- readability is a personality trait a lobby
--                   chooses, not a rung on a competence ladder, and a strong
--                   opponent with an obvious tell is a far more interesting
--                   table than a weak one without.
--
-- A tell only exists if it is consistent, so sizingError works directly
-- against sizingTell: jitter is noise laid over the signal. A seat meant to be
-- read wants a high tell and a low error.
--
-- A single `skill` param from 1 (worst) to 5 (best) sets all six. Any knob
-- can still be named directly by a lobby to override the preset -- see
-- PZLinuxPokerAISkillValue.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}

-- Level 5 is deliberately a perfect passthrough: zero noise, zero bias,
-- perfect recall, no tilt. It is the engine exactly as tuned, so leaving
-- skill alone changes nothing about how these engines already played.
PZLinux.Poker.AI.SkillProfiles = {
    [1] = { equityError = 22, equityBias = 12, memoryAccuracy = 0.25, memoryWindow = 8,  tiltChance = 22, sizingError = 0.45 },
    [2] = { equityError = 16, equityBias =  7, memoryAccuracy = 0.45, memoryWindow = 15, tiltChance = 14, sizingError = 0.30 },
    [3] = { equityError = 11, equityBias =  3, memoryAccuracy = 0.65, memoryWindow = 30, tiltChance =  8, sizingError = 0.20 },
    [4] = { equityError =  6, equityBias =  1, memoryAccuracy = 0.85, memoryWindow = 80, tiltChance =  3, sizingError = 0.10 },
    [5] = { equityError =  0, equityBias =  0, memoryAccuracy = 1.00, memoryWindow = 0,  tiltChance =  0, sizingError = 0.00 },
}

function PZLinuxPokerAISkillProfile(level)
    local profiles = PZLinux.Poker.AI.SkillProfiles
    return profiles[tonumber(level) or 5] or profiles[5]
end

-- Knob defaults are declared as -1, meaning "take it from the skill level".
-- A lobby naming the knob directly gets that value instead, so a table can
-- ask for a level-2 Shark that nonetheless never tilts.
function PZLinuxPokerAISkillValue(params, key)
    local explicit = params[key]
    if explicit ~= nil and explicit >= 0 then return explicit end
    return PZLinuxPokerAISkillProfile(params.skill)[key]
end

-- The knob block an engine mixes into its own defaults.
function PZLinuxPokerAISkillDefaults(skill)
    return {
        skill = skill or 5,
        equityError = -1,
        equityBias = -1,
        memoryAccuracy = -1,
        memoryWindow = -1,
        tiltChance = -1,
        sizingError = -1,
        -- Not drawn from the skill profile: no tell unless a lobby asks.
        sizingTell = 0,
    }
end

-- What this engine believes its equity to be, which at low skill is not what
-- it is. Bias first, then symmetric noise.
function PZLinuxPokerAIPerceivedEquity(context, equity)
    if equity == nil then return nil end
    local params = context.params
    local bias = PZLinuxPokerAISkillValue(params, "equityBias")
    local error = PZLinuxPokerAISkillValue(params, "equityError")
    local perceived = equity + bias
    if error > 0 then
        local span = math.floor(error * 2) + 1
        perceived = perceived + (context.random(span) - error)
    end
    return math.max(0, math.min(100, perceived))
end

-- Discipline failing: it knows it should fold and calls anyway.
function PZLinuxPokerAITilted(context)
    local chance = PZLinuxPokerAISkillValue(context.params, "tiltChance")
    if chance <= 0 then return false end
    return context.random(100) < chance
end

-- Bet sizing: the tell first, then the wobble.
--
-- equityPercent is what the seat believes about its own hand. With a tell set,
-- the bet leans on it -- bigger when strong, smaller when weak -- which is
-- exactly the leak a live player learns to read. The lean is deterministic on
-- purpose: a tell that only shows up sometimes is not a tell, it is noise.
function PZLinuxPokerAISizing(context, fraction, equityPercent)
    local params = context.params
    local tell = params.sizingTell or 0
    if tell > 0 and equityPercent then
        local lean = (math.max(0, math.min(100, equityPercent)) - 50) / 50
        fraction = fraction * (1 + tell * lean)
    end

    local jitter = PZLinuxPokerAISkillValue(params, "sizingError")
    if jitter > 0 then
        local swing = (context.random(201) - 100) / 100 * jitter
        fraction = fraction * (1 + swing)
    end
    return math.max(0.1, fraction)
end

-- The options PZLinuxPokerAIObserve needs to model an imperfect memory.
function PZLinuxPokerAIMemoryOptions(context)
    return {
        accuracy = PZLinuxPokerAISkillValue(context.params, "memoryAccuracy"),
        window = PZLinuxPokerAISkillValue(context.params, "memoryWindow"),
        random = context.random,
    }
end
