function PZLinux_Contract_SendComputer_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    return coroutine.create(function()
        local modData = getPlayer():getModData()
        local globalVolume = getCore():getOptionSoundVolume() / 50
        local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
        local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "
        modData.PZLinuxOnReward = contractsCompanyReward[contract]
        modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
        local message = ""

        local sleepSFX = 1
        if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = sellerName .. "We are looking for a computer."
        self.loadingMessage:setName(message)
        modData.PZLinuxContractInfoCount = 1

        if not PZLinuxUtils_waitSeconds(200, 100, sleepSFX, self) then return end

        typeText(self.typingMessage, "What is the reward for this mission ?", function()
            message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)

        if not PZLinuxUtils_waitSeconds(200, 100, sleepSFX, self) then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
        self.loadingMessage:setName(message)

        if not PZLinuxUtils_waitSeconds(200, 100, sleepSFX, self) then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
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