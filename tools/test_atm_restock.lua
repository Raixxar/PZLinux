-- luacheck: globals getGameTime ZombRand PZLinux isClient
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_atm_restock.lua$") or "."
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

PZLinux = { Config = { ATM = {
    minCash = 10000,
    maxCash = 50000,
    restockPerHour = 500,
} } }

local worldAgeHours = 0
getGameTime = function()
    return { getWorldAgeHours = function() return worldAgeHours end }
end
ZombRand = function(minimum) return minimum end
isClient = function() return false end

-- Slice covering just PZLinuxAtmLoadCash/PZLinuxAtmSaveCash and the local
-- min/max constants they close over.
local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local first = assert(source:find("local PZLINUX_ATM_MIN_CASH", 1, true))
local last = assert(source:find("function PZLinuxGetAtmReference", first, true))
assert(loadstring(source:sub(first, last - 1)))()

local function PZLinuxTestMakeAtm()
    local modData = {}
    return { getModData = function() return modData end }
end

-- A fresh ATM is initialized once, randomly within [minCash, maxCash], and
-- stamped with the current hour so restock accrues only from here on.
local atm = PZLinuxTestMakeAtm()
local initialCash = PZLinuxAtmLoadCash(atm)
PZLinuxTestAssert(initialCash == 10000, "the deterministic minimum roll must initialize an ATM at minCash")
PZLinuxTestAssert(atm:getModData().PZLinuxAtmCashUpdatedHour == 0, "initialization must stamp the current game hour")

-- No time has passed: reloading must not restock anything yet.
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 10000, "loading again with no elapsed time must not restock")

-- Advance 10 in-game hours: cash must regenerate by exactly
-- elapsedHours * restockPerHour, capped at maxCash.
worldAgeHours = 10
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 10000 + 10 * 500,
    "cash must regenerate proportionally to elapsed in-game hours")

-- Withdraw most of it via PZLinuxAtmSaveCash (mirroring what a real
-- withdrawal does), then advance a huge amount of time: regeneration must
-- still cap at maxCash, never exceed it.
PZLinuxAtmSaveCash(atm, 100)
PZLinuxTestAssert(atm:getModData().PZLinuxAtmCashUpdatedHour == 10,
    "saving cash must re-stamp the current hour so regen resumes from now")
worldAgeHours = 10 + 1000
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 50000,
    "regeneration must cap at maxCash even after a very long absence")

-- A completely drained ATM (explicitly saved at 0) must also be able to
-- regenerate back up over time, so withdrawals alone can never permanently
-- empty a machine.
local drainedAtm = PZLinuxTestMakeAtm()
PZLinuxAtmLoadCash(drainedAtm) -- initialize at hour 1010
PZLinuxAtmSaveCash(drainedAtm, 0)
worldAgeHours = 1010 + 50
PZLinuxTestAssert(PZLinuxAtmLoadCash(drainedAtm) == 50 * 500,
    "a fully drained ATM must regenerate at the configured rate like any other")

-- The client must never itself mutate or restock an ATM's cash; it only
-- ever reads whatever the server has already computed.
isClient = function() return true end
local clientAtm = PZLinuxTestMakeAtm()
PZLinuxTestAssert(PZLinuxAtmLoadCash(clientAtm) == 0,
    "the client must never initialize an uninitialized ATM's cash itself")
clientAtm:getModData().PZLinuxAtmCash = 12345
clientAtm:getModData().PZLinuxAtmCashUpdatedHour = 0
worldAgeHours = 1000000
PZLinuxTestAssert(PZLinuxAtmLoadCash(clientAtm) == 12345,
    "the client must never apply restock accrual itself, only read the server-authoritative value")

print("PZLinux ATM restock tests OK")
