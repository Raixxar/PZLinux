PZLinux = PZLinux or {}
PZLinux.darkWebBuySessions = PZLinux.darkWebBuySessions or {}
PZLinux.darkWebSellSessions = PZLinux.darkWebSellSessions or {}

local PZLINUX_DARK_WEB_MARKET_DATA = "PZLinuxDarkWebMarket"

-- A player's real server logs confirmed the actual root cause behind the
-- "bought something, never delivered" report: two separate BUY log lines,
-- both showing queueLenAfter=1 -- the second purchase's queue length after
-- insertion should have been 2 (appending to the first purchase's still-
-- pending entry), not 1 again. The pending-order queue used to be an ARRAY
-- OF TABLES stored directly as a modData value (modData.PZLinuxOnItemBuy
-- OnDarkWeb = { {batch1}, {batch2}, ... }, each batch itself another
-- table) -- exactly the same nested-modData shape already confirmed once
-- before in this mod to not reliably round-trip through a save/reload (see
-- the reputation backup-key fix at the top of ISPZLinuxVariablesTables.lua
-- -- "exactly what a nested value failing to round-trip through a save/
-- reload would look like"), just never connected to this queue until now.
-- The existing v1.0.8 "belt and suspenders" reassignment
-- (modData.X = modData.X after every table.insert) was a good instinct but
-- not enough -- it only guards against in-place mutation not being
-- *noticed*, not against a nested structure failing to actually persist.
-- Fixed by storing the queue as a single flat STRING instead (the same
-- simple, flat-value shape already proven reliable everywhere else in this
-- mod -- "328 usages... without a reported persistence issue" per that
-- same comment) -- "item|qty" entries joined with ";", e.g.
-- "Base.CigarettePack|2;Base.CigarettePack|4".
function PZLinuxDarkWebQueueDecode(queueString)
    local queue = {}
    if type(queueString) ~= "string" or queueString == "" then return queue end
    for entry in queueString:gmatch("[^;]+") do
        local itemName, quantity = entry:match("^(.-)|(%d+)$")
        if itemName and itemName ~= "" and quantity then
            table.insert(queue, { name = itemName, quantity = tonumber(quantity) })
        end
    end
    return queue
end

function PZLinuxDarkWebQueueEncode(queue)
    local parts = {}
    for _, entry in ipairs(queue or {}) do
        table.insert(parts, tostring(entry.name) .. "|" .. tostring(entry.quantity))
    end
    return table.concat(parts, ";")
end

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

function PZLinuxDarkWebGetStockRange(referencePrice)
    referencePrice = math.max(0, tonumber(referencePrice) or 0)
    for _, tier in ipairs((PZLinuxDarkWebMarketConfig or {}).stockTiers or {}) do
        if not tier.maximumPrice or referencePrice <= tier.maximumPrice then
            return math.max(1, tonumber(tier.minimumStock) or 1),
                math.max(1, tonumber(tier.maximumStock) or tonumber(tier.minimumStock) or 1)
        end
    end
    return 1, 1
end

local function PZLinuxDarkWebGetMarketState()
    local market = ModData.getOrCreate(PZLINUX_DARK_WEB_MARKET_DATA)
    market.offers = market.offers or {}
    return market
end

local function PZLinuxDarkWebGetMarketGeneration()
    local config = PZLinuxDarkWebMarketConfig or {}
    local refreshHours = math.max(1, tonumber(config.refreshHours) or 24)
    local worldHour = getGameTime and getGameTime():getWorldAgeHours() or 0
    return math.floor(math.max(0, worldHour) / refreshHours)
end

local function PZLinuxDarkWebGetStockReferencePrice(itemData)
    local scarcity = PZLinuxDarkWebGetHourMultiplier and PZLinuxDarkWebGetHourMultiplier() or 1
    local purchaseMultiplier = PZLinuxDarkWebGetPurchaseMultiplier and PZLinuxDarkWebGetPurchaseMultiplier() or 1
    return math.max(1, math.floor((tonumber(itemData and itemData.Price) or 0) * scarcity * purchaseMultiplier))
end

local function PZLinuxDarkWebTransmitMarket()
    if isServer and isServer() and ModData.transmit then
        ModData.transmit(PZLINUX_DARK_WEB_MARKET_DATA)
    end
end

local function PZLinuxDarkWebGenerateMarket(market, generation)
    local config = PZLinuxDarkWebMarketConfig or {}
    local availableIndexes = {}
    for itemIndex = 1, #PZLinuxDarkWebItemsTable do
        table.insert(availableIndexes, itemIndex)
    end
    for itemIndex = #availableIndexes, 2, -1 do
        local swapIndex = ZombRand(1, itemIndex + 1)
        availableIndexes[itemIndex], availableIndexes[swapIndex] = availableIndexes[swapIndex], availableIndexes[itemIndex]
    end

    local minimumOffers = math.max(1, tonumber(config.minimumOffers) or 5)
    local maximumOffers = math.max(minimumOffers, tonumber(config.maximumOffers) or 50)
    local offerCount = math.min(#availableIndexes, ZombRand(minimumOffers, maximumOffers + 1))
    local offers = {}
    for position = 1, offerCount do
        local sourceIndex = availableIndexes[position]
        local itemData = PZLinuxDarkWebItemsTable[sourceIndex]
        local firstItemId = PZLinuxDarkWebGetFirstItemId(itemData)
        if firstItemId and getScriptManager():FindItem(firstItemId) then
            local referencePrice = PZLinuxDarkWebGetStockReferencePrice(itemData)
            local minimumStock, maximumStock = PZLinuxDarkWebGetStockRange(referencePrice)
            table.insert(offers, {
                id = tostring(generation) .. ":" .. tostring(sourceIndex),
                sourceIndex = sourceIndex,
                item = { id = PZLinuxDarkWebGetItemIds(itemData) },
                stock = ZombRand(minimumStock, maximumStock + 1),
                initialStock = nil,
                referencePrice = referencePrice,
            })
            offers[#offers].initialStock = offers[#offers].stock
        end
    end
    market.generation = generation
    market.offers = offers
    PZLinuxDarkWebTransmitMarket()
end

local function PZLinuxDarkWebEnsureMarket()
    PZLinuxDarkWebLoadCustomItems()
    local market = PZLinuxDarkWebGetMarketState()
    local generation = PZLinuxDarkWebGetMarketGeneration()
    if tonumber(market.generation) ~= generation or type(market.offers) ~= "table" or #market.offers == 0 then
        PZLinuxDarkWebGenerateMarket(market, generation)
        PZLinux.darkWebBuySessions = {}
    end
    return market
end

function PZLinuxDarkWebBuildBuyOffers(player, requestId)
    local market = PZLinuxDarkWebEnsureMarket()
    local playerKey = PZLinuxGetPlayerKey(player)
    local session = PZLinux.darkWebBuySessions[playerKey]
    if not session or tonumber(session.generation) ~= tonumber(market.generation) then
        session = { generation = market.generation, prices = {} }
        PZLinux.darkWebBuySessions[playerKey] = session
    end

    local offers = {}
    for index, marketOffer in ipairs(market.offers) do
        local itemData = PZLinuxDarkWebItemsTable[marketOffer.sourceIndex]
        local price = session.prices[marketOffer.id]
        if not price then
            price = PZLinuxDarkWebCalculateBuyPrice(player, itemData)
            session.prices[marketOffer.id] = price
        end
        offers[index] = {
            index = index,
            offerId = marketOffer.id,
            item = marketOffer.item,
            price = price,
            stock = math.max(0, tonumber(marketOffer.stock) or 0),
            transactionType = "Buy",
            transactionQty = 1,
        }
    end
    session.offers = offers
    return { ok = true, requestId = requestId, offers = offers, balance = PZLinuxLoadBankBalance(player) }
end

function PZLinuxDarkWebGetBuyOffers(player, requestId)
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

    local market = PZLinuxDarkWebEnsureMarket()
    local marketOffer = market.offers[offerIndex]
    if tonumber(session.generation) ~= tonumber(market.generation)
    or not marketOffer or tostring(marketOffer.id) ~= tostring(offer.offerId) then
        return { ok = false, error = "offer_expired", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local availableStock = math.max(0, tonumber(marketOffer.stock) or 0)
    if quantity > availableStock then
        offer.stock = availableStock
        return {
            ok = false,
            error = "not_enough_stock",
            requestId = requestId,
            offerIndex = offerIndex,
            stock = availableStock,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
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

    local modData = playerObj:getModData()
    local queue = PZLinuxDarkWebQueueDecode(modData.PZLinuxOnItemBuyOnDarkWebQueue)
    table.insert(queue, { name = itemToAdd, quantity = quantity })
    modData.PZLinuxOnItemBuyOnDarkWebQueue = PZLinuxDarkWebQueueEncode(queue)
    modData.PZLinuxOnItemBuyOnDarkWebStatus = 1
    -- Diagnostic logging kept from the original investigation (now proven
    -- useful -- this is exactly what surfaced the real root cause) so a
    -- future regression is just as easy to spot from a server log.
    print(string.format(
        "[PZLinux DarkWeb] BUY player=%s item=%s qty=%d queueLenAfter=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(itemToAdd), quantity, #queue))
    marketOffer.stock = availableStock - quantity
    offer.stock = marketOffer.stock
    PZLinuxDarkWebTransmitMarket()
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
        stock = marketOffer.stock,
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
    PZLinuxDarkWebLoadCustomItems()
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
        -- Sell Surplus also uses "Base.SuspiciousPackage" (tagged with its
        -- own PZLinuxSellSaleAmount modData key instead); skip those here so
        -- PZLinuxSellApplyRedeemPackage is the only thing that ever redeems
        -- them, instead of falling through to the name-parsing fallback
        -- below (which also crashed: string.gsub returns two values, and
        -- passing both straight into tonumber(string, base) treated the
        -- substitution count as an invalid numeric base).
        if item and item:getFullType() == "Base.SuspiciousPackage" then
            local itemModData = item:getModData()
            if not itemModData.PZLinuxSellSaleAmount then
                local packageAmount = tonumber(itemModData.PZLinuxDarkWebSaleAmount)
                if not packageAmount then
                    local boxName = item:getName() or ""
                    local cleanedName = boxName:gsub("%$", "")
                    packageAmount = tonumber(cleanedName)
                end

                if packageAmount and packageAmount > 0 then
                    amount = amount + PZLinuxNormalizeMoney(packageAmount)
                    redeemed = redeemed + 1
                    PZLinuxRemoveInventoryItem(playerObj, item)
                end
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
    local queue = PZLinuxDarkWebQueueDecode(modData.PZLinuxOnItemBuyOnDarkWebQueue)

    -- Diagnostic logging kept from the original investigation -- but now
    -- unconditional, printed BEFORE either early-return below, not just on
    -- the "there's something to deliver" path. A player reported not
    -- receiving an order with no queueLenAfter=2 in their BUY logs either
    -- (i.e. the SECOND purchase's own entry, the one that should still
    -- have been the most recent one queued, was also gone by the time they
    -- checked the mailbox) -- this line is what would show definitively
    -- whether that's because the mailbox visit found status/queue already
    -- reset to nothing (rawStatus/rawQueueLen below would show it) or
    -- something else entirely, instead of leaving that mailbox visit with
    -- no log trace at all whenever it hits an early return.
    print(string.format(
        "[PZLinux DarkWeb] DELIVER player=%s rawStatus=%s rawQueueLen=%d decodedQueueLen=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(modData.PZLinuxOnItemBuyOnDarkWebStatus),
        #tostring(modData.PZLinuxOnItemBuyOnDarkWebQueue or ""), #queue))

    if modData.PZLinuxOnItemBuyOnDarkWebStatus ~= 1 then
        return { ok = true, requestId = requestId, delivered = 0, lost = false, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if #queue == 0 then
        modData.PZLinuxOnItemBuyOnDarkWebStatus = 0
        modData.PZLinuxOnItemBuyOnDarkWebQueue = ""
        return { ok = true, requestId = requestId, delivered = 0, lost = false, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    do
        local summary = {}
        for entryIndex, entry in ipairs(queue) do
            table.insert(summary, entryIndex .. ":" .. tostring(entry.name) .. "x" .. tostring(entry.quantity))
        end
        print(string.format(
            "[PZLinux DarkWeb] DELIVER player=%s queueLenBefore=%d entries=%s",
            tostring(PZLinuxGetPlayerKey(playerObj)), #queue, table.concat(summary, " ")))
    end

    local chanceLostOrder = ZombRand(1, 101)
    if chanceLostOrder <= 10 then
        modData.PZLinuxOnItemBuyOnDarkWebStatus = 0
        modData.PZLinuxOnItemBuyOnDarkWebQueue = ""
        PZLinuxTransmitPlayerModData(playerObj)
        PZLinuxCreateStolenOrderNote(playerObj)
        return { ok = true, requestId = requestId, delivered = 0, lost = true, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local delivered = 0
    while #queue > 0 do
        local entry = queue[#queue]
        if not entry.name or not entry.quantity or entry.quantity < 1 then
            table.remove(queue, #queue)
            modData.PZLinuxOnItemBuyOnDarkWebQueue = PZLinuxDarkWebQueueEncode(queue)
            return { ok = false, error = "invalid_pending_order", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local parcel = inventory:AddItem("Base.Parcel_Large")
        local parcelInv = parcel and parcel:getInventory()
        if not parcelInv then
            if parcel then inventory:Remove(parcel) end
            return { ok = false, error = "parcel_creation_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local batchDelivered = 0
        if getScriptManager():FindItem(entry.name) then
            for _ = 1, entry.quantity do
                local deliveredItem = parcelInv:AddItem(entry.name)
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
        table.remove(queue, #queue)
        -- v1.0.8 (kept): transmitting after every single removal, not just
        -- once at the end, means a mid-loop disconnect leaves the
        -- already-delivered entries marked gone rather than betting on one
        -- final transmit at the end of the loop to have covered all of
        -- them.
        modData.PZLinuxOnItemBuyOnDarkWebQueue = PZLinuxDarkWebQueueEncode(queue)
        PZLinuxTransmitPlayerModData(playerObj)
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
