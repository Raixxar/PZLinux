-- Contracts UI - by Raixxar 
-- Updated : 03/03/25

bettingUI = ISPanel:derive("bettingUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0

local bettings = {
    [1] = { baseName = "Zombie Race", price = ZombRand(1,5000) },
}

local betGame = {}
for i = 1, 1 do
    local getHourTimePriceValue = math.ceil(getGameTime():getWorldAgeHours()/2190 + 1)   
    itemName = bettings[i].baseName
    itemPrice = math.ceil(ZombRand(bettings[i].price, bettings[i].price * getHourTimePriceValue)/10)*10
    betGame[i] = { id = i, name = itemName, price = itemPrice, icon = iconTex }
end

-- CONSTRUCTOR
function bettingUI:new(x, y, width, height, player)
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
function bettingUI:initialise()
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

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
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

    local modData = getPlayer():getModData()
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

    self.minimizeBackButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimizeBack)
    self.minimizeBackButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeBackButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeBackButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeBackButton:setVisible(false)
    self.minimizeBackButton:initialise()
    self.topBar:addChild(self.minimizeBackButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
   
    local y = 0.20
    self.betButtons = {}
    for i = 1, #betGame do
        local bet = betGame[i]
        local betButton = ISButton:new(self.width * 0.20, self.height * y, self.width * 0.57, self.height * 0.05, bet.name, self, self.onSelectBet)
        betButton.textColor = {r=0, g=1, b=0, a=1}
        betButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
        betButton.borderColor = {r=0, g=1, b=0, a=0.5}
        betButton.betId = bet.id
        betButton.betPosition = i
        betButton:setVisible(true)
        betButton:initialise()
        self.topBar:addChild(betButton)
        table.insert(self.betButtons, betButton)
        y = y + 0.06
    end
end

function bettingUI:onSelectBet(button)
    self.minimizeBackButton:setVisible(true)
    self.minimizeButton:setVisible(false)

    for _, button in ipairs(self.betButtons) do
        button:setVisible(false)
    end

    local zombie = {
        [1] = { name = "Gallop Zomb", rating = ZombRand(1,10) },
        [2] = { name = "The Great Gallopino", rating = ZombRand(1,10) },
        [3] = { name = "Zombplay", rating = ZombRand(1,15) },
        [4] = { name = "AppleJack", rating = ZombRand(1,15) },
        [5] = { name = "Hocus Pocus", rating = ZombRand(1,15) },
        [6] = { name = "Mr Ed", rating = ZombRand(1,15) },
        [7] = { name = "Whinny the Poop", rating = ZombRand(1,15) },
        [8] = { name = "Long Drop Face", rating = ZombRand(1,15) },
        [9] = { name = "Eyes Out", rating = ZombRand(1,15) },
        [10] = { name = "Smell Bad", rating = ZombRand(1,15) },
        [11] = { name = "Crawler Texas Ranger", rating = ZombRand(1,15) },
        [12] = { name = "Walk to the Moon", rating = ZombRand(1,15) },
        [13] = { name = "Never Sleep Again", rating = ZombRand(1,15) },
        [14] = { name = "Tobit or not Tobit", rating = ZombRand(1,15) },
        [15] = { name = "Toothless", rating = ZombRand(1,20) },
        [16] = { name = "Barefoot", rating = ZombRand(1,20) },
        [17] = { name = "Always Hungry", rating = ZombRand(1,20) },
        [18] = { name = "Eat This", rating = ZombRand(1,20) },
        [19] = { name = "Horde", rating = ZombRand(1,20) },
        [20] = { name = "Toc toc toc", rating = ZombRand(1,20) },
        [21] = { name = "I have Maggots", rating = ZombRand(1,20) },
        [22] = { name = "Glenn", rating = ZombRand(1,20) },
        [23] = { name = "Alpha", rating = ZombRand(1,20) },
        [24] = { name = "A Zomb With No Name", rating = ZombRand(1,20) },
        [25] = { name = "Nobody", rating = ZombRand(1,20) },
        [26] = { name = "No Arms no Chocolate", rating = ZombRand(1,20) },
        [27] = { name = "Zomby McZombyface", rating = ZombRand(1,20) },
        [28] = { name = "Biscuit", rating = ZombRand(1,20) },
        [29] = { name = "Zomby Jumper", rating = ZombRand(1,20) },
        [30] = { name = "Rainbow Rider", rating = ZombRand(1,20) },
        [31] = { name = "Fuzzy Wuzzy", rating = ZombRand(1,50) },
        [32] = { name = "Tony Spark", rating = ZombRand(1,50) },
        [33] = { name = "Thannos", rating = ZombRand(1,50) },
        [34] = { name = "Worm", rating = ZombRand(1,50) },
        [35] = { name = "Should be the wind", rating = ZombRand(1,50) },
        [36] = { name = "Machu Pichtou", rating = ZombRand(1,50) },
        [37] = { name = "Sponge Zomb", rating = ZombRand(1,100) },
        [38] = { name = "Jean Cloud", rating = ZombRand(1,100) },
        [39] = { name = "The King is dead", rating = ZombRand(1,100) },
        [40] = { name = "Terminathour", rating = ZombRand(1,100) }
    }

    for i = #zombie, 2, -1 do
        local j = ZombRand(1, i)
        zombie[i], zombie[j] = zombie[j], zombie[i]
    end

    self.selectedZombies = {}
    for i = 1, 8 do
        table.insert(self.selectedZombies, zombie[i])
    end

    if not self.zombieLabels then
        self.zombieLabels = {}
    end

    for _, label in ipairs(self.zombieLabels) do
        label:removeFromUIManager()
    end

    self.zombieLabels = {}
    local yOffset = self.height * 0.25
    for i, zomb in ipairs(self.selectedZombies) do
        local labelText = string.format("%d. %s - %d/1", i, zomb.name, zomb.rating)
        local label = ISLabel:new(self.width * 0.20, yOffset, self.height * 0.025, labelText, 0, 1, 0, 1, UIFont.Small, true)
        label:initialise()
        label:instantiate()
        self:addChild(label)
        table.insert(self.zombieLabels, label)
        yOffset = yOffset + 25
    end

    self.betInput = ISTextEntryBox:new("Bet on?", self.width * 0.2, self.height * 0.59, self.width * 0.15, self.height * 0.033)
    self.betInput:initialise()
    self.betInput:instantiate()
    self.betInput:setOnlyNumbers(true)
    self.topBar:addChild(self.betInput)

    self.amountInput = ISTextEntryBox:new("Amount", self.width * 0.35, self.height * 0.59, self.width * 0.15, self.height * 0.033)
    self.amountInput:initialise()
    self.amountInput:instantiate()
    self.amountInput:setOnlyNumbers(true)
    self.topBar:addChild(self.amountInput)

    self.startButton = ISButton:new(self.width * 0.20, self.height * 0.625, self.width * 0.57, self.height * 0.05, "START THE RACE!", self, self.onSelectStart)
    self.startButton.textColor = {r=0, g=1, b=0, a=1}
    self.startButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.startButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.startButton:setVisible(true)
    self.startButton:initialise()
    self.topBar:addChild(self.startButton)
end

function bettingUI:onSelectStart()
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)
    local globalVolume = getCore():getOptionSoundVolume() / 10
    if not tonumber(self.amountInput:getText()) 
        or not tonumber(self.betInput:getText()) 
        or tonumber(self.amountInput:getText()) < 1 
        or tonumber(self.betInput:getText()) < 1 
        or tonumber(self.betInput:getText()) > 8 
        or tonumber(self.amountInput:getText()) > loadAtmBalance() then

        getSoundManager():PlayWorldSound("error", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        return
    end

    newBalance = loadAtmBalance() - tonumber(self.amountInput:getText())
    saveAtmBalance(newBalance)
    self.titleLabel:setName("Account Balance $" .. tostring(newBalance))

    getSoundManager():PlayWorldSound("race", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    self.betInput:setVisible(false)
    self.amountInput:setVisible(false)
    self.startButton:setVisible(false)

    if not self.selectedZombies or #self.selectedZombies == 0 then
        return
    end

    self.raceProgress = {}
    self.raceFinished = false

    for i, zomb in ipairs(self.selectedZombies) do
        self.raceProgress[i] = { zombie = zomb, position = -15 }
    end

    self:runRace()
end

function bettingUI:runRace()
    if self.raceFinished then return end

    for _, runner in ipairs(self.raceProgress) do
        local rating = runner.zombie.rating
        local baseSpeed = 5
        local bonus = (100 - rating) / 25
        local speed = baseSpeed + ZombRand(0, bonus)
        runner.position = runner.position + speed
    end

    local actualPosition = -math.huge
    local potentialWinner = nil
    local pos = nil

    for i, runner in ipairs(self.raceProgress) do
        if runner.position > actualPosition then
            actualPosition = runner.position
            potentialWinner = runner.zombie
            pos = i
        end
    end

    if actualPosition >= 130 then
        self.raceFinished = true
        self:declareWinner(pos, potentialWinner)
    end

    self:updateRaceDisplay()
    self:delayFunction(function() self:runRace() end, 20)
end

function bettingUI:updateRaceDisplay()
    local sortedRunners = {}
    
    for i, runner in ipairs(self.raceProgress) do
        table.insert(sortedRunners, { id = i, runner = runner })
    end

    table.sort(sortedRunners, function(a, b)
        return a.runner.position > b.runner.position
    end)

    if not self.zombieTextLabels then
        self.zombieTextLabels = {}
    end

    local yOffset = self.height * 0.52
    local labelText = "Your bet: " .. tonumber(self.amountInput:getText()) .. "$ on the zombie [" .. tonumber(self.betInput:getText()) .. "]"
    for rank, data in ipairs(sortedRunners) do
        local corde = data.id
        local progressText = string.format("%d. %s@C", corde, string.rep(".", data.runner.position))
        self.zombieLabels[data.id]:setName(progressText)
        if rank == 1 or rank == 2 or rank == 3 or rank == 4 or rank == 5 or rank == 6 then
            labelText = labelText .. "\n" .. "[" .. rank .. "] -> " .. corde .. ": " .. data.runner.zombie.name .. " odds: " .. data.runner.zombie.rating .. "/1"
        end
    end
    
    if self.runResultLabel then 
        self.runResultLabel:setName(labelText)
        return
    end

    self.runResultLabel = ISLabel:new(self.width * 0.20, self.height * 0.60, 15, labelText, 0, 1, 0, 1, UIFont.Small, true)
    self.runResultLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.runResultLabel:setVisible(true)
    self.runResultLabel:initialise()
    self.topBar:addChild(self.runResultLabel)
end

function bettingUI:declareWinner(winnerId, winner)
    local winnerText = string.format("%s HAS WON!", winner.name)
    self.winnerLabel = ISLabel:new(self.width * 0.20, self.height * 0.22, 20, winnerText, 1, 1, 0, 1, UIFont.Large, true)
    self.winnerLabel:initialise()
    self.winnerLabel:instantiate()
    self:addChild(self.winnerLabel)

    if winnerId == tonumber(self.betInput:getText()) then
        local balance = loadAtmBalance()
        newBalance = loadAtmBalance() + tonumber(self.amountInput:getText()) * winner.rating
        saveAtmBalance(newBalance)
        self.titleLabel:setName("Account Balance $" .. tostring(newBalance))

        local globalVolume = getCore():getOptionSoundVolume() / 10
        getSoundManager():PlayWorldSound("sold", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    end
end

function bettingUI:delayFunction(func, seconds)
    local startTime = getGameTime():getWorldAgeHours() * 3600
    local targetTime = startTime + seconds

    local function timer()
        local elapsed = getGameTime():getWorldAgeHours() * 3600
        if elapsed >= targetTime then
            Events.OnTick.Remove(timer)
            if not self.isClosing then
                func()
            end
        end
    end

    Events.OnTick.Add(timer)
end

function bettingUI:onYesButton(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxActiveRequest = 1

    local playerBalance = loadAtmBalance()
    local newBalance = playerBalance - (PZLinuxOnItemRequestCount * betGame[button.id].price)
    saveAtmBalance(newBalance)
    self.titleLabel:setName("Bank balance: $"  .. tostring(loadAtmBalance()))

    if type(modData.PZLinuxOnItemRequest) ~= "table" then
        modData.PZLinuxOnItemRequest = {}
    end

    if type(modData.PZLinuxOnItemRequestCount) ~= "table" then
        modData.PZLinuxOnItemRequestCount = {}
    end

    while #modData.PZLinuxOnItemRequest ~= #modData.PZLinuxOnItemRequestCount do
        if #modData.PZLinuxOnItemRequest > #modData.PZLinuxOnItemRequestCount then
            table.remove(modData.PZLinuxOnItemRequest, 1)
        elseif #modData.PZLinuxOnItemRequest < #modData.PZLinuxOnItemRequestCount then
            table.remove(modData.PZLinuxOnItemRequestCount, 1)
        end
    end

    table.insert(modData.PZLinuxOnItemRequest, PZLinuxOnItemRequest)
    table.insert(modData.PZLinuxOnItemRequestCount, PZLinuxOnItemRequestCount)
    
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 9
end

-- LOGOUT
function bettingUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function bettingUI:onMinimizeBack(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 9
end

-- CLOSE
function bettingUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function bettingUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function bettingUI:onSFXOn(button)
    local modData = getPlayer():getModData()
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

function bettingUI:onSFXOff(button)
    local modData = getPlayer():getModData()
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

function bettingMenu_ShowUI(player)
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

    local ui = bettingUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()

    return ui
end