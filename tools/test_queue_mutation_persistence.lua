-- Regression test for two related MP reports about the pending-order
-- queues (Dark Web's PZLinuxOnItemBuyOnDarkWeb, Buy Goods'
-- PZLinuxOnItemRequest):
--   (a) a player could repeatedly re-collect an order already received,
--       surviving log-outs and reconnects;
--   (b) a player's own server logs later confirmed the real, deeper issue:
--       two separate Dark Web BUY log lines both showed queueLenAfter=1 --
--       the second purchase never actually appended to the first, meaning
--       the queue was losing its previous contents between separate
--       purchase commands, not just on delivery.
-- The original v1.0.8 fix for (a) was a "belt and suspenders" pattern --
-- keep the queue as a nested array of tables, but re-assign the modData
-- key right after every in-place table.insert/table.remove, and transmit
-- after every single removal instead of once at the end. That mitigated
-- (a) but, per the real logs behind (b), was not enough: an array of
-- tables is still a nested value in modData, the same shape already
-- confirmed once before in this mod not to reliably round-trip through a
-- save/reload (see the reputation backup-key fix at the top of
-- ISPZLinuxVariablesTables.lua).
--
-- The actual fix: both queues are now encoded as a single flat STRING
-- value (the same simple, flat-value shape already proven reliable
-- everywhere else in this mod) instead of a nested array of tables.
-- PZLinuxDarkWebQueueEncode/Decode and PZLinuxRequestsQueueEncode/Decode
-- are the only things that ever touch the encoded form; everything else
-- just works with a plain Lua array in between.

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

-- ---------------------------------------------------------------------
-- 1. Source checks: neither queue may still be a nested array-of-tables
-- modData value -- both must go through their flat-string encode/decode
-- helpers, and the old nested keys must be gone entirely.
-- ---------------------------------------------------------------------

PZLinuxTestAssert(not darkWebSource:find("PZLinuxOnItemBuyOnDarkWeb%f[%A]") or darkWebSource:find("PZLinuxOnItemBuyOnDarkWebStatus", 1, true),
    "sanity: the status flag itself should still exist")
for _, forbidden in ipairs({ "table.insert(modData.PZLinuxOnItemBuyOnDarkWeb,", "table.remove(modData.PZLinuxOnItemBuyOnDarkWeb," }) do
    PZLinuxTestAssert(not darkWebSource:find(forbidden, 1, true),
        "PZLinuxDarkWeb.lua must no longer mutate a nested table directly in modData: " .. forbidden)
end
PZLinuxTestAssert(darkWebSource:find("modData.PZLinuxOnItemBuyOnDarkWebQueue = PZLinuxDarkWebQueueEncode(queue)", 1, true),
    "the Dark Web queue must be written back through PZLinuxDarkWebQueueEncode")

for _, forbidden in ipairs({ "table.insert(modData.PZLinuxOnItemRequest,", "table.remove(modData.PZLinuxOnItemRequest," }) do
    PZLinuxTestAssert(not variablesSource:find(forbidden, 1, true),
        "ISPZLinuxVariablesTables.lua must no longer mutate a nested table directly in modData: " .. forbidden)
end
PZLinuxTestAssert(variablesSource:find("modData.PZLinuxOnItemRequestQueue = PZLinuxRequestsQueueEncode(queue)", 1, true),
    "the Buy Goods queue must be written back through PZLinuxRequestsQueueEncode")

-- The Dark Web delivery loop must still transmit after every single
-- removal, not just once at the end of the loop.
local deliverBlock = darkWebSource:match("function PZLinuxDarkWebApplyDeliverOrders.-\nend")
PZLinuxTestAssert(deliverBlock, "PZLinuxDarkWebApplyDeliverOrders must exist")
local deliverLoopBlock = deliverBlock:match("while #queue > 0 do.-\n    end")
PZLinuxTestAssert(deliverLoopBlock, "the Dark Web delivery loop must exist")
PZLinuxTestAssert(deliverLoopBlock:find("PZLinuxTransmitPlayerModData(playerObj)", 1, true),
    "the Dark Web delivery loop must transmit modData after every single batch removal")

-- ---------------------------------------------------------------------
-- 2. Functional test: the flat encoding must actually round-trip, and a
-- second, independent decode(prior)+append+encode cycle (simulating two
-- separate purchase commands sharing nothing but the modData string, the
-- exact scenario from the real report) must accumulate rather than reset.
-- ---------------------------------------------------------------------

local darkWebPieces = {
    darkWebSource:match("function PZLinuxDarkWebQueueDecode.-\nend"),
    darkWebSource:match("function PZLinuxDarkWebQueueEncode.-\nend"),
}
for _, piece in ipairs(darkWebPieces) do
    assert(piece, "Dark Web queue encode/decode helpers must exist")
    assert(loadstring(piece))()
end

local queueString = ""
for _, purchase in ipairs({ { name = "Base.CigarettePack", quantity = 2 }, { name = "Base.CigarettePack", quantity = 4 } }) do
    -- Each purchase only has the STRING left behind by the previous one to
    -- work with -- nothing else survives between commands in the real bug.
    local queue = PZLinuxDarkWebQueueDecode(queueString)
    table.insert(queue, purchase)
    queueString = PZLinuxDarkWebQueueEncode(queue)
end
local finalQueue = PZLinuxDarkWebQueueDecode(queueString)
PZLinuxTestAssert(#finalQueue == 2,
    "two separate Dark Web purchases must both still be queued after being decoded/re-encoded independently, found " .. #finalQueue)
PZLinuxTestAssert(finalQueue[1].name == "Base.CigarettePack" and finalQueue[1].quantity == 2,
    "the first purchase must survive the second one's encode/decode cycle")
PZLinuxTestAssert(finalQueue[2].name == "Base.CigarettePack" and finalQueue[2].quantity == 4,
    "the second purchase must be appended, not replace the first")

local requestPieces = {
    variablesSource:match("function PZLinuxRequestsQueueDecode.-\nend"),
    variablesSource:match("function PZLinuxRequestsQueueEncode.-\nend"),
}
for _, piece in ipairs(requestPieces) do
    assert(piece, "Buy Goods queue encode/decode helpers must exist")
    assert(loadstring(piece))()
end

local requestQueueString = ""
for _, order in ipairs({
    { items = { { name = "Base.Apple" }, { name = "Base.Apple" }, { name = "Base.Banana" } } },
    { items = { { name = "Base.CannedBeans" } } },
}) do
    local queue = PZLinuxRequestsQueueDecode(requestQueueString)
    table.insert(queue, order)
    requestQueueString = PZLinuxRequestsQueueEncode(queue)
end
local finalRequestQueue = PZLinuxRequestsQueueDecode(requestQueueString)
PZLinuxTestAssert(#finalRequestQueue == 2, "two separate Buy Goods orders must both still be queued, found " .. #finalRequestQueue)
PZLinuxTestAssert(#finalRequestQueue[1].items == 3, "the first order's 3 items must all survive")
PZLinuxTestAssert(finalRequestQueue[1].items[1].name == "Base.Apple" and finalRequestQueue[1].items[3].name == "Base.Banana",
    "the first order's item names must be preserved in order")
PZLinuxTestAssert(#finalRequestQueue[2].items == 1 and finalRequestQueue[2].items[1].name == "Base.CannedBeans",
    "the second order must be appended, not replace the first")

print("PZLinux queue mutation persistence tests OK")
