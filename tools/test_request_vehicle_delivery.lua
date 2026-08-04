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
local first = assert(source:find("function PZLinuxRequestsCurrentGameDay", 1, true))
local last = assert(source:find("function PZLinuxRequestOrder", first, true))

-- Lightweight catalog for the category-availability roll (PZLinuxRequestsAllCategoryIds
-- iterates over this), independent of the real 13-category data file.
PZLinuxRequestDefinitions = {
    [1] = { baseName = "Canned food" },
    [2] = { baseName = "Meat" },
    [3] = { baseName = "Fish" },
    [9] = { baseName = "Car" },
}

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
-- Mutable so the trailing category-availability tests can simulate the next
-- game day without disturbing the vehicle tests above, which assume a fixed
-- 12h world age throughout.
local worldAgeHours = 12
getGameTime = function()
    return { getWorldAgeHours = function() return worldAgeHours end }
end
isServer = function() return true end
IsoDirections = { S = 4 }
ZombRand = function(minimum) return minimum end
PZLinux = { Config = { Requests = {
    unavailableChancePercentStart = 50,
    unavailableChancePercentMax = 75,
    unavailableRampGameDays = 180,
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

-- Note: applyOrderSource is used only for the static text-position
-- assertions above; PZLinuxRequestsApplyOrder itself was already loaded by
-- the bigger slice above (with access to its local helper upvalues such as
-- PZLinuxRequestsMarkCategoryConsumed). Re-loading this smaller slice as its
-- own separate chunk would redefine the global with a copy that cannot see
-- those local helpers at all, since Lua locals are chunk-scoped.
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

-- Category availability: each of the 4 mocked categories independently rolls
-- once per game day whether a seller exists at all. With the mocked ZombRand
-- always returning the minimum, every category rolls available by default
-- (day 0's chance is the configured 50% start, and 1 <= 50).
local searchModData = { PZLinuxOnItemRequestCar = 0, PZLinuxOnItemRequest = {} }
local searchPlayer = { getModData = function() return searchModData end }

local categoriesDay0 = PZLinuxRequestsGetAvailableCategories(searchPlayer, "categories-day0")
PZLinuxTestAssert(categoriesDay0.ok and #categoriesDay0.available == 4,
    "every mocked category must be available today with the deterministic minimum roll")

local ammoOrder = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 2 }, "order-1")
PZLinuxTestAssert(ammoOrder.ok, "an order for an available category must succeed directly")
PZLinuxTestAssert(ammoOrder.searching == nil,
    "item Requests no longer go through a delayed supplier search reveal")

-- A successful purchase must also consume the category for today: the same
-- seller doesn't have infinite stock to sell twice in one day.
local categoriesAfterPurchase = PZLinuxRequestsGetAvailableCategories(searchPlayer, "categories-after-purchase")
local stillListedAfterPurchase = false
for _, contractId in ipairs(categoriesAfterPurchase.available) do
    if contractId == 2 then stillListedAfterPurchase = true end
end
PZLinuxTestAssert(not stillListedAfterPurchase,
    "a category just bought from must disappear from the list the same day")
local blockedByPurchase = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 2 }, "order-repurchase")
PZLinuxTestAssert(not blockedByPurchase.ok and blockedByPurchase.error == "category_unavailable",
    "buying from the same category twice in one day must be refused")

-- Refusing an offered price hides that category until the next game day,
-- exactly like finding no seller at all would.
local rejected = PZLinuxRequestsRejectCategory(searchPlayer, 3, "reject-3")
PZLinuxTestAssert(rejected.ok, "rejecting a category must succeed")

local categoriesAfterReject = PZLinuxRequestsGetAvailableCategories(searchPlayer, "categories-after-reject")
local stillListed = false
for _, contractId in ipairs(categoriesAfterReject.available) do
    if contractId == 3 then stillListed = true end
end
PZLinuxTestAssert(not stillListed, "a refused category must disappear from the list the same day")

local blockedByRejection = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 3 }, "order-blocked")
PZLinuxTestAssert(not blockedByRejection.ok and blockedByRejection.error == "category_unavailable",
    "ordering a refused category the same day must be refused")

local otherCategoryStillWorks = PZLinuxRequestsApplyOrder(searchPlayer, { contractId = 1 }, "order-other")
PZLinuxTestAssert(otherCategoryStillWorks.ok,
    "refusing one category must not affect other categories the same day")

-- The next game day rerolls everything, including previously refused
-- categories.
worldAgeHours = worldAgeHours + 24
local categoriesNextDay = PZLinuxRequestsGetAvailableCategories(searchPlayer, "categories-day1")
local listedAgain = false
for _, contractId in ipairs(categoriesNextDay.available) do
    if contractId == 3 then listedAgain = true end
end
PZLinuxTestAssert(listedAgain, "a refused category must become available again on the next game day")

-- No seller today: force every category's roll to fail, then verify the
-- category list is empty and ordering is refused -- the simplified fallback
-- the player explicitly agreed to (only ever show categories with a seller).
local noSellerModData = { PZLinuxOnItemRequestCar = 0, PZLinuxOnItemRequest = {} }
local noSellerPlayer = { getModData = function() return noSellerModData end }
local savedZombRand = ZombRand
ZombRand = function(minimum, maximum)
    if maximum then return maximum end -- always rolls above any chance percent, i.e. always fails
    return minimum
end
local noSellerCategories = PZLinuxRequestsGetAvailableCategories(noSellerPlayer, "categories-none")
PZLinuxTestAssert(#noSellerCategories.available == 0,
    "when every category's roll fails, the list must be empty")
local noSellerOrder = PZLinuxRequestsApplyOrder(noSellerPlayer, { contractId = 1 }, "order-none")
PZLinuxTestAssert(not noSellerOrder.ok and noSellerOrder.error == "category_unavailable",
    "an order for a category with no seller today must be refused")
ZombRand = savedZombRand

-- The chance of finding nobody must rise as the world ages, then cap once
-- the configured ramp period has fully elapsed.
worldAgeHours = 0
PZLinuxTestAssert(PZLinuxRequestsCurrentCategoryAvailableChancePercent() == 50,
    "day 0 must use the configured start chance (100 - 50% unavailable)")
worldAgeHours = 180 * 24
PZLinuxTestAssert(PZLinuxRequestsCurrentCategoryAvailableChancePercent() == 25,
    "at the end of the ramp (180 game days, ~6 months) the chance must equal 100 - the configured max unavailable percent")
worldAgeHours = 360 * 24
PZLinuxTestAssert(PZLinuxRequestsCurrentCategoryAvailableChancePercent() == 25,
    "the chance must stay capped once the ramp period has fully elapsed")

print("PZLinux Request vehicle delivery tests OK")
