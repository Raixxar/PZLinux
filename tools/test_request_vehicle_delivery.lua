-- luacheck: globals getCell getGameTime isServer IsoDirections ZombRand VehicleManager instanceItem addVehicleDebug

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_request_vehicle_delivery.lua$") or "."
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

local function PZLinuxTestList(values)
    local list = { values = values or {} }
    function list:size() return #self.values end
    function list:get(index) return self.values[index + 1] end
    function list:toArray()
        local array = {}
        for index, value in ipairs(self.values) do array[index] = value end
        return array
    end
    return list
end

local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local requestUiSource = PZLinuxTestRead(luaRoot .. "/client/Context/World/Features/PZLinuxRequest.lua")
local applyOrderStart = assert(source:find("function PZLinuxRequestsApplyOrder", 1, true))
local applyOrderEnd = assert(source:find("function PZLinuxRequestsApplyDelivery", applyOrderStart, true))
local applyOrderSource = source:sub(applyOrderStart, applyOrderEnd - 1)
local first = assert(source:find("function PZLinuxRequestsRealNowSeconds", 1, true))
local last = assert(source:find("function PZLinuxRequestOrder", first, true))
assert(loadstring(source:sub(first, last - 1)))()

PZLinuxTestAssert(applyOrderSource:find('error = "request_delivery_pending"', 1, true),
    "a pending vehicle delivery must not be overwritten by another Request order")
local pendingGuard = assert(applyOrderSource:find('error = "request_delivery_pending"', 1, true))
local bankDebit = assert(applyOrderSource:find("PZLinuxApplyBankDebit", 1, true))
PZLinuxTestAssert(pendingGuard < bankDebit, "conflicting Request orders must be rejected before bank debit")

local vehicles = PZLinuxTestList()
local square = {
    getX = function() return 100 end,
    getY = function() return 200 end,
    getZ = function() return 0 end,
    isFree = function() return true end,
}
local cell = {
    getVehicles = function() return vehicles end,
    getGridSquare = function() return square end,
}
getCell = function() return cell end
getGameTime = function()
    return { getWorldAgeHours = function() return 12 end }
end
isServer = function() return true end
IsoDirections = { S = 4 }
ZombRand = function(minimum) return minimum end
PZLinux = { Config = { Requests = {
    searchFailureChancePercent = 20,
    searchMinDelaySeconds = 10,
    searchMaxDelaySeconds = 90,
    searchCooldownHours = 24,
} } }

VehicleManager = { instance = {} }
function VehicleManager.instance.getVehicleByID(_manager, vehicleId)
    for index = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(index)
        if tonumber(vehicle:getId()) == tonumber(vehicleId) then return vehicle end
    end
    return nil
end
function VehicleManager.instance:serverUpdate()
    self.updateCount = (self.updateCount or 0) + 1
end

local inventory = { values = {} }
function inventory:getItems() return PZLinuxTestList(self.values) end
function inventory:AddItem(item)
    table.insert(self.values, item)
    return item
end
function inventory:Remove(item)
    for index = #self.values, 1, -1 do
        if self.values[index] == item then table.remove(self.values, index) end
    end
end

instanceItem = function()
    local key = { keyId = 0 }
    function key:setKeyId(value) self.keyId = value end
    function key:getKeyId() return self.keyId end
    function key:setName(value) self.name = value end
    return key
end

local modData = {
    PZLinuxOnItemRequestCar = 1,
    PZLinuxActiveRequest = 1,
    PZLinuxOnItemRequestCarName = "Base.CarNormal",
    PZLinuxRequestLocationX = 100,
    PZLinuxRequestLocationY = 200,
    PZLinuxRequestLocationZ = 0,
}
local player = {
    getModData = function() return modData end,
    getInventory = function() return inventory end,
}
PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function() return "vehicle-test-player" end
PZLinuxLoadBankBalance = function() return 100000 end
PZLinuxTransmitPlayerModData = function() end
PZLinuxSyncAddedInventoryItem = function() return true end
PZLinuxRemoveInventoryItem = function(_, item) inventory:Remove(item) end
PZLinuxIsPlayerNearPosition = function() return true end
PZLinuxRequestsGetDefinition = function()
    return { vehicles = { { baseName = "Base.CarNormal" } } }
end
PZLinuxRequestsContains = function(entries, baseName)
    for _, entry in ipairs(entries or {}) do
        if entry.baseName == baseName then return entry end
    end
    return nil
end
PZLinuxRequestsFindVehicleLocation = function(x, y, z)
    if tonumber(x) == 100 and tonumber(y) == 200 and tonumber(z) == 0 then
        return { x = 100, y = 200, z = 0 }
    end
    return nil
end

assert(loadstring(applyOrderSource))()
local debitCalls = 0
PZLinuxRequestsBuildOrder = function(_, state, requestId)
    return { ok = true, contractId = state.contractId, amount = 100, requestId = requestId }
end
PZLinuxApplyBankDebit = function()
    debitCalls = debitCalls + 1
    return { ok = true }
end
local creditCalls = 0
local lastCreditAmount = 0
PZLinuxApplyBankCredit = function(_, amount)
    creditCalls = creditCalls + 1
    lastCreditAmount = tonumber(amount) or 0
    return { ok = true, amount = lastCreditAmount }
end

local pendingVehiclePlayer = {
    getModData = function()
        return {
            PZLinuxOnItemRequestCar = 1,
            PZLinuxOnItemRequest = {},
            -- Matches the mocked getGameTime() world age (12h): a delivery
            -- ordered "now" is still fresh and must not be self-healed away.
            PZLinuxRequestVehicleOrderedHour = 12,
        }
    end,
}
local blockedItemOrder = PZLinuxRequestsApplyOrder(pendingVehiclePlayer, { contractId = 1 }, "blocked-item-order")
PZLinuxTestAssert(not blockedItemOrder.ok and blockedItemOrder.error == "request_delivery_pending",
    "an item Request must not overwrite a paid vehicle delivery")

local pendingItemPlayer = {
    getModData = function()
        return { PZLinuxOnItemRequestCar = 0, PZLinuxOnItemRequest = { { "paid-batch" } } }
    end,
}
local blockedVehicleOrder = PZLinuxRequestsApplyOrder(pendingItemPlayer, { contractId = 9 }, "blocked-vehicle-order")
PZLinuxTestAssert(not blockedVehicleOrder.ok and blockedVehicleOrder.error == "request_delivery_pending",
    "a vehicle Request must not overwrite paid item deliveries")
PZLinuxTestAssert(debitCalls == 0, "conflicting Request orders must never debit the player")

-- Never-spawned case: the player never got within range of the delivery
-- point, so no vehicle (and no key) was ever created. Self-healing must NOT
-- clear this even after the grace period, or the player would silently lose
-- the vehicle and key they already paid for with no way to ever collect them.
local neverSpawnedModData = {
    PZLinuxOnItemRequestCar = 1,
    PZLinuxOnItemRequest = {},
    PZLinuxRequestVehicleDeliveryId = "PZLinuxVehicle-never-spawned-1-1",
    PZLinuxRequestVehicleOrderedHour = 0,
}
local neverSpawnedPlayer = {
    getModData = function() return neverSpawnedModData end,
}
local neverSpawnedOrder = PZLinuxRequestsApplyOrder(neverSpawnedPlayer, { contractId = 1 }, "never-spawned-order")
PZLinuxTestAssert(not neverSpawnedOrder.ok and neverSpawnedOrder.error == "request_delivery_pending",
    "a vehicle delivery must stay pending, never silently cleared, until it was actually spawned")
PZLinuxTestAssert(neverSpawnedModData.PZLinuxOnItemRequestCar == 1
    and neverSpawnedModData.PZLinuxRequestVehicleDeliveryId == "PZLinuxVehicle-never-spawned-1-1",
    "a never-spawned delivery must keep its pending flags so the player can still collect it later")

-- Already-delivered case: the vehicle (and its key) were already created; only
-- the final visual-confirmation round-trip was lost. This is safe to heal.
local staleDeliveredVehicle = { id = 77, keyId = 55, data = { PZLinuxRequestVehicleDeliveryId = "PZLinuxVehicle-stale-1-1" } }
function staleDeliveredVehicle:getId() return self.id end
function staleDeliveredVehicle:getModData() return self.data end
table.insert(vehicles.values, staleDeliveredVehicle)

local staleVehicleModData = {
    PZLinuxOnItemRequestCar = 1,
    PZLinuxOnItemRequest = {},
    PZLinuxRequestVehicleDeliveryId = "PZLinuxVehicle-stale-1-1",
    -- Ordered well over the grace period ago (world age is mocked at 12h).
    PZLinuxRequestVehicleOrderedHour = 0,
}
local stalePendingVehiclePlayer = {
    getModData = function() return staleVehicleModData end,
}
local healedOrder = PZLinuxRequestsApplyOrder(stalePendingVehiclePlayer, { contractId = 1 }, "healed-item-order")
PZLinuxTestAssert(healedOrder.error ~= "request_delivery_pending",
    "a vehicle delivery stuck well past the grace period must self-heal once it was actually delivered")
PZLinuxTestAssert(staleVehicleModData.PZLinuxOnItemRequestCar == 0
    and staleVehicleModData.PZLinuxRequestVehicleDeliveryId == nil,
    "self-healing an already-delivered stale vehicle must clear its pending flags")

for index = #vehicles.values, 1, -1 do
    if vehicles.values[index] == staleDeliveredVehicle then table.remove(vehicles.values, index) end
end

local spawnedCount = 0
local nextVehicleId = -1
addVehicleDebug = function(scriptName)
    spawnedCount = spawnedCount + 1
    local vehicle = { id = nextVehicleId, keyId = 0, data = {}, scriptName = scriptName }
    function vehicle:getId() return self.id end
    function vehicle.getX(_vehicle) return 100 end
    function vehicle.getY(_vehicle) return 200 end
    function vehicle.getZ(_vehicle) return 0 end
    function vehicle:getModData() return self.data end
    function vehicle:setKeyId(value) self.keyId = value end
    function vehicle:getKeyId() return self.keyId end
    function vehicle:repair() self.repaired = true end
    function vehicle.isExistInTheWorld(_vehicle) return true end
    function vehicle:transmitModData() self.transmitted = true end
    function vehicle:updateParts() self.partsUpdated = true end
    table.insert(vehicles.values, vehicle)
    return vehicle
end

modData.PZLinuxOnItemRequestCarName = "Base.InvalidVehicle"
local invalidVehicle = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-invalid-script")
PZLinuxTestAssert(not invalidVehicle.ok and invalidVehicle.error == "invalid_pending_vehicle",
    "the server must revalidate the persisted vehicle script")
PZLinuxTestAssert(spawnedCount == 0, "an invalid persisted script must not create a vehicle")
modData.PZLinuxOnItemRequestCarName = "Base.CarNormal"

modData.PZLinuxRequestLocationX = 999
local invalidLocation = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-invalid-location")
PZLinuxTestAssert(not invalidLocation.ok and invalidLocation.error == "missing_vehicle_location",
    "the server must revalidate the persisted pickup location")
PZLinuxTestAssert(spawnedCount == 0, "an invalid persisted location must not create a vehicle")
modData.PZLinuxRequestLocationX = 100

local networkPending = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-spawn-network-pending")
PZLinuxTestAssert(not networkPending.ok and networkPending.error == "vehicle_not_networked" and networkPending.retry,
    "an unregistered MP vehicle must remain pending")
PZLinuxTestAssert(spawnedCount == 1 and #vehicles.values == 1, "the server must create exactly one vehicle")
PZLinuxTestAssert(#inventory.values == 1, "the vehicle must have exactly one synchronized key")
PZLinuxTestAssert(modData.PZLinuxOnItemRequestCar == 1,
    "the paid request must remain pending until client visibility is confirmed")
PZLinuxTestAssert(vehicles.values[1].data.PZLinuxRequestVehicleDeliveryId == networkPending.deliveryId,
    "the spawned vehicle must carry its persistent delivery id")

vehicles.values[1].id = 42
local result = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-spawn-registered")
PZLinuxTestAssert(result.ok and result.existing and result.vehicleId == 42,
    "a retry must recover the vehicle after its network registration")
PZLinuxTestAssert(spawnedCount == 1 and #vehicles.values == 1, "a retry must not duplicate the vehicle")
PZLinuxTestAssert(#inventory.values == 1, "a retry must not duplicate the vehicle key")

local retry = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-spawn-2")
PZLinuxTestAssert(retry.ok and retry.existing, "later retries must keep recovering the tagged server vehicle")
PZLinuxTestAssert(spawnedCount == 1 and #vehicles.values == 1, "later retries must not duplicate the vehicle")

local emptyDelivery = PZLinuxRequestsApplyConfirmVehicle(player, "", result.vehicleId, "vehicle-confirm-empty")
PZLinuxTestAssert(not emptyDelivery.ok and emptyDelivery.error == "invalid_vehicle_delivery",
    "an empty delivery id must never complete a vehicle request")

local forged = PZLinuxRequestsApplyConfirmVehicle(player, result.deliveryId, 999, "vehicle-confirm-forged")
PZLinuxTestAssert(not forged.ok and modData.PZLinuxOnItemRequestCar == 1,
    "a forged vehicle id must not consume the paid request")

local confirmed = PZLinuxRequestsApplyConfirmVehicle(player, result.deliveryId, result.vehicleId, "vehicle-confirm-ok")
PZLinuxTestAssert(confirmed.ok and confirmed.confirmed, "the visible canonical vehicle must be confirmable")
PZLinuxTestAssert(modData.PZLinuxOnItemRequestCar == 0 and modData.PZLinuxActiveRequest == 0,
    "validated client visibility must complete the vehicle delivery")

local vehicleSelectionStart = assert(requestUiSource:find("if contract == 9 then", 1, true))
local vehicleSelectionEnd = assert(requestUiSource:find("PZLinuxOnItemRequest = {}", vehicleSelectionStart, true))
local vehicleSelection = requestUiSource:sub(vehicleSelectionStart, vehicleSelectionEnd)
PZLinuxTestAssert(vehicleSelection:find("itemCount = 1", 1, true),
    "a vehicle Request offer must contain exactly one vehicle")

-- Supplier search: an item Request rolls its outcome immediately but only
-- reveals it (and, on failure, refunds and applies a per-item cooldown) once
-- the random delay has passed.
local searchModData = { PZLinuxOnItemRequestCar = 0, PZLinuxOnItemRequest = {} }
local searchPlayer = { getModData = function() return searchModData end }

local ammoOrder = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 2 }, "search-order-1")
PZLinuxTestAssert(ammoOrder.ok and ammoOrder.searching
    and type(ammoOrder.revealDelaySeconds) == "number",
    "an item Request must start a supplier search instead of an instant delivery")
PZLinuxTestAssert(searchModData.PZLinuxRequestSearchPending == 1
    and searchModData.PZLinuxRequestSearchContractId == 2,
    "the search outcome must be tracked in the player's own modData")

local tooSoon = PZLinuxRequestsResolveSearch(searchPlayer, "search-resolve-too-soon")
PZLinuxTestAssert(tooSoon.ok and not tooSoon.resolved and tooSoon.pending,
    "the search must not resolve before its random delay has elapsed")

-- Force the reveal time into the past to simulate the delay having elapsed.
searchModData.PZLinuxRequestSearchRevealAt = PZLinuxRequestsRealNowSeconds() - 1
local resolved = PZLinuxRequestsResolveSearch(searchPlayer, "search-resolve-due")
PZLinuxTestAssert(resolved.ok and resolved.resolved and resolved.found == false,
    "the mocked ZombRand always rolls the minimum, so the search must resolve as failed")
PZLinuxTestAssert(creditCalls == 1 and lastCreditAmount == 100,
    "a failed search must fully refund the paid amount")
PZLinuxTestAssert(searchModData.PZLinuxActiveRequest == 0 and #searchModData.PZLinuxOnItemRequest == 0,
    "a failed search must clear the pending item delivery")
PZLinuxTestAssert(type(searchModData.PZLinuxRequestSearchCooldowns) == "table"
    and searchModData.PZLinuxRequestSearchCooldowns["2"] ~= nil,
    "a failed search must apply a per-item-type cooldown")

local blockedByCooldown = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 2 }, "search-order-blocked")
PZLinuxTestAssert(not blockedByCooldown.ok and blockedByCooldown.error == "supplier_cooldown",
    "the same item type must be refused while its supplier cooldown is active")

local otherItemStillWorks = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 3 }, "search-order-other")
PZLinuxTestAssert(otherItemStillWorks.ok,
    "the supplier cooldown must be scoped to the specific item type, not the whole player")

print("PZLinux Request vehicle delivery tests OK")
