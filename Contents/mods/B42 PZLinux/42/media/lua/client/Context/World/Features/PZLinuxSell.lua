-- Sell Surplus: the inverse of Requests. Once per game day there is a small
-- chance a buyer wants exactly one category; the player picks up to a few
-- items from it, gets a (deliberately bad, occasionally great) price quote,
-- and must drop the items at a mailbox to actually get paid.

PZLinuxSellUI = ISPanel:derive("PZLinuxSellUI")

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
    o.selectedCount = 0
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

    self.content = ISRichTextPanel:new(self.width * 0.20, self.height * 0.24, self.width * 0.57, self.height * 0.30)
    self.content.backgroundColor = {r=0, g=0, b=0, a=0}
    self.content.borderColor = {r=0, g=0, b=0, a=0}
    self.content.autosetheight = false
    self.content.text = "<RGB:0,1,0>" .. PZLinuxSellText("IGUI_PZLinux_Sell_Loading", "Checking for a buyer...")
    self.content:initialise()
    self.content:instantiate()
    self.content:paginate()
    self.topBar:addChild(self.content)

    self.itemButtons = {}
    self.currentPage = 1

    self.sellButton = ISButton:new(
        self.width * 0.20, self.height * 0.86, self.width * 0.27, self.height * 0.05,
        PZLinuxSellText("IGUI_PZLinux_Sell_SellSelected", "SELL SELECTED"), self, self.onSellSelected
    )
    self.sellButton.textColor = {r=0, g=1, b=0, a=1}
    self.sellButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.sellButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.sellButton:initialise()
    self.sellButton:setVisible(false)
    self.topBar:addChild(self.sellButton)

    self.resetButton = ISButton:new(
        self.width * 0.50, self.height * 0.86, self.width * 0.27, self.height * 0.05,
        PZLinuxSellText("IGUI_PZLinux_Sell_ResetSelection", "RESET SELECTION"), self, self.onResetSelection
    )
    self.resetButton.textColor = {r=0, g=1, b=0, a=1}
    self.resetButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.resetButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.resetButton:initialise()
    self.resetButton:setVisible(false)
    self.topBar:addChild(self.resetButton)

    self:refreshDemand()
end

function PZLinuxSellUI:updateContentText()
    if not self.content then return end
    local maxCount = tonumber(PZLinux.Config.Sell and PZLinux.Config.Sell.maxItemsPerSale) or 6
    local lines = {
        PZLinuxSellText("IGUI_PZLinux_Sell_BuyerWants", "A buyer today is interested in: %s", self.contractName or ""),
        PZLinuxSellText("IGUI_PZLinux_Sell_SelectedCount", "Selected: %s / %s", self.selectedCount, maxCount),
        "",
    }
    for _, entry in ipairs(self.itemButtons) do
        local count = self.selected[entry.itemName] or 0
        if count > 0 then
            table.insert(lines, tostring(entry.displayName) .. " x" .. tostring(count))
        end
    end
    self.content.text = "<RGB:0,1,0>" .. table.concat(lines, "<LINE>")
    self.content:paginate()
end

function PZLinuxSellUI:refreshDemand()
    local playerObj = PZLinuxGetPlayer(self.player)
    PZLinuxRequestSellRefreshDemand(playerObj, function(result)
        if self.isClosing or not self.content then return end
        if not result or not result.ok then
            self.content.text = "<RGB:1,0.7,0>" .. PZLinuxSellText(
                "IGUI_PZLinux_Sell_Unavailable", "Sell service unavailable."
            )
            self.content:paginate()
            return
        end

        if not result.available then
            self.content.text = "<RGB:0,1,0>" .. PZLinuxSellText(
                "IGUI_PZLinux_Sell_NoBuyerToday",
                "No buyer today. Come back tomorrow."
            )
            self.content:paginate()
            return
        end

        self.contractId = result.contractId
        self.contractName = result.contractName or tostring(result.contractId)
        self:showCategoryItems()
    end)
end

function PZLinuxSellUI:showCategoryItems()
    for _, entry in ipairs(self.itemButtons) do
        entry.button:setVisible(false)
    end
    self.itemButtons = {}
    self.selected = {}
    self.selectedCount = 0

    local definition = PZLinuxRequestsGetDefinition and PZLinuxRequestsGetDefinition(self.contractId)
    local items = (definition and definition.items) or {}

    local y = 0.42
    local itemsPerPage = 6
    local startIndex = (self.currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #items)

    for index = startIndex, endIndex do
        local itemName = items[index]
        local scriptItem = getScriptManager and getScriptManager():FindItem(itemName)
        local displayName = (scriptItem and scriptItem:getDisplayName() and scriptItem:getDisplayName():match("%S"))
            and scriptItem:getDisplayName() or itemName

        local button = ISButton:new(self.width * 0.20, self.height * y, self.width * 0.57, self.height * 0.045, displayName, self, self.onToggleItem)
        button.textColor = {r=0, g=1, b=0, a=1}
        button.backgroundColor = {r=0, g=0, b=0, a=0.5}
        button.borderColor = {r=0, g=1, b=0, a=0.5}
        button.itemName = itemName
        button:initialise()
        button:setVisible(true)
        self.topBar:addChild(button)
        table.insert(self.itemButtons, { button = button, itemName = itemName, displayName = displayName })
        y = y + 0.055
    end

    self.sellButton:setVisible(true)
    self.resetButton:setVisible(true)
    self:updateContentText()
end

function PZLinuxSellUI:onToggleItem(button)
    local maxCount = tonumber(PZLinux.Config.Sell and PZLinux.Config.Sell.maxItemsPerSale) or 6
    if self.selectedCount >= maxCount then return end
    self.selected[button.itemName] = (self.selected[button.itemName] or 0) + 1
    self.selectedCount = self.selectedCount + 1
    self:updateContentText()
end

function PZLinuxSellUI:onResetSelection(_button)
    self.selected = {}
    self.selectedCount = 0
    self:updateContentText()
end

function PZLinuxSellUI:onSellSelected(_button)
    if self.selectedCount <= 0 then return end
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local items = {}
    for itemName, count in pairs(self.selected) do
        for _ = 1, count do
            table.insert(items, { name = itemName })
        end
    end

    self.sellButton:setEnable(false)
    PZLinuxRequestSellQuote(playerObj, self.contractId, items, function(result)
        self.sellButton:setEnable(true)
        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(getCore():getOptionSoundVolume() / 50)
            HaloTextHelper.addBadText(playerObj, PZLinuxSellText("IGUI_PZLinux_Sell_Rejected", "This sale was rejected."))
            return
        end

        for _, entry in ipairs(self.itemButtons) do
            entry.button:setVisible(false)
        end
        self.itemButtons = {}
        self.sellButton:setVisible(false)
        self.resetButton:setVisible(false)

        local lines
        if result.greatDeal then
            lines = {
                PZLinuxSellText("IGUI_PZLinux_Sell_GreatDeal", "A buyer really wants this! Offer: $%s", result.total),
            }
        else
            lines = {
                PZLinuxSellText("IGUI_PZLinux_Sell_Offer", "Offer: $%s", result.total),
            }
        end
        table.insert(lines, PZLinuxSellText(
            "IGUI_PZLinux_Sell_DropAtMailbox",
            "Bring the items to any mailbox to complete the sale."
        ))
        self.content.text = "<RGB:0,1,0>" .. table.concat(lines, "<LINE>")
        self.content:paginate()
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
