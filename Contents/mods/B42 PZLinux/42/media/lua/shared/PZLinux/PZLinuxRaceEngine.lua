PZLinux = PZLinux or {}
PZLinux.Race = PZLinux.Race or {}

PZLinux.Race.runnerCount = PZLinux.Race.runnerCount or 8
PZLinux.Race.startPosition = PZLinux.Race.startPosition or -15
PZLinux.Race.finishPosition = PZLinux.Race.finishPosition or 130
PZLinux.Race.maxTicks = PZLinux.Race.maxTicks or 120
PZLinux.Race.baseSpeed = PZLinux.Race.baseSpeed or 5
PZLinux.Race.takeoutRate = PZLinux.Race.takeoutRate or 0.15
PZLinux.Race.minimumBettors = PZLinux.Race.minimumBettors or 200
PZLinux.Race.maximumBettors = PZLinux.Race.maximumBettors or 800
PZLinux.Race.minimumVirtualStake = PZLinux.Race.minimumVirtualStake or 25
PZLinux.Race.maximumVirtualStake = PZLinux.Race.maximumVirtualStake or 500
PZLinux.Race.maximumPlayerPoolShare = PZLinux.Race.maximumPlayerPoolShare or 0.10
PZLinux.Race.maximumPlayerBet = PZLinux.Race.maximumPlayerBet or 2000
PZLinux.Race.crowdSpeedExponent = PZLinux.Race.crowdSpeedExponent or 39
PZLinux.Race.serverLiquidityRate = PZLinux.Race.serverLiquidityRate or 0.04

local function PZLinuxRaceDefaultRandom(minimum, maximumExclusive)
    if ZombRand then
        return ZombRand(minimum, maximumExclusive)
    end
    return math.random(minimum, maximumExclusive - 1)
end

local function PZLinuxRaceRandom(randomFunction, minimum, maximumExclusive)
    return (randomFunction or PZLinuxRaceDefaultRandom)(minimum, maximumExclusive)
end

function PZLinuxRaceGenerateCard(runnerPool, runnerCount, randomFunction)
    local pool = {}
    for _, runner in ipairs(runnerPool or {}) do
        table.insert(pool, {
            name = runner.name,
            rating = PZLinuxRaceRandom(randomFunction, runner.rating, runner.maxRating + 1),
        })
    end

    for index = #pool, 2, -1 do
        local swapIndex = PZLinuxRaceRandom(randomFunction, 1, index + 1)
        pool[index], pool[swapIndex] = pool[swapIndex], pool[index]
    end

    local runners = {}
    local count = math.min(tonumber(runnerCount) or PZLinux.Race.runnerCount, #pool)
    for index = 1, count do
        table.insert(runners, pool[index])
    end
    return runners
end

function PZLinuxRaceGetExpectedSpeed(rating)
    local bonusRange = math.max(0, 100 - (tonumber(rating) or 2))
    return PZLinux.Race.baseSpeed + bonusRange / 50
end

function PZLinuxRaceGetSpeed(rating, randomFunction)
    local bonusRange = math.max(0, 100 - (tonumber(rating) or 2))
    return PZLinux.Race.baseSpeed
        + PZLinuxRaceRandom(randomFunction, 0, bonusRange + 1) / 25
end

local function PZLinuxRaceSelectWeightedRunner(runners, totalWeight, randomFunction)
    local draw = PZLinuxRaceRandom(randomFunction, 1, totalWeight + 1)
    local cumulative = 0
    for index, runner in ipairs(runners) do
        cumulative = cumulative + runner.crowdWeight
        if draw <= cumulative then return index end
    end
    return #runners
end

function PZLinuxRaceGetPoolMultiplier(poolTotal, runnerStake, takeoutRate, postCommissionLiquidity)
    poolTotal = math.max(0, tonumber(poolTotal) or 0)
    runnerStake = math.max(0, tonumber(runnerStake) or 0)
    if runnerStake <= 0 then return 999.99 end
    local netPool = poolTotal * (1 - (tonumber(takeoutRate) or PZLinux.Race.takeoutRate))
        + math.max(0, tonumber(postCommissionLiquidity) or 0)
    return math.floor((netPool / runnerStake) * 100) / 100
end

function PZLinuxRaceCreateBettingPool(runners, randomFunction, options)
    options = options or {}
    local minimumBettors = tonumber(options.minimumBettors) or PZLinux.Race.minimumBettors
    local maximumBettors = tonumber(options.maximumBettors) or PZLinux.Race.maximumBettors
    local minimumStake = tonumber(options.minimumStake) or PZLinux.Race.minimumVirtualStake
    local maximumStake = tonumber(options.maximumStake) or PZLinux.Race.maximumVirtualStake
    local maximumPlayerPoolShare = tonumber(options.maximumPlayerPoolShare)
        or PZLinux.Race.maximumPlayerPoolShare
    local maximumPlayerBet = tonumber(options.maximumPlayerBet) or PZLinux.Race.maximumPlayerBet
    local serverLiquidityRate = options.serverLiquidityRate
    if serverLiquidityRate == nil then serverLiquidityRate = PZLinux.Race.serverLiquidityRate end
    local fixedServerLiquidity = math.max(0, tonumber(options.fixedServerLiquidity) or 0)
    local liquidityAfterCommission = options.liquidityAfterCommission == true
    local totalWeight = 0
    for _, runner in ipairs(runners or {}) do
        local relativeSpeed = PZLinuxRaceGetExpectedSpeed(runner.rating) / PZLinux.Race.baseSpeed
        runner.crowdWeight = math.max(1, math.floor(relativeSpeed ^ PZLinux.Race.crowdSpeedExponent * 100))
        runner.bettorCount = 0
        runner.poolStake = 0
        totalWeight = totalWeight + runner.crowdWeight
    end

    local bettorCount = PZLinuxRaceRandom(
        randomFunction,
        minimumBettors,
        maximumBettors + 1
    )
    local poolTotal = 0
    for _ = 1, bettorCount do
        local runnerIndex = PZLinuxRaceSelectWeightedRunner(runners, totalWeight, randomFunction)
        local stake = PZLinuxRaceRandom(
            randomFunction,
            minimumStake,
            maximumStake + 1
        )
        stake = math.max(5, math.floor((stake + 2) / 5) * 5)
        runners[runnerIndex].bettorCount = runners[runnerIndex].bettorCount + 1
        runners[runnerIndex].poolStake = runners[runnerIndex].poolStake + stake
        poolTotal = poolTotal + stake
    end

    local serverLiquidity = fixedServerLiquidity > 0 and fixedServerLiquidity
        or math.floor(poolTotal * serverLiquidityRate / 5) * 5
    local postCommissionLiquidity = liquidityAfterCommission and serverLiquidity or 0
    local prizePool = liquidityAfterCommission and poolTotal or poolTotal + serverLiquidity
    for _, runner in ipairs(runners or {}) do
        runner.multiplier = PZLinuxRaceGetPoolMultiplier(
            prizePool,
            runner.poolStake,
            PZLinux.Race.takeoutRate,
            postCommissionLiquidity
        )
        runner.odds = math.max(0, runner.multiplier - 1)
        runner.crowdWeight = nil
    end

    local poolShareMaximumBet = math.max(5, math.floor(poolTotal * maximumPlayerPoolShare / 5) * 5)
    return {
        bettorCount = bettorCount,
        marketPool = poolTotal,
        serverLiquidity = serverLiquidity,
        postCommissionLiquidity = postCommissionLiquidity,
        poolTotal = prizePool,
        takeoutRate = PZLinux.Race.takeoutRate,
        maximumBet = math.min(maximumPlayerBet, poolShareMaximumBet),
    }
end

function PZLinuxRaceSimulateWinner(runners, randomFunction)
    local progress = {}
    for index, runner in ipairs(runners or {}) do
        progress[index] = { runner = runner, position = PZLinux.Race.startPosition }
    end

    for tick = 1, PZLinux.Race.maxTicks do
        for _, data in ipairs(progress) do
            data.position = data.position + PZLinuxRaceGetSpeed(data.runner.rating, randomFunction)
        end

        local bestPosition = -math.huge
        local leaders = {}
        for index, data in ipairs(progress) do
            if data.position > bestPosition then
                bestPosition = data.position
                leaders = { index }
            elseif data.position == bestPosition then
                table.insert(leaders, index)
            end
        end

        if bestPosition >= PZLinux.Race.finishPosition then
            local winnerId = leaders[PZLinuxRaceRandom(randomFunction, 1, #leaders + 1)]
            return winnerId, tick, progress
        end
    end

    return 1, PZLinux.Race.maxTicks, progress
end

function PZLinuxRaceSelectLowestOdds(runners, randomFunction)
    local lowestMultiplier = math.huge
    local candidates = {}

    for index, runner in ipairs(runners or {}) do
        local multiplier = tonumber(runner.multiplier) or tonumber(runner.rating) or math.huge
        if multiplier < lowestMultiplier then
            lowestMultiplier = multiplier
            candidates = { index }
        elseif multiplier == lowestMultiplier then
            table.insert(candidates, index)
        end
    end

    if #candidates == 0 then return nil, 0, nil end
    local selected = PZLinuxRaceRandom(randomFunction, 1, #candidates + 1)
    return candidates[selected], #candidates, lowestMultiplier
end

function PZLinuxRaceCalculatePayout(amount, poolTotal, winnerPoolStake, won, takeoutRate, postCommissionLiquidity)
    if not won then return 0 end
    amount = math.max(0, tonumber(amount) or 0)
    local grossPool = math.max(0, tonumber(poolTotal) or 0) + amount
    local winningPool = math.max(0, tonumber(winnerPoolStake) or 0) + amount
    if winningPool <= 0 then return 0 end
    local netPool = math.floor(
        grossPool * (1 - (tonumber(takeoutRate) or PZLinux.Race.takeoutRate))
        + math.max(0, tonumber(postCommissionLiquidity) or 0)
    )
    return math.max(amount, math.floor(netPool * amount / winningPool))
end

function PZLinuxRaceCalculateFinalOdds(amount, poolTotal, selectedPoolStake, takeoutRate, postCommissionLiquidity)
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then return 0 end
    local payout = PZLinuxRaceCalculatePayout(
        amount,
        poolTotal,
        selectedPoolStake,
        true,
        takeoutRate,
        postCommissionLiquidity
    )
    return math.max(0, payout / amount - 1)
end

function PZLinuxRaceCalculateSettledPayout(amount, poolTotal, winnerPoolStake, won, takeoutRate, postCommissionLiquidity)
    if not won then return 0 end
    amount = math.max(0, tonumber(amount) or 0)
    winnerPoolStake = math.max(0, tonumber(winnerPoolStake) or 0)
    if amount <= 0 or winnerPoolStake <= 0 then return 0 end
    local netPool = math.floor(
        math.max(0, tonumber(poolTotal) or 0)
            * (1 - (tonumber(takeoutRate) or PZLinux.Race.takeoutRate))
        + math.max(0, tonumber(postCommissionLiquidity) or 0)
    )
    return math.max(amount, math.floor(netPool * amount / winnerPoolStake))
end
