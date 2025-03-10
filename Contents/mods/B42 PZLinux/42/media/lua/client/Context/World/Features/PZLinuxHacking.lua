hackingUI = ISPanel:derive("hackingUI")

local hackingBankBalance = 0
local historyPassword = ""
local hackingPasswordFull = "****"
local hackingPassword1 = 0
local hackingPassword2 = 0
local hackingPassword3 = 0
local hackingPassword4 = 0
local hackZombieName = nil

-- CONSTRUCTOR
function hackingUI:new(x, y, width, height, player)
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
function hackingUI:initialise()
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

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

-- LOGOUT
function hackingUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- LOGOUT
function hackingUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function hackingUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function hackingUI:onSFXOn(button)
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

function hackingUI:onSFXOff(button)
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

-- ID CARD
function hackingUI:onIdCard()
    local playerObj = getPlayer()
    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    hackZombieName = nil
    
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        local modData = getPlayer():getModData()
        if item:getFullType() == "Base.IDcard" 
        or item:getFullType() == "Base.IDcard_Stolen" 
        or item:getFullType() == "Base.IDcard_Female"
        or item:getFullType() == "Base.IDcard_Male"
        or item:getFullType() == "Base.CreditCard"
        or item:getFullType() == "Base.CreditCard_Stolen" then
            hackZombieName = item:getName()
            inventory:Remove(item)
            break
        end
    end

    if hackZombieName then
        self.bootOutput = ISRichTextPanel:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.45)
        self.bootOutput.backgroundColor = {r=0, g=0, b=0, a=0}
        self.bootOutput.borderColor = {r=0, g=0, b=0, a=0}
        self.bootOutput.autosetheight = false
        self.bootOutput:setVisible(true)
        self.bootOutput:initialise()
        self.topBar:addChild(self.bootOutput)

        local player = getSpecificPlayer(0)
        self.bootMessages = {
            "<RGB:0,1,0>Connecting to 104.223.56.8.",
            "Connection attempt in progress.",
            "Connection attempt in progress..",
            "Connection attempt in progress...",
            "Connection attempt in progress....",
            "Connection attempt in progress... Failed.",
            "Brute force attempt... [Failed] Attempt 1 of 100",
            "Brute force attempt... [Failed] Attempt 2 of 100",
            "Connection failed. Retrying...",
            "Brute force attempt... [Failed] Attempt 3 of 100",
            "Authentication process failed.",
            "Brute force attempt... [Failed] Attempt 4 of 100",
            "Brute force attempt... [Failed] Attempt 5 of 100",
            "Brute force attempt... [Failed] Attempt 5 of 100",
            "Brute force attempt... [Failed] Attempt 6 of 100",
            "Brute force attempt... [Failed] Attempt 7 of 100",
            "Brute force attempt... [Failed] Attempt 8 of 100",
            "Brute force attempt... [Failed] Attempt 9 of 100",
            "Brute force attempt... [Failed] Attempt 10 of 100",
            "Brute force attempt... [Failed] Attempt 11 of 100",
            "Brute force attempt... [Failed] Attempt 12 of 100",
            "Brute force attempt... [Failed] Attempt 13 of 100",
            "Brute force attempt... [Failed] Attempt 14 of 100",
            "Connection successful.",
            "Access granted: Authentication interface compromised.",
            "Unauthorized access detected.",
            "Backdoor activated.",
            "Database access located.",
            "Decrypting data...",
            "Encrypting server data: *process in progress*",
            "Alert: Firewall activation detected. Attempting bypass...",
            "Firewall bypass failed. Reconnecting to 104.223.56.8...",
            "Brute force active: multiple attempts to unlock the system.",
            "Brute force successful, stable connection established.",
            "System compromised. Full server access granted.",
            "Alert: Unusual activity detected on the network.",
            "Access denied, attempting to connect to backup server.",
            "Simulation of successful connection to backup server.",
            "Full system scan results: \n- Intrusion detected \n- Data breach detected \n- Tracking activated",
            "System alert: Hacking attempt detected at 104.223.56.8",
            "Data breach: Outbound transfer in progress.",
            "Remote access: \nSecure data transfer initiated.",
            "Brute force successful. Privilege escalation granted.",
            "System password reset... Completed.",
            "Hacker detected in the system.",
            "Remote access authorized: Online banking system compromised.",
            "Virus and malware scan in progress...",
            "Security alert: Emergency protocol activated.",
            "Logging event: Full breach of system 104.223.56.8 detected.",
            "Brute force attack complete. Mission accomplished.</RGB>"
        }
        local messages = {}
        self.terminalCoroutine = coroutine.create(function()
            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            local initialDelay = elapsed + 1
    
            for _, line in ipairs(self.bootMessages) do
                if self.isClosing then return end

                self.bootOutput.text = self.bootOutput.text .. "\n" .. line
                self.bootOutput:paginate()

                local maxYScroll = self.bootOutput:getScrollHeight() - self.bootOutput:getHeight()
                if maxYScroll > 0 then
                    self.bootOutput:setYScroll(-maxYScroll)
                end

                local lineDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(1, 10)
                while elapsed < lineDelay do
                    coroutine.yield()
                    elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
                end
            end
        end)

        self.updateCoroutineFunc = function()
            if coroutine.status(self.terminalCoroutine) ~= "dead" then
                coroutine.resume(self.terminalCoroutine)
            else
                Events.OnTick.Remove(self.updateCoroutineFunc)
                self.updateCoroutineFunc = nil
                self.terminalCoroutine = nil
                self:onHack()
            end
        end
        Events.OnTick.Add(self.updateCoroutineFunc)
    else
        self.hackLabelTitleError = ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.025, "No ID Card or Credit Card...", 0, 1, 0, 1, UIFont.Small, true)
        self.hackLabelTitleError.backgroundColor = {r=0, g=0, b=0, a=0}
        self.hackLabelTitleError.borderColor = {r=0, g=0, b=0, a=0}
        self.hackLabelTitleError:setVisible(true)
        self.hackLabelTitleError:initialise()
        self.topBar:addChild(self.hackLabelTitleError)
    end
end 

function hackingUI:onHack()
    historyPassword = ""
    self.bootOutput:setVisible(false)
    local player = getSpecificPlayer(0)

    hackingBankBalance = ZombRand(5, 1000) * (player:getPerkLevel(Perks.Electricity) + 1)

    local passwordNumbers = {}

    while #passwordNumbers < 4 do
        local num = ZombRand(0, 10)
        local exists = false

        for _, v in ipairs(passwordNumbers) do
            if v == num then
                exists = true
                break
            end
        end

        if not exists then
            table.insert(passwordNumbers, num)
        end
    end

    hackingPassword1 = passwordNumbers[1]
    hackingPassword2 = passwordNumbers[2]
    hackingPassword3 = passwordNumbers[3]
    hackingPassword4 = passwordNumbers[4]

    local hackLabelTitle = tostring(hackZombieName) .. " Bank Balance: $" .. hackingBankBalance .. "\nFind the password in 4 numbers.\n"
    self.hackLabelTitle = ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.025, hackLabelTitle, 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelTitle.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitle.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitle:setVisible(true)
    self.hackLabelTitle:initialise()
    self.topBar:addChild(self.hackLabelTitle)

    self.hackLabel = ISLabel:new(self.width * 0.20, self.height * 0.24, self.height * 0.025, hackingPasswordFull, 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabel.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabel:setVisible(true)
    self.hackLabel:initialise()
    self.topBar:addChild(self.hackLabel)

    self.hackLabelMsg = ISLabel:new(self.width * 0.20, self.height * 0.26, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelMsg.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelMsg.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelMsg:setVisible(true)
    self.hackLabelMsg:initialise()
    self.topBar:addChild(self.hackLabelMsg)

    self.hackLabelAttempts = ISLabel:new(self.width * 0.20, self.height * 0.47, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelAttempts.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelAttempts.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelAttempts:setVisible(true)
    self.hackLabelAttempts:initialise()
    self.topBar:addChild(self.hackLabelAttempts)

    self.hackLabelHistory = ISLabel:new(self.width * 0.20, self.height * 0.32, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelHistory.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelHistory.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelHistory:setVisible(true)
    self.hackLabelHistory:initialise()
    self.topBar:addChild(self.hackLabelHistory)

    self.promptCommand = ISTextEntryBox:new("", self.width * 0.20, self.height * 0.42, self.width * 0.2, self.height * 0.025)
    self.promptCommand.backgroundColor = {r=0, g=0, b=0, a=0}
    self.promptCommand.borderColor = {r=0, g=1, b=0, a=0.8}
    self.promptCommand.onCommandEntered = function(entry) self:onCommandEnter() end
    self.promptCommand:setVisible(false)
    self.promptCommand:initialise()
    self.promptCommand:instantiate()
    self.promptCommand:setOnlyNumbers(true)
    self.promptCommand.onTextChange = function(entry)
        local text = entry:getText()
        if #text > 4 then
            entry:setText(text:sub(1, 4))
        end
    end
    self.topBar:addChild(self.promptCommand)
end

function hackingUI:onCommandEnter()
    local globalVolume = getCore():getOptionSoundVolume() / 10
    hackingUI.triesCount = 0
    hackingUI.maxTries = 7

    local commandText = self.promptCommand:getText()
    local passwordStr = tostring(commandText)

    if #commandText ~= 4 then
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        return
    end

    while #passwordStr < 4 do
        passwordStr = passwordStr .. "*"
    end

    local firstDigit  = tonumber(passwordStr:sub(1, 1))
    local secondDigit = tonumber(passwordStr:sub(2, 2))
    local thirdDigit  = tonumber(passwordStr:sub(3, 3))
    local fourthDigit = tonumber(passwordStr:sub(4, 4))
    print(hackingPassword1, hackingPassword2, hackingPassword3, hackingPassword4)

    local revealedPassword = ""
    revealedPassword = revealedPassword .. (firstDigit  == hackingPassword1 and firstDigit  or "*")
    revealedPassword = revealedPassword .. (secondDigit == hackingPassword2 and secondDigit or "*")
    revealedPassword = revealedPassword .. (thirdDigit  == hackingPassword3 and thirdDigit  or "*")
    revealedPassword = revealedPassword .. (fourthDigit == hackingPassword4 and fourthDigit or "*")
    self.hackLabel:setName(revealedPassword)
    if revealedPassword == commandText then
        self.hackLabelAttempts:setName("Account unlocked")
        getSoundManager():PlayWorldSound("buy", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.hackTransfertButton = ISButton:new(self.width * 0.20, self.height * 0.52, self.width * 0.05, self.height * 0.025, "TRANSFER", self, self.hackTransfert)
        self.hackTransfertButton:setVisible(true)
        self.hackTransfertButton:initialise()
        self.topBar:addChild(self.hackTransfertButton)

        self.hackNextButton = ISButton:new(self.width * 0.20, self.height * 0.55, self.width * 0.05, self.height * 0.025, "NEXT", self, self.hackNext)
        self.hackNextButton:setVisible(true)
        self.hackNextButton:initialise()
        self.topBar:addChild(self.hackNextButton)
        return
    end

    self.triesCount = self.triesCount + 1
    if self.triesCount > 5 then
        self.hackLabelAttempts:setName("Account locked")
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.hackNextButton = ISButton:new(self.width * 0.20, self.height * 0.55, self.width * 0.05, self.height * 0.025, "NEXT", self, self.hackNext)
        self.hackNextButton:setVisible(true)
        self.hackNextButton:initialise()
        self.topBar:addChild(self.hackNextButton)
        return
    end

    local realDigits  = { hackingPassword1, hackingPassword2, hackingPassword3, hackingPassword4 }
    local guessDigits = { firstDigit,       secondDigit,      thirdDigit,       fourthDigit }

    local correctCount = 0
    local misplacedCount = 0
    
    for i = 1, 4 do
        if guessDigits[i] and guessDigits[i] == realDigits[i] then
            correctCount = correctCount + 1
            realDigits[i]  = nil
            guessDigits[i] = nil
        end
    end
    
    for i = 1, 4 do
        local g = guessDigits[i]
        if g then
            for j = 1, 4 do
                if realDigits[j] and realDigits[j] == g then
                    misplacedCount = misplacedCount + 1
                    realDigits[j] = nil
                    break
                end
            end
        end
    end
    
    local feedbackMsg = nil
    if correctCount > 0 and misplacedCount > 0 then
        feedbackMsg = correctCount .. " digit(s) are correctly placed, " .. misplacedCount .. " digit(s) are misplaced"
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.promptCommand:setText("")
    elseif correctCount > 0 then
        feedbackMsg = correctCount .. " digit(s) are correctly placed"
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.promptCommand:setText("")
    elseif misplacedCount > 0 then
        feedbackMsg = misplacedCount .. " digit(s) are misplaced"
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.promptCommand:setText("")
    else
        feedbackMsg = "No digit is present in the code"
        getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        self.promptCommand:setText("")
    end
    
    if feedbackMsg ~= nil then
        historyPassword = historyPassword .. "\n" .. commandText .. " - " .. feedbackMsg .. " - " .. revealedPassword
        self.hackLabelHistory:setName(historyPassword)
        self.hackLabelAttempts:setName("Attempt number: ".. self.triesCount .." / ".. self.maxTries - 1)
    end
end

function hackingUI:hackTransfert()
    hackZombieName = nil
    self.hackTransfertButton:setVisible(false)
    self.titleLabelPlayer = ISLabel:new(self.width * 0.20, self.height * 0.59, self.height * 0.025,"Bank balance: $" .. tostring(loadAtmBalance()) .. " < $" .. tostring(hackingBankBalance), 0, 1, 0, 1, UIFont.Small, true)
    self.titleLabelPlayer.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabelPlayer:setVisible(true)
    self.titleLabelPlayer:initialise()
    self.topBar:addChild(self.titleLabelPlayer)

    self.hackingCoroutine = coroutine.create(function()
        local playerBankBalance = tonumber(loadAtmBalance())
        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local initialDelay = elapsed + 1
        
        while hackingBankBalance > 0 do
            local chunk = 1

            if hackingBankBalance >= 1000 then
                chunk = 1000
            elseif hackingBankBalance >= 100 then
                chunk = 100
            elseif hackingBankBalance >= 10 then
                chunk = 10
            end

            hackingBankBalance = hackingBankBalance - chunk
            playerBankBalance = playerBankBalance + chunk
            saveAtmBalance(playerBankBalance)

            self.titleLabelPlayer:setName("Bank balance: $" .. tostring(loadAtmBalance()) .. " < $" .. tostring(hackingBankBalance) .. "\nTransfer in progress...")
            local lineDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(1, 5)
            while elapsed < lineDelay do
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end
    end)

    self.updateCoroutineFunc = function()
        if coroutine.status(self.hackingCoroutine) ~= "dead" then
            local ok, err = coroutine.resume(self.hackingCoroutine)
            if not ok then
                Events.OnTick.Remove(self.updateCoroutineFunc)
            end
        else

            Events.OnTick.Remove(self.updateCoroutineFunc)
            self.updateCoroutineFunc = nil
            self.hackingCoroutine = nil
            self.titleLabelPlayer:setName("Bank balance: $" .. tostring(loadAtmBalance()) .. " < $" .. tostring(hackingBankBalance) .. "\nTransfer completed")
            self.hackLabelTitle:setName("Hack Balance: $0\n")
        end
    end

    Events.OnTick.Add(self.updateCoroutineFunc)
end

function hackingUI:hackNext()
    local playerObj = getPlayer()
    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        local modData = getPlayer():getModData()
        if item:getFullType() == "Base.IDcard" 
        or item:getFullType() == "Base.IDcard_Stolen" 
        or item:getFullType() == "Base.IDcard_Female"
        or item:getFullType() == "Base.IDcard_Male"
        or item:getFullType() == "Base.CreditCard"
        or item:getFullType() == "Base.CreditCard_Stolen" then
            hackZombieName = item:getName()
            inventory:Remove(item)
            if hackZombieName then
                self.hackNextButton:setVisible(false)
                self.triesCount = 0
                self.hackLabel:setName("")
                self.hackLabelHistory:setName("")
                self.hackLabelTitle:setName("")
                self.hackLabelAttempts:setName("")
                self.hackLabelTitle:setName("")
                self.promptCommand:setText("")
                self.promptCommand:focus()
                if self.hackTransfertButton then self.hackTransfertButton:setVisible(false) end
                if self.titleLabelPlayer then self.titleLabelPlayer:setName("") end
                self:onHack()
            end
            break
        end
    end
end

function hackingMenu_ShowUI(player)
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

    local ui = hackingUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
    ui:onIdCard()

    return ui
end
