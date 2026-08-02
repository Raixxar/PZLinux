PZLinux = PZLinux or {}

PZLinuxMailboxSpriteNames = {
    ["street_decoration_01_8"] = true,
    ["street_decoration_01_9"] = true,
    ["street_decoration_01_10"] = true,
    ["street_decoration_01_11"] = true,
    ["street_decoration_01_18"] = true,
    ["street_decoration_01_19"] = true,
    ["street_decoration_01_20"] = true,
    ["street_decoration_01_21"] = true,
}

function PZLinuxIsMailboxSprite(spriteName)
    return spriteName ~= nil and PZLinuxMailboxSpriteNames[tostring(spriteName)] == true
end

function PZLinuxGetMailboxReference(mailboxObject)
    if not mailboxObject or not mailboxObject.getSquare then return nil end

    local square = mailboxObject:getSquare()
    local sprite = mailboxObject.getSprite and mailboxObject:getSprite()
    local spriteName = sprite and sprite.getName and sprite:getName()
    if not square or not PZLinuxIsMailboxSprite(spriteName) then return nil end

    return {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        sprite = spriteName,
    }
end

function PZLinuxFindMailboxObject(mailboxRef)
    if type(mailboxRef) ~= "table" or not getCell then return nil end

    local x = tonumber(mailboxRef.x)
    local y = tonumber(mailboxRef.y)
    local z = tonumber(mailboxRef.z)
    local expectedSprite = tostring(mailboxRef.sprite or "")
    if not x or not y or not z or not PZLinuxIsMailboxSprite(expectedSprite) then return nil end

    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        local sprite = object and object.getSprite and object:getSprite()
        local spriteName = sprite and sprite.getName and sprite:getName()
        if spriteName == expectedSprite and PZLinuxIsMailboxSprite(spriteName) then
            return object
        end
    end

    return nil
end


function PZLinuxValidateMailboxInteraction(player, mailboxRef)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return nil, "no_player" end
    if type(mailboxRef) ~= "table" then return nil, "missing_mailbox_reference" end

    local mailboxObject = PZLinuxFindMailboxObject(mailboxRef)
    if not mailboxObject then return nil, "invalid_mailbox" end

    local square = mailboxObject:getSquare()
    local playerX = tonumber(playerObj:getX())
    local playerY = tonumber(playerObj:getY())
    local playerZ = tonumber(playerObj:getZ())
    if not square or not playerX or not playerY or not playerZ then
        return nil, "invalid_mailbox_position"
    end

    if math.abs(playerZ - square:getZ()) > 0.1 then
        return nil, "too_far_from_mailbox"
    end

    local distance = math.max(math.abs(playerX - square:getX()), math.abs(playerY - square:getY()))
    if distance > 2 then
        return nil, "too_far_from_mailbox"
    end

    return mailboxObject, nil
end

local function PZLinuxGetEntitySquare(entity)
    return entity and entity.getSquare and entity:getSquare() or nil
end

local function PZLinuxGetEntityId(entity, methodName)
    if not entity or not entity[methodName] then return nil end
    local value = entity[methodName](entity)
    value = tonumber(value)
    if not value or value < 0 then return nil end
    return value
end

function PZLinuxGetWorldObjectReference(object)
    local square = PZLinuxGetEntitySquare(object)
    if not square then return nil end

    local sprite = object.getSprite and object:getSprite()
    return {
        kind = "object",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        index = object.getObjectIndex and object:getObjectIndex() or nil,
        sprite = sprite and sprite.getName and sprite:getName() or "",
    }
end

function PZLinuxGetDeadBodyReference(body)
    local square = PZLinuxGetEntitySquare(body)
    if not square then return nil end

    local bodyIndex
    local bodies = square:getDeadBodys()
    if bodies then
        for index = 0, bodies:size() - 1 do
            if bodies:get(index) == body then bodyIndex = index break end
        end
    end

    return {
        kind = "body",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        onlineId = PZLinuxGetEntityId(body, "getOnlineID"),
        objectId = PZLinuxGetEntityId(body, "getObjectID"),
        index = bodyIndex,
    }
end

function PZLinuxGetZombieReference(zombie)
    local square = PZLinuxGetEntitySquare(zombie)
    if not square then return nil end

    return {
        kind = "zombie",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        onlineId = PZLinuxGetEntityId(zombie, "getOnlineID"),
    }
end

local function PZLinuxReadEntityReference(ref, expectedKind)
    if type(ref) ~= "table" or ref.kind ~= expectedKind then return nil end
    local x, y, z = tonumber(ref.x), tonumber(ref.y), tonumber(ref.z)
    if not x or not y or not z then return nil end
    return x, y, z
end

function PZLinuxFindWorldObject(ref)
    local x, y, z = PZLinuxReadEntityReference(ref, "object")
    if not x or not getCell then return nil end
    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil end

    local expectedIndex = tonumber(ref.index)
    local expectedSprite = tostring(ref.sprite or "")
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        local sprite = object and object.getSprite and object:getSprite()
        local spriteName = sprite and sprite.getName and sprite:getName() or ""
        local indexMatches = expectedIndex == nil or index == expectedIndex
        if indexMatches and spriteName == expectedSprite then return object end
    end
    return nil
end

function PZLinuxFindDeadBody(ref)
    local x, y, z = PZLinuxReadEntityReference(ref, "body")
    if not x or not getCell then return nil end
    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil end

    local expectedOnlineId = tonumber(ref.onlineId)
    local expectedObjectId = tonumber(ref.objectId)
    local expectedIndex = tonumber(ref.index)
    if not expectedOnlineId and not expectedObjectId and not expectedIndex then return nil end
    local bodies = square:getDeadBodys()
    if not bodies then return nil end
    for index = 0, bodies:size() - 1 do
        local body = bodies:get(index)
        local onlineId = PZLinuxGetEntityId(body, "getOnlineID")
        local objectId = PZLinuxGetEntityId(body, "getObjectID")
        if (expectedOnlineId and onlineId == expectedOnlineId)
        or (expectedObjectId and objectId == expectedObjectId)
        or (not expectedOnlineId and not expectedObjectId and index == expectedIndex) then
            return body
        end
    end
    return nil
end

function PZLinuxFindZombie(ref)
    local x = PZLinuxReadEntityReference(ref, "zombie")
    if not x or not getCell then return nil end
    local expectedOnlineId = tonumber(ref.onlineId)
    if not expectedOnlineId then return nil end

    local zombies = getCell():getZombieList()
    if not zombies then return nil end
    for index = 0, zombies:size() - 1 do
        local zombie = zombies:get(index)
        if PZLinuxGetEntityId(zombie, "getOnlineID") == expectedOnlineId then
            return zombie
        end
    end
    return nil
end

function PZLinuxRemoveReplicatedZombie(ref)
    local zombie = PZLinuxFindZombie(ref)
    if not zombie then return false end

    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setUseless then zombie:setUseless(true) end
    local square = zombie.getSquare and zombie:getSquare() or nil
    if zombie.removeFromWorld then zombie:removeFromWorld() end
    if square and zombie.removeFromSquare then zombie:removeFromSquare() end
    return true
end

function PZLinuxIsPlayerNearPosition(player, x, y, z, maxDistance)
    local playerObj = PZLinuxGetPlayer(player)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not playerObj or not x or not y or not z then return false end
    if math.abs((tonumber(playerObj:getZ()) or 0) - z) > 0.1 then return false end
    local distance = math.max(
        math.abs((tonumber(playerObj:getX()) or 0) - x),
        math.abs((tonumber(playerObj:getY()) or 0) - y)
    )
    return distance <= (tonumber(maxDistance) or 2)
end

function PZLinuxValidateWorldInteraction(player, ref, expectedKind, maxDistance)
    local entity
    if expectedKind == "object" then entity = PZLinuxFindWorldObject(ref) end
    if expectedKind == "body" then entity = PZLinuxFindDeadBody(ref) end
    if expectedKind == "zombie" then entity = PZLinuxFindZombie(ref) end
    if not entity then return nil, "invalid_world_target" end

    local square = PZLinuxGetEntitySquare(entity)
    if not square or not PZLinuxIsPlayerNearPosition(player, square:getX(), square:getY(), square:getZ(), maxDistance) then
        return nil, "too_far_from_world_target"
    end
    return entity, nil
end
