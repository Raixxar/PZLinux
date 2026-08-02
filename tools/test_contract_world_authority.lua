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
PZLinuxTestAssert(variables:find('PZLinuxContractsGetEntityObjective%(obj%) == "cargo"'),
    "cargo recovery must reuse an existing tagged object instead of duplicating it")
PZLinuxTestAssert(not spawnCargoBranch:find("replaceExisting"),
    "cargo retries must never remove and recreate an already spawned server object")
PZLinuxTestAssert(variables:find("reused and retransmitted", 1, true)
    and variables:find("PZLinuxCargoVersion = 2", 1, true),
    "cargo retries must idempotently retransmit the canonical server object")
local spawnManhuntBranch = applyBlock:match('eventName == "spawnManhunt"(.-)elseif')
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find('"accepted", "spawned"'),
    "manhunt spawn must be recoverable after reconnect")
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find("PZLinuxContractsEnsureManhuntZombie"),
    "manhunt recovery must reuse an existing tagged target")
PZLinuxTestAssert(variables:find("function PZLinuxContractsFindZombieSpawnSquare")
    and variables:find("square:isFree%(false%)"),
    "contract zombies must use a nearby loaded free square")
PZLinuxTestAssert(variables:find("addZombiesInOutfit%(")
    and variables:find("PZLinuxContractsFirstSpawnedZombie"),
    "contract zombies must use the multiplayer-aware game spawn helper")
PZLinuxTestAssert(variables:find('objectiveType == "manhunt"')
    and variables:find("zombie:setUseless%(true%)")
    and variables:find("zombie:setSitAgainstWall%(true%)"),
    "the manhunt target must remain seated and unable to wander away")
PZLinuxTestAssert(variables:find("removed stale target", 1, true)
    and variables:find("PZLinuxContractsRemoveWorldEntity%(existingZombie%)"),
    "a legacy manhunt target that wandered away must be replaced near the canonical marker")
local restoreProtectBranch = applyBlock:match('eventName == "restoreProtect"(.-)elseif')
PZLinuxTestAssert(restoreProtectBranch and restoreProtectBranch:find("10 %- %(tonumber%(record%.zombieCount%)"),
    "protect recovery must only restore the number of objective kills still required")
PZLinuxTestAssert(variables:find('record%.status == "target_down".-PZLinuxContractManhunt = 2'),
    "a killed manhunt target must remain available for corpse interaction")

for _, eventName in ipairs({ "startProtect", "finishProtect", "decapitate", "blood", "capture" }) do
    local branch = applyBlock:match('eventName == "' .. eventName .. '"(.-)elseif')
        or applyBlock:match('eventName == "' .. eventName .. '"(.-)else')
    PZLinuxTestAssert(branch and branch:find("args%.target"), eventName .. " must resolve a real world target")
end

local takeCargoBranch = applyBlock:match('eventName == "takeCargo"(.-)elseif')
PZLinuxTestAssert(takeCargoBranch and takeCargoBranch:find('usePlayerRecord%(7, "accepted", "spawned"%)'),
    "cargo pickup must resolve the authoritative active contract")
PZLinuxTestAssert(takeCargoBranch and takeCargoBranch:find("PZLinuxIsPlayerNearPosition")
    and not takeCargoBranch:find("args%.target"),
    "cargo pickup must validate canonical proximity without trusting a client object")
local contextMenu = PZLinuxTestRead(luaRoot .. "/client/Context/World/ISContextContractsMenu.lua")
local cargoAction = PZLinuxTestRead(luaRoot .. "/shared/TimedActions/ISTakeTheCargoAction.lua")
PZLinuxTestAssert(contextMenu:find("cargoState == 1")
    and contextMenu:find("cargoState == 2")
    and contextMenu:find("PZLinuxContractTypeId")
    and contextMenu:find("cargoDistance <= packageRadius")
    and cargoAction:find('PZLinuxRequestContractWorldEvent%(self%.character, "takeCargo", {}'),
    "cargo pickup must remain available when the replicated crate is missing")

local cargoSpawn = variables:match("function PZLinuxContractsSpawnCargoObject.-\nend\n\nlocal function PZLinuxContractsFindZombieSpawnSquare")
PZLinuxTestAssert(cargoSpawn and cargoSpawn:find('data%.PZLinuxContractObjective = "cargo"')
    and cargoSpawn:find("PZLinuxContractsTransmitSquareObject", 1, true),
    "cargo must be tagged before its complete server object is transmitted")

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
PZLinuxTestAssert(variables:find("function PZLinuxContractsResolveZombieKiller")
    and variables:find("zombie%.authOwnerPlayer")
    and variables:find('"network_owner"'),
    "multiplayer deaths must fall back to the server zombie network owner when attackedBy is empty")
PZLinuxTestAssert(variables:find("PZLinuxContractsCreditZombieKill%(attacker, activeRecord%)"),
    "a resolved multiplayer zombie death must be credited directly by the server event")
PZLinuxTestAssert(serverCommands:find('args%.event == "capture".-PZLinuxServerBroadcast%("PZLinuxContractZombieRemoved"'),
    "a validated capture must broadcast removal of the zombie to every client")
PZLinuxTestAssert(variables:find('command == "PZLinuxContractZombieRemoved".-PZLinuxRemoveReplicatedZombie'),
    "clients must remove captured zombies only after the trusted server broadcast")
local worldInteractions = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxWorldInteractions.lua")
local replicatedRemoval = worldInteractions:match("function PZLinuxRemoveReplicatedZombie.-\nend")
PZLinuxTestAssert(replicatedRemoval and replicatedRemoval:find("setUseless")
    and replicatedRemoval:find("removeFromWorld") and replicatedRemoval:find("removeFromSquare"),
    "replicated capture removal must neutralize and remove the local zombie")
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
PZLinuxTestAssert(events:find("PZLinuxIsCargoContractPending")
    and events:find("contractType == 7"),
    "cargo recovery must use the canonical contract type when legacy flags are stale")
PZLinuxTestAssert(events:find('PZLinuxRequestContractWorldEvent%(player, "restoreProtect"'),
    "protect contracts must request server recovery after reconnect")

print("PZLinux contract world authority tests OK")
