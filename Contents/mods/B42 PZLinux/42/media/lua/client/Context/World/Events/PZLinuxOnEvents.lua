local PZLinuxManhuntSpawnRequests = {}

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

local function checkAndSpawnZombie(player)
    if not player then return end
    local modData = player:getModData()
    local manhuntState = tonumber(modData.PZLinuxContractManhunt) or 0
    local record = PZLinuxContractsGetWorldContract(modData.PZLinuxContractId)
    local recordStatus = record and record.status or nil
    local canSpawn = manhuntState == 1 or (manhuntState == 2 and recordStatus ~= "target_down")
    if modData.PZLinuxActiveContract == 1 and canSpawn then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 and PZLinuxCanRequestContractRestore(PZLinuxManhuntSpawnRequests, player, 5) then
            PZLinuxRequestContractWorldEvent(player, "spawnManhunt", {}, function(result)
                if result and not result.ok and result.error ~= "invalid_contract_state" then
                    print("[PZLinux Manhunt] restore failed: " .. tostring(result.error or "unknown"))
                end
            end)
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnZombie)

local PZLinuxVehicleSpawnRequests = {}

local function checkAndSpawnVehicle(player)
    if not player then return end
    local modData = player:getModData()
    if modData.PZLinuxOnItemRequestCar == 1 then
        local x, y, z = modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, modData.PZLinuxRequestLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 and PZLinuxCanRequestContractRestore(PZLinuxVehicleSpawnRequests, player, 5) then
            PZLinuxRequestSpawnVehicle(player, function(result)
                if result and result.ok and result.spawned then
                    HaloTextHelper.addGoodText(player, "Requested vehicle delivered")
                elseif result and not result.ok then
                    print("[PZLinux Vehicle] spawn failed: " .. tostring(result.error or "unknown"))
                end
            end)
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnVehicle)

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
                    and data.PZLinuxContractObjective == "cargo" then
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
Events.OnPlayerMove.Add(checkAndSpawnBox)

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
Events.OnPlayerMove.Add(PZLinuxRestoreProtectContract)

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
