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
        playerName = PZLinuxFormatIRCName(generatePseudo(string.lower(playerObj:getUsername()))),
        sellerName = PZLinuxFormatIRCName(companyCode),
        reward = reward,
        message = nil,
    }
end

function PZLinuxContractDialogue.wait(self)
    return PZLinux.Typing.waitProfile(self, "message")
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
    local yesText = PZLinuxContractDialogue.getText("IGUI_PZLinux_Request_Yes", "Yes")
    local noText = PZLinuxContractDialogue.getText("IGUI_PZLinux_Request_No", "No")
    self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.69, 80, 25, yesText, self, self.onYesButton)
    self.yesButton.contractId = contractId
    self.yesButton:initialise()
    self.yesButton:instantiate()
    self.topBar:addChild(self.yesButton)

    self.noButton = ISButton:new(self.width * 0.50, self.height * 0.69, 80, 25, noText, self, self.onMinimizeBack)
    self.noButton:initialise()
    self.noButton:instantiate()
    self.topBar:addChild(self.noButton)
end
