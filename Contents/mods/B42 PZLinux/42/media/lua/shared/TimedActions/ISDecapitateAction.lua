
require "TimedActions/ISBaseTimedAction"
ISDecapitateAction = ISBaseTimedAction:derive("ISDecapitateAction")

function ISDecapitateAction:isValid()
    return self.character ~= nil
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
    getSoundManager():PlayWorldSound("decapitate", false, self.character:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function ISDecapitateAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDecapitateAction:perform()
    PZLinuxRequestContractWorldEvent(self.character, "decapitate", {
        target = PZLinuxGetDeadBodyReference(self.body),
    }, function(result)
        if result and result.ok then
            HaloTextHelper.addGoodText(self.character, "Drop the bag in a mailbox")
        end
    end)
    ISBaseTimedAction.perform(self)
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
