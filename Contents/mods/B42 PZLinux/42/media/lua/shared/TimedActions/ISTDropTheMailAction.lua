
require "TimedActions/ISBaseTimedAction"
ISDropTheMailAction = ISBaseTimedAction:derive("ISDropTheMailAction")

function ISDropTheMailAction:isValid()
    return self.character ~= nil
end

function ISDropTheMailAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISDropTheMailAction:update()
    self.character:faceThisObject(self.item)
end

function ISDropTheMailAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 50
    getSoundManager():PlayWorldSound("openCloseCabinet", false, self.character:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISDropTheMailAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDropTheMailAction:perform()
    PZLinuxRequestMailComplete(self.character, self.id, function(result)
        if not result or not result.ok then
            if result and result.error == "missing_items" then
                HaloTextHelper.addBadText(self.character, "Missing requested items")
            else
                HaloTextHelper.addBadText(self.character, "Mail delivery rejected")
            end
            return
        end

        HaloTextHelper.addGoodText(self.character, "Mail completed successfully!")
        HaloTextHelper.addGoodText(self.character, "You received a gift for your help!")
        HaloTextHelper.addGoodText(self.character, "Reputation increased to +10")
        self.character:getStats():add(CharacterStat.BOREDOM, -2)
        self.character:getStats():add(CharacterStat.UNHAPPINESS, -4)

        local globalVolume = getCore():getOptionSoundVolume() / 50
        getSoundManager():PlayWorldSound("done", false, self.character:getSquare(), 0, 20, 1, true):setVolume(globalVolume)

        if result.x and result.y and contractsRemoveDrawOnMap then
            contractsRemoveDrawOnMap(result.x, result.y)
            contractsRemoveDrawOnMap(result.x + 20, result.y)
        end
    end)

    ISBaseTimedAction.perform(self)
end

function ISDropTheMailAction:new(character, item, id)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.maxTime = 250
    o.id = id
    return o
end
