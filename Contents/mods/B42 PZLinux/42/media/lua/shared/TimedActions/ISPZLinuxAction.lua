ISPZLinuxAction = ISBaseTimedAction:derive("ISPZLinuxAction")

function ISPZLinuxAction:isValid()
    return true
end

function ISPZLinuxAction:waitToStart()
    self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISPZLinuxAction:update()
    self.character:faceThisObject(self.item)
    local modData = self.character:getModData()

    if modData.PZLinuxUIOpenMenu == 1 then 
        self.ui = linuxMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 2 then
        self.ui = connectMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 3 then
        self.ui = darkWebMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 4 then
        self.ui = tradingMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 5 then
        self.ui = walletMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 6 then
        self.ui = hackingMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 7 then
        self.ui = contractsMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end

    if modData.PZLinuxUIOpenMenu == 8 then
        self.ui = requestMenu_ShowUI(self.character)
        modData.PZLinuxUIOpenMenu = 0
    end
end

function ISPZLinuxAction:start()
    local modData = self.character:getModData()
    modData.PZLinuxUIOpenMenu = 0
    self.ui = linuxMenu_ShowUI(self.character)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISPZLinuxAction:stop()
    self.ui:removeFromUIManager()
    ISBaseTimedAction.stop(self)
end

function ISPZLinuxAction:perform()
    ISBaseTimedAction.perform(self)
end

function ISPZLinuxAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = -1
    return o
end