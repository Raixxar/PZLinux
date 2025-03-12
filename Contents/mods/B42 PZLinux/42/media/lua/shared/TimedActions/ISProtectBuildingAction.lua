
require "TimedActions/ISBaseTimedAction"
ISProtectBuildingAction = ISBaseTimedAction:derive("ISProtectBuildingAction")

function ISProtectBuildingAction:isValid()
    return true
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
    local modData = getPlayer():getModData()
    modData.PZLinuxContractProtect = 3
    modData.PZLinuxActiveContract = 9
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