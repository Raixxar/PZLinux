completeContractUI = ISPanel:derive("completeContractUI")

-- CONTEXT MENU
function completeContractMenu_AddContext(player, context, worldobjects)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local modData = playerObj:getModData()
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
                    local objectContractId = PZLinuxContractsGetEntityContractId(obj)
                    local worldRecord = PZLinuxContractsGetWorldContract(objectContractId)
                    if worldRecord and tonumber(worldRecord.contractId) == 7 and worldRecord.status == "spawned" then
                        context:addOption("Prepare the cargo to be helicoptered.", obj, completeContractMenu_OnCargo, player, x, y, z)
                        break
                    end
                    if targetX and targetY and targetZ and isNearTarget(x, y, z, targetX, targetY, targetZ) then
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
        local squareClicked = playerObj:getSquare()
        local captureTargetX, captureTargetY, captureTargetZ = squareClicked:getX(), squareClicked:getY(), squareClicked:getZ()
        local zombies = getCell():getZombieList()
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            local square = zombie:getSquare()
            if square then
                local x, y, z = square:getX(), square:getY(), square:getZ()
                if isNearTargetCapture(x, y, z, captureTargetX, captureTargetY, captureTargetZ) then
                    context:addOption("Capture a zombie", zombie, completeContractMenu_OnCapture, player, x, y, z)
                    break
                end
            end
        end
    end
end

function completeContractMenu_OnUse(obj, player,  x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISTakeThePackageAction:new(playerObj, obj))
end

function completeContractMenu_OnCut(body, player, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(playerObj, x, y, z))
    ISTimedActionQueue.add(ISDecapitateAction:new(playerObj, body))
end

function completeContractMenu_OnBlood(body, player, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(playerObj, x, y, z))
    ISTimedActionQueue.add(ISBloodAction:new(playerObj, body))
end

function completeContractMenu_OnCapture(zombie, player, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISCaptureAction:new(playerObj, zombie))
end

function completeContractMenu_OnCargo(obj, player, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    addSound(playerObj, x, y, z, 1000, 100)
    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISTakeTheCargoAction:new(playerObj, obj))
end

function completeContractMenu_OnProtect(obj, player, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local modData = playerObj:getModData()
    if modData.PZLinuxContractProtect == 3 then
        local playerSquare = playerObj:getSquare()
        if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
            local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z)
            if freeSquare then
                ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
            end
        end
        ISTimedActionQueue.add(ISProtectBuildingAction:new(playerObj, obj))
    else
        PZLinuxRequestContractWorldEvent(playerObj, "startProtect", {
            target = PZLinuxGetWorldObjectReference(obj),
        })
        addSound(playerObj, x, y, z, 1000, 100)
        HaloTextHelper.addGoodText(playerObj, "Kill 10 zombies and return here to confirm the area is secure");
    end
end

Events.OnFillWorldObjectContextMenu.Add(completeContractMenu_AddContext)
