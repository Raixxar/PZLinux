-- TrueSkill ratings, for rating poker engines from free-for-all tables.
--
-- Elo was built for two-player games decided by win or lose. A poker table is
-- a five-way free-for-all decided by chip counts, and the usual way to force
-- Elo onto that -- decompose the table into every pair of seats and update
-- each pair independently -- double-counts evidence and has no way to say how
-- confident it is in any rating.
--
-- TrueSkill models each player as a Gaussian: mu is the estimated skill, sigma
-- the uncertainty in that estimate. A result moves mu toward what happened and
-- shrinks sigma, and how far it moves depends on how surprising the result was
-- and how uncertain both players were. A new engine's rating therefore moves
-- fast and settles as evidence accumulates, and the leaderboard can report the
-- conservative mu - 3*sigma: the skill the evidence supports rather than the
-- skill the point estimate flatters.
--
-- Free-for-all handling: players are sorted by finishing position and updated
-- along the chain of adjacent pairs. This is the standard single-pass
-- approximation rather than full expectation propagation over the factor
-- graph -- the real algorithm iterates messages until convergence. For ranking
-- ten poker engines over thousands of tables the difference is immaterial, but
-- it is an approximation and worth naming as one.
--
-- Defaults follow the published ones: mu 25, sigma 25/3, beta sigma/2 (the
-- skill distance giving roughly a 76% win chance), tau sigma/100 (how much
-- skill is assumed to drift between matches).

PZLinuxTrueSkill = PZLinuxTrueSkill or {}

PZLinuxTrueSkill.MU = 25.0
PZLinuxTrueSkill.SIGMA = 25.0 / 3.0
PZLinuxTrueSkill.BETA = 25.0 / 6.0
PZLinuxTrueSkill.TAU = 25.0 / 300.0
PZLinuxTrueSkill.DRAW_PROBABILITY = 0.02

local SQRT2 = math.sqrt(2)
local SQRT2PI = math.sqrt(2 * math.pi)

-- Abramowitz and Stegun 7.1.26: enough precision for rating work.
local function erf(x)
    local sign = x < 0 and -1 or 1
    x = math.abs(x)
    local t = 1 / (1 + 0.3275911 * x)
    local y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t
        + 0.254829592) * t * math.exp(-x * x)
    return sign * y
end

local function pdf(x)
    return math.exp(-0.5 * x * x) / SQRT2PI
end

local function cdf(x)
    return 0.5 * (1 + erf(x / SQRT2))
end

-- Inverse CDF by bisection. Slower than a rational approximation and far
-- easier to be sure of; it runs once per rating configuration, not per update.
local function ppf(p)
    if p <= 0 then return -40 end
    if p >= 1 then return 40 end
    local low, high = -40, 40
    for _ = 1, 200 do
        local mid = (low + high) / 2
        if cdf(mid) < p then low = mid else high = mid end
    end
    return (low + high) / 2
end

-- The truncated-Gaussian corrections. v is how far the mean is dragged, w how
-- much the variance shrinks. The guards matter: when a result is extremely
-- surprising the denominator underflows, and the limiting value has to be
-- substituted or the rating explodes.
local function vWin(diff, margin)
    local x = diff - margin
    local denom = cdf(x)
    if denom < 1e-12 then return -x end
    return pdf(x) / denom
end

local function wWin(diff, margin)
    local x = diff - margin
    local v = vWin(diff, margin)
    local w = v * (v + x)
    if w > 0 and w < 1 then return w end
    -- Same underflow case: the variance update saturates.
    return 1
end

local function vDraw(diff, margin)
    local absDiff = math.abs(diff)
    local a, b = margin - absDiff, -margin - absDiff
    local denom = cdf(a) - cdf(b)
    local numer = pdf(b) - pdf(a)
    local value = (denom < 1e-12) and a or (numer / denom)
    return diff < 0 and -value or value
end

local function wDraw(diff, margin)
    local absDiff = math.abs(diff)
    local a, b = margin - absDiff, -margin - absDiff
    local denom = cdf(a) - cdf(b)
    if denom < 1e-12 then return 1 end
    local v = vDraw(absDiff, margin)
    return v * v + (a * pdf(a) - b * pdf(b)) / denom
end

-- The chip-count gap two players must be within to count as a draw, derived
-- from how often draws are expected.
function PZLinuxTrueSkillDrawMargin(drawProbability, beta, players)
    return ppf((drawProbability + 1) / 2) * math.sqrt(players) * beta
end

function PZLinuxTrueSkillNew(mu, sigma)
    return { mu = mu or PZLinuxTrueSkill.MU, sigma = sigma or PZLinuxTrueSkill.SIGMA }
end

-- What the leaderboard shows: the skill the evidence actually supports, three
-- standard deviations below the estimate. An engine with few tables is ranked
-- low until it has proved otherwise, which is the behaviour wanted.
function PZLinuxTrueSkillConservative(rating)
    return rating.mu - 3 * rating.sigma
end

-- ratings: array of { mu, sigma }, ranks: array of finishing positions where
-- a lower number finished better and equal numbers are draws. Updates in
-- place and returns the ratings.
function PZLinuxTrueSkillRate(ratings, ranks)
    local beta = PZLinuxTrueSkill.BETA
    local tau = PZLinuxTrueSkill.TAU
    local margin = PZLinuxTrueSkillDrawMargin(PZLinuxTrueSkill.DRAW_PROBABILITY, beta, 2)

    local order = {}
    for index = 1, #ratings do order[index] = index end
    table.sort(order, function(a, b) return ranks[a] < ranks[b] end)

    -- Skill is assumed to drift a little between matches, so uncertainty grows
    -- before the result is folded in. Without this every rating eventually
    -- freezes and stops responding to new evidence.
    for _, index in ipairs(order) do
        local rating = ratings[index]
        rating.sigma = math.sqrt(rating.sigma * rating.sigma + tau * tau)
    end

    for position = 1, #order - 1 do
        local betterIndex = order[position]
        local worseIndex = order[position + 1]
        local better, worse = ratings[betterIndex], ratings[worseIndex]
        local drawn = ranks[betterIndex] == ranks[worseIndex]

        local c = math.sqrt(2 * beta * beta + better.sigma * better.sigma + worse.sigma * worse.sigma)
        local diff = (better.mu - worse.mu) / c
        local scaledMargin = margin / c

        local v, w
        if drawn then
            v = vDraw(diff, scaledMargin)
            w = wDraw(diff, scaledMargin)
        else
            v = vWin(diff, scaledMargin)
            w = wWin(diff, scaledMargin)
        end

        local betterVariance = better.sigma * better.sigma
        local worseVariance = worse.sigma * worse.sigma

        better.mu = better.mu + (betterVariance / c) * v
        worse.mu = worse.mu - (worseVariance / c) * v
        better.sigma = math.sqrt(betterVariance * math.max(1e-6, 1 - (betterVariance / (c * c)) * w))
        worse.sigma = math.sqrt(worseVariance * math.max(1e-6, 1 - (worseVariance / (c * c)) * w))
    end

    return ratings
end

-- Probability the first rating beats the second, for reading a leaderboard.
function PZLinuxTrueSkillWinProbability(a, b)
    local beta = PZLinuxTrueSkill.BETA
    local c = math.sqrt(2 * beta * beta + a.sigma * a.sigma + b.sigma * b.sigma)
    return cdf((a.mu - b.mu) / c)
end
