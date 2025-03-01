
require "TimedActions/ISBaseTimedAction"
ISTakeThePackageAction = ISBaseTimedAction:derive("ISTakeThePackageAction")

function ISTakeThePackageAction:isValid()
    return true
end

function ISTakeThePackageAction:waitToStart()
    return false
end

function ISTakeThePackageAction:update()
    return false
end

function ISTakeThePackageAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("openCloseCabinet", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
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
    local modData = getPlayer():getModData()
    modData.PZLinuxContractPickUp = 3
end

function ISTakeThePackageAction:new(character, worldObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = worldObject
    o.stopOnWalk = true
    o.maxTime = 250
    return o
end