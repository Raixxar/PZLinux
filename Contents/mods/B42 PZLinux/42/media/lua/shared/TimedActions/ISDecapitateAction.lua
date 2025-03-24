
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
    local globalVolume = getCore():getOptionSoundVolume() / 50
    getSoundManager():PlayWorldSound("decapitate", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
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
    local parcelInv = parcel:getInventory()
    parcelInv:AddItem("Base.CorpseMale")
    local modData = getPlayer():getModData()
    modData.PZLinuxContractManhunt = 3
    self.body:removeFromWorld()
    self.body:removeFromSquare()
    HaloTextHelper.addGoodText(getPlayer(), "Drop the bag in a mailbox");
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