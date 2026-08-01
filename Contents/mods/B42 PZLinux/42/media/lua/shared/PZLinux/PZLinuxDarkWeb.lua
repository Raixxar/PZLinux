PZLinux = PZLinux or {}
PZLinux.darkWebBuySessions = PZLinux.darkWebBuySessions or {}
PZLinux.darkWebSellSessions = PZLinux.darkWebSellSessions or {}

function PZLinuxDarkWebGetItemIds(itemData)
    if not itemData then return {} end
    if type(itemData.id) == "table" then return itemData.id end
    if itemData.id then return { itemData.id } end
    return {}
end

function PZLinuxDarkWebGetFirstItemId(itemData)
    local ids = PZLinuxDarkWebGetItemIds(itemData)
    return ids[1]
end

function PZLinuxDarkWebBuildBuyOffers(player, requestId)
    local offers = {}
    local maxItems = ZombRand(5, 51)

    for _ = 1, maxItems do
        local itemData = PZLinuxDarkWebItemsTable[ZombRand(#PZLinuxDarkWebItemsTable) + 1]
        local firstItemId = PZLinuxDarkWebGetFirstItemId(itemData)
        local price = PZLinuxDarkWebCalculateBuyPrice(player, itemData)
        if firstItemId and price and getScriptManager():FindItem(firstItemId) then
            table.insert(offers, {
                index = #offers + 1,
                item = { id = PZLinuxDarkWebGetItemIds(itemData) },
                price = price,
                transactionType = "Buy",
                transactionQty = 1,
            })
        end
    end

    local worldHour = getGameTime and math.ceil(getGameTime():getWorldAgeHours()) or 0
    if worldHour < 24 then worldHour = 24 end
    PZLinux.darkWebBuySessions[PZLinuxGetPlayerKey(player)] = { requestId = requestId, offers = offers, worldHour = worldHour }

    return { ok = true, requestId = requestId, offers = offers, balance = PZLinuxLoadBankBalance(player) }
end

function PZLinuxDarkWebGetBuyOffers(player, requestId)
    local worldHour = getGameTime and math.ceil(getGameTime():getWorldAgeHours()) or 0
    if worldHour < 24 then worldHour = 24 end

    local session = PZLinux.darkWebBuySessions[PZLinuxGetPlayerKey(player)]
    if session and session.offers and (worldHour - (session.worldHour or 0)) < 24 then
        return { ok = true, requestId = requestId, offers = session.offers, balance = PZLinuxLoadBankBalance(player) }
    end

    return PZLinuxDarkWebBuildBuyOffers(player, requestId)
end

function PZLinuxDarkWebApplyBuy(player, offerIndex, quantity, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    offerIndex = tonumber(offerIndex)
    quantity = PZLinuxNormalizeMoney(quantity)
    if not offerIndex or offerIndex < 1 or quantity < 1 then
        return { ok = false, error = "invalid_amount", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local session = PZLinux.darkWebBuySessions[PZLinuxGetPlayerKey(playerObj)]
    if not session or type(session.offers) ~= "table" then
        return { ok = false, error = "no_darkweb_offers", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local offer = session.offers[offerIndex]
    if not offer or not offer.item then
        return { ok = false, error = "invalid_offer", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local itemToAdd = type(offer.item.id) == "table" and offer.item.id[1] or offer.item.id
    if not itemToAdd or not getScriptManager():FindItem(itemToAdd) then
        return { ok = false, error = "invalid_item", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local totalPrice = PZLinuxNormalizeMoney(offer.price * quantity)
    local debit = PZLinuxApplyBankDebit(playerObj, totalPrice, "darkweb-buy", requestId)
    if not debit.ok then
        debit.offerIndex = offerIndex
        debit.quantity = quantity
        return debit
    end

    local batch = { items = {} }
    for _ = 1, quantity do
        table.insert(batch.items, { name = itemToAdd })
    end

    local modData = playerObj:getModData()
    modData.PZLinuxOnItemBuyOnDarkWeb = modData.PZLinuxOnItemBuyOnDarkWeb or {}
    modData.PZLinuxOnItemBuyOnDarkWebStatus = 1
    table.insert(modData.PZLinuxOnItemBuyOnDarkWeb, { batch })
    PZLinuxTransmitPlayerModData(playerObj)

    if addXp then addXp(playerObj, Perks.PlantScavenging, 3) end

    return {
        ok = true,
        requestId = requestId,
        offerIndex = offerIndex,
        item = itemToAdd,
        quantity = quantity,
        amount = totalPrice,
        balance = PZLinuxLoadBankBalance(playerObj),
        previousBalance = debit.previousBalance,
    }
end

function PZLinuxDarkWebInventoryItemMatches(item, itemIds)
    if not item then return false end
    local itemType = item:getFullType()
    for _, itemId in ipairs(itemIds or {}) do
        if itemType == itemId then return true end
    end
    return false
end

function PZLinuxDarkWebCountInventoryItems(player, itemIds)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local items = playerObj:getInventory():getItems()
    local count = 0
    for index = 0, items:size() - 1 do
        if PZLinuxDarkWebInventoryItemMatches(items:get(index), itemIds) then
            count = count + 1
        end
    end
    return count
end

function PZLinuxDarkWebRemoveInventoryItems(player, itemIds)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    local removed = 0
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if PZLinuxDarkWebInventoryItemMatches(item, itemIds) then
            if PZLinuxRemoveInventoryItem(playerObj, item) then
                removed = removed + 1
            end
        end
    end
    return removed
end

function PZLinuxDarkWebBuildSellOffers(player, requestId)
    local offers = {}
    for _, itemData in ipairs(PZLinuxDarkWebItemsTable) do
        local itemIds = PZLinuxDarkWebGetItemIds(itemData)
        local firstItemId = PZLinuxDarkWebGetFirstItemId(itemData)
        local count = PZLinuxDarkWebCountInventoryItems(player, itemIds)
        local price = PZLinuxDarkWebCalculateSellPrice(player, itemData)
        if count > 0 and firstItemId and price and getScriptManager():FindItem(firstItemId) then
            table.insert(offers, {
                index = #offers + 1,
                id = itemIds,
                count = count,
                price = price,
                firstItemId = firstItemId,
            })
        end
    end

    PZLinux.darkWebSellSessions[PZLinuxGetPlayerKey(player)] = { requestId = requestId, offers = offers }
    return { ok = true, requestId = requestId, offers = offers, balance = PZLinuxLoadBankBalance(player) }
end

function PZLinuxDarkWebApplySell(player, offerIndex, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    offerIndex = tonumber(offerIndex)
    if not offerIndex or offerIndex < 1 then
        return { ok = false, error = "invalid_offer", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local session = PZLinux.darkWebSellSessions[PZLinuxGetPlayerKey(playerObj)]
    if not session or type(session.offers) ~= "table" then
        return { ok = false, error = "no_darkweb_sell_offers", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local offer = session.offers[offerIndex]
    if not offer then
        return { ok = false, error = "invalid_offer", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local soldItems = {}
    local inventoryItems = inventory:getItems()
    for index = inventoryItems:size() - 1, 0, -1 do
        local item = inventoryItems:get(index)
        if PZLinuxDarkWebInventoryItemMatches(item, offer.id) then
            table.insert(soldItems, item)
        end
    end
    if #soldItems == 0 then
        return { ok = false, error = "item_not_available", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local amount = PZLinuxNormalizeMoney((offer.price or 0) * #soldItems)
    local parcel = inventory:AddItem("Base.SuspiciousPackage")
    if not parcel then
        return { ok = false, error = "sale_parcel_creation_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    parcel:setName("$" .. tostring(amount))
    parcel:getModData().PZLinuxDarkWebSale = true
    parcel:getModData().PZLinuxDarkWebSaleAmount = amount
    if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
        inventory:Remove(parcel)
        return { ok = false, error = "sale_parcel_sync_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local removed = 0
    for _, soldItem in ipairs(soldItems) do
        if PZLinuxRemoveInventoryItem(playerObj, soldItem) then
            removed = removed + 1
        end
    end

    if addXp then addXp(playerObj, Perks.PlantScavenging, 3) end
    PZLinuxTransmitPlayerModData(playerObj)
    PZLinuxDarkWebBuildSellOffers(playerObj, requestId)

    return {
        ok = true,
        requestId = requestId,
        offerIndex = offerIndex,
        soldCount = removed,
        amount = amount,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxDarkWebApplyRedeemSales(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    local amount = 0
    local redeemed = 0

    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if item and item:getFullType() == "Base.SuspiciousPackage" then
            local itemModData = item:getModData()
            local packageAmount = tonumber(itemModData.PZLinuxDarkWebSaleAmount)
            if not packageAmount then
                local boxName = item:getName() or ""
                packageAmount = tonumber(boxName:gsub("%$", ""))
            end

            if packageAmount and packageAmount > 0 then
                amount = amount + PZLinuxNormalizeMoney(packageAmount)
                redeemed = redeemed + 1
                PZLinuxRemoveInventoryItem(playerObj, item)
            end
        end
    end

    local credit = nil
    if amount > 0 then
        credit = PZLinuxApplyBankCredit(playerObj, amount, "darkweb-sale", requestId)
    end

    PZLinuxTransmitPlayerModData(playerObj)
    return {
        ok = true,
        requestId = requestId,
        amount = amount,
        redeemed = redeemed,
        balance = credit and credit.balance or PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxDarkWebApplyDeliverOrders(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local modData = playerObj:getModData()
    if modData.PZLinuxOnItemBuyOnDarkWebStatus ~= 1 or type(modData.PZLinuxOnItemBuyOnDarkWeb) ~= "table" then
        return { ok = true, requestId = requestId, delivered = 0, lost = false, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local chanceLostOrder = ZombRand(1, 101)
    if chanceLostOrder <= 10 then
        modData.PZLinuxOnItemBuyOnDarkWebStatus = 0
        modData.PZLinuxOnItemBuyOnDarkWeb = {}
        PZLinuxTransmitPlayerModData(playerObj)
        return { ok = true, requestId = requestId, delivered = 0, lost = true, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local delivered = 0
    while #modData.PZLinuxOnItemBuyOnDarkWeb > 0 do
        local lastBatchWrapper = modData.PZLinuxOnItemBuyOnDarkWeb[#modData.PZLinuxOnItemBuyOnDarkWeb]
        local lastBatch = type(lastBatchWrapper) == "table" and lastBatchWrapper[1] or nil
        if not lastBatch or type(lastBatch.items) ~= "table" then
            return { ok = false, error = "invalid_pending_order", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local parcel = inventory:AddItem("Base.Parcel_Large")
        local parcelInv = parcel and parcel:getInventory()
        if not parcelInv then
            if parcel then inventory:Remove(parcel) end
            return { ok = false, error = "parcel_creation_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local batchDelivered = 0
        for _, item in ipairs(lastBatch.items) do
            if item.name and getScriptManager():FindItem(item.name) then
                local deliveredItem = parcelInv:AddItem(item.name)
                if deliveredItem then batchDelivered = batchDelivered + 1 end
            end
        end

        if batchDelivered <= 0 then
            inventory:Remove(parcel)
            return { ok = false, error = "invalid_pending_item", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
            inventory:Remove(parcel)
            return { ok = false, error = "parcel_sync_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end
        delivered = delivered + batchDelivered
        table.remove(modData.PZLinuxOnItemBuyOnDarkWeb, #modData.PZLinuxOnItemBuyOnDarkWeb)
    end

    modData.PZLinuxOnItemBuyOnDarkWebStatus = 0
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, delivered = delivered, lost = false, balance = PZLinuxLoadBankBalance(playerObj) }
end

function PZLinuxRequestDarkWebOffers(player, callback)
    local requestId = PZLinuxNextRequestId("darkweb-offers")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebRequestOffers", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebGetBuyOffers(player, requestId))
    return requestId
end

function PZLinuxRequestDarkWebBuy(player, offerIndex, quantity, callback)
    local requestId = PZLinuxNextRequestId("darkweb-buy")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebBuy", { requestId = requestId, offerIndex = offerIndex, quantity = quantity }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebApplyBuy(player, offerIndex, quantity, requestId))
    return requestId
end

function PZLinuxRequestDarkWebSellOffers(player, callback)
    local requestId = PZLinuxNextRequestId("darkweb-sell-offers")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebSellOffers", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebBuildSellOffers(player, requestId))
    return requestId
end

function PZLinuxRequestDarkWebSell(player, offerIndex, callback)
    local requestId = PZLinuxNextRequestId("darkweb-sell")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebSell", { requestId = requestId, offerIndex = offerIndex }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebApplySell(player, offerIndex, requestId))
    return requestId
end

function PZLinuxRequestDarkWebRedeemSales(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("darkweb-redeem-sales")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebRedeemSales", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebApplyRedeemSales(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestDarkWebDeliverOrders(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("darkweb-deliver-orders")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebDeliverOrders", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebApplyDeliverOrders(player, mailboxRef, requestId))
    return requestId
end
