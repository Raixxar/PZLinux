local function OnZombieDead(_zombie)
    local player = PZLinuxGetPlayer()
    if not player then return end

    PZLinuxRequestContractWorldEvent(player, "zombieKilled", {}, function(result)
        if not result or not result.ok then return end
        local note = nil
        local inv = player:getInventory()
        for i = 0, inv:getItems():size() - 1 do
            local item = inv:getItems():get(i)
            if item:getType() == "Note" and item:getName() == "Contract" then
                note = item
                break
            end
        end

        if note then
            local oldText = note:seePage(1) or ""
            local newText = "Total zombies killed: " .. tostring(result.zombieCount or 0)
            local cleanedText = oldText:gsub("Total zombies killed: %d+", "")
            note:addPage(1, cleanedText .. newText)
        end
    end)
end
Events.OnZombieDead.Add(OnZombieDead)

local function checkAndSpawnZombie(player)
    if not player then return end
    local modData = player:getModData()
    if modData.PZLinuxActiveContract == 1 and modData.PZLinuxContractManhunt == 1 then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            PZLinuxRequestContractWorldEvent(player, "spawnManhunt")
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnZombie)

local function checkAndSpawnVehicle(player)
    if not player then return end
    local modData = player:getModData()
    if modData.PZLinuxOnItemRequestCar == 1 then
        local x, y, z = modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, modData.PZLinuxRequestLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            PZLinuxRequestSpawnVehicle(player, function(result)
                if result and result.ok and result.spawned then
                    HaloTextHelper.addGoodText(player, "Requested vehicle delivered")
                end
            end)
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnVehicle)

local function checkAndSpawnBox(player)
    if not player then return end
    local modData = player:getModData()
    if modData.PZLinuxContractCargo == 1 then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            PZLinuxRequestContractWorldEvent(player, "spawnCargo")
        end
    elseif modData.PZLinuxContractCargo == 3 then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        if not x or not y or not z then return end
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist > 50 then
            PZLinuxRequestContractWorldEvent(player, "clearCargo")
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnBox)

local function contractCompletedPlaySound()
    local playerObj = PZLinuxGetPlayer()
    if not playerObj then return end

    local modData = PZLinuxGetModData(playerObj)
    if not modData then return end

    if modData.PZLinuxActiveContract == 9 then
        local globalVolume = getCore():getOptionSoundVolume() / 50
        getSoundManager():PlayWorldSound("done", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        HaloTextHelper.addGoodText(playerObj, "Contract completed");
        modData.PZLinuxActiveContract = 10

        playerObj:getStats():add(CharacterStat.BOREDOM, -5)
        playerObj:getStats():add(CharacterStat.UNHAPPINESS, -5)
        playerObj:getStats():add(CharacterStat.STRESS, -0.05)
    end
end
Events.OnTick.Add(contractCompletedPlaySound)

Events.OnGameStart.Add(function()
    local player = PZLinuxGetPlayer()
    if not player then return end

    local modData = player:getModData()
    if modData.PZLinuxContractManhunt == 2 then
        modData.PZLinuxContractManhunt = 1
    end
end)

local function mailTick()
    if isClient() then return end
    local player = PZLinuxGetPlayer()
    if not player then return end
    PZLinuxApplyReputationDecay(player, 0.001)
    PZLinuxMailTickPlayer(player)
end
Events.EveryTenMinutes.Add(mailTick)
