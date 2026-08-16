-- Regression test for a player-requested safety feature: mailbox delivery
-- (both Dark Web buy orders and Buy Goods orders) now stops handing out
-- more parcels once the player is getting too loaded down, leaving
-- whatever's left safely queued for a later visit, instead of dumping an
-- entire backlog on them in one go. From player feedback: carrying a huge
-- pile of parcels all at once because a backlog built up is exactly the
-- kind of situation that can get a player one-shot by a horde -- this mod
-- should never create that risk on its own.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_delivery_weight_limit.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- ---------------------------------------------------------------------
-- 1. Mailbox delivery weight helpers in isolation.
-- ---------------------------------------------------------------------

local worldInteractionsSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxWorldInteractions.lua")
local helperStart = assert(worldInteractionsSource:find("function PZLinuxGetDeliveryMaxCarryMultiplier", 1, true))
local helperEnd = assert(worldInteractionsSource:find("local function PZLinuxGetEntitySquare", helperStart, true))
PZLinux = { Config = { Deliveries = { maxCarryMultiplier = 2 } } }
assert(loadstring(worldInteractionsSource:sub(helperStart, helperEnd - 1)))()

local function makeInventory(current, max)
    return {
        getCapacityWeight = function() return current end,
        getMaxWeight = function() return max end,
    }
end

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels(nil) == true,
    "a missing player must fail open (allow delivery) rather than crash")

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels({ getInventory = function() return {} end }) == true,
    "an inventory with no weight API at all must fail open (e.g. a test mock not simulating weight)")

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels({
    isUnlimitedCarry = function() return true end,
    getInventory = function() return makeInventory(999, 10) end,
}) == true, "unlimited carry (sandbox/debug) must always allow more, regardless of weight")

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels({ getInventory = function() return makeInventory(10, 10) end }) == true,
    "normal maximum carry weight must still allow mailbox delivery")

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels({ getInventory = function() return makeInventory(19.9, 10) end }) == true,
    "just under twice the carrying capacity must still allow another delivery attempt")

PZLinuxTestAssert(PZLinuxDeliveryHasRoomForMoreParcels({ getInventory = function() return makeInventory(20, 10) end }) == false,
    "at twice the carrying capacity, another parcel must remain queued")

PZLinuxTestAssert(PZLinuxDeliveryIsWithinWeightLimit({ getInventory = function() return makeInventory(20, 10) end }) == true,
    "a complete parcel ending exactly at twice the carrying capacity must be accepted")

PZLinuxTestAssert(PZLinuxDeliveryIsWithinWeightLimit({ getInventory = function() return makeInventory(20.1, 10) end }) == false,
    "a complete parcel exceeding twice the carrying capacity must be rolled back")

print("PZLinux delivery weight-limit helper tests OK")

-- ---------------------------------------------------------------------
-- 2. Integration: the Dark Web delivery loop actually stops early, keeps
-- the remaining entries queued, and reports tooHeavy=true.
-- ---------------------------------------------------------------------

PZLinux = { Config = { ATM = { minCash = 0, maxCash = 100 } } }
Perks = { PlantScavenging = "PlantScavenging" }
addXp = function() end
getGameTime = function() return { getWorldAgeHours = function() return 0 end } end
isServer = function() return true end
getScriptManager = function()
    return { FindItem = function(_, _t) return {} end }
end
ZombRand = function(a, b) if a == 1 and b == 101 then return 50 end if b then return a end return 0 end

local FakeItem = {}
FakeItem.__index = FakeItem
function FakeItem:getFullType() return self.fullType end
function FakeItem:getInventory() return self.subInv end
function FakeItem:getModData() self.modData = self.modData or {}; return self.modData end
function FakeItem:setName(name) self.name = name end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.list end
function FakeItems:get(i) return self.list[i + 1] end

local FakeInventory = {}
FakeInventory.__index = FakeInventory
function FakeInventory:getItems() return self.itemsObj end
function FakeInventory:AddItem(fullType)
    local item = setmetatable({ fullType = fullType }, FakeItem)
    if fullType == "Base.Parcel_Large" then
        local subList = setmetatable({ list = {} }, FakeItems)
        item.subInv = setmetatable({ itemsObj = subList }, FakeInventory)
    end
    table.insert(self.itemsObj.list, item)
    return item
end
function FakeInventory:Remove(item)
    for i, it in ipairs(self.itemsObj.list) do
        if it == item then table.remove(self.itemsObj.list, i) break end
    end
end

local function buildInventory()
    local inv = setmetatable({}, FakeInventory)
    inv.itemsObj = setmetatable({ list = {} }, FakeItems)
    return inv
end

local playerModData
local FakePlayer = {}
FakePlayer.__index = FakePlayer
function FakePlayer:getModData() return playerModData end
function FakePlayer:getInventory() return self.inventoryObj end
function FakePlayer:getUsername() return "TestPlayer" end

PZLinux.getPlayer = function(p) return p end
function PZLinuxGetPlayer(p) return p end
function PZLinuxGetPlayerKey(player) return player and player:getUsername() or "?" end
function PZLinuxNormalizeMoney(x) return math.floor(x) end
function PZLinuxLoadBankBalance(player) return playerModData.pzlinux.player.bankBalance or 0 end
function PZLinuxSetBankBalance(player, amount) playerModData.pzlinux.player.bankBalance = amount return amount end
function PZLinuxApplyBankDebit(player, amount, reason, requestId)
    local prev = PZLinuxLoadBankBalance(player)
    local bal = PZLinuxSetBankBalance(player, prev - amount)
    return { ok = true, amount = amount, balance = bal, previousBalance = prev, reason = reason, requestId = requestId }
end
function PZLinuxTransmitPlayerModData(_player) end
function PZLinuxSyncAddedInventoryItem(_player, _card) return true end
function PZLinuxCreateStolenOrderNote(_player) end
function PZLinuxValidateMailboxInteraction(_player, _ref) return "fakeMailboxObj", nil end
function PZLinuxDarkWebCalculateSellPrice(_p, itemData) return itemData.Price end
function PZLinuxDarkWebCalculateBuyPrice(_p, itemData) return itemData.Price end
PZLinuxDarkWebMarketConfig = {
    refreshHours = 24, minimumOffers = 1, maximumOffers = 1,
    stockTiers = { { maximumPrice = nil, minimumStock = 5, maximumStock = 5 } },
}
function PZLinuxDarkWebLoadCustomItems() end
PZLinuxDarkWebItemsTable = { { id = { "Base.Axe" }, Price = 50 } }
function PZLinuxDarkWebGetHourMultiplier() return 1 end
function PZLinuxDarkWebGetPurchaseMultiplier() return 1 end
local globalModData = {}
ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}

-- Only enough "room" for ONE parcel: true the first time this is
-- consulted inside a single delivery call, false every time after.
local roomCallCount = 0
local roomAllowedCalls = 1
function PZLinuxDeliveryHasRoomForMoreParcels(_player)
    roomCallCount = roomCallCount + 1
    return roomCallCount <= roomAllowedCalls
end
function PZLinuxDeliveryIsWithinWeightLimit(_player) return true end

local deliverySource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDeliveryQueue.lua")
assert(loadstring(deliverySource))()
local darkWebSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
assert(loadstring(darkWebSource))()

local function resetPlayer()
    playerModData = { pzlinux = { player = { bankBalance = 1000 } } }
    globalModData = {}
    PZLinux.darkWebBuySessions = {}
    PZLinux.darkWebSellSessions = {}
    roomCallCount = 0
    return setmetatable({ inventoryObj = buildInventory() }, FakePlayer)
end

do
    local player = resetPlayer()
    PZLinuxDarkWebGetBuyOffers(player, "req-offers")
    PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-1")
    PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-2")

    local deliver = PZLinuxDarkWebApplyDeliverOrders(player, {}, "req-deliver")
    PZLinuxTestAssert(deliver.ok, "a delivery that stops early for weight must still report ok")
    PZLinuxTestAssert(deliver.delivered == 1, "only the one parcel there was room for must be delivered, got " .. tostring(deliver.delivered))
    PZLinuxTestAssert(deliver.tooHeavy == true, "the result must flag that delivery stopped early for weight")
    PZLinuxTestAssert(deliver.remaining == 1, "exactly one order must remain queued, got " .. tostring(deliver.remaining))
    PZLinuxTestAssert(player:getInventory():getItems():size() == 1,
        "only one parcel must actually be in the player's inventory")
    PZLinuxTestAssert(playerModData.PZLinuxOnItemBuyOnDarkWebStatus == 1,
        "the pending flag must stay set so the remaining order is retried on the next mailbox visit")
    PZLinuxTestAssert(PZLinuxDeliveryPendingCount(player, "darkweb") == 1,
        "the remaining order must still be persisted in modData")

    -- The next mailbox visit (player has since dropped weight) must pick
    -- up exactly where it left off and finish the job.
    roomCallCount = 0
    roomAllowedCalls = 10
    local secondDeliver = PZLinuxDarkWebApplyDeliverOrders(player, {}, "req-deliver-2")
    PZLinuxTestAssert(secondDeliver.ok and secondDeliver.delivered == 1 and not secondDeliver.tooHeavy,
        "once there's room again, the remaining order must deliver normally")
    PZLinuxTestAssert(playerModData.PZLinuxOnItemBuyOnDarkWebStatus == 0,
        "the pending flag must finally clear once everything is actually delivered")
end

print("PZLinux delivery weight-limit integration tests OK")
