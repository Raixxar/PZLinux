-- ATM UI - by Raixxar
-- Updated : 25/01/26

AtmUI = ISPanel:derive("AtmUI")

-- True only if the player has an active "Refill an ATM" contract AND this
-- specific ATM object is the one hardcoded target -- carrying the withdrawn
-- cash to any other ATM must not work.
local function PZLinuxAtmRefillMatchesContract(playerObj, atmObject)
    if not playerObj or not atmObject or not atmObject.getSquare then
        print("[PZLinux ATM] refill check: missing playerObj/atmObject/getSquare")
        return false
    end
    local modData = playerObj:getModData()
    if tonumber(modData.PZLinuxContractAtmRefill) ~= 1 or tonumber(modData.PZLinuxActiveContract) ~= 1 then
        print("[PZLinux ATM] refill check: no matching active contract (PZLinuxContractAtmRefill="
            .. tostring(modData.PZLinuxContractAtmRefill) .. " PZLinuxActiveContract="
            .. tostring(modData.PZLinuxActiveContract) .. ")")
        return false
    end

    local square = atmObject:getSquare()
    if not square then
        print("[PZLinux ATM] refill check: this ATM object has no square")
        return false
    end
    local matches = square:getX() == tonumber(modData.PZLinuxContractLocationX)
        and square:getY() == tonumber(modData.PZLinuxContractLocationY)
        and square:getZ() == tonumber(modData.PZLinuxContractLocationZ)
    if not matches then
        print("[PZLinux ATM] refill check: location mismatch, this ATM=("
            .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
            .. ") contract target=(" .. tostring(modData.PZLinuxContractLocationX) .. ","
            .. tostring(modData.PZLinuxContractLocationY) .. "," .. tostring(modData.PZLinuxContractLocationZ) .. ")")
    end
    return matches
end

-- CONSTRUCTOR
function AtmUI:new(x, y, width, height, player, atmObject)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0}
    o.borderColor     = {r=0.2, g=0.2, b=0.2, a=0}
    o.width           = width
    o.height          = height
    o.player          = player
    o.atmObject       = atmObject
    o.isClosing       = false
    o.balance         = loadAtmBalance(player)
    o.atmCash         = PZLinuxAtmLoadCash(atmObject)
    o.mode            = "main"
    o.transactionPending = false
    return o
end

function AtmUI:updateBalanceLabels()
    self.balance = loadAtmBalance(self.player)
    self.atmCash = PZLinuxAtmLoadCash(self.atmObject)

    if self.balanceLabel then
        self.balanceLabel:setName(PZLinuxGetText("IGUI_PZLinux_ATM_Balance") .. tostring(self.balance))
    end
    if self.atmCashLabel then
        self.atmCashLabel:setName(PZLinuxGetText("IGUI_PZLinux_ATM_Cash") .. tostring(self.atmCash))
    end
end

function AtmUI:setTransactionPending(isPending)
    self.transactionPending = isPending == true
    if self.sendButtonWithdrawal and self.sendButtonWithdrawal.setEnable then
        self.sendButtonWithdrawal:setEnable(not self.transactionPending)
    end
    if self.sendButtonDeposite and self.sendButtonDeposite.setEnable then
        self.sendButtonDeposite:setEnable(not self.transactionPending)
    end
end

function AtmUI:syncFromTransactionResult(result)
    if not result then return end

    if result.balance ~= nil then
        saveAtmBalance(result.balance, self.player)
    end
    if result.atmCash ~= nil and self.atmObject then
        self.atmObject:getModData().PZLinuxAtmCash = PZLinuxNormalizeMoney(result.atmCash)
    end

    self:updateBalanceLabels()
end

function AtmUI:showTransactionError(result)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local errorCode = result and result.error
    local message = PZLinuxGetText("IGUI_PZLinux_ATM_TransactionFailed")
    if errorCode == "not_enough_atm_cash" then
        message = PZLinuxGetText("IGUI_PZLinux_ATM_NotEnoughCash")
    elseif errorCode == "not_enough_bank" then
        message = PZLinuxGetText("IGUI_PZLinux_ATM_NotEnoughBank")
    elseif errorCode == "not_enough_inventory_cash" then
        message = PZLinuxGetText("IGUI_PZLinux_ATM_NotEnoughInventoryCash")
    elseif errorCode == "atm_not_found" then
        message = PZLinuxGetText("IGUI_PZLinux_ATM_NotFound")
    elseif errorCode == "invalid_amount" then
        message = PZLinuxGetText("IGUI_PZLinux_ATM_InvalidAmount")
    elseif errorCode == "wrong_atm" then
        message = PZLinuxFormatText("IGUI_PZLinux_ATM_WrongAtm", "This is not the ATM the contract needs refilled.")
    elseif errorCode == "no_active_contract" then
        message = PZLinuxFormatText("IGUI_PZLinux_ATM_NoActiveContract", "You have no active ATM refill contract.")
    end

    HaloTextHelper.addBadText(playerObj, message)
end

function AtmUI:handleTransactionResult(result)
    self:setTransactionPending(false)
    self:syncFromTransactionResult(result)
    if not result or not result.ok then
        self:showTransactionError(result)
        return
    end

    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        HaloTextHelper.addGoodText(playerObj, PZLinuxGetText("IGUI_PZLinux_ATM_TransactionComplete"))
    end
end

-- SAVE BALANCE BANK ACCOUNT
function saveAtmBalance(balance, player)
    if balance == nil then return PZLinuxLoadBankBalance(player) end
    return PZLinuxSetBankBalance(player, balance)
end

function loadAtmBalance(player)
    return PZLinuxLoadBankBalance(player)
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

    function self.topBar.onMouseDown(topBar, _x, _y)
        topBar.parent.isDragging = true
        topBar.parent.initialX = topBar.parent:getX()
        topBar.parent.initialY = topBar.parent:getY()
        topBar.parent.mouseStartX = getMouseX()
        topBar.parent.mouseStartY = getMouseY()
    end

    function self.topBar.onMouseMove(topBar, _x, _y)
        if topBar.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - topBar.parent.mouseStartX
            local dy = curMouseY - topBar.parent.mouseStartY
            topBar.parent:setX(topBar.parent.initialX + dx)
            topBar.parent:setY(topBar.parent.initialY + dy)
        end
    end

    function self.topBar.onMouseUp(topBar, _x, _y)
        topBar.parent.isDragging = false
    end

    self.titleLabel = ISLabel:new(self.width * 0.225, self.width * 0.43, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_Title"), 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.527, self.width * 0.461, self.width * 0.1, self.height * 0.027, PZLinuxGetText("IGUI_PZLinux_ATM_Leave"), self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.loginButton = ISButton:new(self.width * 0.295, self.width * 0.55, self.width * 0.25, self.height * 0.08, PZLinuxGetText("IGUI_PZLinux_ATM_Login"), self, self.onLoginMenu)
    self.loginButton:setVisible(true)
    self.loginButton:initialise()
    self.topBar:addChild(self.loginButton)

    self.passwordLabel = ISLabel:new(self.width * 0.225, self.width * 0.48, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_Password"), 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.passwordLabel:setVisible(false)
    self.passwordLabel:initialise()
    self.topBar:addChild(self.passwordLabel)
end

-- Creates the "REFILL FOR CONTRACT" button once, the first time modData
-- confirms a matching active contract -- safe to call repeatedly (e.g. once
-- synchronously, then again after an async resync) since it no-ops if the
-- button already exists or if the contract still isn't a match.
function AtmUI:ensureContractRefillButton()
    if self.contractRefillButton then return end
    if not PZLinuxAtmRefillMatchesContract(PZLinuxGetPlayer(self.player), self.atmObject) then return end

    self.contractRefillButton = ISButton:new(
        self.width * 0.295, self.width * 0.77, self.width * 0.25, self.height * 0.08,
        PZLinuxFormatText("IGUI_PZLinux_ATM_ContractRefill", "REFILL FOR CONTRACT"),
        self, self.onContractRefillDeposit
    )
    self.contractRefillButton:setVisible(true)
    self.contractRefillButton:initialise()
    self.topBar:addChild(self.contractRefillButton)
end

function AtmUI:showMainMenu()
    self.withdrawalButton = ISButton:new(self.width * 0.295, self.width * 0.55, self.width * 0.25, self.height * 0.08, PZLinuxGetText("IGUI_PZLinux_ATM_Withdrawal"), self, self.onWithdrawal)
    self.withdrawalButton:setVisible(true)
    self.withdrawalButton:initialise()
    self.topBar:addChild(self.withdrawalButton)

    self.depositeButton = ISButton:new(self.width * 0.295, self.width * 0.66, self.width * 0.25, self.height * 0.08, PZLinuxGetText("IGUI_PZLinux_ATM_Deposit"), self, self.onDeposite)
    self.depositeButton:setVisible(true)
    self.depositeButton:initialise()
    self.topBar:addChild(self.depositeButton)

    self:ensureContractRefillButton()

    -- Unlike computers, the ATM never otherwise asks the server to
    -- resynchronize contract state on open. In real MP, the client's local
    -- modData can be stale after a reconnect (native ModData transmission is
    -- not reliable for this), so the check above may wrongly see no active
    -- contract yet. Re-check once the server confirms the current state.
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        PZLinuxRequestContractSync(playerObj, function()
            if self.isClosing then return end
            self:ensureContractRefillButton()
        end)
    end

    self.atmCashLabel = ISLabel:new(self.width * 0.225, self.width * 0.448, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_Cash") .. tostring(self.atmCash), 1, 1, 1, 1, UIFont.Small, true)
    self.atmCashLabel:initialise()
    self:addChild(self.atmCashLabel)

    self.balanceLabel = ISLabel:new(self.width * 0.225, self.width * 0.47, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_Balance") .. tostring(self.balance), 1, 1, 1, 1, UIFont.Small, true)
    self.balanceLabel:initialise()
    self:addChild(self.balanceLabel)
    self:updateBalanceLabels()

    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        PZLinuxRequestAtmSync(playerObj, self.atmObject, function(result)
            if self.isClosing then return end
            self:syncFromTransactionResult(result)
        end)
    end
end

function AtmUI:showDepositeMenu()
    self.titleLabelDeposite = ISLabel:new(self.width * 0.225, self.width * 0.50, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_DepositMoney"), 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabelDeposite:initialise()
    self:addChild(self.titleLabelDeposite)

    self.amountFieldDeposite = ISTextEntryBox:new("", self.width * 0.315, self.width * 0.58, self.width * 0.229, self.height * 0.025)
    self.amountFieldDeposite:initialise()
    self.amountFieldDeposite:instantiate()
    self:addChild(self.amountFieldDeposite)

    self.sendButtonDeposite = ISButton:new(self.width * 0.315, self.width * 0.63, self.width * 0.10, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_ATM_Send"), self, self.onDepositeSend)
    self.sendButtonDeposite:initialise()
    self:addChild(self.sendButtonDeposite)

    self.backButtonDeposite = ISButton:new(self.width * 0.445, self.width * 0.63, self.width * 0.10, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_ATM_Back"), self, self.onDepositeBack)
    self.backButtonDeposite:initialise()
    self:addChild(self.backButtonDeposite)
end

function AtmUI:showWithdrawalMenu()
    self.titleLabelWithdrawal = ISLabel:new(self.width * 0.225, self.width * 0.50, self.width * 0.1, PZLinuxGetText("IGUI_PZLinux_ATM_WithdrawalMoney"), 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabelWithdrawal:initialise()
    self:addChild(self.titleLabelWithdrawal)

    self.amountFieldWithdrawal = ISTextEntryBox:new("", self.width * 0.315, self.width * 0.58, self.width * 0.229, self.height * 0.025)
    self.amountFieldWithdrawal:initialise()
    self.amountFieldWithdrawal:instantiate()
    self:addChild(self.amountFieldWithdrawal)

    self.sendButtonWithdrawal = ISButton:new(self.width * 0.315, self.width * 0.63, self.width * 0.10, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_ATM_Send"), self, self.onWithdrawalSend)
    self.sendButtonWithdrawal:initialise()
    self:addChild(self.sendButtonWithdrawal)

    self.backButtonWithdrawal = ISButton:new(self.width * 0.445, self.width * 0.63, self.width * 0.10, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_ATM_Back"), self, self.onWithdrawalBack)
    self.backButtonWithdrawal:initialise()
    self:addChild(self.backButtonWithdrawal)
end

function AtmUI:onLoginMenu()
    local globalVolume = getCore():getOptionSoundVolume() / 50
    self.loginButton:setVisible(false)
    local playerObj = PZLinuxGetPlayer(self.player)
    if self.isClosing or not playerObj then
        return
    end

    local loginBase = PZLinuxGetText("IGUI_PZLinux_ATM_InsertCard")

    local passwordBase = PZLinuxGetText("IGUI_PZLinux_ATM_PasswordPrompt")
    local totalAsterisks = 4

    local messageTemplates = {
        {base = PZLinuxGetText("IGUI_PZLinux_ATM_Loading"), variations = 2},
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
        getSoundManager():PlayWorldSound("creditCard", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        self.loadingMessage:setName(loginBase)
        if not PZLinux.Typing.waitProfile(self, "atmPrompt") then return end

        self.loadingMessage:setName(passwordBase)
        if not PZLinux.Typing.waitProfile(self, "atmPrompt") then return end
        if not PZLinux.Typing.typeLabel(self, self.loadingMessage, string.rep("*", totalAsterisks), playerObj, {
            prefix = passwordBase,
            soundName = "atmBip",
            endSound = false,
            volume = globalVolume,
        }) then return end

        for _, message in ipairs(messages) do
            if self.isClosing then
                return
            end

            self.loadingMessage:setName(message)
            if not PZLinux.Typing.waitProfile(self, "atmStatus") then return end
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
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        playerObj:StopAllActionQueue()
    end
end

function AtmUI:onWithdrawal()
    self.depositeButton:setVisible(false)
    self.withdrawalButton:setVisible(false)
    self:showWithdrawalMenu()
end

function AtmUI:onDeposite()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    for i=1,containers:size() do
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
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end
    if self.transactionPending then return end

    local text = self.amountFieldWithdrawal:getText()
    local amount = tonumber(text)

    if not amount then
        return
    end

    if amount <= 0 then
        self:showTransactionError({ error = "invalid_amount" })
        return
    end

    self:setTransactionPending(true)
    PZLinuxRequestAtmWithdrawal(playerObj, self.atmObject, amount, function(result)
        if self.isClosing then return end
        self:handleTransactionResult(result)
    end)
end

function AtmUI:onDepositeSend()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end
    if self.transactionPending then return end

    local text = self.amountFieldDeposite:getText()
    local amount = tonumber(text)

    if not amount then
        return
    end

    if amount <= 0 then
        self:showTransactionError({ error = "invalid_amount" })
        return
    end

    self:setTransactionPending(true)
    PZLinuxRequestAtmDeposit(playerObj, self.atmObject, amount, function(result)
        if self.isClosing then return end
        self:handleTransactionResult(result)
    end)
end

function AtmUI:onContractRefillDeposit()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end
    if self.transactionPending then return end

    self:setTransactionPending(true)
    PZLinuxRequestContractAtmRefillDeposit(playerObj, self.atmObject, function(result)
        if self.isClosing then return end
        self:setTransactionPending(false)
        self:syncFromTransactionResult(result)
        if not result or not result.ok then
            self:showTransactionError(result)
            return
        end

        if self.contractRefillButton then
            self.contractRefillButton:setVisible(false)
        end
        HaloTextHelper.addGoodText(playerObj, PZLinuxFormatText(
            "IGUI_PZLinux_ATM_ContractRefillDone",
            "The ATM has been refilled. Head back to a computer to complete the contract."
        ))
    end)
end

function AtmMenu_ShowUI(player, atmObject)
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

    local uiAtm = AtmUI:new(uiX, uiY, finalW, finalH, player, atmObject)
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
    local playerObj = PZLinuxGetPlayer(player)
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
                        context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_ATM"), obj, AtmMenu_OnUse, player, x, y, z, sprite:getName())
                        break
                     else
                        if playerObj then
                            HaloTextHelper.addBadText(playerObj, PZLinuxGetText("IGUI_PZLinux_NeedPower"));
                        end
                    end
                end
            end
        end
    end
end

function AtmMenu_OnUse(obj, player, x, y, z, sprite)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISATMAction:new(playerObj, obj))
end

Events.OnFillWorldObjectContextMenu.Add(AtmMenu_AddContext)
