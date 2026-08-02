local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"
local variables = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local server = PZLinuxTestRead(luaRoot .. "/server/PZLinuxServerCommands.lua")
local client = PZLinuxTestRead(luaRoot .. "/client/Context/World/Features/PZLinuxBetting.lua")
local engine = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxRaceEngine.lua")

local startBlock = variables:match("function PZLinuxRaceStart.-\nend\n\nfunction PZLinuxRaceFinish")
PZLinuxTestAssert(startBlock, "could not inspect PZLinuxRaceStart")
PZLinuxTestAssert(not startBlock:find('PZLinuxApplyBankCredit'),
    "race start must not credit winnings before the animation finishes")
PZLinuxTestAssert(startBlock:find('PZLinuxRegisterInterruptedSession%(player, "race"'),
    "a debited race must register a restart rollback")

local finishBlock = variables:match("function PZLinuxRaceFinish.-\nend\n\nfunction PZLinuxRequestRaceCard")
PZLinuxTestAssert(finishBlock, "could not inspect PZLinuxRaceFinish")
PZLinuxTestAssert(finishBlock:find('PZLinuxApplyBankCredit'),
    "race finish must authoritatively credit a winning payout")
PZLinuxTestAssert(finishBlock:find('PZLinuxClearInterruptedSession%(player, "race"%)'),
    "a settled race must clear its restart rollback")

PZLinuxTestAssert(server:find('PZLinuxRaceSchedule = PZLinuxServerRaceSchedule'),
    "the prefixed race schedule command must be registered server-side")
PZLinuxTestAssert(server:find('PZLinuxRaceScheduleBet = PZLinuxServerRaceScheduleBet'),
    "scheduled tickets must use a dedicated authoritative server command")
PZLinuxTestAssert(not server:find('PZLinuxRaceStart = PZLinuxServerRaceStart'),
    "the farmable immediate race command must not remain exposed")
PZLinuxTestAssert(client:find('PZLinuxRequestRaceScheduleBet', 1, true),
    "the betting UI must place persistent scheduled tickets")
PZLinuxTestAssert(variables:find('require "PZLinux/PZLinuxRaceEngine"', 1, true),
    "the authoritative runtime must load the shared race engine")
PZLinuxTestAssert(variables:find('require "PZLinux/PZLinuxRaceSchedule"', 1, true),
    "the authoritative runtime must load the persistent race schedule")
PZLinuxTestAssert(variables:find("PZLinuxRaceGenerateCard", 1, true),
    "race cards must use the shared race engine")
PZLinuxTestAssert(variables:find("PZLinuxRaceCalculatePayout", 1, true),
    "race settlement must use the shared payout helper")
PZLinuxTestAssert(engine:find("function PZLinuxRaceSelectLowestOdds", 1, true),
    "the shared engine must expose the favorite strategy used by simulations")

PZLinux = {}
dofile(luaRoot .. "/shared/PZLinux/PZLinuxGamblingData.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxRaceEngine.lua")

local function PZLinuxTestMinimumRandom(minimum, _maximumExclusive)
    return minimum
end

local deterministicCard = PZLinuxRaceGenerateCard(PZLinuxRaceRunnerPool, 8, PZLinuxTestMinimumRandom)
PZLinuxTestAssert(#deterministicCard == 8, "race cards must contain eight runners")
local deterministicPool = PZLinuxRaceCreateBettingPool(deterministicCard, PZLinuxTestMinimumRandom)
PZLinuxTestAssert(deterministicPool.bettorCount == PZLinux.Race.minimumBettors,
    "the server pool must contain its configured minimum number of bettors")
PZLinuxTestAssert(deterministicPool.serverLiquidity == math.floor(deterministicPool.marketPool * 0.04 / 5) * 5,
    "the server must add its configured liquidity to the prize pool")
PZLinuxTestAssert(deterministicPool.poolTotal == deterministicPool.marketPool + deterministicPool.serverLiquidity,
    "the displayed prize pool must include server liquidity")
PZLinuxTestAssert(deterministicPool.maximumBet == math.floor(deterministicPool.marketPool * 0.10 / 5) * 5,
    "the maximum player bet must follow the configured pool share")
local selectedIndex, tiedFavorites, selectedMultiplier = PZLinuxRaceSelectLowestOdds(
    deterministicCard,
    PZLinuxTestMinimumRandom
)
PZLinuxTestAssert(selectedIndex == 1 and tiedFavorites == 1 and selectedMultiplier < 1,
    "favorite selection must follow the lowest pool multiplier")
local deterministicWinner = PZLinuxRaceSimulateWinner(deterministicCard, PZLinuxTestMinimumRandom)
PZLinuxTestAssert(deterministicWinner == 1, "deterministic tied races must preserve current settlement behavior")
PZLinuxTestAssert(PZLinuxRaceCalculatePayout(100, 10000, 1000, true, 0.15) == 780,
    "the shared engine must distribute the net pool proportionally to the winning stake")
PZLinuxTestAssert(PZLinuxRaceCalculatePayout(100, 100, 100, true, 0.15) == 100,
    "a winning ticket must never return less than its stake")
PZLinuxTestAssert(PZLinuxRaceCalculatePayout(100, 10000, 1000, false, 0.15) == 0,
    "a losing pari-mutuel ticket must not pay out")
PZLinuxTestAssert(PZLinuxRaceCalculateFinalOdds(100, 10000, 1000, 0.15) == 6.8,
    "final fractional odds must match the authoritative payout including stake")

print("Zombie Race settlement tests OK")
