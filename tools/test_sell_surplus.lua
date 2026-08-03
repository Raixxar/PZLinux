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

-- Real category catalog (13 sellable categories + the vehicle one at id 9,
-- which Sell Surplus must never offer).
local requestsData = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxRequestsData.lua")
assert(loadstring(requestsData))()

local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local first = assert(source:find("-- Sell Surplus: the inverse of Requests", 1, true))
local last = assert(source:find("function PZLinuxRequestsFindDeliveredVehicle", first, true))
assert(loadstring(source:sub(first, last - 1)))()

PZLinuxRequestsGetDefinition = function(contractId)
    return PZLinuxRequestDefinitions[tonumber(contractId)]
end
PZLinuxRequestsContains = function(entries, baseName)
    for _, entry in ipairs(entries or {}) do
        local value = type(entry) == "table" and entry.baseName or entry
        if value == baseName then return entry end
    end
    return nil
end

PZLinux = { Config = { Sell = {
    demandChancePercent = 15,
    basePricePercent = 50,
    greatDealChancePercent = 10,
    greatDealMinPercent = 110,
    greatDealMaxPercent = 130,
} } }

local currentDay = 0
PZLinuxRequestsCurrentGameDay = function() return currentDay end

-- Deterministic: ZombRand(min[, max]) always returns min. Combined with the
-- config above, this always rolls "demand available", "great deal" and picks
-- the lowest-numbered category and the cheapest end of the great-deal range.
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
PZLinuxRemoveInventoryItem = function(player, item) player:getInventory():Remove(item) return true end

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

-- Adds `count` items of `itemName` directly into the player's main inventory,
-- mirroring what "must be in the main inventory, like Dark Web" requires.
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

-- 13 sellable categories (14 defined minus vehicle id 9).
local categoryCount = 0
for contractId in pairs(PZLinuxRequestDefinitions) do
    if tonumber(contractId) ~= 9 then categoryCount = categoryCount + 1 end
end
PZLinuxTestAssert(categoryCount == 13, "Sell Surplus must offer every Request category except the vehicle")

local player = PZLinuxTestNewPlayer()
local definition1 = PZLinuxRequestDefinitions[1]
local itemA, itemB = definition1.items[1], definition1.items[2]

-- First refresh of day 0 rolls the demand and locks it in for the day.
local refresh1 = PZLinuxSellRefreshDemand(player, "sell-refresh-1")
PZLinuxTestAssert(refresh1.ok and refresh1.available and refresh1.contractId == 1,
    "a fresh day must roll a demand (deterministic mock picks the lowest sellable category id)")
PZLinuxTestAssert(refresh1.contractId ~= 9, "the vehicle category must never be offered for sale")

-- A second refresh the same day must not reroll.
local refresh2 = PZLinuxSellRefreshDemand(player, "sell-refresh-2")
PZLinuxTestAssert(refresh2.available and refresh2.contractId == refresh1.contractId,
    "the demand must not reroll again within the same game day")

-- Quoting the wrong category must be refused, and must not burn the day.
local wrongCategory = PZLinuxSellRequestQuote(player, 2, { itemA }, "sell-quote-wrong")
PZLinuxTestAssert(not wrongCategory.ok and wrongCategory.error == "wrong_category",
    "a quote for a category other than today's demand must be refused")

-- Quoting items the player does not physically own must be refused and must
-- not consume the day's opportunity, since nothing was actually gathered yet.
local notOwned = PZLinuxSellRequestQuote(player, 1, { itemA }, "sell-quote-not-owned")
PZLinuxTestAssert(not notOwned.ok and notOwned.error == "invalid_sell_items",
    "a quote for items not present in the main inventory must be refused")

-- Quoting with items that do not belong to the demanded category is rejected.
local invalidItems = PZLinuxSellRequestQuote(player, 1, { "Base.NotARealItem" }, "sell-quote-invalid")
PZLinuxTestAssert(not invalidItems.ok and invalidItems.error == "invalid_sell_items",
    "a quote with no valid items for the category must be refused")

-- Gather two of itemA and one of itemB, then request a valid quote covering
-- both -- the quantity sold is whatever is actually owned, not a manual pick.
PZLinuxTestGiveItems(player, itemA, 2)
PZLinuxTestGiveItems(player, itemB, 1)
local quote = PZLinuxSellRequestQuote(player, 1, { itemA, itemB }, "sell-quote-ok")
PZLinuxTestAssert(quote.ok and quote.greatDeal and quote.count == 3,
    "a valid quote must sell every owned unit of every selected item type (2 + 1 = 3)")
local expectedUnitPrice = math.floor(definition1.price * 110 / 100)
PZLinuxTestAssert(quote.total == expectedUnitPrice * 3,
    "the quoted total must reflect the great-deal percentage times the owned quantity")
PZLinuxTestAssert(#player.inventory.values == 3, "items must remain in inventory until the offer is accepted")

-- The single daily opportunity is already spent, win or lose, the moment a
-- quote is issued -- even before the player accepts or cancels it.
local secondQuoteSameDay = PZLinuxSellRequestQuote(player, 1, { itemA }, "sell-quote-again")
PZLinuxTestAssert(not secondQuoteSameDay.ok and secondQuoteSameDay.error == "no_demand_today",
    "requesting a second quote the same day must be refused even for the same category")

-- Accepting removes exactly the promised items and hands over one priced
-- package, Dark Web style; nothing is credited to the bank yet.
local accepted = PZLinuxSellAcceptOffer(player, "sell-accept-ok")
PZLinuxTestAssert(accepted.ok and accepted.sold == 3 and accepted.total == quote.total,
    "accepting a valid offer must remove exactly the quoted quantity")
PZLinuxTestAssert(creditCalls == 0, "accepting an offer must not credit the bank directly")
PZLinuxTestAssert(#player.inventory.values == 1, "sold items must be removed from the inventory, replaced by one package")
PZLinuxTestAssert(PZLinuxTestCountPackages(player) == 1, "accepting must create exactly one Sell Surplus package")

-- Redeeming the package at a mailbox is what actually pays the player.
local redeemed = PZLinuxSellApplyRedeemPackage(player, {}, "sell-redeem-ok")
PZLinuxTestAssert(redeemed.ok and redeemed.sold == 1 and redeemed.total == quote.total,
    "redeeming at a mailbox must credit exactly the quoted total")
PZLinuxTestAssert(creditCalls == 1 and lastCreditAmount == quote.total,
    "redeeming must credit the bank exactly once for the package amount")
PZLinuxTestAssert(#player.inventory.values == 0, "the package must be removed once redeemed")

-- Redeeming again with nothing pending is a harmless no-op.
local noPendingRedeem = PZLinuxSellApplyRedeemPackage(player, {}, "sell-redeem-none")
PZLinuxTestAssert(noPendingRedeem.ok and noPendingRedeem.sold == 0, "redeeming with no package must be a harmless no-op")
PZLinuxTestAssert(creditCalls == 1, "a no-op redemption must never credit the player again")

-- The next game day allows a fresh roll.
currentDay = 1
local nextDayRefresh = PZLinuxSellRefreshDemand(player, "sell-refresh-day2")
PZLinuxTestAssert(nextDayRefresh.available, "a new game day must roll a fresh demand")
local nextDayDefinition = PZLinuxRequestDefinitions[nextDayRefresh.contractId]
PZLinuxTestGiveItems(player, nextDayDefinition.items[1], 1)
local nextDayQuote = PZLinuxSellRequestQuote(player, nextDayRefresh.contractId, { nextDayDefinition.items[1] }, "sell-quote-day2")
PZLinuxTestAssert(nextDayQuote.ok, "the day's fresh demand must allow a new quote")

-- Cancelling a locked-in offer never refunds the day: like a failed Request
-- supplier search, the roll already happened, so the player must wait.
local cancelled = PZLinuxSellCancelOffer(player, "sell-cancel-ok")
PZLinuxTestAssert(cancelled.ok, "cancelling a pending offer must succeed")
PZLinuxTestAssert(#player.inventory.values == 1, "cancelling must never touch the player's inventory")
local afterCancelQuote = PZLinuxSellRequestQuote(player, nextDayRefresh.contractId, { nextDayDefinition.items[1] }, "sell-quote-after-cancel")
PZLinuxTestAssert(not afterCancelQuote.ok and afterCancelQuote.error == "no_demand_today",
    "cancelling must not refund today's already-spent opportunity")

-- Accepting when items were spent/lost between quote and accept must fail
-- without creating a package, but must not crash or corrupt state. A fresh
-- player avoids any leftover inventory from the earlier scenarios above.
currentDay = 2
local missingPlayer = PZLinuxTestNewPlayer()
local missingRefresh = PZLinuxSellRefreshDemand(missingPlayer, "sell-refresh-missing")
local missingDefinition = PZLinuxRequestDefinitions[missingRefresh.contractId]
PZLinuxTestGiveItems(missingPlayer, missingDefinition.items[1], 1)
local missingQuote = PZLinuxSellRequestQuote(missingPlayer, missingRefresh.contractId, { missingDefinition.items[1] }, "sell-quote-missing")
PZLinuxTestAssert(missingQuote.ok, "the quote must succeed while the item is still present")
missingPlayer.inventory:Remove(missingPlayer.inventory.values[#missingPlayer.inventory.values])
local missingAccept = PZLinuxSellAcceptOffer(missingPlayer, "sell-accept-missing")
PZLinuxTestAssert(not missingAccept.ok and missingAccept.error == "missing_items",
    "accepting must be refused if the promised items are no longer in the inventory")
PZLinuxTestAssert(PZLinuxTestCountPackages(missingPlayer) == 0, "a failed acceptance must never create a package")

-- Base (non-great-deal) pricing path: queue specific rolls so the demand
-- check still succeeds while the separate great-deal roll fails. Another
-- fresh player keeps this scenario's owned quantity exactly 1.
local savedZombRand = ZombRand
local zombRandQueue = { 1, 1, 50 } -- demand available, category index 1, great-deal roll fails (50 > 10)
ZombRand = function(minimum)
    if #zombRandQueue > 0 then return table.remove(zombRandQueue, 1) end
    return minimum
end
currentDay = 3
local basePlayer = PZLinuxTestNewPlayer()
local baseRefresh = PZLinuxSellRefreshDemand(basePlayer, "sell-refresh-base")
PZLinuxTestAssert(baseRefresh.available, "the queued roll must still make a demand available")
local baseDefinition = PZLinuxRequestDefinitions[baseRefresh.contractId]
PZLinuxTestGiveItems(basePlayer, baseDefinition.items[1], 1)
local baseQuote = PZLinuxSellRequestQuote(basePlayer, baseRefresh.contractId, { baseDefinition.items[1] }, "sell-quote-base")
PZLinuxTestAssert(baseQuote.ok and not baseQuote.greatDeal,
    "rolling above the great-deal chance must fall back to the base (bad) price")
PZLinuxTestAssert(baseQuote.total == math.floor(baseDefinition.price * 50 / 100),
    "the base price must be exactly the configured percentage of the reference price")
ZombRand = savedZombRand

print("PZLinux Sell Surplus tests OK")
