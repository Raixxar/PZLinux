local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_mailbox_proximity.lua$") or "."

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function makeList(entries)
    return {
        size = function() return #entries end,
        get = function(_, index) return entries[index + 1] end,
    }
end

local square = {
    x = 100,
    y = 200,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}

local sprite = {
    getName = function() return "street_decoration_01_18" end,
}

local mailbox = {
    getSquare = function() return square end,
    getSprite = function() return sprite end,
}

square.getObjects = function() return makeList({ mailbox }) end

local player = {
    x = 101,
    y = 201,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}

PZLinux = {}
PZLinuxGetPlayer = function(value) return value end
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if x == square.x and y == square.y and z == square.z then return square end
            return nil
        end,
    }
end

dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxWorldInteractions.lua")

local mailboxRef = PZLinuxGetMailboxReference(mailbox)
assertEqual(mailboxRef.x, 100, "mailbox reference x")
assertEqual(mailboxRef.sprite, "street_decoration_01_18", "mailbox reference sprite")

local resolved, validationError = PZLinuxValidateMailboxInteraction(player, mailboxRef)
assertEqual(resolved, mailbox, "nearby mailbox resolution")
assertEqual(validationError, nil, "nearby mailbox validation")

player.x = 103
resolved, validationError = PZLinuxValidateMailboxInteraction(player, mailboxRef)
assertEqual(resolved, nil, "distant mailbox rejection")
assertEqual(validationError, "too_far_from_mailbox", "distant mailbox error")

player.x = 101
player.z = 1
resolved, validationError = PZLinuxValidateMailboxInteraction(player, mailboxRef)
assertEqual(resolved, nil, "wrong z rejection")
assertEqual(validationError, "too_far_from_mailbox", "wrong z error")

player.z = 0
resolved, validationError = PZLinuxValidateMailboxInteraction(player, {
    x = 100,
    y = 200,
    z = 0,
    sprite = "location_business_bank_01_67",
})
assertEqual(resolved, nil, "forged object type rejection")
assertEqual(validationError, "invalid_mailbox", "forged object type error")

resolved, validationError = PZLinuxValidateMailboxInteraction(player, nil)
assertEqual(resolved, nil, "missing reference rejection")
assertEqual(validationError, "missing_mailbox_reference", "missing reference error")

local serverPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/server/PZLinuxServerCommands.lua"
local serverFile = assert(io.open(serverPath, "rb"))
local serverSource = serverFile:read("*a")
serverFile:close()

assert(serverSource:find("PZLinuxDarkWebApplyRedeemSales%(player, args and args%.mailbox,"), "Dark Web sale redemption must pass a mailbox reference")
assert(serverSource:find("PZLinuxDarkWebApplyDeliverOrders%(player, args and args%.mailbox,"), "Dark Web delivery must pass a mailbox reference")
assert(serverSource:find("PZLinuxContractsApplyDeposit%(player, args and args%.mailbox,"), "contract deposit must pass a mailbox reference")
assert(serverSource:find("PZLinuxRequestsApplyDelivery%(player, args and args%.mailbox,"), "Request delivery must pass a mailbox reference")

-- Regression test for a real gameplay bug: accepting a mail mission
-- silently did nothing (no error, contracts still worked fine). Root
-- cause: md.pzlinux.mails is keyed by number (PZLinuxMailNormalizeRecord
-- itself does tonumber(mailId)), but onAcceptMail read
-- md.pzlinux.mails[self.selectedMailId] without ever coercing it. Lua
-- treats t["42"] and t[42] as unrelated keys, so a mail ID that came back
-- as a string after a ModData round-trip (save/reload, MP sync) made the
-- lookup silently find nothing, and the accept request never even reached
-- the server.
local mailUiPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/Features/PZLinuxMail.lua"
local mailUiFile = assert(io.open(mailUiPath, "rb"))
local mailUiSource = mailUiFile:read("*a")
mailUiFile:close()
assert(mailUiSource:find("self%.selectedMailId = tonumber%(mail%.id%) or mail%.id"),
    "selecting a mail must normalize its ID to a number, or the accept lookup can silently miss")
assert(mailUiSource:find("local id = tonumber%(self%.selectedMailId%) or self%.selectedMailId"),
    "accepting a mail must normalize the selected ID to a number before looking it up")

-- Regression test for a real gameplay bug: completing a mail mission
-- (Ammo/Medical) could silently fail with a generic "Mail delivery
-- rejected" even with the exact right item in hand, at a mailbox that
-- visibly offered the deposit option. Root cause: the context menu shows
-- the option using isNearTarget's Chebyshev distance (<= 5), but
-- PZLinuxMailApplyComplete enforced a different metric entirely --
-- Manhattan distance (<= 3) -- which off-axis can reject a position the
-- client had just approved (e.g. dx=3,dy=3 is Chebyshev 3 but Manhattan 6).
local variablesFile = assert(io.open(
    repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua",
    "rb"
))
local variablesSource = variablesFile:read("*a")
variablesFile:close()
local mailCompleteBlock = variablesSource:match("function PZLinuxMailApplyComplete.-\nend\n\nfunction PZLinuxRequestMailAccept")
assert(mailCompleteBlock and mailCompleteBlock:find("math%.max%(") and mailCompleteBlock:find("distance > 5"),
    "completing a mail mission must use the same Chebyshev distance and threshold (<= 5) as the " ..
    "context menu that offers the deposit option, or a visible option can still be silently rejected")

-- Regression test for a real gameplay bug: the city was reported as
-- missing from mail mission descriptions. Root cause: mission location
-- pool entries only ever have city/building fields (never a "name" field),
-- so "mail.city = mail.city or loc.name" always resolved to nil and left
-- the city permanently unset once a mail was generated.
assert(not variablesSource:find("mail.city = mail.city or loc.name", 1, true),
    "mail city must not be sourced from the nonexistent loc.name field")
assert(variablesSource:find("mail.city = mail.city or loc.city", 1, true),
    "mail city must be sourced from loc.city, the field mission locations actually have")
assert(variablesSource:find("mail.building = mail.building or loc.building", 1, true),
    "mail description must also carry the building/place name, not just the city")

-- Regression test: mail descriptions must include a floor label built from
-- the mission's absolute Z level, using the mod's z=0=ground-floor
-- convention (matching the rest of the mod, e.g. the Ekron ATM target and
-- RELEASE.md's "per absolute Z level" reward wording), with dedicated
-- wording for ground level and basements instead of a bare "Floor 0"/"-1".
assert(variablesSource:find("function PZLinuxFormatFloorLabel", 1, true),
    "a floor-label helper must exist for mail descriptions")
local floorFn = variablesSource:match("function PZLinuxFormatFloorLabel.-\nend")
assert(floorFn and floorFn:find("IGUI_PZLinux_Mail_FloorGround", 1, true)
    and floorFn:find("IGUI_PZLinux_Mail_FloorAbove", 1, true)
    and floorFn:find("IGUI_PZLinux_Mail_FloorBelow", 1, true),
    "the floor label must be translated (ground/above/below wording differs per language)")

for _, relativePath in ipairs({
    "/client/Context/World/Mails/PZLinuxMailAmmo.lua",
    "/client/Context/World/Mails/PZLinuxMailMedical.lua",
}) do
    local mailFile = assert(io.open(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua" .. relativePath, "rb"))
    local mailSource = mailFile:read("*a")
    mailFile:close()
    assert(mailSource:find("PZLinuxFormatFloorLabel(mail.z)", 1, true),
        relativePath .. " must include a floor label built from the mail's Z level")
    assert(mailSource:find("locationLabel", 1, true) and not mailSource:find("displayName, mail.city, mail.sender)", 1, true),
        relativePath .. " must describe the building, city and floor together instead of just the city")
end

-- Regression test for a real gameplay bug: a player's context menu offered
-- the mailbox option on an unrelated B42 object (a newspaper dispenser),
-- and every action on it then failed with "missing_mailbox_reference".
-- Root cause: the context-menu builders matched sprite names with
-- string.find (a substring search), while the server-side allowlist
-- (PZLinuxIsMailboxSprite) does an exact match. A single-digit pattern
-- like "street_decoration_01_9" matches ANY sprite name that merely
-- starts with it, e.g. "street_decoration_01_90" -- a real B42 object
-- added since this code was written. The menu then opened on the wrong
-- object, PZLinuxGetMailboxReference correctly refused to recognize it
-- (exact match), and every action failed downstream with a nil reference.
for _, spec in ipairs({
    { path = "/client/Context/World/ISContextStreetMailBox.lua", fn = "StreetMailBoxMenu_AddContext" },
    { path = "/client/Context/World/ISContextMailBox.lua", fn = "MailBoxMenu_AddContext" },
    { path = "/client/Context/World/ISContextAtmMenu.lua", fn = "AtmMenu_AddContext" },
    { path = "/client/Context/World/ISContextLinuxMenu.lua", fn = "linuxMenu_AddContext" },
}) do
    local specFile = assert(io.open(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua" .. spec.path, "rb"))
    local source = specFile:read("*a")
    specFile:close()
    local block = source:match("function " .. spec.fn .. ".-\nend")
    assert(block, spec.path .. " must define " .. spec.fn)
    assert(not block:find("string.find(sprite", 1, true) and not block:find("string.find(spriteName", 1, true),
        spec.path .. "'s " .. spec.fn .. " must match sprite names exactly (==), not with a substring search " ..
        "that can false-positive on an unrelated object whose sprite name happens to start the same way")
end

-- Regression test for a real gameplay bug: a player reported the computer
-- context menu not appearing at all when the Desktop Computer was placed
-- on top of a piece of furniture (a counter), even standing right next to
-- it. Vanilla's own worldobjects list for a right-click can skip a computer
-- stacked on furniture in favor of the furniture itself, even though the
-- computer object is still really on that tile. The fix rescans each
-- worldobjects square's FULL object list (square:getObjects()) instead of
-- only checking the objects vanilla already chose to list.
do
    local linuxMenuPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/ISContextLinuxMenu.lua"
    local linuxMenuFile = assert(io.open(linuxMenuPath, "rb"))
    local linuxMenuSource = linuxMenuFile:read("*a")
    linuxMenuFile:close()
    local addContextBlock = linuxMenuSource:match("function linuxMenu_AddContext.-\nend")
    assert(addContextBlock, "linuxMenu_AddContext must exist")
    assert(addContextBlock:find("square:getObjects()", 1, true),
        "linuxMenu_AddContext must rescan each candidate square's full object list, " ..
        "not just the objects vanilla's worldobjects already picked out, " ..
        "or a computer stacked on furniture can be silently invisible to the menu")
    assert(addContextBlock:find("isNearTargetCapture(x, y, z, targetX, targetY, targetZ)", 1, true),
        "the extra scan must still be gated by the same player-proximity check as before, " ..
        "so it cannot offer the menu for a computer far from the player")
end

print("Mailbox proximity tests: OK")
