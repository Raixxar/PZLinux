-- Regression test written while investigating a player-reported bug: a
-- Dark Web purchase (money debited, confirmed) never delivered at the
-- mailbox -- no parcel, no "stolen" note, no error either -- most
-- reproducible when a Dark Web sale (redeem) and a pending buy order
-- landed at the mailbox together ("une commande seule fonctionne, c'est
-- vraiment quand il y a les deux que le bug apparait").
--
-- This test exercises the exact sequences reported (a single buy; buying
-- twice before ever visiting the mailbox; a sell immediately followed by a
-- buy, then RedeemSales and DeliverOrders back to back, matching solo's
-- synchronous dispatch order for MailBoxUI:onSendTakePackage's parallel
-- requests) against the real PZLinuxDarkWebApplyBuy/ApplySell/
-- ApplyRedeemSales/ApplyDeliverOrders functions. These all passed even
-- against the ORIGINAL nested-table queue, using this test's simple,
-- always-persistent fake modData table -- which is exactly why the real
-- bug (a nested value not reliably persisting between separate commands in
-- the real game, confirmed via the player's own server logs -- see
-- test_queue_mutation_persistence.lua for the fix and a test that actually
-- reproduces it) slipped past this file the first time around. Kept as a
-- permanent regression guard for the sequences themselves now that the
-- queue is a flat string.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_deliver_orders.lua$") or "."
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

-- ---- Fake PZ environment ----
PZLinux = { Config = { ATM = { minCash = 0, maxCash = 100 } } }
Perks = { PlantScavenging = "PlantScavenging" }
addXp = function() end
getGameTime = function() return { getWorldAgeHours = function() return 0 end } end
isServer = function() return true end
getScriptManager = function()
    return { FindItem = function(_, _t) return { getActualWeight = function() return 0 end } end }
end
-- Avoid the 10% theft roll so this test observes the normal delivery path;
-- theft itself is exercised elsewhere.
ZombRand = function(a, b) if a == 1 and b == 101 then return 50 end if b then return a end return 0 end

local FakeItem = {}
FakeItem.__index = FakeItem
function FakeItem:getFullType() return self.fullType end
function FakeItem:getName() return self.displayName or self.fullType end
function FakeItem:setName(n) self.displayName = n end
function FakeItem:getModData() self.md = self.md or {}; return self.md end
function FakeItem:getInventory() return self.subInv end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.list end
function FakeItems:get(i) return self.list[i + 1] end

local FakeInventory = {}
FakeInventory.__index = FakeInventory
function FakeInventory:getItems() return self.itemsObj end
function FakeInventory:AddItem(fullType)
    local item = setmetatable({ fullType = fullType }, FakeItem)
    if fullType == "Base.Parcel_Large" or fullType == "Base.SuspiciousPackage" then
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
function FakePlayer:getX() return 0 end
function FakePlayer:getY() return 0 end
function FakePlayer:getZ() return 0 end
function FakePlayer:getUsername() return "TestPlayer" end

PZLinux.getPlayer = function(p) return p end
function PZLinuxGetPlayer(p) return p end
function PZLinuxGetPlayerKey(player) return player and player:getUsername() or "?" end
function PZLinuxNormalizeMoney(x) return math.floor(x) end
function PZLinuxLoadBankBalance(player) return playerModData.pzlinux.player.bankBalance or 0 end
function PZLinuxSetBankBalance(player, amount) playerModData.pzlinux.player.bankBalance = amount return amount end
function PZLinuxApplyBankCredit(player, amount, reason, requestId)
    local prev = PZLinuxLoadBankBalance(player)
    local bal = PZLinuxSetBankBalance(player, prev + amount)
    return { ok = true, amount = amount, balance = bal, previousBalance = prev, reason = reason, requestId = requestId }
end
function PZLinuxApplyBankDebit(player, amount, reason, requestId)
    local prev = PZLinuxLoadBankBalance(player)
    local bal = PZLinuxSetBankBalance(player, prev - amount)
    return { ok = true, amount = amount, balance = bal, previousBalance = prev, reason = reason, requestId = requestId }
end
function PZLinuxRemoveInventoryItem(player, item)
    player:getInventory():Remove(item)
    return true
end
function PZLinuxTransmitPlayerModData(_player) end
function PZLinuxSyncAddedInventoryItem(_player, _card) return true end
function PZLinuxCreateStolenOrderNote(_player) end
function PZLinuxValidateMailboxInteraction(_player, _ref) return "fakeMailboxObj", nil end
function PZLinuxDeliveryHasRoomForMoreParcels(_player) return true end
function PZLinuxDeliveryIsWithinWeightLimit(_player) return true end
function PZLinuxDarkWebCalculateSellPrice(_p, itemData) return itemData.Price end
function PZLinuxDarkWebCalculateBuyPrice(_p, itemData) return itemData.Price end
PZLinuxDarkWebMarketConfig = {
    refreshHours = 24, minimumOffers = 1, maximumOffers = 1,
    stockTiers = { { maximumPrice = nil, minimumStock = 5, maximumStock = 5 } },
}
function PZLinuxDarkWebLoadCustomItems() end
PZLinuxDarkWebItemsTable = { { id = { "Base.CigaretteSingle" }, Price = 50 } }
function PZLinuxDarkWebGetHourMultiplier() return 1 end
function PZLinuxDarkWebGetPurchaseMultiplier() return 1 end
local globalModData = {}
ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}

local deliverySource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDeliveryQueue.lua")
assert(loadstring(deliverySource))()
local darkWebSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
assert(loadstring(darkWebSource))()

local function resetPlayer()
    playerModData = { pzlinux = { player = { bankBalance = 1000 } } }
    globalModData = {}
    PZLinux.darkWebBuySessions = {}
    PZLinux.darkWebSellSessions = {}
    return setmetatable({ inventoryObj = buildInventory() }, FakePlayer)
end

-- ---------------------------------------------------------------------
-- Scenario A: a single buy, then straight to the mailbox.
-- ---------------------------------------------------------------------
do
    local player = resetPlayer()
    PZLinuxDarkWebGetBuyOffers(player, "req-offers-a")
    local buy = PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-a")
    PZLinuxTestAssert(buy.ok, "single buy must succeed")
    local balanceAfterBuy = PZLinuxLoadBankBalance(player)
    local replayedBuy = PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-a")
    PZLinuxTestAssert(replayedBuy.ok and replayedBuy.replayed
        and PZLinuxLoadBankBalance(player) == balanceAfterBuy
        and PZLinuxDeliveryPendingCount(player, "darkweb") == 1,
        "replaying a purchase request after a restart must not debit or enqueue it twice")
    local deliver = PZLinuxDarkWebApplyDeliverOrders(player, {}, "req-deliver-a")
    PZLinuxTestAssert(deliver.ok and deliver.delivered == 1 and not deliver.lost,
        "a single pending order must deliver on the next mailbox visit")
    PZLinuxTestAssert(player:getInventory():getItems():size() == 1,
        "exactly one delivered parcel must be in the inventory")
end

-- ---------------------------------------------------------------------
-- Scenario B: buy twice before ever visiting the mailbox.
-- ---------------------------------------------------------------------
do
    local player = resetPlayer()
    PZLinuxDarkWebGetBuyOffers(player, "req-offers-b")
    PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-b1")
    PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-b2")
    PZLinuxTestAssert(PZLinuxDeliveryPendingCount(player, "darkweb") == 2,
        "both purchases must be queued")
    local deliver = PZLinuxDarkWebApplyDeliverOrders(player, {}, "req-deliver-b")
    PZLinuxTestAssert(deliver.ok and deliver.delivered == 2 and not deliver.lost,
        "both queued orders must deliver on a single mailbox visit")
    PZLinuxTestAssert(player:getInventory():getItems():size() == 2,
        "two delivered parcels must be in the inventory")
end

-- ---------------------------------------------------------------------
-- Scenario C: a sell (creates a redeemable package) immediately followed
-- by a buy, then RedeemSales and DeliverOrders back to back -- the exact
-- combination reported to silently lose the order.
-- ---------------------------------------------------------------------
do
    local player = resetPlayer()
    player:getInventory():AddItem("Base.CigaretteSingle")
    local sellOffers = PZLinuxDarkWebBuildSellOffers(player, "req-sell-offers-c")
    PZLinuxTestAssert(#sellOffers.offers == 1, "the carried cigarette must show up as a sell offer")
    local sell = PZLinuxDarkWebApplySell(player, 1, 1, "req-sell-c")
    PZLinuxTestAssert(sell.ok, "the sell must succeed and create a redeemable package")

    PZLinuxDarkWebGetBuyOffers(player, "req-buy-offers-c")
    local buy = PZLinuxDarkWebApplyBuy(player, 1, 1, "req-buy-c")
    PZLinuxTestAssert(buy.ok, "the buy right after a sell must succeed and queue an order")

    local redeem = PZLinuxDarkWebApplyRedeemSales(player, {}, "req-redeem-c")
    PZLinuxTestAssert(redeem.ok and redeem.redeemed == 1 and redeem.amount == sell.amount,
        "the sale package must redeem for the correct amount")

    local deliver = PZLinuxDarkWebApplyDeliverOrders(player, {}, "req-deliver-c")
    PZLinuxTestAssert(deliver.ok and deliver.delivered == 1 and not deliver.lost,
        "the pending buy order must still deliver even after a sell/redeem happened right before it in the same visit")
    PZLinuxTestAssert(player:getInventory():getItems():size() == 1,
        "exactly the delivered parcel must remain in the inventory (the sale package was consumed by redeem)")
    local remainingItem = player:getInventory():getItems():get(0)
    PZLinuxTestAssert(remainingItem:getFullType() == "Base.Parcel_Large",
        "the remaining item must be the delivered order parcel")
end

print("PZLinux Dark Web deliver-orders combo tests OK")
