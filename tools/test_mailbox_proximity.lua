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

print("Mailbox proximity tests: OK")
