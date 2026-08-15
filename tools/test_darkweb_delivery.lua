local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_delivery.lua$") or "."
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

local nestedItems = {}
local networkItems = {}
local inventoryItems = {}
local inventory = {}

function inventory:AddItem(itemType)
    if self.failCreation then return nil end
    local parcelInventory = {
        AddItem = function(_, nestedType)
            local item = { fullType = nestedType }
            table.insert(nestedItems, item)
            return item
        end,
    }
    local parcel = {
        fullType = itemType,
        getInventory = function() return parcelInventory end,
    }
    table.insert(inventoryItems, parcel)
    return parcel
end

function inventory:Remove(item)
    for index = #inventoryItems, 1, -1 do
        if inventoryItems[index] == item then table.remove(inventoryItems, index) end
    end
end

local modData = {
    PZLinuxOnItemBuyOnDarkWebStatus = 1,
    PZLinuxOnItemBuyOnDarkWebQueue = "Base.Axe|1",
}
local player = {
    getInventory = function() return inventory end,
    getModData = function() return modData end,
}

PZLinux = {}
PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function() return "test-player" end
PZLinuxValidateMailboxInteraction = function() return {}, nil end
PZLinuxLoadBankBalance = function() return 1000 end
PZLinuxTransmitPlayerModData = function() end
PZLinuxSyncAddedInventoryItem = function(_, item)
    table.insert(networkItems, item)
    return true
end
ZombRand = function() return 100 end
getScriptManager = function()
    return { FindItem = function(_, itemType) return itemType == "Base.Axe" end }
end

local stolenNoteCalls = {}
PZLinuxCreateStolenOrderNote = function(playerArg)
    table.insert(stolenNoteCalls, playerArg)
end

dofile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")

local result = PZLinuxDarkWebApplyDeliverOrders(player, {}, "delivery-1")
PZLinuxTestAssert(result.ok and result.delivered == 1, "a valid pending order must be delivered")
PZLinuxTestAssert(#inventoryItems == 1 and inventoryItems[1].fullType == "Base.Parcel_Large", "the parcel must be placed in server inventory")
PZLinuxTestAssert(#nestedItems == 1 and nestedItems[1].fullType == "Base.Axe", "the purchased item must be inside the parcel")
PZLinuxTestAssert(#networkItems == 1 and networkItems[1] == inventoryItems[1], "the completed parcel must be synchronized to the client")
PZLinuxTestAssert(modData.PZLinuxOnItemBuyOnDarkWebStatus == 0 and modData.PZLinuxOnItemBuyOnDarkWebQueue == "",
    "the pending order must be cleared only after delivery")

inventory.failCreation = true
modData.PZLinuxOnItemBuyOnDarkWebStatus = 1
modData.PZLinuxOnItemBuyOnDarkWebQueue = "Base.Axe|1"
result = PZLinuxDarkWebApplyDeliverOrders(player, {}, "delivery-2")
PZLinuxTestAssert(not result.ok and result.error == "parcel_creation_failed", "parcel creation failure must be reported")
PZLinuxTestAssert(modData.PZLinuxOnItemBuyOnDarkWebStatus == 1 and modData.PZLinuxOnItemBuyOnDarkWebQueue == "Base.Axe|1",
    "a failed delivery must preserve the pending order")

-- A player reported being confused when a Dark Web order simply never
-- arrived: the 10% theft roll wiped the queue with only an easy-to-miss
-- HaloText bubble as feedback. A stolen order must now also leave a
-- findable note in the player's inventory (PZLinuxCreateStolenOrderNote,
-- shared with Buy Goods -- see test_request_delivery.lua for its half).
modData.PZLinuxOnItemBuyOnDarkWebStatus = 1
modData.PZLinuxOnItemBuyOnDarkWebQueue = "Base.Axe|1"
ZombRand = function() return 1 end
result = PZLinuxDarkWebApplyDeliverOrders(player, {}, "delivery-stolen")
PZLinuxTestAssert(result.ok and result.lost == true and result.delivered == 0, "a stolen order must report lost = true")
PZLinuxTestAssert(#stolenNoteCalls == 1, "a stolen Dark Web order must create exactly one stolen-order note")
ZombRand = function() return 100 end

local variables = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
PZLinuxTestAssert(variables:find("sendAddItemToContainer%(container, item%)"),
    "server-created inventory items must use the B42 container packet")
PZLinuxTestAssert(variables:find("PZLinuxSyncAddedContainerItem%(playerObj:getInventory%(%), item%)"),
    "player inventory synchronization must delegate to the container packet helper")

for _, uiPath in ipairs({
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
}) do
    local uiSource = PZLinuxTestRead(luaRoot .. uiPath)
    PZLinuxTestAssert(uiSource:find('result%.ok == false'), uiPath .. " must display delivery failures")
end

-- Redeeming at a mailbox must never touch a Sell Surplus package (also a
-- "Base.SuspiciousPackage", tagged with PZLinuxSellSaleAmount instead of
-- PZLinuxDarkWebSaleAmount) -- this used to crash entirely, since the
-- name-parsing fallback passed both of string.gsub's return values straight
-- into tonumber(string, base), treating the substitution count as an
-- invalid numeric base.
local function PZLinuxTestList(values)
    local list = { values = values or {} }
    function list:size() return #self.values end
    function list:get(index) return self.values[index + 1] end
    return list
end

local function PZLinuxTestMakePackage(fullType, name, packageModData)
    local item = { fullType = fullType, name = name, modData = packageModData or {} }
    function item:getFullType() return self.fullType end
    function item:getName() return self.name end
    function item:getModData() return self.modData end
    return item
end

local redeemInventoryValues = {
    PZLinuxTestMakePackage("Base.SuspiciousPackage", "$500", { PZLinuxDarkWebSaleAmount = 500 }),
    PZLinuxTestMakePackage("Base.SuspiciousPackage", "$1250", { PZLinuxSellSaleAmount = 1250 }),
    PZLinuxTestMakePackage("Base.SuspiciousPackage", "$750"), -- legacy package, no modData marker at all
}
local removedPackages = {}
local redeemInventory = {
    getItems = function() return PZLinuxTestList(redeemInventoryValues) end,
}
local redeemPlayer = {
    getInventory = function() return redeemInventory end,
    getModData = function() return {} end,
}
PZLinuxRemoveInventoryItem = function(_, item)
    table.insert(removedPackages, item)
    for index = #redeemInventoryValues, 1, -1 do
        if redeemInventoryValues[index] == item then table.remove(redeemInventoryValues, index) end
    end
end
PZLinuxNormalizeMoney = function(amount) return math.floor(tonumber(amount) or 0) end
local creditedAmount, creditCallCount = nil, 0
PZLinuxApplyBankCredit = function(_, amount)
    creditCallCount = creditCallCount + 1
    creditedAmount = amount
    return { ok = true, balance = 1000 + amount }
end

local redeemResult = PZLinuxDarkWebApplyRedeemSales(redeemPlayer, {}, "redeem-mixed")
PZLinuxTestAssert(redeemResult.ok, "redeeming must not crash when a Sell Surplus package is present")
PZLinuxTestAssert(redeemResult.redeemed == 2,
    "only the two Dark Web packages must be redeemed, not the Sell Surplus one")
PZLinuxTestAssert(creditCallCount == 1 and creditedAmount == 1250,
    "the credited amount must be exactly the sum of the two Dark Web packages (500 + 750), skipping the Sell Surplus one")
PZLinuxTestAssert(#redeemInventoryValues == 1
    and redeemInventoryValues[1]:getModData().PZLinuxSellSaleAmount == 1250,
    "the Sell Surplus package must remain in the inventory, untouched, for its own redeem function to handle")

print("PZLinux Dark Web delivery tests OK")
