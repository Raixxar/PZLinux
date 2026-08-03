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
    maxItemsPerSale = 6,
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
        local item = { fullType = fullType }
        function item:getFullType() return self.fullType end
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

-- getScriptManager()/getGameTime() are not used directly by the loaded Sell
-- block (day and price come from mocks above), only getGameTime is referenced
-- as a nil-safe fallback inside PZLinuxRequestsCurrentGameDay's real
-- implementation, which we replaced above, so no further mock is required.

-- 13 sellable categories (14 defined minus vehicle id 9).
local categoryCount = 0
for contractId in pairs(PZLinuxRequestDefinitions) do
    if tonumber(contractId) ~= 9 then categoryCount = categoryCount + 1 end
end
PZLinuxTestAssert(categoryCount == 13, "Sell Surplus must offer every Request category except the vehicle")

local player = PZLinuxTestNewPlayer()

-- First refresh of day 0 rolls the demand and locks it in for the day.
local refresh1 = PZLinuxSellRefreshDemand(player, "sell-refresh-1")
PZLinuxTestAssert(refresh1.ok and refresh1.available and refresh1.contractId == 1,
    "a fresh day must roll a demand (deterministic mock picks the lowest sellable category id)")
PZLinuxTestAssert(refresh1.contractId ~= 9, "the vehicle category must never be offered for sale")

-- A second refresh the same day must not reroll.
local refresh2 = PZLinuxSellRefreshDemand(player, "sell-refresh-2")
PZLinuxTestAssert(refresh2.available and refresh2.contractId == refresh1.contractId,
    "the demand must not reroll again within the same game day")

-- Quoting the wrong category must be refused.
local wrongCategory = PZLinuxSellRequestQuote(player, 2, { { name = "Base.Baloney" } }, "sell-quote-wrong")
PZLinuxTestAssert(not wrongCategory.ok and wrongCategory.error == "wrong_category",
    "a quote for a category other than today's demand must be refused")

-- Quoting with items that do not belong to the demanded category is rejected.
local definition1 = PZLinuxRequestDefinitions[1]
local invalidItems = PZLinuxSellRequestQuote(player, 1, { { name = "Base.NotARealItem" } }, "sell-quote-invalid")
PZLinuxTestAssert(not invalidItems.ok and invalidItems.error == "invalid_sell_items",
    "a quote with no valid items for the category must be refused")

-- A valid quote locks in the price immediately (deterministic mock: a "great
-- deal" at the cheapest end of its range, 110% of the reference price).
local firstItemName = definition1.items[1]
local quote = PZLinuxSellRequestQuote(player, 1, { { name = firstItemName }, { name = firstItemName } }, "sell-quote-ok")
PZLinuxTestAssert(quote.ok and quote.greatDeal and quote.count == 2,
    "a valid quote for the demanded category must succeed")
local expectedUnitPrice = math.floor(definition1.price * 110 / 100)
PZLinuxTestAssert(quote.total == expectedUnitPrice * 2,
    "the quoted total must reflect the great-deal percentage times the quantity")

-- The single daily opportunity is already spent, win or lose.
local secondQuoteSameDay = PZLinuxSellRequestQuote(player, 1, { { name = firstItemName } }, "sell-quote-again")
PZLinuxTestAssert(not secondQuoteSameDay.ok and secondQuoteSameDay.error == "no_demand_today",
    "requesting a second quote the same day must be refused even for the same category")

-- Dropping off without having the items must fail without consuming anything.
local missingDrop = PZLinuxSellApplyConfirmDrop(player, {}, "sell-drop-missing")
PZLinuxTestAssert(not missingDrop.ok and missingDrop.error == "missing_items",
    "confirming the drop without the promised items in inventory must be refused")
PZLinuxTestAssert(creditCalls == 0, "a missing-items drop must never credit the player")

-- Gather the promised items and confirm.
player.inventory:AddItem(firstItemName)
player.inventory:AddItem(firstItemName)
local confirmedDrop = PZLinuxSellApplyConfirmDrop(player, {}, "sell-drop-ok")
PZLinuxTestAssert(confirmedDrop.ok and confirmedDrop.sold == 2 and confirmedDrop.total == quote.total,
    "confirming the drop with the promised items must sell exactly that quantity")
PZLinuxTestAssert(creditCalls == 1 and lastCreditAmount == quote.total,
    "a confirmed drop must credit exactly the quoted total")
PZLinuxTestAssert(#player.inventory.values == 0, "sold items must be removed from the player's inventory")

-- Re-confirming with nothing pending is a harmless no-op.
local noPendingDrop = PZLinuxSellApplyConfirmDrop(player, {}, "sell-drop-none")
PZLinuxTestAssert(noPendingDrop.ok and noPendingDrop.sold == 0,
    "confirming a drop with no pending sale must be a harmless no-op")
PZLinuxTestAssert(creditCalls == 1, "a no-op drop confirmation must never credit the player again")

-- The next game day allows a fresh roll.
currentDay = 1
local nextDayRefresh = PZLinuxSellRefreshDemand(player, "sell-refresh-day2")
PZLinuxTestAssert(nextDayRefresh.available, "a new game day must roll a fresh demand")
local nextDayQuote = PZLinuxSellRequestQuote(
    player, nextDayRefresh.contractId, { { name = PZLinuxRequestDefinitions[nextDayRefresh.contractId].items[1] } },
    "sell-quote-day2"
)
PZLinuxTestAssert(nextDayQuote.ok, "the day's fresh demand must allow a new quote")

-- Base (non-great-deal) pricing path: queue specific rolls so the demand
-- check still succeeds while the separate great-deal roll fails.
local savedZombRand = ZombRand
local zombRandQueue = { 1, 1, 50 } -- demand available, category index 1, great-deal roll fails (50 > 10)
ZombRand = function(minimum)
    if #zombRandQueue > 0 then return table.remove(zombRandQueue, 1) end
    return minimum
end
currentDay = 2
local baseRefresh = PZLinuxSellRefreshDemand(player, "sell-refresh-base")
PZLinuxTestAssert(baseRefresh.available, "the queued roll must still make a demand available")
local baseDefinition = PZLinuxRequestDefinitions[baseRefresh.contractId]
local baseQuote = PZLinuxSellRequestQuote(
    player, baseRefresh.contractId, { { name = baseDefinition.items[1] } }, "sell-quote-base"
)
PZLinuxTestAssert(baseQuote.ok and not baseQuote.greatDeal,
    "rolling above the great-deal chance must fall back to the base (bad) price")
PZLinuxTestAssert(baseQuote.total == math.floor(baseDefinition.price * 50 / 100),
    "the base price must be exactly the configured percentage of the reference price")
ZombRand = savedZombRand

print("PZLinux Sell Surplus tests OK")
