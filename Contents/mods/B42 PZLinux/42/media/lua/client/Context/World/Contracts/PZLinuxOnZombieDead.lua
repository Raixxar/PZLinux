local function OnZombieDead(zombie)
    local modData = getPlayer():getModData()
    modData.PZLinuxOnZombieDead = (modData.PZLinuxOnZombieDead or 0) + 1

    if modData.PZLinuxContractKillZombie == 1 then
        if modData.PZLinuxOnZombieDead >= modData.PZLinuxOnZombieToKill then
            modData.PZLinuxActiveContract = 2
        end
    end
    if modData.PZLinuxContractProtect == 2 then
        if modData.PZLinuxOnZombieDead > 10 then
            modData.PZLinuxContractProtect = 3
        end
    end

    local notebook = nil
    local inv = getPlayer():getInventory()
    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if item:getType() == "Notebook" and item:getName() == "Contract" then
            notebook = item
            break
        end
    end

    if notebook then
        local oldText = notebook:seePage(1) or ""
        local newText = "Total zombies killed: " .. modData.PZLinuxOnZombieDead
        local cleanedText = oldText:gsub("Total zombies killed: %d+", "")
        notebook:addPage(1, cleanedText .. newText)
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
    local key = instanceItem("Base.Key_Blank")
    if modData.PZLinuxOnItemRequestCar == 1 then
        local x, y, z = modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, modData.PZLinuxRequestLocationZ
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        local inv = player:getInventory()
        if dist < 50 then
            local square = getCell():getGridSquare(x, y, z)
            if square then
                local vehicle = addVehicle(modData.PZLinuxOnItemRequestCarName, x, y, z)
                if vehicle then
                    local uniqueKeyId = ZombRand(1, 10000)
                    key:setKeyId(uniqueKeyId)
                    key:setName("Pirated Key #" .. uniqueKeyId)
                    vehicle:setKeyId(uniqueKeyId)
                    vehicle:repair()
                    inv:AddItem(key)
                    modData.PZLinuxOnItemRequestCar = 0
                end
            end
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnVehicle)

local function checkAndSpawnBox(player)
    local modData = player:getModData()
    if modData.PZLinuxContractCargo == 1 then
        local x, y, z = modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractLocationZ
        local dist = math.sqrt((player:getX() - x)^2 + (player:getY() - y)^2)
        local sq = getCell():getGridSquare(x, y , z);
        if dist < 50 then
            local obj = IsoObject.new(sq, "carpentry_01_19")
            sq:AddTileObject(obj)
            modData.PZLinuxContractCargo = 2
        elseif dist > 50 then
            if modData.PZLinuxContractCargo == 3 then
                for i = sq:getObjects():size() - 1, 0, -1 do
                    local obj = sq:getObjects():get(i)
                    if obj and obj:getSprite() and obj:getSprite():getName() == "carpentry_01_19" then
                        sq:removeTileObject(obj)
                        modData.PZLinuxContractCargo = 4
                        break
                    end
                end
            end
        end
    end
end
Events.OnPlayerMove.Add(checkAndSpawnBox)

Events.OnGameStart.Add(function()
    Events.OnPlayerMove.Add(checkAndSpawnZombie)
    local modData = getPlayer():getModData()
    if modData.PZLinuxContractManhunt == 2 then
        modData.PZLinuxContractManhunt = 1
    end
end)