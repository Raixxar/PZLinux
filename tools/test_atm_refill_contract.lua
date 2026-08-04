-- luacheck: globals ZombRand PZLinux
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_atm_refill_contract.lua$") or "."
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

-- Real physical cash mechanics (Base.Money / Base.MoneyBundle), same
-- machinery ATM withdrawals/deposits already use.
local function PZLinuxTestList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function PZLinuxTestItem(fullType)
    return { fullType = fullType, getFullType = function(self) return self.fullType end }
end

local function PZLinuxTestNewInventory()
    local container = { items = {} }
    function container:getItems() return PZLinuxTestList(self.items) end
    function container:AddItem(fullType)
        local item = PZLinuxTestItem(fullType)
        table.insert(self.items, item)
        return item
    end
    function container:Remove(item)
        for index = #self.items, 1, -1 do
            if self.items[index] == item then table.remove(self.items, index) end
        end
    end
    return container
end

PZLinuxSyncAddedContainerItem = function() return true end
PZLinuxRemoveContainerItem = function(container, item) container:Remove(item) return true end
rawset(_G, "instanceof", function() return false end)
dofile(luaRoot .. "/shared/PZLinux/PZLinuxInventoryCash.lua")

-- Slice covering everything touched by this feature: SetTypeFlags,
-- ClearState, ApplyAccept, ApplyCancel, ApplyDeposit (untested here, but
-- harmless to include), and the new PZLinuxContractsApplyAtmRefillDeposit.
local source = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local first = assert(source:find("function PZLinuxContractsSetTypeFlags", 1, true))
local last = assert(source:find("function PZLinuxContractsAcknowledgeCompletion", first, true))
assert(loadstring(source:sub(first, last - 1)))()

-- Mocks for everything PZLinuxContractsApplyAccept/ApplyCancel/
-- ApplyAtmRefillDeposit call out to, isolating just the ATM-refill logic
-- this session added.
PZLinux = {
    Economy = {
        contractCancelPenalty = function() return 1 end,
        contractCompleteReward = function() return 1 end,
    },
    Config = {
        ATM = { minCash = 10000, maxCash = 50000, restockPerHour = 500 },
        AtmRefill = { targetCashMin = 1, targetCashMax = 501 },
    },
}
PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function() return "atm-test-player" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
PZLinuxTransmitPlayerModData = function() end
PZLinuxContractsGetDefinition = function(contractId)
    return { id = contractId, difficulty = 2, reward = 2000, questName = "Refill an ATM", city = true }
end
PZLinuxContractsFindBoardContract = function(contractId)
    return { id = contractId, code = "EZG", questName = "Refill an ATM", cityId = 2 }, { generatedHour = 10 }
end
PZLinux.contractPreviews = {}
local previewAtmAmount = 3000
PZLinuxContractsGetPreview = function(_, contractId, requestId)
    return {
        ok = true,
        requestId = requestId,
        contractId = contractId,
        reward = 2000,
        atmAmount = previewAtmAmount,
        locationX = 418, locationY = 9869, locationZ = 0,
        locationCity = "Ekron", locationDescription = "E-Z GO Banking", locationDescriptionKey = "",
        locationId = "atm_ekron_ez_go_banking_01", locationPool = "atmRefill",
        info = "", infoName = "", infoCount = 0,
        note = "note", fullNote = "note",
        targetName = "", zombieToKill = 0,
    }
end
local worldContractsMarked = {}
PZLinuxContractsCreateWorldContract = function() return { id = "world-atm-1" } end
PZLinuxContractsReplaceContractNote = function() end
PZLinuxContractsRemoveBoardContract = function() end
PZLinuxContractsRemoveContractNote = function() end
PZLinuxContractsUpdateCompanyPrice = function() end
PZLinuxApplyReputationDelta = function() return 1 end
PZLinuxContractsMarkWorldContract = function(worldId, status)
    table.insert(worldContractsMarked, { worldId = worldId, status = status })
    return { id = worldId, status = status }
end

local bankBalance = 100000
PZLinuxLoadBankBalance = function() return bankBalance end
PZLinuxApplyBankDebit = function(_, amount, reason, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    if amount > bankBalance then
        return { ok = false, error = "not_enough_money", requestId = requestId, balance = bankBalance }
    end
    bankBalance = bankBalance - amount
    return { ok = true, amount = amount, balance = bankBalance, reason = reason, requestId = requestId }
end
PZLinuxApplyBankCredit = function(_, amount, reason, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    bankBalance = bankBalance + amount
    return { ok = true, amount = amount, balance = bankBalance, reason = reason, requestId = requestId }
end

local atmObjects = {}
local function PZLinuxTestMakeAtm(x, y, z)
    local atm = { modData = {}, x = x, y = y, z = z }
    function atm:getModData() return self.modData end
    atmObjects[#atmObjects + 1] = atm
    return atm
end
local theAtm = PZLinuxTestMakeAtm(418, 9869, 0)
PZLinuxFindAtmObject = function(atmRef)
    if not atmRef then return nil end
    for _, atm in ipairs(atmObjects) do
        if tonumber(atmRef.x) == atm.x and tonumber(atmRef.y) == atm.y and tonumber(atmRef.z) == atm.z then
            return atm
        end
    end
    return nil
end
PZLinuxAtmLoadCash = function(atm) return tonumber(atm and atm.modData.cash) or 0 end
PZLinuxAtmSaveCash = function(atm, amount)
    atm.modData.cash = math.max(0, math.floor(tonumber(amount) or 0))
    return atm.modData.cash
end

local inventory = PZLinuxTestNewInventory()
local modData = {}
local player = {
    getModData = function() return modData end,
    getInventory = function() return inventory end,
}

-- Accepting with less money than the contract requires must be refused
-- before anything is committed.
bankBalance = 1000
local tooPoor = PZLinuxContractsApplyAccept(player, { contractId = 13 }, "accept-too-poor")
PZLinuxTestAssert(not tooPoor.ok and tooPoor.error == "insufficient_funds_for_contract",
    "accepting the ATM refill contract without enough bank balance must be refused")
PZLinuxTestAssert(modData.PZLinuxActiveContract == nil or modData.PZLinuxActiveContract == 0,
    "a refused accept must not leave a half-committed contract")
PZLinuxTestAssert(bankBalance == 1000, "a refused accept must never touch the bank balance")

-- Accepting with enough money succeeds, but must never touch the bank or
-- hand over any cash automatically: the player has to go withdraw it
-- themselves, from whichever real ATM(s) they choose.
bankBalance = 100000
local accepted = PZLinuxContractsApplyAccept(player, { contractId = 13 }, "accept-ok")
PZLinuxTestAssert(accepted.ok, "accepting with enough bank balance must succeed")
PZLinuxTestAssert(accepted.contractAtmRefill == 1, "the accept response must expose the ATM refill type flag")
PZLinuxTestAssert(accepted.atmAmount == previewAtmAmount, "the accept response must expose the rolled amount")
PZLinuxTestAssert(modData.PZLinuxContractAtmRefill == 1, "modData must record this as an ATM refill contract")
PZLinuxTestAssert(modData.PZLinuxContractAtmAmount == previewAtmAmount, "modData must record the target amount")
PZLinuxTestAssert(bankBalance == 100000, "accepting must never debit the bank by itself")
PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == 0, "accepting must never hand over any physical cash by itself")

-- Depositing before having gathered any cash at all must be refused.
local correctAtmRef = { x = 418, y = 9869, z = 0 }
local emptyHandedDeposit = PZLinuxContractsApplyAtmRefillDeposit(player, correctAtmRef, "deposit-empty-handed")
PZLinuxTestAssert(not emptyHandedDeposit.ok and emptyHandedDeposit.error == "not_enough_inventory_cash",
    "depositing without having withdrawn any cash yet must be refused")

-- Simulate the player withdrawing the target sum from several ordinary ATMs
-- around town (the real withdrawal mechanic debits the bank and hands over
-- cash per ATM; only its net effect on bank balance and inventory cash is
-- reproduced here, since that mechanic itself is untouched by this feature).
PZLinuxApplyBankDebit(player, previewAtmAmount, "atm-withdrawal", "withdraw-1")
PZLinuxAddInventoryCash(player, previewAtmAmount)
PZLinuxTestAssert(bankBalance == 100000 - previewAtmAmount,
    "withdrawing from ordinary ATMs must debit the bank exactly like it always does")

-- Depositing at the wrong ATM must be refused, and must not touch money.
local wrongAtmRef = { x = 999, y = 999, z = 0 }
local wrongAtm = PZLinuxContractsApplyAtmRefillDeposit(player, wrongAtmRef, "deposit-wrong-atm")
PZLinuxTestAssert(not wrongAtm.ok and wrongAtm.error == "wrong_atm",
    "depositing at any ATM other than the hardcoded target must be refused")
PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == previewAtmAmount,
    "a refused deposit must not remove any physical cash")

-- Depositing without enough physical cash (e.g. some was lost/dropped) must
-- be refused without partially consuming what remains.
PZLinuxRemoveInventoryCash(player, 1)
local shortDeposit = PZLinuxContractsApplyAtmRefillDeposit(player, correctAtmRef, "deposit-short")
PZLinuxTestAssert(not shortDeposit.ok and shortDeposit.error == "not_enough_inventory_cash",
    "depositing with less cash than promised must be refused")
PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == previewAtmAmount - 1,
    "a refused deposit for insufficient cash must not remove any of the remaining cash")

-- Gather the missing dollar and complete the deposit at the correct ATM: the
-- withdrawn sum is refunded and the target ATM's own reserve goes up by the
-- same amount, and the contract advances to "ready to complete". The
-- player's net change across withdrawing elsewhere and depositing here is
-- zero on the principal -- only the (separately paid) reward is a net gain.
PZLinuxAddInventoryCash(player, 1)
local balanceBeforeDeposit = bankBalance
local deposit = PZLinuxContractsApplyAtmRefillDeposit(player, correctAtmRef, "deposit-ok")
PZLinuxTestAssert(deposit.ok and deposit.amount == previewAtmAmount, "a valid deposit at the correct ATM must succeed")
PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == 0, "depositing must remove all the withdrawn physical cash")
PZLinuxTestAssert(bankBalance == balanceBeforeDeposit + previewAtmAmount,
    "depositing must refund exactly the withdrawn amount to the bank")
PZLinuxTestAssert(bankBalance == 100000,
    "the player's net change from withdrawing elsewhere then depositing here must be zero")
PZLinuxTestAssert(PZLinuxAtmLoadCash(theAtm) == previewAtmAmount,
    "the target ATM's own cash reserve must increase by the deposited amount")
PZLinuxTestAssert(modData.PZLinuxActiveContract == 9, "a successful deposit must advance the contract to ready-to-complete")
PZLinuxTestAssert(#worldContractsMarked > 0 and worldContractsMarked[#worldContractsMarked].status == "deposited",
    "a successful deposit must mark the world contract as deposited")

-- Depositing again (nothing left to deposit, contract no longer at step 1)
-- must be refused rather than silently succeeding a second time.
local secondDeposit = PZLinuxContractsApplyAtmRefillDeposit(player, correctAtmRef, "deposit-again")
PZLinuxTestAssert(not secondDeposit.ok and secondDeposit.error == "no_active_contract",
    "depositing again after the contract already advanced must be refused")

-- Crediting the target ATM must clamp at the general ATM.maxCash rather
-- than exceed it (an ATM already near its cap, e.g. from its own slow
-- regen, must never be pushed past the configured limit just because a
-- contract completed there). It must NOT clamp at AtmRefill.targetCashMax:
-- that only governs this ATM's near-empty starting roll (1-501 $ by
-- default) -- a real deposit (always far larger) must still be able to
-- raise its balance well above that.
PZLinuxAtmSaveCash(theAtm, 49000) -- close to the mocked general maxCash of 50000
do
    local clampInventory = PZLinuxTestNewInventory()
    local clampModData = {}
    local clampPlayer = {
        getModData = function() return clampModData end,
        getInventory = function() return clampInventory end,
    }
    bankBalance = 100000
    PZLinuxContractsApplyAccept(clampPlayer, { contractId = 13 }, "accept-for-clamp")
    PZLinuxAddInventoryCash(clampPlayer, previewAtmAmount)
    local clampDeposit = PZLinuxContractsApplyAtmRefillDeposit(clampPlayer, correctAtmRef, "deposit-clamp")
    PZLinuxTestAssert(clampDeposit.ok, "depositing into a near-full ATM must still succeed for the player")
    PZLinuxTestAssert(PZLinuxAtmLoadCash(theAtm) == 50000,
        "the target ATM's cash must clamp at the general ATM.maxCash instead of exceeding it")
end

-- Cancelling has nothing special to refund: accepting never touched the
-- bank or inventory, so any cash the player withdrew along the way (using
-- the ordinary mechanic) remains simply theirs, exactly as it would outside
-- this contract.
modData = {}
inventory = PZLinuxTestNewInventory()
player = {
    getModData = function() return modData end,
    getInventory = function() return inventory end,
}
bankBalance = 100000
PZLinuxContractsApplyAccept(player, { contractId = 13 }, "accept-for-cancel")
PZLinuxApplyBankDebit(player, previewAtmAmount, "atm-withdrawal", "withdraw-2")
PZLinuxAddInventoryCash(player, previewAtmAmount)
local balanceBeforeCancel = bankBalance
local cancelled = PZLinuxContractsApplyCancel(player, "cancel-mid-flow")
PZLinuxTestAssert(cancelled.ok, "cancelling an active ATM refill contract must succeed")
PZLinuxTestAssert(bankBalance == balanceBeforeCancel,
    "cancelling must not itself move any money -- it never took any in the first place")
PZLinuxTestAssert(PZLinuxCountInventoryCash(player) == previewAtmAmount,
    "cancelling must not touch cash the player legitimately withdrew on their own")

-- Regression check for the reported MP bug: after a reconnect, the client's
-- local modData can be stale (PZLinuxContractAtmRefill/PZLinuxActiveContract
-- both reading 0 despite the contract still being active server-side),
-- because unlike computers, the ATM never asked the server to resynchronize
-- contract state on open. The button must therefore be (re-)evaluated once
-- after an explicit PZLinuxRequestContractSync, not only from whatever
-- modData happened to already be loaded when the ATM screen first opened.
local atmMenuSource = PZLinuxTestRead(luaRoot .. "/client/Context/World/ISContextAtmMenu.lua")
PZLinuxTestAssert(atmMenuSource:find("PZLinuxRequestContractSync%(playerObj, function%(%)"),
    "opening the ATM main menu must resynchronize contract state, like computers already do")
local showMainMenuBlock = atmMenuSource:match("function AtmUI:showMainMenu%(%).-\nend")
PZLinuxTestAssert(showMainMenuBlock and showMainMenuBlock:find("self:ensureContractRefillButton%(%)"),
    "the refill button must be (re-)checked both synchronously and after the resync callback")
local ensureButtonBlock = atmMenuSource:match("function AtmUI:ensureContractRefillButton%(%).-\nend")
PZLinuxTestAssert(ensureButtonBlock and ensureButtonBlock:find("if self%.contractRefillButton then return end"),
    "re-checking the refill button must be idempotent and never create a duplicate")

-- Showing all three buttons (withdraw/deposit/refill) at once was confusing
-- and pushed a button past the visible ATM screen; when the refill contract
-- matches, the ordinary withdraw/deposit buttons must be hidden entirely.
PZLinuxTestAssert(ensureButtonBlock
    and ensureButtonBlock:find("self%.withdrawalButton:setVisible%(false%)")
    and ensureButtonBlock:find("self%.depositeButton:setVisible%(false%)"),
    "matching the ATM refill contract must hide the ordinary withdraw/deposit buttons")

print("PZLinux ATM refill contract tests OK")
