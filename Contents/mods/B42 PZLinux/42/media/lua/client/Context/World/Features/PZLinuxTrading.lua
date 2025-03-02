-- Dark Web UI - by Raixxar 
-- Updated : 25/01/25

tradingUI = ISPanel:derive("tradingUI")

local LAST_CONNECTION_TIME = 0

local tradingCompanyName = {
    { name = "Crisis Commerce Corp", code = "CCC", price = 1450 },
    { name = "Umbrella Corp", code = "AC", price = 1400 },
    { name = "Walker & Crawler", code = "WC", price = 1300 },
    { name = "Survival Solutions Inc", code = "SSI", price = 1200 },
    { name = "Reclaim Resources Ltd", code = "RRL", price = 1110 },
    { name = "Brain Beers Times", code = "BBT", price = 1000 },
    { name = "Zom Bin", code = "ZB", price = 950 },
    { name = "Endurance Equipments", code = "EE", price = 850 },
    { name = "Grinning Grim Goods", code = "GGG", price = 610 },
    { name = "Country Court Outlaw", code = "CCO", price = 580 },
    { name = "ZomboTrade Co", code = "ZTC", price = 560 },
    { name = "COVID Pop Ltd", code = "CPL", price = 500 },
    { name = "Gorrest Fump", code = "GF", price = 450 },
    { name = "Phoenix Resupply Corp", code = "PRC", price = 350 },
    { name = "Heaven Saint Christ", code = "HSC", price = 260 },
    { name = "28 Ways to Stay Safe", code = "WSS", price = 245 },
    { name = "The Hunger Z", code = "THZ", price = 235 },
    { name = "Zombie of the rings", code = "ZOR", price = 220 },
    { name = "Zombie Zumba", code = "ZZ", price = 200 },
    { name = "Indoor Adventures", code = "IA", price = 180 },
    { name = "Pandemic Pills Inc", code = "PPI", price = 170 },
    { name = "Aftermath Trading Post", code = "ATP", price = 160 },
    { name = "Waste Not Industries", code = "WNI", price = 120 },
    { name = "NecroTech Innovations", code = "NTI", price = 80 },
    { name = "Z Max", code = "ZM", price = 65 },
    { name = "Vigilant Ventures", code = "VV", price = 40 },
    { name = "Flee Market", code = "FM", price = 30 },
    { name = "Raven Goods & Supply", code = "RGS", price = 25 },
    { name = "Brains & Bargains", code = "BB", price = 20 },
    { name = "Rot & Roll", code = "RR", price = 10 },
    { name = "Butcher Ltd", code = "BL", price = 5 }
}

function tradingUI:loadModFile()
    local fileName = "PZLinux.ini"
    local file = getFileReader(fileName, false)

    if not file then
        return {}
    end

    local prices = {}
    local section = nil
    local line = file:readLine()

    while line do
        local sectionHeader = line:match("^%[(.-)%]$")
        if sectionHeader then
            section = sectionHeader
        elseif section == "trading" then
            local code, values = line:match("^(%w+)=(.+)$")
            if code and values then
                prices[code] = {}
                for price in values:gmatch("%d+") do
                    table.insert(prices[code], tonumber(price))
                end
            end
        end
        line = file:readLine()
    end

    file:close()
    return prices
end

-- CONSTRUCTOR
function tradingUI:new(x, y, width, height, player)
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
function tradingUI:initialise()
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

    self.minimizeTradingButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimizeTrading)
    self.minimizeTradingButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeTradingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeTradingButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeTradingButton:setVisible(false)
    self.minimizeTradingButton:initialise()
    self.topBar:addChild(self.minimizeTradingButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onStop)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

function tradingUI:startTrading()
    self:initializePrices()
    self.titleLabel:setVisible(true)
    self.closeButton:setVisible(true)
    self.minimizeButton:setVisible(true)

    local y = 0
    self.tradingButtons = {}

    local scrollPanel = ISScrollingListBox:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.46)
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

    local rowHeight = self.height * 0.045
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

    local tradingMenuNameLabel = ISButton:new(self.width * 0.31, self.height * 0.22, self.width * 0.250, self.height * 0.025, "NAME", self, self.onFilter)
    tradingMenuNameLabel:initialise()
    self.topBar:addChild(tradingMenuNameLabel)

    local tradingMenuH1Label = ISButton:new(self.width * 0.543, self.height * 0.22, self.width * 0.12, self.height * 0.025, "H1", self, self.onFilter)
    tradingMenuH1Label:initialise()
    self.topBar:addChild(tradingMenuH1Label)

    local tradingMenuD1Label = ISButton:new(self.width * 0.657, self.height * 0.22, self.width * 0.12, self.height * 0.025, "D1", self, self.onFilter)
    tradingMenuD1Label:initialise()
    self.topBar:addChild(tradingMenuD1Label)

    for i, company in ipairs(tradingCompanyName) do
        local codeButton = ISButton:new(self.width * 0.0499, y, self.width * 0.12, self.height * 0.025, company.code .. "/USD", self, nil)
        codeButton:initialise()

        local nameButton = ISButton:new(self.width * 0.161, y, self.width * 0.22, self.height * 0.025, company.name, self, nil)
        nameButton:initialise()

        local infoButton = ISButton:new(self.width * 0.371, y, self.width * 0.025, self.height * 0.025, "i", self, function()
            self.titleLabel:setVisible(false)
            tradingMenuCodeLabel:setVisible(false)
            tradingMenuNameLabel:setVisible(false)
            tradingMenuH1Label:setVisible(false)
            tradingMenuD1Label:setVisible(false)
            scrollPanel:setVisible(false)
            self:showCompanyInfo(company.code, company.name)
        end)
        infoButton:initialise()

        -- % PRICE

        local dataName = "PZLinuxTrading" .. company.code

        if isServer() then
            ModData.transmit(dataName)
        end
        
        local companyData = ModData.getOrCreate(dataName)
        local priceHistory = companyData.dataName or {}
        local firstPrice = priceHistory[24]
        local lastIndex = #priceHistory
        local lastPrice = priceHistory[lastIndex]
        local secondLastPrice = priceHistory[47]

        -- H1
        local h1 = string.format("%.2f",((lastPrice - secondLastPrice) / secondLastPrice) * 100)
        local h1Color = tonumber(math.ceil(h1))
        local priceH1Button = ISButton:new(self.width * 0.394, y, self.width * 0.116, self.height * 0.025, h1 .. "%", self, nil)
        if h1Color > 0 then
            priceH1Button.backgroundColor = {r=0, g=1, b=0, a=0.5}
        else
            priceH1Button.backgroundColor = {r=1, g=0, b=0, a=0.5}
        end
        priceH1Button:initialise()

        -- D1
        local d1 = string.format("%.2f",((lastPrice - firstPrice) / firstPrice) * 100)
        local d1Color = tonumber(math.ceil(d1))
        local priceD1Button = ISButton:new(self.width * 0.508, y, self.width * 0.12, self.height * 0.025, d1 .. "%", self, nil)
        if d1Color > 0 then
            priceD1Button.backgroundColor = {r=0, g=1, b=0, a=0.5}
        else
            priceD1Button.backgroundColor = {r=1, g=0, b=0, a=0.5}
        end
        priceD1Button:initialise()
        
        table.insert(self.tradingButtons, {codeButton, nameButton, infoButton, priceH1Button, priceD1Button})

        scrollPanel:addChild(codeButton)
        scrollPanel:addChild(nameButton)
        scrollPanel:addChild(infoButton)
        scrollPanel:addChild(priceH1Button)
        scrollPanel:addChild(priceD1Button)

        y = y + self.height * 0.025
    end
end

function tradingUI:showCompanyInfo(code, name)
    local dataName = "PZLinuxTrading" .. code

    if isServer() then
        ModData.transmit(dataName)
    end
    
    local companyData = ModData.getOrCreate(dataName)
    local priceHistory = companyData.dataName or {}
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex]

    self.closeButton:setVisible(true)
    self.minimizeTradingButton:setVisible(true)
    self.minimizeButton:setVisible(true)

    self.companyCodeLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, code .. "/USD $" .. lastPrice, 0, 1, 0, 1, UIFont.Medium, true)
    self.companyCodeLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.companyCodeLabel:initialise()
    self.topBar:addChild(self.companyCodeLabel)

    self.companyNameLabel = ISLabel:new(self.width * 0.20, self.height * 0.19, self.height * 0.025, name, 0, 1, 0, 1, UIFont.Small, true)
    self.companyNameLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.companyNameLabel:initialise()
    self.topBar:addChild(self.companyNameLabel)

    local chartWidth = self.width * 0.58
    local chartHeight = self.height * 0.25
    local chartX = self.width * 0.20
    local chartY = self.height * 0.24

    local candlestickChart = ISPanel:new(chartX, chartY, chartWidth, chartHeight)
    candlestickChart:initialise()
    candlestickChart.backgroundColor = {r=0, g=0, b=0, a=0.3}
    candlestickChart.borderColor = {r=1, g=1, b=1, a=0.3}

    function candlestickChart:render()
        local numCandles = #priceHistory
        if numCandles < 2 then return end

        local maxPrice = math.max(unpack(priceHistory))
        local minPrice = math.min(unpack(priceHistory))

        local candleWidth = chartWidth / numCandles
        for i = 2, numCandles do
            local openPrice = priceHistory[i - 1]
            local closePrice = priceHistory[i]
            local highPrice = math.max(openPrice, closePrice)
            local lowPrice = math.min(openPrice, closePrice)

            local x = (i - 2) * candleWidth + 0
            local highY = chartHeight - ((highPrice - minPrice) / (maxPrice - minPrice)) * chartHeight
            local lowY = chartHeight - ((lowPrice - minPrice) / (maxPrice - minPrice)) * chartHeight
            local openY = chartHeight - ((openPrice - minPrice) / (maxPrice - minPrice)) * chartHeight
            local closeY = chartHeight - ((closePrice - minPrice) / (maxPrice - minPrice)) * chartHeight

            self:drawRect(x + candleWidth / 2, highY, 1, lowY - highY, 1, 1, 1, 1)
            local color = { r = 0, g = 1, b = 0, a = 1 } -- Green for upward movement
            if closePrice < openPrice then
                color = { r = 1, g = 0, b = 0, a = 1 } -- Red for downward movement
            end

            -- Draw body
            local bodyY = math.min(openY, closeY)
            local bodyHeight = math.abs(closeY - openY)
            if bodyHeight == 0 then bodyHeight = 1 end -- Ensure visible body
            self:drawRect(x, bodyY, candleWidth, bodyHeight, color.a, color.r, color.g, color.b)
        end
    end
    self.topBar:addChild(candlestickChart)

    local player = getPlayer()
    local playerWallet = "ZLinuxPlayerWallet" .. code
    local totalTokenQuantity = player:getModData()[playerWallet] or 0

    self.tradingBalanceLabel = ISLabel:new(self.width * 0.20, self.height * 0.21, self.height * 0.025, "Account Balance $"  .. tostring(loadAtmBalance()), 0, 1, 0, 1, UIFont.Small, true)
    self.tradingBalanceLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.tradingBalanceLabel:initialise()
    self.topBar:addChild(self.tradingBalanceLabel)

    self.tradingWalletLabel = ISLabel:new(self.width * 0.20, self.height * 0.52, self.height * 0.025, "Wallet Balance " .. totalTokenQuantity .. " " .. code, 0, 1, 0, 1, UIFont.Small, true)
    self.tradingWalletLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.tradingWalletLabel:initialise()
    self.topBar:addChild(self.tradingWalletLabel)

    self.quantityInput = ISTextEntryBox:new("QUANTITY", self.width * 0.345, self.height * 0.59, self.width * 0.298, self.height * 0.025)
    self.quantityInput:initialise()
    self.quantityInput:instantiate()
    self.quantityInput:setOnlyNumbers(true)
    self.topBar:addChild(self.quantityInput)

    self.tradingSoldButton = ISButton:new(self.width * 0.344, self.height * 0.62, self.width * 0.15, self.height * 0.05, "SOLD", self, function()
        local quantityTrading = tonumber(self.quantityInput:getText()) or 0
        if quantityTrading > 0 then
            self:onTradingSold(code, lastPrice, quantityTrading)
        end
    end)

    self.tradingSoldButton.backgroundColor = {r=0.5, g=0, b=0, a=1}
    self.tradingSoldButton.borderColor = {r=0, g=0, b=0, a=1}
    self.tradingSoldButton:setVisible(true)
    self.tradingSoldButton:initialise()
    self.tradingSoldButton:setAnchorRight(true)
    self.topBar:addChild(self.tradingSoldButton)

    self.tradingBuyButton = ISButton:new(self.width * 0.494, self.height * 0.62, self.width * 0.15, self.height * 0.05, "BUY", self, function()
        local quantityTrading = tonumber(self.quantityInput:getText()) or 0
        if quantityTrading > 0 then
            self:onTradingBuy(code, lastPrice, quantityTrading)
        end
    end)
    self.tradingBuyButton.backgroundColor = {r=0, g=0.5, b=0, a=1}
    self.tradingBuyButton.borderColor = {r=0, g=0, b=0, a=1}
    self.tradingBuyButton:setVisible(true)
    self.tradingBuyButton:initialise()
    self.topBar:addChild(self.tradingBuyButton)
end

function tradingUI:onTradingSold(code, lastPrice, quantityTrading)
    local player = getPlayer()
    local playerWallet = "ZLinuxPlayerWallet" .. code
    local totalTokenQuantity = player:getModData()[playerWallet] or 0
    local newQuantity = tonumber(totalTokenQuantity) - tonumber(quantityTrading)

    if newQuantity >= 0 then
        local balance = tonumber(loadAtmBalance())
        lastPrice = tonumber(lastPrice) * tonumber(quantityTrading)
        local newBalance = balance + lastPrice
        saveAtmBalance(newBalance)
        self.tradingBalanceLabel:setName("Account Balance $" .. tostring(newBalance))

        player:getModData()[playerWallet] = newQuantity
        self.tradingWalletLabel:setName("Wallet Balance " .. newQuantity .. " " .. code)

    end
end

function tradingUI:onTradingBuy(code, lastPrice, quantityTrading)
    local balance = tonumber(loadAtmBalance())
    lastPrice = tonumber(lastPrice) * tonumber(quantityTrading)
    if balance < lastPrice then
        return
    end
    local newBalance = balance - lastPrice
    saveAtmBalance(newBalance)
    self.tradingBalanceLabel:setName("Account Balance $" .. tostring(newBalance))

    local player = getPlayer()
    local playerWallet = "ZLinuxPlayerWallet" .. code
    local totalTokenQuantity = tonumber(player:getModData()[playerWallet] or 0)
    local quantity = tonumber(quantityTrading)
    player:getModData()[playerWallet] = totalTokenQuantity + quantity
end

function PZLinuxUpdateTradingPrices()
    for _, company in ipairs(tradingCompanyName) do
        local dataName = "PZLinuxTrading" .. company.code
        local companyData = ModData.getOrCreate(dataName)
        local priceHistory = companyData.dataName or {}
        local lastIndex = #priceHistory
        local lastPrice = priceHistory[lastIndex]

        local direction = ZombRand(1, 4)
        if direction == 1 then
            lastPrice = ZombRand(math.max(1, lastPrice - lastPrice * 5 / 100), lastPrice + 2)
        elseif direction == 3 then
            lastPrice = ZombRand(lastPrice, lastPrice + lastPrice * 5 / 100)
        end

        local dataName = "PZLinuxTrading" .. company.code
        local globalData = ModData.getOrCreate(dataName)
        table.insert(globalData.dataName, lastPrice)
        if #globalData.dataName > 48 then
            table.remove(globalData.dataName, 1)
        end
    end
end

function tradingUI:initializePrices()
    local globalData = ModData.getOrCreate("PZLinuxTrading")
    if globalData.PZLinuxTrading == 1 then
        return
    end

    globalData.PZLinuxTrading = 1
    for _, company in ipairs(tradingCompanyName) do
        local dataName = "PZLinuxTrading" .. company.code
        local globalData = ModData.getOrCreate(dataName)
        globalData.dataName = {}
        local tempPrice = company.price
        for i = 1, 48 do
            local direction = ZombRand(1, 4)
            if direction == 1 then
                tempPrice = ZombRand(math.max(1, tempPrice - tempPrice * ZombRand(5, 25) / 100), tempPrice + 2)
            elseif direction == 3 then
                tempPrice = ZombRand(tempPrice, tempPrice + tempPrice * ZombRand(5, 25) / 100)
            end
            table.insert(globalData.dataName, tempPrice)
            if #globalData.dataName > 48 then
                table.remove(globalData.dataName, 1)
            end
        end
    end
end

-- STOP
function tradingUI:onStop(button)
    self.isClosing = true
    self:removeFromUIManager()
end

-- LOGOUT
function tradingUI:onMinimizeTrading(button)
    self.isClosing = true
    self:removeFromUIManager()
    tradingMenu_ShowUI(player)
end

function tradingUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function tradingUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
end

-- UI
function tradingMenu_ShowUI(player)
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

    local ui = tradingUI:new(uiX, uiY, finalW, finalH, player)
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
            LAST_CONNECTION_TIME = getHourTime
        end
    end
    ui:startTrading()

    return ui
end