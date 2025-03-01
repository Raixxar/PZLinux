
require "TimedActions/ISBaseTimedAction"
ISBloodAction = ISBaseTimedAction:derive("ISBloodAction")

function ISBloodAction:isValid()
    return true
end

function ISBloodAction:waitToStart()
    return false
end

function ISBloodAction:update()
    return false
end

function ISBloodAction:start()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("blood", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function ISBloodAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISBloodAction:perform()
    local inv = self.character:getInventory()
    local parcel = inv:AddItem('Base.EmptyJar')
    parcel:setName("Blood for contract")
    parcel:getFluidContainer():addFluid(FluidType.Blood, 1)
    local modData = getPlayer():getModData()
    modData.PZLinuxContractBlood = 3
end

function ISBloodAction:new(character, worldObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = worldObject
    o.stopOnWalk = true
    o.maxTime = 350
    return o
end