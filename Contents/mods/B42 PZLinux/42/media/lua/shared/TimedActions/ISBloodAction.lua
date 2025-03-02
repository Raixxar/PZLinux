
require "TimedActions/ISBaseTimedAction"
ISBloodAction = ISBaseTimedAction:derive("ISBloodAction")

function ISBloodAction:isValid()
    return true
end

function ISBloodAction:waitToStart()
    self.character:faceThisObject(self.body)
	return self.character:shouldBeTurning()
end

function ISBloodAction:update()
    self.character:faceThisObject(self.body)
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

function ISBloodAction:new(character, body)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.body = body
    o.stopOnWalk = true
    o.maxTime = 350
    return o
end