-- StreetMailBox UI - by Raixxar
-- Updated : 25/01/26

StreetMailBoxUI = ISPanel:derive("StreetMailBoxUI")

local function PZLinuxStreetMailBoxActionText(state)
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
function StreetMailBoxUI:new(x, y, width, height, player, mailboxObject)
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
function StreetMailBoxUI:initialise()
    ISPanel.initialise(self)
    self:showLoginMenu()
end

function StreetMailBoxUI:showLoginMenu()
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

    self.closeButton = ISButton:new(self.width * 0.443, self.height * 0.467, self.width * 0.1, self.height * 0.055, PZLinuxGetText("IGUI_PZLinux_Mailbox_Leave"), self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.loginButton = ISButton:new(self.width * 0.195, self.height * 0.375, self.width * 0.6, self.height * 0.027, PZLinuxGetText("IGUI_PZLinux_Mailbox_Check"), self, self.onSendPackage)
    self.loginButton:setVisible(true)
    self.loginButton:setEnable(false)
    self.loginButton:initialise()
    self.topBar:addChild(self.loginButton)
    self:refreshActionState()
end

function StreetMailBoxUI:refreshActionState()
    if not self.loginButton or self.isClosing then return end
    self.loginButton:setEnable(false)
    PZLinuxRequestMailboxActionState(self.player, self.mailbox, function(result)
        if self.isClosing or not self.loginButton then return end
        self.loginButton:setTitle(PZLinuxStreetMailBoxActionText(result and result.ok and result or nil))
        self.loginButton:setEnable(true)
    end)
end

function StreetMailBoxUI:onSendPackage()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    self.loginButton:setEnable(false)
    local pendingActions = 4
    local function PZLinuxStreetMailBoxActionFinished()
        pendingActions = pendingActions - 1
        if pendingActions <= 0 then self:refreshActionState() end
    end

    PZLinuxRequestDarkWebRedeemSales(playerObj, self.mailbox, function(result)
        if result and result.ok and result.amount and result.amount > 0 then
            saveAtmBalance(result.balance, playerObj)
            HaloTextHelper.addGoodText(playerObj, "$" .. tostring(result.amount) .. " transferred to your bank account")
        end
        PZLinuxStreetMailBoxActionFinished()
    end)

    PZLinuxRequestDarkWebDeliverOrders(playerObj, self.mailbox, function(result)
        if result and result.ok == false then
            HaloTextHelper.addBadText(playerObj, "Dark web delivery failed: " .. tostring(result.error or "unknown error"))
        elseif result and result.lost then
            HaloTextHelper.addBadText(playerObj, "Your order has been stolen during delivery!")
        elseif result and result.ok and result.delivered and result.delivered > 0 then
            HaloTextHelper.addGoodText(playerObj, "Dark web order delivered")
        end
        PZLinuxStreetMailBoxActionFinished()
    end)

    PZLinuxRequestContractDeposit(playerObj, self.mailbox, function(result)
        if result and result.ok and result.removed and result.removed > 0 then
            HaloTextHelper.addGoodText(playerObj, "Contract package sent")
        end
        PZLinuxStreetMailBoxActionFinished()
    end)

    PZLinuxRequestDeliver(playerObj, self.mailbox, function(result)
        if result and result.ok == false then
            HaloTextHelper.addBadText(playerObj, "Request delivery failed: " .. tostring(result.error or "unknown error"))
        elseif result and result.lost then
            HaloTextHelper.addBadText(playerObj, "Your order has been stolen during delivery!")
        elseif result and result.ok and result.delivered and result.delivered > 0 then
            HaloTextHelper.addGoodText(playerObj, "Request package delivered")
        end
        PZLinuxStreetMailBoxActionFinished()
    end)

end

function StreetMailBoxUI:onClose()
    self.isClosing = true
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        playerObj:StopAllActionQueue()
    end
end

function StreetMailBoxMenu_ShowUI(player, mailboxObject)
    local texture = getTexture("media/ui/streetMailBox.png")
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

    local uiStreetMailBox = StreetMailBoxUI:new(uiX, uiY, finalW, finalH, player, mailboxObject)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    uiStreetMailBox:addChild(centeredImage)
    uiStreetMailBox.centeredImage = centeredImage
    uiStreetMailBox:initialise()
    uiStreetMailBox:addToUIManager()

    return uiStreetMailBox
end

function StreetMailBoxMenu_AddContext(player, context, worldobjects)
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoObject") then
            local sprite = obj:getSprite()
            if sprite and sprite:getName() then
                if string.find(sprite:getName(), "street_decoration_01_9")
                or string.find(sprite:getName(), "street_decoration_01_8")
                or string.find(sprite:getName(), "street_decoration_01_11")
                or string.find(sprite:getName(), "street_decoration_01_10") then
                    local square = obj:getSquare()
                    if square then
                        local x, y, z = square:getX(), square:getY(), square:getZ()
                        context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_Mailbox"), obj, StreetMailBoxMenu_OnUse, player, x, y, z, sprite:getName())
                        break
                    end
                end
            end
        end
    end
end

function StreetMailBoxMenu_OnUse(obj, player, x, y, z, sprite)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISStreetMailBoxAction:new(playerObj, obj))
end

Events.OnFillWorldObjectContextMenu.Add(StreetMailBoxMenu_AddContext)
