
require "TimedActions/ISBaseTimedAction"
ISDecapitateAction = ISBaseTimedAction:derive("ISDecapitateAction")

function ISDecapitateAction:isValid()
    return true
end

function ISDecapitateAction:waitToStart()
    return false
end

function ISDecapitateAction:update()
    return false
end

function ISDecapitateAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("decapitate", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function ISDecapitateAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDecapitateAction:perform()
    local inv = self.character:getInventory()
    local parcel = inv:AddItem('Base.Bag_Mail')
    parcel:setName("Cut target")
    self.item:removeFromWorld()
    self.item:removeFromSquare()
    local modData = getPlayer():getModData()
    modData.PZLinuxContractManhunt = 3
end

function ISDecapitateAction:new(character, worldObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = worldObject
    o.stopOnWalk = true
    o.maxTime = 350
    return o
end