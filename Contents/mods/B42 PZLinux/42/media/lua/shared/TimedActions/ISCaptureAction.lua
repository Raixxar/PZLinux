
require "TimedActions/ISBaseTimedAction"
ISCaptureAction = ISBaseTimedAction:derive("ISCaptureAction")

function ISCaptureAction:isValid()
    return true
end

function ISCaptureAction:waitToStart()
    self.character:faceThisObject(self.zombie)
	return self.character:shouldBeTurning()
end

function ISCaptureAction:update()
    self.character:faceThisObject(self.zombie)
end

function ISCaptureAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "medium")
    self.character:reportEvent("EventLootItem")
end

function ISCaptureAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISCaptureAction:perform()
    local inv = self.character:getInventory()
    local parcel = inv:AddItem('Base.Bag_Mail')
    parcel:setName("Zombie captured alive")
    local parcelInv = parcel:getInventory()
    parcelInv:AddItem("Base.CorpseMale")
    local modData = getPlayer():getModData()
    modData.PZLinuxContractCapture = 3
    self.zombie:removeFromWorld()
    self.zombie:removeFromSquare()
    HaloTextHelper.addGoodText(getPlayer(), "Drop the bag in a mailbox");
end

function ISCaptureAction:new(character, zombie)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.zombie = zombie
    o.stopOnWalk = true
    o.maxTime = 100
    return o
end