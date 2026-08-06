-- MailBox UI - by Raixxar
-- Updated : 25/01/26

MailBoxUI = ISPanel:derive("MailBoxUI")

local function PZLinuxMailBoxActionText(state)
    if state and state.hasPickup and state.hasContractDeposit then
        return PZLinuxGetText("IGUI_PZLinux_Mailbox_TakeAndSend")
    end
    if state and state.hasContractDeposit then
        return PZLinuxGetText("IGUI_PZLinux_Mailbox_SendContract")
    end
    if state and state.hasPickup then
        return PZLinuxGetText("IGUI_PZLinux_Mailbox_TakeItems")
    end
    return PZLinuxGetText("IGUI_PZLinux_Mailbox_Check")
end

-- CONSTRUCTOR
function MailBoxUI:new(x, y, width, height, player, mailboxObject)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0}
    o.borderColor     = {r=0.2, g=0.2, b=0.2, a=0}
    o.width           = width
    o.height          = height
    o.player          = player
    o.mailbox         = PZLinuxGetMailboxReference(mailboxObject)
    o.isClosing       = false
    o.mode            = "main"
    return o
end

-- INIT
function MailBoxUI:initialise()
    ISPanel.initialise(self)
    self:showLoginMenu()
end

function MailBoxUI:showLoginMenu()
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

    self.titleLabel = ISLabel:new(self.width * 0.225, self.width * 0.43, self.width * 0.1, "", 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.765, self.height * 0.35, self.width * 0.10, self.height * 0.050, PZLinuxGetText("IGUI_PZLinux_Mailbox_Leave"), self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    -- mailBox.png (the personal mailbox) only shows its actual mail slot
    -- across roughly the left third of the texture -- the rest of the
    -- canvas is the box's side panel and the flag pole. Unlike
    -- streetMailBox.png (where the slot spans nearly the full width),
    -- reusing the same 0.60 relative width here overflowed well past the
    -- slot, toward the flag.
    self.loginButton = ISButton:new(self.width * 0.132, self.height * 0.355, self.width * 0.25, self.height * 0.027, PZLinuxGetText("IGUI_PZLinux_Mailbox_Check"), self, self.onSendTakePackage)
    self.loginButton:setVisible(true)
    self.loginButton:setEnable(false)
    self.loginButton:initialise()
    self.topBar:addChild(self.loginButton)
    self:refreshActionState()
end

function MailBoxUI:refreshActionState()
    if not self.loginButton or self.isClosing then return end
    self.loginButton:setEnable(false)
    PZLinuxRequestMailboxActionState(self.player, self.mailbox, function(result)
        if self.isClosing or not self.loginButton then return end
        self.loginButton:setTitle(PZLinuxMailBoxActionText(result and result.ok and result or nil))
        self.loginButton:setEnable(true)
    end)
end

function MailBoxUI:onSendTakePackage()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    self.loginButton:setEnable(false)
    local pendingActions = 6
    local function PZLinuxMailBoxActionFinished()
        pendingActions = pendingActions - 1
        if pendingActions <= 0 then self:refreshActionState() end
    end

    PZLinuxRequestDarkWebRedeemSales(playerObj, self.mailbox, function(result)
        if result and result.ok and result.amount and result.amount > 0 then
            saveAtmBalance(result.balance, playerObj)
            HaloTextHelper.addGoodText(playerObj, "$" .. tostring(result.amount) .. " transferred to your bank account")
        end
        PZLinuxMailBoxActionFinished()
    end)

    PZLinuxRequestDarkWebDeliverOrders(playerObj, self.mailbox, function(result)
        if result and result.ok == false then
            HaloTextHelper.addBadText(playerObj, "Dark web delivery failed: " .. tostring(result.error or "unknown error"))
        elseif result and result.lost then
            HaloTextHelper.addBadText(playerObj, "Your order has been stolen during delivery!")
        elseif result and result.ok and result.delivered and result.delivered > 0 then
            HaloTextHelper.addGoodText(playerObj, "Dark web order delivered")
        end
        PZLinuxMailBoxActionFinished()
    end)

    PZLinuxRequestContractDeposit(playerObj, self.mailbox, function(result)
        if result and result.ok and result.removed and result.removed > 0 then
            HaloTextHelper.addGoodText(playerObj, "Contract package sent")
        end
        PZLinuxMailBoxActionFinished()
    end)

    PZLinuxRequestDeliver(playerObj, self.mailbox, function(result)
        if result and result.ok == false then
            HaloTextHelper.addBadText(playerObj, "Request delivery failed: " .. tostring(result.error or "unknown error"))
        elseif result and result.lost then
            HaloTextHelper.addBadText(playerObj, "Your order has been stolen during delivery!")
        elseif result and result.ok and result.delivered and result.delivered > 0 then
            HaloTextHelper.addGoodText(playerObj, "Request package delivered")
        end
        PZLinuxMailBoxActionFinished()
    end)

    PZLinuxRequestSellRedeemPackage(playerObj, self.mailbox, function(result)
        if result and result.ok == false then
            HaloTextHelper.addBadText(playerObj, "Sell surplus failed: " .. tostring(result.error or "unknown error"))
        elseif result and result.ok and result.sold and result.sold > 0 then
            saveAtmBalance(result.balance, playerObj)
            HaloTextHelper.addGoodText(playerObj, "$" .. tostring(result.total) .. " for your surplus")
        end
        PZLinuxMailBoxActionFinished()
    end)

    PZLinuxRequestMailRewardDelivery(playerObj, self.mailbox, function(result)
        if result and result.ok and result.delivered and result.delivered > 0 then
            HaloTextHelper.addGoodText(playerObj, "A gift for your help arrived")
        end
        PZLinuxMailBoxActionFinished()
    end)

end

function MailBoxUI:onClose()
    self.isClosing = true
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        playerObj:StopAllActionQueue()
    end
end

function MailBoxMenu_ShowUI(player, mailboxObject)
    local texture = getTexture("media/ui/mailBox.png")
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

    local uiMailBox = MailBoxUI:new(uiX, uiY, finalW, finalH, player, mailboxObject)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    uiMailBox:addChild(centeredImage)
    uiMailBox.centeredImage = centeredImage
    uiMailBox:initialise()
    uiMailBox:addToUIManager()

    return uiMailBox
end

function MailBoxMenu_AddContext(player, context, worldobjects)
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoObject") then
            local sprite = obj:getSprite()
            if sprite and sprite:getName() then
                if string.find(sprite:getName(), "street_decoration_01_18")
                or string.find(sprite:getName(), "street_decoration_01_19")
                or string.find(sprite:getName(), "street_decoration_01_20")
                or string.find(sprite:getName(), "street_decoration_01_21") then
                    local square = obj:getSquare()
                    if square then
                        local x, y, z = square:getX(), square:getY(), square:getZ()
                        context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_Mailbox"), obj, MailBoxMenu_OnUse, player, x, y, z, sprite:getName())
                        break
                    end
                end
            end
        end
    end
end

function MailBoxMenu_OnUse(obj, player, x, y, z, sprite)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISMailBoxAction:new(playerObj, obj))
end

Events.OnFillWorldObjectContextMenu.Add(MailBoxMenu_AddContext)
