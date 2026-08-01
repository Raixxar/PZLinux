local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_request_delivery.lua$") or "."
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

local function PZLinuxTestNewInventory(options)
    local inventory = { items = {}, options = options or {} }

    function inventory:AddItem(fullType)
        if self.options.failParcel then return nil end
        local nested = { items = {} }
        function nested.AddItem(nestedContainer, itemType)
            if inventory.options.failItem then return nil end
            local item = { fullType = itemType }
            table.insert(nestedContainer.items, item)
            return item
        end
        local parcel = {
            fullType = fullType,
            getInventory = function() return nested end,
        }
        table.insert(self.items, parcel)
        return parcel
    end

    function inventory:Remove(item)
        for index = #self.items, 1, -1 do
            if self.items[index] == item then table.remove(self.items, index) end
        end
    end

    return inventory
end

local function PZLinuxTestNewPlayer(options)
    local inventory = PZLinuxTestNewInventory(options)
    local modData = {
        PZLinuxActiveRequest = 1,
        PZLinuxOnItemRequest = {
            { { items = { { name = "Base.Axe" }, { name = "Base.Hammer" } } } },
        },
    }
    return {
        inventory = inventory,
        modData = modData,
        getInventory = function(self) return self.inventory end,
        getModData = function(self) return self.modData end,
    }
end

local runtimeSource = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local deliveryBlock = runtimeSource:match("function PZLinuxRequestsApplyDelivery.-\nend")
PZLinuxTestAssert(deliveryBlock, "Request delivery handler must exist")

PZLinuxGetPlayer = function(value) return value end
PZLinuxValidateMailboxInteraction = function() return {}, nil end
PZLinuxLoadBankBalance = function() return 1000 end
PZLinuxTransmitPlayerModData = function() end
rawset(_G, "ZombRand", function() return 100 end)
assert(loadstring(deliveryBlock))()

local synchronized = {}
PZLinuxSyncAddedInventoryItem = function(_, item)
    table.insert(synchronized, item)
    return true
end

local player = PZLinuxTestNewPlayer()
local result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-1")
PZLinuxTestAssert(result.ok and result.delivered == 2, "a valid Request order must be delivered")
PZLinuxTestAssert(#player.inventory.items == 1, "the completed parcel must remain in server inventory")
PZLinuxTestAssert(#player.inventory.items[1]:getInventory().items == 2, "all requested items must be inside the parcel")
PZLinuxTestAssert(#synchronized == 1 and synchronized[1] == player.inventory.items[1],
    "the completed parcel must be synchronized to the owning client")
PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 0 and #player.modData.PZLinuxOnItemRequest == 0,
    "the pending Request order must clear only after synchronization")

for _, failure in ipairs({
    { options = { failParcel = true }, error = "parcel_creation_failed" },
    { options = { failItem = true }, error = "item_creation_failed" },
}) do
    player = PZLinuxTestNewPlayer(failure.options)
    result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-failure")
    PZLinuxTestAssert(not result.ok and result.error == failure.error, failure.error .. " must be reported")
    PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 1 and #player.modData.PZLinuxOnItemRequest == 1,
        failure.error .. " must preserve the paid pending order")
    PZLinuxTestAssert(#player.inventory.items == 0, failure.error .. " must not leave an empty parcel")
end

PZLinuxSyncAddedInventoryItem = function() return false end
player = PZLinuxTestNewPlayer()
result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-sync-failure")
PZLinuxTestAssert(not result.ok and result.error == "parcel_sync_failed", "network synchronization failure must be reported")
PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 1 and #player.modData.PZLinuxOnItemRequest == 1,
    "network synchronization failure must preserve the paid pending order")
PZLinuxTestAssert(#player.inventory.items == 0, "network synchronization failure must roll back the server parcel")

for _, uiPath in ipairs({
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
}) do
    local uiSource = PZLinuxTestRead(luaRoot .. uiPath)
    PZLinuxTestAssert(uiSource:find('Request delivery failed:'), uiPath .. " must display Request delivery failures")
end

print("PZLinux Request delivery tests OK")
