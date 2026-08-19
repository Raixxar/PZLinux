PZLinux = PZLinux or {}

local PZLINUX_DELIVERY_DATA = "PZLinuxDeliveryLedger"
local PZLINUX_DELIVERY_VERSION = 2
local PZLINUX_DELIVERY_MAX_HISTORY = 512

local function PZLinuxDeliveryPlayerKey(player)
    if PZLinuxGetCharacterKey then
        local characterKey = PZLinuxGetCharacterKey(player, true)
        if characterKey and characterKey ~= "" then return tostring(characterKey) end
    end
    if PZLinuxGetPlayerKey then return tostring(PZLinuxGetPlayerKey(player)) end
    if player and player.getUsername then return tostring(player:getUsername()) end
    return tostring(player or "unknown")
end

local function PZLinuxDeliveryAccountKey(player)
    if PZLinuxGetCharacterAccount then return tostring(PZLinuxGetCharacterAccount(player)) end
    if PZLinuxGetPlayerKey then return tostring(PZLinuxGetPlayerKey(player)) end
    if player and player.getUsername then return tostring(player:getUsername()) end
    return tostring(player or "unknown")
end

local function PZLinuxDeliveryWorldHour()
    return getGameTime and getGameTime():getWorldAgeHours() or 0
end

function PZLinuxDeliveryGetLedger()
    local ledger = ModData.getOrCreate(PZLINUX_DELIVERY_DATA)
    ledger.version = PZLINUX_DELIVERY_VERSION
    ledger.nextId = math.max(1, tonumber(ledger.nextId) or 1)
    ledger.players = ledger.players or {}
    ledger.receipts = ledger.receipts or {}
    ledger.receiptRequests = ledger.receiptRequests or {}
    ledger.redeemedReceipts = ledger.redeemedReceipts or {}
    ledger.legacyClaims = ledger.legacyClaims or {}
    return ledger
end

local function PZLinuxDeliveryMigrateLegacyPlayerRecord(ledger, player, playerKey)
    local accountKey = PZLinuxDeliveryAccountKey(player)
    if accountKey == playerKey or ledger.legacyClaims[accountKey] then return end

    local legacyRecord = ledger.players[accountKey]
    if type(legacyRecord) ~= "table" then return end

    local targetRecord = ledger.players[playerKey]
    if type(targetRecord) ~= "table" then
        targetRecord = legacyRecord
        ledger.players[playerKey] = targetRecord
    else
        targetRecord.orders = targetRecord.orders or {}
        for _, order in ipairs(legacyRecord.orders or {}) do
            table.insert(targetRecord.orders, order)
        end
        targetRecord.migrations = targetRecord.migrations or {}
        for migration, value in pairs(legacyRecord.migrations or {}) do
            if targetRecord.migrations[migration] == nil then
                targetRecord.migrations[migration] = value
            end
        end
    end

    targetRecord.account = accountKey
    targetRecord.characterId = PZLinuxGetCharacterId and PZLinuxGetCharacterId(player, true) or nil
    targetRecord.nativeKey = PZLinuxGetCharacterNativeKey and PZLinuxGetCharacterNativeKey(player) or nil
    ledger.players[accountKey] = nil
    ledger.legacyClaims[accountKey] = playerKey

    for _, receipt in pairs(ledger.receipts) do
        if receipt.player == accountKey then
            receipt.player = playerKey
            if receipt.requestId then
                local requestKey = table.concat({ playerKey, receipt.source, tostring(receipt.requestId) }, ":")
                ledger.receiptRequests[requestKey] = receipt.id
            end
        end
    end
    for _, redemption in pairs(ledger.redeemedReceipts) do
        if redemption.player == accountKey then redemption.player = playerKey end
    end
end

function PZLinuxDeliveryGetPlayerRecord(player)
    local ledger = PZLinuxDeliveryGetLedger()
    local playerKey = PZLinuxDeliveryPlayerKey(player)
    PZLinuxDeliveryMigrateLegacyPlayerRecord(ledger, player, playerKey)
    local record = ledger.players[playerKey]
    if type(record) ~= "table" then
        record = {
            orders = {},
            migrations = {},
            account = PZLinuxDeliveryAccountKey(player),
            characterId = PZLinuxGetCharacterId and PZLinuxGetCharacterId(player, true) or nil,
            nativeKey = PZLinuxGetCharacterNativeKey and PZLinuxGetCharacterNativeKey(player) or nil,
        }
        ledger.players[playerKey] = record
    end
    record.orders = record.orders or {}
    record.migrations = record.migrations or {}
    record.account = record.account or PZLinuxDeliveryAccountKey(player)
    record.characterId = record.characterId
        or (PZLinuxGetCharacterId and PZLinuxGetCharacterId(player, true) or nil)
    record.nativeKey = record.nativeKey
        or (PZLinuxGetCharacterNativeKey and PZLinuxGetCharacterNativeKey(player) or nil)
    return record, ledger, playerKey
end

function PZLinuxDeliveryNextId(player, source)
    local ledger = PZLinuxDeliveryGetLedger()
    local id = table.concat({
        "PZLinuxOrder",
        tostring(source or "delivery"),
        PZLinuxDeliveryPlayerKey(player),
        tostring(ledger.nextId),
    }, "-")
    ledger.nextId = ledger.nextId + 1
    return id
end

local function PZLinuxDeliveryNormalizeItems(items)
    local normalized = {}
    for _, item in ipairs(items or {}) do
        local name = tostring(item and item.name or "")
        local quantity = math.max(0, math.floor(tonumber(item and item.quantity) or 0))
        if name ~= "" and quantity > 0 then
            table.insert(normalized, { name = name, quantity = quantity })
        end
    end
    return normalized
end

function PZLinuxDeliveryFindOrderByRequest(player, source, requestId)
    if not requestId then return nil end
    local record = PZLinuxDeliveryGetPlayerRecord(player)
    for _, order in ipairs(record.orders) do
        if order.source == source and tostring(order.requestId or "") == tostring(requestId) then
            return order
        end
    end
    return nil
end

function PZLinuxDeliveryEnqueue(player, source, items, requestId, metadata)
    local existing = PZLinuxDeliveryFindOrderByRequest(player, source, requestId)
    if existing then return existing, false end

    local normalized = PZLinuxDeliveryNormalizeItems(items)
    if #normalized == 0 then return nil, false, "empty_delivery" end

    local record = PZLinuxDeliveryGetPlayerRecord(player)
    local order = {
        id = PZLinuxDeliveryNextId(player, source),
        source = tostring(source or "delivery"),
        status = "pending",
        requestId = requestId and tostring(requestId) or nil,
        createdHour = PZLinuxDeliveryWorldHour(),
        items = normalized,
        metadata = metadata or {},
    }
    table.insert(record.orders, order)
    return order, true
end

function PZLinuxDeliveryGetPendingOrders(player, source)
    local record = PZLinuxDeliveryGetPlayerRecord(player)
    local pending = {}
    for _, order in ipairs(record.orders) do
        if order.source == source
        and (order.status == "pending" or order.status == "materializing") then
            table.insert(pending, order)
        end
    end
    return pending
end

function PZLinuxDeliveryPendingCount(player, source)
    return #PZLinuxDeliveryGetPendingOrders(player, source)
end

local function PZLinuxDeliveryExpectedItemCount(order)
    local count = 0
    for _, item in ipairs(order and order.items or {}) do
        count = count + math.max(0, math.floor(tonumber(item.quantity) or 0))
    end
    return count
end

local function PZLinuxDeliveryParcelMatchesOrder(parcel, order)
    local parcelInventory = parcel and parcel.getInventory and parcel:getInventory()
    local parcelItems = parcelInventory and parcelInventory:getItems()
    if not parcelItems or parcelItems:size() ~= PZLinuxDeliveryExpectedItemCount(order) then return false end

    local expected = {}
    for _, item in ipairs(order.items or {}) do
        expected[item.name] = (expected[item.name] or 0) + math.max(0, math.floor(tonumber(item.quantity) or 0))
    end
    for index = 0, parcelItems:size() - 1 do
        local item = parcelItems:get(index)
        local fullType = item and item.getFullType and item:getFullType() or ""
        if not expected[fullType] or expected[fullType] <= 0 then return false end
        expected[fullType] = expected[fullType] - 1
    end
    for _, remaining in pairs(expected) do
        if remaining ~= 0 then return false end
    end
    return true
end

local function PZLinuxDeliveryFindParcel(playerObj, order)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory()
    local items = inventory and inventory:getItems()
    if not items then return nil end
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local data = item and item.getModData and item:getModData() or nil
        if data
        and tostring(data.PZLinuxDeliveryOrderId or "") == tostring(order and order.id or "")
        and PZLinuxDeliveryParcelMatchesOrder(item, order) then
            return item
        end
    end
    return nil
end

local function PZLinuxDeliveryRemoveTemporaryParcel(inventory, parcel)
    if inventory and parcel then inventory:Remove(parcel) end
end

local function PZLinuxDeliveryCreateParcel(playerObj, order)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return nil, 0, "missing_inventory" end

    local metadata = order.metadata or {}
    local parcelType = tostring(metadata.parcelType or "Base.Parcel_Large")
    local parcel = inventory:AddItem(parcelType)
    local parcelInventory = parcel and parcel:getInventory()
    if not parcelInventory then
        PZLinuxDeliveryRemoveTemporaryParcel(inventory, parcel)
        return nil, 0, "parcel_creation_failed"
    end

    local parcelData = parcel:getModData()
    parcelData.PZLinuxDeliveryOrderId = order.id
    parcelData.PZLinuxDeliverySource = order.source
    if metadata.parcelName and parcel.setName then
        parcel:setName(tostring(metadata.parcelName))
    end

    local added = 0
    for _, item in ipairs(order.items or {}) do
        for _ = 1, math.max(0, math.floor(tonumber(item.quantity) or 0)) do
            if not parcelInventory:AddItem(item.name) then
                PZLinuxDeliveryRemoveTemporaryParcel(inventory, parcel)
                return nil, added, "item_creation_failed"
            end
            added = added + 1
        end
    end

    if added ~= PZLinuxDeliveryExpectedItemCount(order) then
        PZLinuxDeliveryRemoveTemporaryParcel(inventory, parcel)
        return nil, added, "partial_parcel"
    end
    if PZLinuxDeliveryIsWithinWeightLimit
    and not PZLinuxDeliveryIsWithinWeightLimit(playerObj) then
        PZLinuxDeliveryRemoveTemporaryParcel(inventory, parcel)
        return nil, 0, "too_heavy"
    end
    return parcel, added, nil
end

local function PZLinuxDeliveryTrimHistory(record)
    local removable = #record.orders - PZLINUX_DELIVERY_MAX_HISTORY
    if removable <= 0 then return end
    local index = 1
    while index <= #record.orders and removable > 0 do
        local status = record.orders[index].status
        if status == "delivered" or status == "lost" then
            table.remove(record.orders, index)
            removable = removable - 1
        else
            index = index + 1
        end
    end
end

function PZLinuxDeliveryDeliverPending(player, source)
    local playerObj = PZLinuxGetPlayer and PZLinuxGetPlayer(player) or player
    if not playerObj then return { ok = false, error = "no_player" } end

    local record = PZLinuxDeliveryGetPlayerRecord(playerObj)
    local deliveredItems = 0
    local deliveredParcels = 0
    local recoveredParcels = 0
    local tooHeavy = false

    for _, order in ipairs(record.orders) do
        if order.source == source
        and (order.status == "pending" or order.status == "materializing") then
            local existingParcel = PZLinuxDeliveryFindParcel(playerObj, order)
            if existingParcel then
                order.status = "delivered"
                order.deliveredHour = PZLinuxDeliveryWorldHour()
                recoveredParcels = recoveredParcels + 1
            else
                if PZLinuxDeliveryHasRoomForMoreParcels
                and not PZLinuxDeliveryHasRoomForMoreParcels(playerObj) then
                    tooHeavy = true
                    break
                end

                order.status = "materializing"
                local parcel, added, parcelError = PZLinuxDeliveryCreateParcel(playerObj, order)
                if parcelError == "too_heavy" then
                    order.status = "pending"
                    tooHeavy = true
                    break
                end
                if not parcel then
                    order.status = "pending"
                    return {
                        ok = false,
                        error = parcelError or "parcel_creation_failed",
                        delivered = deliveredItems,
                        parcels = deliveredParcels,
                        remaining = PZLinuxDeliveryPendingCount(playerObj, source),
                    }
                end
                if PZLinuxSyncAddedInventoryItem
                and not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
                    PZLinuxDeliveryRemoveTemporaryParcel(playerObj:getInventory(), parcel)
                    order.status = "pending"
                    return {
                        ok = false,
                        error = "parcel_sync_failed",
                        delivered = deliveredItems,
                        parcels = deliveredParcels,
                        remaining = PZLinuxDeliveryPendingCount(playerObj, source),
                    }
                end

                order.status = "delivered"
                order.deliveredHour = PZLinuxDeliveryWorldHour()
                deliveredItems = deliveredItems + added
                deliveredParcels = deliveredParcels + 1
            end
        end
    end

    PZLinuxDeliveryTrimHistory(record)
    local deliveryConfig = PZLinux.Config and PZLinux.Config.Deliveries or {}
    local maxCarryWeight = math.max(1, tonumber(deliveryConfig.maxCarryWeight) or 60)
    local result = {
        ok = true,
        delivered = deliveredItems,
        parcels = deliveredParcels,
        recovered = recoveredParcels,
        remaining = PZLinuxDeliveryPendingCount(playerObj, source),
        tooHeavy = tooHeavy,
        maxCarryWeight = maxCarryWeight,
    }
    print(string.format(
        "[PZLinux Delivery] RESULT player=%s source=%s delivered=%d parcels=%d recovered=%d remaining=%d tooHeavy=%s maxCarryWeight=%s",
        tostring(PZLinuxGetPlayerKey and PZLinuxGetPlayerKey(playerObj) or playerObj),
        tostring(source), result.delivered, result.parcels, result.recovered,
        result.remaining, tostring(result.tooHeavy), tostring(result.maxCarryWeight)))
    return result
end

function PZLinuxDeliveryMarkPendingLost(player, source)
    local pending = PZLinuxDeliveryGetPendingOrders(player, source)
    for _, order in ipairs(pending) do
        order.status = "lost"
        order.lostHour = PZLinuxDeliveryWorldHour()
    end
    return #pending
end

function PZLinuxDeliveryCloseCharacter(player, reason)
    local record = PZLinuxDeliveryGetPlayerRecord(player)
    local lost = 0
    for _, order in ipairs(record.orders) do
        if order.status == "pending" or order.status == "materializing" then
            order.status = "lost"
            order.lostHour = PZLinuxDeliveryWorldHour()
            order.lostReason = tostring(reason or "character_closed")
            lost = lost + 1
        end
    end
    record.status = "closed"
    record.closedHour = PZLinuxDeliveryWorldHour()
    record.closedReason = tostring(reason or "character_closed")
    PZLinuxDeliveryTrimHistory(record)
    return lost
end

function PZLinuxDeliveryFindReceiptByRequest(player, source, requestId)
    if not requestId then return nil end
    local ledger = PZLinuxDeliveryGetLedger()
    local requestKey = table.concat({
        PZLinuxDeliveryPlayerKey(player),
        tostring(source or "sale"),
        tostring(requestId),
    }, ":")
    local receipt = ledger.receipts[ledger.receiptRequests[requestKey]]
    if receipt and receipt.status ~= "cancelled" then return receipt end
    return nil
end

function PZLinuxDeliveryCreateReceiptId(player, source, requestId, metadata)
    local existing = PZLinuxDeliveryFindReceiptByRequest(player, source, requestId)
    if existing then return existing.id, false, existing end

    local ledger = PZLinuxDeliveryGetLedger()
    local playerKey = PZLinuxDeliveryPlayerKey(player)
    local receiptId = PZLinuxDeliveryNextId(player, tostring(source or "sale") .. "-receipt")
    local receipt = {
        id = receiptId,
        player = playerKey,
        source = tostring(source or "sale"),
        requestId = requestId and tostring(requestId) or nil,
        status = "issued",
        createdHour = PZLinuxDeliveryWorldHour(),
        metadata = metadata or {},
    }
    ledger.receipts[receiptId] = receipt
    if requestId then
        local requestKey = table.concat({ playerKey, receipt.source, tostring(requestId) }, ":")
        ledger.receiptRequests[requestKey] = receiptId
    end
    return receiptId, true, receipt
end

function PZLinuxDeliveryCancelReceipt(receiptId)
    local receipt = receiptId and PZLinuxDeliveryGetLedger().receipts[tostring(receiptId)] or nil
    if not receipt or receipt.status == "redeemed" then return false end
    receipt.status = "cancelled"
    receipt.cancelledHour = PZLinuxDeliveryWorldHour()
    return true
end

function PZLinuxDeliveryIsReceiptRedeemed(receiptId)
    if not receiptId or receiptId == "" then return false end
    return PZLinuxDeliveryGetLedger().redeemedReceipts[tostring(receiptId)] ~= nil
end

function PZLinuxDeliveryMarkReceiptRedeemed(receiptId, player)
    if not receiptId or receiptId == "" then return false end
    local ledger = PZLinuxDeliveryGetLedger()
    local key = tostring(receiptId)
    if ledger.redeemedReceipts[key] then return false end
    ledger.redeemedReceipts[key] = {
        player = PZLinuxDeliveryPlayerKey(player),
        redeemedHour = PZLinuxDeliveryWorldHour(),
    }
    if ledger.receipts[key] then
        ledger.receipts[key].status = "redeemed"
        ledger.receipts[key].redeemedHour = PZLinuxDeliveryWorldHour()
    end
    return true
end
