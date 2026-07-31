-- Dark Web UI - by Raixxar
-- Updated : 25/01/25

tradingUI = ISPanel:derive("tradingUI")

local function PZLinuxTradingUIFindCompany(snapshot, code)
    if not snapshot or type(snapshot.companies) ~= "table" then return nil end
    for _, company in ipairs(snapshot.companies) do
        if company.code == code then
            return company
        end
    end
    return nil
end

local function PZLinuxTradingUIGetCompanyData(self, company)
    local snapshotCompany = PZLinuxTradingUIFindCompany(self.tradingSnapshot, company.code)
    if snapshotCompany then
        return snapshotCompany.history or {}, snapshotCompany
    end

    local dataName = "PZLinuxTrading" .. company.code
    local companyData = ModData.getOrCreate(dataName)
    return companyData.dataName or {}, nil
end

local function PZLinuxTradingUIFormatChange(value)
    return string.format("%.2f", tonumber(value) or 0)
end

function tradingUI.loadModFile(_self)
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
        local modData = PZLinuxGetPlayer(self.parent.player):getModData()
        modData.PZLinuxUIX = self.parent:getX()
        modData.PZLinuxUIY = self.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
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

    local modData = PZLinuxGetPlayer(self.player):getModData()
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

    self.minimizeTradingButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimizeTrading)
    self.minimizeTradingButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeTradingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeTradingButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeTradingButton:setVisible(false)
    self.minimizeTradingButton:initialise()
    self.topBar:addChild(self.minimizeTradingButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

function tradingUI:startTrading()
    self.titleLabel:setVisible(true)
    self.closeButton:setVisible(true)
    self.minimizeButton:setVisible(true)

    if not self.tradingSnapshotReady then
        PZLinuxRequestTradingSnapshot(self.player, function(result)
            if not result or not result.ok then return end
            if result.balance then
                saveAtmBalance(result.balance, self.player)
                self.titleLabel:setName("Bank Balance: $" .. tostring(result.balance))
            end
            self.tradingSnapshot = result.tradingSnapshot
            self.tradingSnapshotReady = true
            self:startTrading()
        end)
        return
    end

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

    for i, company in ipairs(PZLinuxTradingCompanyNameTable) do
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

        local priceHistory, snapshotCompany = PZLinuxTradingUIGetCompanyData(self, company)
        local firstPrice = priceHistory[24] or priceHistory[1] or company.price
        local lastIndex = #priceHistory
        local lastPrice = priceHistory[lastIndex] or company.price
        local secondLastPrice = priceHistory[lastIndex - 1] or lastPrice

        -- H1
        local h1 = PZLinuxTradingUIFormatChange(snapshotCompany and snapshotCompany.h1 or ((lastPrice - secondLastPrice) / math.max(1, secondLastPrice)) * 100)
        local h1Color = tonumber(math.ceil(h1))
        local priceH1Button = ISButton:new(self.width * 0.394, y, self.width * 0.116, self.height * 0.025, h1 .. "%", self, nil)
        if h1Color > 0 then
            priceH1Button.backgroundColor = {r=0, g=1, b=0, a=0.5}
        else
            priceH1Button.backgroundColor = {r=1, g=0, b=0, a=0.5}
        end
        priceH1Button:initialise()

        -- D1
        local d1 = PZLinuxTradingUIFormatChange(snapshotCompany and snapshotCompany.d1 or ((lastPrice - firstPrice) / math.max(1, firstPrice)) * 100)
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
    local baseCompany = PZLinuxTradingGetCompanyByCode(code) or { code = code, name = name, price = 1 }
    local priceHistory, snapshotCompany = PZLinuxTradingUIGetCompanyData(self, baseCompany)
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex] or baseCompany.price

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
        if maxPrice == minPrice then return end

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

    local player = PZLinuxGetPlayer(self.player)
    local totalTokenQuantity = snapshotCompany and snapshotCompany.quantity or player:getModData()[PZLinuxTradingGetWalletKey(code)] or 0

    self.tradingBalanceLabel = ISLabel:new(self.width * 0.20, self.height * 0.21, self.height * 0.025, "Account Balance $"  .. tostring(loadAtmBalance(self.player)), 0, 1, 0, 1, UIFont.Small, true)
    self.tradingBalanceLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.tradingBalanceLabel:initialise()
    self.topBar:addChild(self.tradingBalanceLabel)

    self.tradingWalletLabel = ISLabel:new(self.width * 0.20, self.height * 0.52, self.height * 0.025, "Wallet Balance " .. totalTokenQuantity .. " " .. code, 0, 1, 0, 1, UIFont.Small, true)
    self.tradingWalletLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.tradingWalletLabel:initialise()
    self.topBar:addChild(self.tradingWalletLabel)

    local feeRate = tonumber(self.tradingSnapshot and self.tradingSnapshot.feeRate) or PZLinuxTradingGetFeeRate()
    local feePercent = math.floor(feeRate * 100 + 0.5)
    self.tradingFeeLabel = ISLabel:new(self.width * 0.20, self.height * 0.55, self.height * 0.025, "Transaction fee: " .. feePercent .. "%", 1, 1, 0, 1, UIFont.Small, true)
    self.tradingFeeLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.tradingFeeLabel:initialise()
    self.topBar:addChild(self.tradingFeeLabel)

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

function tradingUI.onFilter(_self, _button)
end

function tradingUI:onTradingSold(code, _lastPrice, quantityTrading)
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    PZLinuxRequestTradingSell(self.player, code, quantityTrading, function(result)
        if not result or not result.ok then return end

        if result.balance then
            saveAtmBalance(result.balance, player)
            self.tradingBalanceLabel:setName("Account Balance $" .. tostring(result.balance))
        end
        if result.walletQuantity and self.tradingWalletLabel then
            self.tradingWalletLabel:setName("Wallet Balance " .. tostring(result.walletQuantity) .. " " .. code)
        end
        if result.tradingSnapshot then
            self.tradingSnapshot = result.tradingSnapshot
        end

        if self.tradingFeeLabel then
            self.tradingFeeLabel:setName("Fee: $" .. tostring(result.fee or 0) .. " | Received: $" .. tostring(result.netAmount or result.amount or 0))
        end

        local amount = tonumber(result.amount) or 0
        if amount >= 5000 then
            player:getStats():add(CharacterStat.UNHAPPINESS, -10)
            player:getStats():add(CharacterStat.STRESS, -0.5)
        elseif amount >= 1000 then
            player:getStats():add(CharacterStat.UNHAPPINESS, -5)
            player:getStats():add(CharacterStat.STRESS, -0.1)
        end
    end)
end

function tradingUI:onTradingBuy(code, _lastPrice, quantityTrading)
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    PZLinuxRequestTradingBuy(self.player, code, quantityTrading, function(result)
        if not result or not result.ok then return end

        if result.balance then
            saveAtmBalance(result.balance, player)
            self.tradingBalanceLabel:setName("Account Balance $" .. tostring(result.balance))
        end
        if result.walletQuantity and self.tradingWalletLabel then
            self.tradingWalletLabel:setName("Wallet Balance " .. tostring(result.walletQuantity) .. " " .. code)
        end
        if result.tradingSnapshot then
            self.tradingSnapshot = result.tradingSnapshot
        end
        if self.tradingFeeLabel then
            self.tradingFeeLabel:setName("Fee: $" .. tostring(result.fee or 0) .. " | Paid: $" .. tostring(result.netAmount or result.amount or 0))
        end
    end)
end

function PZLinuxUpdateTradingPrices(player)
    if isClient and isClient() then
        PZLinuxRequestTradingSnapshot(player or PZLinuxGetPlayer(), nil)
        return
    end
    PZLinuxTradingUpdatePrices()
end

function PZLinuxTrading_initializePrices(player)
    if isClient and isClient() then
        PZLinuxRequestTradingSnapshot(player or PZLinuxGetPlayer(), nil)
        return
    end
    PZLinuxTradingInitializePrices()
end

-- LOGOUT
function tradingUI:onMinimizeTrading(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 4
end

function tradingUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function tradingUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function tradingUI:onCloseX(_button)
    self.isClosing = true
    PZLinuxGetPlayer(self.player):StopAllActionQueue()
end

function tradingUI:onSFXOn(_button)
    local modData = PZLinuxGetPlayer(self.player):getModData()
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

function tradingUI:onSFXOff(_button)
    local modData = PZLinuxGetPlayer(self.player):getModData()
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

    local modData = PZLinuxGetPlayer(player):getModData()
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

    ui:startTrading()

    return ui
end
