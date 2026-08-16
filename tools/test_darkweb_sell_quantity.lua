-- Regression test for two player-requested Dark Web Sell changes:
--
-- 1. A quantity field, defaulting to 0 (so a stray click never sells
--    anything by accident), matching how Buy already works -- instead of
--    always selling every single matching item the player owns. Also:
--    when selling fewer than everything owned, currently-EQUIPPED items
--    (e.g. a worn bulletproof vest) are only ever reached for once there
--    aren't enough non-equipped matches left to cover the request, so
--    selling 2 out of 3 owned (1 worn + 2 spare) never touches the worn
--    one without the player having to unequip/stash it first.
--
-- 2. Sell prices used to re-roll (a fresh ZombRand every single call)
--    every time the offer list rebuilt, including right after selling a
--    completely different item -- felt buggy, since prices should only
--    change when the market itself refreshes. Now cached per item/session
--    the same way Buy already caches its own prices, reset together on
--    the same market-generation boundary.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_sell_quantity.lua$") or "."
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
-- 1. Client source checks: the quantity box defaults to "0" and a
-- quantity of 0 must never even send a request.
-- ---------------------------------------------------------------------

local clientSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxDarkWeb.lua")
PZLinuxTestAssert(clientSource:find('ISTextEntryBox:new("0", quantityX, controlY, quantityWidth', 1, true),
    "the Sell quantity box must default to \"0\"")
PZLinuxTestAssert(clientSource:find("if quantity < 1 then return end", 1, true),
    "onSellItem must refuse to act at all when the chosen quantity is 0")

-- ---------------------------------------------------------------------
-- 2. Functional tests against the real PZLinuxDarkWebApplySell/
-- BuildSellOffers.
-- ---------------------------------------------------------------------

PZLinux = { Config = { ATM = { minCash = 0, maxCash = 100 } } }
function PZLinuxDeliveryCreateReceiptId() return "test-darkweb-receipt" end
function PZLinuxDeliveryFindReceiptByRequest() return nil end
function PZLinuxDeliveryCancelReceipt() return true end
Perks = { PlantScavenging = "PlantScavenging" }
addXp = function() end
getGameTime = function() return { getWorldAgeHours = function() return 0 end } end
isServer = function() return true end
getScriptManager = function()
    return { FindItem = function(_, _t) return {} end }
end

local FakeItem = {}
FakeItem.__index = FakeItem
function FakeItem:getFullType() return self.fullType end
function FakeItem:getName() return self.displayName or self.fullType end
function FakeItem:setName(n) self.displayName = n end
function FakeItem:getModData() self.md = self.md or {}; return self.md end
function FakeItem:getInventory() return self.subInv end
function FakeItem:isEquipped() return self.equipped == true end

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
function PZLinuxRemoveInventoryItem(player, item)
    player:getInventory():Remove(item)
    return true
end
function PZLinuxTransmitPlayerModData(_player) end
function PZLinuxSyncAddedInventoryItem(_player, _card) return true end

local sellPriceCallCount = 0
function PZLinuxDarkWebCalculateSellPrice(_player, _itemData)
    sellPriceCallCount = sellPriceCallCount + 1
    -- A different value every call, exactly what the old re-rolling bug
    -- would have produced -- if caching works, the offer's price must
    -- never change between separate PZLinuxDarkWebBuildSellOffers calls.
    return 100 + sellPriceCallCount
end

PZLinuxDarkWebMarketConfig = {
    refreshHours = 24, minimumOffers = 1, maximumOffers = 1,
    stockTiers = { { maximumPrice = nil, minimumStock = 5, maximumStock = 5 } },
}
function PZLinuxDarkWebLoadCustomItems() end
PZLinuxDarkWebItemsTable = { { id = { "Base.KevlarVest" }, Price = 500 } }
function PZLinuxDarkWebGetHourMultiplier() return 1 end
function PZLinuxDarkWebGetPurchaseMultiplier() return 1 end
ModData = { getOrCreate = function(_key) PZLinux._fakeMarket = PZLinux._fakeMarket or {}; return PZLinux._fakeMarket end }
ZombRand = function(a, b) if a == 1 and b == 101 then return 50 end if b then return a end return 0 end

local darkWebSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
assert(loadstring(darkWebSource))()

local function resetPlayer()
    playerModData = { pzlinux = { player = { bankBalance = 0 } } }
    PZLinux.darkWebSellSessions = {}
    return setmetatable({ inventoryObj = buildInventory() }, FakePlayer)
end

-- --- Price stability across rebuilds ---
do
    local player = resetPlayer()
    player:getInventory():AddItem("Base.KevlarVest")
    local first = PZLinuxDarkWebBuildSellOffers(player, "req-a")
    local second = PZLinuxDarkWebBuildSellOffers(player, "req-b")
    PZLinuxTestAssert(first.offers[1].price == second.offers[1].price,
        "the sell price must stay the same across separate offer-list rebuilds, got "
        .. tostring(first.offers[1].price) .. " then " .. tostring(second.offers[1].price))
end

-- --- Quantity: sell fewer than owned, protecting the equipped one ---
do
    local player = resetPlayer()
    local worn = player:getInventory():AddItem("Base.KevlarVest")
    worn.equipped = true
    player:getInventory():AddItem("Base.KevlarVest")
    player:getInventory():AddItem("Base.KevlarVest")

    PZLinuxDarkWebBuildSellOffers(player, "req-offers")
    local result = PZLinuxDarkWebApplySell(player, 1, 2, "req-sell-2")
    PZLinuxTestAssert(result.ok and result.soldCount == 2, "selling 2 of 3 owned must succeed")

    local remaining = player:getInventory():getItems()
    local vestsLeft = 0
    local wornStillThere = false
    for i = 0, remaining:size() - 1 do
        local item = remaining:get(i)
        if item:getFullType() == "Base.KevlarVest" then
            vestsLeft = vestsLeft + 1
            if item == worn then wornStillThere = true end
        end
    end
    PZLinuxTestAssert(vestsLeft == 1, "exactly 1 vest must remain after selling 2 of 3, found " .. vestsLeft)
    PZLinuxTestAssert(wornStillThere, "the equipped vest must be the one left behind, not sold")
end

-- --- Quantity: selling more than owned is rejected, nothing removed ---
do
    local player = resetPlayer()
    player:getInventory():AddItem("Base.KevlarVest")
    PZLinuxDarkWebBuildSellOffers(player, "req-offers2")
    local result = PZLinuxDarkWebApplySell(player, 1, 5, "req-sell-toomany")
    PZLinuxTestAssert(not result.ok and result.error == "not_enough_owned",
        "requesting more than owned must be rejected with not_enough_owned")
    PZLinuxTestAssert(player:getInventory():getItems():size() == 1,
        "a rejected oversized sell must not remove anything")
end

-- --- Quantity: 0/invalid is rejected server-side too (defense in depth) ---
do
    local player = resetPlayer()
    player:getInventory():AddItem("Base.KevlarVest")
    PZLinuxDarkWebBuildSellOffers(player, "req-offers3")
    local result = PZLinuxDarkWebApplySell(player, 1, 0, "req-sell-zero")
    PZLinuxTestAssert(not result.ok and result.error == "invalid_amount",
        "a quantity of 0 must be rejected server-side even if the client should never send it")
end

print("PZLinux Dark Web sell quantity/price-stability tests OK")
