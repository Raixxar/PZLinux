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
    PZLinuxOnItemBuyOnDarkWeb = {
        { { items = { { name = "Base.Axe" } } } },
    },
}
local player = {
    getInventory = function() return inventory end,
    getModData = function() return modData end,
}

PZLinux = {}
PZLinuxGetPlayer = function(value) return value end
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

dofile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")

local result = PZLinuxDarkWebApplyDeliverOrders(player, {}, "delivery-1")
PZLinuxTestAssert(result.ok and result.delivered == 1, "a valid pending order must be delivered")
PZLinuxTestAssert(#inventoryItems == 1 and inventoryItems[1].fullType == "Base.Parcel_Large", "the parcel must be placed in server inventory")
PZLinuxTestAssert(#nestedItems == 1 and nestedItems[1].fullType == "Base.Axe", "the purchased item must be inside the parcel")
PZLinuxTestAssert(#networkItems == 1 and networkItems[1] == inventoryItems[1], "the completed parcel must be synchronized to the client")
PZLinuxTestAssert(modData.PZLinuxOnItemBuyOnDarkWebStatus == 0 and #modData.PZLinuxOnItemBuyOnDarkWeb == 0,
    "the pending order must be cleared only after delivery")

inventory.failCreation = true
modData.PZLinuxOnItemBuyOnDarkWebStatus = 1
modData.PZLinuxOnItemBuyOnDarkWeb = {
    { { items = { { name = "Base.Axe" } } } },
}
result = PZLinuxDarkWebApplyDeliverOrders(player, {}, "delivery-2")
PZLinuxTestAssert(not result.ok and result.error == "parcel_creation_failed", "parcel creation failure must be reported")
PZLinuxTestAssert(modData.PZLinuxOnItemBuyOnDarkWebStatus == 1 and #modData.PZLinuxOnItemBuyOnDarkWeb == 1,
    "a failed delivery must preserve the pending order")

local variables = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
PZLinuxTestAssert(variables:find("sendAddItemToContainer%(playerObj:getInventory%(%), item%)"),
    "server-created inventory items must use the B42 inventory packet")

for _, uiPath in ipairs({
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
}) do
    local uiSource = PZLinuxTestRead(luaRoot .. uiPath)
    PZLinuxTestAssert(uiSource:find('result%.ok == false'), uiPath .. " must display delivery failures")
end

print("PZLinux Dark Web delivery tests OK")
