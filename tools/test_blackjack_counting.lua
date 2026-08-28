-- Does card counting actually work in this game?
--
-- Blackjack now deals from a persistent shoe instead of a freshly shuffled
-- deck every hand (see PZLinuxBlackjackEngine.lua). The whole point of that
-- change is that a player who tracks what has already been dealt should be
-- able to bet bigger when the rest of the shoe favors them. That claim is easy
-- to make and easy to break by accident, so this test measures it rather than
-- assuming it: it plays hundreds of thousands of real hands through the real
-- engine and checks the counter actually comes out ahead.
--
-- The counting system simulated here is Hi-Lo, the standard balanced count:
-- +1 for each 2-6 dealt, 0 for each 7-9, -1 for each 10/J/Q/K/A. The running
-- count is divided by the number of decks still in the shoe to give the "true
-- count", and each +1 of true count shifts roughly half a percent of edge to
-- the player, which is what the bet ramp below is exploiting.
-- Reference: https://www.blackjackapprenticeship.com/hi-lo-system-guide-for-card-counting-blackjack/
--
-- The control run at the bottom is what makes this a real test: it replays the
-- exact same logic against the OLD behavior (a fresh shuffle before every
-- hand) and requires the counter's edge to vanish. If someone reverts the shoe
-- to a per-hand deck, the main run stops beating the control and this fails.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_blackjack_counting.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

-- Deterministic shuffles. The engine prefers the game's own ZombRand when it
-- exists, so providing one here makes every run of this test identical on
-- every machine -- important for a test that asserts on measured averages.
local randomState = 20260828
local function PZLinuxCountingRandom(minInclusive, maxExclusive)
    randomState = (randomState * 16807) % 2147483647
    return minInclusive + (randomState % (maxExclusive - minInclusive))
end
ZombRand = PZLinuxCountingRandom

PZLinux = {}
dofile(luaRoot .. "/shared/PZLinux/PZLinuxConfig.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxBlackjackEngine.lua")

local HI_LO = {
    ["2"] = 1, ["3"] = 1, ["4"] = 1, ["5"] = 1, ["6"] = 1,
    ["7"] = 0, ["8"] = 0, ["9"] = 0,
    ["10"] = -1, J = -1, Q = -1, K = -1, A = -1,
}

-- A balanced count must sum to zero over a full deck, or the true count it
-- produces is biased and every measurement below would be meaningless.
local balance = 0
for _, suit in ipairs(PZLinux.Config.Blackjack.suits) do
    for _, rank in ipairs(PZLinux.Config.Blackjack.ranks) do
        assert(HI_LO[rank] ~= nil, "every rank needs a Hi-Lo tag, missing " .. tostring(rank) .. tostring(suit))
        balance = balance + HI_LO[rank]
    end
end
assert(balance == 0, "Hi-Lo is a balanced count: one full deck must tag out to exactly zero")

-- Whether the hand is holding an ace still counted as 11, which changes how it
-- should be played: a soft hand cannot bust by taking one more card.
local function PZLinuxCountingIsSoft(hand)
    local hardTotal = 0
    local hasAce = false
    for _, card in ipairs(hand) do
        if card.rank == "A" then
            hasAce = true
            hardTotal = hardTotal + 1
        else
            hardTotal = hardTotal + PZLinuxBlackjackCardValue(card)
        end
    end
    return hasAce and PZLinuxBlackjackHandValue(hand) == hardTotal + 10
end

-- Basic strategy for the rules this game actually deals: dealer stands on all
-- 17s, and there is no doubling, splitting or insurance, so every decision is
-- hit or stand. Playing correctly matters here -- a counter betting big while
-- misplaying hands would measure the misplay, not the count.
local function PZLinuxCountingShouldHit(hand, dealerUpValue)
    local total = PZLinuxBlackjackHandValue(hand)

    if PZLinuxCountingIsSoft(hand) then
        if total >= 19 then return false end
        if total == 18 then return dealerUpValue >= 9 end
        return true
    end

    if total >= 17 then return false end
    if total >= 13 then return dealerUpValue >= 7 end
    if total == 12 then return dealerUpValue < 4 or dealerUpValue > 6 end
    return true
end

-- One unit, sized so the 3:2 natural pays a whole number and nothing is lost
-- to the payout's floor().
local UNIT = 100
local HANDS = 200000

-- What a counter does with the count: flat minimum until the shoe is genuinely
-- rich, then a steep ramp. The spread is where a counter's money is actually
-- made -- the edge at a high true count is small, so it only shows up if the
-- bet is large exactly then and small the rest of the time.
local function PZLinuxCountingBetUnits(trueCount)
    if trueCount >= 4 then return 8 end
    if trueCount >= 3 then return 4 end
    if trueCount >= 2 then return 2 end
    return 1
end

-- Plays `hands` hands of real blackjack off the real shoe, keeping a Hi-Lo
-- count exactly as a player at the table could. Returns what flat betting and
-- what counted betting made, plus how each hand did split by true count.
--
-- reshuffleEveryHand reproduces the behavior this feature replaced: a freshly
-- shuffled deck before every hand, with the counter none the wiser and still
-- counting. It is the control -- against a fresh deck the count must be worth
-- nothing.
local function PZLinuxCountingSimulate(tableDef, hands, reshuffleEveryHand)
    PZLinux.Blackjack.Shoes = {}

    local flatNet, countedNet = 0, 0
    local highCountNet, highCountHands = 0, 0
    local lowCountNet, lowCountHands = 0, 0
    local runningCount = 0

    for _ = 1, hands do
        local shoe = PZLinuxBlackjackShoeAcquire(tableDef)
        if reshuffleEveryHand then
            PZLinuxBlackjackShoeFill(shoe)
        elseif shoe.shuffled then
            -- The shoe turned over since the last hand, so everything counted
            -- before it is worthless. A real counter resets here too.
            runningCount = 0
        end

        local decksRemaining = #shoe.cards / 52
        if decksRemaining < 0.25 then decksRemaining = 0.25 end
        local trueCount = runningCount / decksRemaining
        local betUnits = PZLinuxCountingBetUnits(trueCount)
        local shuffleIdAtDeal = shoe.shuffleId

        local playerHand = { PZLinuxBlackjackShoeDraw(shoe) }
        local dealerHand = { PZLinuxBlackjackShoeDraw(shoe) }
        table.insert(playerHand, PZLinuxBlackjackShoeDraw(shoe))
        table.insert(dealerHand, PZLinuxBlackjackShoeDraw(shoe))

        local outcome = PZLinuxBlackjackResolveNaturals(playerHand, dealerHand)
        if not outcome then
            local dealerUpValue = PZLinuxBlackjackCardValue(dealerHand[1])
            while PZLinuxBlackjackHandValue(playerHand) <= 21
                and PZLinuxCountingShouldHit(playerHand, dealerUpValue) do
                table.insert(playerHand, PZLinuxBlackjackShoeDraw(shoe))
            end

            if PZLinuxBlackjackHandValue(playerHand) > 21 then
                outcome = "lose"
            else
                while PZLinuxBlackjackDealerShouldHit(dealerHand) do
                    table.insert(dealerHand, PZLinuxBlackjackShoeDraw(shoe))
                end
                outcome = PZLinuxBlackjackResolveStand(
                    PZLinuxBlackjackHandValue(playerHand),
                    PZLinuxBlackjackHandValue(dealerHand))
            end
        end

        -- Settled through the same payout the server credits players with.
        local netPerUnit = (PZLinuxBlackjackPayout(outcome, UNIT) - UNIT) / UNIT
        flatNet = flatNet + netPerUnit
        countedNet = countedNet + netPerUnit * betUnits

        if trueCount >= 2 then
            highCountNet = highCountNet + netPerUnit
            highCountHands = highCountHands + 1
        elseif trueCount <= -2 then
            lowCountNet = lowCountNet + netPerUnit
            lowCountHands = lowCountHands + 1
        end

        -- Every card both hands showed is now visible to everyone at the
        -- table, so it goes into the count -- unless the shoe turned over
        -- mid-hand, in which case part of this hand came from cards that are
        -- back in play and the count has to start again.
        if shoe.shuffleId ~= shuffleIdAtDeal then
            runningCount = 0
        else
            for _, hand in ipairs({ playerHand, dealerHand }) do
                for _, card in ipairs(hand) do
                    runningCount = runningCount + (HI_LO[card.rank] or 0)
                end
            end
        end
    end

    return {
        flatPerHand = flatNet / hands,
        countedPerHand = countedNet / hands,
        highCountPerHand = highCountHands > 0 and (highCountNet / highCountHands) or 0,
        lowCountPerHand = lowCountHands > 0 and (lowCountNet / lowCountHands) or 0,
        highCountHands = highCountHands,
        lowCountHands = lowCountHands,
    }
end

local microTable = assert(PZLinuxBlackjackGetTable("micro"))
local eliteTable = assert(PZLinuxBlackjackGetTable("elite"))

local single = PZLinuxCountingSimulate(microTable, HANDS, false)

-- Sanity first: if the simulated game were not really blackjack, everything
-- measured after this would be meaningless. Flat basic strategy against a
-- dealer who stands on 17, with no doubling or splitting available, should
-- land a little under break-even -- a small house edge, not a rout either way.
assert(single.flatPerHand < 0.01 and single.flatPerHand > -0.05, string.format(
    "flat basic strategy should sit near break-even with a small house edge, got %.4f per hand",
    single.flatPerHand))

assert(single.highCountHands > 1000 and single.lowCountHands > 1000, string.format(
    "the count must actually swing during play, saw %d high-count and %d low-count hands",
    single.highCountHands, single.lowCountHands))

-- The core claim: hands dealt while the shoe is rich in tens and aces really
-- do go better for the player than hands dealt while it is poor in them. This
-- is what "counting works" means, before any bet sizing is involved.
local countSpread = single.highCountPerHand - single.lowCountPerHand
assert(countSpread > 0.03, string.format(
    "a high true count must play measurably better than a low one: high %.4f, low %.4f, spread %.4f",
    single.highCountPerHand, single.lowCountPerHand, countSpread))

-- And it has to be worth money, not just measurable: betting more when the
-- count is high must beat betting flat over the very same hands.
assert(single.countedPerHand > single.flatPerHand + 0.01, string.format(
    "ramping the bet with the count must beat flat betting by a real margin, not a rounding error: " ..
    "counted %.4f vs flat %.4f per hand", single.countedPerHand, single.flatPerHand))

-- The control. Same player, same count, same ramp -- but the deck is freshly
-- shuffled before every hand, which is exactly what this feature replaced.
-- Every hand is then drawn from an identical fresh distribution, so the count
-- describes nothing and its edge must collapse.
local reshuffled = PZLinuxCountingSimulate(microTable, HANDS, true)
local controlSpread = reshuffled.highCountPerHand - reshuffled.lowCountPerHand

assert(math.abs(controlSpread) < 0.03, string.format(
    "against a deck reshuffled every hand the count must be worth nothing, but high-count hands " ..
    "returned %.4f and low-count hands %.4f (spread %.4f)",
    reshuffled.highCountPerHand, reshuffled.lowCountPerHand, controlSpread))
assert(countSpread > controlSpread * 2 and countSpread - controlSpread > 0.03, string.format(
    "counting must be worth substantially more against the persistent shoe (%.4f) than against a " ..
    "deck reshuffled every hand (%.4f) -- if these ever converge, the shoe has stopped persisting",
    countSpread, controlSpread))

-- Deck count is the difficulty dial: the same count kept the same way is worth
-- less at the three-deck elite table than at the single-deck micro table,
-- because each individual card moves a three-deck shoe far less.
local triple = PZLinuxCountingSimulate(eliteTable, HANDS, false)
local tripleSpread = triple.highCountPerHand - triple.lowCountPerHand
assert(tripleSpread > 0, string.format(
    "counting must still work at a three-deck table, just less well: spread %.4f", tripleSpread))
assert(tripleSpread < countSpread, string.format(
    "a three-deck shoe must be harder to profit from than a single deck: three-deck spread %.4f, " ..
    "single-deck spread %.4f", tripleSpread, countSpread))

print(string.format(
    "Blackjack counting audit OK: %d hands/run, single deck flat %+.4f counted %+.4f (high %+.4f low %+.4f), " ..
    "three deck spread %+.4f, reshuffle-every-hand control spread %+.4f",
    HANDS, single.flatPerHand, single.countedPerHand, single.highCountPerHand, single.lowCountPerHand,
    tripleSpread, controlSpread))
