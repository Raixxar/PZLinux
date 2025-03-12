
require "TimedActions/ISBaseTimedAction"
ISTakeTheCargoAction = ISBaseTimedAction:derive("ISTakeTheCargoAction")

function ISTakeTheCargoAction:isValid()
    return true
end

function ISTakeTheCargoAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISTakeTheCargoAction:update()
    self.character:faceThisObject(self.item)
end

function ISTakeTheCargoAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISTakeTheCargoAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISTakeTheCargoAction:perform()
    local modData = getPlayer():getModData()
    modData.PZLinuxContractCargo = 3
    modData.PZLinuxActiveContract = 9
    testHelicopter()
end

function ISTakeTheCargoAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.maxTime = 1000
    return o
end