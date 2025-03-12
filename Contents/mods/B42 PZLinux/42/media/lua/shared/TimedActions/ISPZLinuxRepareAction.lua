ISPZLinuxRepareAction = ISBaseTimedAction:derive("ISPZLinuxRepareAction")

function ISPZLinuxRepareAction:isValid()
    local items = self.character:getInventory():getItems()
    for j = items:size() - 1, 0, -1 do
        local item = items:get(j)
        if item and item:getFullType() == "Base.ElectronicsScrap" then
            return true
        else 
            HaloTextHelper.addBadText(getPlayer(), "I need electronic parts");
            return false
        end
    end
end

function ISPZLinuxRepareAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISPZLinuxRepareAction:update()
    self.character:faceThisObject(self.item)
end

function ISPZLinuxRepareAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("screw", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISPZLinuxRepareAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISPZLinuxRepareAction:perform()
    local items = self.character:getInventory():getItems()
    for j = items:size() - 1, 0, -1 do
        local item = items:get(j)
        if item and item:getFullType() == "Base.ElectronicsScrap" then
            self.character:getInventory():Remove(item)
            break
        end
    end
    self.item:getModData().statusCondition = self.item:getModData().statusCondition + ZombRand(5,11) * (self.character:getPerkLevel(Perks.Electricity) + 1)
    if self.item:getModData().statusCondition > 100 then self.item:getModData().statusCondition = 100 end
    ISBaseTimedAction.perform(self)
end

function ISPZLinuxRepareAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = 430
    return o
end