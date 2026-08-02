
require "TimedActions/ISBaseTimedAction"
ISTakeTheCargoAction = ISBaseTimedAction:derive("ISTakeTheCargoAction")

function ISTakeTheCargoAction:isValid()
    return self.character ~= nil
end

function ISTakeTheCargoAction:waitToStart()
    if self.item then self.character:faceThisObject(self.item) end
	return self.character:shouldBeTurning()
end

function ISTakeTheCargoAction:update()
    if self.item then self.character:faceThisObject(self.item) end
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
    PZLinuxRequestContractWorldEvent(self.character, "takeCargo", {}, function(result)
        if not result or not result.ok then return end
        local helicopterHandler = rawget(_G, "testHelicopter")
        if type(helicopterHandler) == "function" then
            helicopterHandler()
        else
            print("PZLinux warning: testHelicopter handler is missing")
        end
    end)
    ISBaseTimedAction.perform(self)
end

function ISTakeTheCargoAction:new(character, item, x, y, z)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.x = x
    o.y = y
    o.z = z
    o.stopOnWalk = true
    o.maxTime = 1000
    return o
end
