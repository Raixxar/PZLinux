-- Sell Surplus: the inverse of Requests, Dark Web-styled. Every sellable
-- item independently has a small daily chance of being wanted, for a random
-- quantity the player must fully own to sell. Selling is instant (like Dark
-- Web): the goods disappear immediately, replaced by a priced package that
-- must still be dropped at a mailbox to actually get paid. A negotiation
-- button lets the player gamble for a better price, at the risk of the
-- buyer walking away entirely.

PZLinuxSellUI = ISPanel:derive("PZLinuxSellUI")

local ITEMS_MAX = 40

local function PZLinuxSellText(key, fallback, ...)
    return PZLinuxFormatText(key, fallback, ...)
end

local function PZLinuxSellCountOwned(playerObj, itemName)
    local items = playerObj:getInventory():getItems()
    local count = 0
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getFullType and item:getFullType() == itemName then
            count = count + 1
        end
    end
    return count
end

function PZLinuxSellUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    o.offers = {}
    return o
end

function PZLinuxSellUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self:addChild(self.topBar)
    self.topBar.parent = self

    function self.topBar.onMouseDown(topBar, _x, _y)
        topBar.parent.isDragging = true
        topBar.parent.initialX = topBar.parent:getX()
        topBar.parent.initialY = topBar.parent:getY()
        topBar.parent.mouseStartX = getMouseX()
        topBar.parent.mouseStartY = getMouseY()
    end

    function self.topBar.onMouseMove(topBar, _x, _y)
        if not topBar.parent.isDragging then return end
        topBar.parent:setX(topBar.parent.initialX + getMouseX() - topBar.parent.mouseStartX)
        topBar.parent:setY(topBar.parent.initialY + getMouseY() - topBar.parent.mouseStartY)
    end

    function self.topBar.onMouseUp(topBar, _x, _y)
        topBar.parent.isDragging = false
        local playerObj = PZLinuxGetPlayer(topBar.parent.player)
        local modData = playerObj and playerObj:getModData()
        if modData then
            modData.PZLinuxUIX = topBar.parent:getX()
            modData.PZLinuxUIY = topBar.parent:getY()
        end
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:initialise()
    self.topBar:addChild(self.stopButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onBack)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.titleLabel = ISLabel:new(
        self.width * 0.20, self.height * 0.17, self.height * 0.03,
        PZLinuxSellText("IGUI_PZLinux_Sell_Title", "SELL GOODS"),
        0, 1, 0, 1, UIFont.Medium, true
    )
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.statusLabel = ISLabel:new(
        self.width * 0.20, self.height * 0.215, self.height * 0.025,
        PZLinuxSellText("IGUI_PZLinux_Sell_Loading", "Checking who wants to buy..."),
        0, 1, 0, 1, UIFont.Small, true
    )
    self.statusLabel:initialise()
    self.topBar:addChild(self.statusLabel)

    -- Matches Dark Web's scroll area proportions -- the CRT texture's
    -- visible screen area is smaller than the full image (there is a bezel
    -- baked into the art), so a taller panel here visually overflows past
    -- the monitor frame even though it is numerically within self.height.
    -- Raised slightly and shortened compared to the first pass: there was
    -- too big a gap under the status text and not enough margin above the
    -- bottom bezel.
    self.scrollPanel = ISPanel:new(self.width * 0.193, self.height * 0.24, self.width * 0.568, self.height * 0.43)
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
    self.scrollPanel.borderColor = {r=0, g=0.5, b=0, a=0}
    self.topBar:addChild(self.scrollPanel)
    self.scrollPanel:addScrollBars(true)

    self.rowIcons = {}
    self.rowLabels = {}
    self.rowPriceLabels = {}
    self.rowSellButtons = {}
    self.rowNegotiateButtons = {}

    local rowHeight = math.max(38, self.height * 0.055)
    self.scrollPanel:setScrollHeight(ITEMS_MAX * rowHeight + 10)
    self.scrollPanel.onMouseWheel = function(scrollSelf, del)
        if scrollSelf:getScrollHeight() > 0 then
            scrollSelf:setYScroll(scrollSelf:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    for i = 1, ITEMS_MAX do
        local yOffset = 5 + (i - 1) * rowHeight
        local rowBackground = ISPanel:new(5, yOffset, self.scrollPanel.width - 23, rowHeight)
        rowBackground.backgroundColor = {r=0, g=0, b=0, a=0}
        rowBackground.borderColor = {r=0, g=0, b=0, a=0}
        rowBackground:initialise()
        self.scrollPanel:addChild(rowBackground)

        local iconSize = 28
        local iconImg = ISImage:new(5, (rowHeight - iconSize) / 2, iconSize, iconSize, nil)
        iconImg:initialise()
        rowBackground:addChild(iconImg)
        self.rowIcons[i] = iconImg

        local labelX = 5 + iconSize + 5
        local nameLabel = ISLabel:new(labelX, math.max(0, (rowHeight - 30) / 2), 20, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        rowBackground:addChild(nameLabel)
        self.rowLabels[i] = nameLabel

        local priceLabel = ISLabel:new(labelX, math.max(0, (rowHeight - 30) / 2) + 15, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        priceLabel:initialise()
        rowBackground:addChild(priceLabel)
        self.rowPriceLabels[i] = priceLabel

        local buttonHeight = math.min(22, rowHeight * 0.4)
        local negotiateWidth = math.max(70, self.scrollPanel.width * 0.16)
        local sellWidth = math.max(60, self.scrollPanel.width * 0.13)
        local sellX = rowBackground.width - sellWidth - 6
        local negotiateX = sellX - negotiateWidth - 6

        local negotiateButton = ISButton:new(negotiateX, (rowHeight - buttonHeight) / 2, negotiateWidth, buttonHeight, PZLinuxSellText("IGUI_PZLinux_Sell_Negotiate", "NEGOTIATE"), self, self.onNegotiateItem)
        negotiateButton.backgroundColor = {r=0.4, g=0.3, b=0, a=1}
        negotiateButton.internal = i
        negotiateButton:initialise()
        negotiateButton:setVisible(false)
        rowBackground:addChild(negotiateButton)
        self.rowNegotiateButtons[i] = negotiateButton

        local sellButton = ISButton:new(sellX, (rowHeight - buttonHeight) / 2, sellWidth, buttonHeight, PZLinuxSellText("IGUI_PZLinux_Sell_SellButton", "SELL"), self, self.onSellItem)
        sellButton.backgroundColor = {r=0, g=0.4, b=0, a=1}
        sellButton.internal = i
        sellButton:initialise()
        sellButton:setVisible(false)
        rowBackground:addChild(sellButton)
        self.rowSellButtons[i] = sellButton

        function rowBackground:onMouseMove(_dx, _dy) self.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0.3} end
        function rowBackground:onMouseMoveOutside(_dx, _dy) self.backgroundColor = {r=0, g=0, b=0, a=0} end
    end

    self:refreshOffers()
end

function PZLinuxSellUI:refreshOffers()
    if self.offersPending then return end
    self.offersPending = true
    local playerObj = PZLinuxGetPlayer(self.player)
    PZLinuxRequestSellGetOffers(playerObj, function(result)
        self.offersPending = false
        if self.isClosing then return end
        if not result or not result.ok then
            self.statusLabel:setName(PZLinuxSellText("IGUI_PZLinux_Sell_Unavailable", "Sell service unavailable."))
            return
        end
        self.offers = result.offers or {}
        if #self.offers == 0 then
            self.statusLabel:setName(PZLinuxSellText(
                "IGUI_PZLinux_Sell_NoBuyerToday",
                "Nobody wants to buy anything today. Come back tomorrow."
            ))
        else
            self.statusLabel:setName(PZLinuxSellText(
                "IGUI_PZLinux_Sell_BuyersToday", "Buyers looking for %s item(s) today.", #self.offers
            ))
        end
        self:renderOffers()
    end)
end

function PZLinuxSellUI:renderOffers()
    local playerObj = PZLinuxGetPlayer(self.player)
    for i = 1, ITEMS_MAX do
        local offer = self.offers[i]
        if offer then
            local scriptItem = getScriptManager and getScriptManager():FindItem(offer.name)
            local displayName = (scriptItem and scriptItem:getDisplayName() and scriptItem:getDisplayName():match("%S"))
                and scriptItem:getDisplayName() or offer.name
            local iconName = scriptItem and scriptItem:getIcon()
            local iconTex = iconName and (getTexture(iconName) or getTexture("Item_" .. iconName)) or nil

            if iconTex then
                self.rowIcons[i].texture = iconTex
                self.rowIcons[i]:setVisible(true)
            else
                self.rowIcons[i].texture = nil
                self.rowIcons[i]:setVisible(false)
            end

            local owned = PZLinuxSellCountOwned(playerObj, offer.name)
            self.rowLabels[i]:setName(tostring(displayName) .. " (x" .. tostring(offer.quantity) .. ")")

            local priceText = "$" .. tostring(offer.total)
                .. "  |  " .. PZLinuxSellText("IGUI_PZLinux_Sell_Owned", "You have: %s/%s", owned, offer.quantity)
            if offer.greatDeal then
                priceText = priceText .. "  " .. PZLinuxSellText("IGUI_PZLinux_Sell_GreatDealTag", "(great deal!)")
            end
            self.rowPriceLabels[i]:setName(priceText)

            self.rowSellButtons[i].internal = i
            self.rowSellButtons[i]:setVisible(true)
            self.rowSellButtons[i]:setEnable(owned >= offer.quantity)

            self.rowNegotiateButtons[i].internal = i
            self.rowNegotiateButtons[i]:setVisible(true)
        else
            self.rowIcons[i]:setVisible(false)
            self.rowLabels[i]:setName("")
            self.rowPriceLabels[i]:setName("")
            self.rowSellButtons[i]:setVisible(false)
            self.rowNegotiateButtons[i]:setVisible(false)
        end
    end
end

function PZLinuxSellUI:onSellItem(button)
    local offer = self.offers[button.internal]
    if not offer then return end
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    button:setEnable(false)
    PZLinuxRequestSellSell(playerObj, offer.name, function(result)
        if self.isClosing then return end
        local globalVolume = getCore():getOptionSoundVolume() / 50
        if result and result.ok then
            getSoundManager():PlayWorldSound("sold", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            local message = result.greatDeal
                and PZLinuxSellText("IGUI_PZLinux_Sell_GreatDeal", "Great deal! Sold for $%s", result.total)
                or PZLinuxSellText("IGUI_PZLinux_Sell_Sold", "Sold for $%s", result.total)
            HaloTextHelper.addGoodText(playerObj, message)
            HaloTextHelper.addGoodText(playerObj, PZLinuxSellText(
                "IGUI_PZLinux_Sell_DropAtMailbox", "Bring the package to any mailbox to get paid."
            ))
        else
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            if result and result.error == "missing_items" then
                HaloTextHelper.addBadText(playerObj, PZLinuxSellText(
                    "IGUI_PZLinux_Sell_MissingItems", "You do not have enough of this item."
                ))
            else
                HaloTextHelper.addBadText(playerObj, PZLinuxSellText("IGUI_PZLinux_Sell_Rejected", "This sale was rejected."))
            end
        end
        self:refreshOffers()
    end)
end

function PZLinuxSellUI:onNegotiateItem(button)
    local offer = self.offers[button.internal]
    if not offer then return end
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    button:setEnable(false)
    PZLinuxRequestSellNegotiate(playerObj, offer.name, function(result)
        button:setEnable(true)
        if self.isClosing then return end
        local globalVolume = getCore():getOptionSoundVolume() / 50
        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addBadText(playerObj, PZLinuxSellText("IGUI_PZLinux_Sell_Rejected", "This sale was rejected."))
            self:refreshOffers()
            return
        end

        if result.withdrawn then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addBadText(playerObj, PZLinuxSellText(
                "IGUI_PZLinux_Sell_NegotiateWithdrawn", "The buyer got annoyed and walked away."
            ))
        else
            getSoundManager():PlayWorldSound("ircNotification", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            HaloTextHelper.addGoodText(playerObj, PZLinuxSellText(
                "IGUI_PZLinux_Sell_NegotiateSuccess", "The buyer agreed! New offer: $%s", result.total
            ))
        end
        self:refreshOffers()
    end)
end

function PZLinuxSellUI:onBack(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local playerObj = PZLinuxGetPlayer(self.player)
    local modData = playerObj and playerObj:getModData()
    if modData then modData.PZLinuxUIOpenMenu = 1 end
end

function PZLinuxSellUI:onCloseX(_button)
    self.isClosing = true
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then playerObj:StopAllActionQueue() end
end

function sellMenu_ShowUI(player)
    local playerObj = PZLinuxGetPlayer(player)
    local texture = getTexture("media/ui/oldCRT.png")
    if not playerObj or not texture then return end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local scale = math.min(screenWidth * 0.70 / texture:getWidth(), screenHeight * 0.70 / texture:getHeight())
    local width = math.floor(texture:getWidth() * scale)
    local height = math.floor(texture:getHeight() * scale)
    local modData = playerObj:getModData()
    local x = modData.PZLinuxUIX or (screenWidth - width) / 2
    local y = modData.PZLinuxUIY or (screenHeight - height) / 2

    local ui = PZLinuxSellUI:new(x, y, width, height, playerObj)
    local background = ISImage:new(0, 0, width, height, texture)
    background.scaled = true
    background.scaledWidth = width
    background.scaledHeight = height
    ui:addChild(background)
    ui.centeredImage = background
    ui:initialise()
    ui:addToUIManager()
    return ui
end
