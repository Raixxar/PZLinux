ISStreetMailBoxAction = ISBaseTimedAction:derive("ISStreetMailBoxAction")

function ISStreetMailBoxAction.isValid(_self)
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
    self.ui = StreetMailBoxMenu_ShowUI(self.character, self.item)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISStreetMailBoxAction:stop()
    if self.ui then
        self.ui:removeFromUIManager()
    end
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
