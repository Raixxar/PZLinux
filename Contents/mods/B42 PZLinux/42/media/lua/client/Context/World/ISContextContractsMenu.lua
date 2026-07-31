completeContractUI = ISPanel:derive("completeContractUI")

local PZLinuxContractContextSync = {
    pending = {},
    lastAt = {},
}

local function PZLinuxContractsMaybeSyncContext(playerObj)
    local modData = playerObj and playerObj:getModData()
    if not modData or tonumber(modData.PZLinuxActiveContract) == 0 then return end

    local playerKey = tostring(playerObj:getPlayerNum())
    local now = math.floor(getGameTime():getWorldAgeHours() * 3600)
    local pendingAt = PZLinuxContractContextSync.pending[playerKey]
    if pendingAt and now - pendingAt < 10 then return end
    if now - (PZLinuxContractContextSync.lastAt[playerKey] or -10) < 10 then return end

    PZLinuxContractContextSync.pending[playerKey] = now
    PZLinuxContractContextSync.lastAt[playerKey] = now
    PZLinuxRequestContractSync(playerObj, function()
        PZLinuxContractContextSync.pending[playerKey] = nil
    end)
end

local function PZLinuxContractsOnCreatePlayer(_playerIndex, playerObj)
    PZLinuxRequestContractSync(playerObj)
end

-- CONTEXT MENU
function completeContractMenu_AddContext(player, context, worldobjects)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local modData = playerObj:getModData()
    PZLinuxContractsMaybeSyncContext(playerObj)
    local targetX = tonumber(modData.PZLinuxContractLocationX)
    local targetY = tonumber(modData.PZLinuxContractLocationY)
    local targetZ = tonumber(modData.PZLinuxContractLocationZ)
    local worldRecord = PZLinuxContractsGetWorldContract(modData.PZLinuxContractId)
    local packageReady = modData.PZLinuxContractPickUp == 1
        or tonumber(modData.PZLinuxContractTypeId) == 2
        or (worldRecord
            and tonumber(worldRecord.contractId) == 2
            and PZLinuxContractsIsRecordStatus(worldRecord, "accepted", "in_progress"))

    local playerSquare = playerObj:getSquare()
    if packageReady and playerSquare and targetX and targetY and targetZ
    and math.max(math.abs(playerSquare:getX() - targetX), math.abs(playerSquare:getY() - targetY))
        <= (tonumber(PZLinux.Config.Contracts.packageInteractionRadius) or 10)
    and playerSquare:getZ() == targetZ then
        context:addOption("Take the package of the contract", nil, completeContractMenu_OnUse, player)
    end

    if modData.PZLinuxContractCargo == 2
    or modData.PZLinuxContractProtect == 1
    or modData.PZLinuxContractProtect == 3 then
        for _, obj in ipairs(worldobjects) do
            if instanceof(obj, "IsoObject") then
                local square = obj:getSquare()
                if square then
                    local x, y, z = square:getX(), square:getY(), square:getZ()
                    local objectContractId = PZLinuxContractsGetEntityContractId(obj)
                    local objectWorldRecord = PZLinuxContractsGetWorldContract(objectContractId)
                    if objectWorldRecord and tonumber(objectWorldRecord.contractId) == 7 and objectWorldRecord.status == "spawned" then
                        context:addOption("Prepare the cargo to be helicoptered.", obj, completeContractMenu_OnCargo, player, x, y, z)
                        break
                    end
                    if targetX and targetY and targetZ and isNearTarget(x, y, z, targetX, targetY, targetZ) then
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

function completeContractMenu_OnUse(_obj, player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end
    ISTimedActionQueue.add(ISTakeThePackageAction:new(playerObj))
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
Events.OnCreatePlayer.Add(PZLinuxContractsOnCreatePlayer)
