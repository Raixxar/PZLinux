-- Regression test for a player-reported bug: a Dark Web purchase (money
-- debited, confirmed) was never delivered at the mailbox -- no parcel, no
-- "stolen" note, no error message either, most reproducible when a Dark
-- Web sale (redeem) and a pending order landed at the mailbox together.
--
-- Every server command in this mod funnels through
-- PZLinuxServerProcessIdempotent's worker() call, uncaught. If any one of
-- the dozens of commands routed through it ever throws (an unexpected nil,
-- a bad assumption about item/inventory state, anything), worker() aborts
-- before PZLinuxServerSend ever runs -- the client's registered callback
-- just never fires. That's indistinguishable from "nothing happened" to
-- the player: no delivered items, no error toast, nothing -- exactly what
-- was reported. No Dark Web logic bug reproduces the reported combination
-- under test (see test_darkweb_deliver_orders.lua), which points at
-- exactly this: an uncaught error somewhere, not a logic bug in the Dark
-- Web code itself.
--
-- The fix doesn't require knowing which command or line throws: wrapping
-- every worker() call in pcall turns "total silence" into "a real
-- {ok=false, error=...} response the client can show" plus a server log
-- line naming the exact command, player and requestId, for every command
-- in the mod at once.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_server_command_error_handling.lua$") or "."
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

local serverSource = readFile(luaRoot .. "/server/PZLinuxServerCommands.lua")

PZLinuxTestAssert(serverSource:find("local ok, result = pcall(worker)", 1, true),
    "PZLinuxServerRunIdempotentWorker must run worker() through pcall")
PZLinuxTestAssert(serverSource:find('{ ok = false, error = "internal_error", requestId = requestId }', 1, true),
    "a worker() error must still produce a real response instead of silence")

-- 1 definition + 2 real call sites (the no-requestId branch and the
-- normal/cached branch of PZLinuxServerProcessIdempotent).
local _, occurrences = serverSource:gsub("PZLinuxServerRunIdempotentWorker%(worker, command, player, requestId%)", "")
PZLinuxTestAssert(occurrences == 3,
    "both branches of PZLinuxServerProcessIdempotent that call worker() must run it through the pcall wrapper, " ..
    "found " .. occurrences .. " occurrences (expected 1 definition + 2 call sites)")

-- ---------------------------------------------------------------------
-- Functional test: extract PZLinuxServerRunIdempotentWorker in isolation
-- and confirm both outcomes.
-- ---------------------------------------------------------------------

local function extract(pattern)
    local block = serverSource:match(pattern)
    assert(block, "pattern not found: " .. pattern)
    return block
end

function PZLinuxGetPlayerKey(_player) return "TestPlayer" end

-- Silence the diagnostic print during the test.
local realPrint = print
print = function() end

local chunk = assert(loadstring(extract("local function PZLinuxServerRunIdempotentWorker.-\nend\n")
    :gsub("^local function", "function", 1)))
chunk()
print = realPrint

local normalResult = PZLinuxServerRunIdempotentWorker(function() return { ok = true, amount = 42 } end,
    "PZLinuxTestCommand", "fakePlayer", "req-1")
PZLinuxTestAssert(normalResult.ok == true and normalResult.amount == 42,
    "a worker that succeeds must pass its result through unchanged")

local crashedResult = PZLinuxServerRunIdempotentWorker(function() error("boom") end,
    "PZLinuxTestCommand", "fakePlayer", "req-2")
PZLinuxTestAssert(crashedResult.ok == false and crashedResult.error == "internal_error" and crashedResult.requestId == "req-2",
    "a worker that throws must still produce a graceful error response instead of propagating the crash")

print("PZLinux server command error handling tests OK")
