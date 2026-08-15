-- Regression test for a player-reported visual inconsistency: Training was
-- built by copying PZLinuxAdminBalance.lua's drag/close boilerplate (a
-- debug-only admin tool, deliberately styled as a plain floating dark
-- panel with an opaque background and a red border, on purpose so it
-- never looks like part of the in-world computer). That styling came along
-- with it by accident, so Training rendered as a plain floating box
-- instead of appearing on the computer's own screen like every other
-- PZLinux feature (Dark Web, Trading, Reputation, Check Condition, the
-- boot menu itself, ...), all of which draw their content over the shared
-- oldCRT.png bezel texture with a fully transparent panel underneath it.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_training_ui_style.lua$") or "."
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

local source = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxTraining.lua")

-- trainingMenu_ShowUI must draw the same computer-screen bezel every other
-- feature panel uses, not just a bare ISPanel floating on its own.
local showUiBlock = source:match("function trainingMenu_ShowUI.-\nend")
PZLinuxTestAssert(showUiBlock, "trainingMenu_ShowUI must exist")
PZLinuxTestAssert(showUiBlock:find('getTexture("media/ui/oldCRT.png")', 1, true),
    "trainingMenu_ShowUI must load the shared oldCRT.png computer-screen texture, like every other PZLinux feature panel")
PZLinuxTestAssert(showUiBlock:find("ISImage:new", 1, true),
    "trainingMenu_ShowUI must draw the CRT texture as a background image behind the panel")

-- The panel itself must be fully transparent so only the CRT texture is
-- visible as the frame -- an opaque background/border (the AdminBalance
-- debug-tool look) would draw a second, wrong-looking box on top of it.
local constructorBlock = source:match("function trainingUI:new.-\nend")
PZLinuxTestAssert(constructorBlock, "trainingUI:new must exist")
PZLinuxTestAssert(constructorBlock:find("o.backgroundColor = {r=0, g=0, b=0, a=0}", 1, true),
    "trainingUI's own background must be fully transparent, matching every real computer-app panel")
PZLinuxTestAssert(constructorBlock:find("o.borderColor = {r=0, g=0, b=0, a=0}", 1, true),
    "trainingUI's own border must be fully transparent, matching every real computer-app panel")

print("PZLinux Training UI style tests OK")
