
require "TimedActions/ISBaseTimedAction"
ISProtectBuildingAction = ISBaseTimedAction:derive("ISProtectBuildingAction")

function ISProtectBuildingAction:isValid()
    return self.character ~= nil
end

function ISProtectBuildingAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISProtectBuildingAction:update()
    self.character:faceThisObject(self.item)
end

function ISProtectBuildingAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISProtectBuildingAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISProtectBuildingAction:perform()
    PZLinuxRequestContractWorldEvent(self.character, "finishProtect")
    ISBaseTimedAction.perform(self)
end

function ISProtectBuildingAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.maxTime = 1000
    return o
end
