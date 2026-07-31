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

PZLinuxTestAssert(server:find('PZLinuxRaceFinish = PZLinuxServerRaceFinish'),
    "the prefixed race finish command must be registered server-side")
PZLinuxTestAssert(client:find('self:requestRaceSettlement'),
    "the client must request settlement when the race reaches the finish")
PZLinuxTestAssert(client:find('self:settleGamesBeforeClose'),
    "closing the betting UI must settle a running race")

print("Zombie Race settlement tests OK")
