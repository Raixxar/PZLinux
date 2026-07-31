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

local function mailTick()
    if isClient() then return end
    local player = PZLinuxGetPlayer()
    if not player then return end
    PZLinuxApplyReputationDecay(player, 0.001)
    PZLinuxMailTickPlayer(player)
end
Events.EveryTenMinutes.Add(mailTick)
