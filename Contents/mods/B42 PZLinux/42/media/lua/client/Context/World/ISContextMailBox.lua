-- MailBox UI - by Raixxar 
-- Updated : 25/01/26

MailBoxUI = ISPanel:derive("MailBoxUI")

-- CONSTRUCTOR
function MailBoxUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0}
    o.borderColor     = {r=0.2, g=0.2, b=0.2, a=0}
    o.width           = width
    o.height          = height
    o.player          = player
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

    self.titleLabel = ISLabel:new(self.width * 0.225, self.width * 0.43, self.width * 0.1, "", 0.8, 1, 0.8, 1, UIFont.Small, true)
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.765, self.height * 0.35, self.width * 0.025, self.height * 0.050, "LEAVE", self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.loginButton = ISButton:new(self.width * 0.132, self.height * 0.355, self.width * 0.25, self.height * 0.027, "SEND THE PACKAGE", self, self.onSendPackage)
    self.loginButton:setVisible(true)
    self.loginButton:initialise()
    self.topBar:addChild(self.loginButton)
end

function MailBoxUI:onSendPackage()
    local playerObj = getPlayer()
    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if item and item:getFullType() == "Base.SuspiciousPackage" then
            local boxName = item:getName()
            boxName = boxName:gsub("%$", "")
            local balance = loadAtmBalance()
            local amount = tonumber(boxName)
            if amount then
                saveAtmBalance(balance + amount)
                inventory:Remove(item)
                break
            end
        end
    end
end

function MailBoxUI:onClose()
    self.isClosing = true
    self:removeFromUIManager()
end

function MailBoxMenu_ShowUI(player)
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

    local uiMailBox = MailBoxUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    uiMailBox:addChild(centeredImage)
    uiMailBox.centeredImage = centeredImage
    uiMailBox:initialise()
    uiMailBox:addToUIManager()
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
                        context:addOption("MailBox", obj, MailBoxMenu_OnUse, player)
                        break
                    end
                end
            end
        end
    end
end

function MailBoxMenu_OnUse(option, worldObject, player)
    MailBoxMenu_ShowUI(player)
end

Events.OnFillWorldObjectContextMenu.Add(MailBoxMenu_AddContext)