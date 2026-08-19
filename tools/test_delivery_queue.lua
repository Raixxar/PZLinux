local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_delivery_queue.lua$") or "."
local queuePath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxDeliveryQueue.lua"

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local modDataStore = {}
ModData = {
    getOrCreate = function(key)
        modDataStore[key] = modDataStore[key] or {}
        return modDataStore[key]
    end,
}
getGameTime = function()
    return { getWorldAgeHours = function() return 123 end }
end
PZLinux = { Config = { Deliveries = { maxCarryWeight = 60, maxParcelWeight = 60 } } }
local itemWeights = {
    ["Base.Generator_Old"] = 40,
    ["Base.TestSword"] = 10,
}
getScriptManager = function()
    return {
        FindItem = function(_, fullType)
            return { getActualWeight = function() return itemWeights[fullType] or 0 end }
        end,
    }
end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.values end
function FakeItems:get(index) return self.values[index + 1] end

local FakeInventory = {}
FakeInventory.__index = FakeInventory
function FakeInventory:getItems() return self.items end
function FakeInventory:AddItem(fullType)
    if self.root.failType == fullType then return nil end
    local item = {
        fullType = fullType,
        modData = {},
        getFullType = function(value) return value.fullType end,
        getModData = function(value) return value.modData end,
        setName = function(value, name) value.name = name end,
    }
    if fullType == "Base.Parcel_Large" or fullType == "Base.Present_ExtraLarge" then
        item.inventory = setmetatable({
            root = self.root,
            items = setmetatable({ values = {} }, FakeItems),
        }, FakeInventory)
        item.getInventory = function(value) return value.inventory end
    end
    table.insert(self.items.values, item)
    return item
end
function FakeInventory:Remove(item)
    for index, current in ipairs(self.items.values) do
        if current == item then
            table.remove(self.items.values, index)
            return
        end
    end
end

local function PZLinuxTestInventory()
    local root = {}
    local inventory = setmetatable({
        root = root,
        items = setmetatable({ values = {} }, FakeItems),
    }, FakeInventory)
    root.inventory = inventory
    return inventory, root
end

local inventory, inventoryRoot = PZLinuxTestInventory()
local player = {
    getUsername = function() return "QueueTester" end,
    getInventory = function() return inventory end,
}

function PZLinuxGetPlayer(value) return value end
function PZLinuxGetPlayerKey(value) return value:getUsername() end
function PZLinuxDeliveryHasRoomForMoreParcels() return true end
local allowProjectedWeight = true
local projectedWeightCallCount = 0
local projectedWeightFailOnCall
function PZLinuxDeliveryIsWithinWeightLimit()
    projectedWeightCallCount = projectedWeightCallCount + 1
    if projectedWeightFailOnCall == projectedWeightCallCount then return false end
    return allowProjectedWeight
end
local synchronized = 0
function PZLinuxSyncAddedInventoryItem()
    synchronized = synchronized + 1
    return true
end

assert(loadstring(PZLinuxTestRead(queuePath)))()

local first, firstCreated = PZLinuxDeliveryEnqueue(
    player, "darkweb", { { name = "Base.Axe", quantity = 1 } }, "buy-1")
local duplicate, duplicateCreated = PZLinuxDeliveryEnqueue(
    player, "darkweb", { { name = "Base.Axe", quantity = 99 } }, "buy-1")
local second = PZLinuxDeliveryEnqueue(
    player, "darkweb", { { name = "Base.Nails", quantity = 2 } }, "buy-2")

PZLinuxTestAssert(firstCreated and not duplicateCreated and duplicate.id == first.id,
    "a repeated requestId must reuse its original order")
PZLinuxTestAssert(first.id ~= second.id and PZLinuxDeliveryPendingCount(player, "darkweb") == 2,
    "successive purchases must have distinct persistent order IDs")

local generatorOrder = PZLinuxDeliveryEnqueue(
    player, "generator-split", { { name = "Base.Generator_Old", quantity = 2 } }, "buy-generators")
PZLinuxTestAssert(#generatorOrder.parcels == 2
    and generatorOrder.parcels[1].items[1].quantity == 1
    and generatorOrder.parcels[2].items[1].quantity == 1,
    "two 40-weight generators must be planned as two parcels under the 60-weight ceiling")
PZLinuxTestAssert(generatorOrder.parcels[1].id ~= generatorOrder.parcels[2].id,
    "every parcel part must have a stable unique ID inside its parent order")

local swordOrder = PZLinuxDeliveryEnqueue(
    player, "sword-split", { { name = "Base.TestSword", quantity = 10 } }, "buy-swords")
PZLinuxTestAssert(#swordOrder.parcels == 2
    and swordOrder.parcels[1].items[1].quantity == 6
    and swordOrder.parcels[2].items[1].quantity == 4,
    "ten 10-weight swords must be planned as parcels containing six and four items")

projectedWeightCallCount = 0
projectedWeightFailOnCall = 2
local firstSplitDelivery = PZLinuxDeliveryDeliverPending(player, "generator-split")
PZLinuxTestAssert(firstSplitDelivery.ok and firstSplitDelivery.parcels == 1
    and firstSplitDelivery.delivered == 1 and firstSplitDelivery.tooHeavy
    and PZLinuxDeliveryPendingCount(player, "generator-split") == 1,
    "the first parcel part must remain delivered when the next part reaches the carrying limit")
PZLinuxTestAssert(generatorOrder.parcels[1].status == "delivered"
    and generatorOrder.parcels[2].status == "pending",
    "a partially collected order must persist each parcel status independently")

projectedWeightCallCount = 0
projectedWeightFailOnCall = nil
local secondSplitDelivery = PZLinuxDeliveryDeliverPending(player, "generator-split")
PZLinuxTestAssert(secondSplitDelivery.ok and secondSplitDelivery.parcels == 1
    and secondSplitDelivery.delivered == 1 and not secondSplitDelivery.tooHeavy,
    "a later mailbox visit must resume with only the remaining parcel part")
local firstGeneratorParcel = inventory:getItems():get(inventory:getItems():size() - 2)
local secondGeneratorParcel = inventory:getItems():get(inventory:getItems():size() - 1)
PZLinuxTestAssert(firstGeneratorParcel:getModData().PZLinuxDeliveryOrderId == generatorOrder.id
    and secondGeneratorParcel:getModData().PZLinuxDeliveryOrderId == generatorOrder.id
    and firstGeneratorParcel:getModData().PZLinuxDeliveryPartId ~= secondGeneratorParcel:getModData().PZLinuxDeliveryPartId,
    "split parcels must share the parent order ID but carry distinct part IDs")
local splitReplay = PZLinuxDeliveryDeliverPending(player, "generator-split")
PZLinuxTestAssert(splitReplay.parcels == 0,
    "replaying a completed multi-parcel order must not duplicate any part")

local legacyOrder = PZLinuxDeliveryEnqueue(
    player, "legacy-plan", { { name = "Base.TestSword", quantity = 10 } }, "legacy-plan-request")
legacyOrder.parcels = nil
legacyOrder.parcelPlanVersion = nil
local legacyDelivery = PZLinuxDeliveryDeliverPending(player, "legacy-plan")
PZLinuxTestAssert(legacyDelivery.ok and legacyDelivery.parcels == 2
    and #legacyOrder.parcels == 2
    and legacyOrder.parcelPlanVersion == 1,
    "a pending v2 order must receive and persist its parcel plan during delivery")

local inventoryBeforeDarkWeb = inventory:getItems():size()
local synchronizedBeforeDarkWeb = synchronized
local delivered = PZLinuxDeliveryDeliverPending(player, "darkweb")
PZLinuxTestAssert(delivered.ok and delivered.parcels == 2 and delivered.delivered == 3,
    "every complete queued order must be delivered")
PZLinuxTestAssert(inventory:getItems():size() == inventoryBeforeDarkWeb + 2
    and synchronized == synchronizedBeforeDarkWeb + 2,
    "each order must create and synchronize exactly one parcel")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(player, "darkweb") == 0,
    "delivered orders must leave the pending queue")

local repeated = PZLinuxDeliveryDeliverPending(player, "darkweb")
PZLinuxTestAssert(repeated.parcels == 0 and inventory:getItems():size() == inventoryBeforeDarkWeb + 2,
    "retrying delivery must never duplicate delivered parcels")

local recoveredOrder = PZLinuxDeliveryEnqueue(
    player, "request", { { name = "Base.Hammer", quantity = 1 } }, "request-1")
recoveredOrder.status = "materializing"
local recoveredParcel = inventory:AddItem("Base.Parcel_Large")
recoveredParcel:getModData().PZLinuxDeliveryOrderId = recoveredOrder.id
recoveredParcel:getInventory():AddItem("Base.Hammer")
local beforeRecovery = inventory:getItems():size()
local recovered = PZLinuxDeliveryDeliverPending(player, "request")
PZLinuxTestAssert(recovered.recovered == 1 and recovered.parcels == 0,
    "an already materialized complete parcel must be recovered without recreation")
PZLinuxTestAssert(inventory:getItems():size() == beforeRecovery,
    "recovery must not add another parcel")

local failedOrder = PZLinuxDeliveryEnqueue(player, "mail_reward", {
    { name = "Base.Apple", quantity = 1 },
    { name = "Base.Fail", quantity = 1 },
}, "mail-1", { parcelType = "Base.Present_ExtraLarge", parcelName = "Test gift" })
inventoryRoot.failType = "Base.Fail"
local beforeFailure = inventory:getItems():size()
local failed = PZLinuxDeliveryDeliverPending(player, "mail_reward")
PZLinuxTestAssert(not failed.ok and failedOrder.status == "pending",
    "an item creation failure must keep the whole order pending")
PZLinuxTestAssert(inventory:getItems():size() == beforeFailure,
    "a partially filled parcel must be removed entirely")
inventoryRoot.failType = nil

local retry = PZLinuxDeliveryDeliverPending(player, "mail_reward")
PZLinuxTestAssert(retry.ok and retry.parcels == 1 and retry.delivered == 2,
    "the intact order must deliver fully once item creation works again")
local deliveredGift = inventory:getItems():get(inventory:getItems():size() - 1)
PZLinuxTestAssert(deliveredGift:getFullType() == "Base.Present_ExtraLarge"
    and deliveredGift.name == "Test gift",
    "mail rewards must preserve their dedicated parcel type and name")

local heavyOrder = PZLinuxDeliveryEnqueue(
    player, "request", { { name = "Base.Generator", quantity = 1 } }, "request-heavy")
allowProjectedWeight = false
local beforeHeavy = inventory:getItems():size()
local heavy = PZLinuxDeliveryDeliverPending(player, "request")
PZLinuxTestAssert(heavy.ok and heavy.tooHeavy and heavyOrder.status == "pending",
    "a parcel crossing the post-fill weight limit must remain pending")
PZLinuxTestAssert(inventory:getItems():size() == beforeHeavy,
    "an overweight parcel must not remain in inventory")
allowProjectedWeight = true

local receiptId, receiptCreated = PZLinuxDeliveryCreateReceiptId(
    player, "darkweb", "sale-request-1", { amount = 500 })
local repeatedReceiptId, repeatedReceiptCreated = PZLinuxDeliveryCreateReceiptId(
    player, "darkweb", "sale-request-1", { amount = 999 })
PZLinuxTestAssert(receiptCreated and not repeatedReceiptCreated and repeatedReceiptId == receiptId,
    "a replayed sale request must reuse its original persistent receipt")
PZLinuxTestAssert(not PZLinuxDeliveryIsReceiptRedeemed(receiptId),
    "a new sale receipt must start unredeemed")
PZLinuxTestAssert(PZLinuxDeliveryMarkReceiptRedeemed(receiptId, player),
    "a sale receipt must redeem once")
PZLinuxTestAssert(PZLinuxDeliveryIsReceiptRedeemed(receiptId)
    and not PZLinuxDeliveryMarkReceiptRedeemed(receiptId, player),
    "the same sale receipt must never redeem twice")

print("PZLinux persistent delivery queue tests OK")
