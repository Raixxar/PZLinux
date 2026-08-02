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
    return list
end

local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local first = assert(source:find("local function PZLinuxRequestsFindDeliveredVehicle", 1, true))
local last = assert(source:find("function PZLinuxRequestOrder", first, true))
assert(loadstring(source:sub(first, last - 1)))()

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
isServer = function() return false end
IsoDirections = { S = 4 }
ZombRand = function(minimum) return minimum end

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

local spawnedCount = 0
addVehicleDebug = function(scriptName)
    spawnedCount = spawnedCount + 1
    local vehicle = { id = 42, keyId = 0, data = {}, scriptName = scriptName }
    function vehicle:getId() return self.id end
    function vehicle:getX() return 100 end
    function vehicle:getY() return 200 end
    function vehicle:getZ() return 0 end
    function vehicle:getModData() return self.data end
    function vehicle:setKeyId(value) self.keyId = value end
    function vehicle:repair() self.repaired = true end
    function vehicle:isExistInTheWorld() return true end
    function vehicle:transmitModData() self.transmitted = true end
    function vehicle:updateParts() self.partsUpdated = true end
    table.insert(vehicles.values, vehicle)
    return vehicle
end

local result = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-spawn-1")
PZLinuxTestAssert(result.ok and result.spawned, "the first request must spawn its vehicle")
PZLinuxTestAssert(spawnedCount == 1 and #vehicles.values == 1, "the server must create exactly one vehicle")
PZLinuxTestAssert(#inventory.values == 1, "the vehicle must have exactly one synchronized key")
PZLinuxTestAssert(modData.PZLinuxOnItemRequestCar == 1,
    "the paid request must remain pending until client visibility is confirmed")
PZLinuxTestAssert(vehicles.values[1].data.PZLinuxRequestVehicleDeliveryId == result.deliveryId,
    "the spawned vehicle must carry its persistent delivery id")

local retry = PZLinuxRequestsApplySpawnVehicle(player, "vehicle-spawn-2")
PZLinuxTestAssert(retry.ok and retry.existing, "a retry must recover the tagged server vehicle")
PZLinuxTestAssert(spawnedCount == 1 and #vehicles.values == 1, "a retry must not duplicate the vehicle")
PZLinuxTestAssert(#inventory.values == 1, "a retry must not duplicate the vehicle key")

local forged = PZLinuxRequestsApplyConfirmVehicle(player, result.deliveryId, 999, "vehicle-confirm-forged")
PZLinuxTestAssert(not forged.ok and modData.PZLinuxOnItemRequestCar == 1,
    "a forged vehicle id must not consume the paid request")

local confirmed = PZLinuxRequestsApplyConfirmVehicle(player, result.deliveryId, result.vehicleId, "vehicle-confirm-ok")
PZLinuxTestAssert(confirmed.ok and confirmed.confirmed, "the visible canonical vehicle must be confirmable")
PZLinuxTestAssert(modData.PZLinuxOnItemRequestCar == 0 and modData.PZLinuxActiveRequest == 0,
    "validated client visibility must complete the vehicle delivery")

print("PZLinux Request vehicle delivery tests OK")
