-- "Shark" poker AI: there for the money.
--
-- Same notes as the Survivor, opposite conclusion. Where the Survivor uses a
-- read to avoid being robbed, the Shark uses it to work out who can be robbed,
-- and then does it as often as that table allows.
--
-- Three things drive it, in order of how much money they make:
--
--   Value. It runs a real equity simulation and, when it is ahead, charges
--   for it -- pot-sized rather than the polite minimum raise, because the
--   money comes from the size of the bets it gets called on, not the number.
--   What "ahead" means is not fixed: context.equity answers "how do I fare
--   against random cards", but nobody calls a big bet with random cards. The
--   tighter the table, the stronger the hands that call, and the further that
--   number sits above the truth -- so the bar rises with the table's fold
--   rate. Ignoring this is how a Shark stacks off: it bets three quarters of
--   the pot at what it reads as a solid edge, gets called only by the hands
--   that beat it, and pays them off. Measured against four Survivors, that
--   mistake alone cost it 80,375 chips in value bets against 6,563 in
--   bluffs.
--
--   Fold equity. Against a table that folds too much it bets whether or not
--   it has anything, because those chips are free. Against a table that never
--   folds it stops bluffing entirely and simply value-bets wider: bluffing a
--   station is the single most expensive mistake available here.
--
--   Draws. Middling equity with cards still to come is worth a bet when
--   folding is on the table, since it wins two ways -- immediately when they
--   pass, later when it gets there.
--
-- It reads betting patterns only. It never looks at anyone's hole cards,
-- though the engine view would let it: a Shark that cheats is not a poker AI,
-- it is a scripted outcome, and it would make the reads pointless.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local Shark = {
    id = "shark",
    name = "Shark",
}

-- Params, all optional, all per lobby. Equity figures are percentages.
--
--   equitySamples        Monte Carlo samples per decision
--   valueRaiseEquity     equity at which it starts charging a neutral table
--   neutralFoldRate      the fold rate valueRaiseEquity is calibrated for
--   tightnessScale       equity points the bar moves per unit of fold rate
--                        away from neutral -- the adverse-selection correction
--   minValueBar          floor on the adjusted bar, against callers
--   maxValueBar          ceiling on it, against rocks
--   respectAggression    an opponent raising less often than this is believed
--   respectPenalty       equity points discounted when such a player raises
--   grudgeBonus          equity points added back against a known bluffer
--   bluffRateThreshold   fold-after-raising rate that marks a bluffer
--   shoveEquity          equity at which it stops sizing and just jams
--   shoveStackToPot      it only jams when its stack is within this multiple
--                        of the pot, so a jam is a bet and not a coin flip
--   semiBluffEquity      draw-shaped equity worth betting for fold equity
--   callMargin           edge over pot odds it needs to call, in points
--   potFractionValue     value bet size as a share of the pot
--   potFractionBluff     bluff size -- smaller, because it only has to work
--   exploitFoldRate      table fold rate above which bluffing is profitable
--   stationFoldRate      table fold rate below which bluffing is abandoned
--   bluffChance          percent of eligible spots it actually bluffs
--   maxBluffOpponents    it will not try to bluff a crowd
--   minReadActions       observed actions before a read is trusted
-- Skill knobs (see PZLinuxPokerAISkill.lua) ride along with this engine's
-- own params. skill 1..5 sets them all; naming one directly overrides the
-- preset. Level 5 is a perfect passthrough, so the defaults below play
-- exactly as this engine did before the knobs existed.
function Shark:defaults()
    local params = PZLinuxPokerAISkillDefaults(5)
    local own = {
        equitySamples = 150,
        valueRaiseEquity = 60,
        neutralFoldRate = 0.35,
        tightnessScale = 70,
        minValueBar = 48,
        maxValueBar = 90,
        respectAggression = 0.18,
        respectPenalty = 12,
        grudgeBonus = 8,
        bluffRateThreshold = 0.35,
        shoveEquity = 90,
        shoveStackToPot = 1.2,
        semiBluffEquity = 33,
        callMargin = 2,
        potFractionValue = 0.75,
        potFractionBluff = 0.55,
        exploitFoldRate = 0.45,
        stationFoldRate = 0.20,
        bluffChance = 45,
        maxBluffOpponents = 2,
        minReadActions = 4,
    }
    for key, value in pairs(own) do params[key] = value end
    return params
end

local function SharkEquity(context)
    local equity = context.equity(context.params.equitySamples)
    if not equity then equity = (context.strength or 0) * 100 end
    -- What it believes, not what is true: at low skill these differ.
    return PZLinuxPokerAIPerceivedEquity(context, equity)
end

local function SharkRaise(context, fraction, equityPercent)
    local target = math.floor(context.pot * PZLinuxPokerAISizing(context, fraction, equityPercent))
    return { action = "raise", amount = PZLinux.Poker.AI.RaiseAmountForTarget(context, target) }
end

local function SharkChoose(context)
    local params = context.params
    local reads = PZLinuxPokerAIObserve(context, PZLinuxPokerAIMemoryOptions(context))
    local equity = SharkEquity(context)
    local potOddsPercent = context.potOdds * 100
    local streetsLeft = (context.session.phase ~= "river")

    -- How this table behaves when bet at. Unread tables are assumed neutral:
    -- no bluffing until it has watched enough to know it pays.
    local foldRate = reads.tableFoldRate
    local exploitable = foldRate ~= nil and foldRate >= (params.exploitFoldRate or 0.45)
    local station = foldRate ~= nil and foldRate <= (params.stationFoldRate or 0.20)

    -- The adverse-selection correction. A table that folds often only
    -- continues with real hands, so a call means trouble and the bar to bet
    -- into them rises; a table that calls everything continues with anything,
    -- so thin value is where the money is and the bar drops.
    local valueBar = params.valueRaiseEquity or 60
    if foldRate ~= nil then
        valueBar = valueBar + (foldRate - (params.neutralFoldRate or 0.35)) * (params.tightnessScale or 70)
        valueBar = math.max(params.minValueBar or 48, math.min(params.maxValueBar or 90, valueBar))
    end

    -- The same correction aimed at one player rather than the table. Being
    -- raised by someone who almost never raises is worth more than any
    -- average: their range is strong, so the hand is worth less than the
    -- simulation against random cards says.
    local effectiveEquity = equity
    local villain = reads.aggressor
    if villain and villain.actions >= (params.minReadActions or 4) then
        if villain.aggression <= (params.respectAggression or 0.18) then
            effectiveEquity = effectiveEquity - (params.respectPenalty or 12)
        elseif villain.bluffRate >= (params.bluffRateThreshold or 0.35) then
            effectiveEquity = effectiveEquity + (params.grudgeBonus or 8)
        end
    end

    -- Jamming is a bet, not a coin flip: only with a hand that wants a call
    -- and only when the stack is close enough to the pot to be a real price.
    if effectiveEquity >= (params.shoveEquity or 90)
        and context.seat.stack <= context.pot * (params.shoveStackToPot or 1.2) then
        return { action = "raise", amount = context.seat.stack }
    end

    if effectiveEquity >= valueBar then
        return SharkRaise(context, params.potFractionValue or 0.75, effectiveEquity)
    end

    local canBluff = exploitable
        and not station
        and reads.liveOpponents <= (params.maxBluffOpponents or 2)
        and context.random(100) < (params.bluffChance or 45)

    -- A draw bet wins twice: now if they fold, later if it hits.
    local semiBluff = streetsLeft
        and effectiveEquity >= (params.semiBluffEquity or 33)
        and effectiveEquity < valueBar
        and canBluff

    if context.toCall <= 0 then
        if semiBluff or canBluff then
            return SharkRaise(context, params.potFractionBluff or 0.55, effectiveEquity)
        end
        return { action = "check" }
    end

    if effectiveEquity >= potOddsPercent + (params.callMargin or 2) then
        if semiBluff then return SharkRaise(context, params.potFractionBluff or 0.55, effectiveEquity) end
        return { action = "call" }
    end

    -- Behind, but they fold enough that taking it away is still profitable.
    if canBluff and context.toCall <= context.seat.stack * 0.2 then
        return SharkRaise(context, params.potFractionBluff or 0.55, effectiveEquity)
    end

    return { action = "fold" }
end

function Shark:decide(context)
    local decision = SharkChoose(context)
    -- The leak that separates a good aggressive player from a bad one: a bad
    -- one cannot lay a hand down, and pays off precisely when it should not.
    if decision.action == "fold" and context.toCall > 0 and PZLinuxPokerAITilted(context) then
        return { action = "call" }
    end
    return decision
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(Shark)
else
    PZLinux.Poker.AI.Engines[Shark.id] = Shark
end
