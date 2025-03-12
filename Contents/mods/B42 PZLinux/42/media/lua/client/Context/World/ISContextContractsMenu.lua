completeContractUI = ISPanel:derive("completeContractUI")

-- CONTEXT MENU
function completeContractMenu_AddContext(player, context, worldobjects)
    local modData = getPlayer():getModData()
    local targetX = modData.PZLinuxContractLocationX
    local targetY = modData.PZLinuxContractLocationY
    local targetZ = modData.PZLinuxContractLocationZ

    if modData.PZLinuxContractPickUp == 1 
    or modData.PZLinuxContractCargo == 2 
    or modData.PZLinuxContractProtect == 1
    or modData.PZLinuxContractProtect == 3 then
        for _, obj in ipairs(worldobjects) do
            if instanceof(obj, "IsoObject") then
                local square = obj:getSquare()
                if square then
                    local x, y, z = square:getX(), square:getY(), square:getZ()
                    if isNearTarget(x, y, z, targetX, targetY, targetZ) then
                        if modData.PZLinuxContractPickUp == 1 then context:addOption("Take the package of the contract", obj, completeContractMenu_OnUse, player, x, y, z); break end
                        if modData.PZLinuxContractCargo == 2 then context:addOption("Prepare the cargo to be helicoptered.", obj, completeContractMenu_OnCargo, player, x, y, z); break end
                        if modData.PZLinuxContractProtect == 1 then context:addOption("Protect the building", obj, completeContractMenu_OnProtect, player, x, y, z); break end
                        if modData.PZLinuxContractProtect == 3 then context:addOption("Tag the sector as clear", obj, completeContractMenu_OnProtect, player, x, y, z); break end
                    end
                end
            end
        end
    end

    if modData.PZLinuxContractManhunt == 2 or modData.PZLinuxContractBlood == 1 then
        local checkedSquares = {}
        for _, obj in ipairs(worldobjects) do
            if instanceof(obj, "IsoObject") then
                local square = obj:getSquare()
                if square and not checkedSquares[square] then
                    checkedSquares[square] = true
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            local nearbySquare = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
                            if nearbySquare then
                                local deadBodies = nearbySquare:getDeadBodys()
                                if deadBodies and not deadBodies:isEmpty() then
                                    for i = 0, deadBodies:size() - 1 do
                                        local body = deadBodies:get(i)
                                        local x, y, z = nearbySquare:getX(), nearbySquare:getY(), nearbySquare:getZ()

                                        if modData.PZLinuxContractManhunt == 2 then context:addOption("Cut the target", body, completeContractMenu_OnCut, player, x, y, z); break end                             
                                        if modData.PZLinuxContractBlood == 1 and modData.PZLinuxOnZombieDead > 0 then context:addOption("Take the blood of the target", body, completeContractMenu_OnBlood, player, x, y, z) break end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if modData.PZLinuxContractCapture == 1 then
        local squareClicked = getPlayer():getSquare()
        local targetX, targetY, targetZ = squareClicked:getX(), squareClicked:getY(), squareClicked:getZ()
        local zombies = getCell():getZombieList()
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            local square = zombie:getSquare()
            if square then
                local x, y, z = square:getX(), square:getY(), square:getZ()
                if isNearTargetCapture(x, y, z, targetX, targetY, targetZ) then
                    context:addOption("Capture a zombie", zombie, completeContractMenu_OnCapture, player, x, y, z)
                    break
                end
            end
        end
    end
end

function completeContractMenu_OnUse(obj, player,  x, y, z)
    local playerSquare = getPlayer():getSquare()
    if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
        local freeSquare = getAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), freeSquare))
        end
    end
    ISTimedActionQueue.add(ISTakeThePackageAction:new(getPlayer(), obj))
end

function completeContractMenu_OnCut(body, player, x, y, z)
    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(getPlayer(), x, y, z))
    ISTimedActionQueue.add(ISDecapitateAction:new(getPlayer(), body))
end

function completeContractMenu_OnBlood(body, player, x, y, z)
    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(getPlayer(), x, y, z))
    ISTimedActionQueue.add(ISBloodAction:new(getPlayer(), body))
end

function completeContractMenu_OnCapture(zombie, player, x, y, z)
    local playerSquare = getPlayer():getSquare()
    if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
        local freeSquare = getAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), freeSquare))
        end
    end
    ISTimedActionQueue.add(ISCaptureAction:new(getPlayer(), zombie))
end

function completeContractMenu_OnCargo(obj, player, x, y, z)
    addSound(getPlayer(), x, y, z, 1000, 100)
    local playerSquare = getPlayer():getSquare()
    if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
        local freeSquare = getAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), freeSquare))
        end
    end
    ISTimedActionQueue.add(ISTakeTheCargoAction:new(getPlayer(), obj))
end

function completeContractMenu_OnProtect(obj, player, x, y, z)
    local modData = getPlayer():getModData()
    if modData.PZLinuxContractProtect == 3 then
        local playerSquare = getPlayer():getSquare()
        if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
            local freeSquare = getAdjacentFreeSquare(x, y, z, sprite)
            if freeSquare then
                ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), freeSquare))
            end
        end
        ISTimedActionQueue.add(ISProtectBuildingAction:new(getPlayer(), obj))
    else
        modData.PZLinuxContractProtect = 2
        local randCountSpawn = ZombRand(50,200)
        for i = 1, randCountSpawn do
            local randRadiusSpawn = ZombRand(20,50)
            local randDirectionSpawn = ZombRand(1,5)
            if randDirectionSpawn == 1 then local zombie = createZombie(x + randRadiusSpawn, y + randRadiusSpawn, z, nil, 0, IsoDirections.S) end
            if randDirectionSpawn == 2 then local zombie = createZombie(x - randRadiusSpawn, y - randRadiusSpawn, z, nil, 0, IsoDirections.S) end
            if randDirectionSpawn == 3 then local zombie = createZombie(x + randRadiusSpawn, y - randRadiusSpawn, z, nil, 0, IsoDirections.S) end
            if randDirectionSpawn == 4 then local zombie = createZombie(x - randRadiusSpawn, y + randRadiusSpawn, z, nil, 0, IsoDirections.S) end
        end
        addSound(getPlayer(), x, y, z, 1000, 100)
        HaloTextHelper.addGoodText(getPlayer(), "Kill 10 zombies and return here to confirm the area is secure");
    end
end

Events.OnFillWorldObjectContextMenu.Add(completeContractMenu_AddContext)