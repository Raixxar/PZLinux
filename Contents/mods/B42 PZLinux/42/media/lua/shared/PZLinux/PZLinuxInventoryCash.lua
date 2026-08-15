PZLinux = PZLinux or {}

local function PZLinuxInventoryCashNestedContainer(item)
    if not item then return nil end

    if instanceof and instanceof(item, "InventoryContainer") then
        return item:getInventory()
    end
    if type(item) == "table" and item.getInventory then
        return item:getInventory()
    end
    return nil
end

-- Lets a server admin register a third-party mod's own currency item as
-- valid PZLinux cash, via a sandbox option (PZLinux.CustomMoneyItems,
-- free-text): a comma-separated list of item IDs (module.ItemName), each
-- treated as worth $1 for ATM deposit/withdrawal and everywhere else this
-- mod counts "cash on hand". This is the supported way to make PZLinux
-- compatible with a mod that reskins or replaces vanilla money -- e.g. a
-- "weightless money" mod that ships its own item (so it can coexist with
-- normal-weight Base.Money) instead of patching the vanilla one, which
-- this mod has no way to discover on its own without being told.
--
-- Same lazy-load pattern as PZLinuxDarkWebLoadCustomItems
-- (PZLinuxDarkWebData.lua): SandboxVars isn't populated yet when this file
-- is first parsed at mod boot, so this must never be read at file scope --
-- only from real gameplay code, once SandboxVars reflects the actual
-- joined server/save. Idempotent (guarded by PZLinux.customMoneyItemsLoaded)
-- so every caller can invoke it defensively without re-parsing every call.
PZLinux.customMoneyItemIds = PZLinux.customMoneyItemIds or {}

local function PZLinuxLoadCustomMoneyItems()
    if PZLinux.customMoneyItemsLoaded then return end
    PZLinux.customMoneyItemsLoaded = true

    local raw = SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.CustomMoneyItems
    if not raw or raw == "" then return end

    for entry in tostring(raw):gmatch("[^,]+") do
        local itemName = entry:match("^%s*([%w%._]+)%s*$")
        if not itemName then
            print("[PZLinux ATM] custom money item entry could not be parsed (expected Base.ItemName): " .. tostring(entry))
        elseif not (getScriptManager and getScriptManager():FindItem(itemName)) then
            print("[PZLinux ATM] custom money item ignored (unknown item): " .. tostring(itemName))
        else
            PZLinux.customMoneyItemIds[itemName] = true
            print("[PZLinux ATM] custom money item registered: " .. itemName)
        end
    end
end

-- Recognizes any item this mod treats as spendable cash: PZLinux's own
-- Base.Money ($1) and Base.MoneyBundle ($100), any item whose vanilla
-- "Type" tag is Money regardless of which mod/module it actually comes
-- from (the same flag the base game itself uses to mark an item as
-- currency, so most money-reskin mods keep it even while changing the
-- item's weight/name/module), and anything explicitly registered through
-- PZLinux.CustomMoneyItems above. Returns the $ value of a single
-- instance of the item, or 0 if it isn't recognized as money at all.
function PZLinuxMoneyItemValue(item)
    if not item then return 0 end
    PZLinuxLoadCustomMoneyItems()

    local fullType = item:getFullType()
    if fullType == "Base.MoneyBundle" then return 100 end
    if fullType == "Base.Money" then return 1 end
    if item:getType() == "Money" then return 1 end
    if PZLinux.customMoneyItemIds[fullType] then return 1 end
    return 0
end

local function PZLinuxInventoryCashCollect(container, entries, visited)
    if not container or visited[container] then return end
    visited[container] = true

    local items = container:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local value = PZLinuxMoneyItemValue(item)
            if value == 100 then
                table.insert(entries.bundles, { container = container, item = item })
                entries.total = entries.total + value
            elseif value > 0 then
                table.insert(entries.singles, { container = container, item = item })
                entries.total = entries.total + value
            end

            local nested = PZLinuxInventoryCashNestedContainer(item)
            if nested then
                PZLinuxInventoryCashCollect(nested, entries, visited)
            end
        end
    end
end

local function PZLinuxInventoryCashEntries(player)
    local playerObj = PZLinuxGetPlayer(player)
    local entries = { bundles = {}, singles = {}, total = 0 }
    if not playerObj then return entries, nil end

    local inventory = playerObj:getInventory()
    if inventory then
        PZLinuxInventoryCashCollect(inventory, entries, {})
    end
    return entries, inventory
end

local function PZLinuxInventoryCashRollbackAdded(container, addedItems)
    for index = #addedItems, 1, -1 do
        PZLinuxRemoveContainerItem(container, addedItems[index])
    end
end

local function PZLinuxInventoryCashAddToContainer(container, amount)
    local addedItems = {}
    local remaining = amount

    while remaining >= 100 do
        local item = container:AddItem("Base.MoneyBundle")
        if not item or not PZLinuxSyncAddedContainerItem(container, item) then
            PZLinuxInventoryCashRollbackAdded(container, addedItems)
            return 0
        end
        table.insert(addedItems, item)
        remaining = remaining - 100
    end

    while remaining > 0 do
        local item = container:AddItem("Base.Money")
        if not item or not PZLinuxSyncAddedContainerItem(container, item) then
            PZLinuxInventoryCashRollbackAdded(container, addedItems)
            return 0
        end
        table.insert(addedItems, item)
        remaining = remaining - 1
    end

    return amount
end

function PZLinuxCountInventoryCash(player)
    local entries = PZLinuxInventoryCashEntries(player)
    return entries.total
end

function PZLinuxAddInventoryCash(player, amount)
    amount = PZLinuxNormalizeMoney(amount)
    if amount <= 0 then return 0 end

    local _, inventory = PZLinuxInventoryCashEntries(player)
    if not inventory then return 0 end
    return PZLinuxInventoryCashAddToContainer(inventory, amount)
end

function PZLinuxRemoveInventoryCash(player, amount)
    amount = PZLinuxNormalizeMoney(amount)
    if amount <= 0 then return 0 end

    local entries, inventory = PZLinuxInventoryCashEntries(player)
    if not inventory or entries.total < amount then return 0 end

    local removalPlan = {}
    local remaining = amount
    local bundleIndex = 1
    local singleIndex = 1

    while remaining >= 100 and bundleIndex <= #entries.bundles do
        table.insert(removalPlan, entries.bundles[bundleIndex])
        bundleIndex = bundleIndex + 1
        remaining = remaining - 100
    end

    while remaining > 0 and singleIndex <= #entries.singles do
        table.insert(removalPlan, entries.singles[singleIndex])
        singleIndex = singleIndex + 1
        remaining = remaining - 1
    end

    local change = 0
    if remaining > 0 and bundleIndex <= #entries.bundles then
        table.insert(removalPlan, entries.bundles[bundleIndex])
        change = 100 - remaining
        remaining = 0
    end
    if remaining > 0 then return 0 end

    if change > 0 and PZLinuxInventoryCashAddToContainer(inventory, change) ~= change then
        return 0
    end

    for _, entry in ipairs(removalPlan) do
        PZLinuxRemoveContainerItem(entry.container, entry.item)
    end
    return amount
end
