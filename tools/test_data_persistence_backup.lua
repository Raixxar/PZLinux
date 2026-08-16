-- Regression test for the v1.0.8 "belt and suspenders" persistence fix: a
-- player reported their reputation and bank balance both looking reset
-- after restarting the game. Money lives in a flat top-level modData key
-- (the pattern proven reliable across ~330 other usages in this mod);
-- reputation lived in a nested table (md.pzlinux.player.reputation), a much
-- rarer pattern. Both readers used to silently fall back to a default
-- value (a random $500-$4000 balance; reputation 1) whenever their primary
-- key read nil, with no way to distinguish "genuinely new character" from
-- "value was lost". The bank now also has a server-side character ledger;
-- both values retain their flat ModData mirrors for client synchronization
-- and compatibility recovery.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_data_persistence_backup.lua$") or "."
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

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

-- ---------------------------------------------------------------------
-- Bank balance recovery
-- ---------------------------------------------------------------------

local loadBlock = variablesSource:match("function PZLinuxLoadBankBalance.-\nend")
local setBlock = variablesSource:match("function PZLinuxSetBankBalance.-\nend")
PZLinuxTestAssert(loadBlock, "PZLinuxLoadBankBalance must exist")
PZLinuxTestAssert(setBlock, "PZLinuxSetBankBalance must exist")

PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function() return "test-player" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
-- The default sandbox-configurable starting balance range (see
-- PZLinuxGetStartingBalanceMin/Max in PZLinuxEconomy.lua), stubbed here
-- since this test loads PZLinuxLoadBankBalance in isolation.
PZLinuxGetStartingBalanceMin = function() return 500 end
PZLinuxGetStartingBalanceMax = function() return 4000 end
PZLinuxTransmitPlayerModData = function() end
PZLinuxBankGetCharacterIdentity = function() return nil, nil end
PZLinuxBankIsAuthoritative = function() return true end
PZLinuxBankGetLedger = function() return nil end
PZLinuxBankCharacterCannotMutate = function() return false end
PZLinuxBankRollStartingBalance = function()
    local minimum = PZLinuxGetStartingBalanceMin()
    local maximum = PZLinuxGetStartingBalanceMax()
    return maximum > minimum and ZombRand(minimum, maximum) or minimum
end

local rerollCalls = 0
ZombRand = function(low, high)
    rerollCalls = rerollCalls + 1
    return low -- deterministic for the test
end

assert(loadstring(loadBlock))()
assert(loadstring(setBlock))()

-- A genuinely new character (both keys nil) must still roll a fresh
-- starting balance, exactly like before this fix.
local freshModData = {}
local freshPlayer = { getModData = function() return freshModData end }
local freshBalance = PZLinuxLoadBankBalance(freshPlayer)
PZLinuxTestAssert(rerollCalls == 1, "a genuinely new character must still get a random starting balance")
PZLinuxTestAssert(freshModData.PZLinuxBank == freshBalance, "the rolled balance must be stored in the primary key")
PZLinuxTestAssert(freshModData.PZLinuxBankBackup == freshBalance, "the rolled balance must also be mirrored to the backup key")

-- The primary key intact: no reroll, and the backup stays mirrored.
rerollCalls = 0
local normalModData = { PZLinuxBank = 2500 }
local normalPlayer = { getModData = function() return normalModData end }
local normalBalance = PZLinuxLoadBankBalance(normalPlayer)
PZLinuxTestAssert(normalBalance == 2500, "an intact primary balance must be returned unchanged")
PZLinuxTestAssert(rerollCalls == 0, "an intact primary balance must never trigger a reroll")
PZLinuxTestAssert(normalModData.PZLinuxBankBackup == 2500, "the intact balance must be mirrored to the backup key")

-- The exact bug this guards against: primary key nil (lost/corrupted), but
-- the backup still has the player's real balance -- must recover it, not
-- roll a random new one.
rerollCalls = 0
local recoveryModData = { PZLinuxBankBackup = 7777 }
local recoveryPlayer = { getModData = function() return recoveryModData end }
local recoveredBalance = PZLinuxLoadBankBalance(recoveryPlayer)
PZLinuxTestAssert(recoveredBalance == 7777, "a nil primary key with an intact backup must recover the real balance")
PZLinuxTestAssert(rerollCalls == 0, "recovering from backup must never also roll a random balance")
PZLinuxTestAssert(recoveryModData.PZLinuxBank == 7777, "the recovered balance must be written back to the primary key")

-- PZLinuxSetBankBalance must keep both keys in sync going forward.
local setModData = {}
local setPlayer = { getModData = function() return setModData end }
PZLinuxSetBankBalance(setPlayer, 999)
PZLinuxTestAssert(setModData.PZLinuxBank == 999 and setModData.PZLinuxBankBackup == 999,
    "PZLinuxSetBankBalance must write both the primary and backup keys")

-- ---------------------------------------------------------------------
-- Reputation recovery (PZLinux.getModData)
-- ---------------------------------------------------------------------

local getModDataBlock = variablesSource:match("function PZLinux%.getModData.-\nend")
PZLinuxTestAssert(getModDataBlock, "PZLinux.getModData must exist")

PZLinux = { getPlayer = function(value) return value end }
assert(loadstring(getModDataBlock))()

-- A genuinely new character (no pzlinux table at all) must still default
-- to the neutral baseline, exactly like before this fix.
local freshRepModData = {}
local freshRepPlayer = { getModData = function() return freshRepModData end }
local _, freshPzlinux = PZLinux.getModData(freshRepPlayer)
PZLinuxTestAssert(freshPzlinux.player.reputation == 1, "a genuinely new character must default to neutral reputation")
PZLinuxTestAssert(freshRepModData.PZLinuxReputationBackup == 1, "the default reputation must be mirrored to the backup key")

-- The nested value intact: returned unchanged, backup stays mirrored.
local normalRepModData = { pzlinux = { player = { reputation = 42 } } }
local normalRepPlayer = { getModData = function() return normalRepModData end }
local _, normalPzlinux = PZLinux.getModData(normalRepPlayer)
PZLinuxTestAssert(normalPzlinux.player.reputation == 42, "an intact nested reputation must be returned unchanged")
PZLinuxTestAssert(normalRepModData.PZLinuxReputationBackup == 42, "the intact reputation must be mirrored to the backup key")

-- The exact bug this guards against: the nested value is missing (as if
-- lost across a save/reload), but the flat backup key still has the
-- player's real reputation -- must recover it, not silently reset to 1.
local recoveryRepModData = { PZLinuxReputationBackup = 88 }
local recoveryRepPlayer = { getModData = function() return recoveryRepModData end }
local _, recoveredPzlinux = PZLinux.getModData(recoveryRepPlayer)
PZLinuxTestAssert(recoveredPzlinux.player.reputation == 88,
    "a missing nested reputation with an intact backup must recover the real value, not reset to neutral")

-- ---------------------------------------------------------------------
-- The one call site that used to bypass PZLinuxGetModData's repair path
-- entirely (a raw playerObj:getModData() read) must now go through it.
-- ---------------------------------------------------------------------

local economySource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxEconomy.lua")
local multiplierBlock = economySource:match("function PZLinuxGetReputationPurchaseMultiplier.-\nend")
PZLinuxTestAssert(multiplierBlock, "PZLinuxGetReputationPurchaseMultiplier must exist")
PZLinuxTestAssert(multiplierBlock:find("PZLinuxGetModData(playerObj)", 1, true),
    "PZLinuxGetReputationPurchaseMultiplier must read reputation through PZLinuxGetModData, " ..
    "not a raw getModData() call, or it never benefits from the backup-key recovery above")

print("PZLinux data persistence backup tests OK")
