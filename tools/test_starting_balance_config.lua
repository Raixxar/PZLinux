-- Regression test for a player-reported exploit: dying and creating a new
-- character always granted a random $500-$4000 starting balance with no
-- way to opt out, farmable by repeated suicide+recreate. The range is now
-- sandbox-configurable (PZLinux.StartingBalanceMin/Max) so an admin can set
-- both to 0 and remove the free-money loop entirely, or tune the range.
--
-- Separately: a hypothesis was raised that reusing the same character name
-- after death might let a player recover their old (dead) character's
-- balance. That's not how this works -- the balance lives exclusively on
-- modData (playerObj:getModData()), the same per-character, per-save-slot
-- storage PZ itself uses for anything tied to a specific character; it is
-- never looked up by username or character name anywhere in this codebase
-- (grep the whole mod for "PZLinuxBank" and every hit is a modData read or
-- write). A new character, even with an identical name, gets a genuinely
-- empty modData table and rolls a fresh starting balance like any other
-- new character -- it cannot inherit a dead character's money through this
-- mod's own code.

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
PZLinuxTestAssert(loadBlock, "PZLinuxLoadBankBalance must exist")
PZLinuxTestAssert(loadBlock:find("PZLinuxGetStartingBalanceMin()", 1, true),
    "PZLinuxLoadBankBalance must read the configurable minimum instead of a hardcoded 500")
PZLinuxTestAssert(loadBlock:find("PZLinuxGetStartingBalanceMax()", 1, true),
    "PZLinuxLoadBankBalance must read the configurable maximum instead of a hardcoded 4000")
PZLinuxTestAssert(loadBlock:find("maxStart > minStart and ZombRand(minStart, maxStart) or minStart", 1, true),
    "PZLinuxLoadBankBalance must skip ZombRand entirely when the configured range is empty (min >= max), " ..
    "not risk calling ZombRand(0, 0)")

-- 4. The "same character name recovers the old balance" hypothesis: every
-- reference to the bank balance key must go through modData, never through
-- anything keyed by username/character name.
PZLinuxTestAssert(variablesSource:find("modData%.PZLinuxBank"),
    "sanity check: the bank balance must still be readable somewhere via modData")
PZLinuxTestAssert(not variablesSource:find("PZLinuxGetPlayerKey%(.-%)%s*%]%s*%.?%s*PZLinuxBank"),
    "the bank balance must never be looked up by username/player-key -- only by the character's own modData, " ..
    "or a new character sharing an old character's name could inherit their balance")

print("PZLinux starting balance config tests OK")
