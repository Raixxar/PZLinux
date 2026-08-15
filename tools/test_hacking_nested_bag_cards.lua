-- Regression test locking in a deliberate design decision. A player
-- reported carrying credit cards that Hacking still reported as "No
-- Credit Card..." -- they were inside an equipped bag rather than the
-- top-level inventory. An initial fix made PZLinuxHackingCountCards/
-- RemoveCards recurse into nested containers to find them there too, but
-- that was reverted on request: this mod consistently only ever checks
-- the player's direct, top-level inventory for every other "do I have
-- item X" check (Dark Web's sell/buy matching, Contract deposit checks,
-- etc.), and the preference was to keep Hacking consistent with that
-- rather than making it the one feature that reaches into bags -- cards
-- need to be in the main inventory, same as everywhere else in this mod.
-- This test locks in that a card inside a bag is correctly NOT found,
-- while one directly in the main inventory still is.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_hacking_nested_bag_cards.lua$") or "."
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

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

local function extract(pattern)
    local block = variablesSource:match(pattern)
    assert(block, "pattern not found: " .. pattern)
    return block
end

-- Source-level guard: neither function may reach into a nested container
-- (no "item.getInventory" existence check / no recursive helper call --
-- that specific pattern is unique to the reverted recursive version).
local countBlock = extract("function PZLinuxHackingCountCards.-\nend\n")
local removeBlock = extract("function PZLinuxHackingRemoveCards.-\nend\n")
PZLinuxTestAssert(not countBlock:find("item.getInventory", 1, true)
    and not countBlock:find("InContainer", 1, true),
    "PZLinuxHackingCountCards must not reach into nested containers -- main inventory only, by design")
PZLinuxTestAssert(not removeBlock:find("item.getInventory", 1, true)
    and not removeBlock:find("FromContainer", 1, true),
    "PZLinuxHackingRemoveCards must not reach into nested containers -- main inventory only, by design")

PZLinuxHackingCardTypes = {
    ["Base.CreditCard"] = true,
    ["Base.CreditCard_Stolen"] = true,
}

local pieces = {
    extract("function PZLinuxHackingIsCard.-\nend\n"),
    countBlock,
    removeBlock,
}

local FakeItem = {}
FakeItem.__index = FakeItem
function FakeItem:getFullType() return self.fullType end
function FakeItem:getName() return self.displayName or self.fullType end
function FakeItem:getInventory() return self.subInventory end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.list end
function FakeItems:get(i) return self.list[i + 1] end

local function buildInventory(items)
    local inv = {}
    inv.itemsObj = setmetatable({ list = items }, FakeItems)
    function inv:getItems() return self.itemsObj end
    function inv:Remove(item)
        for i, it in ipairs(self.itemsObj.list) do
            if it == item then table.remove(self.itemsObj.list, i) break end
        end
    end
    return inv
end

local function makeCard(fullType)
    return setmetatable({ fullType = fullType }, FakeItem)
end

local function makeBag(cardsInside)
    local bag = setmetatable({ fullType = "Base.Bag_Backpack" }, FakeItem)
    bag.subInventory = buildInventory(cardsInside)
    return bag
end

PZLinuxGetPlayer = function(p) return p end
PZLinuxRemoveInventoryItem = function(_player, item)
    return fakePlayerInventoryRoot:Remove(item) or true
end

for _, piece in ipairs(pieces) do
    assert(loadstring(piece))()
end

-- 1 card directly in the main inventory, 3 more inside an equipped bag
-- that's sitting in that same main inventory.
local bag = makeBag({ makeCard("Base.CreditCard"), makeCard("Base.CreditCard_Stolen"), makeCard("Base.CreditCard") })
fakePlayerInventoryRoot = buildInventory({ makeCard("Base.CreditCard"), bag })

local fakePlayer = { inventoryObj = fakePlayerInventoryRoot }
function fakePlayer:getInventory() return self.inventoryObj end

local count = PZLinuxHackingCountCards(fakePlayer)
PZLinuxTestAssert(count == 1,
    "only the card directly in the main inventory must be counted, not the 3 inside the bag; got " .. tostring(count))

local removed, firstName = PZLinuxHackingRemoveCards(fakePlayer, 5)
PZLinuxTestAssert(removed == 1, "only the direct card must be removable, requesting more must not reach into the bag; removed " .. tostring(removed))
PZLinuxTestAssert(firstName ~= nil, "a display name must still be captured for the direct card")
PZLinuxTestAssert(bag.subInventory:getItems():size() == 3,
    "the 3 cards inside the bag must be left completely untouched")

print("PZLinux Hacking main-inventory-only card detection tests OK")
