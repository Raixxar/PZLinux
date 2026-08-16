local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_mail_reward_queue.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTestFunction(source, name, nextName)
    local first = assert(source:find("function " .. name, 1, true), name .. " not found")
    local last = assert(source:find("function " .. nextName, first + 1, true), nextName .. " not found")
    return source:sub(first, last - 1)
end

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local globalModData = {}
ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}
getGameTime = function() return { getWorldAgeHours = function() return 10 end } end
ZombRand = function(minimum, maximum)
    if maximum then return minimum end
    return 0
end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.values end
function FakeItems:get(index) return self.values[index + 1] end

local FakeInventory = {}
FakeInventory.__index = FakeInventory
function FakeInventory:getItems() return self.items end
function FakeInventory:AddItem(fullType)
    local item = {
        fullType = fullType,
        modData = {},
        getFullType = function(value) return value.fullType end,
        getModData = function(value) return value.modData end,
        setName = function(value, name) value.name = name end,
    }
    if fullType == "Base.Present_ExtraLarge" then
        item.inventory = setmetatable({ items = setmetatable({ values = {} }, FakeItems) }, FakeInventory)
        item.getInventory = function(value) return value.inventory end
    end
    table.insert(self.items.values, item)
    return item
end
function FakeInventory:Remove(item)
    for index, value in ipairs(self.items.values) do
        if value == item then table.remove(self.items.values, index); return end
    end
end

local inventory = setmetatable({ items = setmetatable({ values = {} }, FakeItems) }, FakeInventory)
local playerModData = { PZLinuxOnMailReward = 2 }
local player = {
    getUsername = function() return "MailTester" end,
    getModData = function() return playerModData end,
    getInventory = function() return inventory end,
}

PZLinux = {}
PZLinuxDarkWebItemsTable = { { id = { "Base.Bandage" } } }
function PZLinuxGetPlayer(value) return value end
function PZLinuxGetPlayerKey(value) return value:getUsername() end
function PZLinuxTransmitPlayerModData() end
function PZLinuxDeliveryHasRoomForMoreParcels() return true end
function PZLinuxDeliveryIsWithinWeightLimit() return true end
function PZLinuxSyncAddedInventoryItem() return true end
function PZLinuxValidateMailboxInteraction() return {}, nil end

assert(loadstring(PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxDeliveryQueue.lua")))()

local shared = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
assert(loadstring(PZLinuxTestFunction(shared, "PZLinuxMailBuildRewardItems", "PZLinuxMailGiveReward")))()
assert(loadstring(PZLinuxTestFunction(shared, "PZLinuxMailGiveReward", "PZLinuxMailMigrateLegacyRewards")))()
assert(loadstring(PZLinuxTestFunction(shared, "PZLinuxMailMigrateLegacyRewards", "PZLinuxMailApplyRewardDelivery")))()
assert(loadstring(PZLinuxTestFunction(shared, "PZLinuxMailApplyRewardDelivery", "PZLinuxMailApplyComplete")))()

local firstMigration = PZLinuxMailMigrateLegacyRewards(player)
local secondMigration = PZLinuxMailMigrateLegacyRewards(player)
PZLinuxTestAssert(firstMigration == 2 and secondMigration == 2,
    "legacy mail rewards must migrate exactly once without multiplying on refresh")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(player, "mail_reward") == 2,
    "every owed legacy gift must become one persistent order")

local delivery = PZLinuxMailApplyRewardDelivery(player, {}, "mail-delivery-1")
PZLinuxTestAssert(delivery.ok and delivery.parcels == 2 and delivery.remaining == 0,
    "all complete mail gifts must be delivered in distinct parcels")
PZLinuxTestAssert(inventory:getItems():size() == 2 and playerModData.PZLinuxOnMailReward == 0,
    "mail delivery must clear only delivered orders and update its compatibility counter")

local repeated = PZLinuxMailApplyRewardDelivery(player, {}, "mail-delivery-2")
PZLinuxTestAssert(repeated.ok and repeated.parcels == 0 and inventory:getItems():size() == 2,
    "checking the mailbox again must not duplicate mail gifts")

print("PZLinux mail reward queue tests OK")
