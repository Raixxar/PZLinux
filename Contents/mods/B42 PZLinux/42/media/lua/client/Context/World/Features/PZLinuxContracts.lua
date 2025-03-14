-- Contracts UI - by Raixxar 
-- Updated : 25/02/25

contractsUI = ISPanel:derive("contractsUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0
local selectedContracts = {}
local locationQuestTown = ""
local questDetailName = ""

local companyCode = {
    { id = 1, code = "CCC" },
    { id = 2, code = "AC" },
    { id = 3, code = "WC" },
    { id = 4, code = "SSI" },
    { id = 5, code = "RRL" },
    { id = 6, code = "BBT" },
    { id = 7, code = "ZB" },
    { id = 8, code = "EE" },
    { id = 9, code = "GGG" },
    { id = 10, code = "CCO" },
    { id = 11, code = "ZTC" },
    { id = 12, code = "CPL" },
    { id = 13, code = "GF" },
    { id = 14, code = "PRC" },
    { id = 15, code = "HSC"},
    { id = 16, code = "WSS" },
    { id = 17, code = "THZ" },
    { id = 18, code = "ZOR" },
    { id = 19, code = "ZZ" },
    { id = 20, code = "IA" },
    { id = 21, code = "PPI" },
    { id = 22, code = "ATP" },
    { id = 23, code = "WNI" },
    { id = 24, code = "NTI" },
    { id = 25, code = "ZM" },
    { id = 26, code = "VV" },
    { id = 27, code = "FM" },
    { id = 28, code = "RGS" },
    { id = 29, code = "BB" },
    { id = 30, code = "RR" },
    { id = 31, code = "BL" }
}

local contracts = {}
for i = 1, 10 do
    local randomId = ZombRand(1, 32)
    local randomCityId = ZombRand(1,13)
    local cityName = ""
    if randomCityId == 1 then cityName = " - Irvington" end
    if randomCityId == 2 then cityName = " - Ekron" end
    if randomCityId == 3 then cityName = " - Brandenburg" end
    if randomCityId == 4 then cityName = " - Echo Creek" end
    if randomCityId == 5 then cityName = " - Riverside" end
    if randomCityId == 6 then cityName = " - Fallas Lake" end
    if randomCityId == 7 then cityName = " - Rosewood" end
    if randomCityId == 8 then cityName = " - March Ridge" end
    if randomCityId == 9 then cityName = " - Muldraugh" end
    if randomCityId == 10 then cityName = " - West Point" end
    if randomCityId == 11 then cityName = " - Valley Station" end
    if randomCityId == 12 then cityName = " - Louisville" end

    local difficulty = 0
    local reward = 20
    local questName = ""
    -- 1 reward * 1000, 2 reward * 2500, 3 reward * 5000, 4 reward * 10000, 5 reward * 20000
    if i == 1 then difficulty = 1; reward = 1000; questName = "Kill zombies"; cityName = "" end
    if i == 2 then difficulty = 3; reward = 5000; questName = "Retrieve the package." end
    if i == 3 then difficulty = 3; reward = 5000; questName = "Eliminate the target." end
    if i == 4 then difficulty = 1; reward = 1000; questName = "Collect zombie blood."; cityName = "" end
    if i == 5 then difficulty = 4; reward = 10000; questName = "Sent car parts."; cityName = "" end
    if i == 6 then difficulty = 4; reward = 10000; questName = "Capture a live zombie."; cityName = "" end
    if i == 7 then difficulty = 4; reward = 10000; questName = "Prepare the cargo." end
    if i == 8 then difficulty = 5; reward = 20000; questName = "Protect the building." end
    if i == 9 then difficulty = 2; reward = 2500; questName = "Sent medical equipment."; cityName = "" end
    if i == 10 then difficulty = 3; reward = 5000; questName = "Sent weapons."; cityName = "" end

    local getHourTime = math.ceil(getGameTime():getWorldAgeHours()/2190 + 1)
    local randomCode = "Execute a contract for " .. companyCode[randomId].code .. " - Difficulty: " .. difficulty .. "/5" .. cityName
    local dataName = "PZLinuxTrading" .. companyCode[randomId].code
    local companyData = ModData.getOrCreate(dataName)
    local priceHistory = companyData.dataName or {}
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex] or 1
    local PZReward = math.ceil((ZombRand(lastPrice, lastPrice * getHourTime) + reward)/10) * 10
    contracts[i] = { id = i, name = randomCode, code = companyCode[randomId].code, reward = PZReward, questName = questName, cityId = randomCityId }
end

local contractsCompanyCodes = {}
local contractsCompanyReward = {}
local contractsQuestName = {}
local contractsCityId = {}
for i, contract in ipairs(contracts) do
    contractsCompanyCodes[contract.id] = contract.code
    contractsCompanyReward[contract.id] = contract.reward
    contractsQuestName[contract.id] = contract.questName
    contractsCityId[contract.id] = contract.cityId
end

-- CONSTRUCTOR
function contractsUI:new(x, y, width, height, player)
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
function contractsUI:initialise()
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

    local modData = getPlayer():getModData()
    if modData.PZLinuxActiveContract == 1 then
        modData.PZLinuxOnZombieDead = modData.PZLinuxOnZombieDead or 0
        local logging = "\nZombie(s) killed during this contract: " .. modData.PZLinuxOnZombieDead
        self.activeContractMessage = ISLabel:new(self.width * 0.20, self.height * 0.30, self.height * 0.025, "Contract already in progress" .. logging, 0, 1, 0, 1, UIFont.Small, true)
        self.activeContractMessage:setVisible(true)
        self.activeContractMessage:initialise()
        self.topBar:addChild(self.activeContractMessage)

        self.cancelContractButton = ISButton:new(self.width * 0.20, self.height * 0.20, self.width * 0.57, self.height * 0.05, "Cancel the contract", self, self.onCancelContract)
        self.cancelContractButton:setVisible(true)
        self.cancelContractButton:initialise()
        self.topBar:addChild(self.cancelContractButton)
        return
    elseif modData.PZLinuxActiveContract == 10 then
        self:onContractComplete()
        return
    end

    local function shuffleTable(t)
        for i = #t, 2, -1 do
            local j = ZombRand(1, i + 1)
            t[i], t[j] = t[j], t[i]
        end
    end

    getHourTime = math.ceil(getGameTime():getWorldAgeHours())

    if getHourTime < 168 then
        getHourTime = 168
    end

    if (getHourTime - LAST_CONNECTION_TIME) >= 168 then
        shuffleTable(contracts)
        selectedContracts = {}
        local randCountContracts = ZombRand(1, 9)
        while #selectedContracts < randCountContracts do
            for _, contract in ipairs(contracts) do
                table.insert(selectedContracts, contract)
                if #selectedContracts >= randCountContracts then break end
            end
        end
        LAST_CONNECTION_TIME = getHourTime
    end
    
    local y = 0.20
    self.contractButtons = {}
    for i = 1, #selectedContracts do
        local contract = selectedContracts[i]
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

function contractsUI:onCancelContract(button)
    local modData = getPlayer():getModData()

    if modData.PZLinuxContractLocationX and modData.PZLinuxContractLocationX > 0 then
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY)
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX + 20, modData.PZLinuxContractLocationY)
    end

    local inv = getPlayer():getInventory()
    local note = inv:Remove('Note')

    local dataName = modData.PZLinuxContractCompanyUp
    local companyData = ModData.getOrCreate(dataName)
    local priceHistory = companyData.dataName or {}
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex]
    local newPrice = math.ceil(lastPrice - (lastPrice * ZombRand(1, 10) / 100))

    table.insert(companyData.dataName, newPrice)
    if #companyData.dataName > 48 then
        table.remove(companyData.dataName, 1)
    end

    self.isClosing = true
    self:removeFromUIManager()
    modData.PZLinuxUIOpenMenu = 7

    modData.PZLinuxContractLocationX = 0
    modData.PZLinuxContractLocationY = 0
    modData.PZLinuxContractLocationZ = 0
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxActiveContract = 0
    modData.PZLinuxContractNote = ""
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractInfoCount = 0
    modData.PZLinuxContractKillZombie = 0
    modData.PZLinuxContractPickUp = 0
    modData.PZLinuxContractManhunt = 0
    modData.PZLinuxContractBlood = 0
    modData.PZLinuxContractCar = 0
    modData.PZLinuxContractCapture = 0
    modData.PZLinuxContractCargo = 0
    modData.PZLinuxContractProtect = 0
    modData.PZLinuxContractMedical = 0
    modData.PZLinuxContractWeapon = 0
end

function contractsUI:onSelectContract(button)
    for _, button in ipairs(self.contractButtons) do
        button:setVisible(false)
    end

    local modData = getPlayer():getModData()
    if modData.PZLinuxActiveContract == nil then
        modData.PZLinuxActiveContract = 0
    end

    if modData.PZLinuxActiveContract == 1 then
        local playerObj = getPlayer()
        local globalVolume = getCore():getOptionSoundVolume() / 10
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        return
    end

    if modData.PZLinuxActiveContract == 10 then
        self:onContractComplete()
        return
    end
    table.remove(selectedContracts, button.contractPosition)
    self:onContractId(button.contractId)
end

function contractsUI:onContractComplete()
    local modData = getPlayer():getModData()
    local moneyEarned = modData.PZLinuxOnReward + modData.PZLinuxOnZombieDead * 5
    local balance = loadAtmBalance() + moneyEarned
    saveAtmBalance(balance)
    self.titleLabel:setName("Bank balance: $"  .. tostring(loadAtmBalance()))

    local logMessage = "You have been paid for your contract.\nTotal zombies killed: " .. modData.PZLinuxOnZombieDead .. "\nTotal money earned: $" .. moneyEarned
    self.completeContractMessage = ISLabel:new(self.width * 0.20, self.height * 0.30, self.height * 0.025, logMessage, 0, 1, 0, 1, UIFont.Small, true)
    self.completeContractMessage:setVisible(true)
    self.completeContractMessage:initialise()
    self.topBar:addChild(self.completeContractMessage)

    local dataName = modData.PZLinuxContractCompanyUp
    local companyData = ModData.getOrCreate(dataName)
    local priceHistory = companyData.dataName or {}
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex]
    local newPrice = math.ceil(lastPrice * ZombRand(1, 10) / 100 + lastPrice)

    table.insert(companyData.dataName, newPrice)
    if #companyData.dataName > 48 then
        table.remove(companyData.dataName, 1)
    end
    
    local playerObj = getPlayer()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("sold", false, playerObj:getSquare(), 0, 50, 1, true):setVolume(globalVolume)

    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local note = inv:Remove('Note')

    if modData.PZLinuxContractLocationX and modData.PZLinuxContractLocationX > 0 then
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY)
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX + 20, modData.PZLinuxContractLocationY)
    end
    
    LAST_CONNECTION_TIME = 0
    modData.PZLinuxContractLocationX = 0
    modData.PZLinuxContractLocationY = 0
    modData.PZLinuxContractLocationZ = 0
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxActiveContract = 0
    modData.PZLinuxContractNote = ""
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractInfoCount = 0
    modData.PZLinuxContractKillZombie = 0
    modData.PZLinuxContractPickUp = 0
    modData.PZLinuxContractManhunt = 0
    modData.PZLinuxContractBlood = 0
    modData.PZLinuxContractCar = 0
    modData.PZLinuxContractCapture = 0
    modData.PZLinuxContractCargo = 0
    modData.PZLinuxContractProtect = 0
    modData.PZLinuxContractMedical = 0
    modData.PZLinuxContractWeapon = 0
end

function contractsUI:onContractId(contract)
    self.minimizeBackButton:setVisible(true)
    self.minimizeButton:setVisible(false)

    local modData = getPlayer():getModData()
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractInfoCount = 0
    modData.PZLinuxContractLocationX = 0
    modData.PZLinuxContractLocationY = 0
    modData.PZLinuxContractLocation2 = 0
    locationQuestTown = "All around the world:"
    questDetailName = ""

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
            
            local letterDelay = elapsed + ZombRand(1, 10) / (getPlayer():getPerkLevel(Perks.Electricity) + 1)
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end
        
        getSoundManager():PlayWorldSound("typingKeyboardEnd", false, player:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        if callback then callback() end
    end
    
    if contract == 1 then
        self.terminalCoroutine = coroutine.create(function()
            local ZtoKill = tostring(ZombRand(1, 6) * 10)
            local modData = getPlayer():getModData()
            modData.PZLinuxOnZombieToKill = ZtoKill

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""
            
            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for a mercenary to clean the streets of our city."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "How many zombies do you need to kill ?", function()
                message = message .. "\n" .. playerName .. "How many zombies do you need to kill ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. modData.PZLinuxOnZombieToKill
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end
    
    if contract == 2 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()
            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end
            print(contractsCityId[contract])

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for a courier to retrieve a package."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "Where is the package exactly ?", function()
                message = message .. "\n" .. playerName .. "Where is the package exactly ?"
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
            if contractsCityId[contract] == 1 then
                quests = {
                    [1] = { description = "In a house of Irvington, in a gray cabinet.", x = 2650, y = 13407, z = 0, city = "Irvington" },
                    [2] = { description = "At the Liquor Store of Irvington, in a green crate.", x = 2542, y = 14468, z = 0, city = "Irvington" },
                    [3] = { description = "At the Gun Club of Irvington, on a metal shelf.", x = 1855, y = 14163, z = 0, city = "Irvington" },
                    [4] = { description = "At the Public Pool of Irvington, in a blue locker.", x = 1883, y = 14461, z = 0, city = "Irvington" },
                    [5] = { description = "At the Sport Store of Irvington, on a metal shelf.", x = 1862, y = 14853, z = 0, city = "Irvington" },
                    [6] = { description = "At the Farming Supply Store of Irvington, in a box.", x = 2466, y = 14317, z = 0, city = "Irvington" },
                    [7] = { description = "At the School of Irvington, in a library.", x = 2238, y = 14359, z = 0, city = "Irvington" },
                }
            end

            if contractsCityId[contract] == 2 then
                quests = {
                    [1] = { description = "In the Metal Workshop of Ekron, in the trash outside.", x = 622, y = 9854, z = 0, city = "Ekron" },
                    [2] = { description = "In the Book Store of Ekron, in a library.", x = 451, y = 9794, z = 0, city = "Ekron" },
                    [3] = { description = "In the Broken Train of Ekron, in a box.", x = 550, y = 9861, z = 0, city = "Ekron" },
                    [4] = { description = "In the Gas Station of Ekron, in a small trash outside.", x = 675, y = 9921, z = 0, city = "Ekron" },
                    [5] = { description = "In the Church of Ekron, on the piano upstairs.", x = 445, y = 9914, z = 1, city = "Ekron" },
                }
            end

            if contractsCityId[contract] == 3 then
                quests = {
                    [1] = { description = "In a house of Brandenburg, in the fridge.", x = 2471, y = 6390, z = 0, city = "Brandenburg" },
                    [2] = { description = "At the Police Station of Brandenburg, in the bathroom.", x = 2037 , y = 5975, z = 0, city = "Brandenburg" },
                    [3] = { description = "At the Dentist of Brandenburg, in a gray shelf.", x = 2077, y = 5912, z = 0, city = "Brandenburg" },
                    [4] = { description = "At the Community Center of Brandenburg, in the yellow locker.", x = 1858, y = 5944, z = 0, city = "Brandenburg" },
                    [5] = { description = "At the Fire Department of Brandenburg, in a tool cart.", x = 2069, y = 6288, z = 0, city = "Brandenburg" },
                    [6] = { description = "At the Destroyed Pile-O-Crepe of Brandenburg, on the table inside.", x = 2137, y = 6427, z = 0, city = "Brandenburg" },
                }
            end

            if contractsCityId[contract] == 4 then
                quests = {
                    [1] = { description = "In the Auto Repair Shop of Echo Creek, on the table inside.", x = 3676, y = 10893, z = 0, city = "Echo Creek" },
                    [2] = { description = "In the Church of Echo Creek, on the piano.", x = 3534, y = 11203, z = 0, city = "Echo Creek" },
                    [3] = { description = "In the Diner of Echo Creek, in the freezer.", x = 3571, y = 10907, z = 0, city = "Echo Creek" },
                }
            end

            if contractsCityId[contract] == 5 then
                quests = {
                    [1] = { description = "In a house, in the box.", x = 6575, y = 5533, z = 0, city = "Riverside" },
                }
            end

            if contractsCityId[contract] == 6 then
                quests = {
                    [1] = { description = "In the Police Station of Fallas Lake, in an archive cabinet.", x = 7251, y = 8378, z = 0, city = "Fallas Lake" },
                    [2] = { description = "In the Bar of Fallas Lake, in a jukebox.", x = 7248, y = 8521, z = 0, city = "Fallas Lake" },
                    [3] = { description = "In the Doctor's Office of Fallas Lake, in a fridge.", x = 7301, y = 8387, z = 0, city = "Fallas Lake" },
                    [4] = { description = "In the Burger Joint of Fallas Lake, under the sink.", x = 7234, y = 8208, z = 0, city = "Fallas Lake" },
                }
            end

            if contractsCityId[contract] == 7 then
                quests = {
                    [1] = { description = "In the police station of Rosewood, in a paper cabinet.", x = 8073, y = 11736, z = 0, city = "Rosewood" },
                    [2] = { description = "In the elementary school of Rosewood, in a school locker.", x = 8333, y = 11616, z = 0, city = "Rosewood" },
                    [3] = { description = "In the church of Rosewood, in a gray cabinet.", x = 8134, y = 11542, z = 0, city = "Rosewood" },
                    [4] = { description = "In the bar of Rosewood, under the sink in a cabinet.", x = 8022, y = 11423, z = 0, city = "Rosewood"  },
                    [5] = { description = "In the Knox Country Court of Justice of Rosewood, in a gray cabinet.", x = 8062, y = 11653, z = 0, city = "Rosewood" },
                    [6] = { description = "In the Prison of Rosewood, in a fridge upstairs.", x = 7695, y = 11901, z = 1, city = "Rosewood" },
                    [7] = { description = "In the Military Research Facility of Rosewood, in a morgue locker.", x = 5566, y = 12437, z = -17, city = "Rosewood" },
                    [8] = { description = "In the Military Research Facility of Rosewood, in an archive cabinet in the basement.", x = 5581, y = 12469, z = -17, city = "Rosewood" },
                }
            end

            if contractsCityId[contract] == 8 then
                quests = {
                    [1] = { description = "At the church of March Ridge, in a library.", x = 10322, y = 12800, z = 0, city = "March Ridge" },
                    [2] = { description = "In the insurance office of March Ridge, in a paper box.", x = 10070, y = 12778, z = 0, city = "March Ridge" },
                    [3] = { description = "At the community center of March Ridge, in the blue locker.", x = 10038, y = 12720, z = 0, city = "March Ridge" },
                    [4] = { description = "At the Knox military apartments of March Ridge, in the clothing washer.", x = 10064, y = 12623, z = 0, city = "March Ridge" },
                    [5] = { description = "In the bar of March Ridge, in the trash inside.", x = 10171, y = 12667, z = 0, city = "March Ridge" },
                    [6] = { description = "In the Bunker of March Ridge, in a trash.", x = 9962, y = 12611, z = -4, city = "March Ridge" },
                }
            end

            if contractsCityId[contract] == 9 then
                quests = {
                    [1] = { description = "At the Electrical Substation, in a gray cabinet.", x = 10380, y = 10061, z = 0, city = "Muldraugh" },
                    [2] = { description = "At Jays Chicken of Muldraugh, in a big trash outside.", x = 10627, y = 9564, z = 0, city = "Muldraugh" },
                    [3] = { description = "At the police station of Muldraugh, in a blue locker.", x = 10646, y = 10409, z = 0, city = "Muldraugh" },
                    [4] = { description = "In the Cortman medical of Muldraugh, in an antique piece of furniture.", x = 10880, y = 10024, z = 0, city = "Muldraugh" },
                    [5] = { description = "At the electronics store of Muldraugh, in a fridge.", x = 10617, y = 9872, z = 0, city = "Muldraugh" },
                    [6] = { description = "In the McCoy logging Corp of Muldraugh, in a yellow locker.", x = 10310, y = 9340, z = 0, city = "Muldraugh" },
                }
            end

            if contractsCityId[contract] == 10 then
                quests = {
                    [1] = { description = "At a house, in a fridge.", x = 11366, y = 7024, z = 0, city = "West Point" },
                    [2] = { description = "At the Mini Hotel of West Point, In the trash outside.", x = 12020, y = 6932, z = 0, city = "West Point" },
                    [3] = { description = "At the Thunder Gas of West Point, In a freezer.", x = 11825, y = 6868, z = 0, city = "West Point" },
                    [4] = { description = "At the Pizza Whirled of West Point, under the sink.", x = 11655, y = 7084, z = 0, city = "West Point" },
                    [5] = { description = "At the Church and Cemetery of West Point, On a tombstone.", x = 11070, y = 6703, z = 0, city = "West Point" },
                    [6] = { description = "At the Knox Bank of West Point, in a office.", x = 11899, y = 6909, z = 1, city = "West Point" },
                }
            end

            if contractsCityId[contract] == 11 then
                quests = {
                    [1] = { description = "In the Yummers of Valley Station, in a fridge.", x = 13581, y = 5744, z = 0, city = "Valley Station" },
                    [2] = { description = "In the Knox Bank of Valley Station, in a flower pot.", x = 13656, y = 5734, z = 0, city = "Valley Station" },
                    [3] = { description = "In the Elementary School of Valley Station, in a yellow locker.", x = 12861, y = 4863, z = 0, city = "Valley Station" },
                    [4] = { description = "In the Church of Valley Station, in boxs.", x = 14556, y = 4964, z = 0, city = "Valley Station" },
                }
            end

            if contractsCityId[contract] == 12 then
                quests = {
                    [1] = { description = "In a house, in a box.", x = 12264, y = 3355, z = 0, city = "Louisville" },
                    [2] = { description = "In the repurposed building of Louisville, in a box.", x = 12436, y = 1420, z = 0, city = "Louisville" },
                    [3] = { description = "At the fire department of Louisville, in a gray wardrobe.", x = 13729, y = 1784, z = 0, city = "Louisville" },
                    [4] = { description = "At the Knox bank of Louisville, on the last floor in a paper box.", x = 12653, y = 1636, z = 15, city = "Louisville" },
                    [5] = { description = "In the hospital of Louisville, in a trash.", x = 12923, y = 2060, z = 2, city = "Louisville" },
                    [6] = { description = "At the Scarlet Oak Distillery of Louisville, in a box.", x = 12021, y = 1934, z = 0, city = "Louisville" },
                    [7] = { description = "At the Knox bank of Louisville, on the third floor in a metal cabinet.", x = 12561, y = 1707, z = 2, city = "Louisville" },
                    [8] = { description = "At the Awl Work and Sew Play of Louisville, in the container somewhere below the register.", x = 12491, y = 1695, z = 0, city = "Louisville" },
                    [9] = { description = "In the Evergreen public school of Louisville, in a yellow locker.", x = 13581, y = 2782, z = 0, city = "Louisville" },
                    [10] = { description = "In the Leafhill heights elementary school of Louisville, in the yellow locker.", x = 12351, y = 3247, z = 1, city = "Louisville" },
                    [11] = { description = "In the Pizza Whirled of Louisville, in the fridge.", x = 13224, y = 2103, z = 0, city = "Louisville" },
                }
            end

            local randomQuest = 1
            if #quests > 1 then
                randomQuest = ZombRand(1, #quests + 1)
            end

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. sellerName .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
                locationQuestTown = quest.city .. ":\n* " .. quest.description
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "How do I give you the package ?", function()
                message = message .. "\n" .. playerName .. "How do I give you the package ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Put the package in a mailbox."
            
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 3 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "
            
            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for a hunter."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "Who is the target ?", function()
                message = message .. "\n" .. playerName .. "Who is the target ?"
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
            
            local firstNameId = ZombRand(1, 101)
            local lastNameId = ZombRand(1, 101)
            local names = {
                { id = 1, first = "Jame", last = "Smith" },
                { id = 2, first = "Mary", last = "Johnson" },
                { id = 3, first = "Robert", last = "Williams" },
                { id = 4, first = "Patricia", last = "Brown" },
                { id = 5, first = "John", last = "Jones" },
                { id = 6, first = "Jennifer", last = "Garcia" },
                { id = 7, first = "Michael", last = "Miller" },
                { id = 8, first = "Linda", last = "Davis" },
                { id = 9, first = "William", last = "Rodriguez" },
                { id = 10, first = "Elizabeth", last = "Martinez" },
                { id = 11, first = "David", last = "Hernandez" },
                { id = 12, first = "Barbara", last = "Lopez" },
                { id = 13, first = "Richard", last = "Gonzalez" },
                { id = 14, first = "Susan", last = "Wilson" },
                { id = 15, first = "Joseph", last = "Anderson" },
                { id = 16, first = "Jessica", last = "Thomas" },
                { id = 17, first = "Thomas", last = "Taylor" },
                { id = 18, first = "Sarah", last = "Moore" },
                { id = 19, first = "Charles", last = "Jackson" },
                { id = 20, first = "Karen", last = "Martin" },
                { id = 21, first = "Christopher", last = "Lee" },
                { id = 22, first = "Nancy", last = "Perez" },
                { id = 23, first = "Daniel", last = "Thompson" },
                { id = 24, first = "Betty", last = "White" },
                { id = 25, first = "Matthew", last = "Harris" },
                { id = 26, first = "Sandra", last = "Sanchez" },
                { id = 27, first = "Anthony", last = "Clark" },
                { id = 28, first = "Ashley", last = "Ramirez" },
                { id = 29, first = "Mark", last = "Lewis" },
                { id = 30, first = "Donna", last = "Robinson" },
                { id = 31, first = "Paul", last = "Walker" },
                { id = 32, first = "Emily", last = "Young" },
                { id = 33, first = "Steven", last = "Allen" },
                { id = 34, first = "Stephanie", last = "King" },
                { id = 35, first = "Andrew", last = "Wright" },
                { id = 36, first = "Melissa", last = "Scott" },
                { id = 37, first = "Kenneth", last = "Torres" },
                { id = 38, first = "Amy", last = "Nguyen" },
                { id = 39, first = "Joshua", last = "Hill" },
                { id = 40, first = "Angela", last = "Flores" },
                { id = 41, first = "Kevin", last = "Green" },
                { id = 42, first = "Sharon", last = "Adams" },
                { id = 43, first = "Brian", last = "Nelson" },
                { id = 44, first = "Laura", last = "Baker" },
                { id = 45, first = "George", last = "Hall" },
                { id = 46, first = "Kimberly", last = "Rivera" },
                { id = 47, first = "Edward", last = "Campbell" },
                { id = 48, first = "Deborah", last = "Mitchell" },
                { id = 49, first = "Jason", last = "Carter" },
                { id = 50, first = "Michelle", last = "Roberts" },
                { id = 51, first = "Jeffrey", last = "Gomez" },
                { id = 52, first = "Emily", last = "Phillips" },
                { id = 53, first = "Ryan", last = "Evans" },
                { id = 54, first = "Carol", last = "Turner" },
                { id = 55, first = "Jacob", last = "Diaz" },
                { id = 56, first = "Rebecca", last = "Parker" },
                { id = 57, first = "Gary", last = "Edwards" },
                { id = 58, first = "Cynthia", last = "Collins" },
                { id = 59, first = "Nicholas", last = "Stewart" },
                { id = 60, first = "Kathleen", last = "Morris" },
                { id = 61, first = "Eric", last = "Rogers" },
                { id = 62, first = "Shirley", last = "Reed" },
                { id = 63, first = "Stephen", last = "Cook" },
                { id = 64, first = "Anna", last = "Morgan" },
                { id = 65, first = "Jonathan", last = "Bell" },
                { id = 66, first = "Brenda", last = "Murphy" },
                { id = 67, first = "Larry", last = "Bailey" },
                { id = 68, first = "Emma", last = "Rivera" },
                { id = 69, first = "Justin", last = "Cooper" },
                { id = 70, first = "Pamela", last = "Richardson" },
                { id = 71, first = "Scott", last = "Cox" },
                { id = 72, first = "Nicole", last = "Howard" },
                { id = 73, first = "Brandon", last = "Ward" },
                { id = 74, first = "Megan", last = "Torres" },
                { id = 75, first = "Benjamin", last = "Peterson" },
                { id = 76, first = "Julie", last = "Gray" },
                { id = 77, first = "Samuel", last = "Ramirez" },
                { id = 78, first = "Hannah", last = "James" },
                { id = 79, first = "Gregory", last = "Watson" },
                { id = 80, first = "Victoria", last = "Brooks" },
                { id = 81, first = "Frank", last = "Kelly" },
                { id = 82, first = "Olivia", last = "Sanders" },
                { id = 83, first = "Alexander", last = "Price" },
                { id = 84, first = "Christina", last = "Bennett" },
                { id = 85, first = "Raymond", last = "Wood" },
                { id = 86, first = "Diane", last = "Barnes" },
                { id = 87, first = "Patrick", last = "Ross" },
                { id = 88, first = "Evelyn", last = "Henderson" },
                { id = 89, first = "Jack", last = "Coleman" },
                { id = 90, first = "Rachel", last = "Jenkins" },
                { id = 91, first = "Dennis", last = "Perry" },
                { id = 92, first = "Grace", last = "Powell" },
                { id = 93, first = "Jerry", last = "Long" },
                { id = 94, first = "Lauren", last = "Patterson" },
                { id = 95, first = "Tyler", last = "Hughes" },
                { id = 96, first = "Alice", last = "Flores" },
                { id = 97, first = "Aaron", last = "Washington" },
                { id = 98, first = "Jacqueline", last = "Butler" },
                { id = 99, first = "Jose", last = "Simmons" },
                { id = 100, first = "Katherine", last = "Foster" },
            }

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            local targetName = names[firstNameId].first .. " " .. names[lastNameId].last
            message = message .. "\n" .. sellerName .. "The target is " .. targetName
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "How do I find my target ?", function()
                message = message .. "\n" .. playerName .. "How do I find my target ?"
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
            if contractsCityId[contract] == 1 then
                quests = {
                    [1] = { description = "The target was supposed to go to the elementary school in Irvington.", x = 2227, y = 14328, z = 0, city = "Irvington" },
                }
            end

            if contractsCityId[contract] == 2 then
                quests = {
                    [1] = { description = "The target must be at the fire station in Ekron", x = 756, y = 9773, z = 0, city = "Ekron" },
                }
            end

            if contractsCityId[contract] == 3 then
                quests = {
                    [1] = { description = "The target was supposed to go to Brandenburg at P.S. Delilah.", x = 2037, y = 5684, z = 2, city = "Brandenburg" },
                    [2] = { description = "The target must be in Brandenburg Prison.", x = 1352, y = 5892, z = -1, city = "Brandenburg" },
                    [3] = { description = "The target was supposed to go to the Tool Store in Brandenburg.", x = 2094, y = 5885, z = 0, city = "Brandenburg" },
                }
            end

            if contractsCityId[contract] == 4 then
                quests = {
                    [1] = { description = "The target was supposed to return home to Echo Creek.", x = 3484, y = 10976, z = 0, city = "Echo Creek" },
                }
            end

            if contractsCityId[contract] == 5 then
                quests = {
                    [1] = { description = "The target was supposed to return home to Riverside.", x = 6310, y = 5333, z = 0, city = "Riverside" },
                }
            end

            if contractsCityId[contract] == 6 then
                quests = {
                    [1] = { description = "The target was last seen at Fallas Lake near the Hardware Store.", x = 7252, y = 8227, z = 0, city = "Fallas Lake" },
                    [2] = { description = "The target was last seen near Fallas Lake at Army Quarters.", x = 7436, y = 7951, z = 0, city = "Fallas Lake" },
                }
            end

            if contractsCityId[contract] == 7 then
                quests = {
                    [1] = { description = "The target was last seen at Rosewood police station.", x = 8061, y = 11725, z = 0, city = "Rosewood" },
                    [2] = { description = "The target was last seen at Rosewwod Auto Repair Shop.", x = 8156, y = 11321, z = 0, city = "Rosewood" },
                    [3] = { description = "The target was last seen at Rosewood Gas Station.", x = 8178, y = 11276, z = 0, city = "Rosewood" },
                }
            end

            if contractsCityId[contract] == 8 then
                quests = {
                    [1] = { description = "The target was supposed to return home to March Ridge.", x = 9945, y = 12831, z = 0, city = "March Ridge" },
                }
            end

            if contractsCityId[contract] == 9 then
                quests = {
                    [1] = { description = "The target was supposed to return home to Muldraugh.", x = 10784, y = 9921, z = 0, city = "Muldraugh" },
                }
            end

            if contractsCityId[contract] == 10 then
                quests = {
                    [1] = { description = "The target was supposed to return home to West Point.", x = 11654, y = 6748, z = 0, city = "West Point" },
                }
            end

            if contractsCityId[contract] == 11 then
                quests = {
                    [1] = { description = "The target was supposed to return home to Valley Station.", x = 13349, y = 5011, z = 0, city = "Valley Station" },
                }
            end

            if contractsCityId[contract] == 12 then
                quests = {
                    [1] = { description = "The target was supposed to return home to Louisville.", x = 12030, y = 3124, z = 0, city = "Louisville" },
                }
            end
            
            local randomQuest = 1
            if #quests > 1 then
                randomQuest = ZombRand(1, #quests + 1)
            end

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. sellerName .. quest.description
                modData.PZLinuxContractLocationX = tonumber(quest.x)
                modData.PZLinuxContractLocationY = tonumber(quest.y)
                modData.PZLinuxContractLocationZ = tonumber(quest.z)
                locationQuestTown = quest.city .. ":\n* " .. quest.description
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "How can I prove to you that he is dead ?", function()
                message = message .. "\n" .. playerName .. "How can I prove to you that he is dead ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Send us the corpse, or what remains of it, with a mailbox."
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 4 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for blood analyses of zombies."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 5 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for someone to find auto parts for us."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "Which auto parts do you need ?", function()
                message = message .. "\n" .. playerName .. "Which auto parts do you need ?"
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
            local quests = {
                [1] = { baseName = "Base.CarBattery3", name = "Battery: Resistant", delta = 1 },
                [2] = { baseName = "Base.CarBattery2", name = "Battery: Sport", delta = 0.9 },
                [3] = { baseName = "Base.CarBattery1", name = "Battery: Standard", delta = 0.8 },
                [4] = { baseName = "Base.ModernBrake3", name = "Performance brakes: Resistant", delta = 1 },
                [5] = { baseName = "Base.ModernBrake2", name = "Performance brakes: Sport", delta = 0.9 },
                [6] = { baseName = "Base.ModernBrake1", name = "Performance brakes: Standard", delta = 0.8 },
                [7] = { baseName = "Base.ModernCarMuffler3", name = "Performance silencers: Resistant", delta = 1 },
                [8] = { baseName = "Base.ModernCarMuffler2", name = "Performance silencers: Sport", delta = 0.9 },
                [9] = { baseName = "Base.ModernCarMuffler1", name = "Performance silencers: Standard", delta = 0.8 },
                [10] = { baseName = "Base.ModernSuspension3", name = "Performance suspension: Resistant", delta = 1 },
                [11] = { baseName = "Base.ModernSuspension2", name = "Performance suspension: Sport", delta = 0.9 },
                [12] = { baseName = "Base.ModernSuspension1", name = "Performance suspension: Standard", delta = 0.8 },
                [13] = { baseName = "Base.NormalBrake3", name = "Standard brakes: Resistant", delta = 0.7 },
                [14] = { baseName = "Base.NormalBrake2", name = "Standard brakes: Sport", delta = 0.6 },
                [15] = { baseName = "Base.NormalBrake1", name = "Standard brakes: Standard", delta = 0.5 },
                [16] = { baseName = "Base.NormalCarMuffler3", name = "Standard silencers: Resistant", delta = 0.7 },
                [17] = { baseName = "Base.NormalCarMuffler2", name = "Standard silencers: Sport", delta = 0.6 },
                [18] = { baseName = "Base.NormalCarMuffler1", name = "Standard silencers: Standard", delta = 0.5 },
                [19] = { baseName = "Base.NormalSuspension3", name = "Standard suspension: Resistant", delta = 0.7 },
                [20] = { baseName = "Base.NormalSuspension2", name = "Standard suspension: Sport", delta = 0.6 },
                [21] = { baseName = "Base.NormalSuspension1", name = "Standard suspension: Standard", delta = 0.5 }
            }
            
            local randomQuest = ZombRand(1, #quests + 1)
            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. sellerName .. quest.name
                modData.PZLinuxContractInfo = quest.baseName
                modData.PZLinuxOnReward = math.ceil((modData.PZLinuxOnReward * quest.delta)/10)*10
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)
            

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 6 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for someone to capture a zombie alive."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
                        
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 7 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()
            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We lost our cargo, we're looking for someone to retrieve it by helicopter."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "Where is the cargo ?", function()
                message = message .. "\n" .. playerName .. "Where is the cargo ?"
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
            if contractsCityId[contract] == 1 then
                quests = {
                    [1] = { description = "In front of Farming Supply Store in Irvington.", x = 2478, y = 14321, z = 0, city = "Irvington" },
                }
            end

            if contractsCityId[contract] == 2 then
                quests = {
                    [1] = { description = "In front of the Liquor Store Store in Ekron.", x = 513, y = 9865, z = 0, city = "Ekron" },
                }
            end

            if contractsCityId[contract] == 3 then
                quests = {
                    [1] = { description = "In front of the Community Center of Brandenburg.", x = 1850, y = 5980, z = 0, city = "Brandenburg" },
                    [2] = { description = "At the center of the Destroyed Train yard of Brandenburg.", x = 2207, y = 6683, z = 0, city = "Brandenburg" },
                }
            end

            if contractsCityId[contract] == 4 then
                quests = {
                    [1] = { description = "At the diner in Echo Creek.", x = 3589, y = 10893, z = 0, city = "Echo Creek" },
                }
            end

            if contractsCityId[contract] == 5 then
                quests = {
                    [1] = { description = "In front of the Laundromat of Riverside.", x = 6387, y = 5336, z = 0, city = "Riverside" },
                }
            end

            if contractsCityId[contract] == 6 then
                quests = {
                    [1] = { description = "In front of the Police Station of Fallas Lake.", x = 7261, y = 8382, z = 0, city = "Fallas Lake" },
                }
            end

            if contractsCityId[contract] == 7 then
                quests = {
                    [1] = { description = "At the intersection of Bank and Zippee Market in Rosewood.", x = 8102, y = 11581, z = 0, city = "Rosewood" },
                }
            end

            if contractsCityId[contract] == 8 then
                quests = {
                    [1] = { description = "In front of Post Office in March Ridge.", x = 10102, y = 12702, z = 0, city = "March Ridge" },
                }
            end

            if contractsCityId[contract] == 9 then
                quests = {
                    [1] = { description = "At the intersection of the Gas Station and Knox Bank in Muldraugh.", x = 10592, y = 9737, z = 0, city = "Muldraugh" },
                }
            end

            if contractsCityId[contract] == 10 then
                quests = {
                    [1] = { description = "At the Town Park of West Point.", x = 11788, y = 6912, z = 0, city = "West Point" },
                    [2] = { description = "In front of the School of West Point.", x = 11348, y = 6793, z = 0, city = "West Point" },
                }
            end

            if contractsCityId[contract] == 11 then
                quests = {
                    [1] = { description = "In the StarEplex Cinema of Valley Station.", x = 13639, y = 5886, z = 0, city = "Valley Station" },
                }
            end

            if contractsCityId[contract] == 12 then
                quests = {
                    [1] = { description = "In the south Cemetary of Louisville.", x = 12583, y = 3280, z = 0, city = "Louisville" },
                }
            end

            local randomQuest = 1
            if #quests > 1 then
                randomQuest = ZombRand(1, #quests + 1)
            end

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. sellerName .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
                locationQuestTown = quest.city .. ":\n* " .. quest.description
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Prepare defenses, we will take the cargo by helicopter."
            
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 8 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()
            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We have a building to protect against a horde of zombies."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            typeText(self.typingMessage, "Where is the building ?", function()
                message = message .. "\n" .. playerName .. "Where is the building ?"
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
            if contractsCityId[contract] == 1 then
                quests = {
                    [1] = { description = "It's the Irvington Metal Workshop.", x = 2373, y = 14479, z = 0, city = "Irvington" },
                    [2] = { description = "It's the Irvington School.", x = 2259, y = 14356, z = 0, city = "Irvington" },
                    [3] = { description = "It's the Irvington Church.", x = 2433, y = 14224, z = 0, city = "Irvington" },
                }
            end

            if contractsCityId[contract] == 2 then
                quests = {
                    [1] = { description = "It's the Ekron Restaurant.", x = 458, y = 9787, z = 0, city = "Ekron" },
                    [2] = { description = "It's the Ekron Metal Workshop.", x = 623, y = 9837, z = 0, city = "Ekron" },
                    [3] = { description = "It's the Ekron Fire Department.", x = 761, y = 9770, z = 0, city = "Ekron" },
                }
            end

            if contractsCityId[contract] == 3 then
                quests = {
                    [1] = { description = "It's the Brandenburg P.S. Delilah.", x = 2049, y = 5696, z = 0, city = "Brandenburg" },
                    [2] = { description = "It's the Brandenburg Bar.", x = 2425, y = 5797, z = 0, city = "Brandenburg" },
                    [3] = { description = "It's the Brandenburg Gigamart.", x = 1865, y = 6349, z = 0, city = "Brandenburg" },
                }
            end

            if contractsCityId[contract] == 4 then
                quests = {
                    [1] = { description = "It's the Echo Creek Garden Store.", x = 3465, y = 11508, z = 0, city = "Echo Creek" },
                }
            end

            if contractsCityId[contract] == 5 then
                quests = {
                    [1] = { description = "It's the Riverside Gigamart.", x = 6506, y = 5346, z = 0, city = "Riverside" },
                    [2] = { description = "It's the Riverside School.", x = 6445, y = 5441, z = 0, city = "Riverside" },
                    [3] = { description = "It's the Riverside Coffee Shop.", x = 6401, y = 5253, z = 0, city = "Riverside" },
                }
            end

            if contractsCityId[contract] == 6 then
                quests = {
                    [1] = { description = "It's the Fallas Lake Farming Supply Store.", x = 7253, y = 8323, z = 0, city = "Fallas Lake" },
                }
            end

            if contractsCityId[contract] == 7 then
                quests = {
                    [1] = { description = "It's the Rosewood Bank.", x = 8089, y = 11591, z = 0, city = "Rosewood" },
                    [2] = { description = "It's the Rosewood Police Station.", x = 8065, y = 11735, z = 0, city = "Rosewood" },
                }
            end

            if contractsCityId[contract] == 8 then
                quests = {
                    [1] = { description = "It's the March Ridge Cinema.", x = 10166, y = 12658, z = 0, city = "March Ridge" },
                    [2] = { description = "It's the March Ridge Community Center.", x = 10030, y = 12734, z = 0, city = "March Ridge" },
                }
            end

            if contractsCityId[contract] == 9 then
                quests = {
                    [1] = { description = "It's the Muldraugh Police Station.", x = 10637, y = 10417, z = 0, city = "Muldraugh" },
                    [2] = { description = "It's the Muldraugh Cortman Medical.", x = 10879, y = 10029, z = 0, city = "Muldraugh" },
                }
            end

            if contractsCityId[contract] == 10 then
                quests = {
                    [1] = { description = "It's the West Point School.", x = 11344, y = 6780, z = 0, city = "West Point" },
                    [2] = { description = "It's the West Point Church.", x = 11964, y = 6999, z = 0, city = "West Point" },
                }
            end

            if contractsCityId[contract] == 11 then
                quests = {
                    [1] = { description = "It's the Valley Station Crossroads Mail.", x = 13944, y = 5908, z = 0, city = "Valley Station" },
                }
            end
            
            if contractsCityId[contract] == 12 then
                quests = {
                    [1] = { description = "It's the Louisville Hospital.", x = 12940, y = 2078, z = 0, city = "Louisville" },
                    [2] = { description = "It's the Louisville Police Station & Prison.", x = 12442, y = 1586, z = 0, city = "Louisville" },
                    [3] = { description = "It's the Louisville Bowling Alley.", x = 12447, y = 2077, z = 0, city = "Louisville" },
                    [4] = { description = "It's the Louisville Court House.", x = 12483, y = 1546, z = 0, city = "Louisville" },
                }
            end
            
            local randomQuest = 1
            if #quests > 1 then
                randomQuest = ZombRand(1, #quests + 1)
            end

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. sellerName .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
                locationQuestTown = quest.city .. ":\n* " .. quest.description .. "\n* Zombies to kill: 10"
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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
            
            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Prepare defenses, there will be many zombies."
            
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 9 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for medical equipment."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What exactly are you looking for ?", function()
                message = message .. "\n" .. playerName .. "What exactly are you looking for ?"
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
            local quests = {
                [1] = { baseName = "Base.Bandaid", name = "Bandage: Adhesive", delta = 0.5 },
                [2] = { baseName = "Base.Bandage", name = "Bandage", delta = 0.6 },
                [3] = { baseName = "Base.AlcoholWipes", name = "Alcohol Wipes", delta = 0.8 },
                [4] = { baseName = "Base.Disinfectant", name = "Bottle of Disinfectant", delta = 1.2 },
                [5] = { baseName = "Base.AlcoholedCottonBalls", name = "Cotton Balls Doused in Alcohol", delta = 0.7 },
                [6] = { baseName = "Base.Antibiotics", name = "Antibiotics", delta = 1.5 },
                [7] = { baseName = "Base.PillsAntiDep", name = "Antidepressants", delta = 1.1 },
                [8] = { baseName = "Base.PillsBeta", name = "Beta Blockers", delta = 1 },
                [9] = { baseName = "Base.Pills", name = "Painkillers", delta = 1.3 },
                [10] = { baseName = "Base.PillsSleepingTablets", name = "Sleeping Pills", delta = 0.8 },
                [11] = { baseName = "Base.PillsVitamins", name = "Caffeine Pills", delta = 0.7 },
            }
            
            local randomQuest = ZombRand(1, #quests + 1)
            local countRequest = ZombRand(1, 11)
            local quest = quests[randomQuest]
            if quest then
                modData.PZLinuxContractInfo = quest.baseName
                modData.PZLinuxContractInfoCount = countRequest
                modData.PZLinuxOnReward = math.ceil((modData.PZLinuxOnReward * quest.delta)/10)*10
                questDetailName = quest.name
                message = message .. "\n" .. sellerName .. modData.PZLinuxContractInfoCount .. " " .. quest.name
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end
    
    if contract == 10 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            local globalVolume = getCore():getOptionSoundVolume() / 10
            local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
            local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local sleepSFX = 1
            if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            message = sellerName .. "We are looking for weapons."
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What exactly are you looking for ?", function()
                message = message .. "\n" .. playerName .. "What exactly are you looking for ?"
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
            local quests = {
                [1] = { baseName = "Base.Pistol3", name ="D-E Pistol", delta = 0.3 },
                [2] = { baseName = "Base.Pistol2", name ="M1911 Pistol", delta = 0.3 },
                [3] = { baseName = "Base.Revolver_Short", name ="M36 Revolver", delta = 0.5 },
                [4] = { baseName = "Base.Revolver", name ="M625 Revolver", delta = 0.4 },
                [5] = { baseName = "Base.Pistol", name ="M9 Pistol", delta = 0.3 },
                [6] = { baseName = "Base.Revolver_Long", name ="Magnum", delta = 0.5 },
                [7] = { baseName = "Base.DoubleBarrelShotgun", name ="Double Barrel Shotgun", delta = 1.2 },
                [8] = { baseName = "Base.Shotgun", name ="JS-2000 Shotgun", delta = 1.2 },
                [9] = { baseName = "Base.DoubleBarrelShotgunSawnoff", name ="Sawed-off Double Barrel Shotgun", delta = 1.2 },
                [10] = { baseName = "Base.ShotgunSawnoff", name ="Sawed-off JS-2000 Shotgun", delta = 1.2 },
                [11] = { baseName = "Base.AssaultRifle2", name ="M14 Rifle", delta = 1.5 },
                [12] = { baseName = "Base.AssaultRifle", name ="M16 Assault Rifle", delta = 1.5 },
                [13] = { baseName = "Base.VarmintRifle", name ="MSR700 Rifle", delta = 1.5 },
                [14] = { baseName = "Base.HuntingRifle", name ="MSR788 Rifle", delta = 1.5 },
            }
            
            local randomQuest = ZombRand(1, #quests + 1)
            local countRequest = ZombRand(1, 6)
            local quest = quests[randomQuest]
            if quest then
                modData.PZLinuxContractInfo = quest.baseName
                modData.PZLinuxContractInfoCount = countRequest
                modData.PZLinuxOnReward = math.ceil((modData.PZLinuxOnReward * quest.delta)/10)*10
                questDetailName = quest.name
                message = message .. "\n" .. sellerName .. modData.PZLinuxContractInfoCount .. " " .. quest.name
            end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            self.loadingMessage:setName(message)
            
            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
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

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end

            if self.isClosing then return end

            getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 50, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. "Deal ?"
            
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

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

-- RESET ALL QUESTS
-- PZLinuxActiveContract = 0 Free
-- PZLinuxActiveContract = 1 Active
-- PZLinuxActiveContract = 2 Complete
function contractsUI:onYesButton(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxActiveContract = 1
    modData.PZLinuxOnZombieDead = 0
    self.isClosing = true
    self:removeFromUIManager()
    modData.PZLinuxUIOpenMenu = 7
    
    modData.PZLinuxContractNote = "* [" .. contractsCompanyCodes[button.contractId] .. "] ".. contractsQuestName[button.contractId] .. " for $" .. contractsCompanyReward[button.contractId]
    if modData.PZLinuxContractInfoCount and modData.PZLinuxContractInfoCount > 0 then
        modData.PZLinuxContractNote = modData.PZLinuxContractNote .. "\n* " .. modData.PZLinuxContractInfoCount .. " " .. questDetailName
    end

    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local note = inv:AddItem('Base.Note')
    note:setName("Contract")
    note:setCanBeWrite(true)
    note:addPage(1, locationQuestTown .. "\n" .. modData.PZLinuxContractNote .. "\n")

    if modData.PZLinuxContractLocationX and modData.PZLinuxContractLocationX > 0 then
        contractsDrawOnMap(modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY, modData.PZLinuxContractNote)
    end

    if button.contractId == 1 then modData.PZLinuxContractKillZombie = 1 end
    if button.contractId == 2 then modData.PZLinuxContractPickUp = 1 end 
    if button.contractId == 3 then modData.PZLinuxContractPickUp = 1 end 
    if button.contractId == 4 then modData.PZLinuxContractPickUp = 1 end
    if button.contractId == 5 then modData.PZLinuxContractManhunt = 1 end
    if button.contractId == 6 then modData.PZLinuxContractBlood = 1 end
    if button.contractId == 7 then modData.PZLinuxContractCar = 1 end
    if button.contractId == 8 then modData.PZLinuxContractCapture = 1 end
    if button.contractId == 9 then modData.PZLinuxContractCargo = 1 end
    if button.contractId == 10 then modData.PZLinuxContractProtect = 1 end
    if button.contractId == 11 then modData.PZLinuxContractMedical = 1 end
    if button.contractId == 12 then modData.PZLinuxContractWeapon = 1 end
end

-- LOGOUT
function contractsUI:onMinimizeBack(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 7
end

function contractsUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function contractsUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function contractsUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function contractsUI:onSFXOn(button)
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

function contractsUI:onSFXOff(button)
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


function contractsMenu_ShowUI(player)
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

    local ui = contractsUI:new(uiX, uiY, finalW, finalH, player)
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