-- Contracts UI - by Raixxar 
-- Updated : 25/02/25

contractsUI = ISPanel:derive("contractsUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0
local selectedContracts = {}

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
for i = 1, 8 do
    local randomId = ZombRand(1, 32)
    local difficulty = "0"
    local reward = 20
    -- 1 reward * 1000, 2 reward * 2500, 3 reward * 5000, 4 reward * 10000, 5 reward * 20000
    if i == 1 then difficulty = "1"; reward = 1000 end -- Kill Zombies
    if i == 2 then difficulty = "2"; reward = 2500 end -- Pick up a package in the town of Rosewood
    if i == 3 then difficulty = "2"; reward = 2500 end -- Pick up a package in the town of March Ridge
    if i == 4 then difficulty = "3"; reward = 5000 end -- Pick up a package in the town of Muldraugh
    if i == 5 then difficulty = "5"; reward = 20000 end -- Pick up a package in the town of Louisville
    if i == 6 then difficulty = "3"; reward = 5000 end -- Manhunt
    if i == 7 then difficulty = "1"; reward = 1000 end -- Blood Market
    if i == 8 then difficulty = "4"; reward = 10000 end -- Car parts
    local getHourTime = math.ceil(getGameTime():getWorldAgeHours()/2190 + 1)
    local randomCode = "Execute a contract for " .. companyCode[randomId].code .. " - Difficulty: " .. difficulty .. "/5"
    local dataName = "PZLinuxTrading" .. companyCode[randomId].code
    local companyData = ModData.getOrCreate(dataName)
    local priceHistory = companyData.dataName or {}
    local lastIndex = #priceHistory
    local lastPrice = priceHistory[lastIndex] or 1
    local PZReward = math.ceil((ZombRand(lastPrice, lastPrice * getHourTime) + reward)/10) * 10
    contracts[i] = { id = i, name = randomCode, code = companyCode[randomId].code, reward = PZReward }
end

local contractsCompanyCodes = {}
local contractsCompanyReward = {}
for i, contract in ipairs(contracts) do
    contractsCompanyCodes[contract.id] = contract.code
    contractsCompanyReward[contract.id] = contract.reward
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

    local modData = getPlayer():getModData()
    if modData.PZLinuxActiveContract == 1 then
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
    elseif modData.PZLinuxActiveContract == 2 then
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

    if (getHourTime - LAST_CONNECTION_TIME) > 168 then
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
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxActiveContract = 0
    modData.PZLinuxContractNote = ""
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractKillZombie = 0
    modData.PZLinuxContractPickUp = 0
    modData.PZLinuxContractManhunt = 0
    modData.PZLinuxContractBlood = 0
    modData.PZLinuxContractCar = 0

    local inv = getPlayer():getInventory()
    local notebook = inv:Remove('Notebook')

    self.isClosing = true
    self:removeFromUIManager()
    contractsMenu_ShowUI(player)
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

    if modData.PZLinuxActiveContract == 2 then
        self:onContractComplete()
        return
    end
    table.remove(selectedContracts, button.contractPosition)
    self:onContractId(button.contractId)
end

function contractsUI:onContractComplete()
    self.completeContractMessage = ISLabel:new(self.width * 0.20, self.height * 0.30, self.height * 0.025, "You have been paid for your contract.", 0, 1, 0, 1, UIFont.Small, true)
    self.completeContractMessage:setVisible(true)
    self.completeContractMessage:initialise()
    self.topBar:addChild(self.completeContractMessage)

    local modData = getPlayer():getModData()
    local balance = modData.PZLinuxOnReward + loadAtmBalance()
    saveAtmBalance(balance)
    self.titleLabel:setName("Bank balance: $"  .. tostring(loadAtmBalance()))

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
    local notebook = inv:Remove('Notebook')
    
    LAST_CONNECTION_TIME = 0
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxActiveContract = 0
    modData.PZLinuxContractNote = ""
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractKillZombie = 0
    modData.PZLinuxContractPickUp = 0
    modData.PZLinuxContractManhunt = 0
    modData.PZLinuxContractBlood = 0
    modData.PZLinuxContractCar = 0
end

function contractsUI:onContractId(contract)
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
    
    if contract == 1 then
        self.terminalCoroutine = coroutine.create(function()
            local ZtoKill = tostring(ZombRand(1, 6) * 10)
            local modData = getPlayer():getModData()
            modData.PZLinuxOnZombieToKill = ZtoKill

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = "Unknown: We are looking for a mercenary to clean the streets of our city."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How many zombies do you need to kill ?", function()
                message = message .. "\nYou: How many zombies do you need to kill ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. modData.PZLinuxOnZombieToKill
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. "Do you accept the contract ?"
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end
    
    if contract == 2 then
        self.terminalCoroutine = coroutine.create(function()
            local randomQuest = ZombRand(1, 6)
            local modData = getPlayer():getModData()

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We are looking for a courier to retrieve a package the town of\nRosewood."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "Where is the package exactly in Rosewood ?", function()
                message = message .. "\nYou: Where is the package in Rosewood ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            local quests = {
                [1] = { description = "In the police station, in a paper cabinet.", x = 8073, y = 11736, z = 0 },
                [2] = { description = "In the elementary school, in a school locker.", x = 8333, y = 11616, z = 0 },
                [3] = { description = "In the church, in a gray cabinet.", x = 8134, y = 11542, z = 0 },
                [4] = { description = "In the bar, under the sink in a cabinet.", x = 8022, y = 11423, z = 0 },
                [5] = { description = "In the Knox Country Court of Justice, in a gray cabinet.", x = 8062, y = 11653, z = 0 }
            }

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\nUnknown: " .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
            end

            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How do I give you the package ?", function()
                message = message .. "\nYou: How do I give you the package ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Put the package in a mailbox."
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 3 then
        self.terminalCoroutine = coroutine.create(function()
            local randomQuest = ZombRand(1, 6)
            local modData = getPlayer():getModData()

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We are looking for someone for a simple race in the\ntown of March Ridge."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "Where is the package exactly in March Ridge ?", function()
                message = message .. "\nYou: Where is the package exactly in March Ridge ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            local quests = {
                [1] = { description = "At the church, in a library.", x = 10322, y = 12800, z = 0 },
                [2] = { description = "In the insurance office, in a paper box.", x = 10070, y = 12778, z = 0 },
                [3] = { description = "At the community center, in the blue locker.", x = 10038, y = 12720, z = 0 },
                [4] = { description = "At the Knox military apartments, in the clothing washer.", x = 10064, y = 12623, z = 0 },
                [5] = { description = "In the bar, in the trash inside.", x = 10171, y = 12667, z = 0 }
            }

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\nUnknown: " .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
            end

            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How do I give you the package ?", function()
                message = message .. "\nYou: How do I give you the package ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Put the package in a mailbox."
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 4 then
        self.terminalCoroutine = coroutine.create(function()
            local randomQuest = ZombRand(1, 6)
            local modData = getPlayer():getModData()
            
            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We're looking for a brave person for simple missions at Muldraugh."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "Where is the package in Muldraugh ?", function()
                message = message .. "\nYou: Where is the package in Muldraugh ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            local quests = {
                [1] = { description = "At Jays Chicken, in a big trash outside.", x = 10627, y = 9564, z = 0 },
                [2] = { description = "At the police station, in a blue locker.", x = 10646, y = 10409, z = 0 },
                [3] = { description = "In the Cortman medical, in an antique piece of furniture.", x = 10880, y = 10024, z = 0 },
                [4] = { description = "At the electronics store, in a fridge.", x = 10617, y = 9872, z = 0 },
                [5] = { description = "In the McCoy logging Corp, in a yellow locker.", x = 10310, y = 9340, z = 0 }
            }

            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
            end

            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How do I give you the package ?", function()
                message = message .. "\nYou: How do I give you the package ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Put the package in a mailbox."
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 5 then
        self.terminalCoroutine = coroutine.create(function()
            local randomQuest = ZombRand(1, 11)
            local modData = getPlayer():getModData()

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We are seeking soldiers for a retrieval mission in Louisville."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "Where is the package in Louisville ?", function()
                message = message .. "\nYou: Where is the package in Louisville ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            local quests = {
                [1]  = { description = "In the repurposed building, in a box.", x = 12436, y = 1420, z = 0 },
                [2]  = { description = "At the fire department, in a gray wardrobe.", x = 13729, y = 1784, z = 0 },
                [3]  = { description = "At the Knox bank, on the last floor in a paper box.", x = 12653, y = 1636, z = 15 },
                [4]  = { description = "In the hospital, in a trash.", x = 12923, y = 2060, z = 2 },
                [5]  = { description = "At the Scarlet Oak Distillery, in a box.", x = 12021, y = 1934, z = 0 },
                [6]  = { description = "At the Knox bank, on the third floor in a metal cabinet.", x = 12561, y = 1707, z = 2 },
                [7]  = { description = "At the Awl Work and Sew Play, in the container somewhere below the register.", x = 12491, y = 1695, z = 0 },
                [8]  = { description = "In the Evergreen public school, in a yellow locker.", x = 13581, y = 2782, z = 0 },
                [9]  = { description = "In the Leafhill heights elementary school, in the yellow locker.", x = 12351, y = 3247, z = 1 },
                [10] = { description = "In the Pizza Whirled, in the fridge.", x = 13224, y = 2103, z = 0 }
            }
            
            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. quest.description
                modData.PZLinuxContractLocationX = quest.x
                modData.PZLinuxContractLocationY = quest.y
                modData.PZLinuxContractLocationZ = quest.z
            end

            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How do I give you the package ?", function()
                message = message .. "\nYou: How do I give you the package ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Put the package in a mailbox."
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 6 then
        self.terminalCoroutine = coroutine.create(function()
            local randomQuest = ZombRand(1, 11)
            local modData = getPlayer():getModData()
            
            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] ": We are looking for a hunter."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "Who is the target ?", function()
                message = message .. "\nYou: Who is the target ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
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

            local targetName = names[firstNameId].first .. " " .. names[lastNameId].last
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": The target is " .. targetName
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How do I find my target ?", function()
                message = message .. "\nYou: How do I find my target ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            local quests = {
                [1] = { description = "The target was last seen at Rosewood police station.", x = 8061, y = 11725, z = 0 },
                [2] = { description = "The target was last seen at Rosewwod Auto Repair Shop.", x = 8156, y = 11321, z = 0},
                [3] = { description = "The target was last seen at Rosewood Gas Station.", x = 8178, y = 11276, z = 0 },
                [4] = { description = "The target was last seen at Fallas Lake near the Hardware Store.", x = 7252, y = 8227, z = 0},
                [5] = { description = "The target was last seen near Fallas Lake at Army Quarters.", x = 7436, y = 7951, z = 0},
                [6] = { description = "The target was supposed to go to Brandenburg at P.S. Delilah.", x = 2037, y = 5684, z = 2},
                [7] = { description = "The target must be in Brandenburg Prison.", x = 1352, y = 5892, z = -1},
                [8] = { description = "The target was supposed to go to the Tool Store in Brandenburg.", x = 2094, y = 5885, z = 0},
                [9] = { description = "The target must be at the fire station in Ekron", x = 756, y = 9773, z = 0},
                [10] = { description = "The target was supposed to go to the elementary school in Irvington.", x = 2227, y = 14328, z = 0},
            }
            
            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. contractsCompanyCodes[contract] .. ": " .. quest.description
                modData.PZLinuxContractLocationX = tonumber(quest.x)
                modData.PZLinuxContractLocationY = tonumber(quest.y)
                modData.PZLinuxContractLocationZ = tonumber(quest.z)
            end
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            typeText(self.typingMessage, "How can I prove to you that he is dead ?", function()
                message = message .. "\nYou: How can I prove to you that he is dead ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Send us the corpse, or what remains of it, with a mailbox."
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 7 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We are looking for blood analyses of zombies."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
            self.noButton:initialise()
            self.noButton:instantiate()
            self.topBar:addChild(self.noButton)
        end)
    end

    if contract == 8 then
        self.terminalCoroutine = coroutine.create(function()
            local modData = getPlayer():getModData()

            modData.PZLinuxOnReward = contractsCompanyReward[contract]
            modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[7]
            local message = ""

            local elapsed = 0
            while elapsed < ZombRand(1, 2) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = contractsCompanyCodes[contract] .. ": We are looking for someone to find auto parts for us."
            self.loadingMessage:setName(message)
            
            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "Which auto parts do you need ?", function()
                message = message .. "\nYou: Which auto parts do you need ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            local quests = {
                [1] = { baseName = "Base.CarBattery3", name = "Sport Battery" },
                [2] = { baseName = "Base.ModernBrake3", name = "Sport type performance brakes" },
                [3] = { baseName = "Base.ModernCarMuffler3", name = "Silent sport type muffler" },
                [4] = { baseName = "Base.ModernSuspension3", name = "Sport type performance suspension" },
            }

            local randomQuest = ZombRand(1, 5)
            local quest = quests[randomQuest]
            if quest then
                message = message .. "\n" .. contractsCompanyCodes[contract] .. ": ".. quest.name
                modData.PZLinuxContractInfo = quest.baseName
            end
            self.loadingMessage:setName(message)
            

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end
            
            typeText(self.typingMessage, "What is the reward for this mission ?", function()
                message = message .. "\nYou: What is the reward for this mission ?"
                self.loadingMessage:setName(message)
                self.typingMessage:setName("")
            end)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": $" .. modData.PZLinuxOnReward 
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            message = message .. "\n" .. contractsCompanyCodes[contract] .. ": Do you accept the contract ?"
            modData.PZLinuxContractNote = message
            self.loadingMessage:setName(message)

            local elapsed = 0
            while elapsed < ZombRand(5, 15) do
                coroutine.yield()
                elapsed = elapsed + 0.016
            end

            self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
            self.yesButton.contractId = contract
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
            
            self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimize)
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
    self.isClosing = true
    self:removeFromUIManager()
    contractsMenu_ShowUI(player)
    
    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local notebook = inv:AddItem('Base.Notebook')
    notebook:setName("Contract")
    notebook:addPage(1, modData.PZLinuxContractNote)

    if button.contractId == 1 then modData.PZLinuxContractKillZombie = 1 end
    if button.contractId == 2 then modData.PZLinuxContractPickUp = 1 end 
    if button.contractId == 3 then modData.PZLinuxContractPickUp = 1 end
    if button.contractId == 4 then modData.PZLinuxContractPickUp = 1 end 
    if button.contractId == 5 then modData.PZLinuxContractPickUp = 1 end
    if button.contractId == 6 then modData.PZLinuxContractManhunt = 1 end
    if button.contractId == 7 then modData.PZLinuxContractBlood = 1 end
    if button.contractId == 8 then modData.PZLinuxContractCar = 1 end
end

-- STOP
function contractsUI:onStop(button)
    self.isClosing = true
    self:removeFromUIManager()
end

-- LOGOUT
function contractsUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    contractsMenu_ShowUI(player)
end

-- CLOSE
function contractsUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    contractsMenu_ShowUI(player)
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
end