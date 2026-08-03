-- luacheck: globals getGameTime ZombRand PZLinux
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_sell_surplus.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- Lightweight catalog: 2 categories (one sellable, one the vehicle category
-- that must never be offered), independent of the real 13-category data file.
PZLinuxRequestDefinitions = {
    [1] = { baseName = "Canned food", price = 1000, items = { "Base.ItemA", "Base.ItemB" } },
    [9] = { baseName = "Car", price = 65000, vehicles = {} },
}

local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

-- PZLinuxRequestsAllCategoryIds is a `local function` in the real file, so it
-- is not visible to a separately-loaded chunk; provide an equivalent global
-- for the Sell Surplus slice below to call.
PZLinuxRequestsAllCategoryIds = function()
    local ids = {}
    for contractId in pairs(PZLinuxRequestDefinitions or {}) do
        table.insert(ids, tonumber(contractId))
    end
    table.sort(ids)
    return ids
end

local first = assert(source:find("-- Sell Surplus: the inverse of Requests, Dark Web-styled", 1, true))
local last = assert(source:find("function PZLinuxRequestsFindDeliveredVehicle", first, true))
assert(loadstring(source:sub(first, last - 1)))()

PZLinux = { Config = { Sell = {
    demandChancePercent = 15,
    quantityMin = 1,
    quantityMax = 10,
    basePricePercentMin = 15,
    basePricePercentMax = 25,
    greatDealChancePercent = 10,
    greatDealMinPercent = 25,
    greatDealMaxPercent = 75,
    negotiateIncrement = 100,
    negotiateSuccessChancePercent = 50,
} } }

local currentDay = 0
PZLinuxRequestsCurrentGameDay = function() return currentDay end

-- Deterministic: ZombRand(min[, max]) always returns min. Combined with the
-- config above, this always rolls "item wanted" (1 <= 15), quantity = 1 (the
-- minimum), and a "great deal" (1 <= 10) at the cheapest end of its range.
ZombRand = function(minimum) return minimum end

PZLinuxGetPlayerKey = function() return "sell-test-player" end
local transmitCalls = 0
PZLinuxTransmitPlayerModData = function() transmitCalls = transmitCalls + 1 end
PZLinuxLoadBankBalance = function() return 1000 end
local creditCalls, lastCreditAmount = 0, 0
PZLinuxApplyBankCredit = function(_, amount)
    creditCalls = creditCalls + 1
    lastCreditAmount = tonumber(amount) or 0
    return { ok = true, amount = lastCreditAmount, balance = 1000 + lastCreditAmount }
end
PZLinuxValidateMailboxInteraction = function() return {}, nil end
PZLinuxNormalizeMoney = function(amount) return math.floor(tonumber(amount) or 0) end
PZLinuxSyncAddedInventoryItem = function() return true end
PZLinuxRemoveInventoryItem = function(player, item) player:getInventory():Remove(item) end

local function PZLinuxTestList(values)
    local list = { values = values or {} }
    function list:size() return #self.values end
    function list:get(index) return self.values[index + 1] end
    return list
end

local function PZLinuxTestNewPlayer()
    local inventory = { values = {} }
    function inventory:getItems() return PZLinuxTestList(self.values) end
    function inventory:Remove(item)
        for index = #self.values, 1, -1 do
            if self.values[index] == item then table.remove(self.values, index) end
        end
    end
    function inventory:AddItem(fullType)
        local itemModData = {}
        local item = { fullType = fullType, name = fullType }
        function item:getFullType() return self.fullType end
        function item:getModData() return itemModData end
        function item:setName(name) self.name = name end
        function item:getName() return self.name end
        table.insert(self.values, item)
        return item
    end

    local modData = {}
    return {
        modData = modData,
        inventory = inventory,
        getModData = function(self) return self.modData end,
        getInventory = function(self) return self.inventory end,
    }
end

PZLinuxGetPlayer = function(value) return value end

local function PZLinuxTestGiveItems(player, itemName, count)
    for _ = 1, count do
        player.inventory:AddItem(itemName)
    end
end

local function PZLinuxTestCountPackages(player)
    local count = 0
    for _, item in ipairs(player.inventory.values) do
        if item:getFullType() == "Base.SuspiciousPackage" and item:getModData().PZLinuxSellSaleAmount then
            count = count + 1
        end
    end
    return count
end

-- The catalog must flatten every item of every category except the vehicle
-- one (id 9), which must never be offered for sale.
local player = PZLinuxTestNewPlayer()
local offersDay0 = PZLinuxSellGetOffers(player, "offers-day0")
PZLinuxTestAssert(offersDay0.ok, "getting today's offers must succeed")
PZLinuxTestAssert(#offersDay0.offers == 2, "both mocked catalog items must roll wanted with the deterministic minimum roll")
local itemAOffer, itemBOffer
for _, offer in ipairs(offersDay0.offers) do
    if offer.name == "Base.ItemA" then itemAOffer = offer end
    if offer.name == "Base.ItemB" then itemBOffer = offer end
end
PZLinuxTestAssert(itemAOffer and itemBOffer, "every mocked item must appear in the offer list")
PZLinuxTestAssert(itemAOffer.quantity == 1, "the deterministic minimum roll must pick the minimum quantity (1)")
PZLinuxTestAssert(itemAOffer.greatDeal, "the deterministic minimum roll must pick a great deal (1 <= 10)")
local expectedUnitPrice = math.floor(1000 * 25 / 100)
PZLinuxTestAssert(itemAOffer.total == expectedUnitPrice * 1,
    "the quoted total must reflect the great-deal percentage times the wanted quantity")

-- A second refresh the same day must not reroll (same quantities/prices).
local offersDay0Again = PZLinuxSellGetOffers(player, "offers-day0-again")
local itemAOfferAgain
for _, offer in ipairs(offersDay0Again.offers) do
    if offer.name == "Base.ItemA" then itemAOfferAgain = offer end
end
PZLinuxTestAssert(itemAOfferAgain.total == itemAOffer.total, "the same day must not reroll a demanded item's price")

-- Selling without owning enough of the item must be refused.
local missingSale = PZLinuxSellApplySell(player, "Base.ItemA", "sell-missing")
PZLinuxTestAssert(not missingSale.ok and missingSale.error == "missing_items",
    "selling an item the player does not fully own must be refused")
PZLinuxTestAssert(creditCalls == 0, "a refused sale must never credit the player")

-- Gather exactly the demanded quantity and sell.
PZLinuxTestGiveItems(player, "Base.ItemA", itemAOffer.quantity)
local sale = PZLinuxSellApplySell(player, "Base.ItemA", "sell-ok")
PZLinuxTestAssert(sale.ok and sale.sold == itemAOffer.quantity and sale.total == itemAOffer.total,
    "a valid sale must remove exactly the demanded quantity for the demanded total")
PZLinuxTestAssert(#player.inventory.values == 1, "sold items must be removed from the inventory, replaced by one package")
PZLinuxTestAssert(PZLinuxTestCountPackages(player) == 1, "selling must create exactly one Sell Surplus package")
PZLinuxTestAssert(creditCalls == 0, "selling must not credit the bank directly -- only redeeming the package does")

-- The same item cannot be sold again today.
PZLinuxTestGiveItems(player, "Base.ItemA", 1)
local resaleAttempt = PZLinuxSellApplySell(player, "Base.ItemA", "sell-again")
PZLinuxTestAssert(not resaleAttempt.ok and resaleAttempt.error == "no_demand",
    "an already-sold item must not be sellable again the same day")

local offersAfterSale = PZLinuxSellGetOffers(player, "offers-after-sale")
local itemAStillListed = false
for _, offer in ipairs(offersAfterSale.offers) do
    if offer.name == "Base.ItemA" then itemAStillListed = true end
end
PZLinuxTestAssert(not itemAStillListed, "a sold item must disappear from the offer list for the rest of the day")

-- Redeeming the package at a mailbox is what actually pays the player.
local redeemed = PZLinuxSellApplyRedeemPackage(player, {}, "redeem-ok")
PZLinuxTestAssert(redeemed.ok and redeemed.sold == 1 and redeemed.total == sale.total,
    "redeeming at a mailbox must credit exactly the sale total")
PZLinuxTestAssert(creditCalls == 1 and lastCreditAmount == sale.total,
    "redeeming must credit the bank exactly once for the package amount")

-- Negotiation: force success (ZombRand always minimum, so 1 <= 50 succeeds),
-- raising the price by the configured increment.
local negotiated = PZLinuxSellNegotiate(player, "Base.ItemB", "negotiate-1")
PZLinuxTestAssert(negotiated.ok and not negotiated.withdrawn,
    "the deterministic minimum roll must always succeed a negotiation (1 <= 50)")
PZLinuxTestAssert(negotiated.total == itemBOffer.total + 100,
    "a successful negotiation must raise the total by the configured increment")

local offersAfterNegotiate = PZLinuxSellGetOffers(player, "offers-after-negotiate")
local itemBAfterNegotiate
for _, offer in ipairs(offersAfterNegotiate.offers) do
    if offer.name == "Base.ItemB" then itemBAfterNegotiate = offer end
end
PZLinuxTestAssert(itemBAfterNegotiate and itemBAfterNegotiate.total == negotiated.total,
    "the raised price must persist across subsequent offer refreshes")

-- Negotiation failure: force the roll to fail, the buyer must walk away and
-- the item must become unsellable for the rest of the day.
local savedZombRand = ZombRand
ZombRand = function(minimum, maximum)
    if maximum then return maximum end -- always rolls above the 50% success chance
    return minimum
end
local failedNegotiation = PZLinuxSellNegotiate(player, "Base.ItemB", "negotiate-fail")
PZLinuxTestAssert(failedNegotiation.ok and failedNegotiation.withdrawn,
    "a failed negotiation roll must make the buyer withdraw")
ZombRand = savedZombRand

local offersAfterWithdrawal = PZLinuxSellGetOffers(player, "offers-after-withdrawal")
local itemBStillListed = false
for _, offer in ipairs(offersAfterWithdrawal.offers) do
    if offer.name == "Base.ItemB" then itemBStillListed = true end
end
PZLinuxTestAssert(not itemBStillListed, "a withdrawn item must disappear from the offer list for the rest of the day")

PZLinuxTestGiveItems(player, "Base.ItemB", 10)
local sellAfterWithdrawal = PZLinuxSellApplySell(player, "Base.ItemB", "sell-after-withdrawal")
PZLinuxTestAssert(not sellAfterWithdrawal.ok and sellAfterWithdrawal.error == "no_demand",
    "a withdrawn item must not be sellable even if the player owns plenty")

-- The next game day rerolls everything, including sold/withdrawn items.
currentDay = 1
local offersNextDay = PZLinuxSellGetOffers(player, "offers-day1")
PZLinuxTestAssert(#offersNextDay.offers == 2, "the next game day must reroll every item fresh")

-- Base (non-great-deal) pricing path: queue specific rolls so the demand
-- check still succeeds while the separate great-deal roll fails (the queue
-- covers only the first item's rolls: wanted, quantity, great-deal-fails;
-- everything after falls back to the deterministic minimum, so the base
-- price percent resolves to the configured basePricePercentMin, 15).
local zombRandQueue = { 1, 1, 50 } -- item wanted, quantity = 1, great-deal roll fails (50 > 10)
ZombRand = function(minimum)
    if #zombRandQueue > 0 then return table.remove(zombRandQueue, 1) end
    return minimum
end
currentDay = 2
local basePlayer = PZLinuxTestNewPlayer()
local baseOffers = PZLinuxSellGetOffers(basePlayer, "offers-base")
PZLinuxTestAssert(#baseOffers.offers >= 1, "the queued rolls must still make at least one item wanted")
local baseOffer = baseOffers.offers[1]
PZLinuxTestAssert(not baseOffer.greatDeal, "rolling above the great-deal chance must fall back to the base (bad) price")
local expectedBasePrice = math.floor(1000 * 15 / 100)
PZLinuxTestAssert(baseOffer.total == expectedBasePrice * baseOffer.quantity,
    "the base price must fall within the configured base percentage range times the quantity")
ZombRand = savedZombRand

print("PZLinux Sell Surplus tests OK")
