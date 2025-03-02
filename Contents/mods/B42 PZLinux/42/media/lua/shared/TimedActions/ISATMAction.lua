ISATMAction = ISBaseTimedAction:derive("ISATMAction")

function ISATMAction:isValid()
    return true
end

function ISATMAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISATMAction:update()
    self.character:faceThisObject(self.item)
end

function ISATMAction:start()
    self.ui = AtmMenu_ShowUI(self.character)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISATMAction:stop()
    self.ui:removeFromUIManager()
    ISBaseTimedAction.stop(self)
end

function ISATMAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISATMAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = -1
    return o
end