-- Regression test for a player-reported bug: repairing the in-world
-- computer (ISPZLinuxRepareAction, the "Repair Computer" world context
-- option) never granted Electricity XP, even though the repair itself
-- visibly worked (item consumed, condition improved).
--
-- Root cause: this action's perform() runs client-side, same as every
-- other TimedAction in this mod (queued via ISTimedActionQueue.add in
-- ISContextLinuxMenu.lua's linuxMenu_OnRepare) -- but addXp is a
-- server-side-only native, nil on the client. Every other call site in
-- this mod (46+ across ISPZLinuxVariablesTables.lua/PZLinuxDarkWeb.lua)
-- already guards it with "if addXp then addXp(...) end"; this was the one
-- place calling it bare, so it threw "attempt to call a nil value" right
-- there, silently aborting the rest of perform() (including the XP grant)
-- without crashing the game, since the repair math above it had already
-- applied.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_repair_action_xp.lua$") or "."
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

local source = readFile(luaRoot .. "/shared/TimedActions/ISPZLinuxRepareAction.lua")

local _, callCount = source:gsub("addXp%(self%.character, Perks%.Electricity, 3%)", "")
PZLinuxTestAssert(callCount == 1, "expected exactly one addXp call in this action, found " .. callCount)
PZLinuxTestAssert(source:find("if addXp then addXp(self.character, Perks.Electricity, 3) end", 1, true),
    "the Electricity XP grant on a successful repair must be guarded the same way as every other addXp call in this mod")

print("PZLinux repair action XP guard test OK")
