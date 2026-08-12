-- Regression test for a real MP report: a player could repeatedly re-
-- collect Dark Web orders they had already received, and it survived
-- log-outs and reconnects. The pending-order queues (Dark Web's
-- PZLinuxOnItemBuyOnDarkWeb, Buy Goods' PZLinuxOnItemRequest) were only
-- ever mutated in place with table.insert/table.remove -- the modData key
-- itself was never re-assigned. If the engine's change-detection for
-- network sync/save is keyed on assignment rather than a deep scan, an
-- in-place-only mutation can silently fail to persist, so a reconnect
-- reloads the pre-delivery state and the same batch delivers again. Every
-- insert/remove on these queues now re-assigns the key right after (even
-- to the same table) as a belt-and-suspenders guard, and the Dark Web
-- delivery loop now also transmits after every single removal rather than
-- only once at the end, matching how the Buy Goods delivery loop already
-- worked.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_queue_mutation_persistence.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local darkWebSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

local buyBlock = darkWebSource:match("function PZLinuxDarkWebApplyBuy.-\nend")
PZLinuxTestAssert(buyBlock, "PZLinuxDarkWebApplyBuy must exist")
PZLinuxTestAssert(buyBlock:find("table.insert(modData.PZLinuxOnItemBuyOnDarkWeb", 1, true),
    "a Dark Web purchase must still queue its batch")
PZLinuxTestAssert(buyBlock:find("modData.PZLinuxOnItemBuyOnDarkWeb = modData.PZLinuxOnItemBuyOnDarkWeb", 1, true),
    "queuing a new Dark Web purchase must re-assign the queue key after the in-place insert, " ..
    "or the change may not be recognized for sync/save")

local deliverBlock = darkWebSource:match("function PZLinuxDarkWebApplyDeliverOrders.-\nend")
PZLinuxTestAssert(deliverBlock, "PZLinuxDarkWebApplyDeliverOrders must exist")
PZLinuxTestAssert(deliverBlock:find("table.remove(modData.PZLinuxOnItemBuyOnDarkWeb", 1, true),
    "delivering Dark Web orders must still remove each batch from the queue")
PZLinuxTestAssert(deliverBlock:find("modData.PZLinuxOnItemBuyOnDarkWeb = modData.PZLinuxOnItemBuyOnDarkWeb", 1, true),
    "removing a delivered Dark Web batch must re-assign the queue key after the in-place removal")
-- The transmit must happen INSIDE the delivery loop (once per removed
-- batch), not just once after the whole loop -- a disconnect between two
-- batches must not leave the already-delivered one still marked pending.
local deliverLoopBlock = deliverBlock:match("while #modData%.PZLinuxOnItemBuyOnDarkWeb > 0 do.-\n    end")
PZLinuxTestAssert(deliverLoopBlock, "the Dark Web delivery loop must exist")
PZLinuxTestAssert(deliverLoopBlock:find("PZLinuxTransmitPlayerModData(playerObj)", 1, true),
    "the Dark Web delivery loop must transmit modData after every single batch removal, " ..
    "not only once after the whole loop finishes")

local orderBlock = variablesSource:match("function PZLinuxRequestsApplyOrder.-\nend")
PZLinuxTestAssert(orderBlock, "PZLinuxRequestsApplyOrder must exist")
PZLinuxTestAssert(orderBlock:find("table.insert(modData.PZLinuxOnItemRequest", 1, true),
    "placing a Buy Goods order must still queue its batch")
PZLinuxTestAssert(orderBlock:find("modData.PZLinuxOnItemRequest = modData.PZLinuxOnItemRequest", 1, true),
    "queuing a new Buy Goods order must re-assign the queue key after the in-place insert")

local requestDeliverBlock = variablesSource:match("function PZLinuxRequestsApplyDelivery.-\nend")
PZLinuxTestAssert(requestDeliverBlock, "PZLinuxRequestsApplyDelivery must exist")
PZLinuxTestAssert(requestDeliverBlock:find("table.remove(modData.PZLinuxOnItemRequest", 1, true),
    "delivering a Buy Goods order must still remove the batch from the queue")
PZLinuxTestAssert(requestDeliverBlock:find("modData.PZLinuxOnItemRequest = modData.PZLinuxOnItemRequest", 1, true),
    "removing a delivered Buy Goods batch must re-assign the queue key after the in-place removal")

print("PZLinux queue mutation persistence tests OK")
