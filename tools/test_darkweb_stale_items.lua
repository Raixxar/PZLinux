-- Regression test for a player-reported bug: a Dark Web purchase was never
-- delivered. Investigating it (test_darkweb_deliver_orders.lua) found no
-- logic bug, but the player asked to double check the item ids themselves
-- were still valid -- cross-referencing every "Base.*" id referenced
-- anywhere in this mod's shared/client/server Lua against the real,
-- currently installed Build 42 item/vehicle declarations found 9 entries
-- in PZLinuxDarkWebData.lua (plus matching ones duplicated into
-- PZLinuxEconomy.lua's Dark Web price-balancing table,
-- PZLinuxMailData.lua's mail-reward ammo pool, and
-- PZLinuxMailAmmo.lua's live ammo-roll function) that referenced items
-- that no longer exist:
--   - Base.223Box / Base.223Clip: .223 was removed from the game in Build
--     42.14, replaced by 5.56 -- Base.556Box/Base.556Clip already existed
--     as their own separate, correct entries, so these were flat-out
--     removed rather than renamed onto an id that would have duplicated
--     an existing row.
--   - Base.308Clip / Base.223BulletsMold / Base.308BulletsMold /
--     Base.9mmBulletsMold / Base.ShotgunShellsMold: never had a valid
--     current equivalent (.308 has no clip-fed variant; no "mold" item of
--     any kind exists in the current Reloading system) -- removed.
--   - Base.IronSight: no current equivalent found -- removed.
--   - Base.PigIronIngot: renamed to Base.IronIngot, the current
--     basic-tier ingot (not already listed elsewhere in the catalog).
--   - Base.Stone (PZLinuxRequestsData.lua's Materials category): renamed
--     to Base.Stone2, the current generic loose-stone item.
-- These items being unreachable in the shop (Dark Web/Economy) is silent
-- and self-limiting (getScriptManager():FindItem simply excludes them from
-- ever being offered) -- not the reported non-delivery bug itself, whose
-- fix is the pcall hardening in test_server_command_error_handling.lua --
-- but the mail ammo pools actively try to hand a rolled item to a player,
-- so a stale id there really would fail silently. This test locks in that
-- none of the stale ids remain and the replacements are in place.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_stale_items.lua$") or "."
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

local staleIds = {
    "Base.223Box", "Base.223Clip", "Base.308Clip", "Base.223BulletsMold",
    "Base.308BulletsMold", "Base.9mmBulletsMold", "Base.ShotgunShellsMold",
    "Base.IronSight", "Base.PigIronIngot",
}

local filesToCheck = {
    "/shared/PZLinux/PZLinuxDarkWebData.lua",
    "/shared/PZLinux/PZLinuxEconomy.lua",
    "/shared/PZLinux/PZLinuxMailData.lua",
    "/client/Context/World/Mails/PZLinuxMailAmmo.lua",
    "/shared/PZLinux/PZLinuxRequestsData.lua",
}

for _, relativePath in ipairs(filesToCheck) do
    local content = readFile(luaRoot .. relativePath)
    for _, staleId in ipairs(staleIds) do
        PZLinuxTestAssert(not content:find('"' .. staleId .. '"', 1, true),
            relativePath .. " must not reference the stale item id " .. staleId)
    end
end

local requestsContent = readFile(luaRoot .. "/shared/PZLinux/PZLinuxRequestsData.lua")
PZLinuxTestAssert(not requestsContent:find('"Base.Stone"', 1, true),
    "PZLinuxRequestsData.lua must not reference the stale item id Base.Stone")
PZLinuxTestAssert(requestsContent:find('"Base.Stone2"', 1, true),
    "PZLinuxRequestsData.lua must reference the current generic stone item Base.Stone2")

local darkWebContent = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWebData.lua")
PZLinuxTestAssert(darkWebContent:find('"Base.IronIngot"', 1, true),
    "PZLinuxDarkWebData.lua must reference Base.IronIngot (the Base.PigIronIngot replacement)")
PZLinuxTestAssert(darkWebContent:find('"Base.556Box"', 1, true) and darkWebContent:find('"Base.556Clip"', 1, true),
    "PZLinuxDarkWebData.lua must still carry the correct 5.56 entries that made the stale .223 ones redundant")

print("PZLinux Dark Web / mail / requests stale item id tests OK")
