local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_inventory_authority.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTestFunction(source, name, nextName)
    local first = assert(source:find("function " .. name, 1, true), name .. " not found")
    local last = nextName and assert(source:find("function " .. nextName, first + 1, true), nextName .. " not found") or #source + 1
    return source:sub(first, last - 1)
end

local function PZLinuxTestAssertOrdered(source, firstPattern, secondPattern, message)
    local first = source:find(firstPattern, 1, true)
    local second = source:find(secondPattern, 1, true)
    assert(first and second and first < second, message)
end

local shared = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local darkWeb = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")

local interrupted = PZLinuxTestFunction(shared, "PZLinuxApplyInterruptedSessionRollbacks", "PZLinuxAtmTransmitModData")
assert(interrupted:find("PZLinuxSyncAddedInventoryItem", 1, true), "Hacking rollback cards must be synchronized")
assert(interrupted:find("pendingCardTypes", 1, true), "failed Hacking card restoration must remain pending")

local requestDelivery = PZLinuxTestFunction(shared, "PZLinuxRequestsApplyDelivery", "PZLinuxRequestsApplySpawnVehicle")
assert(requestDelivery:find("PZLinuxSyncAddedInventoryItem", 1, true), "Request parcels must be synchronized")
PZLinuxTestAssertOrdered(requestDelivery, "PZLinuxSyncAddedInventoryItem", "table.remove(modData.PZLinuxOnItemRequest",
    "Request state must clear only after parcel synchronization")

local requestOrder = PZLinuxTestFunction(shared, "PZLinuxRequestsApplyOrder", "PZLinuxRequestsApplyDelivery")
assert(requestOrder:find('error = "request_delivery_pending"', 1, true),
    "vehicle Requests must not overwrite another paid pending delivery")
PZLinuxTestAssertOrdered(requestOrder, 'error = "request_delivery_pending"', "PZLinuxApplyBankDebit",
    "conflicting Request orders must be rejected before debit")

local vehicleSpawn = PZLinuxTestFunction(shared, "PZLinuxRequestsApplySpawnVehicle", "PZLinuxRequestsApplyConfirmVehicle")
assert(vehicleSpawn:find("addVehicleDebug", 1, true), "requested vehicles must use the positioned B42 spawn API")
assert(not vehicleSpawn:find("addVehicle(modData.PZLinuxOnItemRequestCarName, x, y, z)", 1, true),
    "requested vehicles must not use the removed coordinate overload")
assert(vehicleSpawn:find("candidate:isFree(false)", 1, true),
    "requested vehicles must search for a nearby free square")
assert(vehicleSpawn:find("PZLinuxRequestsFindDeliveredVehicle", 1, true)
    and vehicleSpawn:find("PZLinuxRequestsRefreshVehicleNetwork", 1, true),
    "vehicle spawn retries must reuse and refresh the tagged server vehicle")
assert(not vehicleSpawn:find("modData.PZLinuxOnItemRequestCar = 0", 1, true),
    "vehicle request state must remain pending until the client sees the vehicle")
assert(vehicleSpawn:find("PZLinuxRequestVehicleDeliveryId", 1, true)
    and vehicleSpawn:find("vehicleData.PZLinuxRequestVehicleDeliveryId", 1, true),
    "requested vehicles must carry a persistent delivery id")
assert(vehicleSpawn:find("PZLinuxRequestsGetDefinition(9)", 1, true)
    and vehicleSpawn:find("PZLinuxRequestsFindVehicleLocation", 1, true),
    "vehicle spawn must revalidate its persisted script and canonical location")
assert(vehicleSpawn:find("PZLinuxRequestsGetVehicleNetworkId", 1, true)
    and vehicleSpawn:find('error = "vehicle_not_networked"', 1, true),
    "MP vehicle delivery must wait for a registered network id")

local vehicleConfirm = PZLinuxTestFunction(shared, "PZLinuxRequestsApplyConfirmVehicle", "PZLinuxRequestOrder")
assert(vehicleConfirm:find("PZLinuxRequestsFindDeliveredVehicle", 1, true)
    and vehicleConfirm:find("PZLinuxIsPlayerNearPosition", 1, true),
    "vehicle confirmation must validate the tagged server vehicle and player proximity")
assert(vehicleConfirm:find("modData.PZLinuxOnItemRequestCar = 0", 1, true),
    "vehicle request state must clear only after validated client visibility")

local mailRemove = PZLinuxTestFunction(shared, "PZLinuxMailRemoveInventoryItems", "PZLinuxMailGiveReward")
assert(mailRemove:find("PZLinuxRemoveInventoryItem", 1, true), "Mail mission items must use synchronized removal")
assert(not mailRemove:find("inventory:Remove(item)", 1, true), "Mail mission items must not use raw server removal")

local mailReward = PZLinuxTestFunction(shared, "PZLinuxMailGiveReward", "PZLinuxMailApplyComplete")
assert(mailReward:find("PZLinuxSyncAddedInventoryItem", 1, true), "Mail reward parcels must be synchronized")
assert(mailReward:find("return 0, nil", 1, true), "Mail reward creation failures must be reported")

local mailComplete = PZLinuxTestFunction(shared, "PZLinuxMailApplyComplete", "PZLinuxRequestMailAccept")
PZLinuxTestAssertOrdered(mailComplete, "PZLinuxMailGiveReward", "PZLinuxMailRemoveInventoryItems",
    "Mail rewards must exist before mission items are consumed")
assert(mailComplete:find('error = "reward_creation_failed"', 1, true), "Mail completion must reject missing rewards")

local hackingRemove = PZLinuxTestFunction(shared, "PZLinuxHackingRemoveCards", "PZLinuxHackingGeneratePassword")
assert(hackingRemove:find("PZLinuxRemoveInventoryItem", 1, true), "consumed Hacking cards must use synchronized removal")
assert(not hackingRemove:find("inventory:Remove(item)", 1, true), "Hacking cards must not use raw server removal")

local darkWebRemove = PZLinuxTestFunction(darkWeb, "PZLinuxDarkWebRemoveInventoryItems", "PZLinuxDarkWebBuildSellOffers")
assert(darkWebRemove:find("PZLinuxRemoveInventoryItem", 1, true), "Dark Web sold items must use synchronized removal")

local darkWebSell = PZLinuxTestFunction(darkWeb, "PZLinuxDarkWebApplySell", "PZLinuxDarkWebApplyRedeemSales")
PZLinuxTestAssertOrdered(darkWebSell, 'inventory:AddItem("Base.SuspiciousPackage")', "PZLinuxRemoveInventoryItem",
    "the Dark Web sale parcel must be created before sold items are consumed")
PZLinuxTestAssertOrdered(darkWebSell, "PZLinuxSyncAddedInventoryItem", "PZLinuxRemoveInventoryItem",
    "the Dark Web sale parcel must be synchronized before sold items are consumed")

local darkWebRedeem = PZLinuxTestFunction(darkWeb, "PZLinuxDarkWebApplyRedeemSales", "PZLinuxDarkWebApplyDeliverOrders")
assert(darkWebRedeem:find("PZLinuxRemoveInventoryItem", 1, true), "redeemed Dark Web parcels must use synchronized removal")

local darkWebDelivery = PZLinuxTestFunction(darkWeb, "PZLinuxDarkWebApplyDeliverOrders", "PZLinuxRequestDarkWebOffers")
assert(darkWebDelivery:find('error = "parcel_sync_failed"', 1, true), "Dark Web delivery must preserve orders on synchronization failure")

local mailboxState = PZLinuxTestFunction(shared, "PZLinuxMailboxGetActionState", "PZLinuxContractsApplyDeposit")
assert(mailboxState:find("PZLinuxValidateMailboxInteraction", 1, true),
    "mailbox action state must be validated by the server at the real mailbox")
assert(mailboxState:find("hasPickup", 1, true) and mailboxState:find("hasContractDeposit", 1, true),
    "mailbox action state must distinguish item pickup from contract deposit")

local serverCommands = PZLinuxTestRead(luaRoot .. "/server/PZLinuxServerCommands.lua")
assert(serverCommands:find("PZLinuxMailboxState = PZLinuxServerMailboxState", 1, true),
    "the authoritative mailbox-state command must be registered")
assert(serverCommands:find("PZLinuxRequestConfirmVehicle = PZLinuxServerRequestConfirmVehicle", 1, true),
    "the authoritative vehicle confirmation command must be registered")

local clientEvents = PZLinuxTestRead(luaRoot .. "/client/Context/World/Events/PZLinuxOnEvents.lua")
assert(clientEvents:find("PZLinuxFindVisibleDeliveredVehicle", 1, true)
    and clientEvents:find("PZLinuxRequestConfirmVehicle", 1, true),
    "the client must acknowledge a delivery only after the vehicle is visible locally")
assert(clientEvents:find('local canMatchDeliveryId = expectedDeliveryId ~= ""', 1, true),
    "an empty delivery id must not match an unrelated visible vehicle")

for _, relativePath in ipairs({
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
}) do
    local mailboxUi = PZLinuxTestRead(luaRoot .. relativePath)
    assert(mailboxUi:find("PZLinuxRequestMailboxActionState", 1, true),
        relativePath .. " must request its action label from the server")
    assert(not mailboxUi:find("SEND/TAKE THE PACKAGE", 1, true),
        relativePath .. " must not expose the ambiguous legacy action label")
end

print("PZLinux authoritative inventory tests OK")
