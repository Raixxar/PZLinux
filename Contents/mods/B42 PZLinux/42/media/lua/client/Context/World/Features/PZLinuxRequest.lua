-- Contracts UI - by Raixxar 
-- Updated : 25/02/25

requestUI = ISPanel:derive("requestUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0
local PZLinuxOnItemRequest = {}
local PZLinuxOnItemRequestName = ""
local ZLinuxOnItemRequestPriceDelta = 1
local PZLinuxOnItemRequestCount = 0

local requests = {
    [1] = { baseName = "Canned food", price = 50 },
    [2] = { baseName = "Meat", price = 80 },
    [3] = { baseName = "Fish", price = 1200 },
    [4] = { baseName = "Fruits", price = 60 },
    [5] = { baseName = "Vegetables", price = 60 },
    [6] = { baseName = "Pickled food", price = 70 },
    [7] = { baseName = "Drink", price = 30 },
    [8] = { baseName = "Book", price = 150 },
    [9] = { baseName = "Car", price = 15000 },
    [10] = { baseName = "Repairing", price = 40 },
    [11] = { baseName = "Materials", price = 100 },
    [12] = { baseName = "Paint bucket", price = 500 },
    [13] = { baseName = "Electronics", price = 80 },
    [14] = { baseName = "Seeds", price = 20 },
}

local contracts = {}
for i = 1, #requests do
    local getHourTimePriceValue = math.ceil(getGameTime():getWorldAgeHours()/2190 + 1)   
    itemName = requests[i].baseName
    itemPrice = math.ceil(ZombRand(requests[i].price, requests[i].price * getHourTimePriceValue))
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
   
    local itemsPerPage = 8
    local currentPage = self.currentPage or 1
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #contracts)

    local y = 0.20
    self.contractButtons = {}
    for i = startIndex, endIndex do
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

    self.prevButton = ISButton:new(self.width * 0.454, self.height * 0.68, self.width * 0.030, self.height * 0.025, "<", self, function()
        if currentPage == 1 then currentPage = 2 end
        self.currentPage = currentPage - 1
        self:refreshContracts()
    end)
    self.prevButton:initialise()
    self.topBar:addChild(self.prevButton)

    if endIndex < #contracts then
        self.nextButton = ISButton:new(self.width * 0.484, self.height * 0.68, self.width * 0.030, self.height * 0.025, ">", self, function()
            self.currentPage = currentPage + 1
            self:refreshContracts()
        end)
        self.nextButton:initialise()
        self.topBar:addChild(self.nextButton)
    end
end

function requestUI:refreshContracts()
    self.prevButton:setVisible(false)
    self.nextButton:setVisible(false)
    for _, button in ipairs(self.contractButtons) do
        button:setVisible(false)
    end
    self.contractButtons = {}

    local y = 0.20
    local itemsPerPage = 8
    local currentPage = self.currentPage or 1
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #contracts)

    for i = startIndex, endIndex do
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

    self.prevButton = ISButton:new(self.width * 0.454, self.height * 0.68, self.width * 0.030, self.height * 0.025, "<", self, function()
        if currentPage == 1 then currentPage = 2 end
        self.currentPage = currentPage - 1
        self:refreshContracts()
    end)
    self.prevButton:initialise()
    self.topBar:addChild(self.prevButton)

    if endIndex < #contracts then
        self.nextButton = ISButton:new(self.width * 0.484, self.height * 0.68, self.width * 0.030, self.height * 0.025, ">", self, function()
            self.currentPage = currentPage + 1
            self:refreshContracts()
        end)
        self.nextButton:initialise()
        self.topBar:addChild(self.nextButton)
    end
end

function requestUI:onSelectContract(button)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)
    self.prevButton:setVisible(false)
    self.nextButton:setVisible(false)
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

        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        
        while index <= totalLetters do
            if self.isClosing then return end
            
            local soundName = "typingKeyboard" .. ZombRand(1, 10)
            getSoundManager():PlayWorldSound(soundName, false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            
            message = message .. string.sub(text, index, index)
            index = index + 1
            label:setName(message)
            
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(1, 10) / (getPlayer():getPerkLevel(Perks.Electricity) + 1)
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end
        
        getSoundManager():PlayWorldSound("typingKeyboardEnd", false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        if callback then callback() end
    end
    
    self.terminalCoroutine = coroutine.create(function()
        local modData = getPlayer():getModData()
        local message = ""

        local sleepSFX = 1
        if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

        message = "You are alone in this IRC channel."
        self.loadingMessage:setName(message)

        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        local globalVolume = getCore():getOptionSoundVolume() / 10
        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        local sellerName = generateUsername()
        local playerName = generatePseudo(string.lower(getPlayer():getUsername()))

        message = "New user " .. sellerName .. " has joined the channel."
        self.loadingMessage:setName(message)
        sellerName = "<" .. sellerName .. "> "

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end


        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        message = sellerName .. "Are you looking for " .. contracts[contract].name .. " ?"
        self.loadingMessage:setName(message)
        
        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        typeText(self.typingMessage, "Yes, do you have any for sale ?", function()
            message = message .. "\n" .. playerName .. "Yes, do you have any for sale ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)
        
        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        local quests = {}
        local locations = {}
        if contract == 1 then -- Canned food
            quests = {
                [1] = { baseName = "Base.TinnedBeans", weight = 1 },
                [2] = { baseName = "Base.CannedCarrots2", weight = 1 },
                [3] = { baseName = "Base.CannedChili", weight = 1 },
                [4] = { baseName = "Base.CannedCorn", weight = 1 },
                [5] = { baseName = "Base.CannedCornedBeef", weight = 1 },
                [6] = { baseName = "Base.CannedMushroomSoup", weight = 1 },
                [7] = { baseName = "Base.CannedPeaches", weight = 1 },
                [8] = { baseName = "Base.CannedPeas", weight = 1 },
                [9] = { baseName = "Base.CannedPineapple", weight = 1 },
                [10] = { baseName = "Base.CannedPotato2", weight = 1 },
                [11] = { baseName = "Base.CannedSardines", weight = 1 },
                [12] = { baseName = "Base.TinnedSoup", weight = 1 },
                [13] = { baseName = "Base.CannedBolognese", weight = 1 },
                [14] = { baseName = "Base.CannedTomato2", weight = 1 },
                [15] = { baseName = "Base.TunaTin", weight = 0.3 },
                [16] = { baseName = "Base.Dogfood", weight = 1 },
                [17] = { baseName = "Base.CannedMilk", weight = 1 },
                [18] = { baseName = "Base.CannedFruitBeverage", weight = 1 }
            }
        end

        if contract == 2 then -- Protein
            quests = {
                [1] = { baseName = "Base.Baloney", weight = 0.5 },
                [2] = { baseName = "Base.Chicken", weight = 0.3 },
                [3] = { baseName = "Base.Ham", weight = 0.1 },
                [4] = { baseName = "Base.MincedMeat", weight = 0.3 },
                [5] = { baseName = "Base.MuttonChop", weight = 0.3 },
                [6] = { baseName = "Base.PorkChop", weight = 0.3 },
                [7] = { baseName = "Base.Salami", weight = 0.1 },
                [8] = { baseName = "Base.Sausage", weight = 0.1 },
                [9] = { baseName = "Base.Steak", weight = 0.3 }
            }
        end

        if contract == 3 then -- Seafood
            quests = {
                [1] = { baseName = "Base.Paddlefish", weight = 10 },
                [2] = { baseName = "Base.FlatheadCatfish", weight = 10 },
                [3] = { baseName = "Base.ChannelCatfish", weight = 10 },
                [4] = { baseName = "Base.BlueCatfish", weight = 10 },
                [5] = { baseName = "Base.BlackCrappie", weight = 10 },
                [6] = { baseName = "Base.Bluegill", weight = 10 },
                [7] = { baseName = "Base.Shrimp", weight = 10 },
                [8] = { baseName = "Base.FreshwaterDrum", weight = 10 },
                [9] = { baseName = "Base.Muskellunge", weight = 10 },
                [10] = { baseName = "Base.SmallmouthBass", weight = 10 },
                [11] = { baseName = "Base.StripedBass", weight = 10 },
                [12] = { baseName = "Base.WhiteBass", weight = 10 },
                [13] = { baseName = "Base.YellowPerch", weight = 10 },
            }
        end

        if contract == 4 then -- fruits
            quests = {
               [1] = { baseName = "Base.Apple", weight = 0.3 },
               [2] = { baseName = "Base.Banana", weight = 0.2 },
               [3] = { baseName = "Base.BerryBlack", weight = 0.1 },
               [4] = { baseName = "Base.BerryBlue", weight = 0.1 },
               [5] = { baseName = "Base.Cherry", weight = 0.3 },
               [6] = { baseName = "Base.Grapes", weight = 0.2 },
               [7] = { baseName = "Base.Lemon", weight = 0.2 },
               [8] = { baseName = "Base.Lime", weight = 0.2 },
               [9] = { baseName = "Base.Mango", weight = 0.3 },
               [10] = { baseName = "Base.Orange", weight = 0.2 },
               [11] = { baseName = "Base.Peach", weight = 0.2 },
               [12] = { baseName = "Base.Pear", weight = 0.2 },
               [13] = { baseName = "Base.Pineapple", weight = 0.3 },
               [14] = { baseName = "Base.Watermelon", weight = 3 },
            }
        end
        
        if contract == 5 then -- Vegetables
            quests = {
                [1] = { baseName = "Base.Avocado", weight = 0.3 },
                [2] = { baseName = "Base.BellPepper", weight = 0.3 },
                [3] = { baseName = "Base.Blackbeans", weight = 0.1 },
                [4] = { baseName = "Base.Broccoli", weight = 0.2 },
                [5] = { baseName = "Base.Carrots", weight = 0.3 },
                [6] = { baseName = "Base.Corn", weight = 0.3 },
                [7] = { baseName = "Base.Daikon", weight = 0.2 },
                [8] = { baseName = "Base.Edamame", weight = 0.1 },
                [9] = { baseName = "Base.Eggplant", weight = 0.3 },
                [10] = { baseName = "Base.PepperHabanero", weight = 0.1 },
                [11] = { baseName = "Base.PepperJalapeno", weight = 0.1 },
                [12] = { baseName = "Base.Leek", weight = 0.2 },
                [13] = { baseName = "Base.Lettuce", weight = 0.5 },
                [14] = { baseName = "Base.Onion", weight = 0.2 },
                [15] = { baseName = "Base.Pickles", weight = 0.1 },
                [16] = { baseName = "Base.Pumpkin", weight = 1 },
                [17] = { baseName = "Base.Zucchini", weight = 0.3 },
            }
        end

        if contract == 6 then  -- Pickled food
            quests = {
                [1] = { baseName = "Base.CannedBellPepper", weight = 1 },
                [2] = { baseName = "Base.CannedBroccoli", weight = 1 },
                [3] = { baseName = "Base.CannedCabbage", weight = 1 },
                [4] = { baseName = "Base.CannedCarrots", weight = 1 },
                [5] = { baseName = "Base.CannedEggplant", weight = 1 },
                [6] = { baseName = "Base.CannedLeek", weight = 1 },
                [7] = { baseName = "Base.CannedPotato", weight = 1 },
                [8] = { baseName = "Base.CannedRedRadish", weight = 1 },
                [9] = { baseName = "Base.CannedTomato", weight = 1 },
            }
        end

        if contract == 7 then  -- Drink
            quests = {
                [1] = { baseName = "Base.JuiceBox", weight = 1 },
                [2] = { baseName = "Base.Milk", weight = 1 },
                [3] = { baseName = "Base.PopBottle", weight = 1 },
                [4] = { baseName = "Base.Pop2", weight = 1 },
                [5] = { baseName = "Base.Pop", weight = 1 },
                [6] = { baseName = "Base.Pop3", weight = 1 },
            }
        end

        if contract == 8 then  -- Book
            quests = {
                [1] = { baseName = "Base.Book", weight = 1 },
                [2] = { baseName = "Base.Magazine", weight = 0.5 },
            }
        end

        if contract == 9 then  -- Car
            quests = {
                [1] = { baseName = "Base.CarStationWagon", weight = 10, delta = 1.2 },
                [2] = { baseName = "Base.CarStationWagon2", weight = 10, delta = 1.2 },
                [3] = { baseName = "Base.SportsCar", weight = 10, delta = 4 },
                [4] = { baseName = "Base.PickUpTruck", weight = 10, delta = 2 },
                [5] = { baseName = "Base.PickUpTruckLightsFire", weight = 10, delta = 2.5 },
                [6] = { baseName = "Base.PickUpTruckMccoy", weight = 10, delta = 2 },
                [7] = { baseName = "Base.SmallCar", weight = 10, delta = 0.5 },
                [8] = { baseName = "Base.CarNormal", weight = 10, delta = 1 },
                [9] = { baseName = "Base.CarLightsPolice", weight = 10, delta = 2 },
                [10] = { baseName = "Base.CarTaxi", weight = 10, delta = 1 },
                [11] = { baseName = "Base.CarTaxi2", weight = 10, delta = 1 },
                [12] = { baseName = "Base.ModernCar02", weight = 10, delta = 1.5 },
                [13] = { baseName = "Base.StepVan", weight = 10, delta = 1.8 },
                [14] = { baseName = "Base.StepVanMail", weight = 10, delta = 1.8 },
                [15] = { baseName = "Base.StepVan_Heralds", weight = 10, delta = 1.8 },
                [16] = { baseName = "Base.StepVan_Scarlet", weight = 10, delta = 1.8 },
                [17] = { baseName = "Base.ModernCar", weight = 10, delta = 1.5 },
                [18] = { baseName = "Base.OffRoad", weight = 10, delta = 3 },
                [19] = { baseName = "Base.SUV", weight = 10, delta = 3 },
                [20] = { baseName = "Base.Van", weight = 10, delta = 2 },
                [21] = { baseName = "Base.VanAmbulance", weight = 10, delta = 2.5 },
                [22] = { baseName = "Base.VanRadio", weight = 10, delta = 2 },
                [23] = { baseName = "Base.VanSeats", weight = 10, delta = 2 },
                [24] = { baseName = "Base.VanRadio_3N", weight = 10, delta = 2 },
                [25] = { baseName = "Base.VanSpiffo", weight = 10, delta = 2 },
                [26] = { baseName = "Base.Van_KnoxDisti", weight = 10, delta = 2 },
                [27] = { baseName = "Base.Van_LectroMax", weight = 10, delta = 2 },
                [28] = { baseName = "Base.Van_MassGenFac", weight = 10, delta = 2 },
                [29] = { baseName = "Base.Van_Transit", weight = 10, delta = 2 },
                [30] = { baseName = "Base.SmallCar02", weight = 10, delta = 0.5 },
                [31] = { baseName = "Base.CarLuxury", weight = 10, delta = 4 }
            }

            locations = {
                [1] = { name = "Storage Units of Riverside", x = 5550, y = 6080, z = 0 },
                [2] = { name = "Storage Units of Brandenburg", x = 1995, y = 6519, z = 0 },
                [3] = { name = "Storage Units of Irvington", x = 2442, y = 13917, z = 0 },
                [4] = { name = "Storage Units of Muldraugh: South", x = 10771, y = 10323, z = 0 },
                [5] = { name = "Storage Units of Muldraugh: North", x = 10696, y = 9814, z = 0 },
                [6] = { name = "Storage Units of Muldraugh: North", x = 10696, y = 9814, z = 0 },
                [7] = { name = "Storage Units of West Point", x = 12154, y = 6996, z = 0 },
                [8] = { name = "Storage Units of Valley Station", x = 12963, y = 4851, z = 0 },           
                [9] = { name = "Storage Units of Louisville: South", x = 12712, y = 2010, z = 0 },
                [10] = { name = "Storage Units of Louisville: West", x = 12205, y = 1684, z = 0 },
            }           
        end

        if contract == 10 then  -- Repairing
            quests = {
                [1] = { baseName = "Base.Scotchtape", weight = 0.3 },
                [2] = { baseName = "Base.DuctTape", weight = 0.5 },
                [3] = { baseName = "Base.Glue", weight = 0.5 },
                [4] = { baseName = "Base.Woodglue", weight = 1 },
            }
        end

        if contract == 11 then  -- Materials
            quests = {
                [1] = { baseName = "Base.Aluminum", weight = 0.1 },
                [2] = { baseName = "Base.ConcretePowder", weight = 5 },
                [3] = { baseName = "Base.PlasterPowder", weight = 5 },
                [4] = { baseName = "Base.BarbedWire", weight = 1 },
                [5] = { baseName = "Base.NailsBox", weight = 0.3 },
                [6] = { baseName = "Base.PaperclipBox", weight = 0.3 },
                [7] = { baseName = "Base.Screws", weight = 0.3 },
                [8] = { baseName = "Base.Sparklers", weight = 0.2 },
                [9] = { baseName = "Base.Charcoal", weight = 8 },
                [10] = { baseName = "Base.Dirtbag", weight = 2 },
                [11] = { baseName = "Base.Hinge", weight = 0.3 },
                [12] = { baseName = "Base.Doorknob", weight = 0.5 },
                [13] = { baseName = "Base.Gravelbag", weight = 2 },
                [14] = { baseName = "Base.GunPowder", weight = 0.1 },
                [15] = { baseName = "Base.SheetMetal", weight = 1.5 },
                [16] = { baseName = "Base.Nails", weight = 0.01 },
                [17] = { baseName = "Base.Plank", weight = 3 },
                [18] = { baseName = "Base.PropaneTank", weight = 10 },
                [19] = { baseName = "Base.Rope", weight = 0.8 },
                [20] = { baseName = "Base.SmallSheetMetal", weight = 0.4 },
                [21] = { baseName = "Base.Staples", weight = 0.1 },
                [22] = { baseName = "Base.Stone", weight = 1 },
                [23] = { baseName = "Base.Tarp", weight = 1 },
                [24] = { baseName = "Base.Thread", weight = 0.1 },
                [25] = { baseName = "Base.Twine", weight = 0.1 },
                [26] = { baseName = "Base.WeldingRods", weight = 1.5 },
                [27] = { baseName = "Base.Wire", weight = 0.2 },
                [28] = { baseName = "Base.Yarn", weight = 0.1 },
                [29] = { baseName = "Base.DenimStrips", weight = 0.05 },
                [30] = { baseName = "Base.LeatherStrips", weight = 0.05 },
                [31] = { baseName = "Base.RippedSheets", weight = 0.05 },
            }
        end

        if contract == 12 then  -- Paint
            quests = {
                [1] = { baseName = "Base.PaintBlack", weight = 5 },
                [2] = { baseName = "Base.PaintBlue", weight = 5 },
                [3] = { baseName = "Base.PaintBrown", weight = 5 },
                [4] = { baseName = "Base.PaintCyan", weight = 5 },
                [5] = { baseName = "Base.PaintGreen", weight = 5 },
                [6] = { baseName = "Base.PaintGrey", weight = 5 },
                [7] = { baseName = "Base.PaintLightBlue", weight = 5 },
                [8] = { baseName = "Base.PaintLightBrown", weight = 5 },
                [9] = { baseName = "Base.PaintOrange", weight = 5 },
                [10] = { baseName = "Base.PaintPink", weight = 5 },
                [11] = { baseName = "Base.PaintPurple", weight = 5 },
                [12] = { baseName = "Base.PaintRed", weight = 5 },
                [13] = { baseName = "Base.PaintTurquoise", weight = 5 },
                [14] = { baseName = "Base.PaintWhite", weight = 5 },
                [15] = { baseName = "Base.PaintYellow", weight = 5 },
                [16] = { baseName = "Base.PaintbucketEmpty", weight = 5 },
            }
        end

        if contract == 13 then  -- Electronics
            quests = {
                [1] = { baseName = "Base.Battery", weight = 0.1 },
                [2] = { baseName = "Base.Amplifier", weight = 0.3 },
                [3] = { baseName = "Base.TimerCrafted", weight = 0.5 },
                [4] = { baseName = "Base.TriggerCrafted", weight = 0.2 },
                [5] = { baseName = "Base.ElectricWire", weight = 0.1 },
                [6] = { baseName = "Base.ElectronicsScrap", weight = 0.1 },
                [7] = { baseName = "Base.MotionSensor", weight = 0.3 },
                [8] = { baseName = "Base.RadioReceiver", weight = 0.1 },
                [9] = { baseName = "Base.RadioTransmitter", weight = 0.1 },
                [10] = { baseName = "Base.Receiver", weight = 0.1 },
                [11] = { baseName = "Base.ScannerModule", weight = 0.1 },
                [12] = { baseName = "Base.RemoteCraftedV1", weight = 0.4 },
                [13] = { baseName = "Base.RemoteCraftedV2", weight = 0.4 },
                [14] = { baseName = "Base.RemoteCraftedV3", weight = 0.4 },
                [15] = { baseName = "Base.LightBulb", weight = 0.3 },
                [16] = { baseName = "Base.LightBulbRed", weight = 0.3 },
                [17] = { baseName = "Base.LightBulbGreen", weight = 0.3 },
                [18] = { baseName = "Base.LightBulbBlue", weight = 0.3 },
                [19] = { baseName = "Base.LightBulbYellow", weight = 0.3 },
                [20] = { baseName = "Base.LightBulbCyan", weight = 0.3 },
                [21] = { baseName = "Base.LightBulbMagenta", weight = 0.3 },
                [22] = { baseName = "Base.LightBulbOrange", weight = 0.3 },
                [23] = { baseName = "Base.LightBulbPurple", weight = 0.3 },
                [24] = { baseName = "Base.LightBulbPink", weight = 0.3 },
            }
        end

        if contract == 14 then  -- Seeds
            quests = {
                [1] = { baseName = "Base.RoseBagSeed", weight = 0.1 },
                [2] = { baseName = "Base.PoppyBagSeed", weight = 0.1 },
                [3] = { baseName = "Base.LavenderBagSeed", weight = 0.1 },
                [4] = { baseName = "Base.BarleyBagSeed", weight = 0.1 },
                [5] = { baseName = "Base.RyeBagSeed", weight = 0.1 },
                [6] = { baseName = "Base.SugarBeetBagSeed", weight = 0.1 },
                [7] = { baseName = "Base.WheatBagSeed", weight = 0.1 },
                [8] = { baseName = "Base.ChamomileBagSeed", weight = 0.1 },
                [9] = { baseName = "Base.MarigoldBagSeed", weight = 0.1 },
                [10] = { baseName = "Base.LettuceBagSeed", weight = 0.1 },
                [11] = { baseName = "Base.BellPepperBagSeed", weight = 0.1 },
                [12] = { baseName = "Base.CauliflowerBagSeed", weight = 0.1 },
                [13] = { baseName = "Base.CucumberBagSeed", weight = 0.1 },
                [14] = { baseName = "Base.LeekBagSeed", weight = 0.1 },
                [15] = { baseName = "Base.LemonGrassBagSeed", weight = 0.1 },
                [16] = { baseName = "Base.ZucchiniBagSeed", weight = 0.1 },
                [17] = { baseName = "Base.WatermelonBagSeed", weight = 0.1 },
                [18] = { baseName = "Base.HabaneroBagSeed", weight = 0.1 },
                [19] = { baseName = "Base.JalapenoBagSeed", weight = 0.1 },
                [20] = { baseName = "Base.BlackSageBagSeed", weight = 0.1 },
                [21] = { baseName = "Base.BroadleafPlantainBagSeed", weight = 0.1 },
                [22] = { baseName = "Base.ComfreyBagSeed", weight = 0.1 },
                [23] = { baseName = "Base.CommonMallowBagSeed", weight = 0.1 },
                [24] = { baseName = "Base.HempBagSeed", weight = 0.1 },
                [25] = { baseName = "Base.HopsBagSeed", weight = 0.1 },
                [26] = { baseName = "Base.MintBagSeed", weight = 0.1 },
                [27] = { baseName = "Base.TurnipBagSeed", weight = 0.1 },
                [28] = { baseName = "Base.WildGarlicBagSeed", weight = 0.1 },
                [29] = { baseName = "Base.PumpkinBagSeed", weight = 0.1 },
            }
        end

        local randomQuest = ZombRand(1, #quests + 1)
        local quest = quests[randomQuest]
        local deltaWeight = 10
        local locationName = ""
        local weightPackage = 0
        local itemCount = 0
        local batch = { items = {} }

        while weightPackage <= 9.5 do
            local itemIdRand = ZombRand(1, #quests + 1)
            local quest = quests[itemIdRand]
            if quest then
                table.insert(batch.items, { name = quest.baseName })
                deltaWeight = quest.weight
                weightPackage = weightPackage + quest.weight
                itemCount = itemCount + 1
            end
        end

        PZLinuxOnItemRequestCount = itemCount
        table.insert(PZLinuxOnItemRequest, batch)

        if contract == 9 then
            local randomLocation = ZombRand(1, #locations + 1)
            local location = locations[randomLocation]
            if quest and location then
                PZLinuxOnItemRequestPriceDelta = quest.delta
                modData.PZLinuxRequestLocationX = location.x
                modData.PZLinuxRequestLocationY = location.y
                modData.PZLinuxRequestLocationZ = location.z
                locationName = location.name
            end
        end

        local produceName = ""
        local lastBatch = PZLinuxOnItemRequest[#PZLinuxOnItemRequest]
        for _, entry in ipairs(lastBatch.items) do
            local itemBaseName = entry.name
            local checkProduceName = getScriptManager():FindItem(itemBaseName)
            local produceNameValide = checkProduceName and checkProduceName:getDisplayName() and checkProduceName:getDisplayName():match("%S")
            if produceNameValide then
                produceName = produceName .. "\n" .. sellerName .. checkProduceName:getDisplayName()
            else    
                produceName = produceName .. "\n" .. sellerName .. contracts[contract].name
            end

            if contract == 9 then
                PZLinuxOnItemRequestName = entry.name
                local vehicle = getScriptManager():getVehicle(entry.name)
                if vehicle then
                    produceName = getText("IGUI_VehicleName" .. vehicle:getName())
                else
                    produceName = entry.name
                end
            end
        end

        if contract == 9 then 
            table.remove(PZLinuxOnItemRequest, #PZLinuxOnItemRequest)
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Yes, I can sell you ".. PZLinuxOnItemRequestCount .. " " .. produceName
            self.loadingMessage:setName(message)

            local playerObj = getPlayer()
            local inv = playerObj:getInventory()
            local note = inv:AddItem('Base.Note')
            note:setName("Car purchased")
            note:setCanBeWrite(true)
            note:addPage(1, produceName .. "\n" .. locationName)

        else
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Yes, I can sell you ".. PZLinuxOnItemRequestCount
            self.loadingMessage:setName(message)
        end

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if contract == 9 then
            if self.isClosing then return end
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "The car is at the " .. locationName
            self.loadingMessage:setName(message)
    
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end

        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "Deal ?"
        self.loadingMessage:setName(message)

        local requestPrice = math.ceil(contracts[contract].price - ((getPlayer():getPerkLevel(Perks.PlantScavenging) + 1) * contracts[contract].price / 100))
        requestPrice = math.ceil(requestPrice / 10)*10

        message = message .. "\n\nTOTAL: $" .. PZLinuxOnItemRequestCount * requestPrice * ZLinuxOnItemRequestPriceDelta
        self.loadingMessage:setName(message)

        local playerBalance = loadAtmBalance()
        local noButton = "No"
        if playerBalance < PZLinuxOnItemRequestCount * requestPrice * ZLinuxOnItemRequestPriceDelta then
            noButton = "Not enough money"
        else
            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.id = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
        end
        self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, noButton, self, self.onMinimizeBack)
        self.noButton:initialise()
        self.noButton:instantiate()
        self.topBar:addChild(self.noButton)
    end)
    
    self.updateCoroutineFunc = function()
        if self.terminalCoroutine and coroutine.status(self.terminalCoroutine) ~= "dead" then
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

    local playerBalance = loadAtmBalance()
    local newBalance = playerBalance - (PZLinuxOnItemRequestCount * contracts[button.id].price * ZLinuxOnItemRequestPriceDelta)
    saveAtmBalance(newBalance)
    self.titleLabel:setName("Bank balance: $"  .. tostring(loadAtmBalance()))

    if button.id == 9 then 
        contractsDrawOnMap(modData.PZLinuxRequestLocationX, modData.PZLinuxRequestLocationY, "* Car requested")
        modData.PZLinuxOnItemRequestCar = 1
        modData.PZLinuxOnItemRequestCarName = PZLinuxOnItemRequestName
        self.isClosing = true
        self:removeFromUIManager()
        requestMenu_ShowUI(player)
        return
    end

    if type(modData.PZLinuxOnItemRequest) ~= "table" then
        modData.PZLinuxOnItemRequest = {}
    end
    modData.PZLinuxOnItemRequest = PZLinuxOnItemRequest
    
    self.isClosing = true
    self:removeFromUIManager()
    modData.PZLinuxUIOpenMenu = 8
    HaloTextHelper.addGoodText(getPlayer(), "Item available in a mailbox");
end

-- LOGOUT
function requestUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function requestUI:onMinimizeBack(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 8
end

-- CLOSE
function requestUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function requestUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()

end

function requestUI:onSFXOn(button)
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

function requestUI:onSFXOff(button)
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

    return ui
end