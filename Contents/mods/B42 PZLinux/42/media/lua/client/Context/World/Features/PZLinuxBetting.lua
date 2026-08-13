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
    if not card or card.hidden then return "??" end

    local rank = card.rank
    local suit = card.suit
    if card.label and (not rank or not suit or tostring(rank) == "?" or tostring(suit) == "?") then
        local label = tostring(card.label)
        if label:sub(1, 2) == "10" then
            rank = "10"
            suit = label:sub(3, 3)
        else
            rank = label:sub(1, 1)
            suit = label:sub(2, 2)
        end
    end

    rank = tostring(rank or "?"):upper()
    suit = tostring(suit or "?"):upper()

    local ranks = { ["1"] = "A", A = "A", T = "10", J = "J", Q = "Q", K = "K" }
    local suits = { C = "C", D = "D", H = "H", S = "S" }
    return (ranks[rank] or rank or "?") .. (suits[suit] or suit or "?")
end

local PZLinuxBettingSuitTextures = {
    C = "media/ui/PZLinux/cards/suit_club.png",
    D = "media/ui/PZLinux/cards/suit_diamond.png",
    H = "media/ui/PZLinux/cards/suit_heart.png",
    S = "media/ui/PZLinux/cards/suit_spade.png",
}

local PZLINUX_BETTING_ZOMBIE_TEXTURE = "media/ui/PZLinux/betting/zombie_runner.png"
local PZLINUX_BETTING_RACE_DISTANCE = 130

local function PZLinuxBettingParseCard(card)
    if not card or card.hidden then
        return "??", nil, true
    end

    local rank = card.rank
    local suit = card.suit
    if card.label and (not rank or not suit or tostring(rank) == "?" or tostring(suit) == "?") then
        local label = tostring(card.label)
        if label:sub(1, 2) == "10" then
            rank = "10"
            suit = label:sub(3, 3)
        else
            rank = label:sub(1, 1)
            suit = label:sub(2, 2)
        end
    end

    rank = tostring(rank or "?"):upper()
    suit = tostring(suit or "?"):upper()

    local ranks = { ["1"] = "A", A = "A", T = "10", J = "J", Q = "Q", K = "K" }
    return ranks[rank] or rank or "?", suit
end

local function PZLinuxBettingTextWidth(text)
    return math.max(8, string.len(tostring(text or "")) * 7)
end

local function PZLinuxBettingShortText(text, maxLength)
    text = tostring(text or "")
    maxLength = tonumber(maxLength) or 34
    local characters = {}
    for character in text:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
        table.insert(characters, character)
    end
    if #characters <= maxLength then return text end
    local shortened = {}
    for index = 1, math.max(1, maxLength - 3) do
        shortened[index] = characters[index]
    end
    return table.concat(shortened) .. "..."
end

local function PZLinuxBettingAddDisplayControl(ui, controls, control)
    control:initialise()
    ui.topBar:addChild(control)
    table.insert(controls, control)
    return control
end

local function PZLinuxBettingClearDisplayControls(controls)
    for _, control in ipairs(controls or {}) do
        if control and control.close then
            control:close()
        elseif control then
            control:setVisible(false)
        end
    end
end

local PZLinuxBettingTablePanel = ISPanel:derive("PZLinuxBettingTablePanel")

function PZLinuxBettingTablePanel:new(x, y, width, height)
    local panel = ISPanel:new(x, y, width, height)
    setmetatable(panel, self)
    self.__index = self
    panel.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.borderColor = {r=0, g=0, b=0, a=0}
    return panel
end

function PZLinuxBettingTablePanel:prerender()
    ISPanel.prerender(self)
    local rowHeight = 4
    local centerX = self.width / 2
    local centerY = self.height / 2

    for y = 0, self.height - 1, rowHeight do
        local normalizedY = (y + rowHeight / 2 - centerY) / centerY
        local halfWidth = centerX * math.sqrt(math.max(0, 1 - normalizedY * normalizedY))
        self:drawRect(centerX - halfWidth, y, halfWidth * 2, rowHeight + 1, 0.95, 0.02, 0.30, 0.10)
    end

    local inset = 5
    local innerWidth = self.width - inset * 2
    local innerHeight = self.height - inset * 2
    local innerCenterX = self.width / 2
    local innerCenterY = inset + innerHeight / 2
    for y = inset, self.height - inset - 1, rowHeight do
        local normalizedY = (y + rowHeight / 2 - innerCenterY) / (innerHeight / 2)
        local halfWidth = innerWidth / 2 * math.sqrt(math.max(0, 1 - normalizedY * normalizedY))
        self:drawRect(innerCenterX - halfWidth, y, halfWidth * 2, rowHeight + 1, 0.96, 0.01, 0.16, 0.055)
    end
end

local function PZLinuxBettingAddCardLine(ui, controls, x, y, prefix, cards, suffix)
    local labelHeight = ui.height * 0.019
    local iconSize = math.max(10, math.floor(labelHeight))
    local cursor = x

    if prefix and prefix ~= "" then
        PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, prefix, 0, 1, 0, 1, UIFont.Small, true))
        cursor = cursor + PZLinuxBettingTextWidth(prefix)
    end

    if not cards or #cards == 0 then
        PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, "--", 1, 1, 0, 1, UIFont.Small, true))
        cursor = cursor + PZLinuxBettingTextWidth("-- ")
    else
        for _, card in ipairs(cards) do
            local rank, suit, hidden = PZLinuxBettingParseCard(card)
            if hidden or not PZLinuxBettingSuitTextures[suit] then
                local text = hidden and "??" or PZLinuxBettingFormatCard(card)
                PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, text, 1, 1, 0, 1, UIFont.Small, true))
                cursor = cursor + PZLinuxBettingTextWidth(text .. " ")
            else
                PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, rank, 1, 1, 0, 1, UIFont.Small, true))
                cursor = cursor + PZLinuxBettingTextWidth(rank)

                local texture = getTexture(PZLinuxBettingSuitTextures[suit])
                if texture then
                    local image = ISImage:new(cursor, y + 1, iconSize, iconSize, texture)
                    PZLinuxBettingAddDisplayControl(ui, controls, image)
                    cursor = cursor + iconSize + 8
                else
                    PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, suit, 1, 1, 0, 1, UIFont.Small, true))
                    cursor = cursor + PZLinuxBettingTextWidth(suit .. " ")
                end
            end
        end
    end

    if suffix and suffix ~= "" then
        PZLinuxBettingAddDisplayControl(ui, controls, ISLabel:new(cursor, y, labelHeight, suffix, 0, 1, 0, 1, UIFont.Small, true))
    end
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
    o.zombieIcons = {}
    o.raceSettlementCallbacks = {}
    o.blackjackControls = {}
    o.blackjackCardControls = {}
    o.pokerControls = {}
    o.blackjackStakeMoodApplied = false
    o.blackjackSelectedTableId = (PZLinux.Config.Blackjack.tables[1] or {}).id
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

-- ISButton/ISLabel (everything this builds) have no :close() method, so
-- the old "call :close() if it exists, else just hide it" logic always
-- fell through to :setVisible(false) -- every single poker control ever
-- created stayed a live child of self.topBar forever, just invisible,
-- piling up across every hand/action for the whole session. Actually
-- removing them (they're already invisible via ~setVisible either way,
-- but now genuinely gone from the tree) closes the same class of stale-
-- widget bug already fixed for Hacking/Trading elsewhere this cycle.
function PZLinuxBettingUI:clearPokerControls()
    for _, control in ipairs(self.pokerControls or {}) do
        if control then
            self.topBar:removeChild(control)
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
        -- The server refused because a table this client had already lost
        -- track of (e.g. after navigating back to this lobby screen without
        -- properly leaving the table first) is still active -- see the
        -- comment above PZLinuxPokerCreateSession. Fetching that session's
        -- own state instead of just showing a raw error code lets the
        -- player actually get back to their table (and their stack).
        if result and result.error == "session_already_active" then
            PZLinuxRequestPokerRestoreSession(self.player, function(sessionResult)
                if self.isClosing then return end
                self:showPokerState(sessionResult)
            end)
            return
        end
        self:showPokerState(result)
    end)
end

local function PZLinuxBettingPokerPlayerSlot(sessionId)
    local value = tostring(sessionId or "poker")
    local hash = 0
    for index = 1, #value do
        hash = (hash + string.byte(value, index) * index) % 6
    end
    return hash + 1
end

local function PZLinuxBettingPokerSeatAction(seat)
    if seat.lastAction and seat.lastAction ~= "" then return seat.lastAction end
    if seat.state == "folded" then return "FOLD" end
    if seat.state == "allin" then return "ALL-IN" end
    return "..."
end

local function PZLinuxBettingPokerHandName(handName)
    if not handName then return PZLinuxGetText("IGUI_PZLinux_Betting_PokerHandHighCard") end
    local keys = {
        royal_flush = "IGUI_PZLinux_Betting_PokerHandRoyalFlush",
        straight_flush = "IGUI_PZLinux_Betting_PokerHandStraightFlush",
        four_kind = "IGUI_PZLinux_Betting_PokerHandFourKind",
        full_house = "IGUI_PZLinux_Betting_PokerHandFullHouse",
        flush = "IGUI_PZLinux_Betting_PokerHandFlush",
        straight = "IGUI_PZLinux_Betting_PokerHandStraight",
        three_kind = "IGUI_PZLinux_Betting_PokerHandThreeKind",
        two_pair = "IGUI_PZLinux_Betting_PokerHandTwoPair",
        pair = "IGUI_PZLinux_Betting_PokerHandPair",
        high_card = "IGUI_PZLinux_Betting_PokerHandHighCard",
    }
    return PZLinuxGetText(keys[handName] or keys.high_card)
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

    local leftX = self.width * 0.20
    local tablePanel = PZLinuxBettingTablePanel:new(self.width * 0.195, self.height * 0.24, self.width * 0.58, self.height * 0.32)
    self:addPokerControl(tablePanel)

    local pot = 0
    for _, seat in ipairs(result.seats or {}) do pot = pot + (tonumber(seat.committed) or 0) end
    local tableInfo = string.format("$%d/$%d  |  %s  |  POT $%d", result.smallBlind or 0, result.bigBlind or 0, string.upper(tostring(result.phase or "")), pot)
    self:addPokerControl(ISLabel:new(self.width * 0.395, self.height * 0.315, self.height * 0.018, tableInfo, 1, 1, 0, 1, UIFont.Small, true))
    PZLinuxBettingAddCardLine(self, self.pokerControls, self.width * 0.35, self.height * 0.35, "", result.community)
    local handText = PZLinuxGetText("IGUI_PZLinux_Betting_PokerCurrentHand") .. ": " .. PZLinuxBettingPokerHandName(result.playerHand)
    self:addPokerControl(ISLabel:new(self.width * 0.355, self.height * 0.405, self.height * 0.018, handText, 1, 1, 0, 1, UIFont.Small, true))

    local anchors = {
        {x = 0.235, y = 0.245},
        {x = 0.525, y = 0.245},
        {x = 0.615, y = 0.345},
        {x = 0.525, y = 0.47},
        {x = 0.235, y = 0.47},
        {x = 0.16, y = 0.345},
    }
    local playerSlot = PZLinuxBettingPokerPlayerSlot(result.sessionId)
    for index, seat in ipairs(result.seats or {}) do
        if seat.state ~= "eliminated" then
            local visualSlot = ((playerSlot + index - 2) % #anchors) + 1
            local anchor = anchors[visualSlot]
            local seatX = self.width * anchor.x
            local seatY = self.height * anchor.y
            local seatName = PZLinuxBettingShortText(seat.isHuman and "(YOU)" or seat.name, 15)
            if seat.isHuman and result.playerEquity ~= nil then
                seatName = seatName .. " ~" .. string.format("%.1f", result.playerEquity) .. "%"
            end
            if seat.dealer then seatName = seatName .. " [D]" end
            if seat.turn then seatName = "> " .. seatName end

            local nameR, nameG, nameB = 0, 1, 0
            if seat.state == "folded" then
                nameR, nameG, nameB = 0.45, 0.65, 0.45
            elseif seat.state == "allin" then
                nameR, nameG, nameB = 1, 1, 0
            elseif seat.isHuman then
                nameR, nameG, nameB = 0.2, 1, 0.8
            end
            self:addPokerControl(ISLabel:new(seatX, seatY, self.height * 0.018, seatName, nameR, nameG, nameB, 1, UIFont.Small, true))

            local actionText = PZLinuxBettingPokerSeatAction(seat) .. "  |  $" .. tostring(seat.stack or 0)
            self:addPokerControl(ISLabel:new(seatX, seatY + self.height * 0.019, self.height * 0.016, PZLinuxBettingShortText(actionText, 22), 0.8, 1, 0.8, 1, UIFont.Small, true))

            local revealCards = seat.isHuman or result.showdown or result.phase == "hand_complete" or result.phase == "finished"
            if revealCards then
                local suffix = seat.hand and (" - " .. PZLinuxBettingPokerHandName(seat.hand)) or ""
                PZLinuxBettingAddCardLine(self, self.pokerControls, seatX, seatY + self.height * 0.038, "", seat.cards, suffix)
            end
        end
    end

    if result.phase == "finished" then
        local statusKey = result.status == "won" and "IGUI_PZLinux_Betting_PokerTableWon" or "IGUI_PZLinux_Betting_PokerBusted"
        self:addPokerControl(ISLabel:new(leftX, self.height * 0.575, self.height * 0.018, PZLinuxGetText(statusKey), 1, 1, 0, 1, UIFont.Small, true))
    end

    local actions = result.legalActions or {}
    self.pokerActionY = self.height * 0.642
    self.pokerActionX = self.width * 0.20
    if result.awaitingPlayer then
        self.pokerActionInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_PokerAmount"), self.width * 0.20, self.height * 0.603, self.width * 0.18, self.height * 0.028)
        self.pokerActionInput:instantiate()
        self.pokerActionInput:setOnlyNumbers(true)
        self:addPokerControl(self.pokerActionInput)
    end
    self:addPokerActionButton("fold", PZLinuxGetText("IGUI_PZLinux_Betting_PokerFold"), actions.fold)
    self:addPokerActionButton("check", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCheck"), actions.check)
    self:addPokerActionButton("call", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCall") .. " $" .. tostring(actions.toCall or 0), actions.call)
    self:addPokerActionButton(actions.raise and "raise" or "bet", actions.raise and PZLinuxGetText("IGUI_PZLinux_Betting_PokerRaise") or PZLinuxGetText("IGUI_PZLinux_Betting_PokerBet"), actions.raise or actions.bet)
    self.pokerActionX = self.width * 0.20
    self.pokerActionY = self.pokerActionY + self.height * 0.032
    self:addPokerActionButton("allin", PZLinuxGetText("IGUI_PZLinux_Betting_PokerAllIn"), actions.allin)

    if result.phase == "hand_complete" then
        self.pokerActionX = self.width * 0.20
        self:addPokerActionButton("next", PZLinuxGetText("IGUI_PZLinux_Betting_PokerNextHand"), true, 0.27)
        self:addPokerActionButton("cashout", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCashOut"), true, 0.27)
    else
        self:addPokerActionButton("cashout", PZLinuxGetText("IGUI_PZLinux_Betting_PokerCashOut"), true, 0.20)
    end
end

function PZLinuxBettingUI:addPokerActionButton(action, label, enabled, relativeWidth)
    if not enabled then return end

    relativeWidth = relativeWidth or 0.110
    if self.pokerActionX + self.width * relativeWidth > self.width * 0.77 then
        self.pokerActionX = self.width * 0.20
        self.pokerActionY = self.pokerActionY + self.height * 0.032
    end

    local button = ISButton:new(self.pokerActionX, self.pokerActionY, self.width * relativeWidth, self.height * 0.028, label, self, self.onPokerAction)
    button.pokerAction = action
    button.textColor = {r=0, g=1, b=0, a=1}
    button.backgroundColor = {r=0, g=0, b=0, a=0.5}
    button.borderColor = {r=0, g=1, b=0, a=0.5}
    button:setEnable(enabled and true or false)
    self:addPokerControl(button)
    self.pokerActionX = self.pokerActionX + self.width * (relativeWidth + 0.02)
end

function PZLinuxBettingUI:onPokerAction(button)
    if not self.pokerSession or not self.pokerSession.sessionId then return end
    button:setEnable(false)
    -- Same race as Blackjack's Deal/Hit/Stand (see forfeitBlackjackBeforeClose):
    -- Close/Minimize/Leave stay clickable while this action is in flight, so
    -- closing the panel right after clicking Call/Raise/etc. could send the
    -- auto-cashout before this action's own effect on the stack is applied
    -- -- cashing out a stack that hasn't been debited/credited by the bet
    -- that's still on its way. Waiting for this to land first closes that gap.
    self.pokerActionInFlight = true
    if button.pokerAction == "cashout" then
        PZLinuxRequestPokerCashOut(self.player, self.pokerSession.sessionId, function(result)
            self.pokerActionInFlight = false
            if not self.isClosing then
                self.pokerSession = nil
                self:showPokerCashOut(result)
            end
            self:pokerRunPendingCashOut()
        end)
        return
    end

    local amount = tonumber(self.pokerActionInput and self.pokerActionInput:getText()) or 0
    PZLinuxRequestPokerAction(self.player, self.pokerSession.sessionId, button.pokerAction, amount, function(result)
        self.pokerActionInFlight = false
        if not self.isClosing then
            self:showPokerState(result)
        end
        self:pokerRunPendingCashOut()
    end)
end

function PZLinuxBettingUI:showPokerCashOut(result)
    self:clearPokerControls()
    self.pokerSession = nil
    self:updateBalanceLabel(result and result.balance)
    local text = PZLinuxGetText("IGUI_PZLinux_Betting_PokerClosed")
    if result and result.ok then
        text = string.format("%s buy-in $%d refund $%d net $%d", text, result.buyIn or 0, result.refund or 0, result.net or 0)
    end
    self:addPokerControl(ISLabel:new(self.width * 0.20, self.height * 0.35, self.height * 0.025, text, 0, 1, 0, 1, UIFont.Small, true))
end

function PZLinuxBettingUI:clearRaceControls()
    PZLinuxBettingClearDisplayControls(self.raceControls)
    self.raceControls = {}
    self.errorLabel = nil
    self.loadingLabel = nil
    self.raceScheduleId = nil
end

function PZLinuxBettingUI:showRaceLoading()
    self:clearRaceControls()
    self.loadingLabel = ISLabel:new(self.width * 0.20, self.height * 0.25, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_LoadingRace"), 0, 1, 0, 1, UIFont.Small, true)
    self.loadingLabel:initialise()
    self.topBar:addChild(self.loadingLabel)
    table.insert(self.raceControls, self.loadingLabel)

    PZLinuxRequestRaceSchedule(self.player, function(result)
        if self.isClosing then return end
        self:showRaceSchedule(result)
    end)
end

function PZLinuxBettingUI:showRaceSchedule(result)
    self:clearRaceControls()
    if not result or not result.ok then
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_Error"))
        return
    end
    self:updateBalanceLabel(result.balance)

    local title = ISLabel:new(self.width * 0.20, self.height * 0.225, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_RaceScheduleTitle"), 0, 1, 0, 1, UIFont.Small, true)
    title:initialise()
    self.topBar:addChild(title)
    table.insert(self.raceControls, title)

    local resultLines = {}
    local unreadResults = result.unreadResults or {}
    if #unreadResults == 0 and result.latestResult then unreadResults = { result.latestResult } end
    for _, raceResult in ipairs(unreadResults) do
        local outcome = raceResult.won
            and string.format(PZLinuxGetText("IGUI_PZLinux_Betting_RaceResultWin"), raceResult.payout or 0)
            or string.format(PZLinuxGetText("IGUI_PZLinux_Betting_RaceResultLose"), raceResult.amount or 0)
        table.insert(resultLines, PZLinuxBettingShortText(
            tostring(raceResult.label) .. " | " .. tostring(raceResult.winnerName) .. " | " .. outcome,
            68
        ))
    end
    if #resultLines == 0 then
        resultLines[1] = PZLinuxGetText("IGUI_PZLinux_Betting_RaceNoResult")
    end

    local resultPanel = ISRichTextPanel:new(
        self.width * 0.20,
        self.height * 0.26,
        self.width * 0.57,
        self.height * 0.115
    )
    resultPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    resultPanel.borderColor = {r=0, g=0, b=0, a=0}
    resultPanel.autosetheight = false
    -- ISRichTextPanel:paginate() tokenizes on spaces; a word glued directly
    -- to a following tag gets swallowed by the tag's token and never
    -- rendered. A space on each side of <LINE> avoids that -- it's exactly
    -- what the engine itself inserts when converting "\n".
    resultPanel.text = "<RGB:1,1,0>" .. table.concat(resultLines, " <LINE> ")
    resultPanel:initialise()
    resultPanel:instantiate()
    resultPanel:paginate()
    if resultPanel.vscroll then
        resultPanel.vscroll:setVisible(resultPanel:getScrollHeight() > resultPanel:getHeight())
    end
    self.topBar:addChild(resultPanel)
    table.insert(self.raceControls, resultPanel)

    local yOffset = self.height * 0.40
    for _, race in ipairs(result.races or {}) do
        local text = tostring(race.label)
        if race.jackpot then
            text = text .. " | " .. string.format(PZLinuxGetText("IGUI_PZLinux_Betting_RaceJackpot"), race.jackpotAmount or 0)
        end
        if race.ticket then
            text = text .. " | " .. string.format(
                PZLinuxGetText("IGUI_PZLinux_Betting_RaceTicket"),
                race.ticket.amount or 0,
                race.ticket.selectedRunner or 0
            )
        end
        local button = ISButton:new(self.width * 0.20, yOffset, self.width * 0.57, self.height * 0.043, PZLinuxBettingShortText(text, 52), self, self.onSelectScheduledRace)
        button.raceSchedule = race
        button.textColor = race.jackpot and {r=1, g=1, b=0, a=1} or {r=0, g=1, b=0, a=1}
        button.backgroundColor = {r=0, g=0, b=0, a=0.5}
        button.borderColor = {r=0, g=1, b=0, a=0.5}
        button:initialise()
        self.topBar:addChild(button)
        table.insert(self.raceControls, button)
        yOffset = yOffset + self.height * 0.052
    end
end

function PZLinuxBettingUI:onSelectScheduledRace(button)
    local race = button and button.raceSchedule
    if not race then return end
    self:showRaceCard({
        ok = true,
        runners = race.runners,
        pool = race.pool,
        schedule = race,
        balance = self.balance,
    })
end

function PZLinuxBettingUI:showRaceCard(result)
    self:clearRaceControls()
    if not result or not result.ok then
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_Error"))
        return
    end

    self.raceResult = nil
    self.raceSettlement = nil
    self.raceSettlementInProgress = false
    self.raceSettlementCallbacks = {}
    self.selectedZombies = result.runners or {}
    self.racePool = result.pool or {}
    self.raceSchedule = result.schedule
    self.raceScheduleId = self.raceSchedule and self.raceSchedule.id or nil
    self.raceTicket = self.raceSchedule and self.raceSchedule.ticket or nil
    self:updateBalanceLabel(result.balance)

    self.zombieLabels = {}
    self.zombieIcons = {}
    local scheduleText = self.raceSchedule and self.raceSchedule.label or ""
    if self.raceSchedule and self.raceSchedule.jackpot then
        scheduleText = scheduleText .. " | " .. string.format(
            PZLinuxGetText("IGUI_PZLinux_Betting_RaceJackpot"),
            self.raceSchedule.jackpotAmount or 0
        )
    end
    self.raceScheduleLabel = ISLabel:new(self.width * 0.20, self.height * 0.205, self.height * 0.020, scheduleText, 1, 1, 0, 1, UIFont.Small, true)
    self.raceScheduleLabel:initialise()
    self.topBar:addChild(self.raceScheduleLabel)
    table.insert(self.raceControls, self.raceScheduleLabel)

    local poolText = string.format(
        PZLinuxGetText("IGUI_PZLinux_Betting_RacePool"),
        self.racePool.bettorCount or 0,
        self.racePool.poolTotal or 0,
        self.racePool.maximumBet or 0
    )
    self.racePoolLabel = ISLabel:new(self.width * 0.20, self.height * 0.235, self.height * 0.025, poolText, 1, 1, 0, 1, UIFont.Small, true)
    self.racePoolLabel:initialise()
    self.topBar:addChild(self.racePoolLabel)
    table.insert(self.raceControls, self.racePoolLabel)

    local yOffset = self.height * 0.275
    local zombieTexture = getTexture(PZLINUX_BETTING_ZOMBIE_TEXTURE)
    local iconSize = math.max(18, math.floor(self.height * 0.028))
    for index, zomb in ipairs(self.selectedZombies) do
        local labelText = string.format(
            "%d. %s - %.2f/1 (%d)",
            index,
            zomb.name,
            tonumber(zomb.odds) or math.max(0, (tonumber(zomb.multiplier) or 1) - 1),
            tonumber(zomb.bettorCount) or 0
        )
        if zombieTexture then
            local icon = ISImage:new(self.width * 0.20, yOffset + 1, iconSize, iconSize, zombieTexture)
            icon:initialise()
            self.topBar:addChild(icon)
            self.zombieIcons[index] = icon
            table.insert(self.raceControls, icon)
        end

        local label = ISLabel:new(self.width * 0.235, yOffset, self.height * 0.025, labelText, 0, 1, 0, 1, UIFont.Small, true)
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

    self.startButton = ISButton:new(self.width * 0.20, self.height * 0.625, self.width * 0.37, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_RacePlaceBet"), self, self.onSelectStart)
    self.startButton.textColor = {r=0, g=1, b=0, a=1}
    self.startButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.startButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.startButton:setVisible(true)
    self.startButton:initialise()
    self.topBar:addChild(self.startButton)
    table.insert(self.raceControls, self.startButton)
    self.startButton:setEnable(not self.raceTicket)

    self.scheduleBackButton = ISButton:new(self.width * 0.58, self.height * 0.625, self.width * 0.19, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Betting_RaceBackSchedule"), self, self.showRaceLoading)
    self.scheduleBackButton.textColor = {r=0, g=1, b=0, a=1}
    self.scheduleBackButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.scheduleBackButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.scheduleBackButton:initialise()
    self.topBar:addChild(self.scheduleBackButton)
    table.insert(self.raceControls, self.scheduleBackButton)
end

function PZLinuxBettingUI:onSelectStart()
    local selectedRunner = tonumber(self.betInput:getText())
    local amount = tonumber(self.amountInput:getText())

    if not amount or not selectedRunner or amount < 1 or selectedRunner < 1 or selectedRunner > 8 then
        PZLinuxBettingPlaySound(self, "error")
        self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_InvalidBet"))
        return
    end
    if self.racePool and amount > (tonumber(self.racePool.maximumBet) or 0) then
        PZLinuxBettingPlaySound(self, "error")
        self:showError(string.format(
            PZLinuxGetText("IGUI_PZLinux_Betting_RaceBetLimit"),
            self.racePool.maximumBet or 0
        ))
        return
    end

    if not self.raceScheduleId or self.raceTicket then return end
    self.startButton:setEnable(false)
    self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_RaceSavingBet"))

    PZLinuxRequestRaceScheduleBet(self.player, self.raceScheduleId, selectedRunner, amount, function(result)
        if self.isClosing then return end
        if not result or not result.ok then
            self.startButton:setEnable(true)
            self:showError(PZLinuxGetText("IGUI_PZLinux_Betting_Error"))
            return
        end
        self:showRaceSchedule(result)
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
    local selectedZombie = self.selectedZombies[result.selectedRunner]
    if selectedZombie then
        selectedZombie.odds = result.finalOdds or selectedZombie.odds
        selectedZombie.multiplier = (selectedZombie.odds or 0) + 1
        selectedZombie.bettorCount = (tonumber(selectedZombie.bettorCount) or 0) + 1
    end
    self:updateBalanceLabel(result.balance)

    local playerObj = PZLinuxBettingGetPlayer(self)
    PZLinuxBettingApplyStakeMood(playerObj, result.amount, result.previousBalance)

    PZLinuxBettingPlaySound(self, "race")
    PZLinuxBettingHide({ self.betInput, self.amountInput, self.startButton, self.errorLabel })

    self.raceProgress = {}
    self.raceFinished = false
    for index, zomb in ipairs(self.selectedZombies) do
        self.raceProgress[index] = { zombie = zomb, position = -15 }
        if self.zombieLabels[index] then
            self.zombieLabels[index]:setName(string.format("%d. %s", index, zomb.name))
        end
    end

    self:runRace()
end

function PZLinuxBettingUI:runRace()
    if self.raceFinished or not self.raceResult then return end

    for index, runner in ipairs(self.raceProgress) do
        local speed = PZLinuxRaceGetSpeed(runner.zombie.rating)
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

    if bestPosition >= PZLINUX_BETTING_RACE_DISTANCE then
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
        .. " @ "
        .. string.format("%.2f/1", tonumber(self.raceResult.finalOdds) or 0)

    for rank, data in ipairs(sortedRunners) do
        local progress = math.max(0, math.min(PZLINUX_BETTING_RACE_DISTANCE, data.runner.position))
        local icon = self.zombieIcons and self.zombieIcons[data.id]
        if icon then
            local trackStart = self.width * 0.42
            local trackWidth = self.width * 0.30
            icon:setX(trackStart + trackWidth * progress / PZLINUX_BETTING_RACE_DISTANCE)
        end
        if rank <= 6 then
            labelText = labelText .. "\n[" .. rank .. "] -> " .. data.id .. ": "
                .. data.runner.zombie.name .. " "
                .. string.format(
                    "%.2f/1",
                    tonumber(data.runner.zombie.odds)
                        or math.max(0, (tonumber(data.runner.zombie.multiplier) or 1) - 1)
                )
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

    self:requestRaceSettlement(function(result)
        if not result or not result.ok or self.isClosing then return end
        self:updateBalanceLabel(result.balance)

        local playerObj = PZLinuxBettingGetPlayer(self)
        PZLinuxBettingApplyOutcomeMood(playerObj, result.amount, result.previousBalance, result.payout, result.outcome)
        if result.outcome == "win" then
            PZLinuxBettingPlaySound(self, "sold")
        end
    end)
end

function PZLinuxBettingUI:requestRaceSettlement(callback)
    callback = callback or function() end
    if self.raceSettlement then
        callback(self.raceSettlement)
        return
    end
    if not self.raceResult or not self.raceResult.raceId then
        callback(nil)
        return
    end

    table.insert(self.raceSettlementCallbacks, callback)
    if self.raceSettlementInProgress then return end
    self.raceSettlementInProgress = true

    PZLinuxRequestRaceFinish(self.player, self.raceResult.raceId, function(result)
        self.raceSettlementInProgress = false
        if result and result.ok then
            self.raceSettlement = result
            self.raceResult.balance = result.balance
            self.raceResult.payout = result.payout
            self.raceResult.outcome = result.outcome
            self.raceResult.status = result.status
        end

        local callbacks = self.raceSettlementCallbacks
        self.raceSettlementCallbacks = {}
        for _, settlementCallback in ipairs(callbacks) do
            settlementCallback(result)
        end
    end)
end

function PZLinuxBettingUI:showBlackjackMenu()
    self.blackjackStakeMoodApplied = false
    self.blackjackControls = {}
    PZLinuxBettingClearDisplayControls(self.blackjackCardControls)
    self.blackjackCardControls = {}
    self:updateBalanceLabel(PZLinuxLoadBankBalance(self.player))

    self.blackjackTablePanel = PZLinuxBettingTablePanel:new(self.width * 0.195, self.height * 0.24, self.width * 0.58, self.height * 0.32)
    self.blackjackTablePanel:initialise()
    self.topBar:addChild(self.blackjackTablePanel)
    table.insert(self.blackjackControls, self.blackjackTablePanel)

    self.blackjackTitle = ISLabel:new(self.width * 0.43, self.height * 0.35, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_BlackjackTitle"), 1, 1, 0, 1, UIFont.Small, true)
    self.blackjackTitle:initialise()
    self.topBar:addChild(self.blackjackTitle)
    table.insert(self.blackjackControls, self.blackjackTitle)

    -- Fixed-stakes table picker, same idea as the Poker lobby list: pick a
    -- table before betting, and the amount you can type is capped to that
    -- table's own posted limits instead of being open-ended.
    self.blackjackTableButtons = {}
    local tableButtonWidth = self.width * 0.135
    local tableButtonX = self.width * 0.20
    for _, tableDef in ipairs(PZLinux.Config.Blackjack.tables) do
        local tableLabel = string.format("%s $%d-$%d", tableDef.id, tableDef.minBet, tableDef.maxBet)
        local tableButton = ISButton:new(tableButtonX, self.height * 0.565, tableButtonWidth, self.height * 0.03, tableLabel, self, self.onBlackjackSelectTable)
        tableButton.tableId = tableDef.id
        tableButton.textColor = {r=0, g=1, b=0, a=1}
        tableButton.backgroundColor = (tableDef.id == self.blackjackSelectedTableId) and {r=0, g=0.4, b=0, a=1} or {r=0, g=0, b=0, a=0.5}
        tableButton.borderColor = {r=0, g=1, b=0, a=0.5}
        tableButton:setVisible(true)
        tableButton:initialise()
        self.topBar:addChild(tableButton)
        table.insert(self.blackjackControls, tableButton)
        table.insert(self.blackjackTableButtons, tableButton)
        tableButtonX = tableButtonX + tableButtonWidth + self.width * 0.005
    end

    self.blackjackAmountInput = ISTextEntryBox:new(PZLinuxGetText("IGUI_PZLinux_Betting_Amount"), self.width * 0.20, self.height * 0.603, self.width * 0.18, self.height * 0.028)
    self.blackjackAmountInput:initialise()
    self.blackjackAmountInput:instantiate()
    self.blackjackAmountInput:setOnlyNumbers(true)
    self.topBar:addChild(self.blackjackAmountInput)
    table.insert(self.blackjackControls, self.blackjackAmountInput)

    self.blackjackDealButton = ISButton:new(self.width * 0.40, self.height * 0.603, self.width * 0.37, self.height * 0.04, PZLinuxGetText("IGUI_PZLinux_Betting_Deal"), self, self.onBlackjackDeal)
    self.blackjackDealButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackDealButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackDealButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackDealButton:setVisible(true)
    self.blackjackDealButton:initialise()
    self.topBar:addChild(self.blackjackDealButton)
    table.insert(self.blackjackControls, self.blackjackDealButton)

    self.blackjackDealerLabel = ISLabel:new(self.width * 0.435, self.height * 0.255, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Betting_Dealer"), 0, 1, 0, 1, UIFont.Small, true)
    self.blackjackDealerLabel:initialise()
    self.blackjackDealerLabel:setVisible(true)
    self.topBar:addChild(self.blackjackDealerLabel)
    table.insert(self.blackjackControls, self.blackjackDealerLabel)

    self.blackjackPlayerLabel = ISLabel:new(self.width * 0.44, self.height * 0.455, self.height * 0.025, "(YOU)", 0.2, 1, 0.8, 1, UIFont.Small, true)
    self.blackjackPlayerLabel:initialise()
    self.blackjackPlayerLabel:setVisible(true)
    self.topBar:addChild(self.blackjackPlayerLabel)
    table.insert(self.blackjackControls, self.blackjackPlayerLabel)

    self.blackjackMessageLabel = ISLabel:new(self.width * 0.35, self.height * 0.39, self.height * 0.025, "", 1, 1, 0, 1, UIFont.Small, true)
    self.blackjackMessageLabel:initialise()
    self.topBar:addChild(self.blackjackMessageLabel)
    table.insert(self.blackjackControls, self.blackjackMessageLabel)

    self.blackjackHitButton = ISButton:new(self.width * 0.20, self.height * 0.652, self.width * 0.25, self.height * 0.04, PZLinuxGetText("IGUI_PZLinux_Betting_Hit"), self, self.onBlackjackHit)
    self.blackjackHitButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackHitButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackHitButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackHitButton:setVisible(false)
    self.blackjackHitButton:initialise()
    self.topBar:addChild(self.blackjackHitButton)
    table.insert(self.blackjackControls, self.blackjackHitButton)

    self.blackjackStandButton = ISButton:new(self.width * 0.52, self.height * 0.652, self.width * 0.25, self.height * 0.04, PZLinuxGetText("IGUI_PZLinux_Betting_Stand"), self, self.onBlackjackStand)
    self.blackjackStandButton.textColor = {r=0, g=1, b=0, a=1}
    self.blackjackStandButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.blackjackStandButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.blackjackStandButton:setVisible(false)
    self.blackjackStandButton:initialise()
    self.topBar:addChild(self.blackjackStandButton)
    table.insert(self.blackjackControls, self.blackjackStandButton)
end

-- Debounce guard against a click landing twice in a very short window --
-- a mechanical mouse double-click defect, a rapid real double-click, or a
-- click racing the button's own :setEnable(false) before it takes effect
-- can all fire this handler twice almost simultaneously. Without this, a
-- second call can slip through and, depending on timing, land on
-- whatever action the (by-then-changed) button layout shows next -- e.g.
-- Hit or Stand appearing where Deal just was -- fast enough to blow
-- through a hand before the player consciously acts on it.
local PZLINUX_BLACKJACK_DEBOUNCE_MS = 250
local function PZLinuxBlackjackDebounced(self)
    local timestampProvider = rawget(_G, "getTimestampMs")
    local now = timestampProvider and tonumber(timestampProvider())
    if not now then return true end
    if self.blackjackLastActionMs and now - self.blackjackLastActionMs < PZLINUX_BLACKJACK_DEBOUNCE_MS then
        return false
    end
    self.blackjackLastActionMs = now
    return true
end

function PZLinuxBettingUI:onBlackjackSelectTable(button)
    self.blackjackSelectedTableId = button.tableId
    for _, tableButton in ipairs(self.blackjackTableButtons or {}) do
        tableButton.backgroundColor = (tableButton.tableId == self.blackjackSelectedTableId)
            and {r=0, g=0.4, b=0, a=1} or {r=0, g=0, b=0, a=0.5}
    end
    self:showBlackjackError("")
end

function PZLinuxBettingUI:onBlackjackDeal()
    if not PZLinuxBlackjackDebounced(self) then return end
    local amount = tonumber(self.blackjackAmountInput:getText())
    if not amount or amount < 1 then
        PZLinuxBettingPlaySound(self, "error")
        self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_InvalidBet"))
        return
    end

    -- Client-side pre-check, same courtesy as Poker's onPokerSelectLobby --
    -- the server re-validates this regardless (see PZLinuxBlackjackStart),
    -- this just avoids a round trip for an obviously out-of-range bet.
    local tableDef = PZLinuxBlackjackGetTable(self.blackjackSelectedTableId)
    if not tableDef or amount < tableDef.minBet or amount > tableDef.maxBet then
        PZLinuxBettingPlaySound(self, "error")
        self:showBlackjackError(PZLinuxFormatText(
            "IGUI_PZLinux_Betting_BlackjackBetRange",
            "This table's bet range is $%s-$%s",
            tableDef and tableDef.minBet or 0, tableDef and tableDef.maxBet or 0))
        return
    end

    self.blackjackStakeMoodApplied = false
    self.blackjackDealButton:setEnable(false)
    self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_Dealing"))

    -- See blackjackActionInFlight's use in forfeitBlackjackBeforeClose: this
    -- flag lets a close-panel forfeit wait for this request's own response
    -- instead of racing ahead of it.
    self.blackjackActionInFlight = true
    PZLinuxRequestBlackjackStart(self.player, self.blackjackSelectedTableId, amount, function(result)
        self.blackjackActionInFlight = false
        if not self.isClosing then
            self:showBlackjackState(result)
        end
        self:blackjackRunPendingForfeit()
    end)
end

function PZLinuxBettingUI:onBlackjackHit()
    if not PZLinuxBlackjackDebounced(self) then return end
    self.blackjackHitButton:setEnable(false)
    self.blackjackStandButton:setEnable(false)
    self.blackjackActionInFlight = true
    PZLinuxRequestBlackjackHit(self.player, function(result)
        self.blackjackActionInFlight = false
        if not self.isClosing then
            self:showBlackjackState(result)
        end
        self:blackjackRunPendingForfeit()
    end)
end

function PZLinuxBettingUI:onBlackjackStand()
    if not PZLinuxBlackjackDebounced(self) then return end
    self.blackjackHitButton:setEnable(false)
    self.blackjackStandButton:setEnable(false)
    self.blackjackActionInFlight = true
    PZLinuxRequestBlackjackStand(self.player, function(result)
        self.blackjackActionInFlight = false
        if not self.isClosing then
            self:showBlackjackState(result)
        end
        self:blackjackRunPendingForfeit()
    end)
end

function PZLinuxBettingUI:showBlackjackState(result)
    if not result or not result.ok then
        PZLinuxBettingPlaySound(self, "error")
        self.blackjackDealButton:setEnable(true)
        if result and result.error == "bet_out_of_range" then
            self:showBlackjackError(PZLinuxFormatText(
                "IGUI_PZLinux_Betting_BlackjackBetRange",
                "This table's bet range is $%s-$%s",
                result.minBet, result.maxBet))
        else
            self:showBlackjackError(PZLinuxGetText("IGUI_PZLinux_Betting_NotEnoughMoney"))
        end
        return
    end

    self:updateBalanceLabel(result.balance)

    PZLinuxBettingClearDisplayControls(self.blackjackCardControls)
    self.blackjackCardControls = {}

    PZLinuxBettingAddCardLine(self,
        self.blackjackCardControls,
        self.width * 0.39,
        self.height * 0.285,
        "",
        result.dealerHand,
        " (" .. tostring(result.dealerValue) .. (result.dealerHidden and "+?" or "") .. ")")

    PZLinuxBettingAddCardLine(self,
        self.blackjackCardControls,
        self.width * 0.39,
        self.height * 0.485,
        "",
        result.playerHand,
        " (" .. tostring(result.playerValue) .. ")")

    PZLinuxBettingAddDisplayControl(self,
        self.blackjackCardControls,
        ISLabel:new(self.width * 0.39, self.height * 0.42, self.height * 0.018,
            PZLinuxGetText("IGUI_PZLinux_Betting_YourBet") .. "$" .. tostring(result.bet or 0),
            1, 1, 0, 1, UIFont.Small, true))

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
        self.blackjackAmountInput:setVisible(true)
        PZLinuxBettingSetVisible(self.blackjackTableButtons, true)
        self.blackjackStakeMoodApplied = false
        if result.outcome == "win" or result.outcome == "blackjack" then
            PZLinuxBettingPlaySound(self, "sold")
        end
        return
    end

    self.blackjackDealButton:setVisible(false)
    self.blackjackAmountInput:setVisible(false)
    PZLinuxBettingSetVisible(self.blackjackTableButtons, false)
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

function PZLinuxBettingUI:cashOutPokerBeforeClose(afterCashOut)
    if self.pokerAutoCashoutInProgress then return end
    -- See onPokerAction: wait for any in-flight Call/Raise/Fold/etc. to land
    -- before deciding whether (and for how much) to auto-cash-out, or this
    -- can race ahead of that action's effect on the stack.
    if self.pokerActionInFlight then
        self.pokerPendingCashOutAfterAction = afterCashOut
        return
    end

    local session = self.pokerSession
    if not session or not session.sessionId or session.phase == "finished" or session.status == "closed" then
        afterCashOut()
        return
    end

    self.pokerAutoCashoutInProgress = true
    PZLinuxBettingHide(self.pokerControls)
    PZLinuxRequestPokerCashOut(self.player, session.sessionId, function(result)
        self.pokerAutoCashoutInProgress = false
        self.pokerSession = nil
        if result and result.balance then
            self:updateBalanceLabel(result.balance)
        end
        afterCashOut()
    end)
end

-- Runs a forfeit-on-close that got deferred by the guard above because a
-- Poker action was still in flight when the panel tried to close. Called
-- from that action's own callback once it lands.
function PZLinuxBettingUI:pokerRunPendingCashOut()
    if not self.pokerPendingCashOutAfterAction then return end
    local afterCashOut = self.pokerPendingCashOutAfterAction
    self.pokerPendingCashOutAfterAction = nil
    self:cashOutPokerBeforeClose(afterCashOut)
end

function PZLinuxBettingUI:settleRaceBeforeClose(afterSettlement)
    self:requestRaceSettlement(function()
        afterSettlement()
    end)
end

-- Closing the panel used to just abandon an in-progress Blackjack hand:
-- the bet had already been taken at Deal time, and nothing settled or
-- refunded it, unlike Race and Poker just above. Asking the server to
-- forfeit is safe whenever there's no hand in progress -- see
-- PZLinuxBlackjackForfeit, it's a no-op in that case.
--
-- It is NOT safe while a Deal/Hit/Stand request for the current hand is
-- still awaiting its server response, though: the Close/Minimize/Leave
-- buttons are never disabled the way Hit/Stand disable each other, so a
-- player can click Stand and then immediately click Leave before that
-- round trip completes. If the forfeit reaches the server first (or even
-- just before the in-flight action's own effects are accounted for on the
-- client), it refunds the hand as a "push" -- and when the real action's
-- result lands a moment later, the hand has already been wiped, so its
-- actual win/lose outcome is silently discarded. Net effect: the player
-- watches a hand play out and lose, but the earlier bet comes right back,
-- balance unchanged -- reported as "it's like free gambling". Waiting for
-- any in-flight action to land first (see blackjackActionInFlight in
-- onBlackjackDeal/Hit/Stand) closes that race.
function PZLinuxBettingUI:forfeitBlackjackBeforeClose(afterForfeit)
    if self.blackjackForfeitInProgress then return end
    if self.blackjackActionInFlight then
        self.blackjackPendingForfeitAfterAction = afterForfeit
        return
    end
    self.blackjackForfeitInProgress = true
    PZLinuxRequestBlackjackForfeit(self.player, function(result)
        self.blackjackForfeitInProgress = false
        if result and result.balance then
            self:updateBalanceLabel(result.balance)
        end
        afterForfeit()
    end)
end

-- Runs a forfeit-on-close that got deferred by the guard above because a
-- Deal/Hit/Stand request was still in flight when the panel tried to
-- close. Called from that action's own callback once it lands, so the
-- forfeit (if the panel still wants to close) always sees the hand's real,
-- fully-settled state instead of racing ahead of it.
function PZLinuxBettingUI:blackjackRunPendingForfeit()
    if not self.blackjackPendingForfeitAfterAction then return end
    local afterForfeit = self.blackjackPendingForfeitAfterAction
    self.blackjackPendingForfeitAfterAction = nil
    self:forfeitBlackjackBeforeClose(afterForfeit)
end

function PZLinuxBettingUI:settleGamesBeforeClose(afterSettlement)
    self:settleRaceBeforeClose(function()
        self:cashOutPokerBeforeClose(function()
            self:forfeitBlackjackBeforeClose(afterSettlement)
        end)
    end)
end

function PZLinuxBettingUI:onMinimize(_button)
    self:settleGamesBeforeClose(function()
        self.isClosing = true
        self:removeFromUIManager()
        local modData = PZLinuxBettingGetModData(self)
        if modData then
            modData.PZLinuxUIOpenMenu = 1
        end
    end)
end

function PZLinuxBettingUI:onMinimizeBack(_button)
    self:settleGamesBeforeClose(function()
        self.isClosing = true
        self:removeFromUIManager()
        local modData = PZLinuxBettingGetModData(self)
        if modData then
            modData.PZLinuxUIOpenMenu = 9
        end
    end)
end

function PZLinuxBettingUI:onClose(_button)
    self:settleGamesBeforeClose(function()
        self.isClosing = true
        self:removeFromUIManager()
        local modData = PZLinuxBettingGetModData(self)
        if modData then
            modData.PZLinuxUIOpenMenu = 1
        end
    end)
end

function PZLinuxBettingUI:onCloseX(_button)
    self:settleGamesBeforeClose(function()
        self.isClosing = true
        local playerObj = PZLinuxBettingGetPlayer(self)
        if playerObj then
            playerObj:StopAllActionQueue()
        end
    end)
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
