
require "TimedActions/ISBaseTimedAction"
ISDropTheMailAction = ISBaseTimedAction:derive("ISDropTheMailAction")

function ISDropTheMailAction:isValid()
    return true
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
    getSoundManager():PlayWorldSound("openCloseCabinet", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISDropTheMailAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISDropTheMailAction:perform()
    local inv = self.character:getInventory()
    local parcel = inv:AddItem('Base.Present_ExtraLarge')
    parcel:setName("A gift to thank you")

    local bonusRand = ZombRand(1,6)
    local parcelInv = parcel:getInventory()

    for i = 1, bonusRand do
        local entry = PZLinuxDarkWebItemsTable[ZombRand(#PZLinuxDarkWebItemsTable) + 1]
        if entry and entry.id and #entry.id > 0 then
            local one = entry.id[ZombRand(#entry.id) + 1]
            parcelInv:AddItem(one)
        end
    end

    if bonusRand == 1 then
        local bonusTotal = ZombRand(1,2000)
        parcelInv:AddItem("Base.Revolver")
        for i = 1, bonusTotal do
            parcelInv:AddItem("Base.Money")
        end
    end

    if bonusRand == 2 then
        parcelInv:AddItem("Base.Revolver")
    end

    HaloTextHelper.addGoodText(getPlayer(), "Mail completed successfully!");
    HaloTextHelper.addGoodText(getPlayer(), "You received a gift for your help!");
    getPlayer():getStats():add(CharacterStat.BOREDOM, -2)
    getPlayer():getStats():add(CharacterStat.UNHAPPINESS, -4)

    local globalVolume = getCore():getOptionSoundVolume() / 50
    getSoundManager():PlayWorldSound("done", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)

    local md = self.character:getModData()
    contractsRemoveDrawOnMap(md.pzlinux.mails[self.id].x, md.pzlinux.mails[self.id].y)
    contractsRemoveDrawOnMap(md.pzlinux.mails[self.id].x + 20, md.pzlinux.mails[self.id].y)
    md.pzlinux = md.pzlinux or {}
    md.pzlinux.player = md.pzlinux.player or {}
    md.pzlinux.player.reputation = md.pzlinux.player.reputation or 1
    md.pzlinux.player.reputation = md.pzlinux.player.reputation + 10
    md.pzlinux.mails[self.id].status = 10
    HaloTextHelper.addGoodText(getPlayer(), "Reputation increased to +10");
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