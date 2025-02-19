ISDarkWebAction = ISBaseTimedAction:derive("ISDarkWebAction")

function ISDarkWebAction:isValid()
    return true
end

function ISDarkWebAction:waitToStart()
    return false
end

function ISDarkWebAction:update()
    return false
end

function ISDarkWebAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function ISDarkWebAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDarkWebAction:perform()
    local item = self.item
    sendRemoveItemFromContainer(item:getContainer(), item)
    item:getContainer():Remove(item)
end

function ISDarkWebAction:new(character, item)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.maxTime = 5
    return o
end