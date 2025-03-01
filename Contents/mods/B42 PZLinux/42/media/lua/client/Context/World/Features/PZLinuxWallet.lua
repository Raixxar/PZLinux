-- Dark Web UI - by Raixxar 
-- Updated : 25/01/25

walletUI = ISPanel:derive("walletUI")

local walletCompanyName = {
    { name = "Crisis Commerce Corp", code = "CCC" },
    { name = "Umbrella Corp", code = "AC" },
    { name = "Walker & Crawler", code = "WC" },
    { name = "Survival Solutions Inc", code = "SSI" },
    { name = "Reclaim Resources Ltd", code = "RRL" },
    { name = "Brain Buffet Times", code = "BBT" },
    { name = "Zom Bin", code = "ZB" },
    { name = "Endurance Equipments", code = "EE" },
    { name = "Grinning Grim Goods", code = "GGG" },
    { name = "Couch Co-op", code = "CCO" },
    { name = "ZomboTrade Co", code = "ZTC" },
    { name = "COVID Pop Ltd", code = "CPL" },
    { name = "Gorrest Fump", code = "GF" },
    { name = "Phoenix Resupply Corp", code = "PRC" },
    { name = "Haven Supply Co", code = "HSC" },
    { name = "28 Ways to Stay Safe", code = "WSS" },
    { name = "The Hunger Z", code = "THZ" },
    { name = "Zombie of the rings", code = "ZOR" },
    { name = "Zombie Zumba", code = "ZZ" },
    { name = "Indoor Adventures", code = "IA" },
    { name = "Pandemic Pills Inc", code = "PPI" },
    { name = "Aftermath Trading Post", code = "ATP" },
    { name = "Waste Not Industries", code = "WNI" },
    { name = "NecroTech Innovations", code = "NTI" },
    { name = "Z Max", code = "ZM" },
    { name = "Vigilant Ventures", code = "VV" },
    { name = "Flee Market", code = "FM" },
    { name = "Raven Goods & Supply", code = "RGS" },
    { name = "Brains & Bargains", code = "BB" },
    { name = "Rot & Roll", code = "RR" },
    { name = "Butcher Ltd", code = "BL" }
}

local walletBalance = 0
local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0

-- CONSTRUCTOR
function walletUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    return o
end

-- INIT
function walletUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar:onMouseDown(x, y)
        self.parent.isDragging = true
        self.parent.initialX = self.parent:getX()
        self.parent.initialY = self.parent:getY()
        self.parent.mouseStartX = getMouseX()
        self.parent.mouseStartY = getMouseY()
    end

    function self.topBar:onMouseMove(x, y)
        if self.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - self.parent.mouseStartX
            local dy = curMouseY - self.parent.mouseStartY
            self.parent:setX(self.parent.initialX + dx)
            self.parent:setY(self.parent.initialY + dy)
        end
    end

    function self.topBar:onMouseUp(x, y)
        self.parent.isDragging = false
        local modData = getPlayer():getModData()
        modData.PZLinuxUIX = self.parent:getX()
        modData.PZLinuxUIY = self.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onStop)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, "Bank Balance: $"  .. tostring(loadAtmBalance()), 0, 1, 0, 1, UIFont.Small, true)
    self.titleLabel.backgroundColor = {r=0, g=0, b=0, a=0}
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

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onStop)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

-- Terminal loading
function walletUI:startWallet()
    self.titleLabel:setVisible(true)
    self.minimizeButton:setVisible(true)
    self.closeButton:setVisible(true)

    local scrollPanel = ISScrollingListBox:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.20)
    scrollPanel.backgroundColor = {r=0, g=0, b=0, a=1}
    scrollPanel.borderColor = {r=0, g=0, b=0, a=0}
    scrollPanel:initialise()
    scrollPanel:instantiate()
    
    function scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end
    
    scrollPanel:setScrollChildren(true)
    self:addChild(scrollPanel)

    local rowHeight = 50
    local totalHeight = 100 * rowHeight + 10
    scrollPanel:setScrollHeight(totalHeight)
    scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    local tradingMenuCodeLabel = ISButton:new(self.width * 0.20, self.height * 0.22, self.width * 0.12, self.height * 0.025, "CODE", self, self.onFilter)
    tradingMenuCodeLabel:initialise()
    self.topBar:addChild(tradingMenuCodeLabel)

    local tradingMenuNameLabel = ISButton:new(self.width * 0.31, self.height * 0.22, self.width * 0.12, self.height * 0.025, "QUANTITY", self, self.onFilter)
    tradingMenuNameLabel:initialise()
    self.topBar:addChild(tradingMenuNameLabel)

    local tradingMenuNameLabel = ISButton:new(self.width * 0.425, self.height * 0.22, self.width * 0.12, self.height * 0.025, "PRICE", self, self.onFilter)
    tradingMenuNameLabel:initialise()
    self.topBar:addChild(tradingMenuNameLabel)

    local tradingMenuH1Label = ISButton:new(self.width * 0.543, self.height * 0.22, self.width * 0.12, self.height * 0.025, "H1", self, self.onFilter)
    tradingMenuH1Label:initialise()
    self.topBar:addChild(tradingMenuH1Label)

    local tradingMenuD1Label = ISButton:new(self.width * 0.657, self.height * 0.22, self.width * 0.12, self.height * 0.025, "D1", self, self.onFilter)
    tradingMenuD1Label:initialise()
    self.topBar:addChild(tradingMenuD1Label)

    local tokens = {}
    local totalWalletBalance = 0
    local player = getPlayer()
    for i, company in ipairs(walletCompanyName) do
        local playerWallet = "ZLinuxPlayerWallet" .. company.code
        local totalTokenQuantity = player:getModData()[playerWallet] or 0

        local dataName = "PZLinuxTrading" .. company.code
        local globalData = ModData.getOrCreate(dataName)
        local priceHistory = globalData.dataName or {}
        local firstPrice = priceHistory[24] or 0
        local lastPrice = priceHistory[48] or 0
        local secondLastPrice = priceHistory[47] or 0

        if totalTokenQuantity > 0 then
            table.insert(tokens, {c = company.code, q = tostring(totalTokenQuantity), fp = firstPrice, lp = lastPrice, slp = secondLastPrice})
            totalWalletBalance = totalWalletBalance + lastPrice * totalTokenQuantity
            walletBalance = totalWalletBalance
        end
    end
    
    local y = 0
    for i, token in ipairs(tokens) do
        local codeButton = ISButton:new(self.width * 0.050, y, self.width * 0.12, self.height * 0.025, tostring(token.c) .. "/USD", self, nil)
        codeButton:initialise()
        self:addChild(codeButton)
        scrollPanel:addChild(codeButton)
    
        local quantityButton = ISButton:new(self.width * 0.161, y, self.width * 0.12, self.height * 0.025, token.q, self, nil)
        quantityButton:initialise()
        self:addChild(quantityButton)
        scrollPanel:addChild(quantityButton)

        local tokenPriceButton = ISButton:new(self.width * 0.274, y, self.width * 0.12, self.height * 0.025, tostring(token.lp), self, nil)
        tokenPriceButton:initialise()
        self:addChild(tokenPriceButton)
        scrollPanel:addChild(tokenPriceButton)
        
        local h1 = string.format("%.2f",((token.lp - token.slp) / token.slp) * 100)
        local h1Color = tonumber(math.ceil(h1))
        local priceH1Button = ISButton:new(self.width * 0.389, y, self.width * 0.12, self.height * 0.025, h1 .. "%", self, nil)
        if h1Color > 0 then
            priceH1Button.backgroundColor = {r=0, g=1, b=0, a=0.5}
        else
            priceH1Button.backgroundColor = {r=1, g=0, b=0, a=0.5}
        end
        priceH1Button:initialise()
        scrollPanel:addChild(priceH1Button)

        local d1 = string.format("%.2f",((token.lp - token.fp) / token.fp) * 100)
        local d1Color = tonumber(math.ceil(d1))
        local priceD1Button = ISButton:new(self.width * 0.508, y, self.width * 0.12, self.height * 0.025, d1 .. "%", self, nil)
        if d1Color > 0 then
            priceD1Button.backgroundColor = {r=0, g=1, b=0, a=0.5}
        else
            priceD1Button.backgroundColor = {r=1, g=0, b=0, a=0.5}
        end
        priceD1Button:initialise()
        scrollPanel:addChild(priceD1Button)
        
        y = y + self.height * 0.025
    end

    self.walletTitleLabel = ISLabel:new(self.width * 0.20, self.height * 0.46, self.height * 0.025, "Wallet Balance: $"  .. tostring(totalWalletBalance), 0, 1, 0, 1, UIFont.Small, true)
    self.walletTitleLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.walletTitleLabel:setVisible(true)
    self.walletTitleLabel:initialise()
    self.topBar:addChild(self.walletTitleLabel) 
    
    local chartWidth = self.width * 0.589
    local chartHeight = self.height * 0.20
    local chartX = self.width * 0.195
    local chartY = self.height * 0.49

    self.walletChart = ISPanel:new(chartX, chartY, chartWidth, chartHeight)
    self.walletChart.backgroundColor = {r=0, g=0, b=0, a=0.3}
    self.walletChart.borderColor = {r=1, g=1, b=1, a=0.3}
    self.walletChart:setVisible(true)
    self.walletChart:initialise()

    function  self.walletChart:render()
        local player = getPlayer()
        local values = player:getModData().playerWallet
        local numPoints = #values
        if numPoints < 2 then return end
    
        local maxValue = math.max(unpack(values))
        local minValue = math.min(unpack(values))
        if maxValue == minValue then return end
    
        local barWidth = 7
    
        for i = 2, numPoints do
            local closePrice = values[i]
            local barX = (i - 1) * barWidth
            local barY = chartHeight - ((closePrice - minValue) / (maxValue - minValue)) * chartHeight
            local barHeight = chartHeight - barY
            local color = { r = 0, g = 1, b = 0, a = 0.8 }
            self:drawRect(barX, barY, barWidth, barHeight, color.a, color.r, color.g, color.b)
        end
    end
    self.topBar:addChild(self.walletChart)
end

function walletUI:updateWallet()
    local totalWalletBalance = 0
    local player = getPlayer()

    if not player:getModData().playerWallet then
        player:getModData().playerWallet = {}
    end

    for i, company in ipairs(walletCompanyName) do
        local playerWallet = "ZLinuxPlayerWallet" .. company.code
        local totalTokenQuantity = player:getModData()[playerWallet] or 0

        local dataName = "PZLinuxTrading" .. company.code
        local globalData = ModData.getOrCreate(dataName)
        local priceHistory = globalData.dataName or {}
        local lastPrice = tonumber(priceHistory[48]) or 0

        totalWalletBalance = totalWalletBalance + lastPrice * totalTokenQuantity
        walletBalance = totalWalletBalance + walletBalance
    end
    table.insert(player:getModData().playerWallet, walletBalance)
    if #player:getModData().playerWallet > 48 then
        table.remove(player:getModData().playerWallet, 1)
    end
end

-- STOP
function walletUI:onStop(button)
    self.isClosing = true
    lastConnectionTimestamp = 0
    self:removeFromUIManager()
end

-- LOGOUT
function walletUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    linuxMenu_ShowUI(player)
end

-- CLOSE
function walletUI:onClose(button)
    self.isClosing = true
    lastConnectionTimestamp = 0
    self:removeFromUIManager()
    linuxMenu_ShowUI(player)
end

function walletMenu_ShowUI(player)
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
    
    local modData = getPlayer():getModData()
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = walletUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()

    local getHourTime = math.ceil(getGameTime():getWorldAgeHours())
    if getHourTime + 1 > LAST_CONNECTION_TIME then
        if LAST_CONNECTION_TIME == 0 then LAST_CONNECTION_TIME = getHourTime end
        if LAST_CONNECTION_TIME > 0 then 
            local deltaTrading = getHourTime - LAST_CONNECTION_TIME
            for i = 1, deltaTrading do
                PZLinuxUpdateTradingPrices()
            end
            ui:updateWallet()
            LAST_CONNECTION_TIME = getHourTime
        end
    end
    ui:startWallet()
end