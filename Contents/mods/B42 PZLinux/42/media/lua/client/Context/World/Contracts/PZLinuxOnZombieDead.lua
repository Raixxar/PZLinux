local function OnZombieDead(zombie)
    local modData = getPlayer():getModData()
    modData.PZLinuxOnZombieDead = modData.PZLinuxOnZombieDead or 0
    modData.PZLinuxOnZombieDead = modData.PZLinuxOnZombieDead + 1
    if modData.PZLinuxContractKillZombie == 1 then
        if modData.PZLinuxOnZombieDead >= modData.PZLinuxOnZombieToKill then
            modData.PZLinuxActiveContract = 2
        end
    end
end
Events.OnZombieDead.Add(OnZombieDead)

local function checkAndSpawnZombie(player)
    local modData = player:getModData()
    if modData.PZLinuxActiveContract == 1 and modData.PZLinuxContractManhunt == 1 then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            local square = getCell():getGridSquare(x, y, z)
            if square then
                local zombie = createZombie(x, y, z, nil, 0, IsoDirections.S)
                checkSpawn = 1
                if zombie then
                    zombie:setUseless(true)
                    zombie:setSitAgainstWall(true)
                    modData.PZLinuxContractManhunt = 2
                end
            end
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnZombie)

local function checkAndSpawnVehicle(player)
    local modData = player:getModData()
    if modData.PZLinuxOnItemRequestCar == 1 then
        local x, y, z = modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, modData.PZLinuxRequestLocationZ
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        if dist < 50 then
            local square = getCell():getGridSquare(x, y, z)
            if square then
                local vehicle = addVehicle(modData.PZLinuxOnItemRequestCarName, x, y, z)
                if vehicle then
                    local uniqueKeyId = ZombRand(1, 10000)
                    local key = instanceItem("Base.Key_Blank")
                    key:setKeyId(uniqueKeyId)
                    vehicle:setKeyId(uniqueKeyId)
                    vehicle:putKeyOnDoor(key)        
                    vehicle:addKeyToGloveBox()
                    vehicle:repair()
                    modData.PZLinuxOnItemRequestCar = 0
                end
            end
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnVehicle)

Events.OnGameStart.Add(function()
    Events.OnPlayerMove.Add(checkAndSpawnZombie)
    local modData = getPlayer():getModData()
    if modData.PZLinuxContractManhunt == 2 then
        modData.PZLinuxContractManhunt = 1
    end
end)