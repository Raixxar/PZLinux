PZLinuxContractDialogue = PZLinuxContractDialogue or {}

function PZLinuxContractDialogue.getText(key, fallback)
    if getText then
        local translated = getText(key)
        if translated and translated ~= key then
            return translated
        end
    end
    return fallback
end

function PZLinuxContractDialogue.create(self, contractId, contractsCompanyCodes, contractsCompanyReward)
    local playerObj = PZLinuxGetPlayer(self.player)
    local modData = playerObj:getModData()
    local sleepSFX = 1
    if modData.PZLinuxUISFX == 0 then sleepSFX = 0.1 end

    local preview = self.contractPreview or {}
    local companyCode = tostring(preview.code or contractsCompanyCodes[contractId] or "")
    local reward = tonumber(preview.reward)
        or tonumber(contractsCompanyReward[contractId])
        or tonumber(modData.PZLinuxOnReward)
        or 0
    modData.PZLinuxOnReward = reward
    modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. companyCode

    return {
        contractId = contractId,
        playerObj = playerObj,
        modData = modData,
        globalVolume = getCore():getOptionSoundVolume() / 50,
        playerName = generatePseudo(string.lower(playerObj:getUsername())),
        sellerName = "<" .. companyCode .. "> ",
        reward = reward,
        message = nil,
        sleepSFX = sleepSFX,
        elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600),
    }
end

function PZLinuxContractDialogue.wait(self, dialogue, minDelay, maxDelay)
    local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(minDelay or 20, maxDelay or 100) * dialogue.sleepSFX
    while dialogue.elapsed < letterDelay do
        if self.isClosing then return false end
        coroutine.yield()
        dialogue.elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
    end
    return not self.isClosing
end

function PZLinuxContractDialogue.notify(dialogue)
    getSoundManager():PlayWorldSound("ircNotification", false, dialogue.playerObj:getSquare(), 0, 20, 1, true):setVolume(dialogue.globalVolume)
end

function PZLinuxContractDialogue.setSellerLine(self, dialogue, text, playSound)
    if playSound then
        PZLinuxContractDialogue.notify(dialogue)
    end
    dialogue.message = dialogue.sellerName .. text
    self.loadingMessage:setName(dialogue.message)
end

function PZLinuxContractDialogue.appendSellerLine(self, dialogue, text, playSound)
    if playSound then
        PZLinuxContractDialogue.notify(dialogue)
    end
    dialogue.message = dialogue.message .. "\n" .. dialogue.sellerName .. text
    self.loadingMessage:setName(dialogue.message)
end

function PZLinuxContractDialogue.ask(self, dialogue, text, typeText)
    typeText(self.typingMessage, text, function()
        dialogue.message = dialogue.message .. "\n" .. dialogue.playerName .. text
        self.loadingMessage:setName(dialogue.message)
        self.typingMessage:setName("")
    end)
end

function PZLinuxContractDialogue.addChoiceButtons(self, contractId)
    self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
    self.yesButton.contractId = contractId
    self.yesButton:initialise()
    self.yesButton:instantiate()
    self.topBar:addChild(self.yesButton)

    self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
    self.noButton:initialise()
    self.noButton:instantiate()
    self.topBar:addChild(self.noButton)
end
