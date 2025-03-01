-- Contracts UI - by Raixxar 
-- Updated : 25/02/25

requestUI = ISPanel:derive("requestUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0

local requests = {
    [1] = { baseName = "Canned food", price = 1000 },
    [2] = { baseName = "Protein", price = 2000 },
    [3] = { baseName = "Seafood", price = 2000 },
    [4] = { baseName = "Fruits", price = 4000 },
    [5] = { baseName = "Vegetables", price = 4000 },
    [6] = { baseName = "Pickled food", price = 5000 },
    [7] = { baseName = "Drink", price = 5000 },
}

local contracts = {}
for i = 1, 7 do
    local getHourTimePriceValue = math.ceil(getGameTime():getWorldAgeHours()/2190 + 1)   
    itemName = requests[i].baseName
    itemPrice = math.ceil(ZombRand(requests[i].price, requests[i].price * getHourTimePriceValue)/10)*10
    contracts[i] = { id = i, name = itemName, price = itemPrice, icon = iconTex }
end

-- CONSTRUCTOR
function requestUI:new(x, y, width, height, player)
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
function requestUI:initialise()
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
    self.titleLabel:setVisible(true)
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
   
    local y = 0.20
    self.contractButtons = {}
    for i = 1, #contracts do
        local contract = contracts[i]
        local contractButton = ISButton:new(self.width * 0.20, self.height * y, self.width * 0.57, self.height * 0.05, contract.name, self, self.onSelectContract)
        contractButton.textColor = {r=0, g=1, b=0, a=1}
        contractButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
        contractButton.borderColor = {r=0, g=1, b=0, a=0.5}
        contractButton.contractId = contract.id
        contractButton.contractPosition = i
        contractButton:setVisible(true)
        contractButton:initialise()
        self.topBar:addChild(contractButton)
        table.insert(self.contractButtons, contractButton)
        y = y + 0.06
    end
end

function requestUI:onSelectContract(button)
    for _, button in ipairs(self.contractButtons) do
        button:setVisible(false)
    end
    self:onContractId(button.contractId)
end

function requestUI:onContractId(contract)
    local globalVolume = getCore():getOptionSoundVolume() / 10
    local player = getPlayer()
    
    if not self.typingMessage then
        self.typingMessage = ISLabel:new(self.width * 0.20, self.height * 0.65, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
        self.typingMessage:initialise()
        self.topBar:addChild(self.typingMessage)
    end
    
    if not self.loadingMessage then
        self.loadingMessage = ISLabel:new(self.width * 0.20, self.height * 0.45, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
        self.loadingMessage:initialise()
        self.topBar:addChild(self.loadingMessage)
    end
    
    local function typeText(label, text, callback)
        local index, message = 1, ""
        local totalLetters = string.len(text)
        
        while index <= totalLetters do
            if self.isClosing then return end
            
            local soundName = "typingKeyboard" .. ZombRand(1, 10)
            getSoundManager():PlayWorldSound(soundName, false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            
            message = message .. string.sub(text, index, index)
            index = index + 1
            label:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(1, 3) / (player:getPerkLevel(Perks.Electricity) + 1) do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
        end
        
        getSoundManager():PlayWorldSound("typingKeyboardEnd", false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        if callback then callback() end
    end
    
    self.terminalCoroutine = coroutine.create(function()
        local modData = getPlayer():getModData()
        local message = ""

        message = "Waiting for a seller..."
        self.loadingMessage:setName(message)

        local elapsed = 0
        while elapsed < ZombRand(20, 100) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        message = "User Unknown has connected to the room."
        self.loadingMessage:setName(message)

        local elapsed = 0
        while elapsed < ZombRand(10, 50) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        message = "Unknown: Are you looking for " .. contracts[contract].name .. " ?"
        self.loadingMessage:setName(message)
        
        local elapsed = 0
        while elapsed < ZombRand(5, 25) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        typeText(self.typingMessage, "Yes, do you have any for sale ?", function()
            message = message .. "\nYou: Yes, do you have any for sale ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)
        
        local elapsed = 0
        while elapsed < ZombRand(5, 25) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        local quests = {}
        if contract == 1 then
            quests = {
                [1] = { baseName = "Base.TinnedBeans" },
                [2] = { baseName = "Base.CannedCarrots2" },
                [3] = { baseName = "Base.CannedChili" },
                [4] = { baseName = "Base.CannedCorn" },
            }
        end
        
        local randomQuest = ZombRand(1, #quests + 1)
        local quest = quests[randomQuest]
        if quest then
            modData.PZLinuxOnItemRequest = quest.baseName
            print(modData.PZLinuxOnItemRequest)
        end
        
        modData.PZLinuxOnItemRequestCount = ZombRand(5, 10)
        message = message .. "\nUnknown: Yes, I can sell you " .. modData.PZLinuxOnItemRequestCount .. " for $" .. contracts[contract].price .. " each."
        self.loadingMessage:setName(message)

        local elapsed = 0
        while elapsed < ZombRand(5, 25) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        message = message .. "\nUnknown: Do you want to buy ?"
        self.loadingMessage:setName(message)

        local elapsed = 0
        while elapsed < ZombRand(5, 25) do
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        message = message .. "\n\nTOTAL: $" .. modData.PZLinuxOnItemRequestCount * contracts[contract].price
        self.loadingMessage:setName(message)

        self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
        self.yesButton:initialise()
        self.yesButton:instantiate()
        self.topBar:addChild(self.yesButton)
        
        self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
        self.noButton:initialise()
        self.noButton:instantiate()
        self.topBar:addChild(self.noButton)
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

function requestUI:onYesButton(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxActiveRequest = 1
    self.isClosing = true
    self:removeFromUIManager()
    requestMenu_ShowUI(player)
end

-- STOP
function requestUI:onStop(button)
    self.isClosing = true
    self:removeFromUIManager()
end

-- LOGOUT
function requestUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    requestMenu_ShowUI(player)
end

-- CLOSE
function requestUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    requestMenu_ShowUI(player)
end

function requestMenu_ShowUI(player)
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

    local ui = requestUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
end