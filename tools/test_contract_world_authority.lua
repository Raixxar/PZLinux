local root = arg[1] or "."
local luaRoot = root .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local variables = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local applyBlock = variables:match("function PZLinuxContractsApplyWorldEvent.-\nend\n\nfunction PZLinuxRequestContractWorldEvent")
PZLinuxTestAssert(applyBlock ~= nil, "could not inspect contract world-event authority")
PZLinuxTestAssert(not applyBlock:find("args%.contractId"), "world events must not trust a client contract id")
PZLinuxTestAssert(not applyBlock:find("args%.x") and not applyBlock:find("args%.y") and not applyBlock:find("args%.z"),
    "world events must not trust client coordinates")
PZLinuxTestAssert(applyBlock:find('eventName == "zombieKilled".-server_event_only'),
    "zombie kills must only be accepted from the server event")
PZLinuxTestAssert(applyBlock:find('eventName == "clearCargo".-server_event_only'),
    "cargo cleanup must not be client-triggerable")
local spawnCargoBranch = applyBlock:match('eventName == "spawnCargo"(.-)elseif')
PZLinuxTestAssert(spawnCargoBranch and spawnCargoBranch:find('"accepted", "spawned"'),
    "cargo spawn must be recoverable after reconnect without resetting server state")
PZLinuxTestAssert(variables:find('PZLinuxContractsGetEntityObjective%(existing%) == "cargo"'),
    "cargo recovery must reuse an existing tagged object instead of duplicating it")
local spawnManhuntBranch = applyBlock:match('eventName == "spawnManhunt"(.-)elseif')
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find('"accepted", "spawned"'),
    "manhunt spawn must be recoverable after reconnect")
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find("PZLinuxContractsEnsureManhuntZombie"),
    "manhunt recovery must reuse an existing tagged target")
local restoreProtectBranch = applyBlock:match('eventName == "restoreProtect"(.-)elseif')
PZLinuxTestAssert(restoreProtectBranch and restoreProtectBranch:find("10 %- %(tonumber%(record%.zombieCount%)"),
    "protect recovery must only restore the number of objective kills still required")
PZLinuxTestAssert(variables:find('record%.status == "target_down".-PZLinuxContractManhunt = 2'),
    "a killed manhunt target must remain available for corpse interaction")

for _, eventName in ipairs({ "startProtect", "finishProtect", "takeCargo", "decapitate", "blood", "capture" }) do
    local branch = applyBlock:match('eventName == "' .. eventName .. '"(.-)elseif')
        or applyBlock:match('eventName == "' .. eventName .. '"(.-)else')
    PZLinuxTestAssert(branch and branch:find("args%.target"), eventName .. " must resolve a real world target")
end

local pickupBranch = applyBlock:match('eventName == "pickupPackage"(.-)elseif')
PZLinuxTestAssert(pickupBranch and pickupBranch:find("PZLinuxIsPlayerNearPosition"),
    "package pickup must validate the server-side player position")
PZLinuxTestAssert(not pickupBranch:find("args%.target"),
    "package pickup must not depend on an arbitrary client-selected world object")

local requestBlock = variables:match("function PZLinuxRequestContractWorldEvent.-\nend\n\nfunction PZLinuxRequestContractsBoard")
PZLinuxTestAssert(requestBlock ~= nil, "could not inspect world-event request")
PZLinuxTestAssert(not requestBlock:find("PZLinuxContractId"), "world-event requests must not inject a client contract id")

local serverCommands = PZLinuxTestRead(luaRoot .. "/server/PZLinuxServerCommands.lua")
PZLinuxTestAssert(serverCommands:find("Events%.OnZombieDead%.Add%(PZLinuxServerOnZombieDead%)"),
    "the server must own zombie-death accounting")
PZLinuxTestAssert(variables:find("modData%.PZLinuxActiveContract = PZLinuxContractsCanonicalActiveState%(record%.status%)"),
    "active contract state must be rebuilt from the persistent server record")
PZLinuxTestAssert(variables:find("PZLinuxContractsUpdateKillNote%(playerObj, record%)"),
    "server kill accounting must synchronize the persistent contract note")
PZLinuxTestAssert(variables:find('PZLinuxContractsTagEntity%(note, record%.id, "contract_note"%)'),
    "contract notes must carry their persistent server contract id")

for _, path in ipairs({
    "/shared/TimedActions/ISCaptureAction.lua",
    "/shared/TimedActions/ISDecapitateAction.lua",
}) do
    local action = PZLinuxTestRead(luaRoot .. path)
    PZLinuxTestAssert(not action:find(":removeFromWorld%(") and not action:find(":removeFromSquare%("),
        path .. " must not remove world entities on the client")
end

local events = PZLinuxTestRead(luaRoot .. "/client/Context/World/Events/PZLinuxOnEvents.lua")
PZLinuxTestAssert(not events:find('"zombieKilled"'), "the client must not report zombie kills")
PZLinuxTestAssert(not events:find('"clearCargo"'), "the client must not request cargo deletion")
PZLinuxTestAssert(not events:find("PZLinuxContractManhunt = 1"), "reconnect must not reset a persistent spawned target")
PZLinuxTestAssert(events:find("cargoState == 1 or cargoState == 2"),
    "accepted and previously spawned cargo contracts must both recover on reconnect")
PZLinuxTestAssert(events:find('PZLinuxRequestContractWorldEvent%(player, "restoreProtect"'),
    "protect contracts must request server recovery after reconnect")

print("PZLinux contract world authority tests OK")
