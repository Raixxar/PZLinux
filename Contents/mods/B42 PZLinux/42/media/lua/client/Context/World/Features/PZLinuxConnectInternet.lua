connectUI = ISPanel:derive("connectUI")

-- CONSTRUCTOR
function connectUI:new(x, y, width, height, player)
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
function connectUI:initialise()
    ISPanel.initialise(self)

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
        local modData = PZLinuxGetPlayer(topBar.parent.player):getModData()
        modData.PZLinuxUIX = topBar.parent:getX()
        modData.PZLinuxUIY = topBar.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)


    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimize)
    self.minimizeButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeButton:setVisible(true)
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

-- CONNECT TO INTERNET
function connectUI:startConnect()
    local globalVolume = getCore():getOptionSoundVolume() / 50
    if self.isClosing or not PZLinuxGetPlayer(self.player) then
        return
    end

    local player = PZLinuxGetPlayer(self.player)
    local playerUsername = ""
    if player then
        playerUsername = string.lower(player:getUsername()) .. "@aol.com"
    end
    local loginBase = "login: "

    local passwordBase = "password: "
    local totalAsterisks = 8

    local messageTemplates = {
        {base = "Loading", variations = 10},
        {base = "Connected", variations = 0, repeatCount = 2},
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
        self.loadingMessage = ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.025, "#", 0, 1, 0, 1, UIFont.Small, true)
        self.loadingMessage:initialise()
        self.topBar:addChild(self.loadingMessage)
    end

    self.terminalCoroutine = coroutine.create(function()
        self.loadingMessage:setName(loginBase)
        if not PZLinux.Typing.waitProfile(self, "systemStatus") then return end
        if not PZLinux.Typing.typeLabel(self, self.loadingMessage, playerUsername, player, {
            prefix = loginBase,
            volume = globalVolume,
        }) then return end
        if not PZLinux.Typing.typeLabel(self, self.loadingMessage, string.rep("*", totalAsterisks), player, {
            prefix = passwordBase,
            volume = globalVolume,
        }) then return end
        getSoundManager():PlayWorldSound("upInternet", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)

        for _, message in ipairs(messages) do
            if self.isClosing then return end

            self.loadingMessage:setName(message)
            if not PZLinux.Typing.waitProfile(self, "systemStatus") then return end
        end

        self.topBar:removeChild(self.loadingMessage)
        self.loadingMessage = nil
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

-- LOGOUT
function connectUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function connectUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function connectUI:onCloseX(_button)
    self.isClosing = true
    PZLinuxGetPlayer(self.player):StopAllActionQueue()
end


function connectMenu_ShowUI(player)
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

    local ui = connectUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
    ui:startConnect()

    return ui
end
