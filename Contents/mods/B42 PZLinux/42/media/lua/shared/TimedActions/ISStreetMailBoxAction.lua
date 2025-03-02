ISStreetMailBoxAction = ISBaseTimedAction:derive("ISStreetMailBoxAction")

function ISStreetMailBoxAction:isValid()
    return true
end

function ISStreetMailBoxAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISStreetMailBoxAction:update()
    self.character:faceThisObject(self.item)
end

function ISStreetMailBoxAction:start()
    self.ui = StreetMailBoxMenu_ShowUI(self.character)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISStreetMailBoxAction:stop()
    self.ui:removeFromUIManager()
    ISBaseTimedAction.stop(self)
end

function ISStreetMailBoxAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISStreetMailBoxAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = -1
    return o
end