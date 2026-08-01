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

print("PZLinux authoritative inventory tests OK")
