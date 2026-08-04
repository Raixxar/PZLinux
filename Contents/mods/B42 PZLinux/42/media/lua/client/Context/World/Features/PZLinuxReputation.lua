PZLinuxReputationUI = ISPanel:derive("PZLinuxReputationUI")

local function PZLinuxReputationText(key, fallback, ...)
    return PZLinuxFormatText(key, fallback, ...)
end

local function PZLinuxReputationRoundedNumber(value)
    value = tonumber(value) or 0
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

local function PZLinuxReputationStatusText(status)
    local labels = {
        blacklisted = { "IGUI_PZLinux_Reputation_StatusBlacklisted", "BLACKLISTED" },
        distrusted = { "IGUI_PZLinux_Reputation_StatusDistrusted", "DISTRUSTED" },
        neutral = { "IGUI_PZLinux_Reputation_StatusNeutral", "NEUTRAL" },
        known = { "IGUI_PZLinux_Reputation_StatusKnown", "KNOWN" },
        reliable = { "IGUI_PZLinux_Reputation_StatusReliable", "RELIABLE" },
        preferred = { "IGUI_PZLinux_Reputation_StatusPreferred", "PREFERRED" },
    }
    local label = labels[status] or labels.neutral
    return PZLinuxReputationText(label[1], label[2])
end

local function PZLinuxReputationMailText(frequency)
    if frequency == "reduced" then
        return PZLinuxReputationText("IGUI_PZLinux_Reputation_MailReduced", "REDUCED")
    end
    if frequency == "improved" then
        return PZLinuxReputationText("IGUI_PZLinux_Reputation_MailImproved", "IMPROVED")
    end
    return PZLinuxReputationText("IGUI_PZLinux_Reputation_MailNormal", "NORMAL")
end

local function PZLinuxReputationPercent(value)
    local rounded = PZLinuxReputationRoundedNumber(value)
    local formatted = tostring(math.abs(rounded))
    if rounded > 0 then return "+" .. formatted .. "%" end
    if rounded < 0 then return "-" .. formatted .. "%" end
    return "0%"
end

function PZLinuxReputationUI:new(x, y, width, height, player)
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

function PZLinuxReputationUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
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
        if not topBar.parent.isDragging then return end
        topBar.parent:setX(topBar.parent.initialX + getMouseX() - topBar.parent.mouseStartX)
        topBar.parent:setY(topBar.parent.initialY + getMouseY() - topBar.parent.mouseStartY)
    end

    function self.topBar.onMouseUp(topBar, _x, _y)
        topBar.parent.isDragging = false
        local playerObj = PZLinuxGetPlayer(topBar.parent.player)
        local modData = playerObj and playerObj:getModData()
        if modData then
            modData.PZLinuxUIX = topBar.parent:getX()
            modData.PZLinuxUIY = topBar.parent:getY()
        end
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:initialise()
    self.topBar:addChild(self.stopButton)

    self.backButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onBack)
    self.backButton.textColor = {r=0, g=1, b=0, a=1}
    self.backButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.backButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.backButton:initialise()
    self.topBar:addChild(self.backButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onBack)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.titleLabel = ISLabel:new(
        self.width * 0.20,
        self.height * 0.20,
        self.height * 0.03,
        PZLinuxReputationText("IGUI_PZLinux_Reputation_Title", "NETWORK REPUTATION"),
        0, 1, 0, 1, UIFont.Medium, true
    )
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.content = ISRichTextPanel:new(self.width * 0.20, self.height * 0.26, self.width * 0.57, self.height * 0.36)
    self.content.backgroundColor = {r=0, g=0, b=0, a=0}
    self.content.borderColor = {r=0, g=0, b=0, a=0}
    self.content.autosetheight = false
    self.content.text = "<RGB:0,1,0>" .. PZLinuxReputationText("IGUI_PZLinux_Reputation_Loading", "Loading reputation...")
    self.content:initialise()
    self.content:instantiate()
    self.content:paginate()
    self.topBar:addChild(self.content)

    self.menuButton = ISButton:new(
        self.width * 0.20,
        self.height * 0.66,
        self.width * 0.57,
        self.height * 0.05,
        PZLinuxReputationText("IGUI_PZLinux_Reputation_Back", "BACK"),
        self,
        self.onBack
    )
    self.menuButton.textColor = {r=0, g=1, b=0, a=1}
    self.menuButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.menuButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.menuButton:initialise()
    self.topBar:addChild(self.menuButton)

    self:refreshSnapshot()
end

function PZLinuxReputationUI:refreshSnapshot()
    PZLinuxRequestReputationSnapshot(self.player, function(snapshot)
        if self.isClosing or not self.content then return end
        if not snapshot or not snapshot.ok then
            self.content.text = "<RGB:1,0.7,0>" .. PZLinuxReputationText(
                "IGUI_PZLinux_Reputation_Unavailable",
                "Reputation service unavailable."
            )
            self.content:paginate()
            return
        end

        local lines = {
            PZLinuxReputationText("IGUI_PZLinux_Reputation_Score", "Score: %s (range %s to %s)",
                PZLinuxReputationRoundedNumber(snapshot.reputation),
                PZLinuxReputationRoundedNumber(snapshot.minimum),
                PZLinuxReputationRoundedNumber(snapshot.maximum)),
            PZLinuxReputationText("IGUI_PZLinux_Reputation_Status", "Status: %s",
                PZLinuxReputationStatusText(snapshot.status)),
            "",
            PZLinuxReputationText("IGUI_PZLinux_Reputation_PriceModifier", "Purchase prices: %s",
                PZLinuxReputationPercent(snapshot.purchaseModifierPercent)),
            PZLinuxReputationText("IGUI_PZLinux_Reputation_MailFrequency", "Mail frequency: %s",
                PZLinuxReputationMailText(snapshot.mailFrequency)),
            "",
            PZLinuxReputationText("IGUI_PZLinux_Reputation_CompletionGain", "Contract or mail mission completed: +%s",
                PZLinuxReputationRoundedNumber(snapshot.completionReward)),
            PZLinuxReputationText("IGUI_PZLinux_Reputation_CancelPenalty", "Contract cancelled: -%s",
                PZLinuxReputationRoundedNumber(snapshot.cancellationPenalty)),
            PZLinuxReputationText("IGUI_PZLinux_Reputation_Decay", "Without activity, reputation gradually returns to neutral."),
        }

        if snapshot.nextStatus and snapshot.pointsToNext then
            table.insert(lines, "")
            table.insert(lines, PZLinuxReputationText(
                "IGUI_PZLinux_Reputation_NextStatus",
                "Next status: %s (%s points)",
                PZLinuxReputationStatusText(snapshot.nextStatus),
                PZLinuxReputationRoundedNumber(snapshot.pointsToNext)
            ))
        else
            table.insert(lines, "")
            table.insert(lines, PZLinuxReputationText(
                "IGUI_PZLinux_Reputation_MaxStatus",
                "Highest reputation status reached."
            ))
        end

        -- ISRichTextPanel:paginate() tokenizes on spaces; a word glued
        -- directly to a following tag (e.g. "neutralité.<LINE>") gets
        -- swallowed by the tag's token and never rendered. A space on each
        -- side of <LINE> avoids that -- it's exactly what the engine itself
        -- inserts when converting "\n".
        self.content.text = "<RGB:0,1,0>" .. table.concat(lines, " <LINE> ")
        self.content:paginate()
        local maxYScroll = math.max(0, self.content:getScrollHeight() - self.content:getHeight())
        if self.content.vscroll then self.content.vscroll:setVisible(maxYScroll > 0) end
        self.content:setYScroll(0)
    end)
end

function PZLinuxReputationUI:onBack(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local playerObj = PZLinuxGetPlayer(self.player)
    local modData = playerObj and playerObj:getModData()
    if modData then modData.PZLinuxUIOpenMenu = 1 end
end

function PZLinuxReputationUI:onCloseX(_button)
    self.isClosing = true
    local playerObj = PZLinuxGetPlayer(self.player)
    if playerObj then playerObj:StopAllActionQueue() end
end

function reputationMenu_ShowUI(player)
    local playerObj = PZLinuxGetPlayer(player)
    local texture = getTexture("media/ui/oldCRT.png")
    if not playerObj or not texture then return end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local scale = math.min(screenWidth * 0.70 / texture:getWidth(), screenHeight * 0.70 / texture:getHeight())
    local width = math.floor(texture:getWidth() * scale)
    local height = math.floor(texture:getHeight() * scale)
    local modData = playerObj:getModData()
    local x = modData.PZLinuxUIX or (screenWidth - width) / 2
    local y = modData.PZLinuxUIY or (screenHeight - height) / 2

    local ui = PZLinuxReputationUI:new(x, y, width, height, playerObj)
    local background = ISImage:new(0, 0, width, height, texture)
    background.scaled = true
    background.scaledWidth = width
    background.scaledHeight = height
    ui:addChild(background)
    ui.centeredImage = background
    ui:initialise()
    ui:addToUIManager()
    return ui
end
