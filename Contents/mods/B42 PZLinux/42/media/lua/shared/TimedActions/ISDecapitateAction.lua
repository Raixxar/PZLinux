
require "TimedActions/ISBaseTimedAction"
ISDecapitateAction = ISBaseTimedAction:derive("ISDecapitateAction")

function ISDecapitateAction:isValid()
    return true
end

function ISDecapitateAction:waitToStart()
    self.character:faceThisObject(self.body)
	return self.character:shouldBeTurning()
end

function ISDecapitateAction:update()
    self.character:faceThisObject(self.body)
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
    self.body:removeFromWorld()
    self.body:removeFromSquare()
    local modData = getPlayer():getModData()
    modData.PZLinuxContractManhunt = 3
end

function ISDecapitateAction:new(character, body)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.body = body
    o.stopOnWalk = true
    o.maxTime = 350
    return o
end