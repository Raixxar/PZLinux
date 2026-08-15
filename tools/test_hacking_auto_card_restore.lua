-- Regression test for a player-reported money exploit (v1.0.10): "when I
-- close the computer after Auto + Transfer, my credit cards come back in
-- my inventory, and I can redo Auto with them indefinitely."
--
-- Root cause: the interrupted-session rollback (PZLinuxApplyInterrupted
-- SessionRollbacks) exists to make a player whole after a genuine SERVER
-- RESTART mid-hack -- PZLinux.hackingSessions is memory-only while the
-- matching sessions.hacking flag is persisted in modData, so a restart
-- between "cards removed" and "hack resolved" would otherwise lose the
-- cards forever with no trace they were ever taken. But the rollback fired
-- on ANY later idempotent command finding sessions.hacking set with no
-- matching PZLinux.hackingSessions[key] entry -- true both after a real
-- restart (correct) AND after a normal, fully successful Auto+Transfer if
-- anything else ever let those two independently-tracked flags drift apart
-- within the same running process (the exact trigger for that drift was
-- never fully pinned down, but a locked-out manual hack was confirmed to
-- produce the mirror-image asymmetry, and this shared machinery is also
-- the prime suspect the code already flagged, unconfirmed, for an
-- analogous "Blackjack bet sometimes not being taken" report).
--
-- The fix doesn't depend on knowing the exact trigger: every interrupted-
-- session entry is now stamped with the boot ID active when it was
-- written (a bare table's own tostring(), unique for the life of this Lua
-- state), and the rollback only fires once that boot ID no longer matches
-- the CURRENT one -- i.e. only across an actual restart, which is the only
-- way a memory-only table can legitimately forget an entry mid-process.
-- Also fixes the confirmed asymmetry itself (a locked-out manual hack
-- cleared the persisted flag but left the dead session sitting in memory)
-- so PZLinuxHackingClearSession/PZLinuxClearInterruptedSession are always
-- called together, with no path left that calls only one of the two.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_hacking_auto_card_restore.lua$") or "."
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

-- ---------------------------------------------------------------------
-- 1. Source checks: every rollback condition (all four session types)
-- requires a boot ID mismatch, not just a missing memory session; the
-- lock-out path clears both the memory and interrupted-session state.
-- ---------------------------------------------------------------------

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

PZLinuxTestAssert(variablesSource:find("PZLinux.serverBootId = PZLinux.serverBootId or tostring({})", 1, true),
    "a per-boot unique id must be declared")
PZLinuxTestAssert(variablesSource:find("data.bootId = PZLinux.serverBootId", 1, true),
    "PZLinuxRegisterInterruptedSession must stamp every entry with the current boot id")

for _, sessionType in ipairs({ "blackjack", "race", "hacking", "poker" }) do
    PZLinuxTestAssert(
        variablesSource:find(sessionType .. ".bootId ~= PZLinux.serverBootId", 1, true),
        "the " .. sessionType .. " rollback must require a boot id mismatch before restoring anything")
end

PZLinuxTestAssert(
    variablesSource:find("PZLinuxHackingClearSession(playerObj)\n            PZLinuxClearInterruptedSession(playerObj, \"hacking\")", 1, true),
    "a locked-out (max tries exceeded) manual hack must clear the in-memory session, not just the persisted interrupted-session flag")

-- ---------------------------------------------------------------------
-- 2. Functional test: a same-process anomaly that empties
-- PZLinux.hackingSessions while sessions.hacking is still set (whatever
-- the exact real-world trigger) must NOT restore cards; a genuine restart
-- (fresh boot id) still must.
-- ---------------------------------------------------------------------

PZLinux = { Config = { ATM = { minCash = 0, maxCash = 100 } } }
Perks = { Electricity = "Electricity" }
function ZombRand(a, b) if b then return a end return 0 end
addXp = function() end
getGameTime = function() return { getWorldAgeHours = function() return 0 end } end

local FakeItem = {}
FakeItem.__index = FakeItem
function FakeItem:getFullType() return self.fullType end
function FakeItem:getName() return "Credit Card" end

local FakeItems = {}
FakeItems.__index = FakeItems
function FakeItems:size() return #self.list end
function FakeItems:get(i) return self.list[i + 1] end

local FakeInventory = {}
FakeInventory.__index = FakeInventory
function FakeInventory:getItems() return self.itemsObj end
function FakeInventory:AddItem(fullType)
    local item = setmetatable({ fullType = fullType }, FakeItem)
    table.insert(self.itemsObj.list, item)
    return item
end
function FakeInventory:Remove(item)
    for i, it in ipairs(self.itemsObj.list) do
        if it == item then table.remove(self.itemsObj.list, i) break end
    end
end

local function buildInventory(cardTypes)
    local list = {}
    for _, t in ipairs(cardTypes) do
        table.insert(list, setmetatable({ fullType = t }, FakeItem))
    end
    local inv = setmetatable({}, FakeInventory)
    inv.itemsObj = setmetatable({ list = list }, FakeItems)
    return inv
end

local playerModData = { pzlinux = { player = {} } }
local FakePlayer = {}
FakePlayer.__index = FakePlayer
function FakePlayer:getModData() return playerModData end
function FakePlayer:getInventory() return self.inventoryObj end
function FakePlayer:getPerkLevel(_perk) return 0 end
function FakePlayer:getUsername() return "TestPlayer" end

local fakePlayer = setmetatable(
    { inventoryObj = buildInventory({ "Base.CreditCard", "Base.CreditCard", "Base.CreditCard" }) }, FakePlayer)

PZLinux.getPlayer = function(p) return p end

local function extract(pattern)
    local block = variablesSource:match(pattern)
    assert(block, "pattern not found: " .. pattern)
    return block
end

local pieces = {
    extract("PZLinux%.hackingSessions = .-\n"),
    extract("PZLinux%.serverBootId = .-\n"),
    extract("function PZLinux%.getModData.-\nend\n"),
    extract("function PZLinuxGetPlayer.-\nend\n"),
    extract("function PZLinuxGetModData.-\nend\n"),
    extract("function PZLinuxGetInterruptedSessions.-\nend\n"),
    extract("function PZLinuxRegisterInterruptedSession.-\nend\n"),
    extract("function PZLinuxClearInterruptedSession.-\nend\n"),
    extract("function PZLinuxApplyInterruptedSessionRollbacks.-\nend\n"),
    extract("PZLinuxHackingCardTypes = .-\n}\n"),
    extract("function PZLinuxHackingIsCard.-\nend\n"),
    extract("function PZLinuxHackingCountCards.-\nend\n"),
    extract("function PZLinuxHackingRemoveCards.-\nend\n"),
    extract("function PZLinuxHackingGetSession.-\nend\n"),
    extract("function PZLinuxHackingSetSession.-\nend\n"),
    extract("function PZLinuxHackingClearSession.-\nend\n"),
    (extract("local function PZLinuxHackingRejectIfPendingTransfer.-\nend\n"):gsub("^local function", "function", 1)),
    extract("function PZLinuxHackingAuto.-\nend\n"),
    extract("function PZLinuxHackingTransfer.-\nend\n"),
}

function PZLinuxGetPlayerKey(player) return player and player:getUsername() or "?" end
function PZLinuxNormalizeMoney(x) return math.floor(x) end
function PZLinuxLoadBankBalance(player) return playerModData.pzlinux.player.bankBalance or 0 end
function PZLinuxSetBankBalance(player, amount) playerModData.pzlinux.player.bankBalance = amount return amount end
function PZLinuxApplyBankCredit(player, amount, reason, requestId)
    local prev = PZLinuxLoadBankBalance(player)
    local bal = PZLinuxSetBankBalance(player, prev + amount)
    return { ok = true, amount = amount, balance = bal, previousBalance = prev, reason = reason, requestId = requestId }
end
function PZLinuxRemoveInventoryItem(player, item)
    player:getInventory():Remove(item)
    return true
end
function PZLinuxTransmitPlayerModData(_player) end
function PZLinuxSyncAddedInventoryItem(_player, _card) return true end

for _, piece in ipairs(pieces) do
    assert(loadstring(piece))()
end

-- Auto removes the cards and registers the interrupted session.
PZLinuxHackingAuto(fakePlayer, "req-auto-1")
PZLinuxTestAssert(fakePlayer:getInventory():getItems():size() == 0, "Auto must remove all cards")

-- Simulate whatever empties the memory session WITHOUT a real restart --
-- the exact mechanism doesn't matter, this is exactly the ambiguity the
-- fix removes.
PZLinux.hackingSessions[PZLinuxGetPlayerKey(fakePlayer)] = nil
local sameProcessRollback = PZLinuxApplyInterruptedSessionRollbacks(fakePlayer)
PZLinuxTestAssert(not (sameProcessRollback.applied and sameProcessRollback.applied.hackingCards),
    "a same-process anomaly must not trigger a card restore")
PZLinuxTestAssert(fakePlayer:getInventory():getItems():size() == 0,
    "cards must stay gone when the boot id still matches (no real restart happened)")

-- A genuine restart (fresh memory tables AND a fresh boot id) must still
-- restore the cards -- the safety net this rollback exists for.
fakePlayer.inventoryObj = buildInventory({})
PZLinux.hackingSessions = {}
PZLinux.serverBootId = tostring({})
local restartRollback = PZLinuxApplyInterruptedSessionRollbacks(fakePlayer)
PZLinuxTestAssert(restartRollback.applied and restartRollback.applied.hackingCards == 3,
    "a genuine restart must still restore the 3 cards that were mid-hack when it happened")

print("PZLinux hacking auto card-restore exploit tests OK")
