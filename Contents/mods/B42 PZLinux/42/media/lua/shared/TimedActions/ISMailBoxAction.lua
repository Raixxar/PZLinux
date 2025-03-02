ISMailBoxAction = ISBaseTimedAction:derive("ISMailBoxAction")

function ISMailBoxAction:isValid()
    return true
end

function ISMailBoxAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISMailBoxAction:update()
    self.character:faceThisObject(self.item)
end

function ISMailBoxAction:start()
    self.ui = MailBoxMenu_ShowUI(self.character)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISMailBoxAction:stop()
    self.ui:removeFromUIManager()
    ISBaseTimedAction.stop(self)
end

function ISMailBoxAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISMailBoxAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = -1
    return o
end