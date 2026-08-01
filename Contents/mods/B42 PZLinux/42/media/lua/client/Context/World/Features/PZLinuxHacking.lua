hackingUI = ISPanel:derive("hackingUI")

local hackingBankBalance = 0
local historyPassword = ""
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

    function self.topBar:onMouseDown(_x, _y)
        self.parent.isDragging = true
        self.parent.initialX = self.parent:getX()
        self.parent.initialY = self.parent:getY()
        self.parent.mouseStartX = getMouseX()
        self.parent.mouseStartY = getMouseY()
    end

    function self.topBar:onMouseMove(_x, _y)
        if self.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - self.parent.mouseStartX
            local dy = curMouseY - self.parent.mouseStartY
            self.parent:setX(self.parent.initialX + dx)
            self.parent:setY(self.parent.initialY + dy)
        end
    end

    function self.topBar:onMouseUp(_x, _y)
        self.parent.isDragging = false
        local modData = PZLinuxGetModData(self.parent.player)
        if not modData then return end
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
function hackingUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUIOpenMenu = 1
end

-- LOGOUT
function hackingUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUIOpenMenu = 1
end

function hackingUI:onCloseX(_button)
    self.isClosing = true
    local player = PZLinuxGetPlayer(self.player)
    if player then
        player:StopAllActionQueue()
    end
end


-- ID CARD
function hackingUI:onIdCard()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    PZLinuxRequestHackingStart(playerObj, function(result)
        if not result or not result.ok then
            self:showNoCardError()
            return
        end

        hackZombieName = result.cardName
        hackingBankBalance = tonumber(result.amount) or 0
        self.passwordLength = tonumber(result.passwordLength) or 4
        self.maxTries = tonumber(result.maxTries) or 6
        self:startBootSequence()
    end)
end

function hackingUI:showNoCardError()
    self.hackLabelTitleError = ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.025, "No ID Card or Credit Card...", 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelTitleError.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitleError.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitleError:setVisible(true)
    self.hackLabelTitleError:initialise()
    self.topBar:addChild(self.hackLabelTitleError)
end

function hackingUI:startBootSequence()
    self.bootOutput = ISRichTextPanel:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.45)
    self.bootOutput.backgroundColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.borderColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.autosetheight = false
    self.bootOutput:setVisible(true)
    self.bootOutput:initialise()
    self.topBar:addChild(self.bootOutput)

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
    self.terminalCoroutine = coroutine.create(function()
        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)

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
end

function hackingUI:onHack()
    historyPassword = ""
    self.bootOutput:setVisible(false)
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    self.triesCount = 0
    self.maxTries = self.maxTries or 6
    local passwordLength = self.passwordLength or 4
    local hiddenPassword = string.rep("*", passwordLength)
    local hackLabelTitle = tostring(hackZombieName) .. " Bank Balance: $" .. hackingBankBalance .. "\nFind the password in " .. passwordLength .. " numbers.\n"
    self.hackLabelTitle = ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.025, hackLabelTitle, 0, 1, 0, 1, UIFont.Small, true)
    self.hackLabelTitle.backgroundColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitle.borderColor = {r=0, g=0, b=0, a=0}
    self.hackLabelTitle:setVisible(true)
    self.hackLabelTitle:initialise()
    self.topBar:addChild(self.hackLabelTitle)

    self.hackLabel = ISLabel:new(self.width * 0.20, self.height * 0.24, self.height * 0.025, hiddenPassword, 0, 1, 0, 1, UIFont.Small, true)
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
    self.promptCommand.onCommandEntered = function(_entry) self:onCommandEnter() end
    self.promptCommand:setVisible(false)
    self.promptCommand:initialise()
    self.promptCommand:instantiate()
    self.promptCommand:setOnlyNumbers(true)
    self.promptCommand.onTextChange = function(entry)
        local text = entry:getText()
        if #text > passwordLength then
            entry:setText(text:sub(1, passwordLength))
        end
    end

    self.topBar:addChild(self.promptCommand)

    self.hackAutoButton = ISButton:new(self.width * 0.41, self.height * 0.419, self.width * 0.05, self.height * 0.025, "AUTO", self, self.hackAuto)
    self.hackAutoButton:setVisible(true)
    self.hackAutoButton:initialise()
    self.topBar:addChild(self.hackAutoButton)

    self.promptCommand:setVisible(true)
    self.promptCommand:setText("")
    self.promptCommand:focus()
end

function hackingUI:onCommandEnter()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    player:getStats():add(CharacterStat.BOREDOM, -2)
    local globalVolume = getCore():getOptionSoundVolume() / 50
    local commandText = self.promptCommand:getText()

    local passwordLength = self.passwordLength or 4
    if #commandText ~= passwordLength then
        getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        return
    end

    PZLinuxRequestHackingGuess(player, commandText, function(result)
        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            if result and result.error == "account_locked" then
                self.hackLabelAttempts:setName("Account locked")
            end
            return
        end

        local revealedPassword = result.revealedPassword or string.rep("*", passwordLength)
        self.hackLabel:setName(revealedPassword)
        hackingBankBalance = tonumber(result.amount) or hackingBankBalance
        self.triesCount = tonumber(result.tries) or self.triesCount
        self.maxTries = tonumber(result.maxTries) or self.maxTries

        if result.unlocked then
            self.hackLabelAttempts:setName("Account unlocked")
            getSoundManager():PlayWorldSound("buy", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            self.hackTransfertButton = ISButton:new(self.width * 0.20, self.height * 0.52, self.width * 0.05, self.height * 0.025, "TRANSFER", self, self.hackTransfert)
            self.hackTransfertButton:setVisible(true)
            self.hackTransfertButton:initialise()
            self.topBar:addChild(self.hackTransfertButton)

            self.hackAutoButton:setVisible(false)
            self.hackNextButton = ISButton:new(self.width * 0.20, self.height * 0.55, self.width * 0.05, self.height * 0.025, "NEXT", self, self.hackNext)
            self.hackNextButton:setVisible(true)
            self.hackNextButton:initialise()
            self.topBar:addChild(self.hackNextButton)
            return
        end

        if result.locked then
            self.hackLabelAttempts:setName("Account locked")
            self.hackAutoButton:setVisible(false)
            getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            self.hackNextButton = ISButton:new(self.width * 0.20, self.height * 0.55, self.width * 0.05, self.height * 0.025, "NEXT", self, self.hackNext)
            self.hackNextButton:setVisible(true)
            self.hackNextButton:initialise()
            self.topBar:addChild(self.hackNextButton)
            return
        end

        local correctCount = tonumber(result.correctCount) or 0
        local misplacedCount = tonumber(result.misplacedCount) or 0
        local feedbackMsg = "No digit is present in the code"
        if correctCount > 0 and misplacedCount > 0 then
            feedbackMsg = correctCount .. " digit(s) are correctly placed, " .. misplacedCount .. " digit(s) are misplaced"
        elseif correctCount > 0 then
            feedbackMsg = correctCount .. " digit(s) are correctly placed"
        elseif misplacedCount > 0 then
            feedbackMsg = misplacedCount .. " digit(s) are misplaced"
        end

        getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        self.promptCommand:setText("")
        historyPassword = historyPassword .. "\n" .. commandText .. " - " .. feedbackMsg .. " - " .. revealedPassword
        self.hackLabelHistory:setName(historyPassword)
        self.hackLabelAttempts:setName("Attempt number: " .. tostring(self.triesCount) .. " / " .. tostring(self.maxTries))
    end)
end

function hackingUI:hackTransfert()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    hackZombieName = nil
    self.hackTransfertButton:setVisible(false)
    self.titleLabelPlayer = ISLabel:new(self.width * 0.20, self.height * 0.59, self.height * 0.025,"Bank balance: $" .. tostring(loadAtmBalance(player)) .. " < $" .. tostring(hackingBankBalance), 0, 1, 0, 1, UIFont.Small, true)
    self.titleLabelPlayer.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabelPlayer:setVisible(true)
    self.titleLabelPlayer:initialise()
    self.topBar:addChild(self.titleLabelPlayer)

    if hackingBankBalance >= 5000 then
        player:getStats():add(CharacterStat.UNHAPPINESS, -10)
        player:getStats():add(CharacterStat.STRESS, -0.5)
    elseif hackingBankBalance >= 1000 then
        player:getStats():add(CharacterStat.UNHAPPINESS, -5)
        player:getStats():add(CharacterStat.STRESS, -0.1)
    else
        player:getStats():add(CharacterStat.UNHAPPINESS, -2)
        player:getStats():add(CharacterStat.STRESS, -0.05)
    end

    PZLinuxRequestHackingTransfer(player, function(result)
        if not result or not result.ok then
            HaloTextHelper.addBadText(player, "Transfer rejected")
            return
        end

        local targetBalance = tonumber(result.balance) or loadAtmBalance(player)
        local creditedAmount = tonumber(result.hackedAmount or result.amount) or hackingBankBalance
        saveAtmBalance(targetBalance, player)
        hackingBankBalance = creditedAmount

        self.hackingCoroutine = coroutine.create(function()
            local playerBankBalance = targetBalance - creditedAmount
            if playerBankBalance < 0 then playerBankBalance = 0 end
            local remainingBalance = creditedAmount
            local displayedBankBalance = playerBankBalance
            local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)

            while remainingBalance > 0 do
                local chunk = 1

                if remainingBalance >= 1000 then
                    chunk = 1000
                elseif remainingBalance >= 100 then
                    chunk = 100
                elseif remainingBalance >= 10 then
                    chunk = 10
                end

                remainingBalance = remainingBalance - chunk
                displayedBankBalance = displayedBankBalance + chunk
                hackingBankBalance = remainingBalance

                self.titleLabelPlayer:setName("Bank balance: $" .. tostring(displayedBankBalance) .. " < $" .. tostring(remainingBalance) .. "\nTransfer in progress...")
                local lineDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(1, 5)
                while elapsed < lineDelay do
                    coroutine.yield()
                    elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
                end
            end
        end)

        self.updateCoroutineFunc = function()
            if coroutine.status(self.hackingCoroutine) ~= "dead" then
                local ok = coroutine.resume(self.hackingCoroutine)
                if not ok then
                    Events.OnTick.Remove(self.updateCoroutineFunc)
                end
            else
                Events.OnTick.Remove(self.updateCoroutineFunc)
                self.updateCoroutineFunc = nil
                self.hackingCoroutine = nil
                hackingBankBalance = 0
                self.titleLabelPlayer:setName("Bank balance: $" .. tostring(targetBalance) .. " < $0\nTransfer completed")
                self.hackLabelTitle:setName("Hack Balance: $0\n")
            end
        end

        Events.OnTick.Add(self.updateCoroutineFunc)
    end)
end

function hackingUI:hackAuto()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    PZLinuxRequestHackingAuto(player, function(result)
        if not result or not result.ok then
            HaloTextHelper.addBadText(player, "No ID Card or Credit Card...");
            return
        end

        hackingBankBalance = tonumber(result.amount) or 0
        self.hackTransfertButton = ISButton:new(self.width * 0.20, self.height * 0.52, self.width * 0.05, self.height * 0.025, "TRANSFER", self, self.hackTransfert)
        self.hackTransfertButton:setVisible(true)
        self.hackTransfertButton:initialise()
        self.topBar:addChild(self.hackTransfertButton)

        local cardCount = tonumber(result.cardCount) or 0
        self.titleLabelAuto = ISLabel:new(self.width * 0.20, self.height * 0.45, self.height * 0.025,"Total money hacked. $" .. tostring(hackingBankBalance) .. " from " .. tostring(cardCount) .. " card(s)", 0, 1, 0, 1, UIFont.Small, true)
        self.titleLabelAuto.backgroundColor = {r=0, g=0, b=0, a=0}
        self.titleLabelAuto:setVisible(true)
        self.titleLabelAuto:initialise()
        self.topBar:addChild(self.titleLabelAuto)
    end)
end

function hackingUI:hackNext()
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    PZLinuxRequestHackingStart(playerObj, function(result)
        if not result or not result.ok then
            HaloTextHelper.addBadText(playerObj, "No ID Card or Credit Card...")
            return
        end

        hackZombieName = result.cardName
        hackingBankBalance = tonumber(result.amount) or 0
        self.passwordLength = tonumber(result.passwordLength) or 4
        self.maxTries = tonumber(result.maxTries) or 6
        if self.hackNextButton then self.hackNextButton:setVisible(false) end
        self.triesCount = 0
        self.hackLabel:setName("")
        self.hackLabelHistory:setName("")
        self.hackLabelTitle:setName("")
        self.hackLabelAttempts:setName("")
        self.promptCommand:setText("")
        self.promptCommand:focus()
        if self.hackTransfertButton then self.hackTransfertButton:setVisible(false) end
        if self.titleLabelPlayer then self.titleLabelPlayer:setName("") end
        self:onHack()
    end)
end

function hackingMenu_ShowUI(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

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

    local modData = playerObj:getModData()
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = hackingUI:new(uiX, uiY, finalW, finalH, playerObj)
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
