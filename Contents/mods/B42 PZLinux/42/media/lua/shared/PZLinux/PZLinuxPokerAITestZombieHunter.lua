-- TEST_ZombieHunter: a test instrument, not an opponent.
--
-- It never looks at its cards. Instead it plays the other engines' fold rule
-- directly, sizing every bet to land on a chosen side of it. Early streets it
-- bets the most it can while still being called, to inflate the pot; on the
-- last street it bets an amount calculated to make them all pass.
--
-- That makes it a probe for the ZombieBrain family's continuation logic. If a
-- change to that logic ever alters when opponents fold, this bot's fold-forced
-- rate moves with it, and the tests built on it fail loudly.
--
-- The arithmetic it exploits, from PZLinuxPokerAIZombieBrain:
--
--     folds when  toCall > 0  and  confidence < potOdds + 0.12
--
-- Pot odds are computed with the bettor's own chips already in the pot, so
--
--     potOdds = toCall / (pot + toCall)
--
-- and letting P be the pot before this action, b what this seat already has
-- in on this street, and a the chips it is about to add, an opponent yet to
-- act this street faces toCall = b + a against a pot of P + a:
--
--     potOdds = (b + a) / (P + b + 2a)
--
-- Solving that for a at a chosen target t gives the bet below. Note the
-- ceiling this implies: as a grows, potOdds tends to 1/2 and no further, so
-- no bet however large can demand better than even money. An opponent whose
-- confidence exceeds about 0.62 cannot be bet off its hand at all -- which is
-- itself worth knowing, and is why this bot forces folds rather than
-- guaranteeing them.
--
-- Not for a live lobby: it plays blind and will happily call off its stack.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local ZombieHunter = {
    id = "test_zombiehunter",
    name = "TEST_ZombieHunter",
    testOnly = true,
}

-- Params, all optional:
--
--   keepInPotOdds     pot odds to offer on the streets where it wants calls.
--                     0.30 leaves an opponent needing 0.42 confidence, which
--                     most hands clear
--   forceFoldPotOdds  pot odds to offer on the last street. 0.45 leaves an
--                     opponent needing 0.57, which nothing below a flush
--                     reaches before noise
--   finalPhase        the street on which it switches to forcing folds
--   maxPotMultiple    ceiling on any bet, in multiples of the pot, so a
--                     target that would demand an absurd bet just shoves
--   maxHandFraction   share of its stack one hand may take. Reached by being
--                     re-raised, it gives the hand up: it is blind, so paying
--                     to see a showdown tells it nothing
function ZombieHunter:defaults()
    return {
        keepInPotOdds = 0.30,
        forceFoldPotOdds = 0.45,
        finalPhase = "river",
        maxPotMultiple = 8,
        maxHandFraction = 0.35,
    }
end

-- Chips to add so that the next opponent to act faces exactly targetOdds.
local function ZombieHunterBetFor(context, targetOdds)
    local params = context.params
    local pot = math.max(1, context.pot)
    local alreadyIn = context.seat.bet or 0

    -- Pot odds cannot reach 1/2, so a target at or above it has no solution.
    local target = math.min(targetOdds, 0.49)
    local denominator = 1 - 2 * target
    local amount = (target * pot - alreadyIn * (1 - target)) / denominator

    local ceiling = pot * (params.maxPotMultiple or 8)
    amount = math.min(amount, ceiling)
    amount = math.max(amount, context.toCall + context.minRaise)
    return math.floor(math.min(amount, context.seat.stack))
end

function ZombieHunter:decide(context)
    local params = context.params
    local finalStreet = context.session.phase == (params.finalPhase or "river")

    -- One sizing bet per street. Recomputing the target after someone raises
    -- would price it off the enlarged pot and raise again, and again -- the
    -- two of them escalating to all-in every hand, which measures nothing.
    -- Having made its bet for this street, it simply calls.
    -- Being re-raised past the cap ends the hand. Without this it calls off
    -- its stack blind against real hands and never survives to make the
    -- last-street bet that is the entire point of the engine.
    local behind = context.seat.stack + (context.seat.committed or 0)
    local wouldCommit = (context.seat.committed or 0) + context.toCall
    if context.toCall > 0 and wouldCommit > behind * (params.maxHandFraction or 0.35) then
        return { action = "fold" }
    end

    local street = tostring(context.session.handNumber) .. "|" .. tostring(context.session.phase)
    if context.memory.betOnStreet == street then
        if context.toCall > 0 then return { action = "call" } end
        return { action = "check" }
    end

    local target = finalStreet and (params.forceFoldPotOdds or 0.45) or (params.keepInPotOdds or 0.30)
    local amount = ZombieHunterBetFor(context, target)

    if amount > context.toCall then
        context.memory.betOnStreet = street
        return { action = "raise", amount = amount }
    end
    if context.toCall > 0 then
        return { action = "call" }
    end
    return { action = "check" }
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(ZombieHunter)
else
    PZLinux.Poker.AI.Engines[ZombieHunter.id] = ZombieHunter
end
