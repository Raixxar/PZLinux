completeContractUI = ISPanel:derive("completeContractUI")

-- CONTEXT MENU
function completeContractMenu_AddContext(player, context, worldobjects)
    local function isNearTarget(x, y, z, targetX, targetY, targetZ)
        return math.max(math.abs(x - targetX), math.abs(y - targetY)) <= 5 and z == targetZ
    end

    local modData = getPlayer():getModData()
    local targetX = modData.PZLinuxContractLocationX
    local targetY = modData.PZLinuxContractLocationY
    local targetZ = modData.PZLinuxContractLocationZ

    if modData.PZLinuxContractPickUp == 1 then
        for _, obj in ipairs(worldobjects) do
            if instanceof(obj, "IsoObject") then
                local square = obj:getSquare()
                if square then
                    local x, y, z = square:getX(), square:getY(), square:getZ()
                    if isNearTarget(x, y, z, targetX, targetY, targetZ) then
                        context:addOption("Take the package of the contract", obj, completeContractMenu_OnUse, player, x, y, z)
                        break
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

                                        if modData.PZLinuxContractManhunt == 2 then
                                            context:addOption("Cut the target", body, completeContractMenu_OnCut, player, x, y, z)
                                            break
                                        end
                                        
                                        if modData.PZLinuxContractBlood == 1 then
                                            context:addOption("Take the blood of the target", body, completeContractMenu_OnBlood, player, x, y, z)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
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

Events.OnFillWorldObjectContextMenu.Add(completeContractMenu_AddContext)