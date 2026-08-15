-- Contracts UI - by Raixxar
-- Updated : 25/02/25

contractsUI = ISPanel:derive("contractsUI")

local selectedContracts = {}

local contractsCompanyCodes = {}
local contractsCompanyReward = {}

local function PZLinuxContractsText(key, fallback, ...)
    return PZLinuxFormatText(key, fallback, ...)
end

-- A player reported that an Auto Parts contract's request didn't say
-- whether a Standard/Sport/Resistant part was needed. Confirmed root
-- cause: PZ's own vanilla display name for these items is IDENTICAL
-- across every quality tier of a given part -- e.g. Base.NormalSuspension1
-- /2/3 (the mod's own "Standard"/"Sport"/"Resistant" tiers) all translate
-- to the exact same "Suspension - Regular" (same for Base.CarBattery1/2/3
-- -> "Car Battery", Base.ModernBrake1/2/3 -> "Brake - Performance", etc.
-- -- see media/lua/shared/Translate/EN/ItemName.json). This function used
-- to try the vanilla, non-disambiguating name FIRST and only fall back to
-- the caller-provided name if that failed -- but it essentially never
-- fails (the vanilla item obviously exists), so the caller's own name
-- (fallback) -- which for every real caller (PZLinuxContractAutoPartRequests/
-- MedicalRequests/WeaponRequests, see PZLinuxContractMission.lua) is
-- always a curated, disambiguating name like "Standard suspension: Sport"
-- -- was never actually used, even though it exists specifically to solve
-- this. Now tried first instead, since it's always more precise than the
-- generic vanilla name whenever a caller bothers to provide one.
local function PZLinuxContractsLocalizedItemName(fullType, fallback)
    local itemType = tostring(fullType or "")
    if fallback and fallback ~= "" then return tostring(fallback) end

    local itemNameResolver = rawget(_G, "getItemNameFromFullType")
    if itemType ~= "" and itemNameResolver then
        local ok, translatedName = pcall(itemNameResolver, itemType)
        if ok and translatedName and translatedName ~= "" and translatedName ~= itemType then
            return translatedName
        end
    end

    if itemType ~= "" and getScriptManager then
        local scriptItem = getScriptManager():FindItem(itemType)
        local displayName = scriptItem and scriptItem:getDisplayName() or nil
        if displayName and displayName ~= "" then return displayName end
    end
    return itemType
end

local function PZLinuxContractsCompletionAmountText(receipt)
    local amount = math.max(0, math.floor(tonumber(
        receipt and (receipt.moneyEarned or receipt.amount)
    ) or 0))
    local label = PZLinuxContractsText(
        "IGUI_PZLinux_Contracts_CompletionAmount",
        "Total money earned: $%s"
    )
    label = label:gsub("%$[ \t]*%%s", "")
    label = label:gsub("%%s", "")
    label = label:gsub("%$[ \t]*%%1", "")
    label = label:gsub("%%1", "")
    label = label:gsub("[ \t]*%$[ \t]*$", "")
    label = label:gsub("[ \t]+$", "")
    return label .. " " .. tostring(amount) .. " $"
end

local function PZLinuxContractsFormatItemRequest(contractPreview)
    local count = math.max(0, tonumber(contractPreview.infoCount) or 0)
    local itemName = PZLinuxContractsLocalizedItemName(contractPreview.info, contractPreview.infoName)
    if count > 0 then return tostring(count) .. " " .. itemName end
    return itemName
end

local function PZLinuxContractsSetRichText(panel, message)
    if not panel then return end
    panel.text = "<RGB:0,1,0>" .. tostring(message or "")
    panel:paginate()

    local maxYScroll = math.max(0, panel:getScrollHeight() - panel:getHeight())
    if panel.vscroll then panel.vscroll:setVisible(maxYScroll > 0) end
    panel:setYScroll(-maxYScroll)
end

local function PZLinuxContractsCreateTextPanel(ui, x, y, width, height)
    local panel = ISRichTextPanel:new(x, y, width, height)
    panel.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.borderColor = {r=0, g=0, b=0, a=0}
    panel.autosetheight = false
    panel:setVisible(true)
    panel:initialise()
    panel:instantiate()
    function panel:setName(message)
        PZLinuxContractsSetRichText(self, message)
    end
    ui.topBar:addChild(panel)
    return panel
end

local function PZLinuxContractsShowCompletionReceipt(self, receipt)
    if not self or type(receipt) ~= "table" or not receipt.id then return false end
    if self.completionReceiptVisible
    and tostring(self.pendingCompletionReceiptId) == tostring(receipt.id) then
        return true
    end

    self.completionReceiptVisible = true
    self.pendingCompletionReceiptId = tostring(receipt.id)
    for _, contractButton in ipairs(self.contractButtons or {}) do
        contractButton:setVisible(false)
    end
    if self.activeContractMessage then self.activeContractMessage:setVisible(false) end
    if self.cancelContractButton then self.cancelContractButton:setVisible(false) end

    local lines = {
        PZLinuxContractsText(
            "IGUI_PZLinux_Contracts_CompletionPaid",
            "You have been paid for your contract."
        ),
        PZLinuxContractsCompletionAmountText(receipt),
    }
    if (tonumber(receipt.zombieCount) or 0) > 0 then
        table.insert(lines, PZLinuxContractsText(
            "IGUI_PZLinux_Contracts_CompletionZombies",
            "Total zombies killed: %s",
            tostring(receipt.zombieCount)
        ))
    end

    self.completeContractMessage = ISRichTextPanel:new(
        self.width * 0.20,
        self.height * 0.28,
        self.width * 0.57,
        self.height * 0.20
    )
    self.completeContractMessage.backgroundColor = {r=0, g=0, b=0, a=0}
    self.completeContractMessage.borderColor = {r=0, g=0, b=0, a=0}
    self.completeContractMessage.autosetheight = false
    -- ISRichTextPanel:paginate() tokenizes on spaces; a word glued directly
    -- to a following tag (e.g. "payé.<LINE>") gets swallowed by the tag's
    -- token and never rendered. A space on each side of <LINE> avoids that
    -- -- it's exactly what the engine itself inserts when converting "\n".
    self.completeContractMessage.text = "<RGB:0,1,0>" .. table.concat(lines, " <LINE> ")
    self.completeContractMessage:initialise()
    self.completeContractMessage:instantiate()
    self.completeContractMessage:paginate()
    self.topBar:addChild(self.completeContractMessage)

    self.completionReceiptButton = ISButton:new(
        self.width * 0.20,
        self.height * 0.52,
        self.width * 0.57,
        self.height * 0.05,
        PZLinuxContractsText(
            "IGUI_PZLinux_Contracts_ViewAvailable",
            "VIEW AVAILABLE CONTRACTS"
        ),
        self,
        self.onCompletionReceiptContinue
    )
    self.completionReceiptButton.textColor = {r=0, g=1, b=0, a=1}
    self.completionReceiptButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.completionReceiptButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.completionReceiptButton:initialise()
    self.topBar:addChild(self.completionReceiptButton)

    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then
        local globalVolume = getCore():getOptionSoundVolume() / 50
        getSoundManager():PlayWorldSound("sold", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    end
    return true
end

local function PZLinuxContractsStopDialogue(self)
    if self.contractDialogueRegistered and self.contractDialogueEvent and self.updateCoroutineFunc then
        self.contractDialogueEvent.Remove(self.updateCoroutineFunc)
    end
    self.contractDialogueRegistered = false
    self.contractDialogueEvent = nil
    self.updateCoroutineFunc = nil
    self.terminalCoroutine = nil
end

local function PZLinuxContractsFailDialogue(self, err)
    print("PZLinux contracts coroutine error:", tostring(err))
    if self.loadingMessage then
        self.loadingMessage:setName(PZLinuxContractsText(
            "IGUI_PZLinux_Contracts_PreviewError",
            "Contract unavailable (%s).",
            "dialogue_error"
        ))
    end
    PZLinuxContractsStopDialogue(self)
end

local function PZLinuxContractsApplyBoard(availableContracts)
    if type(availableContracts) ~= "table" then return end

    selectedContracts = {}
    contractsCompanyCodes = {}
    contractsCompanyReward = {}

    for _, contract in ipairs(availableContracts) do
        table.insert(selectedContracts, contract)
        contractsCompanyCodes[contract.id] = contract.code
        contractsCompanyReward[contract.id] = contract.reward
    end
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

function contractsUI:showContractsBoard()
    if self.completionReceiptVisible then return end
    local y = 0.20
    for _, contractButton in ipairs(self.contractButtons or {}) do
        self.topBar:removeChild(contractButton)
    end
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

function contractsUI:onCompletionReceiptContinue(button)
    if self.isClosing or self.completionReceiptAckPending then return end
    local receiptId = self.pendingCompletionReceiptId
    if not receiptId then return end

    self.completionReceiptAckPending = true
    if button and button.setEnable then button:setEnable(false) end
    PZLinuxRequestContractCompletionAck(self.player, receiptId, function(result)
        self.completionReceiptAckPending = false
        if self.isClosing then return end
        if not result or not result.ok then
            if button and button.setEnable then button:setEnable(true) end
            return
        end

        if self.completeContractMessage then
            self.topBar:removeChild(self.completeContractMessage)
            self.completeContractMessage = nil
        end
        if self.completionReceiptButton then
            self.topBar:removeChild(self.completionReceiptButton)
            self.completionReceiptButton = nil
        end
        self.completionReceiptVisible = false
        self.pendingCompletionReceiptId = nil

        PZLinuxRequestContractsBoard(self.player, function(boardResult)
            if self.isClosing or not boardResult or not boardResult.ok then return end
            if boardResult.balance then
                saveAtmBalance(boardResult.balance, self.player)
                self.titleLabel:setName(PZLinuxContractsText(
                    "IGUI_PZLinux_Request_Balance",
                    "Bank Balance: $%s",
                    tostring(boardResult.balance)
                ))
            end
            PZLinuxContractsApplyBoard(boardResult.contracts)
            self.contractsBoardReady = true
            self:showContractsBoard()
        end)
    end)
end

function contractsUI:showSynchronizedContractState(synchronizedState)
    if self.isClosing or self.contractStateRendered then return end
    self.contractStateRendered = true

    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end
    local modData = playerObj:getModData()
    local activeContract = tonumber(modData.PZLinuxActiveContract) or 0

    if synchronizedState and synchronizedState.balance then
        saveAtmBalance(synchronizedState.balance, self.player)
        self.titleLabel:setName(PZLinuxContractsText(
            "IGUI_PZLinux_Request_Balance",
            "Bank Balance: $%s",
            tostring(synchronizedState.balance)
        ))
    end
    if synchronizedState and PZLinuxContractsShowCompletionReceipt(
        self,
        synchronizedState.completionReceipt
    ) then
        return
    end

    if activeContract == 1 then
        local logging = ""
        if tonumber(modData.PZLinuxContractTypeId) == 1 then
            local zombieCount = tonumber(modData.PZLinuxOnZombieDead) or 0
            local zombieTarget = tonumber(modData.PZLinuxOnZombieToKill) or 0
            logging = "\nZombies killed: " .. tostring(zombieCount) .. " / " .. tostring(zombieTarget)
        end
        self.activeContractMessage = ISLabel:new(self.width * 0.20, self.height * 0.30, self.height * 0.025, "Contract already in progress" .. logging, 0, 1, 0, 1, UIFont.Small, true)
        self.activeContractMessage:setVisible(true)
        self.activeContractMessage:initialise()
        self.topBar:addChild(self.activeContractMessage)

        self.cancelContractButton = ISButton:new(self.width * 0.20, self.height * 0.20, self.width * 0.57, self.height * 0.05, "Cancel the contract", self, self.onCancelContract)
        self.cancelContractButton:setVisible(true)
        self.cancelContractButton:initialise()
        self.topBar:addChild(self.cancelContractButton)
        return
    end

    if activeContract == 9 or activeContract == 10 then
        self:onContractComplete()
        return
    end

    PZLinuxRequestContractsBoard(self.player, function(result)
        if self.isClosing or not result or not result.ok then return end
        if result.balance then
            saveAtmBalance(result.balance, self.player)
            self.titleLabel:setName(PZLinuxContractsText("IGUI_PZLinux_Request_Balance", "Bank Balance: $%s", tostring(result.balance)))
        end
        PZLinuxContractsApplyBoard(result.contracts)
        self.contractsBoardReady = true
        self:showContractsBoard()
    end)
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

    function self.topBar.onMouseDown(topBar, _x, _y)
        topBar.parent.isDragging = true
        PZLinuxTrackDragging(topBar.parent)
        topBar.parent.initialX = topBar.parent:getX()
        topBar.parent.initialY = topBar.parent:getY()
        topBar.parent.mouseStartX = getMouseX()
        topBar.parent.mouseStartY = getMouseY()
    end

    function self.topBar.onMouseMove(topBar, _x, _y)
        if topBar.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - topBar.parent.mouseStartX
            local dy = curMouseY - topBar.parent.mouseStartY
            topBar.parent:setX(topBar.parent.initialX + dx)
            topBar.parent:setY(topBar.parent.initialY + dy)
        end
    end

    function self.topBar.onMouseUp(topBar, _x, _y)
        topBar.parent.isDragging = false
        local modData = PZLinuxGetPlayer(topBar.parent.player):getModData()
        modData.PZLinuxUIX = topBar.parent:getX()
        modData.PZLinuxUIY = topBar.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, PZLinuxContractsText("IGUI_PZLinux_Request_Balance", "Bank Balance: $%s", tostring(loadAtmBalance())), 0, 1, 0, 1, UIFont.Small, true)
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

    self.contractStateRendered = false
    PZLinuxRequestContractSync(self.player, function(result)
        self:showSynchronizedContractState(result)
    end)
end

function contractsUI:onCancelContract(_button)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local modData = playerObj:getModData()

    if modData.PZLinuxContractLocationX and modData.PZLinuxContractLocationX > 0 then
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY)
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX + 20, modData.PZLinuxContractLocationY)
    end

    PZLinuxRequestContractCancel(self.player, function(result)
        if not result or not result.ok then return end
        self.isClosing = true
        self:removeFromUIManager()
        modData.PZLinuxUIOpenMenu = 7
    end)
end

function contractsUI:onSelectContract(button)
    for _, contractButton in ipairs(self.contractButtons) do
        contractButton:setVisible(false)
    end

    local modData = PZLinuxGetPlayer(self.player):getModData()
    if modData.PZLinuxActiveContract == nil then
        modData.PZLinuxActiveContract = 0
    end

    if modData.PZLinuxActiveContract == 1 then
        local playerObj = PZLinuxGetPlayer(self.player)
        local globalVolume = getCore():getOptionSoundVolume() / 50
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        return
    end

    if modData.PZLinuxActiveContract == 10 then
        self:onContractComplete()
        return
    end
    if self.previewErrorMessage then
        self.previewErrorMessage:setName("")
    end
    self:onContractId(button.contractId)
end

-- PZLinuxContractsApplyComplete is already safe against being entered
-- twice for the same contract on its own (it atomically resets
-- PZLinuxActiveContract before returning, in the same synchronous call --
-- no window for a second call to see the old, still-completable state).
-- This guard is pure hygiene/consistency with the rest of the mod's
-- money-moving actions (Trading, Buy Goods, etc. all guard their own
-- button), not a fix for a proven double-payout.
function contractsUI:onContractComplete()
    if self.contractCompleteInProgress then return end
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local modData = playerObj:getModData()

    if modData.PZLinuxContractLocationX and modData.PZLinuxContractLocationX > 0 then
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX, modData.PZLinuxContractLocationY)
        contractsRemoveDrawOnMap(modData.PZLinuxContractLocationX + 20, modData.PZLinuxContractLocationY)
    end

    self.contractCompleteInProgress = true
    PZLinuxRequestContractComplete(self.player, function(result)
        self.contractCompleteInProgress = false
        if self.isClosing or not result or not result.ok then return end

        saveAtmBalance(result.balance, playerObj)
        self.titleLabel:setName(PZLinuxContractsText("IGUI_PZLinux_Request_Balance", "Bank Balance: $%s", tostring(result.balance)))

        PZLinuxContractsShowCompletionReceipt(self, result.completionReceipt or result)
    end)
end

function contractsUI:onContractId(contract)
    PZLinuxRequestContractPreview(self.player, contract, function(preview)
        if self.isClosing then return end
        if not preview or not preview.ok then
            local errorCode = tostring(preview and preview.error or "no_response")
            print("PZLinux contract preview error:", errorCode, "contract:", tostring(contract))
            for _, contractButton in ipairs(self.contractButtons or {}) do
                contractButton:setVisible(true)
            end
            if not self.previewErrorMessage then
                self.previewErrorMessage = ISLabel:new(
                    self.width * 0.20,
                    self.height * 0.72,
                    self.height * 0.025,
                    "",
                    1,
                    0.7,
                    0,
                    1,
                    UIFont.Small,
                    true
                )
                self.previewErrorMessage:initialise()
                self.topBar:addChild(self.previewErrorMessage)
            end
            self.previewErrorMessage:setName(PZLinuxContractsText(
                "IGUI_PZLinux_Contracts_PreviewError",
                "Contract unavailable (%s).",
                errorCode
            ))
            return
        end
        self:onContractPreview(contract, preview)
    end)
end

function contractsUI:onContractPreview(contract, contractPreview)
    self.minimizeBackButton:setVisible(true)
    self.minimizeButton:setVisible(false)
    self.contractPreview = contractPreview

    local uiModData = PZLinuxGetPlayer(self.player):getModData()
    contractsCompanyCodes[contract] = contractPreview.code
    contractsCompanyReward[contract] = tonumber(contractPreview.reward) or 0
    uiModData.PZLinuxOnReward = contractsCompanyReward[contract]
    uiModData.PZLinuxContractInfo = contractPreview.info or ""
    uiModData.PZLinuxContractInfoName = contractPreview.infoName or ""
    uiModData.PZLinuxContractInfoCount = tonumber(contractPreview.infoCount) or 0
    uiModData.PZLinuxContractLocationX = tonumber(contractPreview.locationX) or 0
    uiModData.PZLinuxContractLocationY = tonumber(contractPreview.locationY) or 0
    uiModData.PZLinuxContractLocationZ = tonumber(contractPreview.locationZ) or 0
    uiModData.PZLinuxContractTargetName = contractPreview.targetName or ""
    uiModData.PZLinuxOnZombieToKill = tonumber(contractPreview.zombieToKill) or 0

    local typingVolume = getCore():getOptionSoundVolume() / 50
    local player = PZLinuxGetPlayer(self.player)

    if not self.typingMessage then
        self.typingMessage = PZLinuxContractsCreateTextPanel(
            self,
            self.width * 0.20,
            self.height * 0.61,
            self.width * 0.57,
            self.height * 0.07
        )
    end

    if not self.loadingMessage then
        self.loadingMessage = PZLinuxContractsCreateTextPanel(
            self,
            self.width * 0.20,
            self.height * 0.25,
            self.width * 0.57,
            self.height * 0.34
        )
    end

    local function typeText(label, text, callback)
        if PZLinux.Typing.typeLabel(self, label, text, player, { volume = typingVolume }) and callback then
            callback()
        end
    end

    local function PZLinuxContractsCreateDialogue(contractId)
        local playerObj = PZLinuxGetPlayer(self.player)
        local modData = playerObj:getModData()
        local companyCode = tostring(contractPreview.code or contractsCompanyCodes[contractId] or "")
        local reward = tonumber(contractPreview.reward)
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

    local function PZLinuxContractsWaitDialogue(_dialogue)
        return PZLinux.Typing.waitProfile(self, "message")
    end

    local function PZLinuxContractsNotify(dialogue)
        getSoundManager():PlayWorldSound("ircNotification", false, dialogue.playerObj:getSquare(), 0, 20, 1, true):setVolume(dialogue.globalVolume)
    end

    local function PZLinuxContractsSetSellerLine(dialogue, text)
        dialogue.message = dialogue.sellerName .. text
        self.loadingMessage:setName(dialogue.message)
    end

    local function PZLinuxContractsAppendSellerLine(dialogue, text, playSound)
        if playSound then
            PZLinuxContractsNotify(dialogue)
        end
        dialogue.message = dialogue.message .. "\n" .. dialogue.sellerName .. text
        self.loadingMessage:setName(dialogue.message)
    end

    local function PZLinuxContractsAsk(dialogue, text)
        typeText(self.typingMessage, text, function()
            dialogue.message = dialogue.message .. "\n" .. dialogue.playerName .. text
            self.loadingMessage:setName(dialogue.message)
            self.typingMessage:setName("")
        end)
    end

    local function PZLinuxContractsApplyLocation(dialogue, poolName)
        if contractPreview.locationPool ~= poolName or not contractPreview.locationId or contractPreview.locationId == "" then
            self.loadingMessage:setName(dialogue.message .. "\n" .. dialogue.sellerName .. PZLinuxContractsText("IGUI_PZLinux_Contracts_NoB42Location", "No B42.20 location configured for this city yet."))
            return false
        end

        local questDescription = contractPreview.locationDescription or ""
        if contractPreview.locationDescriptionKey and contractPreview.locationDescriptionKey ~= "" and getText then
            local translated = getText(contractPreview.locationDescriptionKey)
            if translated and translated ~= contractPreview.locationDescriptionKey then
                questDescription = translated
            end
        end
        questDescription = questDescription .. " (" .. PZLinuxFormatFloorLabel(contractPreview.locationZ) .. ")"
        dialogue.message = dialogue.message .. "\n" .. dialogue.sellerName .. questDescription
        PZLinuxContractsNotify(dialogue)
        self.loadingMessage:setName(dialogue.message)
        return true
    end

    local function PZLinuxContractsAddChoiceButtons(contractId)
        self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.69, 80, 25, PZLinuxContractsText("IGUI_PZLinux_Request_Yes", "Yes"), self, self.onYesButton)
        self.yesButton.contractId = contractId
        self.yesButton:initialise()
        self.yesButton:instantiate()
        self.topBar:addChild(self.yesButton)

        self.noButton = ISButton:new(self.width * 0.50, self.height * 0.69, 80, 25, PZLinuxContractsText("IGUI_PZLinux_Request_No", "No"), self, self.onMinimizeBack)
        self.noButton:initialise()
        self.noButton:instantiate()
        self.topBar:addChild(self.noButton)
    end

    if contract == 1 then self.terminalCoroutine = PZLinux_Contract_KillZombie_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    elseif contract == 2 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_RetrievePackage_Intro", "We are looking for a courier to retrieve a package."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_RetrievePackage_AskLocation", "Where is the package exactly ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            if not PZLinuxContractsApplyLocation(dialogue, "packages") then return end

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_RetrievePackage_AskDelivery", "How do I give you the package ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_RetrievePackage_Delivery", "Put the package in a mailbox."), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 3 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_Intro", "We are looking for a hunter."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_AskTarget", "Who is the target ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_TargetIs", "The target is ") .. tostring(contractPreview.targetName or ""), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_AskLocation", "How do I find my target ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            if not PZLinuxContractsApplyLocation(dialogue, "manhunt") then return end

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_AskProof", "How can I prove to you that he is dead ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Manhunt_ProofDelivery", "Send us the corpse, or what remains of it, with a mailbox."), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)



    elseif contract == 4 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_BloodAnalysis_Intro", "We are looking for blood analyses of zombies."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 5 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AutoParts_Intro", "We are looking for someone to find auto parts for us."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AutoParts_AskParts", "Which auto parts do you need ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsFormatItemRequest(contractPreview), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 6 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_CaptureZombie_Intro", "We are looking for someone to capture a zombie alive."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 7 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Cargo_Intro", "We lost our cargo, we're looking for someone to retrieve it by helicopter."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Cargo_AskLocation", "Where is the cargo ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            if not PZLinuxContractsApplyLocation(dialogue, "cargo") then return end

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Cargo_Defense", "Prepare defenses, we will take the cargo by helicopter."), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 8 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Protect_Intro", "We have a building to protect against a horde of zombies."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Protect_AskLocation", "Where is the building ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            if not PZLinuxContractsApplyLocation(dialogue, "protect") then return end

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Protect_Defense", "Prepare defenses, there will be many zombies."), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 9 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Medical_Intro", "We are looking for medical equipment."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskExactRequest", "What exactly are you looking for ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsFormatItemRequest(contractPreview), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)


    elseif contract == 10 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Weapons_Intro", "We are looking for weapons."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskExactRequest", "What exactly are you looking for ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsFormatItemRequest(contractPreview), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)

    elseif contract == 13 then
        self.terminalCoroutine = coroutine.create(function()
            local dialogue = PZLinuxContractsCreateDialogue(contract)

            PZLinuxContractsSetSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AtmRefill_Intro", "One of our ATMs ran dry. We need someone to refill it."))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Protect_AskLocation", "Where is the building ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            if not PZLinuxContractsApplyLocation(dialogue, "atmRefill") then return end

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText(
                "IGUI_PZLinux_Contracts_AtmRefill_Amount",
                "You will need to withdraw $%s from your own account and carry it there.",
                tostring(contractPreview.atmAmount)
            ), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAsk(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"))

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, "$" .. tostring(dialogue.reward), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText(
                "IGUI_PZLinux_Contracts_AtmRefill_Refund",
                "Once deposited, the full amount is refunded to your account on top of the reward."
            ), true)

            if not PZLinuxContractsWaitDialogue(dialogue) then return end
            PZLinuxContractsAppendSellerLine(dialogue, PZLinuxContractsText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

            PZLinuxContractsAddChoiceButtons(contract)
        end)

    elseif contract == 11 then self.terminalCoroutine = PZLinux_Contract_SendComputer_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    elseif contract == 12 then self.terminalCoroutine = PZLinux_Contract_SendFridge_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    end

    if not self.terminalCoroutine then
        PZLinuxContractsFailDialogue(self, "unsupported contract id " .. tostring(contract))
        return
    end

    self.contractDialogueEvent = Events.OnTickEvenPaused or Events.OnTick
    self.contractDialogueRegistered = false
    self.updateCoroutineFunc = function()
        if not self.terminalCoroutine or coroutine.status(self.terminalCoroutine) == "dead" then
            PZLinuxContractsStopDialogue(self)
            return
        end

        local ok, err = coroutine.resume(self.terminalCoroutine)
        if not ok then
            PZLinuxContractsFailDialogue(self, err)
            return
        end

        if coroutine.status(self.terminalCoroutine) == "dead" then
            PZLinuxContractsStopDialogue(self)
        end
    end

    -- Prime the dialogue now so its first line never depends on a later game tick.
    self.updateCoroutineFunc()
    if self.updateCoroutineFunc and self.contractDialogueEvent then
        self.contractDialogueEvent.Add(self.updateCoroutineFunc)
        self.contractDialogueRegistered = true
    end
end

-- RESET ALL QUESTS
-- PZLinuxActiveContract = 0 Free
-- PZLinuxActiveContract = 1 Active
-- PZLinuxActiveContract = 2 Complete
function contractsUI:onYesButton(button)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end
    local contractId = tonumber(button.contractId)

    PZLinuxRequestContractAccept(self.player, contractId, function(result)
        if not result or not result.ok then
            if result and result.error == "insufficient_funds_for_contract" then
                HaloTextHelper.addBadText(playerObj, PZLinuxContractsText(
                    "IGUI_PZLinux_Contracts_InsufficientFunds",
                    "You need at least $%s in your bank account to accept this contract.",
                    tostring(tonumber(result.requiredAmount) or 0)
                ))
            end
            return
        end

        local updatedModData = playerObj:getModData()
        updatedModData.PZLinuxActiveContract = result.activeContract
        updatedModData.PZLinuxContractId = result.worldContractId
        updatedModData.PZLinuxContractTypeId = tonumber(result.contractId) or 0
        updatedModData.PZLinuxOnReward = result.reward
        updatedModData.PZLinuxContractLocationX = tonumber(result.locationX) or 0
        updatedModData.PZLinuxContractLocationY = tonumber(result.locationY) or 0
        updatedModData.PZLinuxContractLocationZ = tonumber(result.locationZ) or 0
        updatedModData.PZLinuxContractInfo = result.info or ""
        updatedModData.PZLinuxContractInfoName = result.infoName or ""
        updatedModData.PZLinuxContractInfoCount = tonumber(result.infoCount) or 0
        updatedModData.PZLinuxContractTargetName = result.targetName or ""
        updatedModData.PZLinuxOnZombieToKill = tonumber(result.zombieToKill) or 0
        updatedModData.PZLinuxContractNote = result.note or ""
        updatedModData.PZLinuxContractKillZombie = tonumber(result.contractKillZombie) or 0
        updatedModData.PZLinuxContractPickUp = tonumber(result.contractPickUp) or 0
        updatedModData.PZLinuxContractManhunt = tonumber(result.contractManhunt) or 0
        updatedModData.PZLinuxContractBlood = tonumber(result.contractBlood) or 0
        updatedModData.PZLinuxContractCar = tonumber(result.contractCar) or 0
        updatedModData.PZLinuxContractCapture = tonumber(result.contractCapture) or 0
        updatedModData.PZLinuxContractCargo = tonumber(result.contractCargo) or 0
        updatedModData.PZLinuxContractProtect = tonumber(result.contractProtect) or 0
        updatedModData.PZLinuxContractMedical = tonumber(result.contractMedical) or 0
        updatedModData.PZLinuxContractWeapon = tonumber(result.contractWeapon) or 0
        updatedModData.PZLinuxContractSendComputer = tonumber(result.contractSendComputer) or 0
        updatedModData.PZLinuxContractSendFridge = tonumber(result.contractSendFridge) or 0
        updatedModData.PZLinuxContractAtmRefill = tonumber(result.contractAtmRefill) or 0
        updatedModData.PZLinuxContractAtmAmount = tonumber(result.atmAmount) or 0

        if updatedModData.PZLinuxContractLocationX and updatedModData.PZLinuxContractLocationX > 0 then
            contractsDrawOnMap(updatedModData.PZLinuxContractLocationX, updatedModData.PZLinuxContractLocationY, updatedModData.PZLinuxContractNote)
        end

        self.isClosing = true
        self:removeFromUIManager()
        updatedModData.PZLinuxUIOpenMenu = 7
    end)
end

-- LOGOUT
function contractsUI:onMinimizeBack(_button)
    self.isClosing = true
    PZLinuxContractsStopDialogue(self)
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 7
end

function contractsUI:onMinimize(_button)
    self.isClosing = true
    PZLinuxContractsStopDialogue(self)
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function contractsUI:onClose(_button)
    self.isClosing = true
    PZLinuxContractsStopDialogue(self)
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- CLOSE
function contractsUI:onCloseX(_button)
    self.isClosing = true
    PZLinuxContractsStopDialogue(self)
    PZLinuxGetPlayer(self.player):StopAllActionQueue()
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

    local modData = PZLinuxGetPlayer(player):getModData()
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
