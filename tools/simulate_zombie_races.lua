local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/simulate_zombie_races.lua$") or "."

local options = {
    runs = 1000,
    stake = 100,
    seed = os.time(),
    output = repoRoot .. "/doc/RAPPORT_ZOMBIE_RACES.md",
    targetMin = 0.85,
    targetMax = 0.95,
    failOutsideTarget = false,
    crowdExponent = nil,
}

local function PZLinuxRaceSimulationUsage()
    print([[
Usage: lua5.1 tools/simulate_zombie_races.lua [options]

Options:
  --runs N                 Number of races (default: 1000)
  --stake N                Stake per race (default: 100)
  --seed N                 Reproducible random seed
  --output PATH            Markdown report path
  --target-min RATE        Minimum target RTP (default: 0.85)
  --target-max RATE        Maximum target RTP (default: 0.95)
  --crowd-exponent N       Override virtual-bettor sensitivity for calibration
  --fail-outside-target    Exit non-zero when RTP is outside the target
  --help                    Show this help
]])
end

local index = 1
while index <= #arg do
    local option = arg[index]
    if option == "--help" or option == "-h" then
        PZLinuxRaceSimulationUsage()
        os.exit(0)
    elseif option == "--fail-outside-target" then
        options.failOutsideTarget = true
        index = index + 1
    else
        local value = arg[index + 1]
        if not value then error("Missing value for " .. tostring(option)) end
        if option == "--runs" then options.runs = tonumber(value)
        elseif option == "--stake" then options.stake = tonumber(value)
        elseif option == "--seed" then options.seed = tonumber(value)
        elseif option == "--output" then options.output = value
        elseif option == "--target-min" then options.targetMin = tonumber(value)
        elseif option == "--target-max" then options.targetMax = tonumber(value)
        elseif option == "--crowd-exponent" then options.crowdExponent = tonumber(value)
        else error("Unknown option: " .. tostring(option)) end
        index = index + 2
    end
end

assert(options.runs and options.runs >= 1 and options.runs == math.floor(options.runs), "--runs must be a positive integer")
assert(options.stake and options.stake > 0, "--stake must be positive")
assert(options.seed and options.seed == math.floor(options.seed), "--seed must be an integer")
assert(options.targetMin and options.targetMax and options.targetMin <= options.targetMax, "invalid RTP target")

PZLinux = {}
dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxGamblingData.lua")
dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxRaceEngine.lua")
if options.crowdExponent then
    PZLinux.Race.crowdSpeedExponent = options.crowdExponent
end

math.randomseed(options.seed)

local function PZLinuxRaceSimulationRandom(minimum, maximumExclusive)
    return math.random(minimum, maximumExclusive - 1)
end

local function PZLinuxRaceSimulationStats()
    return {
        appearances = 0,
        wins = 0,
        selections = 0,
        selectedWins = 0,
        selectedStake = 0,
        selectedPayout = 0,
        ratingSum = 0,
    }
end

local function PZLinuxRaceSimulationGet(stats, key)
    if not stats[key] then stats[key] = PZLinuxRaceSimulationStats() end
    return stats[key]
end

local function PZLinuxRaceSimulationPercent(value)
    return string.format("%.2f%%", (tonumber(value) or 0) * 100)
end

local function PZLinuxRaceSimulationMoney(value)
    return string.format("$%.2f", tonumber(value) or 0)
end

local byRunner = {}
local bySelectedOdds = {}
local byPosition = {}
for position = 1, PZLinux.Race.runnerCount do
    byPosition[position] = PZLinuxRaceSimulationStats()
end

local totalStake = 0
local totalPayout = 0
local strategyWins = 0
local tiedFavoriteCards = 0
local totalFavoriteCandidates = 0
local totalTicks = 0
local returnSum = 0
local returnSquareSum = 0
local totalVirtualBettors = 0
local totalMarketPool = 0
local totalServerLiquidity = 0
local poolSamples = {
    bettors = {},
    market = {},
    liquidity = {},
    prize = {},
    maximumBet = {},
    favoriteOdds = {},
    allOdds = {},
}
local longOddsThresholds = { 10, 15, 20, 25, 50, 100 }
local longOddsRunnerCounts = {}
local longOddsCardCounts = {}
for _, threshold in ipairs(longOddsThresholds) do
    longOddsRunnerCounts[threshold] = 0
    longOddsCardCounts[threshold] = 0
end

for _ = 1, options.runs do
    local runners = PZLinuxRaceGenerateCard(
        PZLinuxRaceRunnerPool,
        PZLinux.Race.runnerCount,
        PZLinuxRaceSimulationRandom
    )
    local pool = PZLinuxRaceCreateBettingPool(runners, PZLinuxRaceSimulationRandom)
    local selectedIndex, candidateCount = PZLinuxRaceSelectLowestOdds(
        runners,
        PZLinuxRaceSimulationRandom
    )
    local winnerIndex, ticks = PZLinuxRaceSimulateWinner(runners, PZLinuxRaceSimulationRandom)
    local selectedRunner = runners[selectedIndex]
    local won = selectedIndex == winnerIndex
    local payout = PZLinuxRaceCalculatePayout(
        options.stake,
        pool.poolTotal,
        runners[winnerIndex].poolStake,
        won,
        pool.takeoutRate
    )

    totalStake = totalStake + options.stake
    totalPayout = totalPayout + payout
    totalTicks = totalTicks + ticks
    totalVirtualBettors = totalVirtualBettors + pool.bettorCount
    totalMarketPool = totalMarketPool + pool.marketPool
    totalServerLiquidity = totalServerLiquidity + pool.serverLiquidity
    table.insert(poolSamples.bettors, pool.bettorCount)
    table.insert(poolSamples.market, pool.marketPool)
    table.insert(poolSamples.liquidity, pool.serverLiquidity)
    table.insert(poolSamples.prize, pool.poolTotal)
    table.insert(poolSamples.maximumBet, pool.maximumBet)
    local cardHasLongOdds = {}
    for _, runner in ipairs(runners) do
        local runnerOdds = tonumber(runner.odds) or 0
        table.insert(poolSamples.allOdds, runnerOdds)
        for _, threshold in ipairs(longOddsThresholds) do
            if runnerOdds >= threshold then
                longOddsRunnerCounts[threshold] = longOddsRunnerCounts[threshold] + 1
                cardHasLongOdds[threshold] = true
            end
        end
    end
    for _, threshold in ipairs(longOddsThresholds) do
        if cardHasLongOdds[threshold] then
            longOddsCardCounts[threshold] = longOddsCardCounts[threshold] + 1
        end
    end
    totalFavoriteCandidates = totalFavoriteCandidates + candidateCount
    if candidateCount > 1 then tiedFavoriteCards = tiedFavoriteCards + 1 end
    if won then strategyWins = strategyWins + 1 end

    local returnMultiple = payout / options.stake
    returnSum = returnSum + returnMultiple
    returnSquareSum = returnSquareSum + returnMultiple * returnMultiple

    for runnerIndex, runner in ipairs(runners) do
        local runnerStats = PZLinuxRaceSimulationGet(byRunner, runner.name)
        runnerStats.appearances = runnerStats.appearances + 1
        runnerStats.ratingSum = runnerStats.ratingSum + runner.rating
        byPosition[runnerIndex].appearances = byPosition[runnerIndex].appearances + 1
        if runnerIndex == winnerIndex then
            runnerStats.wins = runnerStats.wins + 1
            byPosition[runnerIndex].wins = byPosition[runnerIndex].wins + 1
        end
    end

    local selectedStats = PZLinuxRaceSimulationGet(byRunner, selectedRunner.name)
    selectedStats.selections = selectedStats.selections + 1
    selectedStats.selectedStake = selectedStats.selectedStake + options.stake
    selectedStats.selectedPayout = selectedStats.selectedPayout + payout
    if won then selectedStats.selectedWins = selectedStats.selectedWins + 1 end

    local selectedOdds = PZLinuxRaceCalculateFinalOdds(
        options.stake,
        pool.poolTotal,
        selectedRunner.poolStake,
        pool.takeoutRate
    )
    table.insert(poolSamples.favoriteOdds, selectedOdds)
    local oddsBucket = math.floor(selectedOdds * 10) / 10
    local oddsStats = PZLinuxRaceSimulationGet(bySelectedOdds, oddsBucket)
    oddsStats.selections = oddsStats.selections + 1
    oddsStats.selectedStake = oddsStats.selectedStake + options.stake
    oddsStats.selectedPayout = oddsStats.selectedPayout + payout
    if won then oddsStats.selectedWins = oddsStats.selectedWins + 1 end
end

local rtp = totalPayout / totalStake
local houseEdge = 1 - rtp
local meanReturn = returnSum / options.runs
local variance = 0
if options.runs > 1 then
    variance = math.max(0, (returnSquareSum - options.runs * meanReturn * meanReturn) / (options.runs - 1))
end
local standardError = math.sqrt(variance / options.runs)
local confidenceLow = math.max(0, meanReturn - 1.96 * standardError)
local confidenceHigh = meanReturn + 1.96 * standardError
local largestPositionDeviation = 0
for position = 1, PZLinux.Race.runnerCount do
    local winRate = byPosition[position].wins / options.runs
    largestPositionDeviation = math.max(
        largestPositionDeviation,
        math.abs(winRate - (1 / PZLinux.Race.runnerCount))
    )
end

local minimumBucketSelections = math.max(100, math.floor(options.runs * 0.01))
local outlierOdds = {}
local bucketTolerance = 0.10
for rating, stats in pairs(bySelectedOdds) do
    if stats.selections >= minimumBucketSelections then
        local bucketRtp = stats.selectedPayout / stats.selectedStake
        if bucketRtp < options.targetMin - bucketTolerance
            or bucketRtp > options.targetMax + bucketTolerance then
            table.insert(outlierOdds, rating)
        end
    end
end
table.sort(outlierOdds)

local function PZLinuxRaceSimulationSummarize(values)
    table.sort(values)
    local total = 0
    for _, value in ipairs(values) do total = total + value end
    local function percentile(ratio)
        local percentileIndex = math.floor((#values - 1) * ratio) + 1
        return values[percentileIndex]
    end
    return {
        minimum = values[1],
        p10 = percentile(0.10),
        median = percentile(0.50),
        average = total / #values,
        p90 = percentile(0.90),
        maximum = values[#values],
    }
end

local poolSummaries = {
    bettors = PZLinuxRaceSimulationSummarize(poolSamples.bettors),
    market = PZLinuxRaceSimulationSummarize(poolSamples.market),
    liquidity = PZLinuxRaceSimulationSummarize(poolSamples.liquidity),
    prize = PZLinuxRaceSimulationSummarize(poolSamples.prize),
    maximumBet = PZLinuxRaceSimulationSummarize(poolSamples.maximumBet),
    favoriteOdds = PZLinuxRaceSimulationSummarize(poolSamples.favoriteOdds),
    allOdds = PZLinuxRaceSimulationSummarize(poolSamples.allOdds),
}

local assessment
if rtp > 1 then
    assessment = "Desequilibre en faveur du joueur : la strategie est profitable a long terme."
elseif rtp < 0.75 then
    assessment = "Tres defavorable au joueur : l'avantage maison est probablement excessif."
elseif rtp < options.targetMin then
    assessment = "Defavorable au joueur : le RTP est sous la cible d'equilibrage."
elseif rtp <= options.targetMax then
    assessment = "Dans la cible configuree."
else
    assessment = "Genereux pour le joueur : le RTP depasse la cible configuree."
end

local report = {}
local function PZLinuxRaceSimulationWrite(line)
    table.insert(report, line or "")
end

PZLinuxRaceSimulationWrite("# Rapport d'equilibrage Zombie Race")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Rapport genere le " .. os.date("!%Y-%m-%d %H:%M:%S UTC") .. ".")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("## Scenario")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("- Courses simulees : **" .. options.runs .. "**")
PZLinuxRaceSimulationWrite("- Mise fixe : **" .. PZLinuxRaceSimulationMoney(options.stake) .. "**")
PZLinuxRaceSimulationWrite("- Graine aleatoire : **" .. options.seed .. "**")
PZLinuxRaceSimulationWrite("- Sensibilite des parieurs : exposant **"
    .. PZLinux.Race.crowdSpeedExponent .. "**")
PZLinuxRaceSimulationWrite("- Strategie : choisir la cote pari-mutuel la plus basse; departager les ex aequo au hasard.")
PZLinuxRaceSimulationWrite("- Reglement : pool pari-mutuel, commission de **"
    .. PZLinuxRaceSimulationPercent(PZLinux.Race.takeoutRate) .. "**, partage proportionnel aux mises gagnantes.")
PZLinuxRaceSimulationWrite("- Liquidite serveur ajoutee au pool : **"
    .. PZLinuxRaceSimulationPercent(PZLinux.Race.serverLiquidityRate) .. "** des mises virtuelles.")
PZLinuxRaceSimulationWrite("- Cible RTP configuree : **" .. PZLinuxRaceSimulationPercent(options.targetMin)
    .. " a " .. PZLinuxRaceSimulationPercent(options.targetMax) .. "**")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("La simulation charge directement `PZLinuxGamblingData.lua` et `PZLinuxRaceEngine.lua`, le meme moteur pur que le serveur.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("## Verdict")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("**" .. assessment .. "**")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Indicateur | Resultat |")
PZLinuxRaceSimulationWrite("| --- | ---: |")
PZLinuxRaceSimulationWrite("| Mises totales | " .. PZLinuxRaceSimulationMoney(totalStake) .. " |")
PZLinuxRaceSimulationWrite("| Gains verses | " .. PZLinuxRaceSimulationMoney(totalPayout) .. " |")
PZLinuxRaceSimulationWrite("| Resultat net joueur | " .. PZLinuxRaceSimulationMoney(totalPayout - totalStake) .. " |")
PZLinuxRaceSimulationWrite("| Resultat net maison | " .. PZLinuxRaceSimulationMoney(totalStake - totalPayout) .. " |")
PZLinuxRaceSimulationWrite("| Victoires joueur | " .. strategyWins .. " / " .. options.runs .. " |")
PZLinuxRaceSimulationWrite("| Taux de victoire | " .. PZLinuxRaceSimulationPercent(strategyWins / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| RTP joueur | " .. PZLinuxRaceSimulationPercent(rtp) .. " |")
PZLinuxRaceSimulationWrite("| Avantage maison | " .. PZLinuxRaceSimulationPercent(houseEdge) .. " |")
PZLinuxRaceSimulationWrite("| Intervalle RTP 95 % | " .. PZLinuxRaceSimulationPercent(confidenceLow)
    .. " - " .. PZLinuxRaceSimulationPercent(confidenceHigh) .. " |")
PZLinuxRaceSimulationWrite("| Cartes avec favoris ex aequo | "
    .. PZLinuxRaceSimulationPercent(tiedFavoriteCards / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Nombre moyen de favoris minimum | "
    .. string.format("%.2f", totalFavoriteCandidates / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Duree moyenne | " .. string.format("%.2f ticks", totalTicks / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Parieurs virtuels moyens | " .. string.format("%.2f", totalVirtualBettors / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Mises virtuelles moyennes | " .. PZLinuxRaceSimulationMoney(totalMarketPool / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Liquidite serveur moyenne | " .. PZLinuxRaceSimulationMoney(totalServerLiquidity / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Pool de prix moyen | "
    .. PZLinuxRaceSimulationMoney((totalMarketPool + totalServerLiquidity) / options.runs) .. " |")
PZLinuxRaceSimulationWrite("| Tranches de cote significatives fortement hors cible | " .. #outlierOdds .. " |")
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Distribution des pools")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Les percentiles montrent la variation produite par les parieurs virtuels sur l'ensemble de la campagne.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Indicateur | Min | P10 | Mediane | Moyenne | P90 | Max |")
PZLinuxRaceSimulationWrite("| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
local function PZLinuxRaceSimulationWritePoolSummary(label, summary, formatter)
    PZLinuxRaceSimulationWrite(string.format(
        "| %s | %s | %s | %s | %s | %s | %s |",
        label,
        formatter(summary.minimum),
        formatter(summary.p10),
        formatter(summary.median),
        formatter(summary.average),
        formatter(summary.p90),
        formatter(summary.maximum)
    ))
end
PZLinuxRaceSimulationWritePoolSummary("Parieurs virtuels", poolSummaries.bettors, function(value)
    return string.format("%.0f", value)
end)
PZLinuxRaceSimulationWritePoolSummary("Mises virtuelles", poolSummaries.market, PZLinuxRaceSimulationMoney)
PZLinuxRaceSimulationWritePoolSummary("Liquidite serveur", poolSummaries.liquidity, PZLinuxRaceSimulationMoney)
PZLinuxRaceSimulationWritePoolSummary("Pool de prix", poolSummaries.prize, PZLinuxRaceSimulationMoney)
PZLinuxRaceSimulationWritePoolSummary("Pari joueur maximum", poolSummaries.maximumBet, PZLinuxRaceSimulationMoney)
PZLinuxRaceSimulationWritePoolSummary("Cote finale du favori", poolSummaries.favoriteOdds, function(value)
    return string.format("%.2f/1", value)
end)
PZLinuxRaceSimulationWritePoolSummary("Cotes indicatives, tous concurrents", poolSummaries.allOdds, function(value)
    return string.format("%.2f/1", value)
end)
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("### Frequence des grandes cotes")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Une carte contient huit concurrents. La cote d'un concurrent est indicative avant la mise du joueur; sa cote finale est recalculee au lancement.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Seuil | Concurrents concernes | Part des places | Cartes avec au moins un | Part des cartes |")
PZLinuxRaceSimulationWrite("| ---: | ---: | ---: | ---: | ---: |")
for _, threshold in ipairs(longOddsThresholds) do
    PZLinuxRaceSimulationWrite(string.format(
        "| %d/1 ou plus | %d | %s | %d | %s |",
        threshold,
        longOddsRunnerCounts[threshold],
        PZLinuxRaceSimulationPercent(longOddsRunnerCounts[threshold] / (options.runs * PZLinux.Race.runnerCount)),
        longOddsCardCounts[threshold],
        PZLinuxRaceSimulationPercent(longOddsCardCounts[threshold] / options.runs)
    ))
end
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Grille de gains par cote")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Le paiement total inclut le remboursement de la mise. La derniere colonne indique la masse nette necessaire pour conserver cette cote lorsque le total des mises gagnantes vaut $1,000.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Cote finale | Mise | Benefice | Paiement total | Pool net pour $1,000 gagnants |")
PZLinuxRaceSimulationWrite("| ---: | ---: | ---: | ---: | ---: |")
for _, odds in ipairs({ 1, 2, 3, 5, 10, 15, 20, 25, 50, 100 }) do
    PZLinuxRaceSimulationWrite(string.format(
        "| %d/1 | %s | %s | %s | %s |",
        odds,
        PZLinuxRaceSimulationMoney(options.stake),
        PZLinuxRaceSimulationMoney(options.stake * odds),
        PZLinuxRaceSimulationMoney(options.stake * (odds + 1)),
        PZLinuxRaceSimulationMoney(1000 * (odds + 1))
    ))
end
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Resultats par cote selectionnee")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Cote | Paris | Part | Victoires | Taux victoire | RTP |")
PZLinuxRaceSimulationWrite("| ---: | ---: | ---: | ---: | ---: | ---: |")
local oddsKeys = {}
for rating in pairs(bySelectedOdds) do table.insert(oddsKeys, rating) end
table.sort(oddsKeys)
for _, rating in ipairs(oddsKeys) do
    local stats = bySelectedOdds[rating]
    local oddsRtp = stats.selectedPayout / stats.selectedStake
    PZLinuxRaceSimulationWrite(string.format(
        "| %.1f/1-%.1f/1 | %d | %s | %d | %s | %s |",
        rating,
        rating + 0.1,
        stats.selections,
        PZLinuxRaceSimulationPercent(stats.selections / options.runs),
        stats.selectedWins,
        PZLinuxRaceSimulationPercent(stats.selectedWins / stats.selections),
        PZLinuxRaceSimulationPercent(oddsRtp)
    ))
end
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Biais par position sur la carte")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Une course parfaitement symetrique donnerait environ 12,50 % de victoires a chaque position.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Position | Victoires | Taux | Ecart a 12,50 % |")
PZLinuxRaceSimulationWrite("| ---: | ---: | ---: | ---: |")
for position = 1, PZLinux.Race.runnerCount do
    local positionStats = byPosition[position]
    local winRate = positionStats.wins / options.runs
    local deviation = winRate - (1 / PZLinux.Race.runnerCount)
    PZLinuxRaceSimulationWrite(string.format(
        "| %d | %d | %s | %+.2f points |",
        position,
        positionStats.wins,
        PZLinuxRaceSimulationPercent(winRate),
        deviation * 100
    ))
end
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Vitesse et cotes du pool")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("La vitesse conserve la formule continue historique : `5 + random(0, 100 - rating) / 25`.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Rating | Avance par tick | Avance moyenne |")
PZLinuxRaceSimulationWrite("| ---: | ---: | ---: |")
PZLinuxRaceSimulationWrite("| 2 | 5.00 a 8.92 | 6.96 |")
PZLinuxRaceSimulationWrite("| 25 | 5.00 a 8.00 | 6.50 |")
PZLinuxRaceSimulationWrite("| 50 | 5.00 a 7.00 | 6.00 |")
PZLinuxRaceSimulationWrite("| 75 | 5.00 a 6.00 | 5.50 |")
PZLinuxRaceSimulationWrite("| 100 | 5.00 | 5.00 |")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Le rating pilote uniquement la performance. La cote `N/1` est derivee du pool : une cote finale de 25/1 rend la mise et verse 25 fois la mise en benefice.")
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Resultats par coureur")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Coureur | Apparitions | Rating moyen | Victoires | Taux victoire | Paris favori | RTP favori |")
PZLinuxRaceSimulationWrite("| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
local runnerNames = {}
for name in pairs(byRunner) do table.insert(runnerNames, name) end
table.sort(runnerNames)
for _, name in ipairs(runnerNames) do
    local stats = byRunner[name]
    local selectedRtp = stats.selectedStake > 0 and stats.selectedPayout / stats.selectedStake or 0
    PZLinuxRaceSimulationWrite(string.format(
        "| %s | %d | %.2f | %d | %s | %d | %s |",
        name,
        stats.appearances,
        stats.ratingSum / stats.appearances,
        stats.wins,
        PZLinuxRaceSimulationPercent(stats.wins / stats.appearances),
        stats.selections,
        stats.selections > 0 and PZLinuxRaceSimulationPercent(selectedRtp) or "n/a"
    ))
end
PZLinuxRaceSimulationWrite("")

PZLinuxRaceSimulationWrite("## Diagnostic automatique")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("- La frequence des favoris de pool ex aequo est de "
    .. PZLinuxRaceSimulationPercent(tiedFavoriteCards / options.runs) .. ".")
if largestPositionDeviation > 0.01 then
    PZLinuxRaceSimulationWrite("- Un biais de position superieur a 1 point est mesure et merite un echantillon plus large.")
else
    PZLinuxRaceSimulationWrite("- Aucun biais de position superieur a 1 point n'est visible dans cet echantillon.")
end
if rtp < options.targetMin then
    PZLinuxRaceSimulationWrite("- La strategie favorite perd trop par rapport a la cible. Il faut augmenter le payout ou recalibrer les probabilites.")
elseif rtp > options.targetMax then
    PZLinuxRaceSimulationWrite("- La strategie favorite paie au-dessus de la cible. Il faut reduire le payout ou renforcer l'avantage maison.")
else
    PZLinuxRaceSimulationWrite("- Le RTP de la strategie favorite se situe dans la plage cible.")
end
if #outlierOdds > 0 then
    local labels = {}
    for _, rating in ipairs(outlierOdds) do table.insert(labels, string.format("%.1f/1", rating)) end
    PZLinuxRaceSimulationWrite("- Tranches de cote suffisamment representees hors cible : "
        .. table.concat(labels, ", ") .. ".")
end
PZLinuxRaceSimulationWrite("- Le payout inclut la mise retournee et depend du pool final : `pool net x mise joueur / mises gagnantes`.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("## Etude : course cagnote du dimanche")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("La course hebdomadaire avec **$50,000 ajoutes par le serveur** est implementee comme un rendez-vous global. Ajouter $50,000 a chaque session personnelle aurait permis a chaque joueur de recreer la subvention et aurait ete exploitable.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Architecture retenue :")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("1. Creer une seule course partagee le dimanche du calendrier en jeu a 16:00.")
PZLinuxRaceSimulationWrite("2. Ouvrir les mises avant la course, avec 500 a 1,300 parieurs virtuels et les mises reelles de tous les joueurs.")
PZLinuxRaceSimulationWrite("3. Fermer les mises a 16:00, verrouiller les cotes, puis calculer un seul vainqueur autoritaire.")
PZLinuxRaceSimulationWrite("4. Calculer `pool net = mises apres commission + $50,000`, afin que toute la cagnote promotionnelle soit distribuee.")
PZLinuxRaceSimulationWrite("5. Conserver les tickets dans le ModData serveur et crediter aussi les gagnants deconnectes lors de leur prochaine connexion.")
PZLinuxRaceSimulationWrite("6. Limiter chaque joueur a un ticket de $500 maximum pour contenir le RTP promotionnel et eviter la manipulation des cotes.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Exemple indicatif avec 900 parieurs a $262.50 de moyenne :")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("| Element | Montant |")
PZLinuxRaceSimulationWrite("| --- | ---: |")
PZLinuxRaceSimulationWrite("| Mises virtuelles | $236,250 |")
PZLinuxRaceSimulationWrite("| Pool apres commission de 15 % | $200,812 |")
PZLinuxRaceSimulationWrite("| Cagnote serveur ajoutee | $50,000 |")
PZLinuxRaceSimulationWrite("| Masse finale a partager | $250,812 |")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Une simulation separee de 10 000 super cagnottes mesure environ 119 % de RTP en jouant toujours le favori, avec 900 parieurs et $236,326 de mises virtuelles en moyenne. Ce rendement promotionnel est volontaire mais justifie le plafond hebdomadaire de $500 par joueur.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("Cette variante est couverte par un test deterministe du calendrier, des tickets multiples, du reglement automatique et du paiement bancaire. Une validation avec deux clients sur serveur dedie reste requise.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("## Corrections recommandees")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("1. Verifier en jeu que le pool, le nombre de parieurs, le plafond et les cotes restent lisibles dans le CRT.")
PZLinuxRaceSimulationWrite("2. Tester plusieurs tailles de mises pour confirmer que le partage proportionnel ne produit aucun gain inferieur a la mise sur un pari gagnant autorise.")
PZLinuxRaceSimulationWrite("3. Comparer la strategie favorite a un pari aleatoire et aux autres tranches de multiplicateur avant de figer la commission.")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("## Reproduction")
PZLinuxRaceSimulationWrite("")
PZLinuxRaceSimulationWrite("```bash")
PZLinuxRaceSimulationWrite("bash tools/simulate_zombie_races.sh --runs " .. options.runs
    .. " --stake " .. options.stake .. " --seed " .. options.seed
    .. " --target-min " .. options.targetMin .. " --target-max " .. options.targetMax)
PZLinuxRaceSimulationWrite("```")

local outputFile = assert(io.open(options.output, "wb"))
outputFile:write(table.concat(report, "\n"), "\n")
outputFile:close()

print(string.format(
    "Zombie Race simulation: runs=%d wins=%d RTP=%.2f%% house_edge=%.2f%% seed=%d",
    options.runs,
    strategyWins,
    rtp * 100,
    houseEdge * 100,
    options.seed
))
print("Report: " .. options.output)

local gateFailed = rtp < options.targetMin
    or rtp > options.targetMax
    or largestPositionDeviation > 0.02
    or #outlierOdds > 0
if options.failOutsideTarget and gateFailed then
    os.exit(2)
end
