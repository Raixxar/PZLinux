-- PZLinux Training - by Raixxar
-- Buy XP for money: 3 courses re-rolled weekly, one at a time, progress
-- gated by keeping this panel open (like watching a training video, the
-- same reason vanilla reading a skill book takes real in-game time and
-- stops the moment you stop reading) rather than passing regardless of
-- whether the player is actually here. See PZLinuxTrainingApplyProgressTick
-- (ISPZLinuxVariablesTables.lua) for why that's measured in-game (world
-- age hours), not real wall-clock time, and why the server -- not the
-- client -- is the one measuring it.

trainingUI = ISPanel:derive("trainingUI")

-- CONSTRUCTOR
function trainingUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    -- Fully transparent: like every other PZLinux computer app (Dark Web,
    -- Reputation, Trading, Check Condition, ...), the visible frame is the
    -- oldCRT.png bezel image drawn behind this panel in trainingMenu_ShowUI,
    -- not the panel's own background/border.
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    return o
end

-- INIT
function trainingUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar:onMouseDown(_x, _y)
        self.parent.isDragging = true
        PZLinuxTrackDragging(self.parent)
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
        if modData then
            modData.PZLinuxUIX = self.parent:getX()
            modData.PZLinuxUIY = self.parent:getY()
        end
    end

    -- Standard PZLinux computer-screen chrome, matching every other feature
    -- panel drawn over the oldCRT.png bezel (Reputation, Dark Web, Check
    -- Condition, ...): a bottom-left "X" over the screen's own physical
    -- stop button, and a minimize/close pair near the top-right corner.
    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:initialise()
    self.topBar:addChild(self.stopButton)

    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onClose)
    self.minimizeButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.20, self.height * 0.03, PZLinuxGetText("IGUI_PZLinux_Training_Title"), 0, 1, 0, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.statusLabel = ISLabel:new(self.width * 0.20, self.height * 0.26, self.height * 0.025, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.statusLabel:initialise()
    self.topBar:addChild(self.statusLabel)

    -- Active-course view: a progress bar plus a label, both hidden unless
    -- there's actually a course in progress (see applyState).
    self.progressBar = ISProgressBar:new(self.width * 0.20, self.height * 0.34, self.width * 0.57, self.height * 0.06)
    self.progressBar:initialise()
    self.progressBar:setVisible(false)
    self.topBar:addChild(self.progressBar)

    self.activeLabel = ISLabel:new(self.width * 0.20, self.height * 0.43, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.activeLabel:initialise()
    self.activeLabel:setVisible(false)
    self.topBar:addChild(self.activeLabel)

    -- Offers view: up to 3 rows, only shown when nothing is in progress.
    self.offerRows = {}
    for i = 1, 3 do
        local yOffset = self.height * (0.34 + (i - 1) * 0.15)

        local nameLabel = ISLabel:new(self.width * 0.20, yOffset, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        nameLabel:setVisible(false)
        self.topBar:addChild(nameLabel)

        local detailLabel = ISLabel:new(self.width * 0.20, yOffset + self.height * 0.035, self.height * 0.022, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        detailLabel:initialise()
        detailLabel:setVisible(false)
        self.topBar:addChild(detailLabel)

        local buyButton = ISButton:new(self.width * 0.63, yOffset, self.width * 0.14, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Training_Buy"), self, self.onBuyCourse)
        buyButton.textColor = {r=0, g=1, b=0, a=1}
        buyButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
        buyButton.borderColor = {r=0, g=1, b=0, a=0.5}
        buyButton:initialise()
        buyButton:setVisible(false)
        self.topBar:addChild(buyButton)

        self.offerRows[i] = { name = nameLabel, detail = detailLabel, button = buyButton }
    end

    self:refresh()
end

-- Mirrors the established Hacking pattern (PZLinuxHacking.lua's
-- stopTransferAnimation/stopBootAnimation): a dedicated field for this
-- animation, and a helper that always tears down any previous instance by
-- its own captured reference before a new one is ever created, called
-- both when a new tick loop starts and on every close handler. Prevents
-- the exact orphaned-Events.OnTick-handler bug class fixed there.
function trainingUI:stopTickLoop()
    if self.tickHandler then
        Events.OnTick.Remove(self.tickHandler)
    end
    self.tickHandler = nil
end

function trainingUI:startTickLoop()
    self:stopTickLoop()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    self.tickPending = false
    self.tickHandler = function()
        if self.isClosing then self:stopTickLoop() return end
        if self.tickPending then return end
        -- Real-time paced (not every single frame) so this doesn't spam
        -- the server -- roughly twice a second is plenty smooth for a
        -- progress bar while keeping request volume low.
        local nowMs = getTimestampMs and getTimestampMs() or 0
        if self.lastTickRequestMs and (nowMs - self.lastTickRequestMs) < 500 then return end
        self.lastTickRequestMs = nowMs
        self.tickPending = true
        PZLinuxRequestTrainingTick(player, function(result)
            self.tickPending = false
            if self.isClosing then return end
            if result and result.ok then
                if result.completed then
                    self:stopTickLoop()
                    getSoundManager():PlayWorldSound("levelup", false, player:getSquare(), 0, 20, 1, true)
                    HaloTextHelper.addGoodText(player, string.format(PZLinuxGetText("IGUI_PZLinux_Training_Completed"), tostring(result.xpGranted)))
                end
                self:applyState(result)
            end
        end)
    end
    Events.OnTick.Add(self.tickHandler)
end

function trainingUI:applyState(state)
    self.currentOffers = state.offers or self.currentOffers or {}
    self.currentActive = state.active

    if state.balance then
        saveAtmBalance(state.balance, self.player)
    end

    if self.currentActive then
        self.progressBar:setVisible(true)
        self.activeLabel:setVisible(true)
        self.progressBar:setProgress(self.currentActive.progress or 0)
        local percent = math.floor((self.currentActive.progress or 0) * 100)
        self.progressBar:setText(tostring(percent) .. "%")
        -- PZLinuxTrainingResolveOffer comes from PZLinuxTrainingData.lua, a
        -- shared file required by shared/ISPZLinuxVariablesTables.lua, so
        -- it's already loaded client-side too -- no need to have the server
        -- also echo the name key back in the active-course state.
        local activeCourse = PZLinuxTrainingResolveOffer(self.currentActive.courseId)
        local courseName = activeCourse and PZLinuxGetText(activeCourse.nameKey) or tostring(self.currentActive.courseId)
        self.activeLabel:setName(string.format(PZLinuxGetText("IGUI_PZLinux_Training_InProgress"), courseName))
        self.statusLabel:setName(PZLinuxGetText("IGUI_PZLinux_Training_StayHere"))

        for _, row in ipairs(self.offerRows) do
            row.name:setVisible(false)
            row.detail:setVisible(false)
            row.button:setVisible(false)
        end

        self:startTickLoop()
    else
        self.progressBar:setVisible(false)
        self.activeLabel:setVisible(false)
        self:stopTickLoop()
        self.statusLabel:setName(PZLinuxGetText("IGUI_PZLinux_Training_ChooseCourse"))

        for i, row in ipairs(self.offerRows) do
            local offer = self.currentOffers[i]
            if offer then
                row.name:setName(PZLinuxGetText(offer.nameKey))
                row.detail:setName(string.format(
                    PZLinuxGetText("IGUI_PZLinux_Training_Detail"),
                    tostring(offer.xp), tostring(offer.price), tostring(offer.durationHours)))
                row.button.internal = offer.id
                row.name:setVisible(true)
                row.detail:setVisible(true)
                row.button:setVisible(true)
            else
                row.name:setVisible(false)
                row.detail:setVisible(false)
                row.button:setVisible(false)
            end
        end
    end
end

function trainingUI:refresh()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end
    PZLinuxRequestTrainingState(player, function(result)
        if self.isClosing then return end
        if result and result.ok then
            self:applyState(result)
        end
    end)
end

function trainingUI:onBuyCourse(button)
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    if button.setEnable then button:setEnable(false) end
    PZLinuxRequestTrainingPurchase(player, button.internal, function(result)
        if button.setEnable then button:setEnable(true) end
        if self.isClosing then return end

        if result and result.ok then
            getSoundManager():PlayWorldSound("keyboard1", false, player:getSquare(), 0, 20, 1, true)
            self:applyState(result)
        else
            getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true)
            if result and result.error == "training_in_progress" then
                HaloTextHelper.addBadText(player, PZLinuxGetText("IGUI_PZLinux_Training_AlreadyInProgress"))
            else
                HaloTextHelper.addBadText(player, "I need money in my bank account")
            end
        end
    end)
end

function trainingUI:onClose(_button)
    self.isClosing = true
    self:stopTickLoop()
    self:removeFromUIManager()
    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUIOpenMenu = 1
end

function trainingUI:onCloseX(_button)
    self.isClosing = true
    self:stopTickLoop()
    local player = PZLinuxGetPlayer(self.player)
    if player then
        player:StopAllActionQueue()
    end
end

function trainingMenu_ShowUI(player)
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

    local ui = trainingUI:new(x, y, width, height, player)
    local background = ISImage:new(0, 0, width, height, texture)
    background.scaled = true
    background.scaledWidth = width
    background.scaledHeight = height
    ui:addChild(background)
    ui.centeredImage = background
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    return ui
end
