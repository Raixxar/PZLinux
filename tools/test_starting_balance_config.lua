-- Regression test for a player-reported exploit: dying and creating a new
-- character always granted a random $500-$4000 starting balance with no
-- way to opt out, farmable by repeated suicide+recreate. The range is now
-- sandbox-configurable (PZLinux.StartingBalanceMin/Max) so an admin can set
-- both to 0 and remove the free-money loop entirely, or tune the range.
--
-- The authoritative balance now lives in a server ledger keyed by the
-- persistent PZLinux character identity. Player ModData remains its client-
-- visible mirror. Reusing an account or character name therefore cannot
-- recover a deceased character's balance; a new identity receives a fresh
-- configured starting balance.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_starting_balance_config.lua$") or "."
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

-- 1. The sandbox option must exist so a server admin can actually reach
-- this setting without editing Lua.
local sandboxOptions = readFile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/sandbox-options.txt")
PZLinuxTestAssert(sandboxOptions:find("option PZLinux.StartingBalanceMin", 1, true),
    "a PZLinux.StartingBalanceMin sandbox option must exist")
PZLinuxTestAssert(sandboxOptions:find("option PZLinux.StartingBalanceMax", 1, true),
    "a PZLinux.StartingBalanceMax sandbox option must exist")

local sandboxTranslations = readFile(luaRoot .. "/shared/Translate/EN/Sandbox.json")
PZLinuxTestAssert(sandboxTranslations:find('"Sandbox_PZLinux_StartingBalanceMin"', 1, true),
    "the starting balance minimum option must have a display translation")
PZLinuxTestAssert(sandboxTranslations:find('"Sandbox_PZLinux_StartingBalanceMax"', 1, true),
    "the starting balance maximum option must have a display translation")

-- 2. Functional behavior: default (untouched SandboxVars) must match the
-- mod's historical $500-$4000 range exactly, and an admin setting both to
-- 0 must produce a guaranteed $0 start with no random roll at all.
rawset(_G, "SandboxVars", nil)
local economySource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxEconomy.lua")
local minBlock = economySource:match("function PZLinuxGetStartingBalanceMin.-\nend")
local maxBlock = economySource:match("function PZLinuxGetStartingBalanceMax.-\nend")
PZLinuxTestAssert(minBlock, "PZLinuxGetStartingBalanceMin must exist")
PZLinuxTestAssert(maxBlock, "PZLinuxGetStartingBalanceMax must exist")
assert(loadstring(minBlock))()
assert(loadstring(maxBlock))()

PZLinuxTestAssert(PZLinuxGetStartingBalanceMin() == 500, "the default minimum must stay $500, unchanged from before this fix")
PZLinuxTestAssert(PZLinuxGetStartingBalanceMax() == 4000, "the default maximum must stay $4000, unchanged from before this fix")

rawset(_G, "SandboxVars", { PZLinux = { StartingBalanceMin = 0, StartingBalanceMax = 0 } })
PZLinuxTestAssert(PZLinuxGetStartingBalanceMin() == 0, "a server must be able to set the minimum to 0")
PZLinuxTestAssert(PZLinuxGetStartingBalanceMax() == 0, "a server must be able to set the maximum to 0")

-- 3. PZLinuxLoadBankBalance must actually use these instead of hardcoded
-- 500/4000, and must not call ZombRand at all when min >= max (a $0-$0
-- config must not risk an ill-defined/erroring ZombRand(0, 0) call).
local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local loadBlock = variablesSource:match("function PZLinuxLoadBankBalance.-\nend")
local rollBlock = variablesSource:match("local function PZLinuxBankRollStartingBalance.-\nend")
PZLinuxTestAssert(loadBlock, "PZLinuxLoadBankBalance must exist")
PZLinuxTestAssert(rollBlock, "PZLinuxBankRollStartingBalance must exist")
PZLinuxTestAssert(loadBlock:find("PZLinuxBankRollStartingBalance()", 1, true),
    "PZLinuxLoadBankBalance must delegate fresh-character initialization to the configured roll")
PZLinuxTestAssert(rollBlock:find("PZLinuxGetStartingBalanceMin()", 1, true),
    "the starting-balance roll must read the configurable minimum instead of a hardcoded 500")
PZLinuxTestAssert(rollBlock:find("PZLinuxGetStartingBalanceMax()", 1, true),
    "the starting-balance roll must read the configurable maximum instead of a hardcoded 4000")
PZLinuxTestAssert(rollBlock:find("maxStart > minStart and ZombRand(minStart, maxStart) or minStart", 1, true),
    "PZLinuxLoadBankBalance must skip ZombRand entirely when the configured range is empty (min >= max), " ..
    "not risk calling ZombRand(0, 0)")

-- 4. The bank mirror must never be indexed directly by username. Persistent
-- storage is keyed through PZLinuxGetCharacterKey instead.
PZLinuxTestAssert(variablesSource:find("modData%.PZLinuxBank"),
    "the client-visible bank balance must remain mirrored in player ModData")
PZLinuxTestAssert(not variablesSource:find("PZLinuxGetPlayerKey%(.-%)%s*%]%s*%.?%s*PZLinuxBank"),
    "the bank balance must never be indexed directly by username/player-key")
PZLinuxTestAssert(variablesSource:find("PZLinuxGetCharacterKey", 1, true),
    "the authoritative bank ledger must use the persistent character identity")

print("PZLinux starting balance config tests OK")
