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
    local hasOtherLocationObjective = tonumber(modData.PZLinuxContractManhunt) == 1
        or tonumber(modData.PZLinuxContractManhunt) == 2
        or tonumber(modData.PZLinuxContractCargo) == 1
        or tonumber(modData.PZLinuxContractCargo) == 2
        or tonumber(modData.PZLinuxContractProtect) == 1
        or tonumber(modData.PZLinuxContractProtect) == 2
        or tonumber(modData.PZLinuxContractProtect) == 3
    local legacyPackageFallback = tonumber(modData.PZLinuxActiveContract) == 1
        and targetX and targetX > 0 and targetY and targetY > 0
        and not hasOtherLocationObjective
    local packageReady = modData.PZLinuxContractPickUp == 1
        or tonumber(modData.PZLinuxContractTypeId) == 2
        or legacyPackageFallback
        or (worldRecord
            and tonumber(worldRecord.contractId) == 2
            and PZLinuxContractsIsRecordStatus(worldRecord, "accepted", "in_progress"))

    local playerSquare = playerObj:getSquare()
    local packageRadius = tonumber(PZLinux.Config.Contracts.packageInteractionRadius) or 5
    local packageDistance = playerSquare and targetX and targetY and math.max(
        math.abs(playerSquare:getX() - targetX),
        math.abs(playerSquare:getY() - targetY)
    ) or math.huge
    local packageSameZ = playerSquare and targetZ and playerSquare:getZ() == targetZ
    if packageReady and packageDistance <= packageRadius and packageSameZ then
        context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_TakeContractPackage"), nil, completeContractMenu_OnUse, player)
    elseif packageReady and packageDistance <= 100 then
        print("[PZLinux Contracts Context] option missing"
            .. " active=" .. tostring(modData.PZLinuxActiveContract)
            .. " type=" .. tostring(modData.PZLinuxContractTypeId)
            .. " pickup=" .. tostring(modData.PZLinuxContractPickUp)
            .. " worldId=" .. tostring(modData.PZLinuxContractId)
            .. " worldType=" .. tostring(worldRecord and worldRecord.contractId)
            .. " worldStatus=" .. tostring(worldRecord and worldRecord.status)
            .. " player=" .. tostring(playerSquare and playerSquare:getX()) .. "," .. tostring(playerSquare and playerSquare:getY()) .. "," .. tostring(playerSquare and playerSquare:getZ())
            .. " target=" .. tostring(targetX) .. "," .. tostring(targetY) .. "," .. tostring(targetZ)
            .. " distance=" .. tostring(packageDistance)
            .. " radius=" .. tostring(packageRadius)
            .. " sameZ=" .. tostring(packageSameZ))
    end

    local cargoDistance = playerSquare and targetX and targetY and math.max(
        math.abs(playerSquare:getX() - targetX),
        math.abs(playerSquare:getY() - targetY)
    ) or math.huge
    local cargoState = tonumber(modData.PZLinuxContractCargo) or 0
    local cargoRecordReady = worldRecord
        and tonumber(worldRecord.contractId) == 7
        and PZLinuxContractsIsRecordStatus(worldRecord, "accepted", "spawned")
    local cargoReady = tonumber(modData.PZLinuxActiveContract) == 1
        and (cargoState == 1
            or cargoState == 2
            or tonumber(modData.PZLinuxContractTypeId) == 7
            or cargoRecordReady)
    if cargoReady
    and cargoDistance <= packageRadius and packageSameZ then
        context:addOption(
            PZLinuxGetText("IGUI_PZLinux_Context_PrepareCargo"),
            nil,
            completeContractMenu_OnCargo,
            player,
            targetX,
            targetY,
            targetZ
        )
    elseif cargoReady and cargoDistance <= 100 then
        print("[PZLinux Cargo Context] outside interaction radius"
            .. " state=" .. tostring(cargoState)
            .. " type=" .. tostring(modData.PZLinuxContractTypeId)
            .. " worldStatus=" .. tostring(worldRecord and worldRecord.status)
            .. " player=" .. tostring(playerSquare and playerSquare:getX()) .. "," .. tostring(playerSquare and playerSquare:getY()) .. "," .. tostring(playerSquare and playerSquare:getZ())
            .. " target=" .. tostring(targetX) .. "," .. tostring(targetY) .. "," .. tostring(targetZ)
            .. " distance=" .. tostring(cargoDistance)
            .. " radius=" .. tostring(packageRadius)
            .. " sameZ=" .. tostring(packageSameZ))
    end

    if modData.PZLinuxContractProtect == 1
    or modData.PZLinuxContractProtect == 3 then
        for _, obj in ipairs(worldobjects) do
            if instanceof(obj, "IsoObject") then
                local square = obj:getSquare()
                if square then
                    local x, y, z = square:getX(), square:getY(), square:getZ()
                    if targetX and targetY and targetZ and isNearTarget(x, y, z, targetX, targetY, targetZ) then
                        if modData.PZLinuxContractProtect == 1 then context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_ProtectBuilding"), obj, completeContractMenu_OnProtect, player, x, y, z); break end
                        if modData.PZLinuxContractProtect == 3 then context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_MarkSectorClear"), obj, completeContractMenu_OnProtect, player, x, y, z); break end
                    end
                end
            end
        end
    end

    local manhuntWorldStatus = tostring(modData.PZLinuxContractWorldStatus
        or (worldRecord and worldRecord.status)
        or "")
    local manhuntRecordDown = tonumber(modData.PZLinuxContractTypeId) == 3
        and manhuntWorldStatus == "target_down"
    local manhuntReady = manhuntRecordDown
        or (manhuntWorldStatus == ""
            and tonumber(modData.PZLinuxContractTypeId) == 3
            and tonumber(modData.PZLinuxContractManhunt) == 2)
    local bloodReady = tonumber(modData.PZLinuxContractBlood) == 1
        and (tonumber(modData.PZLinuxOnZombieDead) or 0) > 0
    if manhuntReady or bloodReady then
        local checkedSquares = {}
        local centers = { playerSquare }
        for _, obj in ipairs(worldobjects) do
            local square = obj and obj.getSquare and obj:getSquare() or nil
            if square then table.insert(centers, square) end
        end

        local manhuntAdded = false
        local bloodAdded = false
        for _, centerSquare in ipairs(centers) do
            for dx = -2, 2 do
                for dy = -2, 2 do
                    local nearbySquare = getCell():getGridSquare(
                        centerSquare:getX() + dx,
                        centerSquare:getY() + dy,
                        centerSquare:getZ()
                    )
                    if nearbySquare and not checkedSquares[nearbySquare] then
                        checkedSquares[nearbySquare] = true
                        local deadBodies = nearbySquare:getDeadBodys()
                        if deadBodies then
                            for index = 0, deadBodies:size() - 1 do
                                local body = deadBodies:get(index)
                                local x, y, z = nearbySquare:getX(), nearbySquare:getY(), nearbySquare:getZ()
                                local targetDeathX = tonumber(worldRecord and worldRecord.targetDeathX)
                                local targetDeathY = tonumber(worldRecord and worldRecord.targetDeathY)
                                local targetDeathZ = tonumber(worldRecord and worldRecord.targetDeathZ)
                                local matchesRecordedDeath = not targetDeathX or (
                                    math.max(math.abs(x - targetDeathX), math.abs(y - targetDeathY)) <= 2
                                    and (not targetDeathZ or z == targetDeathZ)
                                )

                                if manhuntReady and not manhuntAdded and matchesRecordedDeath then
                                    context:addOption(
                                        PZLinuxGetText("IGUI_PZLinux_Context_CutTarget"),
                                        body,
                                        completeContractMenu_OnCut,
                                        player,
                                        x,
                                        y,
                                        z
                                    )
                                    manhuntAdded = true
                                end
                                if bloodReady and not bloodAdded then
                                    context:addOption(
                                        PZLinuxGetText("IGUI_PZLinux_Context_TakeZombieBlood"),
                                        body,
                                        completeContractMenu_OnBlood,
                                        player,
                                        x,
                                        y,
                                        z
                                    )
                                    bloodAdded = true
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
                    context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_CaptureZombie"), zombie, completeContractMenu_OnCapture, player, x, y, z)
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
    ISTimedActionQueue.add(ISTakeTheCargoAction:new(playerObj, obj, x, y, z))
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
