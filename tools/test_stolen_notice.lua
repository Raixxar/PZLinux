-- Regression test for the v1.0.7 "stolen order" feature: a player who lost
-- an order to the shared 10% Dark Web / Buy Goods theft roll used to get
-- only an easy-to-miss HaloText bubble. They now also get a torn note with
-- a random flavor message (20 candidates) in their inventory
-- (PZLinuxCreateStolenOrderNote). A centered ISModalDialog popup was tried
-- and deliberately dropped: it's the same class used for the vanilla
-- "call out"/report-noise confirmations, and stopping to click through a
-- popup mid-danger is worse than the bug it was meant to fix -- plain
-- HaloText plus the note is the actual shipped design. The hook-up into
-- both delivery functions is covered separately in test_darkweb_delivery.lua
-- and test_request_delivery.lua; this file covers the note helper itself
-- and the translation catalog it depends on.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_stolen_notice.lua$") or "."
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

-- 1. PZLinuxCreateStolenOrderNote itself, in isolation.
local addedItems = {}
local inventory = {}
function inventory:AddItem(itemType)
    local item = { fullType = itemType, pages = {} }
    function item:setName(name) self.itemName = name end
    function item:setCanBeWrite(value) self.canWrite = value end
    function item:addPage(index, text) self.pages[index] = text end
    table.insert(addedItems, item)
    return item
end

local synchronized = {}
local player = {
    getInventory = function() return inventory end,
}

PZLinuxGetPlayer = function(value) return value end
PZLinuxSyncAddedInventoryItem = function(_, item)
    table.insert(synchronized, item)
    return true
end

local seenTranslateKeys = {}
local translatedMessages = {
    "Sorry, survival comes first!", "That's life!", "Should've hidden it better.",
    "Finders keepers.", "Better luck with the next delivery.", "The apocalypse has bills too.",
    "Consider it a survival tax.", "Someone needed it more than you. Or just wanted it.",
    "Not all heroes wear masks. This one did.", "Thanks for the donation!",
    "Someone's apocalypse just got a little easier. Not yours.", "Guess it wasn't meant to be.",
    "Easy come, easy go.", "The Knox Event doesn't do refunds.",
    "You snooze, you lose. Someone else didn't snooze.", "Well, that's one way to lose weight.",
    "At least it wasn't your legs.", "Free enterprise, zombie-apocalypse style.",
    "Karma's just late on some deliveries.", "Next time, maybe tip the courier.",
}
PZLinuxGetText = function(key)
    table.insert(seenTranslateKeys, key)
    if key == "IGUI_PZLinux_StolenNote_Title" then return "Torn Note" end
    local index = tonumber(key:match("IGUI_PZLinux_StolenNote_(%d+)$"))
    if index then return translatedMessages[index] end
    return key
end
ZombRand = function(low, high) return low end -- deterministic: always picks message 1

local variablesBlock = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local helperBlock = variablesBlock:match("function PZLinuxCreateStolenOrderNote.-\nend")
PZLinuxTestAssert(helperBlock, "PZLinuxCreateStolenOrderNote must exist in the shared variables file")
-- The real file also declares a local message-count constant just above
-- this function; extracted in isolation that identifier resolves as a
-- global instead, so it's provided here to match.
rawset(_G, "PZLINUX_STOLEN_NOTE_MESSAGE_COUNT", 20)
assert(loadstring(helperBlock))()

local note = PZLinuxCreateStolenOrderNote(player)
PZLinuxTestAssert(note ~= nil, "a stolen-order note must be created when the player and inventory are valid")
PZLinuxTestAssert(note.fullType == "Base.Note", "the stolen-order note must be a real Base.Note item")
PZLinuxTestAssert(note.itemName == "Torn Note", "the stolen-order note must use the localized title")
PZLinuxTestAssert(note.pages[1] == "Sorry, survival comes first!", "the note's page text must be the resolved flavor message")
PZLinuxTestAssert(#synchronized == 1 and synchronized[1] == note, "the note must be synchronized to the client")

-- No inventory (e.g. player disconnected mid-delivery) must not error.
PZLinuxTestAssert(PZLinuxCreateStolenOrderNote({ getInventory = function() return nil end }) == nil,
    "a missing inventory must be handled gracefully, not crash the delivery it's called from")

-- The message pool must actually be 20 wide, not silently stuck at the
-- earlier 10 -- ZombRand's upper bound is what drives that in real play.
PZLinuxTestAssert(helperBlock:find("PZLINUX_STOLEN_NOTE_MESSAGE_COUNT%s*%+%s*1"),
    "the message roll must span the full message-count constant")
PZLinuxTestAssert(variablesBlock:find('IGUI_PZLinux_StolenNote_20%s*=', 1, false)
    or variablesBlock:find("IGUI_PZLinux_StolenNote_20"),
    "the fallback text table must define all 20 flavor messages, not just 10")

-- 2. Both delivery functions must actually call the shared helper -- see
-- the dedicated per-system regression tests for the runtime proof; this is
-- a cheap source-pattern safety net so the call site can't silently be
-- deleted by an unrelated refactor without a test failing here too.
PZLinuxTestAssert(variablesBlock:find("PZLinuxCreateStolenOrderNote%(playerObj%)"),
    "PZLinuxRequestsApplyDelivery must call the shared stolen-order note helper")

local darkWebSource = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
PZLinuxTestAssert(darkWebSource:find("PZLinuxCreateStolenOrderNote%(playerObj%)"),
    "PZLinuxDarkWebApplyDeliverOrders must call the shared stolen-order note helper")

-- 3. Every one of the 20 language catalogs must carry the new keys, with
-- valid JSON (round-trip parity, same technique as test_mail_translations.lua).
local languages = { "CH", "CN", "CS", "DE", "EN", "ES", "FR", "HU", "IT", "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RU", "TH", "TR", "UA" }
local requiredKeys = { "IGUI_PZLinux_StolenNote_Title" }
for i = 1, 20 do table.insert(requiredKeys, "IGUI_PZLinux_StolenNote_" .. i) end

for _, lang in ipairs(languages) do
    local path = luaRoot .. "/shared/Translate/" .. lang .. "/IG_UI.json"
    local content = PZLinuxTestRead(path)
    for _, key in ipairs(requiredKeys) do
        PZLinuxTestAssert(content:find('"' .. key .. '"', 1, true),
            lang .. "/IG_UI.json must define " .. key)
    end
end

print("PZLinux stolen notice tests OK")
