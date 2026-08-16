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
            local item = {
                fullType = itemType,
                getFullType = function(value) return value.fullType end,
            }
            table.insert(nestedContainer.items, item)
            return item
        end
        function nested:getItems()
            return {
                size = function() return #self.items end,
                get = function(_, index) return self.items[index + 1] end,
            }
        end
        local parcel = {
            fullType = fullType,
            modData = {},
            getFullType = function(value) return value.fullType end,
            getModData = function(value) return value.modData end,
            setName = function() end,
            getInventory = function() return nested end,
        }
        table.insert(self.items, parcel)
        return parcel
    end

    function inventory:getItems()
        return {
            size = function() return #self.items end,
            get = function(_, index) return self.items[index + 1] end,
        }
    end

    function inventory:Remove(item)
        for index = #self.items, 1, -1 do
            if self.items[index] == item then table.remove(self.items, index) end
        end
    end

    return inventory
end

local globalModData = {}

local function PZLinuxTestNewPlayer(options)
    globalModData = {}
    local inventory = PZLinuxTestNewInventory(options)
    local modData = {
        PZLinuxActiveRequest = 1,
        PZLinuxOnItemRequestQueue = "Base.Axe,Base.Hammer",
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
local queueDecodeBlock = runtimeSource:match("function PZLinuxRequestsQueueDecode.-\nend")
local queueEncodeBlock = runtimeSource:match("function PZLinuxRequestsQueueEncode.-\nend")
PZLinuxTestAssert(queueDecodeBlock and queueEncodeBlock, "Request queue encode/decode helpers must exist")

PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function() return "test-player" end
PZLinuxValidateMailboxInteraction = function() return {}, nil end
PZLinuxLoadBankBalance = function() return 1000 end
PZLinuxTransmitPlayerModData = function() end
PZLinuxDeliveryHasRoomForMoreParcels = function() return true end
PZLinuxDeliveryIsWithinWeightLimit = function() return true end
getGameTime = function() return { getWorldAgeHours = function() return 0 end } end
globalModData = {}
ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}
local stolenNoteCalls = {}
PZLinuxCreateStolenOrderNote = function(playerArg)
    table.insert(stolenNoteCalls, playerArg)
end
rawset(_G, "ZombRand", function() return 100 end)
assert(loadstring(queueDecodeBlock))()
assert(loadstring(queueEncodeBlock))()
assert(loadstring(PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxDeliveryQueue.lua")))()
function PZLinuxRequestsMigrateLegacyQueue(player)
    local record = PZLinuxDeliveryGetPlayerRecord(player)
    if tonumber(record.migrations.requests) ~= 1 then
        for index, batch in ipairs(PZLinuxRequestsQueueDecode(player:getModData().PZLinuxOnItemRequestQueue)) do
            local deliveryItems = {}
            for _, item in ipairs(batch.items) do
                table.insert(deliveryItems, { name = item.name, quantity = 1 })
            end
            PZLinuxDeliveryEnqueue(player, "request", deliveryItems, "legacy-request-" .. tostring(index))
        end
        record.migrations.requests = 1
    end
    local pending = PZLinuxDeliveryPendingCount(player, "request")
    player:getModData().PZLinuxActiveRequest = pending > 0 and 1 or 0
    player:getModData().PZLinuxOnItemRequestQueue = ""
    return pending
end
local function PZLinuxTestSyncRequestState(player)
    local pending = PZLinuxDeliveryPendingCount(player, "request")
    player:getModData().PZLinuxActiveRequest = pending > 0 and 1 or 0
    player:getModData().PZLinuxOnItemRequestQueue = ""
    return pending
end
PZLinuxRequestsSyncPendingState = PZLinuxTestSyncRequestState
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
PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 0 and player.modData.PZLinuxOnItemRequestQueue == "",
    "the pending Request order must clear only after synchronization")

for _, failure in ipairs({
    { options = { failParcel = true }, error = "parcel_creation_failed" },
    { options = { failItem = true }, error = "item_creation_failed" },
}) do
    player = PZLinuxTestNewPlayer(failure.options)
    result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-failure")
    PZLinuxTestAssert(not result.ok and result.error == failure.error, failure.error .. " must be reported")
    PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 1
        and PZLinuxDeliveryPendingCount(player, "request") == 1,
        failure.error .. " must preserve the paid pending order")
    PZLinuxTestAssert(#player.inventory.items == 0, failure.error .. " must not leave an empty parcel")
end

PZLinuxSyncAddedInventoryItem = function() return false end
player = PZLinuxTestNewPlayer()
result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-sync-failure")
PZLinuxTestAssert(not result.ok and result.error == "parcel_sync_failed", "network synchronization failure must be reported")
PZLinuxTestAssert(player.modData.PZLinuxActiveRequest == 1
    and PZLinuxDeliveryPendingCount(player, "request") == 1,
    "network synchronization failure must preserve the paid pending order")
PZLinuxTestAssert(#player.inventory.items == 0, "network synchronization failure must roll back the server parcel")

-- Same shared stolen-order note as Dark Web -- see test_darkweb_delivery.lua
-- for its half of this regression coverage.
rawset(_G, "ZombRand", function() return 1 end)
player = PZLinuxTestNewPlayer()
result = PZLinuxRequestsApplyDelivery(player, {}, "request-delivery-stolen")
PZLinuxTestAssert(result.ok and result.lost == true and result.delivered == 0, "a stolen Request order must report lost = true")
PZLinuxTestAssert(#stolenNoteCalls == 1, "a stolen Request order must create exactly one stolen-order note")
rawset(_G, "ZombRand", function() return 100 end)

for _, uiPath in ipairs({
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
}) do
    local uiSource = PZLinuxTestRead(luaRoot .. uiPath)
    PZLinuxTestAssert(uiSource:find('Request delivery failed:'), uiPath .. " must display Request delivery failures")
end

print("PZLinux Request delivery tests OK")
