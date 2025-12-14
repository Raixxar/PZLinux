
require "TimedActions/ISBaseTimedAction"
ISTakeThePackageAction = ISBaseTimedAction:derive("ISTakeThePackageAction")

function ISTakeThePackageAction:isValid()
    return true
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
    getSoundManager():PlayWorldSound("openCloseCabinet", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Medium")
    self.character:reportEvent("EventLootItem")
end

function ISTakeThePackageAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISTakeThePackageAction:perform()
    local inv = self.character:getInventory()
    local parcel = inv:AddItem('Base.Bag_ProtectiveCaseSmall')
    parcel:setName("Contract case")

    local bonusRand = ZombRand(1,6)
    local parcelInv = parcel:getInventory()
    if bonusRand == 1 then
        local bonusTotal = ZombRand(1,2000)
        parcelInv:AddItem("Base.Note")
        parcelInv:AddItem("Base.Revolver")
        for i = 1, bonusTotal do
            parcelInv:AddItem("Base.Money")
        end
    else
        parcelInv:AddItem("Base.Note")
    end

    if bonusRand == 2 then
        parcelInv:AddItem("Base.Revolver")
    end

    local modData = getPlayer():getModData()
    modData.PZLinuxContractPickUp = 3
    HaloTextHelper.addGoodText(getPlayer(), "Drop the contract case in a mailbox");
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