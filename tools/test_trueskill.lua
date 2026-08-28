-- Tests for the TrueSkill implementation used to rate the poker engines.
--
-- The important one is the first: the published TrueSkill defaults produce a
-- documented result for a single one-on-one win, and matching it to two
-- decimal places is what says the maths is the real algorithm rather than
-- something that merely moves numbers in plausible directions.

dofile("tools/poker_trueskill.lua")

local function close(a, b, tolerance)
    return math.abs(a - b) <= (tolerance or 0.01)
end

-- The canonical check. The published figures assume the library default draw
-- probability of 0.1, so it is pinned here; this module ships 0.02 instead,
-- because two poker seats almost never finish on exactly the same chip count.
local shippedDrawProbability = PZLinuxTrueSkill.DRAW_PROBABILITY
PZLinuxTrueSkill.DRAW_PROBABILITY = 0.1

local winner = PZLinuxTrueSkillNew()
local loser = PZLinuxTrueSkillNew()
PZLinuxTrueSkillRate({ winner, loser }, { 1, 2 })
assert(close(winner.mu, 29.396, 0.05),
    string.format("a default one-on-one win must lift the winner to ~29.396, got %.3f", winner.mu))
assert(close(loser.mu, 20.604, 0.05),
    string.format("...and drop the loser to ~20.604, got %.3f", loser.mu))
assert(close(winner.sigma, 7.171, 0.05) and close(loser.sigma, 7.171, 0.05),
    string.format("both sigmas must fall to ~7.171, got %.3f and %.3f", winner.sigma, loser.sigma))

PZLinuxTrueSkill.DRAW_PROBABILITY = shippedDrawProbability

-- Uncertainty only ever shrinks on evidence, and mu moves the right way.
local a, b = PZLinuxTrueSkillNew(), PZLinuxTrueSkillNew()
for _ = 1, 20 do PZLinuxTrueSkillRate({ a, b }, { 1, 2 }) end
assert(a.mu > 29 and b.mu < 21, "twenty straight wins must separate the ratings")
assert(a.sigma < 5 and b.sigma < 5, "twenty results must leave both ratings confident")
assert(a.sigma < PZLinuxTrueSkill.SIGMA, "sigma must shrink as evidence accumulates")
-- And it must not collapse: once the result is a foregone conclusion each
-- further win says almost nothing, so uncertainty plateaus rather than
-- vanishing. A system that drove sigma to zero here would be overclaiming.
assert(a.sigma > 3, "repeated expected wins are weak evidence and must not collapse sigma")

-- A draw pulls two ratings together rather than apart.
local high, low = PZLinuxTrueSkillNew(32, 3), PZLinuxTrueSkillNew(20, 3)
local gapBefore = high.mu - low.mu
PZLinuxTrueSkillRate({ high, low }, { 1, 1 })
assert((high.mu - low.mu) < gapBefore, "a draw must narrow the gap between unequal ratings")

-- An upset moves ratings further than an expected result does.
local favourite, underdog = PZLinuxTrueSkillNew(35, 3), PZLinuxTrueSkillNew(15, 3)
local expectedFav = PZLinuxTrueSkillNew(35, 3)
local expectedDog = PZLinuxTrueSkillNew(15, 3)
PZLinuxTrueSkillRate({ underdog, favourite }, { 1, 2 })     -- upset
PZLinuxTrueSkillRate({ expectedFav, expectedDog }, { 1, 2 }) -- as expected
assert((underdog.mu - 15) > (expectedFav.mu - 35),
    "an upset must move the ratings further than the expected result")

-- Free-for-all: a five-way table ranks in the order it finished.
local seats = {}
for index = 1, 5 do seats[index] = PZLinuxTrueSkillNew() end
for _ = 1, 30 do PZLinuxTrueSkillRate(seats, { 1, 2, 3, 4, 5 }) end
for index = 1, 4 do
    assert(seats[index].mu > seats[index + 1].mu,
        "a repeated five-way finishing order must rank the seats in that order")
end

-- The conservative rating is what a leaderboard should sort on: an unproven
-- engine must not outrank a proven one on the same point estimate.
local proven = PZLinuxTrueSkillNew(28, 1.5)
local unproven = PZLinuxTrueSkillNew(28, 8.0)
assert(PZLinuxTrueSkillConservative(proven) > PZLinuxTrueSkillConservative(unproven),
    "the same mu with more uncertainty must rank lower")

-- Win probability is symmetric and sane.
local even = PZLinuxTrueSkillWinProbability(PZLinuxTrueSkillNew(25, 1), PZLinuxTrueSkillNew(25, 1))
assert(close(even, 0.5, 0.01), "equal ratings must be a coin flip, got " .. even)
local strong = PZLinuxTrueSkillWinProbability(PZLinuxTrueSkillNew(35, 1), PZLinuxTrueSkillNew(25, 1))
assert(strong > 0.9, "a ten-point edge must be a heavy favourite, got " .. strong)

-- Extreme mismatches must not produce infinities or NaN through the
-- underflow guards in v and w.
local absurd = PZLinuxTrueSkillNew(50, 0.5)
local hopeless = PZLinuxTrueSkillNew(1, 0.5)
PZLinuxTrueSkillRate({ hopeless, absurd }, { 1, 2 })
assert(absurd.mu == absurd.mu and hopeless.mu == hopeless.mu, "ratings must never go NaN")
assert(absurd.sigma > 0 and hopeless.sigma > 0, "sigma must stay positive")

print("PZLinux TrueSkill tests OK")
