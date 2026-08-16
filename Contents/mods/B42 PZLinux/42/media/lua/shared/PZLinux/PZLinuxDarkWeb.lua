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

local function PZLinuxDarkWebSyncPendingState(playerObj)
    local modData = playerObj:getModData()
    local pending = PZLinuxDeliveryPendingCount(playerObj, "darkweb")
    modData.PZLinuxOnItemBuyOnDarkWebStatus = pending > 0 and 1 or 0
    modData.PZLinuxOnItemBuyOnDarkWebQueue = ""
    modData.PZLinuxDarkWebPendingCount = pending
    PZLinuxTransmitPlayerModData(playerObj)
    return pending
end

function PZLinuxDarkWebMigrateLegacyQueue(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local record = PZLinuxDeliveryGetPlayerRecord(playerObj)
    if tonumber(record.migrations.darkWeb) == 1 then
        return PZLinuxDarkWebSyncPendingState(playerObj)
    end

    local modData = playerObj:getModData()
    local legacyQueue = PZLinuxDarkWebQueueDecode(modData.PZLinuxOnItemBuyOnDarkWebQueue)
    for index, entry in ipairs(legacyQueue) do
        PZLinuxDeliveryEnqueue(
            playerObj,
            "darkweb",
            { { name = entry.name, quantity = entry.quantity } },
            "legacy-darkweb-" .. tostring(index) .. "-" .. tostring(entry.name)
        )
    end
    record.migrations.darkWeb = 1
    return PZLinuxDarkWebSyncPendingState(playerObj)
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

    local existingOrder = PZLinuxDeliveryFindOrderByRequest(playerObj, "darkweb", requestId)
    if existingOrder then
        local metadata = existingOrder.metadata or {}
        return {
            ok = true,
            replayed = true,
            requestId = requestId,
            item = metadata.item,
            quantity = metadata.quantity,
            orderId = existingOrder.id,
            queued = false,
            amount = metadata.amount,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

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

    PZLinuxDarkWebMigrateLegacyQueue(playerObj)
    local order, created, queueError = PZLinuxDeliveryEnqueue(
        playerObj,
        "darkweb",
        { { name = itemToAdd, quantity = quantity } },
        requestId,
        { amount = totalPrice, item = itemToAdd, quantity = quantity, offerIndex = offerIndex }
    )
    if not order then
        PZLinuxApplyBankCredit(playerObj, totalPrice, "darkweb-buy-refund", requestId)
        return {
            ok = false,
            error = queueError or "delivery_queue_failed",
            requestId = requestId,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end
    local pendingCount = PZLinuxDarkWebSyncPendingState(playerObj)
    -- Diagnostic logging kept from the original investigation (now proven
    -- useful -- this is exactly what surfaced the real root cause) so a
    -- future regression is just as easy to spot from a server log.
    print(string.format(
        "[PZLinux DarkWeb] BUY player=%s item=%s qty=%d queueLenAfter=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(itemToAdd), quantity, pendingCount))
    marketOffer.stock = availableStock - quantity
    offer.stock = marketOffer.stock
    PZLinuxDarkWebTransmitMarket()
    if addXp then addXp(playerObj, Perks.PlantScavenging, 3) end

    return {
        ok = true,
        requestId = requestId,
        offerIndex = offerIndex,
        item = itemToAdd,
        quantity = quantity,
        orderId = order.id,
        queued = created,
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

-- A player noticed sell prices changing every time the list refreshed
-- (including right after selling something else entirely), which felt
-- buggy -- and it was: PZLinuxDarkWebCalculateSellPrice rolls a fresh
-- ZombRand every single call, with nothing caching the result, unlike the
-- Buy side (PZLinuxDarkWebBuildBuyOffers), which already prices each
-- offer once per market generation and reuses it (session.prices, keyed
-- off the rotating offer id). Sell offers aren't a rotating subset of the
-- catalog the way Buy's market.offers are -- every owned, sellable item
-- always shows up -- so the cache here is keyed by each item's own fixed
-- position in PZLinuxDarkWebItemsTable instead, but reset on the exact
-- same market.generation boundary, so Buy and Sell prices stay in sync
-- with each other and both refresh together on the same schedule.
function PZLinuxDarkWebBuildSellOffers(player, requestId)
    PZLinuxDarkWebLoadCustomItems()
    local market = PZLinuxDarkWebEnsureMarket()
    local playerKey = PZLinuxGetPlayerKey(player)
    local session = PZLinux.darkWebSellSessions[playerKey]
    if not session or tonumber(session.generation) ~= tonumber(market.generation) then
        session = { generation = market.generation, prices = {} }
        PZLinux.darkWebSellSessions[playerKey] = session
    end

    local offers = {}
    for itemIndex, itemData in ipairs(PZLinuxDarkWebItemsTable) do
        local itemIds = PZLinuxDarkWebGetItemIds(itemData)
        local firstItemId = PZLinuxDarkWebGetFirstItemId(itemData)
        local count = PZLinuxDarkWebCountInventoryItems(player, itemIds)
        local price = session.prices[itemIndex]
        if not price then
            price = PZLinuxDarkWebCalculateSellPrice(player, itemData)
            session.prices[itemIndex] = price
        end
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

    session.requestId = requestId
    session.offers = offers
    return { ok = true, requestId = requestId, offers = offers, balance = PZLinuxLoadBankBalance(player) }
end

function PZLinuxDarkWebApplySell(player, offerIndex, quantity, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local existingReceipt = PZLinuxDeliveryFindReceiptByRequest(playerObj, "darkweb", requestId)
    if existingReceipt then
        local metadata = existingReceipt.metadata or {}
        return {
            ok = true,
            replayed = true,
            requestId = requestId,
            offerIndex = metadata.offerIndex,
            soldCount = metadata.quantity,
            amount = metadata.amount,
            receiptId = existingReceipt.id,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    offerIndex = tonumber(offerIndex)
    quantity = tonumber(quantity)
    if not offerIndex or offerIndex < 1 or not quantity or quantity < 1 then
        return { ok = false, error = "invalid_amount", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local session = PZLinux.darkWebSellSessions[PZLinuxGetPlayerKey(playerObj)]
    if not session or type(session.offers) ~= "table" then
        return { ok = false, error = "no_darkweb_sell_offers", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local offer = session.offers[offerIndex]
    if not offer then
        return { ok = false, error = "invalid_offer", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    -- A player reported wearing a bulletproof vest and owning 2 spares,
    -- wanting to sell only those 2 -- but the sell flow used to grab every
    -- matching item indiscriminately, risking the one they had equipped,
    -- forcing them to manually stash it away first. Matching items are now
    -- collected unequipped-first, so selling fewer than everything owned
    -- only ever reaches for something actually equipped once there aren't
    -- enough loose ones left to cover the requested quantity.
    local inventory = playerObj:getInventory()
    local inventoryItems = inventory:getItems()
    local unequippedItems, equippedItems = {}, {}
    for index = 0, inventoryItems:size() - 1 do
        local item = inventoryItems:get(index)
        if PZLinuxDarkWebInventoryItemMatches(item, offer.id) then
            if item.isEquipped and item:isEquipped() then
                table.insert(equippedItems, item)
            else
                table.insert(unequippedItems, item)
            end
        end
    end

    local available = #unequippedItems + #equippedItems
    if available == 0 then
        return { ok = false, error = "item_not_available", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    if quantity > available then
        return { ok = false, error = "not_enough_owned", requestId = requestId, available = available, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local soldItems = {}
    for _, item in ipairs(unequippedItems) do
        if #soldItems >= quantity then break end
        table.insert(soldItems, item)
    end
    for _, item in ipairs(equippedItems) do
        if #soldItems >= quantity then break end
        table.insert(soldItems, item)
    end

    local amount = PZLinuxNormalizeMoney((offer.price or 0) * #soldItems)
    local parcel = inventory:AddItem("Base.SuspiciousPackage")
    if not parcel then
        return { ok = false, error = "sale_parcel_creation_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    parcel:setName("$" .. tostring(amount))
    local parcelData = parcel:getModData()
    parcelData.PZLinuxDarkWebSale = true
    parcelData.PZLinuxDarkWebSaleAmount = amount
    local receiptId = PZLinuxDeliveryCreateReceiptId(playerObj, "darkweb", requestId, {
        amount = amount,
        quantity = quantity,
        offerIndex = offerIndex,
    })
    parcelData.PZLinuxSaleReceiptId = receiptId
    if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
        inventory:Remove(parcel)
        PZLinuxDeliveryCancelReceipt(receiptId)
        return { ok = false, error = "sale_parcel_sync_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local removed = 0
    for _, soldItem in ipairs(soldItems) do
        if PZLinuxRemoveInventoryItem(playerObj, soldItem) then
            removed = removed + 1
        end
    end
    if removed ~= quantity then
        PZLinuxRemoveInventoryItem(playerObj, parcel)
        PZLinuxDeliveryCancelReceipt(receiptId)
        return {
            ok = false,
            error = "sale_item_removal_failed",
            requestId = requestId,
            removed = removed,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
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
        receiptId = receiptId,
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
    local packages = {}

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
                    local receiptId = tostring(itemModData.PZLinuxSaleReceiptId or "")
                    table.insert(packages, { item = item, amount = packageAmount, receiptId = receiptId })
                    if receiptId == "" or not PZLinuxDeliveryIsReceiptRedeemed(receiptId) then
                        amount = amount + PZLinuxNormalizeMoney(packageAmount)
                        redeemed = redeemed + 1
                    end
                end
            end
        end
    end

    local credit = nil
    if amount > 0 then
        credit = PZLinuxApplyBankCredit(playerObj, amount, "darkweb-sale", requestId)
    end

    for _, package in ipairs(packages) do
        if package.receiptId ~= "" then
            PZLinuxDeliveryMarkReceiptRedeemed(package.receiptId, playerObj)
        end
        PZLinuxRemoveInventoryItem(playerObj, package.item)
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

    local pendingBefore = PZLinuxDarkWebMigrateLegacyQueue(playerObj)
    print(string.format(
        "[PZLinux DarkWeb] DELIVER player=%s pending=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), pendingBefore))

    if pendingBefore <= 0 then
        return { ok = true, requestId = requestId, delivered = 0, parcels = 0, lost = false, remaining = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local chanceLostOrder = ZombRand(1, 101)
    if chanceLostOrder <= 10 then
        local lostCount = PZLinuxDeliveryMarkPendingLost(playerObj, "darkweb")
        PZLinuxDarkWebSyncPendingState(playerObj)
        PZLinuxCreateStolenOrderNote(playerObj)
        return { ok = true, requestId = requestId, delivered = 0, parcels = 0, lost = true, lostCount = lostCount, remaining = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local result = PZLinuxDeliveryDeliverPending(playerObj, "darkweb")
    result.requestId = requestId
    result.lost = false
    result.balance = PZLinuxLoadBankBalance(playerObj)
    PZLinuxDarkWebSyncPendingState(playerObj)
    return result
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

function PZLinuxRequestDarkWebSell(player, offerIndex, quantity, callback)
    local requestId = PZLinuxNextRequestId("darkweb-sell")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxDarkWebSell", { requestId = requestId, offerIndex = offerIndex, quantity = quantity }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxDarkWebApplySell(player, offerIndex, quantity, requestId))
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
