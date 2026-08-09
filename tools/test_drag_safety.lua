-- Regression test for a real gameplay bug: a player reported a PZLinux UI
-- panel getting stuck glued to the mouse cursor after clicking a bet
-- amount input then a race runner's name in the Zombie Races betting
-- screen, with no way out except ESC. Every PZLinux panel implements
-- window dragging manually (topBar.onMouseDown sets isDragging = true,
-- topBar.onMouseUp clears it), and a click landing on certain child
-- widgets can end up not routing its release back to topBar's own
-- onMouseUp, leaving isDragging stuck true forever -- the panel then
-- chases the mouse on every subsequent move, making it impossible to
-- click anything precisely.
--
-- The fix adds a second, independent way to clear isDragging: a global
-- Events.OnMouseUp/OnRightMouseUp hook (PZLinuxReleaseAllDragging in
-- PZLinuxUtils.lua) that fires on every mouse button release regardless of
-- which specific widget handled the click, clearing isDragging on every
-- panel that registered itself via PZLinuxTrackDragging when it started
-- dragging. This does not change normal drag behavior at all -- the
-- panel's own topBar.onMouseUp still fires and does the same thing in the
-- ordinary case; this is purely a fallback for when it doesn't.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_drag_safety.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local utilsSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxUtils.lua")
assert(utilsSource:find("function PZLinuxTrackDragging", 1, true),
    "PZLinuxUtils.lua must define the shared drag-tracking function")
assert(utilsSource:find("Events.OnMouseUp.Add(", 1, true),
    "the drag safety net must hook the real vanilla Events.OnMouseUp, not a PZLinux-only event")
assert(utilsSource:find("Events.OnRightMouseUp.Add(", 1, true),
    "the drag safety net must also cover right-click release, not just left-click")
assert(utilsSource:find("panel.isDragging = false", 1, true),
    "the global release handler must actually clear isDragging on every tracked panel")

-- Every PZLinux panel that can start a manual drag must also register
-- itself with the safety net at the same time -- not just later, not just
-- sometimes, or the stuck-forever case can still slip through untracked.
local dragFiles = {
    "/client/Context/World/Features/PZLinuxReputation.lua",
    "/client/Context/World/Features/PZLinuxHacking.lua",
    "/client/Context/World/Features/PZLinuxWallet.lua",
    "/client/Context/World/Features/PZLinuxConnectInternet.lua",
    "/client/Context/World/ISContextMailBox.lua",
    "/client/Context/World/ISContextStreetMailBox.lua",
    "/client/Context/World/Features/PZLinuxTrading.lua",
    "/client/Context/World/Features/PZLinuxContracts.lua",
    "/client/Context/World/ISContextLinuxMenu.lua",
    "/client/Context/World/Features/PZLinuxSell.lua",
    "/client/Context/World/ISContextAtmMenu.lua",
    "/client/Context/World/Features/PZLinuxDarkWeb.lua",
    "/client/Context/World/Features/PZLinuxCondition.lua",
    "/client/Context/World/Features/PZLinuxBetting.lua",
    "/client/Context/World/Features/PZLinuxMail.lua",
    "/client/Context/World/Features/PZLinuxRequest.lua",
}

for _, relativePath in ipairs(dragFiles) do
    local source = readFile(luaRoot .. relativePath)
    local dragLine = source:find(".isDragging = true", 1, true)
    assert(dragLine, relativePath .. " must set isDragging = true when starting a manual drag")
    assert(source:find("PZLinuxTrackDragging(", 1, true),
        relativePath .. " must register its panel with the drag safety net right when it starts dragging, " ..
        "or a missed onMouseUp can leave it stuck glued to the cursor with only ESC to escape")
end

print("PZLinux drag safety tests OK")
