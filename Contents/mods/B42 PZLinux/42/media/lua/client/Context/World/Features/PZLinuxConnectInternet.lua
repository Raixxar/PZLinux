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

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onStop)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimize)
    self.minimizeButton:setVisible(true)
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onStop)
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

-- CONNECT TO INTERNET
function connectUI:startConnect()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    if self.isClosing or not getPlayer() then
        return
    end

    local player = getSpecificPlayer(0)
    local playerUsername = ""
    if player then
        playerUsername = string.lower(player:getUsername()) .. "@hotmail.com"
    end
    local loginBase = "login: "
    local currentLogin = loginBase
    local index = 1
    local totalLetters = string.len(playerUsername)

    local passwordBase = "password: "
    local currentPassword = passwordBase
    local passwordIndex = 1
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
        local initialDelay = 4.0
        local elapsed = 0
        while elapsed < initialDelay do
            if self.isClosing then
                return
            end
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        while index <= totalLetters do
            if self.isClosing then
                return
            end

            local randomSoundIndex = ZombRand(1, 10)
            local soundName = "typingKeyboard" .. randomSoundIndex
            getSoundManager():PlayWorldSound(soundName, false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            
            currentLogin = currentLogin .. string.sub(playerUsername, index, index)
            index = index + 1
            self.loadingMessage:setName(currentLogin)

            local letterDelay = ZombRand(1, 3) / (player:getPerkLevel(Perks.Electricity) + 1)
            local elapsed = 0
            while elapsed < letterDelay do
                if self.isClosing then
                    return
                end
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
        end
        getSoundManager():PlayWorldSound("typingKeyboardEnd", false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)

        while passwordIndex <= totalAsterisks do
            if self.isClosing then
                return
            end

            local randomSoundIndex = ZombRand(1, 10)
            local soundName = "typingKeyboard" .. randomSoundIndex
            getSoundManager():PlayWorldSound(soundName, false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)

            currentPassword = currentPassword .. "*"
            passwordIndex = passwordIndex + 1
            self.loadingMessage:setName(currentPassword)
            local passwordDelay = ZombRand(1, 3) / (player:getPerkLevel(Perks.Electricity) + 1)
            local elapsed = 0
            while elapsed < passwordDelay do
                if self.isClosing then
                    return
                end
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
        end
        getSoundManager():PlayWorldSound("typingKeyboardEnd", false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        getSoundManager():PlayWorldSound("upInternet", false, player:getSquare(), 0, 100, 1, true):setVolume(globalVolume)

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

-- STOP
function connectUI:onStop(button)
    self.isClosing = true
    self:removeFromUIManager()
end

-- LOGOUT
function connectUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    linuxMenu_ShowUI(player)
end

-- CLOSE
function connectUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
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
    local uiX, uiY = (realScreenW - finalW) / 2, (realScreenH - finalH) / 2

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
end