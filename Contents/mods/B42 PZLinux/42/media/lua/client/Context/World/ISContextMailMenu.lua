function completeMailAmmo_AddContext(player, context, worldobjects)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local md = playerObj:getModData()
    if not (md.pzlinux and md.pzlinux.mails) then return end

    for _, obj in ipairs(worldobjects) do
        local square = obj.getSquare and obj:getSquare() or nil
        if square then
            local x, y, z = square:getX(), square:getY(), square:getZ()
            for id, mail in pairs(md.pzlinux.mails) do
                if type(id) == "number" and type(mail) == "table" then
                    if mail.status == 2 then
                        if isNearTarget(x, y, z, mail.x, mail.y, mail.z) then
                            context:addOption("Deposit the requested items from the email", obj, completeMailMenu_OnUse, playerObj, id, x, y, z)
                            return
                        end
                    end
                end
            end
        end
    end
end

function completeMailMenu_OnUse(obj, player, id, x, y, z)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local md = playerObj:getModData()
    if not (md.pzlinux and md.pzlinux.mails and md.pzlinux.mails[id]) then return end
    local mail = md.pzlinux.mails[id]
    if mail.status ~= 2 then return end

    local playerSquare = playerObj:getSquare()
    if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISDropTheMailAction:new(playerObj, obj, id))
end

Events.OnFillWorldObjectContextMenu.Add(completeMailAmmo_AddContext)
