-- Online betting UI - by Raixxar
-- Updated for PZLinux 1.0.0 MP-safe betting flow.

PZLinuxBettingUI = ISPanel:derive("PZLinuxBettingUI")
bettingUI = PZLinuxBettingUI

local function PZLinuxBettingGetPlayer(self)
    return PZLinuxGetPlayer(self.player)
end

local function PZLinuxBettingGetModData(self)
    return PZLinuxGetModData(self.player)
end

local function PZLinuxBettingPlaySound(self, soundName)
    local playerObj = PZLinuxBettingGetPlayer(self)
    if not playerObj then return end

    local globalVolume = getCore():getOptionSoundVolume() / 50
    getSoundManager():PlayWorldSound(soundName, false, playerObj:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
end

local function PZLinuxBettingSetVisible(controls, visible)
    for _, control in ipairs(controls or {}) do
        if control then
            control:setVisible(visible)
        end
    end
end

local function PZLinuxBettingHide(controls)
    PZLinuxBettingSetVisible(controls, false)
end

local function PZLinuxBettingFormatCard(card)
    if not card or card.hidden then return "Hidden" end

    local rank = card.rank
    local suit = card.suit
    if (not rank or not suit) and card.label then
        if card.label:sub(1, 2) == "10" then
            rank = "10"
            suit = card.label:sub(3, 3)
        else
            rank = card.label:sub(1, 1)
            suit = card.label:sub(2, 2)
        end
    end

    local ranks = { T = "10", J = "Jack", Q = "Queen", K = "King", A = "Ace" }
    local suits = { C = "Clubs", D = "Diamonds", H = "Hearts", S = "Spades" }
    return (ranks[rank] or rank or "?") .. " " .. (suits[suit] or suit or "?")
end

local function PZLinuxBettingFormatCards(cards)
    local labels = {}
    for _, card in ipairs(cards or {}) do
        table.insert(labels, PZLinuxBettingFormatCard(card))
    end
    return table.concat(labels, " ")
end

local function PZLinuxBettingAddMood(playerObj, stat, amount)
    if not playerObj or not playerObj.getStats or not CharacterStat then
        return
    end

    local statType = nil
    if stat == "BOREDOM" then
        statType = CharacterStat.BOREDOM
    elseif stat == "UNHAPPINESS" then
        statType = CharacterStat.UNHAPPINESS
    elseif stat == "STRESS" then
        statType = CharacterStat.STRESS
    end

    if statType then
        playerObj:getStats():add(statType, amount)
    end
end

local function PZLinuxBettingApplyStakeMood(playerObj, amount, previousBalance)
    amount = tonumber(amount) or 0
    previousBalance = math.max(tonumber(previousBalance) or 0, 1)

    PZLinuxBettingAddMood(playerObj, "BOREDOM", -2)

    local ratio = amount / previousBalance
    if ratio >= 0.50 and amount >= 1000 then
        PZLinuxBettingAddMood(playerObj, "STRESS", 0.25)
    elseif ratio >= 0.25 and amount >= 500 then
        PZLinuxBettingAddMood(playerObj, "STRESS", 0.10)
    end
end

local function PZLinuxBettingApplyOutcomeMood(playerObj, amount, previousBalance, payout, outcome)
    amount = tonumber(amount) or 0
    payout = tonumber(payout) or 0
    previousBalance = math.max(tonumber(previousBalance) or 0, 1)

    local stakeRatio = amount / previousBalance
    local winRatio = payout / previousBalance

    if outcome == "win" or outcome == "blackjack" then
        if winRatio >= 0.50 and payout >= 1000 then
            PZLinuxBettingAddMood(playerObj, "UNHAPPINESS", -10)
            PZLinuxBettingAddMood(playerObj, "STRESS", -0.20)
        elseif winRatio >= 0.25 and payout >= 500 then
            PZLinuxBettingAddMood(playerObj, "UNHAPPINESS", -5)
            PZLinuxBettingAddMood(playerObj, "STRESS", -0.10)
        else
            PZLinuxBettingAddMood(playerObj, "UNHAPPINESS", -2)
            PZLinuxBettingAddMood(playerObj, "STRESS", -0.05)
        end
    elseif outcome == "push" then
        PZLinuxBettingAddMood(playerObj, "BOREDOM", -1)
    elseif stakeRatio >= 0.50 and amount >= 1000 then
        PZLinuxBettingAddMood(playerObj, "UNHAPPINESS", 5)
        PZLinuxBettingAddMood(playerObj, "STRESS", 0.15)
    elseif stakeRatio >= 0.25 and amount >= 500 then
        PZLinuxBettingAddMood(playerObj, "UNHAPPINESS", 2)
        PZLinuxBettingAddMood(playerObj, "STRESS", 0.05)
    end
end

function PZLinuxBettingUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    o.isDragging = false
    o.gameButtons = {}
    o.raceControls = {}
    o.blackjackControls = {}
    o.pokerControls = {}
    o.blackjackStakeMoodApplied = false
    return o
end

function PZLinuxBettingUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar.onMouseDown(topBar, _x, _y)
        topBar.parent.isDragging = true
        topBar.parent.initialX = topBar.parent:getX()
        topBar.parent.initialY = topBar.parent:getY()
        topBar.parent.mouseStartX = getMouseX()
        topBar.parent.mouseStartY = getMouseY()
    end

    function self.topBar.onMouseMove(topBar, _x, _y)
        if topBar.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            topBar.parent:setX(topBar.parent.initialX + curMouseX - topBar.parent.mouseStartX)
            topBar.parent:setY(topBar.parent.initialY + curMouseY - topBar.parent.mouseStartY)
        end
    end

    function self.topBar.onMouseUp(topBar, _x, _y)
        topBar.parent.isDragging = false
        local modData = PZLinuxBettingGetModData(topBar.parent)
        if modData then
            modData.PZLinuxUIX = topBar.parent:getX()
            modData.PZLinuxUIY = topBar.parent:getY()
        end
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.titleLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    local modData = PZLinuxBettingGetModData(self) or {}
    if modData.PZLinuxUISFX == 0 then
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
        self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
    else
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
        self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
    end
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)

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

    self:showHub()
    PZLinuxRequestBankSync(self.player, function(result)
        if self.isClosing then return end
        self:updateBalanceLabel(result.balance)
    end)
end

function PZLinuxBettingUI:updateBalanceLabel(balance)
    self.balance = tonumber(balance) or PZLinuxLoadBankBalance(self.player)
    if self.titleLabel then
        self.titleLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_Balance") .. tostring(self.balance))
    end
end

function PZLinuxBettingUI:showHub()
    self.minimizeButton:setVisible(true)
    self.minimizeBackButton:setVisible(false)
    self:updateBalanceLabel(PZLinuxLoadBankBalance(self.player))

    self.gameButtons = {}

    local raceButton = ISButton:new(self.width * 0.20, self.height * 0.25, self.width * 0.57, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_ZombieRace"), self, self.onSelectBet)
    raceButton.game = "race"
    raceButton.textColor = {r=0, g=1, b=0, a=1}
    raceButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    raceButton.borderColor = {r=0, g=1, b=0, a=0.5}
    raceButton:setVisible(true)
    raceButton:initialise()
    self.topBar:addChild(raceButton)
    table.insert(self.gameButtons, raceButton)

    local blackjackButton = ISButton:new(self.width * 0.20, self.height * 0.31, self.width * 0.57, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_Blackjack"), self, self.onSelectBet)
    blackjackButton.game = "blackjack"
    blackjackButton.textColor = {r=0, g=1, b=0, a=1}
    blackjackButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    blackjackButton.borderColor = {r=0, g=1, b=0, a=0.5}
    blackjackButton:setVisible(true)
    blackjackButton:initialise()
    self.topBar:addChild(blackjackButton)
    table.insert(self.gameButtons, blackjackButton)

    local pokerButton = ISButton:new(self.width * 0.20, self.height * 0.37, self.width * 0.57, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_Poker"), self, self.onSelectBet)
    pokerButton.game = "poker"
    pokerButton.textColor = {r=0, g=1, b=0, a=1}
    pokerButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    pokerButton.borderColor = {r=0, g=1, b=0, a=0.5}
    pokerButton:setVisible(true)
    pokerButton:initialise()
    self.topBar:addChild(pokerButton)
    table.insert(self.gameButtons, pokerButton)
end

function PZLinuxBettingUI:onSelectBet(button)
    PZLinuxBettingHide(self.gameButtons)
    self.minimizeBackButton:setVisible(true)
    self.minimizeButton:setVisible(false)

    if button.game == "blackjack" then
        self:showBlackjackMenu()
    elseif button.game == "poker" then
        self:showPokerLobby()
    else
        self:showRaceLoading()
    end
end

function PZLinuxBettingUI:addPokerControl(control)
    control:initialise()
    self.topBar:addChild(control)
    table.insert(self.pokerControls, control)
    return control
end

function PZLinuxBettingUI:clearPokerControls()
    for _, control in ipairs(self.pokerControls or {}) do
        if control and control.close then
            control:close()
        elseif control then
            control:setVisible(false)
        end
    end
    self.pokerControls = {}
end

function PZLinuxBettingUI:showPokerLobby()
    self:clearPokerControls()
    self:updateBalanceLabel(PZLinuxLoadBankBalance(self.player))
    self.pokerSession = nil

    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.24, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_PokerLobby"), 0, 1, 0, 1, UIFont.Small, true))

    local yOffset = self.height * 0.29
    for _, lobby in ipairs(PZLinux.Poker.Config.lobbies or {}) do
        local minBuyIn, maxBuyIn = PZLinuxPokerGetBuyInLimits(lobby)
        local label = string.format("%s  $%d/$%d  buy-in $%d-$%d", lobby.id, lobby.smallBlind, lobby.bigBlind, minBuyIn, maxBuyIn)
        local button = ISButton:new(self.width * 0.20, yOffset, self.width * 0.57, self.height * 0.045, label, self, self.onPokerSelectLobby)
        button.lobbyId = lobby.id
        button.minBuyIn = minBuyIn
        button.maxBuyIn = maxBuyIn
        button.textColor = {r=0, g=1, b=0, a=1}
        button.backgroundColor = {r=0, g=0, b=0, a=0.5}
        button.borderColor = {r=0, g=1, b=0, a=0.5}
        self:addPokerControl(button)
        yOffset = yOffset + self.height * 0.052
    end

    self.pokerBuyInInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_PokerBuyIn"), self.width * 0.20, self.height * 0.54, self.width * 0.24, self.height * 0.033)
    self.pokerBuyInInput:instantiate()
    self.pokerBuyInInput:setOnlyNumbers(true)
    self:addPokerControl(self.pokerBuyInInput)

    self.pokerMessageLabel = self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.60, self.height * 0.025, "", 1, 0.3, 0.3, 1, UIFont.Small, true))
end

function PZLinuxBettingUI:onPokerSelectLobby(button)
    local buyIn = tonumber(self.pokerBuyInInput:getText())
    if not buyIn then buyIn = button.minBuyIn end
    if buyIn < button.minBuyIn or buyIn > button.maxBuyIn then
        self.pokerMessageLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_PokerInvalidBuyIn"))
        return
    end

    button:setEnable(false)
    self.pokerMessageLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_PokerJoining"))
    PZLinuxRequestPokerStart(self.player, button.lobbyId, buyIn, function(result)
        if self.isClosing then return end
        self:showPokerState(result)
    end)
end

local function PZLinuxBettingPokerCards(cards)
    local labels = {}
    for _, card in ipairs(cards or {}) do
        table.insert(labels, PZLinuxBettingFormatCard(card))
    end
    if #labels == 0 then return "--" end
    return table.concat(labels, " | ")
end

local function PZLinuxBettingPokerStateLabel(seat)
    if seat.isHuman then return "YOU" end
    if seat.state == "folded" then return "FOLD" end
    if seat.state == "allin" then return "ALL-IN" end
    if seat.state == "eliminated" then return "OUT" end
    return "IN"
end

function PZLinuxBettingUI:showPokerState(result)
    if not result or not result.ok then
        local message = result and result.error or "error"
        if self.pokerMessageLabel then
            self.pokerMessageLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_PokerError") .. ": " .. tostring(message))
        end
        return
    end

    self:clearPokerControls()
    self.pokerSession = result
    self:updateBalanceLabel(result.balance)

    local title = string.format("%s $%d/$%d - %s", PZLinuxGetText("IGUI_PZLinux_Betting_PokerTable"), result.smallBlind or 0, result.bigBlind or 0, tostring(result.phase or ""))
    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.22, self.height * 0.023, title, 0, 1, 0, 1, UIFont.Small, true))

    local community = PZLinuxGetText("IGUI_PZLinux_Betting_PokerBoard") .. " " .. PZLinuxBettingPokerCards(result.community)
    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.255, self.height * 0.023, community, 1, 1, 0, 1, UIFont.Small, true))

    local yOffset = self.height * 0.30
    for _, seat in ipairs(result.seats or {}) do
        local flags = (seat.dealer and "D" or "-") .. (seat.turn and ">" or " ")
        local stars = seat.isHuman and "" or string.rep("*", tonumber(seat.difficulty) or 1)
        local cards = PZLinuxBettingPokerCards(seat.cards)
        if not seat.isHuman and not result.showdown then cards = "Hidden | Hidden" end
        local text = string.format("%d %s %-14s %-5s $%d / bet $%d  %s", seat.index, flags, seat.name, PZLinuxBettingPokerStateLabel(seat), seat.stack or 0, seat.bet or 0, stars)
        self:addPokerControl(ISLabel:new(self.width * 0.20, yOffset, self.height * 0.019, text, 0, 1, 0, 1, UIFont.Small, true))
        yOffset = yOffset + self.height * 0.023
        if seat.isHuman or seat.hand then
            local cardText = "   " .. cards .. (seat.hand and (" - " .. seat.hand) or "")
            self:addPokerControl(ISLabel:new(self.width * 0.22, yOffset, self.height * 0.019, cardText, 1, 1, 0, 1, UIFont.Small, true))
            yOffset = yOffset + self.height * 0.023
        end
    end

    local recent = {}
    for index = 1, math.min(5, #(result.history or {})) do
        table.insert(recent, result.history[index])
    end
    local historyText = table.concat(recent, "\n")
    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.565, self.height * 0.018, historyText, 0.8, 1, 0.8, 1, UIFont.Small, true))

    local actions = result.legalActions or {}
    self.pokerActionY = self.height * 0.695
    self.pokerActionX = self.width * 0.20
    if result.awaitingPlayer then
        self.pokerActionInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_PokerAmount"), self.width * 0.20, self.height * 0.655, self.width * 0.18, self.height * 0.030)
        self.pokerActionInput:instantiate()
        self.pokerActionInput:setOnlyNumbers(true)
        self:addPokerControl(self.pokerActionInput)
    end
    self:addPokerActionButton("fold", PZLinuxGetText("IGUI_PZLinux_Betting_PokerFold"), actions.fold)
    self:addPokerActionButton("check", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCheck"), actions.check)
    self:addPokerActionButton("call", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCall") .. " $" .. tostring(actions.toCall or 0), actions.call)
    self:addPokerActionButton(actions.raise and "raise" or "bet", actions.raise and PZLinuxGetText("IGUI_PZLinux_Betting_PokerRaise") or PZLinuxGetText("IGUI_PZLinux_Betting_PokerBet"), actions.raise or actions.bet)
    self:addPokerActionButton("allin", PZLinuxGetText("IGUI_PZLinux_Betting_PokerAllIn"), actions.allin)

    if result.phase == "hand_complete" then
        self:addPokerActionButton("next", PZLinuxGetText("IGUI_PZLinux_Betting_PokerNextHand"), true)
    end
    self:addPokerActionButton("cashout", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCashOut"), true)
end

function PZLinuxBettingUI:addPokerActionButton(action, label, enabled)
    if not enabled then return end

    local button = ISButton:new(self.pokerActionX, self.pokerActionY, self.width * 0.155, self.height * 0.034, label, self, self.onPokerAction)
    button.pokerAction = action
    button.textColor = {r=0, g=1, b=0, a=1}
    button.backgroundColor = {r=0, g=0, b=0, a=0.5}
    button.borderColor = {r=0, g=1, b=0, a=0.5}
    button:setEnable(enabled and true or false)
    self:addPokerControl(button)
    self.pokerActionX = self.pokerActionX + self.width * 0.165
    if self.pokerActionX > self.width * 0.68 then
        self.pokerActionX = self.width * 0.20
        self.pokerActionY = self.pokerActionY + self.height * 0.040
    end
end

function PZLinuxBettingUI:onPokerAction(button)
    if not self.pokerSession or not self.pokerSession.sessionId then return end
    button:setEnable(false)
    if button.pokerAction == "cashout" then
        PZLinuxRequestPokerCashOut(self.player, self.pokerSession.sessionId, function(result)
            if self.isClosing then return end
            self:showPokerCashOut(result)
        end)
        return
    end

    local amount = tonumber(self.pokerActionInput and self.pokerActionInput:getText()) or 0
    PZLinuxRequestPokerAction(self.player, self.pokerSession.sessionId, button.pokerAction, amount, function(result)
        if self.isClosing then return end
        self:showPokerState(result)
    end)
end

function PZLinuxBettingUI:showPokerCashOut(result)
    self:clearPokerControls()
    self:updateBalanceLabel(result and result.balance)
    local text = PZLinuxGetText("IGUI_PZLinux_Betting_PokerClosed")
    if result and result.ok then
        text = string.format("%s buy-in $%d refund $%d net $%d", text, result.buyIn or 0, result.refund or 0, result.net or 0)
    end
    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.35, self.height * 0.025, text, 0, 1, 0, 1, UIFont.Small, true))
end

function PZLinuxBettingUI:showRaceLoading()
    self.raceControls = {}
    self.loadingLabel = ISLabel:new(self.width * 0.20, self.height * 0.25, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_LoadingRace"), 0, 1, 0, 1, UIFont.Small, true)
    self.loadingLabel:initialise()
    self.topBar:addChild(self.loadingLabel)
    table.insert(self.raceControls, self.loadingLabel)

    PZLinuxRequestRaceCard(self.player, function(result)
        if self.isClosing then return end
        if self.loadingLabel then
            self.loadingLabel:setVisible(false)
        end
        self:showRaceCard(result)
    end)
end

function PZLinuxBettingUI:showRaceCard(result)
    if not result or not result.ok then
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_Error"))
        return
    end

    self.selectedZombies = result.runners or {}
    self:updateBalanceLabel(result.balance)

    self.zombieLabels = {}
    local yOffset = self.height * 0.25
    for index, zomb in ipairs(self.selectedZombies) do
        local labelText = string.format("%d. %s - %d/1", index, zomb.name, zomb.rating)
        local label = ISLabel:new(self.width * 0.20, yOffset, self.height * 0.025, labelText, 0, 1, 0, 1, UIFont.Small, true)
        label:initialise()
        self.topBar:addChild(label)
        table.insert(self.zombieLabels, label)
        table.insert(self.raceControls, label)
        yOffset = yOffset + 25
    end

    self.betInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_BetOn"), self.width * 0.2, self.height * 0.59, self.width * 0.15, self.height * 0.033)
    self.betInput:initialise()
    self.betInput:instantiate()
    self.betInput:setOnlyNumbers(true)
    self.topBar:addChild(self.betInput)
    table.insert(self.raceControls, self.betInput)

    self.amountInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_Amount"), self.width * 0.35, self.height * 0.59, self.width * 0.15, self.height * 0.033)
    self.amountInput:initialise()
    self.amountInput:instantiate()
    self.amountInput:setOnlyNumbers(true)
    self.topBar:addChild(self.amountInput)
    table.insert(self.raceControls, self.amountInput)

    self.startButton = ISButton:new(self.width * 0.20, self.height * 0.625, self.width * 0.57, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_StartRace"), self, self.onSelectStart)
    self.startButton.textColor = {r=0, g=1, b=0, a=1}
    self.startButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.startButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.startButton:setVisible(true)
    self.startButton:initialise()
    self.topBar:addChild(self.startButton)
    table.insert(self.raceControls, self.startButton)
end

function PZLinuxBettingUI:onSelectStart()
    local selectedRunner = tonumber(self.betInput:getText())
    local amount = tonumber(self.amountInput:getText())

    if not amount or not selectedRunner or amount < 1 or selectedRunner < 1 or selectedRunner > 8 then
        PZLinuxBettingPlaySound(self, "error")
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_InvalidBet"))
        return
    end

    self.startButton:setEnable(false)
    self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_StartingRace"))

    PZLinuxRequestRaceStart(self.player, selectedRunner, amount, function(result)
        if self.isClosing then return end
        self:startRaceFromResult(result)
    end)
end

function PZLinuxBettingUI:startRaceFromResult(result)
    if not result or not result.ok then
        PZLinuxBettingPlaySound(self, "error")
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_NotEnoughMoney"))
        if self.startButton then
            self.startButton:setEnable(true)
        end
        return
    end

    self.raceResult = result
    self.selectedZombies = result.runners
    self:updateBalanceLabel(result.balance)

    local playerObj = PZLinuxBettingGetPlayer(self)
    PZLinuxBettingApplyStakeMood(playerObj, result.amount, result.previousBalance)

    PZLinuxBettingPlaySound(self, "race")
    PZLinuxBettingHide({ self.betInput, self.amountInput, self.startButton, self.errorLabel })

    self.raceProgress = {}
    self.raceFinished = false
    for index, zomb in ipairs(self.selectedZombies) do
        self.raceProgress[index] = { zombie = zomb, position = -15 }
    end

    self:runRace()
end

function PZLinuxBettingUI:runRace()
    if self.raceFinished or not self.raceResult then return end

    for index, runner in ipairs(self.raceProgress) do
        local rating = runner.zombie.rating
        local bonus = math.max(1, math.floor((100 - rating) / 25))
        local speed = 5 + ZombRand(0, bonus + 1)
        if index == self.raceResult.winnerId then
            speed = speed + 2
        end
        runner.position = runner.position + speed
    end

    local bestPosition = -math.huge
    for _, runner in ipairs(self.raceProgress) do
        if runner.position > bestPosition then
            bestPosition = runner.position
        end
    end

    self:updateRaceDisplay()

    if bestPosition >= 130 then
        self.raceFinished = true
        self:declareWinner(self.raceResult.winnerId, self.selectedZombies[self.raceResult.winnerId])
        return
    end

    self:delayFunction(function() self:runRace() end, 20)
    local playerObj = PZLinuxBettingGetPlayer(self)
    PZLinuxBettingAddMood(playerObj, "BOREDOM", -0.5)
end

function PZLinuxBettingUI:updateRaceDisplay()
    if not self.raceProgress or not self.zombieLabels then return end

    local sortedRunners = {}
    for index, runner in ipairs(self.raceProgress) do
        table.insert(sortedRunners, { id = index, runner = runner })
    end

    table.sort(sortedRunners, function(a, b)
        return a.runner.position > b.runner.position
    end)

    local labelText = PZLinuxGetText("IGUI_PZLinux_Betting_YourBet")
        .. tostring(self.raceResult.amount)
        .. "$ #"
        .. tostring(self.raceResult.selectedRunner)

    for rank, data in ipairs(sortedRunners) do
        local progressText = string.format("%d. %s@C", data.id, string.rep(".", math.max(0, data.runner.position)))
        self.zombieLabels[data.id]:setName(progressText)
        if rank <= 6 then
            labelText = labelText .. "\n[" .. rank .. "] -> " .. data.id .. ": " .. data.runner.zombie.name .. " odds: " .. data.runner.zombie.rating .. "/1"
        end
    end

    if self.runResultLabel then
        self.runResultLabel:setName(labelText)
        return
    end

    self.runResultLabel = ISLabel:new(self.width * 0.20, self.height * 0.60, 15, labelText, 0, 1, 0, 1, UIFont.Small, true)
    self.runResultLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.runResultLabel:setVisible(true)
    self.runResultLabel:initialise()
    self.topBar:addChild(self.runResultLabel)
    table.insert(self.raceControls, self.runResultLabel)
end

function PZLinuxBettingUI:declareWinner(_winnerId, winner)
    local winnerText = string.format(PZLinuxGetText("IGUI_PZLinux_Betting_RaceWinner"), winner.name)
    self.winnerLabel = ISLabel:new(self.width * 0.20, self.height * 0.22, 20, winnerText, 1, 1, 0, 1, UIFont.Large, true)
    self.winnerLabel:initialise()
    self.topBar:addChild(self.winnerLabel)
    table.insert(self.raceControls, self.winnerLabel)

    self:updateBalanceLabel(self.raceResult.balance)

    local playerObj = PZLinuxBettingGetPlayer(self)
    PZLinuxBettingApplyOutcomeMood(playerObj, self.raceResult.amount, self.raceResult.previousBalance, self.raceResult.payout, self.raceResult.outcome)

    if self.raceResult.outcome == "win" then
        PZLinuxBettingPlaySound(self, "sold")
    end
end

function PZLinuxBettingUI:showBlackjackMenu()
    self.blackjackStakeMoodApplied = false
    self.blackjackControls = {}
    self:updateBalanceLabel(PZLinuxLoadBankBalance(self.player))

    self.blackjackTitle = ISLabel:new(self.width * 0.20, self.height * 0.25, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_BlackjackTitle"), 0, 1, 0, 1, UIFont.Small, true)
    self.blackjackTitle:initialise()
    self.topBar:addChild(self.blackjackTitle)
    table.insert(self.blackjackControls, self.blackjackTitle)

    self.blackjackAmountInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_Amount"), self.width * 0.20, self.height * 0.31, self.width * 0.22, self.height * 0.033)
    self.blackjackAmountInput:initialise()
    self.blackjackAmountInput:instantiate()
    self.blackjackAmountInput:setOnlyNumbers(true)
    self.topBar:addChild(self.blackjackAmountInput)
    table.insert(self.blackjackControls, self.blackjackAmountInput)

    self.blackjackDealButton = ISButton:new(self.width * 0.45, self.height * 0.31, self.width * 0.32, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_Deal"), self, self.onBlackjackDeal)
    self.blackjackDealButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackDealButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackDealButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackDealButton:setVisible(true)
    self.blackjackDealButton:initialise()
    self.topBar:addChild(self.blackjackDealButton)
    table.insert(self.blackjackControls, self.blackjackDealButton)

    self.blackjackDealerLabel = ISLabel:new(self.width * 0.20, self.height * 0.42, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.blackjackDealerLabel:initialise()
    self.topBar:addChild(self.blackjackDealerLabel)
    table.insert(self.blackjackControls, self.blackjackDealerLabel)

    self.blackjackPlayerLabel = ISLabel:new(self.width * 0.20, self.height * 0.48, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.blackjackPlayerLabel:initialise()
    self.topBar:addChild(self.blackjackPlayerLabel)
    table.insert(self.blackjackControls, self.blackjackPlayerLabel)

    self.blackjackMessageLabel = ISLabel:new(self.width * 0.20, self.height * 0.56, self.height * 0.025, "", 1, 1, 0, 1, UIFont.Small, true)
    self.blackjackMessageLabel:initialise()
    self.topBar:addChild(self.blackjackMessageLabel)
    table.insert(self.blackjackControls, self.blackjackMessageLabel)

    self.blackjackHitButton = ISButton:new(self.width * 0.20, self.height * 0.64, self.width * 0.25, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_Hit"), self, self.onBlackjackHit)
    self.blackjackHitButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackHitButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackHitButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackHitButton:setVisible(false)
    self.blackjackHitButton:initialise()
    self.topBar:addChild(self.blackjackHitButton)
    table.insert(self.blackjackControls, self.blackjackHitButton)

    self.blackjackStandButton = ISButton:new(self.width * 0.52, self.height * 0.64, self.width * 0.25, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_Stand"), self, self.onBlackjackStand)
    self.blackjackStandButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackStandButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackStandButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackStandButton:setVisible(false)
    self.blackjackStandButton:initialise()
    self.topBar:addChild(self.blackjackStandButton)
    table.insert(self.blackjackControls, self.blackjackStandButton)
end

function PZLinuxBettingUI:onBlackjackDeal()
    local amount = tonumber(self.blackjackAmountInput:getText())
    if not amount or amount < 1 then
        PZLinuxBettingPlaySound(self, "error")
        self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_InvalidBet"))
        return
    end

    self.blackjackStakeMoodApplied = false
    self.blackjackDealButton:setEnable(false)
    self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_Dealing"))

    PZLinuxRequestBlackjackStart(self.player, amount, function(result)
        if self.isClosing then return end
        self:showBlackjackState(result)
    end)
end

function PZLinuxBettingUI:onBlackjackHit()
    self.blackjackHitButton:setEnable(false)
    self.blackjackStandButton:setEnable(false)
    PZLinuxRequestBlackjackHit(self.player, function(result)
        if self.isClosing then return end
        self:showBlackjackState(result)
    end)
end

function PZLinuxBettingUI:onBlackjackStand()
    self.blackjackHitButton:setEnable(false)
    self.blackjackStandButton:setEnable(false)
    PZLinuxRequestBlackjackStand(self.player, function(result)
        if self.isClosing then return end
        self:showBlackjackState(result)
    end)
end

function PZLinuxBettingUI:showBlackjackState(result)
    if not result or not result.ok then
        PZLinuxBettingPlaySound(self, "error")
        self.blackjackDealButton:setEnable(true)
        self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_NotEnoughMoney"))
        return
    end

    self:updateBalanceLabel(result.balance)

    self.blackjackDealerLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_Dealer")
        .. PZLinuxBettingFormatCards(result.dealerHand)
        .. " ("
        .. tostring(result.dealerValue)
        .. (result.dealerHidden and "+?" or "")
        .. ")")

    self.blackjackPlayerLabel:setName(PZLinuxGetText("IGUI_PZLinux_Betting_Player")
        .. PZLinuxBettingFormatCards(result.playerHand)
        .. " ("
        .. tostring(result.playerValue)
        .. ")")

    local payoutText = ""
    if result.finished then
        payoutText = " " .. PZLinuxGetText("IGUI_PZLinux_Betting_Payout") .. tostring(result.payout)
    end
    self.blackjackMessageLabel:setName(tostring(result.message or "") .. payoutText)

    local playerObj = PZLinuxBettingGetPlayer(self)
    if not self.blackjackStakeMoodApplied then
        PZLinuxBettingApplyStakeMood(playerObj, result.bet, result.previousBalance)
        self.blackjackStakeMoodApplied = true
    end

    if result.finished then
        PZLinuxBettingApplyOutcomeMood(playerObj, result.bet, result.previousBalance, result.payout, result.outcome)
        self.blackjackHitButton:setVisible(false)
        self.blackjackStandButton:setVisible(false)
        self.blackjackDealButton:setEnable(true)
        self.blackjackDealButton:setVisible(true)
        self.blackjackStakeMoodApplied = false
        if result.outcome == "win" or result.outcome == "blackjack" then
            PZLinuxBettingPlaySound(self, "sold")
        end
        return
    end

    self.blackjackDealButton:setVisible(false)
    self.blackjackHitButton:setVisible(true)
    self.blackjackStandButton:setVisible(true)
    self.blackjackHitButton:setEnable(true)
    self.blackjackStandButton:setEnable(true)
end

function PZLinuxBettingUI:showError(message)
    if self.errorLabel then
        self.errorLabel:setName(message)
        self.errorLabel:setVisible(true)
        return
    end

    self.errorLabel = ISLabel:new(self.width * 0.20, self.height * 0.70, self.height * 0.025, message, 1, 0.3, 0.3, 1, UIFont.Small, true)
    self.errorLabel:initialise()
    self.topBar:addChild(self.errorLabel)
    table.insert(self.raceControls, self.errorLabel)
end

function PZLinuxBettingUI:showBlackjackError(message)
    if self.blackjackMessageLabel then
        self.blackjackMessageLabel:setName(message)
    end
end

function PZLinuxBettingUI:delayFunction(func, seconds)
    local startTime = getGameTime():getWorldAgeHours() * 3600
    local targetTime = startTime + seconds

    local function timer()
        local elapsed = getGameTime():getWorldAgeHours() * 3600
        if elapsed >= targetTime then
            Events.OnTick.Remove(timer)
            if not self.isClosing then
                func()
            end
        end
    end

    Events.OnTick.Add(timer)
end

function PZLinuxBettingUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxBettingGetModData(self)
    if modData then
        modData.PZLinuxUIOpenMenu = 1
    end
end

function PZLinuxBettingUI:onMinimizeBack(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxBettingGetModData(self)
    if modData then
        modData.PZLinuxUIOpenMenu = 9
    end
end

function PZLinuxBettingUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxBettingGetModData(self)
    if modData then
        modData.PZLinuxUIOpenMenu = 1
    end
end

function PZLinuxBettingUI:onCloseX(_button)
    self.isClosing = true
    local playerObj = PZLinuxBettingGetPlayer(self)
    if playerObj then
        playerObj:StopAllActionQueue()
    end
end

function PZLinuxBettingUI:onSFXOn(_button)
    local modData = PZLinuxBettingGetModData(self)
    if modData then
        modData.PZLinuxUISFX = 0
    end
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

function PZLinuxBettingUI:onSFXOff(_button)
    local modData = PZLinuxBettingGetModData(self)
    if modData then
        modData.PZLinuxUISFX = 1
    end
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

function PZLinuxBettingMenu_ShowUI(player)
    local texture = getTexture("media/ui/oldCRT.png")
    if not texture then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()

    local maxW = realScreenW * 0.70
    local maxH = realScreenH * 0.70
    local texW = texture:getWidth()
    local texH = texture:getHeight()

    local ratioX, ratioY = maxW / texW, maxH / texH
    local scale = math.min(ratioX, ratioY)
    local finalW, finalH = math.floor(texW * scale), math.floor(texH * scale)

    local modData = PZLinuxGetModData(player)
    local uiX = modData and modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData and modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = PZLinuxBettingUI:new(uiX, uiY, finalW, finalH, player)
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

bettingMenu_ShowUI = PZLinuxBettingMenu_ShowUI
