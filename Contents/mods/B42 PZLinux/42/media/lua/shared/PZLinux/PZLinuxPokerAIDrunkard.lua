-- "Drunkard" poker AI: plays the mood, not the cards.
--
-- The one engine here that never looks at its own hand. It does not call
-- context.equity, does not read context.strength, and keeps no notes on
-- anyone -- every decision is a dice roll against its own habits. That makes
-- it genuinely unpredictable rather than merely bad: it cannot be read,
-- because there is nothing to read.
--
-- Two things keep it from being pure noise. It bets small, never shoving a
-- stack it was not asked for, so it stays at the table long enough to be
-- annoying. And it notices size, if not odds: told to put in half its stack
-- it usually declines, not because the maths says so but because that is
-- visibly a lot of money. Everything in between it will happily call.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local Drunkard = {
    id = "drunkard",
    name = "Drunkard",
}

-- Params, all optional, all per lobby:
--
--   raiseChance         percent chance of putting chips in unprompted
--   foldChance          percent chance of folding a bet it could afford
--   heroCallChance      percent chance of calling a bet it thinks is too big
--   maxRaiseBigBlinds   ceiling on a raise, in big blinds -- the anti-shove
--   bigBetStackFraction a bet costing more than this share of its stack is
--                       "a lot of money" and usually gets folded
function Drunkard:defaults()
    return {
        raiseChance = 22,
        foldChance = 12,
        heroCallChance = 15,
        maxRaiseBigBlinds = 3,
        bigBetStackFraction = 0.5,
    }
end

-- Small and scaled to the blinds rather than to the pot: this engine has no
-- concept of what a pot is worth.
local function DrunkardRaise(context)
    local params = context.params
    local ceiling = math.max(1, math.floor((params.maxRaiseBigBlinds or 3) * context.bigBlind))
    local extra = context.randomRange(0, ceiling + 1)
    return { action = "raise", amount = context.toCall + context.minRaise + extra }
end

function Drunkard:decide(context)
    local params = context.params
    local roll = context.random(100)

    if context.toCall <= 0 then
        if roll < (params.raiseChance or 22) then return DrunkardRaise(context) end
        return { action = "check" }
    end

    -- Not pot odds -- just a sense that this is more money than it fancies.
    local bigBet = context.toCall > context.seat.stack * (params.bigBetStackFraction or 0.5)
    if bigBet then
        if context.random(100) < (params.heroCallChance or 15) then return { action = "call" } end
        return { action = "fold" }
    end

    if roll < (params.foldChance or 12) then return { action = "fold" } end
    if roll < (params.foldChance or 12) + (params.raiseChance or 22) then return DrunkardRaise(context) end
    return { action = "call" }
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(Drunkard)
else
    PZLinux.Poker.AI.Engines[Drunkard.id] = Drunkard
end
