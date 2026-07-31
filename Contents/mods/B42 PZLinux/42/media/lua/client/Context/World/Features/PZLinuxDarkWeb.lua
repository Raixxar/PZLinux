-- Dark Web UI - by Raixxar 
-- Updated : 25/01/25

darkWebUI = ISPanel:derive("darkWebUI")

local ITEMS_MAX = 50
local currentOffers = {}

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

    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    if modData.PZLinuxUISFX == 0 then
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    else
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    end

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
    self.transactionBtns = {}
    self.transactionQtys = {}

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
        local labelNameY = (rowHeight - 16) / 2
        local nameLabel  = ISLabel:new(labelNameX, labelNameY, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        offerBackground:addChild(nameLabel)
        self.offerLabels[i] = nameLabel

        local labelPriceX = self.width * 0.355
        local priceLabel = ISLabel:new(labelPriceX, labelNameY, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        priceLabel:initialise()
        offerBackground:addChild(priceLabel)
        self.offerPriceLabels[i] = priceLabel
        
        local buttonWidth, buttonHeight = self.width * 0.08, self.height * 0.025
        local transactionQty = ISTextEntryBox:new("0", self.width * 0.415, (rowHeight - buttonHeight - 2) / 2, self.width * 0.03, self.height * 0.024)
        transactionQty.backgroundColor = {r=0, g=0, b=0, a=1}
        transactionQty.internal = i
        transactionQty:setVisible(true)
        transactionQty:initialise()
        transactionQty:setOnlyNumbers(true)
        offerBackground:addChild(transactionQty)
        self.transactionQtys[i] = transactionQty
       
        local transactionBtn = ISButton:new(offerBackground.width - buttonWidth - 10, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight, "", self, function(self, btn)
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

function darkWebUI:onSFXOn(_button)
    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUISFX = 0
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

function darkWebUI:onSFXOff(_button)
    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUISFX = 1
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
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
                        if #displayName > 37 then
                            displayName = displayName:sub(1, 35) .. "..."
                        end
                        self.offerLabels[lineIndex]:setName(displayName)
                    end

                    if self.offerPriceLabels[lineIndex] then
                        self.offerPriceLabels[lineIndex]:setName("$" .. tostring(rowData.price))
                    end

                    if self.transactionQtys[lineIndex] then
                        self.transactionQtys[lineIndex]:setVisible(true)
                    end

                    if self.transactionBtns[lineIndex] then
                        self.transactionBtns[lineIndex].internal = i
                        if rowData.transactionType == "Buy" then
                            self.transactionBtns[lineIndex]:setTitle("Buy")
                            self.transactionBtns[lineIndex].backgroundColor = {r=0, g=0.6, b=0, a=1}
                        end
                        self.transactionBtns[lineIndex]:setVisible(true)
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

        local iconSize = 28
        local itemSellLabel = ISLabel:new(self.width * 0.059, yOffset, 20, item.name, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(itemSellLabel)

        local priceLabel = ISLabel:new(self.width * 0.41, yOffset, 20, " $" .. item.price, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(priceLabel)

        local buttonWidth, buttonHeight = self.width * 0.08, self.height * 0.025
        local sellButton = ISButton:new(self.width * 0.48, yOffset, buttonWidth, buttonHeight, "SELL", self, self.onSellItem)
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

    if button.setEnable then button:setEnable(false) end
    PZLinuxRequestDarkWebBuy(self.player, button.internal, transactionQty, function(result)
        if button.setEnable then button:setEnable(true) end
        if self.isClosing then return end

        if result and result.balance then
            saveAtmBalance(result.balance, playerObj)
            self.titleLabel:setName("Bank balance: $" .. tostring(result.balance))
        end

        if result and result.ok then
            getSoundManager():PlayWorldSound("buy", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addGoodText(playerObj, "Item available in a mailbox")
        else
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addGoodText(playerObj, "I need money in my bank account")
        end
    end)
end

function darkWebUI:onSellItem(button)
    local globalVolume = getCore():getOptionSoundVolume() / 50
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    if button.setEnable then button:setEnable(false) end
    PZLinuxRequestDarkWebSell(self.player, button.internal, function(result)
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
            HaloTextHelper.addBadText(playerObj, "The item is not available")
        end
    end)
end

function darkWebUI:onHelp()
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
        local itemPrice = itemData.Price
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
