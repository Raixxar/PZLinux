-- Dark Web UI - by Raixxar
-- Updated : 25/01/25

darkWebUI = ISPanel:derive("darkWebUI")

local ITEMS_MAX = 50
local currentOffers = {}

local function PZLinuxDarkWebTextWidth(text)
    local managerProvider = rawget(_G, "getTextManager")
    local manager = managerProvider and managerProvider() or nil
    if manager and manager.MeasureStringX then
        return manager:MeasureStringX(UIFont.Small, tostring(text or ""))
    end
    return #tostring(text or "") * 7
end

local function PZLinuxDarkWebRemoveLastCharacter(text)
    local lastIndex = #text
    if lastIndex == 0 then return "" end

    while lastIndex > 1 do
        local byte = text:byte(lastIndex)
        if not byte or byte < 128 or byte > 191 then break end
        lastIndex = lastIndex - 1
    end
    return text:sub(1, lastIndex - 1)
end

local function PZLinuxDarkWebFitText(text, maxWidth)
    text = tostring(text or "")
    if maxWidth <= 0 or PZLinuxDarkWebTextWidth(text) <= maxWidth then return text end

    local suffix = "..."
    while text ~= "" and PZLinuxDarkWebTextWidth(text .. suffix) > maxWidth do
        text = PZLinuxDarkWebRemoveLastCharacter(text)
    end
    return text .. suffix
end

-- CONSTRUCTOR
function darkWebUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.filterMode = "all"
    o.searchTextLower = ""
    o.isClosing = false
    return o
end

-- INIT
function darkWebUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar:onMouseDown(_x, _y)
        self.parent.isDragging = true
        PZLinuxTrackDragging(self.parent)
        self.parent.initialX = self.parent:getX()
        self.parent.initialY = self.parent:getY()
        self.parent.mouseStartX = getMouseX()
        self.parent.mouseStartY = getMouseY()
    end

    function self.topBar:onMouseMove(_x, _y)
        if self.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - self.parent.mouseStartX
            local dy = curMouseY - self.parent.mouseStartY
            self.parent:setX(self.parent.initialX + dx)
            self.parent:setY(self.parent.initialY + dy)
        end
    end

    function self.topBar:onMouseUp(_x, _y)
        self.parent.isDragging = false
        local modData = PZLinuxGetModData(self.parent.player)
        if modData then
            modData.PZLinuxUIX = self.parent:getX()
            modData.PZLinuxUIY = self.parent:getY()
        end
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, "Bank balance: $"  .. tostring(loadAtmBalance(self.player)), 0, 1, 0, 1, UIFont.Small, true)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabel:setVisible(false)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)


    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimize)
    self.minimizeButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeButton:setVisible(true)
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.minimizeBackButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimizeBack)
    self.minimizeBackButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeBackButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeBackButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeBackButton:setVisible(false)
    self.minimizeBackButton:initialise()
    self.topBar:addChild(self.minimizeBackButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.filterAllBtn = ISButton:new(self.width * 0.20, self.height * 0.20, self.width * 0.08, self.height * 0.025, "All", self, self.OnFilter)
    self.filterAllBtn.internal = "all"
    self.filterAllBtn:setVisible(false)
    self.filterAllBtn:initialise()
    self:addChild(self.filterAllBtn)

    self.searchBtn = ISButton:new(self.width * 0.28, self.height * 0.20, self.width * 0.08, self.height * 0.025, "Search", self, self.OnSearch)
    self.searchBtn.internal = "search"
    self.searchBtn:setVisible(false)
    self.searchBtn:initialise()
    self:addChild(self.searchBtn)

    self.shoppingBuyButton = ISButton:new(self.width * 0.35, self.width * 0.32, self.width * 0.25, self.height * 0.08, "BUY", self, self.onBuy)
    self.shoppingBuyButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingBuyButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingBuyButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingBuyButton:setVisible(true)
    self.shoppingBuyButton:initialise()
    self.topBar:addChild(self.shoppingBuyButton)

    self.shoppingSellButton = ISButton:new(self.width * 0.35, self.width * 0.43, self.width * 0.25, self.height * 0.08, "SELL", self, self.onSell)
    self.shoppingSellButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingSellButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingSellButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingSellButton:setVisible(true)
    self.shoppingSellButton:initialise()
    self.topBar:addChild(self.shoppingSellButton)

    self.shoppingHelpButton = ISButton:new(self.width * 0.35, self.width * 0.54, self.width * 0.25, self.height * 0.08, "HELP", self, self.onHelp)
    self.shoppingHelpButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingHelpButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingHelpButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingHelpButton:setVisible(true)
    self.shoppingHelpButton:initialise()
    self.topBar:addChild(self.shoppingHelpButton)

    self.searchField = ISTextEntryBox:new("", self.width * 0.363, self.height * 0.199, self.width * 0.399, self.height * 0.025)
    self.searchField.onCommandEntered = function(_entry) self:onCommandEnter() end
    self.searchField:setVisible(false)
    self.searchField:initialise()
    self:addChild(self.searchField)

    self.scrollPanel = ISPanel:new(self.width * 0.193, self.height * 0.228, self.width * 0.568, self.height * 0.48)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    self.offerBackgrounds = {}
    self.offerIcons = {}
    self.offerLabels = {}
    self.offerPriceLabels = {}
    self.offerTextWidths = {}
    self.transactionBtns = {}
    self.transactionQtys = {}

    local rowHeight = math.max(38, self.height * 0.05)
    local totalHeight = 100 * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    for i = 1, ITEMS_MAX do
        local yOffset = 5 + (i - 1) * rowHeight
        local offerBackground = ISPanel:new(5, yOffset, self.scrollPanel.width - 23, rowHeight)
        offerBackground.backgroundColor = {r=0, g=0, b=0, a=0}
        offerBackground.borderColor     = {r=0, g=0, b=0, a=0}
        offerBackground:initialise()
        self.scrollPanel:addChild(offerBackground)
        self.offerBackgrounds[i] = offerBackground

        local iconSize = 28
        local iconY    = (rowHeight - iconSize) / 2
        local iconImg  = ISImage:new(5, iconY, iconSize, iconSize, nil)
        iconImg:initialise()
        offerBackground:addChild(iconImg)
        self.offerIcons[i] = iconImg

        local labelNameX = 5 + iconSize + 5
        local labelNameY = math.max(0, (rowHeight - 30) / 2)
        local nameLabel  = ISLabel:new(labelNameX, labelNameY, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        offerBackground:addChild(nameLabel)
        self.offerLabels[i] = nameLabel

        local priceLabel = ISLabel:new(labelNameX, labelNameY + 15, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        priceLabel:initialise()
        offerBackground:addChild(priceLabel)
        self.offerPriceLabels[i] = priceLabel

        local buyWidth = PZLinuxDarkWebTextWidth(PZLinuxGetText("IGUI_PZLinux_DarkWeb_Buy"))
        local soldOutWidth = PZLinuxDarkWebTextWidth(PZLinuxGetText("IGUI_PZLinux_DarkWeb_SoldOut"))
        local buttonWidth = math.min(offerBackground.width * 0.25, math.max(58, buyWidth + 16, soldOutWidth + 16))
        local buttonHeight = self.height * 0.025
        local quantityWidth = math.max(32, self.width * 0.035)
        local buttonX = offerBackground.width - buttonWidth - 6
        local quantityX = buttonX - quantityWidth - 5
        self.offerTextWidths[i] = math.max(40, quantityX - labelNameX - 8)

        local transactionQty = ISTextEntryBox:new("0", quantityX, (rowHeight - buttonHeight - 2) / 2, quantityWidth, self.height * 0.024)
        transactionQty.backgroundColor = {r=0, g=0, b=0, a=1}
        transactionQty.internal = i
        transactionQty:setVisible(true)
        transactionQty:initialise()
        transactionQty:setOnlyNumbers(true)
        offerBackground:addChild(transactionQty)
        self.transactionQtys[i] = transactionQty

        local transactionBtn = ISButton:new(buttonX, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight, "", self, function(self, btn)
            local quantityTrading = tonumber(transactionQty:getText()) or 0
            self:OnBuyItem(btn, quantityTrading)
        end)
        transactionBtn.internal = i
        transactionBtn:setVisible(false)
        transactionBtn:initialise()
        offerBackground:addChild(transactionBtn)
        self.transactionBtns[i] = transactionBtn


        function offerBackground:onMouseMove(_dx, _dy)
            self.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0.3}
        end
        function offerBackground:onMouseMoveOutside(_dx, _dy)
            self.backgroundColor = {r=0, g=0, b=0, a=0}
        end
    end
end

-- STOP
function darkWebUI:onStop(_button)
    self.isClosing = true

    Events.OnKeyStartPressed.Remove(self.onKeyEvent)
    Events.OnKeyPressed.Remove(self.onKeyEvent)
    Events.OnKeyKeepPressed.Remove(self.onKeyEvent)

    if self.updateCoroutineFunc then
        Events.OnTick.Remove(self.updateCoroutineFunc)
        self.updateCoroutineFunc = nil
    end

    if self.loadingMessage then
        self.scrollPanel:removeChild(self.loadingMessage)
        self.loadingMessage = nil
    end

    if self.centeredImage then
        self.centeredImage:removeFromUIManager()
        self.centeredImage = nil
    end

    self:removeFromUIManager()
    self.terminalCoroutine = nil
end

-- LOGOUT
function darkWebUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if modData then modData.PZLinuxUIOpenMenu = 1 end
end

function darkWebUI:onMinimizeBack(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if modData then modData.PZLinuxUIOpenMenu = 3 end
end


-- LOGOUT
function darkWebUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if modData then modData.PZLinuxUIOpenMenu = 1 end
end

function darkWebUI:onCloseX(_button)
    self.isClosing = true
    local player = PZLinuxGetPlayer(self.player)
    if player then
        player:StopAllActionQueue()
    end
end


-- UPDATE UI
function darkWebUI:startUI()
    self.titleLabel:setVisible(true)
    self.minimizeButton:setVisible(true)
    self.closeButton:setVisible(true)
    self.filterAllBtn:setVisible(false)
    self.searchField:setVisible(false)
    self.searchBtn:setVisible(false)
    self.scrollPanel:setVisible(false)
    self.scrollPanel:addScrollBars(false)
end

function darkWebUI:onBuy()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.titleLabel:setVisible(true)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)
    self.closeButton:setVisible(true)
    self.filterAllBtn:setVisible(true)
    self.searchField:setVisible(true)
    self.searchBtn:setVisible(true)
    self.scrollPanel:setVisible(true)
    self.scrollPanel:addScrollBars(true)

    if not self.darkWebBuyOffersLoaded then
        if self.darkWebBuyOffersPending then return end
        self.darkWebBuyOffersPending = true
        PZLinuxRequestDarkWebOffers(self.player, function(result)
            self.darkWebBuyOffersPending = false
            if result and result.ok then
                currentOffers = result.offers or {}
                self.darkWebBuyOffersLoaded = true
                if result.balance then
                    saveAtmBalance(result.balance, self.player)
                    self.titleLabel:setName("Bank balance: $" .. tostring(result.balance))
                end
                if not self.isClosing then
                    self:onBuy()
                end
            end
        end)
        return
    end

    local lineIndex = 1
    for i, rowData in ipairs(currentOffers) do
        if self:FilterMatch(rowData) then
            local firstId
            if type(rowData.item.id) == "table" then
                firstId = rowData.item.id[1]
            else
                firstId = rowData.item.id
            end
            local scriptItem = getScriptManager():FindItem(firstId)
            local isValid = scriptItem and scriptItem:getDisplayName() and scriptItem:getDisplayName():match("%S")

            if isValid then
                if lineIndex <= ITEMS_MAX then
                    local iconName = scriptItem:getIcon()
                    local iconTex  = getTexture(iconName) or getTexture("Item_" .. iconName)

                    if iconTex and self.offerIcons[lineIndex] then
                        self.offerIcons[lineIndex].texture = iconTex
                        self.offerIcons[lineIndex]:setVisible(true)
                    elseif self.offerIcons[lineIndex] then
                        self.offerIcons[lineIndex].texture = nil
                        self.offerIcons[lineIndex]:setVisible(false)
                    end

                    if self.offerLabels[lineIndex] then
                        local displayName = scriptItem:getDisplayName()
                        self.offerLabels[lineIndex]:setName(PZLinuxDarkWebFitText(
                            displayName,
                            self.offerTextWidths[lineIndex] or 120
                        ))
                    end

                    local offerDetails = "$" .. tostring(rowData.price) .. " | " .. string.format(
                        PZLinuxGetText("IGUI_PZLinux_DarkWeb_Stock"),
                        tonumber(rowData.stock) or 0
                    )
                    local offerTooltip = scriptItem:getDisplayName() .. "\n" .. offerDetails
                    if self.offerPriceLabels[lineIndex] then
                        self.offerPriceLabels[lineIndex]:setName(PZLinuxDarkWebFitText(
                            offerDetails,
                            self.offerTextWidths[lineIndex] or 120
                        ))
                    end

                    if self.transactionQtys[lineIndex] then
                        self.transactionQtys[lineIndex]:setVisible(true)
                    end

                    if self.transactionBtns[lineIndex] then
                        -- Defense in depth on top of the FilterMatch fix
                        -- above: if this row slot ever ends up bound to a
                        -- different offer than last render for any other
                        -- reason (e.g. the search filter changing what's
                        -- shown), clear out whatever quantity was typed
                        -- for the PREVIOUS offer at this position instead
                        -- of silently carrying it over to a new item.
                        if self.transactionBtns[lineIndex].internal ~= i and self.transactionQtys[lineIndex] then
                            self.transactionQtys[lineIndex]:setText("0")
                        end
                        self.transactionBtns[lineIndex].internal = i
                        if rowData.transactionType == "Buy" then
                            local titleKey = (tonumber(rowData.stock) or 0) > 0
                                and "IGUI_PZLinux_DarkWeb_Buy"
                                or "IGUI_PZLinux_DarkWeb_SoldOut"
                            self.transactionBtns[lineIndex]:setTitle(PZLinuxGetText(titleKey))
                            self.transactionBtns[lineIndex].backgroundColor = {r=0, g=0.6, b=0, a=1}
                        end
                        self.transactionBtns[lineIndex]:setVisible(true)
                        self.transactionBtns[lineIndex]:setEnable((tonumber(rowData.stock) or 0) > 0)
                        if self.transactionBtns[lineIndex].setTooltip then
                            self.transactionBtns[lineIndex]:setTooltip(offerTooltip)
                        end
                    end

                    if self.offerBackgrounds[lineIndex].setTooltip then
                        self.offerBackgrounds[lineIndex]:setTooltip(offerTooltip)
                    end
                    if self.offerIcons[lineIndex].setTooltip then
                        self.offerIcons[lineIndex]:setTooltip(offerTooltip)
                    end
                    if self.offerLabels[lineIndex].setTooltip then
                        self.offerLabels[lineIndex]:setTooltip(offerTooltip)
                    end
                    if self.offerPriceLabels[lineIndex].setTooltip then
                        self.offerPriceLabels[lineIndex]:setTooltip(offerTooltip)
                    end
                    if self.transactionQtys[lineIndex].setTooltip then
                        self.transactionQtys[lineIndex]:setTooltip(offerTooltip)
                    end

                    lineIndex = lineIndex + 1
                end
            end
        end
    end

    for j = lineIndex, ITEMS_MAX do
        if self.offerIcons[j] then
            self.offerIcons[j]:setVisible(false)
        end
        if self.offerLabels[j] then
            self.offerLabels[j]:setName("")
        end
        if self.offerPriceLabels[j] then
            self.offerPriceLabels[j]:setName("")
        end
        if self.transactionBtns[j] then
            self.transactionBtns[j]:setVisible(false)
        end
        if self.transactionQtys[j] then
            self.transactionQtys[j]:setVisible(false)
        end
    end

    if self.loadingMessage then
        self.scrollPanel:removeChild(self.loadingMessage)
        self.loadingMessage = nil
    end
end

function darkWebUI:onSell()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)

    if not self.darkWebSellOffersLoaded then
        if self.darkWebSellOffersPending then return end
        self.darkWebSellOffersPending = true
        PZLinuxRequestDarkWebSellOffers(self.player, function(result)
            self.darkWebSellOffersPending = false
            if result and result.ok then
                self.darkWebSellOffers = result.offers or {}
                self.darkWebSellOffersLoaded = true
                if result.balance then
                    saveAtmBalance(result.balance, self.player)
                    self.titleLabel:setName("Bank balance: $" .. tostring(result.balance))
                end
                if not self.isClosing then
                    self:onSell()
                end
            end
        end)
        return
    end

    local itemsToSell = {}
    for _, offer in ipairs(self.darkWebSellOffers or {}) do
        local scriptItem = getScriptManager():FindItem(offer.firstItemId)
        local itemName = scriptItem and scriptItem:getDisplayName() or "Unknown Item"
        local iconName = scriptItem and scriptItem:getIcon()
        local iconTex = iconName and (getTexture(iconName) or getTexture("Item_" .. iconName)) or nil
        table.insert(itemsToSell, {
            index = offer.index,
            name = itemName,
            count = offer.count,
            price = offer.price,
            icon = iconTex,
        })
    end

    -- The Sell list is rebuilt from scratch every time this runs (including
    -- right after selling an item, to refresh stock/prices) -- unlike the
    -- Buy list, which pre-allocates a fixed pool of rows once and only
    -- updates their content. Without removing the previous scrollPanel
    -- first, each rebuild stacked a brand new full set of rows on top of
    -- the old one (never detached, just no longer referenced), so every
    -- sale left one more overlapping copy of the list behind, making rows
    -- increasingly unreadable the more items were sold in a row.
    if self.scrollPanel then
        self:removeChild(self.scrollPanel)
        self.scrollPanel = nil
    end

    self.scrollPanel = ISPanel:new(self.width * 0.193, self.height * 0.228, self.width * 0.568, self.height * 0.48)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    self.offerBackgrounds = {}
    self.offerIcons = {}
    self.offerLabels = {}
    self.offerPriceLabels = {}
    self.transactionBtns = {}
    self.transactionQtysSell = {}

    local rowHeight = self.height * 0.045
    local totalHeight = 100 * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    local yOffset = 0
    for _, item in ipairs(itemsToSell) do
        if item.icon then
            local itemIcon = ISImage:new(self.width * 0.01, yOffset, 20, 20, item.icon)
            self.scrollPanel:addChild(itemIcon)
        end

        local itemSellLabel = ISLabel:new(self.width * 0.059, yOffset, 20, item.name, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(itemSellLabel)

        local priceText = " $" .. tostring(item.price) .. " | " .. string.format(
            PZLinuxGetText("IGUI_PZLinux_DarkWeb_Stock"),
            tonumber(item.count) or 0
        )
        local priceLabel = ISLabel:new(self.width * 0.35, yOffset, 20, priceText, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(priceLabel)

        -- A player asked for exactly this: selling used to always take
        -- every matching item the player owned, with no way to sell fewer
        -- -- e.g. wearing one bulletproof vest and owning 2 spares, wanting
        -- to sell only those 2 meant first manually stashing the worn one
        -- away so it wouldn't get swept up too. Quantity box defaults to
        -- "0", same as Buy's, specifically so a stray click on SELL can
        -- never sell anything by accident -- see onSellItem below, which
        -- refuses to even send a request at quantity 0.
        -- buttonX is deliberately left exactly where the SELL button
        -- already sat before this change (proven to fit inside the
        -- scrollPanel, which is only 0.568 * self.width wide) -- the
        -- quantity box is inserted just before it instead of pushing the
        -- button further right, which would overflow that boundary.
        local buttonWidth, buttonHeight = self.width * 0.08, self.height * 0.025
        local buttonX = self.width * 0.48
        local quantityWidth = self.width * 0.035
        local quantityX = buttonX - quantityWidth - 5

        local sellQty = ISTextEntryBox:new("0", quantityX, yOffset, quantityWidth, self.height * 0.024)
        sellQty.backgroundColor = {r=0, g=0, b=0, a=1}
        sellQty:setVisible(true)
        sellQty:initialise()
        sellQty:setOnlyNumbers(true)
        self.scrollPanel:addChild(sellQty)
        self.transactionQtysSell[item.index] = sellQty

        local sellButton = ISButton:new(buttonX, yOffset, buttonWidth, buttonHeight, "SELL", self, function(self, btn)
            local quantitySelling = tonumber(sellQty:getText()) or 0
            self:onSellItem(btn, quantitySelling)
        end)
        sellButton.backgroundColor = {r=0.6, g=0, b=0, a=1}
        sellButton.internal = item.index
        sellButton.price = item.price
        sellButton.count = item.count
        self.scrollPanel:addChild(sellButton)

        yOffset = yOffset + 30
    end
end

-- FILTER
function darkWebUI:OnFilter(button)
    if button.internal == "all" then
        self.filterMode = "all"
    end
    self.searchField:setText("")
    self.searchTextLower = ""
    self:onBuy()
end

function darkWebUI:FilterMatch(rowData)
    -- A sold-out offer used to be filtered out of the list entirely here,
    -- which silently shifted every offer after it up by one visual row.
    -- Since each row is a reused button/quantity-box pair whose bound
    -- offer index gets reassigned on every re-render (see the onBuy loop
    -- below), that shift could leave a player's already-typed quantity
    -- sitting in a row that now points at a completely different item --
    -- clicking BUY there purchases whatever silently slid into that slot,
    -- not what was on screen a moment ago. Sold-out offers now stay in
    -- place and simply render disabled with a "SOLD OUT" label (the rest
    -- of this function already assumed that), so row positions never move
    -- just because stock ran out.
    if self.filterMode == "all" then
        return true
    elseif self.filterMode == "search" then
        local firstId
        if type(rowData.item.id) == "table" then
            firstId = rowData.item.id[1]
        else
            firstId = rowData.item.id
        end
        local scriptItem = getScriptManager():FindItem(firstId)
        if not scriptItem then
            return false
        end

        local itemName = scriptItem:getDisplayName()
        if type(itemName) ~= "string" then
            return false
        end
        local itemNameLower = string.lower(itemName)
        return string.find(itemNameLower, self.searchTextLower, 1, true) ~= nil
    end
    return true
end

-- SEARCH
function darkWebUI:onCommandEnter()
    self:OnSearch()
end

function darkWebUI:OnSearch()
    local searchText = self.searchField:getText()
    if self.noResultsWindow then
        self.noResultsWindow:setVisible(false)
    end
    if self.emptySearchWindow then
        self.emptySearchWindow:setVisible(false)
    end
    if not searchText then
        searchText = ""
    end
    if searchText ~= "" then
        self.searchTextLower = string.lower(searchText)
        self.filterMode = "search"
        self:onBuy()
    else
        self.filterMode = "all"
        self.searchTextLower = ""
        self:onBuy()
    end
end

-- CLICK BUY SELL
function darkWebUI:OnBuyItem(button, quantityTrading)
    local globalVolume = getCore():getOptionSoundVolume() / 50
    if self.isClosing then
        return
    end

    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local offer = currentOffers[button.internal]
    if not offer then return end
    local transactionQty = tonumber(quantityTrading)
    if not transactionQty or transactionQty < 1 then return end
    if transactionQty > (tonumber(offer.stock) or 0) then
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        HaloTextHelper.addGoodText(playerObj, PZLinuxGetText("IGUI_PZLinux_DarkWeb_NotEnoughStock"))
        return
    end

    if button.setEnable then button:setEnable(false) end
    PZLinuxRequestDarkWebBuy(self.player, button.internal, transactionQty, function(result)
        if button.setEnable then button:setEnable(true) end
        if self.isClosing then return end

        if result and result.balance then
            saveAtmBalance(result.balance, playerObj)
            self.titleLabel:setName("Bank balance: $" .. tostring(result.balance))
        end

        if result and result.offerIndex and result.stock ~= nil and currentOffers[result.offerIndex] then
            currentOffers[result.offerIndex].stock = result.stock
            self:onBuy()
        end

        if result and result.ok then
            getSoundManager():PlayWorldSound("buy", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addGoodText(playerObj, PZLinuxGetText("IGUI_PZLinux_Request_MailboxAvailable"))
        else
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            if result and (result.error == "not_enough_stock" or result.error == "offer_expired") then
                HaloTextHelper.addGoodText(playerObj, PZLinuxGetText("IGUI_PZLinux_DarkWeb_NotEnoughStock"))
                if result.error == "offer_expired" then
                    self.darkWebBuyOffersLoaded = false
                    self:onBuy()
                end
            else
                HaloTextHelper.addGoodText(playerObj, "I need money in my bank account")
            end
        end
    end)
end

function darkWebUI:onSellItem(button, quantitySelling)
    local globalVolume = getCore():getOptionSoundVolume() / 50
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    -- Quantity 0 (the default -- see onSell above) means nothing was
    -- actually chosen: do nothing rather than treat a stray click as
    -- "sell everything", the old behavior this box replaces.
    local quantity = tonumber(quantitySelling) or 0
    if quantity < 1 then return end
    if quantity > (tonumber(button.count) or 0) then
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        HaloTextHelper.addBadText(playerObj, "You don't have that many")
        return
    end

    if button.setEnable then button:setEnable(false) end
    PZLinuxRequestDarkWebSell(self.player, button.internal, quantity, function(result)
        if button.setEnable then button:setEnable(true) end
        if self.isClosing then return end

        if result and result.balance then
            saveAtmBalance(result.balance, playerObj)
            self.titleLabel:setName("Bank balance: $" .. tostring(result.balance))
        end

        if result and result.ok then
            getSoundManager():PlayWorldSound("sold", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addGoodText(playerObj, "Drop the package in a mailbox")
            self.darkWebSellOffersLoaded = false
            self:onSell()
        else
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            if result and result.error == "not_enough_owned" then
                HaloTextHelper.addBadText(playerObj, "You don't have that many")
            else
                HaloTextHelper.addBadText(playerObj, "The item is not available")
            end
        end
    end)
end

function darkWebUI:onHelp()
    PZLinuxDarkWebLoadCustomItems()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)

    local helpMessageTitle = "To sell an item, it must be in the main inventory. Once in the inventory,\nclicking 'Sell' will sell all items of that type and a suspicious package\nwill appear in your inventory. To complete the sale, you need to send\nthe item via a mailbox\n\nHere is the list of items that can be bought and sold:"
    local helpMessage = ISLabel:new(self.width * 0.2, self.height * 0.25, 20, helpMessageTitle, 0, 1, 0, 1, UIFont.Small, true)
    self:addChild(helpMessage)

    self.scrollPanel = ISPanel:new(self.width * 0.2, self.height * 0.34, self.width * 0.568, self.height * 0.35)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    local rowHeight = self.height * 0.045
    local totalHeight = #PZLinuxDarkWebItemsTable * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    local yOffset = 0
    for _, itemData in ipairs(PZLinuxDarkWebItemsTable) do
        local itemIds = itemData.id
        local firstItemId = type(itemIds) == "table" and itemIds[1] or itemIds

        local scriptItem = getScriptManager():FindItem(firstItemId)
        local itemName = scriptItem and scriptItem:getDisplayName() or "Unknown Item"
        local iconName = scriptItem and scriptItem:getIcon()
        local iconTex = iconName and (getTexture(iconName) or getTexture("Item_" .. iconName)) or nil

        if iconTex and itemName ~= "Unknown Item" then
            local itemIcon = ISImage:new(self.width * 0.01, yOffset, 20, 20, iconTex)
            self.scrollPanel:addChild(itemIcon)

            local itemLabel = ISLabel:new(self.width * 0.059, yOffset, 20, itemName, 0, 1, 0, 1, UIFont.Small, true)
            self.scrollPanel:addChild(itemLabel)
            yOffset = yOffset + 30
        end

    end
end

-- UI
function darkWebMenu_ShowUI(player)
    local texture = getTexture("media/ui/oldCRT.png")
    if not texture then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()

    local maxW = realScreenW * 0.70
    local maxH = realScreenH * 0.70
    local texW = texture:getWidth()
    local texH = texture:getHeight()

    local ratioX, ratioY = maxW / texW, maxH / texH
    local scale  = math.min(ratioX, ratioY)
    local finalW, finalH = math.floor(texW * scale), math.floor(texH * scale)

    local modData = PZLinuxGetModData(player)
    if not modData then return end
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = darkWebUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
    ui:startUI()

    return ui
end
