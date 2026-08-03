local PZLinuxManhuntSpawnRequests = {}
local PZLinuxManhuntTargetState = {}

local function PZLinuxKeepManhuntTargetPassive(zombie)
    if not zombie then return end
    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setUseless then zombie:setUseless(true) end
    if zombie.setCanWalk then zombie:setCanWalk(false) end
    if zombie.setAlwaysKnockedDown then zombie:setAlwaysKnockedDown(true) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(true) end
end

local function PZLinuxIsManhuntContractPending(modData)
    if not modData then return false end

    local activeState = tonumber(modData.PZLinuxActiveContract) or 0
    local manhuntState = tonumber(modData.PZLinuxContractManhunt) or 0
    local contractType = tonumber(modData.PZLinuxContractTypeId) or 0
    local record = PZLinuxContractsGetWorldContract(modData.PZLinuxContractId)
    local recordIsManhunt = record
        and tonumber(record.contractId) == 3
        and PZLinuxContractsIsRecordStatus(record, "accepted", "spawned")

    if record and tonumber(record.contractId) == 3 then
        return activeState == 1 and recordIsManhunt
    end

    return activeState == 1
        and (manhuntState == 1 or manhuntState == 2 or contractType == 3 or recordIsManhunt)
end

local function PZLinuxContractRestoreNow()
    local timestampProvider = rawget(_G, "getTimestampMs")
    if timestampProvider then return math.floor(timestampProvider() / 1000) end
    return math.floor(getGameTime():getWorldAgeHours() * 3600)
end

local function PZLinuxCanRequestContractRestore(requests, player, cooldown)
    local playerKey = tostring(player:getPlayerNum())
    local now = PZLinuxContractRestoreNow()
    local lastRequest = requests[playerKey] or -cooldown
    if now - lastRequest < cooldown then return false end
    requests[playerKey] = now
    return true
end

local function PZLinuxFindVisibleManhuntTarget(modData, expectedState)
    if not getCell then return nil end
    local rememberedZombie = expectedState and expectedState.zombie
    if rememberedZombie
    and (not rememberedZombie.isDead or not rememberedZombie:isDead())
    and rememberedZombie.getSquare and rememberedZombie:getSquare() then
        return rememberedZombie
    end
    local zombies = getCell():getZombieList()
    if not zombies then return nil end
    local contractWorldId = tostring(modData.PZLinuxContractId or "")
    local onlineId = tonumber(expectedState and expectedState.onlineId) or -1
    local spawnX = tonumber(expectedState and expectedState.x)
    local spawnY = tonumber(expectedState and expectedState.y)
    local spawnZ = tonumber(expectedState and expectedState.z)

    for index = 0, zombies:size() - 1 do
        local zombie = zombies:get(index)
        local data = zombie and zombie.getModData and zombie:getModData() or nil
        local zombieOnlineId = zombie and zombie.getOnlineID and tonumber(zombie:getOnlineID()) or -1
        local matchesNetworkId = onlineId >= 0 and zombieOnlineId == onlineId
        local matchesTag = data
            and tostring(data.PZLinuxContractId or "") == contractWorldId
            and data.PZLinuxContractObjective == "manhunt"
            and tonumber(data.PZLinuxManhuntVersion) == 4
        local matchesConfirmedPosition = spawnX and spawnY and spawnZ
            and math.abs(zombie:getX() - spawnX) <= 2
            and math.abs(zombie:getY() - spawnY) <= 2
            and math.abs(zombie:getZ() - spawnZ) <= 0.1
        if zombie and (not zombie.isDead or not zombie:isDead())
        and (matchesNetworkId or matchesTag or matchesConfirmedPosition) then
            return zombie
        end
    end
    return nil
end

local function checkAndSpawnZombie(player)
    if not player then return end
    local modData = player:getModData()
    local playerKey = tostring(player:getPlayerNum())
    if PZLinuxIsManhuntContractPending(modData) then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        local activationRadius = tonumber(PZLinux.Config.Contracts.objectiveActivationRadius) or 80
        local targetState = PZLinuxManhuntTargetState[playerKey]
        local visibleTarget = dist < activationRadius
            and PZLinuxFindVisibleManhuntTarget(modData, targetState)
            or nil
        if visibleTarget then
            targetState = targetState or {}
            targetState.zombie = visibleTarget
            PZLinuxManhuntTargetState[playerKey] = targetState
            PZLinuxKeepManhuntTargetPassive(visibleTarget)
            return
        end
        if dist < activationRadius
        and PZLinuxCanRequestContractRestore(PZLinuxManhuntSpawnRequests, player, 5) then
            print("[PZLinux Manhunt][client] requesting target"
                .. " active=" .. tostring(modData.PZLinuxActiveContract)
                .. " type=" .. tostring(modData.PZLinuxContractTypeId)
                .. " status=" .. tostring(modData.PZLinuxContractWorldStatus)
                .. " contract=" .. tostring(modData.PZLinuxContractId)
                .. " player=" .. tostring(math.floor(player:getX())) .. "," .. tostring(math.floor(player:getY()))
                .. " target=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
            PZLinuxRequestContractWorldEvent(player, "spawnManhunt", {}, function(result)
                if result and result.ok then
                    PZLinuxManhuntTargetState[playerKey] = {
                        onlineId = result.spawnEntityId,
                        x = tonumber(result.spawnX) or tonumber(x),
                        y = tonumber(result.spawnY) or tonumber(y),
                        z = tonumber(result.spawnZ) or tonumber(z),
                    }
                    print("[PZLinux Manhunt] server confirmed target at "
                        .. tostring(result.spawnX or x) .. ","
                        .. tostring(result.spawnY or y) .. ","
                        .. tostring(result.spawnZ or z)
                        .. " onlineId=" .. tostring(result.spawnEntityId or -1)
                        .. " created=" .. tostring(tonumber(result.spawned) == 1))
                else
                    print("[PZLinux Manhunt][client] restore failed: "
                        .. tostring(result and result.error or "no_server_response")
                        .. " detail=" .. tostring(result and result.errorDetail or "")
                        .. " active=" .. tostring(modData.PZLinuxActiveContract)
                        .. " flag=" .. tostring(modData.PZLinuxContractManhunt)
                        .. " worldContract=" .. tostring(modData.PZLinuxContractId))
                end
            end)
        end
    else
        PZLinuxManhuntTargetState[playerKey] = nil
    end
end
-- Not registered on Events.OnPlayerMove: that fires reentrantly from inside
-- IsoPlayer's own per-frame update (IsoCell.ProcessObjects -> IsoPlayer.update),
-- and spawning/searching zombies from there caused hard crashes in solo (the
-- server-side logic runs inline instead of on a separate server thread).
-- PZLinuxPollWorldObjectiveRestores below calls this safely once per second
-- from Events.OnTick instead, for every local player.

local PZLinuxVehicleSpawnRequests = {}
local PZLinuxVehicleDeliveryState = {}

local function PZLinuxFindVisibleDeliveredVehicle(vehicleId, deliveryId)
    local expectedVehicleId = tonumber(vehicleId)
    local expectedDeliveryId = tostring(deliveryId or "")
    local canMatchVehicleId = expectedVehicleId ~= nil and expectedVehicleId >= 0
    local canMatchDeliveryId = expectedDeliveryId ~= ""
    if not canMatchVehicleId and not canMatchDeliveryId then return nil end

    if not getCell then return nil end
    -- IsoCell:getVehicles() returns a java.util.Set (confirmed in the game's own
    -- bytecode), which has no :get(index) method, only :size() and :toArray().
    -- Converting to an array first (same pattern the game itself uses for other
    -- Set-returning APIs, e.g. item:getTags():toArray() in Vehicles.lua) makes
    -- it safely iterable instead of throwing "tried to call nil".
    local vehicles = getCell():getVehicles()
    local vehicleArray = vehicles and vehicles.toArray and vehicles:toArray() or nil
    if not vehicleArray then return nil end
    for _, vehicle in ipairs(vehicleArray) do
        local data = vehicle and vehicle.getModData and vehicle:getModData() or nil
        local matchesVehicleId = canMatchVehicleId and tonumber(vehicle:getId()) == expectedVehicleId
        local matchesDeliveryId = canMatchDeliveryId
            and data
            and tostring(data.PZLinuxRequestVehicleDeliveryId or "") == expectedDeliveryId
        if vehicle and (matchesVehicleId or matchesDeliveryId) then
            return vehicle
        end
    end
    return nil
end

local function PZLinuxConfirmVisibleVehicle(player, state)
    if not state or tostring(state.deliveryId or "") == "" then return false end
    if state.confirming then return true end
    local vehicle = PZLinuxFindVisibleDeliveredVehicle(state.vehicleId, state.deliveryId)
    if not vehicle then return false end
    state.confirming = true
    PZLinuxRequestConfirmVehicle(player, state.deliveryId, vehicle:getId(), function(result)
        state.confirming = false
        if result and result.ok and result.confirmed then
            local modData = player:getModData()
            modData.PZLinuxOnItemRequestCar = 0
            modData.PZLinuxActiveRequest = 0
            PZLinuxVehicleDeliveryState[tostring(player:getPlayerNum())] = nil
            HaloTextHelper.addGoodText(player, "Requested vehicle delivered")
        elseif result then
            print("[PZLinux Vehicle] confirmation failed: " .. tostring(result.error or "unknown"))
            local playerKey = tostring(player:getPlayerNum())
            if PZLinuxVehicleDeliveryState[playerKey] == state then
                PZLinuxVehicleDeliveryState[playerKey] = nil
            end
        end
    end)
    return true
end

local function checkAndSpawnVehicle(player)
    if not player then return end
    local modData = player:getModData()
    local playerKey = tostring(player:getPlayerNum())
    if modData.PZLinuxOnItemRequestCar == 1 then
        local deliveryState = PZLinuxVehicleDeliveryState[playerKey]
        local canonicalDeliveryId = tostring(modData.PZLinuxRequestVehicleDeliveryId or "")
        if deliveryState and canonicalDeliveryId ~= ""
        and tostring(deliveryState.deliveryId or "") ~= canonicalDeliveryId then
            PZLinuxVehicleDeliveryState[playerKey] = nil
            deliveryState = nil
        end
        if PZLinuxConfirmVisibleVehicle(player, deliveryState) then return end
        local x, y, z = modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, modData.PZLinuxRequestLocationZ
        if not x or not y or not z then
            print("[PZLinux Vehicle][client] no delivery location in modData"
                .. " x=" .. tostring(x) .. " y=" .. tostring(y) .. " z=" .. tostring(z)
                .. " deliveryId=" .. tostring(modData.PZLinuxRequestVehicleDeliveryId))
            return
        end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        local canRestore = PZLinuxCanRequestContractRestore(PZLinuxVehicleSpawnRequests, player, 5)
        if dist >= 50 or not canRestore then
            print("[PZLinux Vehicle][client] not requesting spawn"
                .. " dist=" .. tostring(dist) .. " canRestore=" .. tostring(canRestore)
                .. " player=" .. tostring(math.floor(player:getX())) .. "," .. tostring(math.floor(player:getY()))
                .. " target=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
        end
        if dist < 50 and canRestore then
            print("[PZLinux Vehicle][client] requesting spawn deliveryId="
                .. tostring(modData.PZLinuxRequestVehicleDeliveryId)
                .. " car=" .. tostring(modData.PZLinuxOnItemRequestCarName))
            PZLinuxRequestSpawnVehicle(player, function(result)
                if result and result.ok and result.spawned then
                    PZLinuxVehicleDeliveryState[playerKey] = {
                        deliveryId = result.deliveryId,
                        vehicleId = result.vehicleId,
                    }
                    print("[PZLinux Vehicle] server confirmed vehicleId="
                        .. tostring(result.vehicleId) .. " delivery=" .. tostring(result.deliveryId)
                        .. " at " .. tostring(result.spawnX) .. ","
                        .. tostring(result.spawnY) .. "," .. tostring(result.spawnZ))
                    PZLinuxConfirmVisibleVehicle(player, PZLinuxVehicleDeliveryState[playerKey])
                elseif result and not result.ok then
                    print("[PZLinux Vehicle] spawn failed: " .. tostring(result.error or "unknown"))
                end
            end)
        end
    else
        PZLinuxVehicleDeliveryState[playerKey] = nil
    end
end
-- See the comment above checkAndSpawnZombie: the same reentrancy hazard
-- crashed vehicle requests in solo. Handled by the OnTick poller instead.

local PZLinuxCargoSpawnRequests = {}

local function PZLinuxIsCargoContractPending(modData)
    if not modData then return false end

    local activeState = tonumber(modData.PZLinuxActiveContract) or 0
    local cargoState = tonumber(modData.PZLinuxContractCargo) or 0
    local contractType = tonumber(modData.PZLinuxContractTypeId) or 0
    local record = PZLinuxContractsGetWorldContract(modData.PZLinuxContractId)
    local recordIsCargo = record
        and tonumber(record.contractId) == 7
        and PZLinuxContractsIsRecordStatus(record, "accepted", "spawned")

    return activeState == 1
        and (cargoState == 1 or cargoState == 2 or contractType == 7 or recordIsCargo)
end

local function PZLinuxCargoExists(modData, x, y, z)
    if not getCell then return false end
    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local level = math.floor(tonumber(z) or 0)

    for offsetX = -5, 5 do
        for offsetY = -5, 5 do
            local square = getCell():getGridSquare(centerX + offsetX, centerY + offsetY, level)
            local objects = square and square:getObjects() or nil
            if objects then
                for index = 0, objects:size() - 1 do
                    local obj = objects:get(index)
                    local data = obj and obj.getModData and obj:getModData() or nil
                    if data
                    and tostring(data.PZLinuxContractId or "") == tostring(modData.PZLinuxContractId or "")
                    and data.PZLinuxContractObjective == "cargo"
                    and tonumber(data.PZLinuxCargoVersion) == 3 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function checkAndSpawnBox(player)
    if not player then return end
    local modData = player:getModData()
    if PZLinuxIsCargoContractPending(modData) then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            if PZLinuxCargoExists(modData, x, y, z) then return end

            if not PZLinuxCanRequestContractRestore(PZLinuxCargoSpawnRequests, player, 5) then return end
            PZLinuxRequestContractWorldEvent(player, "spawnCargo", {}, function(result)
                if result and result.ok then
                    print("[PZLinux Cargo] server confirmed cargo at "
                        .. tostring(result.spawnX or x) .. ","
                        .. tostring(result.spawnY or y) .. ","
                        .. tostring(result.spawnZ or z)
                        .. " created=" .. tostring(tonumber(result.spawned) == 1))
                elseif result then
                    print("[PZLinux Cargo] restore failed: " .. tostring(result.error or "unknown"))
                else
                    print("[PZLinux Cargo] restore failed: empty server response")
                end
            end)
        end
    end
end
-- See the comment above checkAndSpawnZombie. Handled by the OnTick poller.

local PZLinuxProtectRestoreRequests = {}

local function PZLinuxRestoreProtectContract(player)
    if not player then return end
    local modData = player:getModData()
    if tonumber(modData.PZLinuxContractProtect) ~= 2 then return end

    local x, y = tonumber(modData.PZLinuxContractLocationX), tonumber(modData.PZLinuxContractLocationY)
    if not x or not y then return end
    local distance = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
    if distance >= 50 or not PZLinuxCanRequestContractRestore(PZLinuxProtectRestoreRequests, player, 30) then return end

    PZLinuxRequestContractWorldEvent(player, "restoreProtect", {}, function(result)
        if result and not result.ok and result.error ~= "invalid_contract_state" then
            print("[PZLinux Protect] restore failed: " .. tostring(result.error or "unknown"))
        end
    end)
end
-- See the comment above checkAndSpawnZombie. Handled by the OnTick poller.

local PZLinuxWorldObjectiveLastPoll = -1

local function PZLinuxPollWorldObjectiveRestores()
    local now = PZLinuxContractRestoreNow()
    if now <= PZLinuxWorldObjectiveLastPoll then return end
    PZLinuxWorldObjectiveLastPoll = now

    for playerIndex = 0, 3 do
        local player = getSpecificPlayer(playerIndex)
        if player then
            checkAndSpawnZombie(player)
            checkAndSpawnVehicle(player)
            checkAndSpawnBox(player)
            PZLinuxRestoreProtectContract(player)
        end
    end
end
Events.OnTick.Add(PZLinuxPollWorldObjectiveRestores)

PZLinux = PZLinux or {}
PZLinux.ContractCompletionNotifications = PZLinux.ContractCompletionNotifications or {}

local function PZLinuxContractCompletionNotificationKey(playerObj, modData)
    local playerKey = tostring(playerObj:getPlayerNum())
    local contractKey = tostring(modData.PZLinuxContractId or "")
    if contractKey == "" then
        contractKey = table.concat({
            tostring(modData.PZLinuxContractTypeId or "legacy"),
            tostring(modData.PZLinuxContractLocationX or 0),
            tostring(modData.PZLinuxContractLocationY or 0),
            tostring(modData.PZLinuxOnReward or 0),
        }, ":")
    end
    return playerKey .. ":" .. contractKey
end

local function PZLinuxContractCompletedPlaySound()
    local playerObj = PZLinuxGetPlayer()
    if not playerObj then return end

    local modData = PZLinuxGetModData(playerObj)
    if not modData then return end

    if modData.PZLinuxActiveContract == 9 then
        local notificationKey = PZLinuxContractCompletionNotificationKey(playerObj, modData)
        local alreadyNotified = PZLinux.ContractCompletionNotifications[notificationKey] == true
        PZLinux.ContractCompletionNotifications[notificationKey] = true
        modData.PZLinuxActiveContract = 10

        if alreadyNotified then return end

        local globalVolume = getCore():getOptionSoundVolume() / 50
        getSoundManager():PlayWorldSound("done", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        HaloTextHelper.addGoodText(playerObj, "Contract completed")

        playerObj:getStats():add(CharacterStat.BOREDOM, -5)
        playerObj:getStats():add(CharacterStat.UNHAPPINESS, -5)
        playerObj:getStats():add(CharacterStat.STRESS, -0.05)
    end
end
Events.OnTick.Add(PZLinuxContractCompletedPlaySound)

local function mailTick()
    if isClient() then return end
    local player = PZLinuxGetPlayer()
    if not player then return end
    PZLinuxApplyReputationDecay(player, 0.001)
    PZLinuxMailTickPlayer(player)
end
Events.EveryTenMinutes.Add(mailTick)
