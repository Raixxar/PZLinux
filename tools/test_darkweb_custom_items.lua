-- Regression test for a requested feature: letting a server admin add (or
-- re-price) Dark Web items via a sandbox option instead of editing
-- PZLinuxDarkWebData.lua directly. The option is free text
-- ("Base.ItemName:Price", comma-separated), parsed lazily (never at file
-- scope, since SandboxVars isn't populated yet at mod boot) and merged
-- into the existing PZLinuxDarkWebItemsTable so every consumer (market
-- generation, sell offers, the in-game help list) sees the same items
-- with zero changes needed at those call sites.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_custom_items.lua$") or "."
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

-- 1. The sandbox option and its translation must exist.
local sandboxOptions = readFile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/sandbox-options.txt")
PZLinuxTestAssert(sandboxOptions:find("option PZLinux.CustomDarkWebItems", 1, true),
    "a PZLinux.CustomDarkWebItems sandbox option must exist")
PZLinuxTestAssert(sandboxOptions:find("type = string", 1, true),
    "the custom items option must be a free-text string field")

local sandboxTranslations = readFile(luaRoot .. "/shared/Translate/EN/Sandbox.json")
PZLinuxTestAssert(sandboxTranslations:find('"Sandbox_PZLinux_CustomDarkWebItems"', 1, true),
    "the custom Dark Web items option must have a display translation")

-- 2. Functional behavior of the loader itself.
local dataSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWebData.lua")
local loaderBlock = dataSource:match("function PZLinuxDarkWebLoadCustomItems.-\nend")
PZLinuxTestAssert(loaderBlock, "PZLinuxDarkWebLoadCustomItems must exist")

PZLinux = { DarkWeb = {} }
local knownItems = { ["Base.Machete"] = true, ["Base.MyCustomItem"] = true }
getScriptManager = function()
    return { FindItem = function(_, itemId) return knownItems[itemId] end }
end

local function freshItemsTable()
    return {
        { id = { "Base.Machete" }, Price = 1000 },
        { id = { "Base.Katana" }, Price = 8000 },
    }
end

-- A genuinely new item must be appended.
PZLinux.DarkWeb.customItemsLoaded = nil
PZLinuxDarkWebItemsTable = freshItemsTable()
SandboxVars = { PZLinux = { CustomDarkWebItems = "Base.MyCustomItem:250" } }
assert(loadstring(loaderBlock))()
PZLinuxDarkWebLoadCustomItems()
PZLinuxTestAssert(#PZLinuxDarkWebItemsTable == 3, "a genuinely new custom item must be appended to the table")
PZLinuxTestAssert(PZLinuxDarkWebItemsTable[3].id[1] == "Base.MyCustomItem" and PZLinuxDarkWebItemsTable[3].Price == 250,
    "the new item must carry the configured price")

-- An item ID that already exists must have its price overridden, not be
-- duplicated as a second row.
PZLinux.DarkWeb.customItemsLoaded = nil
PZLinuxDarkWebItemsTable = freshItemsTable()
SandboxVars = { PZLinux = { CustomDarkWebItems = "Base.Machete:9999" } }
PZLinuxDarkWebLoadCustomItems()
PZLinuxTestAssert(#PZLinuxDarkWebItemsTable == 2, "an existing item ID must override its price, not add a duplicate row")
PZLinuxTestAssert(PZLinuxDarkWebItemsTable[1].Price == 9999, "the existing item's price must be updated")

-- Unknown items and malformed entries must be skipped without crashing or
-- touching the table, and valid entries in the same list must still work.
PZLinux.DarkWeb.customItemsLoaded = nil
PZLinuxDarkWebItemsTable = freshItemsTable()
SandboxVars = { PZLinux = { CustomDarkWebItems = "Base.DoesNotExist:100, not valid, Base.MyCustomItem:300" } }
PZLinuxDarkWebLoadCustomItems()
PZLinuxTestAssert(#PZLinuxDarkWebItemsTable == 3,
    "unknown items and unparseable entries must be silently skipped, while valid entries in the same list still apply")

-- Idempotency: calling it again (e.g. from a second entry point) must not
-- re-parse or double-add anything.
local lengthAfterFirstLoad = #PZLinuxDarkWebItemsTable
PZLinuxDarkWebLoadCustomItems()
PZLinuxTestAssert(#PZLinuxDarkWebItemsTable == lengthAfterFirstLoad,
    "calling the loader again must be a no-op, or every entry point calling it defensively would re-parse repeatedly")

-- Blank/default configuration must never touch the table at all.
PZLinux.DarkWeb.customItemsLoaded = nil
PZLinuxDarkWebItemsTable = freshItemsTable()
SandboxVars = { PZLinux = { CustomDarkWebItems = "" } }
PZLinuxDarkWebLoadCustomItems()
PZLinuxTestAssert(#PZLinuxDarkWebItemsTable == 2, "an empty option must leave the items table untouched")

-- 3. Every real entry point that reads PZLinuxDarkWebItemsTable for actual
-- gameplay (not just error paths) must call the loader defensively.
local darkWebSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")
local ensureMarketBlock = darkWebSource:match("local function PZLinuxDarkWebEnsureMarket.-\nend")
PZLinuxTestAssert(ensureMarketBlock, "PZLinuxDarkWebEnsureMarket must exist")
PZLinuxTestAssert(ensureMarketBlock:find("PZLinuxDarkWebLoadCustomItems()", 1, true),
    "market generation must load custom items first, or they'll never appear in the daily buy offers")

local sellOffersBlock = darkWebSource:match("function PZLinuxDarkWebBuildSellOffers.-\nend")
PZLinuxTestAssert(sellOffersBlock, "PZLinuxDarkWebBuildSellOffers must exist")
PZLinuxTestAssert(sellOffersBlock:find("PZLinuxDarkWebLoadCustomItems()", 1, true),
    "building sell offers must load custom items first, or a custom item in the player's inventory could never be sold")

local clientSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxDarkWeb.lua")
local onHelpBlock = clientSource:match("function darkWebUI:onHelp.-\nend")
PZLinuxTestAssert(onHelpBlock, "darkWebUI:onHelp must exist")
PZLinuxTestAssert(onHelpBlock:find("PZLinuxDarkWebLoadCustomItems()", 1, true),
    "the help/reference list (a separate client-side iteration of the items table) must also load custom items")

print("PZLinux Dark Web custom items tests OK")
