-- "Survivor" poker AI: playing not to lose.
--
-- Its goal is to still be sitting at the table later, which is a different
-- game from winning the most money. It folds a great deal, it never bluffs,
-- and it caps how much of its stack any single hand may consume. Given a
-- marginal spot it takes the exit.
--
-- What stops that being simply a rock is the tit-for-tat: it keeps notes on
-- who has been raising and how often that raise turned out to be nothing
-- (PZLinuxPokerAIReads). Aggression from someone who has been caught giving
-- up hands gets discounted -- it will call that person down light. Aggression
-- from someone who has barely raised all session gets believed, and it folds
-- hands it would otherwise have paid off. Retaliation here means refusing to
-- be bluffed, not bluffing back.
--
-- The one time it stops folding is when folding has become the losing move:
-- short enough that the blinds will finish it anyway, it takes the best hand
-- it can find and commits, because surviving the next orbit requires chips.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local Survivor = {
    id = "survivor",
    name = "Survivor",
}

-- Params, all optional, all per lobby. Equity figures are percentages,
-- matching what context.equity returns.
--
--   equitySamples        Monte Carlo samples per decision; more is sharper
--                        and slower
--   callMargin           how far equity must beat the pot odds before it
--                        will pay, in percentage points
--   raiseEquity          it only raises when clearly ahead, never as a bluff
--   riskCap              share of its stack one hand may consume without a
--                        hand strong enough to justify it
--   riskCapEquity        equity that lifts the risk cap
--   grudgeDiscount       percentage points shaved off what a known bluffer's
--                        aggression demands
--   respectPenalty       percentage points added when a rarely-aggressive
--                        opponent finally raises
--   bluffRateThreshold   fold-after-raising rate at which an opponent stops
--                        being believed
--   respectAggression    aggression rate below which an opponent's raise is
--                        treated as the real thing
--   shortStackBigBlinds  below this it must gamble rather than blind away
--   minReadActions       observed actions before a read is trusted at all
-- Skill knobs (see PZLinuxPokerAISkill.lua) ride along with this engine's
-- own params. skill 1..5 sets them all; naming one directly overrides the
-- preset. Level 5 is a perfect passthrough, so the defaults below play
-- exactly as this engine did before the knobs existed.
function Survivor:defaults()
    local params = PZLinuxPokerAISkillDefaults(5)
    local own = {
        equitySamples = 80,
        callMargin = 6,
        raiseEquity = 72,
        riskCap = 0.25,
        riskCapEquity = 78,
        grudgeDiscount = 9,
        respectPenalty = 7,
        bluffRateThreshold = 0.35,
        respectAggression = 0.18,
        shortStackBigBlinds = 12,
        minReadActions = 4,
    }
    for key, value in pairs(own) do params[key] = value end
    return params
end

-- Equity when the simulation can produce one, the crude heuristic when it
-- cannot -- preflop with an incomplete table, or a hand already decided.
local function SurvivorEquity(context)
    local equity = context.equity(context.params.equitySamples)
    if not equity then equity = (context.strength or 0) * 100 end
    -- What it believes, not what is true: at low skill these differ.
    return PZLinuxPokerAIPerceivedEquity(context, equity)
end

local function SurvivorChoose(context)
    local params = context.params
    local reads = PZLinuxPokerAIObserve(context, PZLinuxPokerAIMemoryOptions(context))
    local equity = SurvivorEquity(context)
    local potOddsPercent = context.potOdds * 100

    -- Tit for tat. The price of calling is adjusted by who is charging it.
    local required = potOddsPercent + (params.callMargin or 6)
    local villain = reads.aggressor
    if villain and villain.actions >= (params.minReadActions or 4) then
        if villain.bluffRate >= (params.bluffRateThreshold or 0.35) then
            required = required - (params.grudgeDiscount or 9)
        elseif villain.aggression <= (params.respectAggression or 0.18) then
            required = required + (params.respectPenalty or 7)
        end
    end

    local shortStacked = context.seat.stack <= (params.shortStackBigBlinds or 12) * context.bigBlind

    if context.toCall <= 0 then
        -- Free cards are always taken; betting is for hands that are ahead.
        if equity >= (params.raiseEquity or 72) then
            local target = math.floor(context.pot * PZLinuxPokerAISizing(context, 0.5, equity))
            return { action = "raise", amount = math.max(context.minRaise, target) }
        end
        return { action = "check" }
    end

    -- Stack preservation. Committing beyond the cap needs a hand that
    -- justifies it, whatever the pot odds say in isolation.
    local committedAfter = (context.seat.committed or 0) + context.toCall
    local exposure = committedAfter / math.max(1, context.seat.stack + (context.seat.committed or 0))
    if exposure > (params.riskCap or 0.25) and equity < (params.riskCapEquity or 78) and not shortStacked then
        return { action = "fold" }
    end

    if equity < required then return { action = "fold" } end

    if equity >= (params.raiseEquity or 72) then
        local target = math.floor(context.pot * PZLinuxPokerAISizing(context, 0.5, equity))
        return { action = "raise", amount = math.max(context.toCall + context.minRaise, target) }
    end

    -- Blinding out is losing slowly. With a real hand and nothing behind,
    -- getting it in beats folding into oblivion.
    if shortStacked and equity >= potOddsPercent + 2 then
        return { action = "raise", amount = context.seat.stack }
    end

    return { action = "call" }
end

function Survivor:decide(context)
    local decision = SurvivorChoose(context)
    -- Discipline failing. A Survivor that cannot fold is no longer surviving,
    -- which is exactly what makes a low-skill one lose.
    if decision.action == "fold" and context.toCall > 0 and PZLinuxPokerAITilted(context) then
        return { action = "call" }
    end
    return decision
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(Survivor)
else
    PZLinux.Poker.AI.Engines[Survivor.id] = Survivor
end
