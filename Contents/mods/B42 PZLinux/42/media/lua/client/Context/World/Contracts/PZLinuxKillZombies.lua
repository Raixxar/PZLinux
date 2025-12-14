function PZLinux_Contract_KillZombie_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    return coroutine.create(function()
        local ZtoKill = tostring(ZombRand(1, 6) * 10)
        local modData = getPlayer():getModData()
        modData.PZLinuxOnZombieToKill = ZtoKill

        local globalVolume = getCore():getOptionSoundVolume() / 50
        local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
        local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

        modData.PZLinuxOnReward = contractsCompanyReward[contract] + ZtoKill * 100
        modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]

        local message = ""

        local sleepSFX = 1
        if modData.PZLinuxUISFX == 0 then sleepSFX = 0.1 end

        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)

        local function waitRand(min, max)
            local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(min, max) * sleepSFX
            while elapsed < letterDelay do
                if self.isClosing then return end
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end

        waitRand(20, 100)
        if self.isClosing then return end

        message = sellerName .. "We are looking for a mercenary to clean the streets of our city."
        self.loadingMessage:setName(message)

        waitRand(20, 100)
        if self.isClosing then return end

        typeText(self.typingMessage, "How many zombies do you need to kill ?", function()
            message = message .. "\n" .. playerName .. "How many zombies do you need to kill ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)

        waitRand(20, 100)
        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. modData.PZLinuxOnZombieToKill
        self.loadingMessage:setName(message)

        waitRand(20, 100)
        if self.isClosing then return end

        typeText(self.typingMessage, "What is the reward for this mission ?", function()
            message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)

        waitRand(20, 100)
        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward
        self.loadingMessage:setName(message)

        waitRand(20, 100)
        if self.isClosing then return end

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
