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
        ATM = { minCash = 10000, maxCash = 50000, restockPerHour = 500, restockCap = 15000 },
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

-- Mutable mock of the contract world-data lookup, so tests can simulate an
-- active/inactive "Refill an ATM" contract without loading the real
-- contract system.
local mockWorldContracts = {}
PZLinuxContractsGetWorldData = function()
    return { active = mockWorldContracts }
end

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

-- Regression test for a real design problem: regen used to accrue purely
-- from elapsed world time, regardless of whether anyone ever withdrew from
-- that specific ATM. Over a long game, every ATM a player had ever visited
-- once would drift up to maxCash on its own and permanently block deposits
-- there. Regen must now only ever refund cash that was actually withdrawn
-- from THIS ATM -- an ATM nobody withdraws from must never regen, no
-- matter how much time passes.
worldAgeHours = 100000
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 10000,
    "an ATM nobody has ever withdrawn from must never regenerate on its own, however long it's been")

-- Simulate a withdrawal of 8,000 (down to 2,000), recorded the same way
-- PZLinuxApplyAtmWithdrawal does. Regen must catch back up to exactly what
-- was withdrawn (10,000), never more, however long is given.
worldAgeHours = 100010
PZLinuxAtmSaveCash(atm, 2000)
atm:getModData().PZLinuxAtmWithdrawnTotal = 8000
worldAgeHours = 100010 + 1000
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 10000,
    "regen must catch back up to exactly the amount withdrawn from this ATM")
worldAgeHours = 100010 + 1000 + 100000
PZLinuxTestAssert(PZLinuxAtmLoadCash(atm) == 10000,
    "regen must stop once it has refunded everything ever withdrawn, even after more time passes")

-- Regression test for the hard lifetime cap: if cumulative withdrawals
-- exceed restockCap (15,000 here), regen must still never grant more than
-- restockCap in total, so a heavily-farmed ATM can't fully self-heal to
-- maxCash purely from regen and permanently block deposits either.
local cappedAtm = PZLinuxTestMakeAtm()
worldAgeHours = 200000
PZLinuxAtmLoadCash(cappedAtm) -- initialize at 10,000, hour 200000
PZLinuxAtmSaveCash(cappedAtm, 500) -- withdrew 9,500
cappedAtm:getModData().PZLinuxAtmWithdrawnTotal = 9500
worldAgeHours = 200000 + 1000
PZLinuxTestAssert(PZLinuxAtmLoadCash(cappedAtm) == 10000,
    "regen below the lifetime cap must fully catch up to what was withdrawn")
PZLinuxAtmSaveCash(cappedAtm, 1000) -- withdrew another 9,000 (cumulative 18,500, past the 15,000 cap)
cappedAtm:getModData().PZLinuxAtmWithdrawnTotal = 18500
worldAgeHours = 200000 + 1000 + 100000
PZLinuxTestAssert(PZLinuxAtmLoadCash(cappedAtm) == 6500,
    "regen must stop at the lifetime cap (15,000 granted total) even if more was withdrawn than that")

-- The one ATM matching the "Refill an ATM" contract's target location must
-- roll its very first balance within the much lower
-- AtmRefill.targetCashMin/targetCashMax range instead of the general ATM
-- range, so it visibly looks near-empty and the contract feels meaningful
-- (a normal ATM sitting near its 50,000 $ cap would barely notice a
-- 1,000-5,000 $ deposit). That low range only affects the initial roll; the
-- regen ceiling stays the general ATM.maxCash so a real refill deposit can
-- still raise its balance well above 501 $ -- but passive regen itself
-- still only ever refunds real withdrawals, so this near-empty machine
-- doesn't silently balloon back up to 50,000 on its own either.
worldAgeHours = 300000
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
worldAgeHours = 300000 + 100000
PZLinuxTestAssert(PZLinuxAtmLoadCash(targetAtm) == 1,
    "the contract's target ATM must not regenerate on its own either, absent any withdrawal")
local otherAtm = PZLinuxTestMakeAtmAt(1, 1, 0)
worldAgeHours = 300000
PZLinuxTestAssert(PZLinuxAtmLoadCash(otherAtm) == 10000,
    "an ATM elsewhere on the map must still use the general ATM cash range")

-- Regression test for the "Refill an ATM" reset escape valve: accepting a
-- fresh instance of the contract must drop the target ATM's balance back
-- down to a near-empty roll, even if it had climbed all the way to
-- maxCash, so players who've been farming physical cash and hitting
-- "ATM full" everywhere always have somewhere to deposit again -- without
-- ever touching any player's bank balance.
local resetAtm = PZLinuxTestMakeAtmAt(418, 9869, 0)
worldAgeHours = 500000
PZLinuxAtmLoadCash(resetAtm) -- initialize near-empty (1), no active contract yet
PZLinuxAtmSaveCash(resetAtm, 50000) -- simulate it having filled all the way up since
mockWorldContracts["PZLinuxContract-1"] = {
    contractId = 13, status = "accepted", locationX = 418, locationY = 9869, locationZ = 0, id = "PZLinuxContract-1",
}
PZLinuxTestAssert(PZLinuxAtmLoadCash(resetAtm) == 1,
    "accepting a fresh Refill an ATM contract must reset its full target ATM back to a near-empty roll")
PZLinuxTestAssert(resetAtm:getModData().PZLinuxAtmWithdrawnTotal == 0
    and resetAtm:getModData().PZLinuxAtmRegenGranted == 0,
    "resetting the ATM must also clear its withdrawal/regen tracking")

-- The reset must only ever apply once per contract instance, not on every
-- load while that same contract stays active.
PZLinuxAtmSaveCash(resetAtm, 30000)
PZLinuxTestAssert(PZLinuxAtmLoadCash(resetAtm) == 30000,
    "the same active contract instance must not reset the ATM a second time")

-- Once that contract is no longer active (deposited/completed/cancelled),
-- no more resets happen until a genuinely new contract instance appears.
mockWorldContracts["PZLinuxContract-1"].status = "deposited"
PZLinuxAtmSaveCash(resetAtm, 45000)
PZLinuxTestAssert(PZLinuxAtmLoadCash(resetAtm) == 45000,
    "a completed contract must not keep resetting the ATM")

-- A brand new contract instance targeting the same ATM (fresh world id)
-- must reset it again.
mockWorldContracts["PZLinuxContract-2"] = {
    contractId = 13, status = "accepted", locationX = 418, locationY = 9869, locationZ = 0, id = "PZLinuxContract-2",
}
PZLinuxTestAssert(PZLinuxAtmLoadCash(resetAtm) == 1,
    "a fresh new contract instance targeting the same ATM must reset it again")

-- A completely drained ATM (withdrawn down to 0) must still be able to
-- regenerate back up to what was actually taken out of it, proportionally
-- to elapsed time while it's still under budget.
local drainedAtm = PZLinuxTestMakeAtm()
worldAgeHours = 400000
PZLinuxAtmLoadCash(drainedAtm) -- initialize at 10,000, hour 400000
PZLinuxAtmSaveCash(drainedAtm, 0)
drainedAtm:getModData().PZLinuxAtmWithdrawnTotal = 10000
worldAgeHours = 400000 + 10
PZLinuxTestAssert(PZLinuxAtmLoadCash(drainedAtm) == 10 * 500,
    "regen must accrue proportionally to elapsed hours while still under the withdrawn-amount budget")
worldAgeHours = 400000 + 10 + 100
PZLinuxTestAssert(PZLinuxAtmLoadCash(drainedAtm) == 10000,
    "regen must still fully catch up to the full amount withdrawn, given enough time")

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
