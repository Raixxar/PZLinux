-- ATM UI - by Raixxar 
-- Updated : 25/01/26

AtmUI = ISPanel:derive("AtmUI")

-- CONSTRUCTOR
function AtmUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0}
    o.borderColor     = {r=0.2, g=0.2, b=0.2, a=0}
    o.width           = width
    o.height          = height
    o.player          = player
    o.isClosing       = false
    o.balance         = loadAtmBalance()
    o.mode            = "main"
    return o
end

-- SAVE BALANCE BANK ACCOUNT
function saveAtmBalance(balance)
    if balance then
        local player = getPlayer()
        player:getModData().PZLinuxBank = balance
    end
end

function loadAtmBalance()
    local player = getPlayer()
    local bankBalance = player:getModData().PZLinuxBank
    if bankBalance then
        return bankBalance
    else
        bankBalance = ZombRand(500, 4000)
        player:getModData().PZLinuxBank = bankBalance
        return bankBalance
    end
end

-- INIT
function AtmUI:initialise()
    ISPanel.initialise(self)
    self:showLoginMenu()
end

function AtmUI:showLoginMenu()
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
    end

    self.titleLabel = ISLabel:new(self.width * 0.225, self.width * 0.43, self.width * 0.1, "ATM AMERICAN BANK", 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.527, self.width * 0.461, self.width * 0.1, self.height * 0.027, "LEAVE", self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.loginButton = ISButton:new(self.width * 0.295, self.width * 0.55, self.width * 0.25, self.height * 0.08, "  LOGIN   ", self, self.onLoginMenu)
    self.loginButton:setVisible(true)
    self.loginButton:initialise()
    self.topBar:addChild(self.loginButton)

    self.passwordLabel = ISLabel:new(self.width * 0.225, self.width * 0.48, self.width * 0.1, "PASSWORD", 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.passwordLabel:setVisible(false)
    self.passwordLabel:initialise()
    self.topBar:addChild(self.passwordLabel)
end

function AtmUI:showMainMenu()
    self.withdrawalButton = ISButton:new(self.width * 0.295, self.width * 0.52, self.width * 0.25, self.height * 0.08, "  WITHDRAWAL   ", self, self.onWithdrawal)
    self.withdrawalButton:setVisible(true)
    self.withdrawalButton:initialise()
    self.topBar:addChild(self.withdrawalButton)

    self.depositeButton = ISButton:new(self.width * 0.295, self.width * 0.63, self.width * 0.25, self.height * 0.08, "      DEPOSITE      ", self, self.onDeposite)
    self.depositeButton:setVisible(true)
    self.depositeButton:initialise()
    self.topBar:addChild(self.depositeButton)

    self.balanceLabel = ISLabel:new(self.width * 0.225, self.width * 0.45, self.width * 0.1, "Balance: $" .. tostring(self.balance), 1, 1, 1, 1, UIFont.Small, true)
    self.balanceLabel:initialise()
    self:addChild(self.balanceLabel)
end

function AtmUI:showDepositeMenu()
    self.titleLabelDeposite = ISLabel:new(self.width * 0.225, self.width * 0.47, self.width * 0.1, "DEPOSIT MONEY", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabelDeposite:initialise()
    self:addChild(self.titleLabelDeposite)

    self.amountFieldDeposite = ISTextEntryBox:new("", self.width * 0.315, self.width * 0.58, self.width * 0.229, self.height * 0.025)
    self.amountFieldDeposite:initialise()
    self.amountFieldDeposite:instantiate()
    self:addChild(self.amountFieldDeposite)

    self.sendButtonDeposite = ISButton:new(self.width * 0.315, self.width * 0.63, self.width * 0.10, self.height * 0.05, "SEND", self, self.onDepositeSend)
    self.sendButtonDeposite:initialise()
    self:addChild(self.sendButtonDeposite)

    self.backButtonDeposite = ISButton:new(self.width * 0.445, self.width * 0.63, self.width * 0.10, self.height * 0.05, "BACK", self, self.onDepositeBack)
    self.backButtonDeposite:initialise()
    self:addChild(self.backButtonDeposite)
end

function AtmUI:showWithdrawalMenu()
    self.titleLabelWithdrawal = ISLabel:new(self.width * 0.225, self.width * 0.47, self.width * 0.1, "WITHDRAWAL MONEY", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabelWithdrawal:initialise()
    self:addChild(self.titleLabelWithdrawal)

    self.amountFieldWithdrawal = ISTextEntryBox:new("", self.width * 0.315, self.width * 0.58, self.width * 0.229, self.height * 0.025)
    self.amountFieldWithdrawal:initialise()
    self.amountFieldWithdrawal:instantiate()
    self:addChild(self.amountFieldWithdrawal)

    self.sendButtonWithdrawal = ISButton:new(self.width * 0.315, self.width * 0.63, self.width * 0.10, self.height * 0.05, "SEND", self, self.onWithdrawalSend)
    self.sendButtonWithdrawal:initialise()
    self:addChild(self.sendButtonWithdrawal)

    self.backButtonWithdrawal = ISButton:new(self.width * 0.445, self.width * 0.63, self.width * 0.10, self.height * 0.05, "BACK", self, self.onWithdrawalBack)
    self.backButtonWithdrawal:initialise()
    self:addChild(self.backButtonWithdrawal)
end

function AtmUI:onLoginMenu()
    local globalVolume = getCore():getOptionSoundVolume() / 50
    self.loginButton:setVisible(false)
    if self.isClosing or not getPlayer() then
        return
    end

    local loginBase = "INSERT YOUR CREDIT CARD"
    local currentLogin = loginBase
    local index = 1

    local passwordBase = "PASSWORD: "
    local currentPassword = passwordBase
    local passwordIndex = 1
    local totalAsterisks = 4

    local messageTemplates = {
        {base = "Loading", variations = 2},
    }

    local messages = {}

    for _, template in ipairs(messageTemplates) do
        if template.variations and template.variations > 0 then
            for i = 1, template.variations do
                table.insert(messages, template.base .. string.rep(".", i))
            end
            if template.repeatCount then
                for _ = 1, template.repeatCount do
                    table.insert(messages, template.base .. string.rep(".", template.variations))
                end
            end
        else
            table.insert(messages, template.base)
        end
    end

    if not self.loadingMessage then
        self.loadingMessage = ISLabel:new(self.width * 0.225, self.width * 0.45, self.width * 0.1, "", 0.8, 1, 0.8, 1, UIFont.Small, true)
        self.loadingMessage:initialise()
        self.topBar:addChild(self.loadingMessage)
    end

    self.terminalCoroutine = coroutine.create(function()
        getSoundManager():PlayWorldSound("creditCard", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        self.loadingMessage:setName(loginBase)

        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local initialDelay = elapsed + 40
        while elapsed < initialDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        self.loadingMessage:setName(passwordBase)
        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local initialDelay = elapsed + 40
        while elapsed < initialDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        while passwordIndex <= totalAsterisks do
            if self.isClosing then
                return
            end
            
            getSoundManager():PlayWorldSound("atmBip", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            currentPassword = currentPassword .. "*"
            passwordIndex = passwordIndex + 1
            self.loadingMessage:setName(currentPassword)
            
            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = elapsed + ZombRand(2, math.ceil((-((getPlayer():getPerkLevel(Perks.Electricity)^2) / 1) + 130) / 10))
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end

        for _, message in ipairs(messages) do
            if self.isClosing then
                return
            end

            self.loadingMessage:setName(message)
            local delay = ZombRand(60, 240)
            for _ = 1, delay do
                if self.isClosing then
                    return
                end
                coroutine.yield()
            end
        end
        
        self.loadingMessage:setVisible(false)
        self.loadingMessage = nil
        self:showMainMenu()
    end)

    self.updateCoroutineFunc = function()
        if coroutine.status(self.terminalCoroutine) ~= "dead" then
            coroutine.resume(self.terminalCoroutine)
        else
            Events.OnTick.Remove(self.updateCoroutineFunc)
            self.updateCoroutineFunc = nil
            self.terminalCoroutine = nil
        end
    end
    Events.OnTick.Add(self.updateCoroutineFunc)
end

function AtmUI:onClose()
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function AtmUI:onWithdrawal()
    self.depositeButton:setVisible(false)
    self.withdrawalButton:setVisible(false)
    self:showWithdrawalMenu()
end

function AtmUI:onDeposite()
    local playerObj = getPlayer()
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    for i=1,containers:size() do
        local newCount = 0
        local container = containers:get(i-1)
        local items = container:getItems()
        for j = 0, items:size() - 1 do
            local item = items:get(j)
            if item:getFullType() == "Base.Money" or item:getFullType() == "Base.MoneyBundle" then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
            end
        end
    end
    self.depositeButton:setVisible(false)
    self.withdrawalButton:setVisible(false)
    self:showDepositeMenu()
end

function AtmUI:onDepositeBack()
    self.titleLabelDeposite:setVisible(false)
    self.amountFieldDeposite:setVisible(false)
    self.sendButtonDeposite:setVisible(false)
    self.backButtonDeposite:setVisible(false)
    self.depositeButton:setVisible(true)
    self.withdrawalButton:setVisible(true)
end

function AtmUI:onWithdrawalBack()
    self.titleLabelWithdrawal:setVisible(false)
    self.amountFieldWithdrawal:setVisible(false)
    self.sendButtonWithdrawal:setVisible(false)
    self.backButtonWithdrawal:setVisible(false)
    self.depositeButton:setVisible(true)
    self.withdrawalButton:setVisible(true)
end

function AtmUI:onWithdrawalSend()
    local checkBalance = tonumber(loadAtmBalance())

    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local text = self.amountFieldWithdrawal:getText()
    local amount = tonumber(text)

    if not amount then
        return
    end
    
    if amount > 0 then
        if checkBalance >= amount then
            local remainingBalance = amount
            while remainingBalance >= 100 do
                inv:AddItem("Base.MoneyBundle")
                remainingBalance = remainingBalance - 100
            end
            for i = 1, remainingBalance do
                inv:AddItem("Base.Money")
            end
            local newBalance = checkBalance - amount

            saveAtmBalance(newBalance)
            self.balanceLabel:setName("Balance: $" .. tostring(newBalance))
        else
            return
        end 
    else
        return
    end
end

function AtmUI:onDepositeSend()
    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local checkBalance = loadAtmBalance()

    local moneyBundle = inv:FindAndReturn("Base.MoneyBundle")
    local text = self.amountFieldDeposite:getText()
    local amount = tonumber(text)

    if not amount then
        return
    end

    if amount > 0 then
        local moneyCount = 0
        for i = 0, inv:getItems():size() - 1 do
            local item = inv:getItems():get(i)
            if item and item:getType() == "Money" then
                moneyCount = moneyCount + item:getCount()
            end
        end

        if moneyCount < amount then
            local deficit = amount - moneyCount
            local moneyBundle = inv:FindAndReturn("Base.MoneyBundle")
            
            while deficit > 0 and moneyBundle do
                inv:Remove(moneyBundle)
                for i = 1, 100 do
                    inv:AddItem("Base.Money")
                end
                moneyCount = moneyCount + 100
                deficit = amount - moneyCount
                moneyBundle = inv:FindAndReturn("Base.MoneyBundle")
            end
        end

        for i = 1, amount do
            local moneyItem = inv:FindAndReturn("Base.Money")
            if moneyItem then
                inv:Remove(moneyItem)
            else
                break
            end
        end

        local newBalance = checkBalance
        if moneyCount >= amount then
            newBalance = amount + checkBalance
        else
            newBalance = moneyCount + checkBalance
        end

        saveAtmBalance(newBalance)
        self.balanceLabel:setName("Balance: $" .. tostring(newBalance))
    end
end

function AtmMenu_ShowUI(player)
    local texture = getTexture("media/ui/oldATM.png")
    if not texture then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()

    local maxW = realScreenW * 0.80
    local maxH = realScreenH * 0.80
    local texW = texture:getWidth()
    local texH = texture:getHeight()

    local ratioX, ratioY = maxW / texW, maxH / texH
    local scale  = math.min(ratioX, ratioY)
    local finalW, finalH = math.floor(texW * scale), math.floor(texH * scale)
    local uiX, uiY = (realScreenW - finalW) / 2, (realScreenH - finalH) / 2

    local uiAtm = AtmUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    uiAtm:addChild(centeredImage)
    uiAtm.centeredImage = centeredImage
    uiAtm:initialise()
    uiAtm:addToUIManager()

    return uiAtm
end

function AtmMenu_AddContext(player, context, worldobjects)
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoObject") then
            local sprite = obj:getSprite()
            if sprite and sprite:getName() then
                if string.find(sprite:getName(), "location_business_bank_01_67")
                or string.find(sprite:getName(), "location_business_bank_01_66")
                or string.find(sprite:getName(), "location_business_bank_01_65")
                or string.find(sprite:getName(), "location_business_bank_01_64") then
                    local square = obj:getSquare()
                    if square and ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or 
                     (getSandboxOptions():getElecShutModifier() > -1 and 
                     (getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30) < getSandboxOptions():getElecShutModifier())) then
                        local x, y, z = square:getX(), square:getY(), square:getZ()
                        context:addOption("ATM", obj, AtmMenu_OnUse, player, x, y, z, sprite:getName())
                        break
                     else
                        HaloTextHelper.addBadText(getPlayer(), "I need power");
                    end
                end
            end
        end
    end
end

function AtmMenu_OnUse(obj, player, x, y, z, sprite)
    local playerSquare = getPlayer():getSquare()
    if not (math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) <= 1) then
        local freeSquare = getAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), freeSquare))
        end
    end
    ISTimedActionQueue.add(ISATMAction:new(getPlayer()), obj)
end

Events.OnFillWorldObjectContextMenu.Add(AtmMenu_AddContext)