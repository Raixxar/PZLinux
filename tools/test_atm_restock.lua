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

PZLinux = {
    Config = {
        ATM = { minCash = 10000, maxCash = 50000, restockPerHour = 500 },
        AtmRefill = { targetCashMin = 1, targetCashMax = 501 },
    },
    MissionLocations = {
        pools = {
            atmRefill = {
                byCityId = {
                    [2] = { { id = "atm_ekron_ez_go_banking_01", x = 418, y = 9869, z = 0 } },
                },
            },
        },
    },
}

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

-- The one ATM matching the "Refill an ATM" contract's target location must
-- roll its very first balance within the much lower
-- AtmRefill.targetCashMin/targetCashMax range instead of the general ATM
-- range, so it visibly looks near-empty and the contract feels meaningful
-- (a normal ATM sitting near its 50,000 $ cap would barely notice a
-- 1,000-5,000 $ deposit). That low range only affects the initial roll,
-- though: the regen ceiling stays the general ATM.maxCash, so a real
-- refill deposit can actually raise its balance well above 501 $.
worldAgeHours = 2000
local function PZLinuxTestMakeAtmAt(x, y, z)
    local modData = {}
    return {
        getModData = function() return modData end,
        getSquare = function()
            return { getX = function() return x end, getY = function() return y end, getZ = function() return z end }
        end,
    }
end
local targetAtm = PZLinuxTestMakeAtmAt(418, 9869, 0)
PZLinuxTestAssert(PZLinuxAtmLoadCash(targetAtm) == 1,
    "the contract's target ATM must roll its initial balance within its own much lower cash range")
worldAgeHours = 2000 + 100000
PZLinuxTestAssert(PZLinuxAtmLoadCash(targetAtm) == 50000,
    "the contract's target ATM must still regenerate up to the general maxCash, not just its own low starting range")
local otherAtm = PZLinuxTestMakeAtmAt(1, 1, 0)
worldAgeHours = 2000
PZLinuxTestAssert(PZLinuxAtmLoadCash(otherAtm) == 10000,
    "an ATM elsewhere on the map must still use the general ATM cash range")

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
