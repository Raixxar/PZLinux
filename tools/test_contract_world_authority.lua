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
PZLinuxTestAssert(variables:find("reused and retransmitted v3 crate", 1, true)
    and variables:find("PZLinuxCargoVersion = PZLinuxCargoObjectVersion", 1, true),
    "cargo retries must idempotently retransmit the canonical server object")
local spawnManhuntBranch = applyBlock:match('eventName == "spawnManhunt"(.-)elseif')
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find('"accepted", "spawned"'),
    "manhunt spawn must be recoverable after reconnect")
PZLinuxTestAssert(spawnManhuntBranch and spawnManhuntBranch:find("PZLinuxContractsEnsureManhuntZombie"),
    "manhunt recovery must reuse an existing tagged target")
PZLinuxTestAssert(variables:find("function PZLinuxContractsFindZombieSpawnSquare")
    and variables:find("square:isFree%(false%)"),
    "contract zombies must use a nearby loaded free square")
PZLinuxTestAssert(variables:find("addZombiesInOutfit", 1, true)
    and variables:find("PZLinuxContractsFirstSpawnedZombie"),
    "contract zombies must use the multiplayer-aware game spawn helper")
PZLinuxTestAssert(variables:find('objectiveType == "manhunt" and addZombieSitting', 1, true)
    and variables:find('spawnMethod = "addZombieSitting"', 1, true),
    "manhunt must prefer the game's dedicated sitting-zombie helper")
PZLinuxTestAssert(variables:find("if not zombie and addZombiesInOutfit", 1, true)
    and variables:find("if not zombie and createZombie", 1, true),
    "zombie spawning must fall back when an available helper returns no zombie")
PZLinuxTestAssert(variables:find("PZLinuxContractsConfigureManhuntZombie"),
    "manhunt must apply its network-safe target configuration")
local manhuntConfig = variables:match("local function PZLinuxContractsConfigureManhuntZombie.-\nend")
PZLinuxTestAssert(manhuntConfig and manhuntConfig:find("zombie:setUseless%(false%)")
    and manhuntConfig:find("zombie:setCanWalk%(false%)")
    and manhuntConfig:find("zombie:setAlwaysKnockedDown%(true%)")
    and manhuntConfig:find("zombie:setSitAgainstWall%(true%)")
    and manhuntConfig:find("networkAI:extraUpdate%(%)"),
    "the manhunt target must stay network-active while seated and unable to wander away")
PZLinuxTestAssert(variables:find("PZLinuxContractsFindTaggedZombies")
    and variables:find("removedDuplicates", 1, true)
    and variables:find("PZLinuxContractsRemoveWorldEntity%(candidate%)"),
    "manhunt recovery must retain one canonical target and remove duplicate spawns")
PZLinuxTestAssert(not variables:find("existingOnlineId >= 0", 1, true),
    "a visible B42 multiplayer target must not be discarded only because its online id is -1")
PZLinuxTestAssert(variables:find("local PZLinuxManhuntTargetVersion = 3", 1, true)
    and variables:find("PZLinuxManhuntVersion = PZLinuxManhuntTargetVersion", 1, true),
    "legacy manhunt targets must migrate once to the network-safe v3 target")
local restoreProtectBranch = applyBlock:match('eventName == "restoreProtect"(.-)elseif')
PZLinuxTestAssert(restoreProtectBranch and restoreProtectBranch:find("10 %- %(tonumber%(record%.zombieCount%)"),
    "protect recovery must only restore the number of objective kills still required")
PZLinuxTestAssert(variables:find('record%.status == "target_down".-PZLinuxContractManhunt = 2'),
    "a killed manhunt target must remain available for corpse interaction")
PZLinuxTestAssert(variables:find("targetDeathX = zombie:getX%(%)")
    and variables:find("PZLinuxContractsFindManhuntRecordForBody%(body%)"),
    "manhunt decapitation must resolve the server-recorded death position when corpse tags are absent")

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
PZLinuxTestAssert(contextMenu:find("elseif packageReady and packageDistance <= 100", 1, true),
    "package diagnostics must not spam the log for unrelated active contracts")
local cargoAction = PZLinuxTestRead(luaRoot .. "/shared/TimedActions/ISTakeTheCargoAction.lua")
PZLinuxTestAssert(contextMenu:find("cargoState == 1")
    and contextMenu:find("cargoState == 2")
    and contextMenu:find("PZLinuxContractTypeId")
    and contextMenu:find("cargoDistance <= packageRadius")
    and cargoAction:find('PZLinuxRequestContractWorldEvent%(self%.character, "takeCargo", {}'),
    "cargo pickup must remain available when the replicated crate is missing")

local cargoSpawn = variables:match("function PZLinuxContractsSpawnCargoObject.-\nend\n\nlocal function PZLinuxContractsFindZombieSpawnSquare")
PZLinuxTestAssert(cargoSpawn and cargoSpawn:find('data%.PZLinuxContractObjective = "cargo"')
    and cargoSpawn:find("IsoThumpable%.new%(getCell%(%)")
    and cargoSpawn:find("square:AddSpecialObject%(obj%)")
    and cargoSpawn:find("PZLinuxContractsTransmitSquareObject", 1, true),
    "cargo must be a tagged special IsoThumpable before its complete server object is transmitted")
PZLinuxTestAssert(cargoSpawn:find("replaced legacy crate", 1, true)
    and variables:find("local PZLinuxCargoObjectVersion = 3", 1, true),
    "cargo spawning must replace legacy visual objects before creating the v3 crate")
PZLinuxTestAssert(variables:find("obj:transmitUpdatedSpriteToClients%(%s*%)"),
    "cargo synchronization must explicitly send its visible sprite to clients")
local cargoRemove = variables:match("local function PZLinuxContractsRemoveCargoObjectFromSquare.-\nend")
PZLinuxTestAssert(cargoRemove and cargoRemove:find("transmitRemoveItemFromSquare")
    and cargoRemove:find("else%s+square:removeTileObject"),
    "cargo removal must not remove a square object before broadcasting its removal")

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
local manhuntEvents = events:match("local function PZLinuxFindVisibleManhuntTarget.-Events%.OnPlayerMove%.Add%(checkAndSpawnZombie%)")
PZLinuxTestAssert(manhuntEvents ~= nil, "could not inspect client manhunt recovery")
PZLinuxTestAssert(not events:find('"zombieKilled"'), "the client must not report zombie kills")
PZLinuxTestAssert(not events:find('"clearCargo"'), "the client must not request cargo deletion")
PZLinuxTestAssert(not events:find("PZLinuxContractManhunt = 1"), "reconnect must not reset a persistent spawned target")
PZLinuxTestAssert(manhuntEvents:find("PZLinuxFindVisibleManhuntTarget")
    and manhuntEvents:find("result%.spawnEntityId")
    and manhuntEvents:find("matchesConfirmedPosition")
    and manhuntEvents:find("tonumber%(data%.PZLinuxManhuntVersion%) == 3"),
    "the client must recognize the confirmed v3 target by id, tag, or spawn position")
PZLinuxTestAssert(events:find("local function PZLinuxIsManhuntContractPending")
    and events:find("contractType == 3")
    and events:find("return activeState == 1 and recordIsManhunt", 1, true),
    "manhunt recovery must survive a stale legacy type flag after reconnect")
PZLinuxTestAssert(manhuntEvents:find("getGridSquare")
    and manhuntEvents:find("if dist < 50 and not targetSquare then return end", 1, true),
    "manhunt must wait until the objective chunk is loaded on the client")
PZLinuxTestAssert(manhuntEvents:find("[PZLinux Manhunt][client] restore failed", 1, true)
    and not manhuntEvents:find('result%.error ~= "invalid_contract_state"'),
    "manhunt recovery must log every server rejection, including invalid state")
PZLinuxTestAssert(events:find("cargoState == 1 or cargoState == 2"),
    "accepted and previously spawned cargo contracts must both recover on reconnect")
PZLinuxTestAssert(events:find("tonumber%(data%.PZLinuxCargoVersion%) == 3"),
    "clients must request replacement of legacy cargo objects that may be invisible")
PZLinuxTestAssert(events:find("PZLinuxIsCargoContractPending")
    and events:find("contractType == 7"),
    "cargo recovery must use the canonical contract type when legacy flags are stale")
PZLinuxTestAssert(events:find('PZLinuxRequestContractWorldEvent%(player, "restoreProtect"'),
    "protect contracts must request server recovery after reconnect")
PZLinuxTestAssert(events:find("local function PZLinuxPollWorldObjectiveRestores")
    and events:find("Events%.OnTick%.Add%(PZLinuxPollWorldObjectiveRestores%)")
    and events:find("checkAndSpawnZombie%(player%)")
    and events:find("checkAndSpawnVehicle%(player%)")
    and events:find("checkAndSpawnBox%(player%)"),
    "world objectives must retry periodically after chunk streaming even when the player stops moving")

local contractsUI = PZLinuxTestRead(luaRoot .. "/client/Context/World/Features/PZLinuxContracts.lua")
PZLinuxTestAssert(contractsUI:find("PZLinuxContractTypeId = tonumber%(result%.contractId%) or 0"),
    "contract acceptance must retain the canonical contract type for world-event recovery")

print("PZLinux contract world authority tests OK")
