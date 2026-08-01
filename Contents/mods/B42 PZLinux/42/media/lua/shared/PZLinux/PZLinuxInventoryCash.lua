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

local function PZLinuxInventoryCashCollect(container, entries, visited)
    if not container or visited[container] then return end
    visited[container] = true

    local items = container:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local fullType = item:getFullType()
            if fullType == "Base.MoneyBundle" then
                table.insert(entries.bundles, { container = container, item = item })
                entries.total = entries.total + 100
            elseif fullType == "Base.Money" or item:getType() == "Money" then
                table.insert(entries.singles, { container = container, item = item })
                entries.total = entries.total + 1
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
