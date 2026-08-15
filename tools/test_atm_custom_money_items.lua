-- Regression test for a requested compatibility feature: letting a server
-- admin register a third-party mod's own currency item (e.g. from a
-- "weightless money" mod that ships its own item rather than patching
-- vanilla Base.Money) as valid PZLinux cash, via a sandbox option. Without
-- this, PZLinuxCountInventoryCash/PZLinuxRemoveInventoryCash and the ATM's
-- deposit flow never recognize such an item as money at all, so a player
-- carrying only that item sees every deposit rejected as
-- "not_enough_inventory_cash" while visibly holding cash. From player
-- feedback: a "Weightless Money" mod's item couldn't be deposited.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_atm_custom_money_items.lua$") or "."
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
PZLinuxTestAssert(sandboxOptions:find("option PZLinux.CustomMoneyItems", 1, true),
    "a PZLinux.CustomMoneyItems sandbox option must exist")
PZLinuxTestAssert(sandboxOptions:find("type = string", 1, true),
    "the custom money items option must be a free-text string field")

local sandboxTranslations = readFile(luaRoot .. "/shared/Translate/EN/Sandbox.json")
PZLinuxTestAssert(sandboxTranslations:find('"Sandbox_PZLinux_CustomMoneyItems"', 1, true),
    "the custom money items option must have a display translation")

-- 2. Functional behavior of PZLinuxMoneyItemValue, the shared recognizer.
local function PZLinuxTestItem(fullType, itemType)
    return {
        fullType = fullType,
        itemType = itemType or fullType:match("[^.]+$"),
        getFullType = function(self) return self.fullType end,
        getType = function(self) return self.itemType end,
        getInventory = function() return nil end,
    }
end

local knownItems = { ["WeightlessMoney.Money"] = true }
getScriptManager = function()
    return { FindItem = function(_, itemId) return knownItems[itemId] end }
end
PZLinuxGetPlayer = function(value) return value end
PZLinuxNormalizeMoney = function(value) return math.max(0, math.floor(tonumber(value) or 0)) end
PZLinuxSyncAddedContainerItem = function() return true end
PZLinuxRemoveContainerItem = function() return true end

dofile(luaRoot .. "/shared/PZLinux/PZLinuxInventoryCash.lua")

-- Vanilla money must always be recognized, sandbox option or not.
SandboxVars = { PZLinux = { CustomMoneyItems = "" } }
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("Base.Money")) == 1, "vanilla Base.Money must be worth $1")
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("Base.MoneyBundle")) == 100, "vanilla Base.MoneyBundle must be worth $100")

-- An unrelated item must never be counted as cash.
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("Base.Bandage", "Bandage")) == 0,
    "an unrelated item must never be counted as cash")

-- A third-party item that still carries the vanilla "Money" Type tag must
-- already be recognized, with no sandbox configuration needed -- this is
-- the pre-existing fallback for a same-Type reskin.
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("SomeOtherMod.CashPile", "Money")) == 1,
    "any item whose vanilla Type is Money must be recognized as $1 cash regardless of its module")

-- A third-party item with neither the vanilla fullType nor the Money Type
-- tag must be rejected until explicitly registered via the sandbox option.
PZLinux.customMoneyItemsLoaded = nil
PZLinux.customMoneyItemIds = {}
SandboxVars = { PZLinux = { CustomMoneyItems = "" } }
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("WeightlessMoney.Money", "Bill")) == 0,
    "an unregistered custom money item with a non-Money Type tag must not be recognized yet")

-- Once registered through the sandbox option, it must be recognized as $1.
PZLinux.customMoneyItemsLoaded = nil
PZLinux.customMoneyItemIds = {}
SandboxVars = { PZLinux = { CustomMoneyItems = "WeightlessMoney.Money" } }
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("WeightlessMoney.Money", "Bill")) == 1,
    "an explicitly registered custom money item must be recognized as $1 cash")

-- An unknown item ID (typo, or an item that doesn't actually exist) must
-- be skipped without crashing or silently accepting it anyway.
PZLinux.customMoneyItemsLoaded = nil
PZLinux.customMoneyItemIds = {}
SandboxVars = { PZLinux = { CustomMoneyItems = "SomeMod.DoesNotExist" } }
PZLinuxTestAssert(PZLinuxMoneyItemValue(PZLinuxTestItem("SomeMod.DoesNotExist", "Bill")) == 0,
    "an unknown item ID must be skipped, not silently registered as cash")

-- Idempotency: the loader only ever parses SandboxVars once, matching the
-- established custom-item lazy-load pattern (PZLinuxDarkWebLoadCustomItems).
PZLinux.customMoneyItemsLoaded = nil
PZLinux.customMoneyItemIds = {}
SandboxVars = { PZLinux = { CustomMoneyItems = "WeightlessMoney.Money" } }
PZLinuxMoneyItemValue(PZLinuxTestItem("Base.Money"))
SandboxVars = { PZLinux = { CustomMoneyItems = "AnotherMod.Cash" } }
PZLinuxMoneyItemValue(PZLinuxTestItem("Base.Money"))
PZLinuxTestAssert(PZLinux.customMoneyItemIds["AnotherMod.Cash"] == nil,
    "the loader must only ever parse SandboxVars once, not re-parse on every call")

-- 3. A registered custom money item must actually be counted (and
-- removable) by the real inventory-cash helpers, not just recognized by
-- the low-level value function in isolation.
PZLinux.customMoneyItemsLoaded = nil
PZLinux.customMoneyItemIds = {}
SandboxVars = { PZLinux = { CustomMoneyItems = "WeightlessMoney.Money" } }

local function PZLinuxTestList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local customItem = PZLinuxTestItem("WeightlessMoney.Money", "Bill")
local player = {
    inventory = {
        items = { customItem },
        getItems = function(self) return PZLinuxTestList(self.items) end,
    },
}
player.getInventory = function() return player.inventory end

PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == 1,
    "a registered custom money item sitting in the player's inventory must be counted toward their cash total")
PZLinuxTestAssert(PZLinuxRemoveInventoryCash(player, 1) == 1,
    "a registered custom money item must actually be removable when spending cash, not just countable")

-- 4. The ATM's "gather money from bags before showing the deposit menu"
-- client step must use the same shared recognizer, not a hardcoded
-- Base.Money/Base.MoneyBundle-only check -- otherwise a custom money item
-- sitting in a bag would never get pulled into the main inventory before
-- the deposit menu opens.
local atmSource = readFile(luaRoot .. "/client/Context/World/ISContextAtmMenu.lua")
local onDepositeBlock = atmSource:match("function AtmUI:onDeposite%(%).-\nend")
PZLinuxTestAssert(onDepositeBlock, "AtmUI:onDeposite must exist")
PZLinuxTestAssert(onDepositeBlock:find("PZLinuxMoneyItemValue(item)", 1, true),
    "onDeposite must recognize money through the shared PZLinuxMoneyItemValue helper, not a hardcoded fullType check")
PZLinuxTestAssert(not onDepositeBlock:find('"Base.Money"', 1, true),
    "onDeposite must no longer hardcode Base.Money directly, or a custom money item would still be skipped here")

print("PZLinux ATM custom money items tests OK")
