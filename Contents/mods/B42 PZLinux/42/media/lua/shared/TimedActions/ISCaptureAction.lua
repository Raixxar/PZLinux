
require "TimedActions/ISBaseTimedAction"
ISCaptureAction = ISBaseTimedAction:derive("ISCaptureAction")

function ISCaptureAction:isValid()
    return self.character ~= nil
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
    PZLinuxRequestContractWorldEvent(self.character, "capture", {
        target = PZLinuxGetZombieReference(self.zombie),
    }, function(result)
        if result and result.ok then
            HaloTextHelper.addGoodText(self.character, "Drop the bag in a mailbox")
        end
    end)
    ISBaseTimedAction.perform(self)
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
