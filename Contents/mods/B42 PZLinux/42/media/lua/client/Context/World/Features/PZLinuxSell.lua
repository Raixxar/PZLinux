-- Sell Surplus: the inverse of Requests. Once per game day there is a small
-- chance a buyer wants exactly one category; the player picks items they
-- currently hold in their main inventory, gets a (deliberately bad,
-- occasionally great) price quote, then must accept it -- which turns the
-- goods into a priced package, Dark Web style -- and drop that package at a
-- mailbox to actually get paid.

PZLinuxSellUI = ISPanel:derive("PZLinuxSellUI")

local ITEMS_PER_PAGE = 5

local function PZLinuxSellText(key, fallback, ...)
    return PZLinuxFormatText(key, fallback, ...)
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
    o.selected = {}
    o.currentPage = 1
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
        PZLinuxSellText("IGUI_PZLinux_Sell_Title", "SELL SURPLUS"),
        0, 1, 0, 1, UIFont.Medium, true
    )
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.content = ISRichTextPanel:new(self.width * 0.20, self.height * 0.24, self.width * 0.57, self.height * 0.14)
    self.content.backgroundColor = {r=0, g=0, b=0, a=0}
    self.content.borderColor = {r=0, g=0, b=0, a=0}
    self.content.autosetheight = false
    self.content.text = "<RGB:0,1,0>" .. PZLinuxSellText("IGUI_PZLinux_Sell_Loading", "Checking for a buyer...")
    self.content:initialise()
    self.content:instantiate()
    self.content:paginate()
    self.topBar:addChild(self.content)

    self.itemButtons = {}

    self.prevPageButton = ISButton:new(self.width * 0.20, self.height * 0.76, self.width * 0.12, self.height * 0.04, "<", self, self.onPrevPage)
    self.prevPageButton.textColor = {r=0, g=1, b=0, a=1}
    self.prevPageButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.prevPageButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.prevPageButton:initialise()
    self.prevPageButton:setVisible(false)
    self.topBar:addChild(self.prevPageButton)

    self.nextPageButton = ISButton:new(self.width * 0.65, self.height * 0.76, self.width * 0.12, self.height * 0.04, ">", self, self.onNextPage)
    self.nextPageButton.textColor = {r=0, g=1, b=0, a=1}
    self.nextPageButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.nextPageButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.nextPageButton:initialise()
    self.nextPageButton:setVisible(false)
    self.topBar:addChild(self.nextPageButton)

    self.sellButton = ISButton:new(
        self.width * 0.20, self.height * 0.86, self.width * 0.27, self.height * 0.05,
        PZLinuxSellText("IGUI_PZLinux_Sell_SellSelected", "GET A QUOTE"), self, self.onSellSelected
    )
    self.sellButton.textColor = {r=0, g=1, b=0, a=1}
    self.sellButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.sellButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.sellButton:initialise()
    self.sellButton:setVisible(false)
    self.topBar:addChild(self.sellButton)

    self.acceptButton = ISButton:new(
        self.width * 0.20, self.height * 0.86, self.width * 0.27, self.height * 0.05,
        PZLinuxSellText("IGUI_PZLinux_Sell_Accept", "ACCEPT"), self, self.onAcceptOffer
    )
    self.acceptButton.textColor = {r=0, g=1, b=0, a=1}
    self.acceptButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.acceptButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.acceptButton:initialise()
    self.acceptButton:setVisible(false)
    self.topBar:addChild(self.acceptButton)

    self.cancelButton = ISButton:new(
        self.width * 0.50, self.height * 0.86, self.width * 0.27, self.height * 0.05,
        PZLinuxSellText("IGUI_PZLinux_Sell_Cancel", "CANCEL"), self, self.onCancelOffer
    )
    self.cancelButton.textColor = {r=0, g=1, b=0, a=1}
    self.cancelButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.cancelButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.cancelButton:initialise()
    self.cancelButton:setVisible(false)
    self.topBar:addChild(self.cancelButton)

    self:refreshDemand()
end

function PZLinuxSellUI:setContentText(text)
    if not self.content then return end
    self.content.text = "<RGB:0,1,0>" .. text
    self.content:paginate()
end

function PZLinuxSellUI:hideSelectionControls()
    for _, entry in ipairs(self.itemButtons) do
        entry.button:setVisible(false)
    end
    self.itemButtons = {}
    self.prevPageButton:setVisible(false)
    self.nextPageButton:setVisible(false)
    self.sellButton:setVisible(false)
    self.acceptButton:setVisible(false)
    self.cancelButton:setVisible(false)
end

function PZLinuxSellUI:refreshDemand()
    local playerObj = PZLinuxGetPlayer(self.player)
    PZLinuxRequestSellRefreshDemand(playerObj, function(result)
        if self.isClosing or not self.content then return end
        if not result or not result.ok then
            self:hideSelectionControls()
            self:setContentText(PZLinuxSellText("IGUI_PZLinux_Sell_Unavailable", "Sell service unavailable."))
            return
        end

        if not result.available then
            self:hideSelectionControls()
            self:setContentText(PZLinuxSellText(
                "IGUI_PZLinux_Sell_NoBuyerToday",
                "No buyer today. Come back tomorrow."
            ))
            return
        end

        self.contractId = result.contractId
        self.contractName = result.contractName or tostring(result.contractId)
        self.currentPage = 1
        self.selected = {}
        self:showCategoryItems()
    end)
end

function PZLinuxSellUI:getOwnedCategoryItems()
    local playerObj = PZLinuxGetPlayer(self.player)
    local definition = PZLinuxRequestsGetDefinition and PZLinuxRequestsGetDefinition(self.contractId)
    local categoryItems = (definition and definition.items) or {}
    if not playerObj then return {} end

    local counts = {}
    local items = playerObj:getInventory():getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local fullType = item and item.getFullType and item:getFullType()
        if fullType then counts[fullType] = (counts[fullType] or 0) + 1 end
    end

    local owned = {}
    for _, itemName in ipairs(categoryItems) do
        if (counts[itemName] or 0) > 0 then
            table.insert(owned, { name = itemName, count = counts[itemName] })
        end
    end
    return owned
end

function PZLinuxSellUI:showCategoryItems()
    for _, entry in ipairs(self.itemButtons) do
        entry.button:setVisible(false)
    end
    self.itemButtons = {}
    self.acceptButton:setVisible(false)
    self.cancelButton:setVisible(false)

    local ownedItems = self:getOwnedCategoryItems()
    if #ownedItems == 0 then
        self.prevPageButton:setVisible(false)
        self.nextPageButton:setVisible(false)
        self.sellButton:setVisible(false)
        self:setContentText(PZLinuxSellText(
            "IGUI_PZLinux_Sell_NothingToSell",
            "A buyer today is interested in: %s\nYou have none of it in your main inventory.",
            self.contractName or ""
        ))
        return
    end

    local pageCount = math.max(1, math.ceil(#ownedItems / ITEMS_PER_PAGE))
    self.currentPage = math.min(math.max(1, self.currentPage), pageCount)
    local startIndex = (self.currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #ownedItems)

    local y = 0.42
    for index = startIndex, endIndex do
        local entry = ownedItems[index]
        local scriptItem = getScriptManager and getScriptManager():FindItem(entry.name)
        local displayName = (scriptItem and scriptItem:getDisplayName() and scriptItem:getDisplayName():match("%S"))
            and scriptItem:getDisplayName() or entry.name

        local isSelected = self.selected[entry.name] and true or false
        local label = tostring(displayName) .. " x" .. tostring(entry.count) .. (isSelected and " [SELECTED]" or "")
        local button = ISButton:new(self.width * 0.20, self.height * y, self.width * 0.57, self.height * 0.045, label, self, self.onToggleItem)
        button.textColor = isSelected and {r=1, g=1, b=0, a=1} or {r=0, g=1, b=0, a=1}
        button.backgroundColor = {r=0, g=0, b=0, a=0.5}
        button.borderColor = {r=0, g=1, b=0, a=0.5}
        button.itemName = entry.name
        button:initialise()
        button:setVisible(true)
        self.topBar:addChild(button)
        table.insert(self.itemButtons, { button = button, itemName = entry.name })
        y = y + 0.055
    end

    self.prevPageButton:setVisible(pageCount > 1)
    self.prevPageButton:setEnable(self.currentPage > 1)
    self.nextPageButton:setVisible(pageCount > 1)
    self.nextPageButton:setEnable(self.currentPage < pageCount)
    self.sellButton:setVisible(true)

    local selectedCount = 0
    for _ in pairs(self.selected) do selectedCount = selectedCount + 1 end
    self:setContentText(
        PZLinuxSellText("IGUI_PZLinux_Sell_BuyerWants", "A buyer today is interested in: %s", self.contractName or "")
        .. "<LINE>" .. PZLinuxSellText("IGUI_PZLinux_Sell_SelectedCount", "Selected item types: %s", selectedCount)
    )
end

function PZLinuxSellUI:onPrevPage(_button)
    self.currentPage = math.max(1, self.currentPage - 1)
    self:showCategoryItems()
end

function PZLinuxSellUI:onNextPage(_button)
    self.currentPage = self.currentPage + 1
    self:showCategoryItems()
end

function PZLinuxSellUI:onToggleItem(button)
    if self.selected[button.itemName] then
        self.selected[button.itemName] = nil
    else
        self.selected[button.itemName] = true
    end
    self:showCategoryItems()
end

function PZLinuxSellUI:onSellSelected(_button)
    local itemNames = {}
    for itemName in pairs(self.selected) do
        table.insert(itemNames, itemName)
    end
    if #itemNames == 0 then return end

    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    self.sellButton:setEnable(false)
    PZLinuxRequestSellQuote(playerObj, self.contractId, itemNames, function(result)
        self.sellButton:setEnable(true)
        if self.isClosing or not self.content then return end
        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(getCore():getOptionSoundVolume() / 50)
            HaloTextHelper.addBadText(playerObj, PZLinuxSellText("IGUI_PZLinux_Sell_Rejected", "This sale was rejected."))
            return
        end

        self:hideSelectionControls()
        self.quoteTotal = result.total
        self.quoteGreatDeal = result.greatDeal

        local lines
        if result.greatDeal then
            lines = { PZLinuxSellText("IGUI_PZLinux_Sell_GreatDeal", "A buyer really wants this! Offer: $%s", result.total) }
        else
            lines = { PZLinuxSellText("IGUI_PZLinux_Sell_Offer", "Offer: $%s", result.total) }
        end
        table.insert(lines, PZLinuxSellText(
            "IGUI_PZLinux_Sell_AcceptOrCancel",
            "Accept to hand over the items now, or cancel. Either way, no one will buy today after this."
        ))
        self:setContentText(table.concat(lines, "<LINE>"))
        self.acceptButton:setVisible(true)
        self.cancelButton:setVisible(true)
    end)
end

function PZLinuxSellUI:onAcceptOffer(_button)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    self.acceptButton:setEnable(false)
    self.cancelButton:setEnable(false)
    PZLinuxRequestSellAcceptOffer(playerObj, function(result)
        self.acceptButton:setEnable(true)
        self.cancelButton:setEnable(true)
        if self.isClosing or not self.content then return end

        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(getCore():getOptionSoundVolume() / 50)
            if result and result.error == "missing_items" then
                HaloTextHelper.addBadText(playerObj, PZLinuxSellText(
                    "IGUI_PZLinux_Sell_MissingItems",
                    "You no longer have all the promised items."
                ))
                return
            end
            HaloTextHelper.addBadText(playerObj, PZLinuxSellText("IGUI_PZLinux_Sell_Rejected", "This sale was rejected."))
            return
        end

        self.acceptButton:setVisible(false)
        self.cancelButton:setVisible(false)
        self:setContentText(PZLinuxSellText(
            "IGUI_PZLinux_Sell_DropAtMailbox",
            "Deal! Bring the package to any mailbox to get paid."
        ))
    end)
end

function PZLinuxSellUI:onCancelOffer(_button)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    self.acceptButton:setEnable(false)
    self.cancelButton:setEnable(false)
    PZLinuxRequestSellCancelOffer(playerObj, function(result)
        if self.isClosing or not self.content then return end
        self.acceptButton:setVisible(false)
        self.cancelButton:setVisible(false)
        if not result or not result.ok then return end
        self:setContentText(PZLinuxSellText(
            "IGUI_PZLinux_Sell_NoBuyerToday",
            "No one wants to buy items anymore. Come back tomorrow."
        ))
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
