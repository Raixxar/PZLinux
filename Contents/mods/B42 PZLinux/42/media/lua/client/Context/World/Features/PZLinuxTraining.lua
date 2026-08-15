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
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.95}
    o.borderColor = {r=0, g=0.5, b=0, a=1}
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
    end

    self.titleLabel = ISLabel:new(self.width * 0.05, self.height * 0.04, self.height * 0.03, PZLinuxGetText("IGUI_PZLinux_Training_Title"), 0, 1, 0, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.90, self.height * 0.03, self.width * 0.06, self.height * 0.04, "X", self, self.onClose)
    self.closeButton.backgroundColor = {r=0.4, g=0, b=0, a=1}
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.statusLabel = ISLabel:new(self.width * 0.05, self.height * 0.10, self.height * 0.03, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.statusLabel:initialise()
    self.topBar:addChild(self.statusLabel)

    -- Active-course view: a progress bar plus a label, both hidden unless
    -- there's actually a course in progress (see refreshFromState).
    self.progressBar = ISProgressBar:new(self.width * 0.05, self.height * 0.18, self.width * 0.90, self.height * 0.06)
    self.progressBar:initialise()
    self.progressBar:setVisible(false)
    self.topBar:addChild(self.progressBar)

    self.activeLabel = ISLabel:new(self.width * 0.05, self.height * 0.26, self.height * 0.03, "", 0, 1, 0, 1, UIFont.Small, true)
    self.activeLabel:initialise()
    self.activeLabel:setVisible(false)
    self.topBar:addChild(self.activeLabel)

    -- Offers view: up to 3 rows, only shown when nothing is in progress.
    self.offerRows = {}
    for i = 1, 3 do
        local yOffset = self.height * (0.18 + (i - 1) * 0.14)

        local nameLabel = ISLabel:new(self.width * 0.05, yOffset, self.height * 0.03, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        nameLabel:setVisible(false)
        self.topBar:addChild(nameLabel)

        local detailLabel = ISLabel:new(self.width * 0.05, yOffset + self.height * 0.035, self.height * 0.025, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        detailLabel:initialise()
        detailLabel:setVisible(false)
        self.topBar:addChild(detailLabel)

        local buyButton = ISButton:new(self.width * 0.75, yOffset, self.width * 0.20, self.height * 0.05, PZLinuxGetText("IGUI_PZLinux_Training_Buy"), self, self.onBuyCourse)
        buyButton.backgroundColor = {r=0, g=0.3, b=0, a=1}
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
    if not playerObj then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()
    local finalW = math.min(600, realScreenW * 0.45)
    local finalH = math.min(520, realScreenH * 0.65)
    local uiX = (realScreenW - finalW) / 2
    local uiY = (realScreenH - finalH) / 2

    local ui = trainingUI:new(uiX, uiY, finalW, finalH, player)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    return ui
end
