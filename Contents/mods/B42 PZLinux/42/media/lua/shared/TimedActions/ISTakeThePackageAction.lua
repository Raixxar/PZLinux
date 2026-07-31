
require "TimedActions/ISBaseTimedAction"
ISTakeThePackageAction = ISBaseTimedAction:derive("ISTakeThePackageAction")

function ISTakeThePackageAction:isValid()
    return self.character ~= nil
end

function ISTakeThePackageAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISTakeThePackageAction:update()
    self.character:faceThisObject(self.item)
end

function ISTakeThePackageAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 50
    getSoundManager():PlayWorldSound("openCloseCabinet", false, self.character:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISTakeThePackageAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISTakeThePackageAction:perform()
    PZLinuxRequestContractWorldEvent(self.character, "pickupPackage", {}, function(result)
        if result and result.ok then
            HaloTextHelper.addGoodText(self.character, "Drop the contract case in a mailbox")
        end
    end)
    ISBaseTimedAction.perform(self)
end

function ISTakeThePackageAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.maxTime = 250
    return o
end
