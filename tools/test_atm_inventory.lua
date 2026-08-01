local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_atm_inventory.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
    end
end

local function PZLinuxTestList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function PZLinuxTestItem(fullType, nested)
    return {
        fullType = fullType,
        nested = nested,
        getFullType = function(self) return self.fullType end,
        getType = function(self) return self.fullType:match("[^.]+$") end,
        getInventory = function(self) return self.nested end,
    }
end

local function PZLinuxTestContainer()
    local container = { items = {}, addCalls = 0 }

    function container:getItems()
        return PZLinuxTestList(self.items)
    end

    function container:AddItem(fullType)
        self.addCalls = self.addCalls + 1
        if self.failAtAdd and self.addCalls >= self.failAtAdd then return nil end
        local item = PZLinuxTestItem(fullType)
        table.insert(self.items, item)
        return item
    end

    function container:Remove(item)
        for index = #self.items, 1, -1 do
            if self.items[index] == item then
                table.remove(self.items, index)
                return
            end
        end
    end

    return container
end

local addedPackets = {}
local removedPackets = {}

PZLinuxGetPlayer = function(value) return value end
PZLinuxNormalizeMoney = function(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end
PZLinuxSyncAddedContainerItem = function(container, item)
    table.insert(addedPackets, { container = container, item = item })
    return true
end
PZLinuxRemoveContainerItem = function(container, item)
    table.insert(removedPackets, { container = container, item = item })
    container:Remove(item)
    return true
end
rawset(_G, "instanceof", function(item, className)
    return className == "InventoryContainer" and item.nested ~= nil
end)

dofile(luaRoot .. "/shared/PZLinux/PZLinuxInventoryCash.lua")

local root = PZLinuxTestContainer()
local bag = PZLinuxTestContainer()
local bagItem = PZLinuxTestItem("Base.Bag_Schoolbag", bag)
table.insert(root.items, bagItem)
table.insert(bag.items, PZLinuxTestItem("Base.MoneyBundle"))
for _ = 1, 50 do table.insert(bag.items, PZLinuxTestItem("Base.Money")) end

local player = { getInventory = function() return root end }
PZLinuxTestAssertEqual(PZLinuxCountInventoryCash(player), 150, "cash in carried bags must be counted")
PZLinuxTestAssertEqual(PZLinuxRemoveInventoryCash(player, 125), 125, "deposit must remove the requested cash")
PZLinuxTestAssertEqual(PZLinuxCountInventoryCash(player), 25, "deposit must leave the correct bag balance")
PZLinuxTestAssertEqual(#removedPackets, 26, "deposit must synchronize each removed physical item")
for _, packet in ipairs(removedPackets) do
    PZLinuxTestAssertEqual(packet.container, bag, "nested cash must be removed from its real container")
end

addedPackets = {}
PZLinuxTestAssertEqual(PZLinuxAddInventoryCash(player, 205), 205, "withdrawal must create the requested cash")
PZLinuxTestAssertEqual(PZLinuxCountInventoryCash(player), 230, "withdrawal must update physical cash")
PZLinuxTestAssertEqual(#addedPackets, 7, "withdrawal must synchronize bundles and notes")
for _, packet in ipairs(addedPackets) do
    PZLinuxTestAssertEqual(packet.container, root, "withdrawn cash must use the player inventory")
end

root = PZLinuxTestContainer()
table.insert(root.items, PZLinuxTestItem("Base.MoneyBundle"))
table.insert(root.items, PZLinuxTestItem("Base.MoneyBundle"))
player = { getInventory = function() return root end }
PZLinuxTestAssertEqual(PZLinuxRemoveInventoryCash(player, 150), 150, "a bundle may be split for an exact deposit")
PZLinuxTestAssertEqual(PZLinuxCountInventoryCash(player), 50, "bundle change must be returned")

root = PZLinuxTestContainer()
root.failAtAdd = 2
player = { getInventory = function() return root end }
PZLinuxTestAssertEqual(PZLinuxAddInventoryCash(player, 200), 0, "partial cash creation must fail atomically")
PZLinuxTestAssertEqual(PZLinuxCountInventoryCash(player), 0, "partial withdrawal cash must be rolled back")

local runtimeFile = assert(io.open(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua", "rb"))
local runtimeSource = runtimeFile:read("*a")
runtimeFile:close()
local withdrawal = runtimeSource:match("function PZLinuxApplyAtmWithdrawal.-\nend")
PZLinuxTestAssertEqual(withdrawal ~= nil, true, "ATM withdrawal handler must exist")
PZLinuxTestAssertEqual(withdrawal:find("PZLinuxAddInventoryCash") < withdrawal:find("PZLinuxSetBankBalance"), true,
    "physical cash must be created before debiting the bank")
PZLinuxTestAssertEqual(withdrawal:find('error = "cash_add_failed"') ~= nil, true,
    "cash creation failure must leave the economy untouched")

print("PZLinux ATM inventory tests OK")
