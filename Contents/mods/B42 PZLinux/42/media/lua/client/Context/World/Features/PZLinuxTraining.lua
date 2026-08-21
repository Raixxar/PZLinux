-- PZLinux Training - by Raixxar
-- Buy XP for money: 3 courses re-rolled weekly, one at a time, progress
-- gated by keeping this panel open (like watching a training video, the
-- same reason vanilla reading a skill book takes real in-game time and
-- stops the moment you stop reading) rather than passing regardless of
-- whether the player is actually here. See PZLinuxTrainingApplyProgressTick
-- (ISPZLinuxVariablesTables.lua) for why that's measured in-game (world
-- age hours), not real wall-clock time, and why the server -- not the
-- client -- is the one measuring it.

-- PZLinux's own %s-substitution convention (PZLinuxFormatText,
-- ISPZLinuxVariablesTables.lua) still has a real client-side cost here:
-- the game's own native Translator unconditionally tries to format any
-- translated string that contains a raw "%s" the moment getText(key)
-- resolves it, even though PZLinux always does its own substitution
-- afterward in Lua -- throwing (and catching, and logging) a genuine Java
-- exception on every single lookup either way. That was tolerable for a
-- label only rebuilt on real state changes, but this panel's offer list
-- calls it once per card (up to 3 times) on every click -- selecting a
-- card, cancelling back to the list, a fresh refresh -- and 3 synchronous
-- Java exceptions back to back was a real, player-visible hitch, reported
-- as "sometimes nothing happens when I click, I need to click again."
-- Training's own placeholder-bearing keys (Detail, InProgress, Completed)
-- use "{1}"/"{2}"/"{3}" instead of "%s" so the native lookup never even
-- sees a percent sign to trip over -- substitution still happens entirely
-- in Lua, exactly like PZLinuxFormatText already does for "%s" elsewhere.
local function PZLinuxTrainingFormat(template, ...)
    local values = { ... }
    for index = 1, select("#", ...) do
        template = template:gsub("{" .. index .. "}", tostring(values[index] or ""), 1)
    end
    return template
end

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

    -- Offers view: up to 3 clickable "course card" rows, name and price/
    -- duration stacked inside each one, only shown when nothing is in
    -- progress. Clicking a card never spends money by itself -- it only
    -- selects it (onSelectCourse); paying requires the separate Pay/
    -- Cancel confirmation below, so a stray click on a card can never
    -- charge the player by accident. From player feedback: wanted this to
    -- look like Buy Goods' list of clickable rows, with an explicit
    -- confirm/cancel step before any money moves.
    self.offerRows = {}
    for i = 1, 3 do
        local cardY = self.height * (0.30 + (i - 1) * 0.14)
        local cardWidth = self.width * 0.57
        local cardHeight = self.height * 0.12

        local card = ISButton:new(self.width * 0.20, cardY, cardWidth, cardHeight, "", self, self.onSelectCourse)
        card.textColor = {r=0, g=1, b=0, a=1}
        card.backgroundColor = {r=0, g=0, b=0, a=0.5}
        card.borderColor = {r=0, g=1, b=0, a=0.5}
        card:initialise()
        card:setVisible(false)
        self.topBar:addChild(card)

        local nameLabel = ISLabel:new(cardWidth * 0.04, cardHeight * 0.20, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        card:addChild(nameLabel)

        local detailLabel = ISLabel:new(cardWidth * 0.04, cardHeight * 0.55, self.height * 0.022, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        detailLabel:initialise()
        card:addChild(detailLabel)

        self.offerRows[i] = { card = card, name = nameLabel, detail = detailLabel }
    end

    -- Confirm step: only shown once a card above has actually been
    -- clicked, one explicit "Pay" or "Cancel" away from spending money.
    -- Centered in the middle of the screen, on its own -- every card
    -- (including the one just selected) is hidden while this is showing,
    -- rather than reusing the list's own row positions, so this reads as
    -- a clean standalone confirmation instead of a leftover gap where the
    -- other 2 cards used to be.
    self.confirmLabel = ISLabel:new(self.width * 0.20, self.height * 0.47, self.height * 0.03, "", 0, 1, 0, 1, UIFont.Small, true)
    self.confirmLabel:initialise()
    self.confirmLabel:setVisible(false)
    self.topBar:addChild(self.confirmLabel)

    self.payButton = ISButton:new(self.width * 0.20, self.height * 0.55, self.width * 0.26, self.height * 0.06, PZLinuxGetText("IGUI_PZLinux_Training_Buy"), self, self.onPayCourse)
    self.payButton.textColor = {r=0, g=1, b=0, a=1}
    self.payButton.backgroundColor = {r=0, g=0.25, b=0, a=0.7}
    self.payButton.borderColor = {r=0, g=1, b=0, a=1}
    self.payButton:initialise()
    self.payButton:setVisible(false)
    self.topBar:addChild(self.payButton)

    self.cancelButton = ISButton:new(self.width * 0.51, self.height * 0.55, self.width * 0.26, self.height * 0.06, PZLinuxGetText("IGUI_PZLinux_Training_Cancel"), self, self.onCancelSelection)
    self.cancelButton.textColor = {r=1, g=0.4, b=0.4, a=1}
    self.cancelButton.backgroundColor = {r=0.25, g=0, b=0, a=0.7}
    self.cancelButton.borderColor = {r=0.6, g=0, b=0, a=1}
    self.cancelButton:initialise()
    self.cancelButton:setVisible(false)
    self.topBar:addChild(self.cancelButton)

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
                    -- "GainExperienceLevel" is vanilla's own properly-scripted
                    -- sound for actually leveling up a skill (Game/LevelUp,
                    -- captioned "Level Up" in every language's subtitle
                    -- settings). The plain string "levelup" instead resolves
                    -- directly to media/sound/levelup.ogg/.wav, a leftover
                    -- legacy asset (its old SoundBanks.lua alias is commented
                    -- out) with a fuller fanfare mix including a vocal chant
                    -- layer that doesn't match the rest of the game's actual
                    -- level-up moments -- from player feedback, only the
                    -- guitar sting vanilla itself uses was wanted here.
                    getSoundManager():PlayWorldSound("GainExperienceLevel", false, player:getSquare(), 0, 20, 1, true)
                    HaloTextHelper.addGoodText(player, PZLinuxTrainingFormat(PZLinuxGetText("IGUI_PZLinux_Training_Completed"), result.xpGranted))
                    -- A completion response doesn't carry a fresh offers
                    -- list (see PZLinuxTrainingApplyProgressTick) -- refresh
                    -- from the server instead of applying it directly, so
                    -- the just-finished course correctly disappears from
                    -- the list right away instead of the panel still
                    -- showing a stale, already-consumed card the player
                    -- could click on.
                    self.selectedOfferId = nil
                    self:refresh()
                else
                    self:applyState(result)
                end
            end
        end)
    end
    Events.OnTick.Add(self.tickHandler)
end

function trainingUI:applyState(state)
    self.currentOffers = state.offers or self.currentOffers or {}
    self.currentActive = state.active

    if state.balance ~= nil then
        saveAtmBalance(state.balance, self.player)
    end

    if self.currentActive then
        self.progressBar:setVisible(true)
        self.activeLabel:setVisible(true)
        self.progressBar:setProgress(self.currentActive.progress or 0)
        local percent = math.floor((self.currentActive.progress or 0) * 100)
        self.progressBar:setText(tostring(percent) .. "%")

        -- The course name/label text never changes between ticks -- only
        -- the progress bar above does -- so only rebuild it when the
        -- active course itself changes (just started, or the panel
        -- reopened mid-course), instead of re-resolving and re-formatting
        -- the same translation on every ~500ms tick response. Cheap either
        -- way now that InProgress uses "{1}" instead of "%s" (see
        -- PZLinuxTrainingFormat at the top of this file), but there is
        -- still no reason to redo the same lookup+string-build twice a
        -- second for text that never actually changes.
        if self.activeLabelCourseId ~= self.currentActive.courseId then
            self.activeLabelCourseId = self.currentActive.courseId
            -- PZLinuxTrainingResolveOffer comes from PZLinuxTrainingData.lua,
            -- a shared file required by shared/ISPZLinuxVariablesTables.lua,
            -- so it's already loaded client-side too -- no need to have the
            -- server also echo the name key back in the active-course state.
            local activeCourse = PZLinuxTrainingResolveOffer(self.currentActive.courseId)
            local courseName = activeCourse and PZLinuxGetText(activeCourse.nameKey) or tostring(self.currentActive.courseId)
            self.activeLabel:setName(PZLinuxTrainingFormat(PZLinuxGetText("IGUI_PZLinux_Training_InProgress"), courseName))
            self.statusLabel:setName(PZLinuxGetText("IGUI_PZLinux_Training_StayHere"))
        end

        self.selectedOfferId = nil
        for _, row in ipairs(self.offerRows) do
            row.card:setVisible(false)
        end
        self.confirmLabel:setVisible(false)
        self.payButton:setVisible(false)
        self.cancelButton:setVisible(false)

        self:startTickLoop()
    else
        self.progressBar:setVisible(false)
        self.activeLabel:setVisible(false)
        self.activeLabelCourseId = nil
        self:stopTickLoop()
        self:refreshOfferView()
    end
end

-- Two sub-states, neither of which spends money on its own: a LIST of up
-- to 3 clickable course cards (nothing selected yet), or a CONFIRM view
-- for exactly the one card the player just clicked (every other card
-- hidden, a recap line, and the actual Pay/Cancel buttons) -- paying
-- always requires this explicit second step. Also called after every
-- refresh() so a stale selection (the offer got bought/consumed
-- elsewhere, or the week rolled over) safely falls back to the list
-- instead of confirming a purchase that can no longer succeed.
function trainingUI:refreshOfferView()
    local selectedOffer = nil
    if self.selectedOfferId then
        for _, offer in ipairs(self.currentOffers) do
            if offer.id == self.selectedOfferId then selectedOffer = offer end
        end
        if not selectedOffer then self.selectedOfferId = nil end
    end

    self.statusLabel:setName(PZLinuxGetText("IGUI_PZLinux_Training_ChooseCourse"))

    if selectedOffer then
        -- Every card is hidden here, including the one just selected --
        -- the confirm view is a clean standalone screen centered on its
        -- own (see the constructor), not the list with 2 rows missing.
        for _, row in ipairs(self.offerRows) do
            row.card:setVisible(false)
        end

        local courseName = PZLinuxGetText(selectedOffer.nameKey)
        local detail = PZLinuxTrainingFormat(
            PZLinuxGetText("IGUI_PZLinux_Training_Detail"),
            selectedOffer.xp, selectedOffer.price, selectedOffer.durationHours)
        self.confirmLabel:setName(courseName .. " - " .. detail)
        self.confirmLabel:setVisible(true)
        self.payButton:setVisible(true)
        self.cancelButton:setVisible(true)
    else
        self.confirmLabel:setVisible(false)
        self.payButton:setVisible(false)
        self.cancelButton:setVisible(false)

        for i, row in ipairs(self.offerRows) do
            local offer = self.currentOffers[i]
            if offer then
                row.card.internal = offer.id
                row.card.borderColor = {r=0, g=1, b=0, a=0.5}
                row.card.backgroundColor = {r=0, g=0, b=0, a=0.5}
                row.name:setName(PZLinuxGetText(offer.nameKey))
                row.detail:setName(PZLinuxTrainingFormat(
                    PZLinuxGetText("IGUI_PZLinux_Training_Detail"),
                    offer.xp, offer.price, offer.durationHours))
                row.card:setVisible(true)
            else
                row.card:setVisible(false)
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

-- Selecting a card never spends money -- it only narrows the list down to
-- the one card clicked and reveals the Pay/Cancel confirmation below it
-- (refreshOfferView). Actually paying is a separate, explicit step
-- (onPayCourse), so a stray click on a card can never charge the player.
function trainingUI:onSelectCourse(button)
    self.selectedOfferId = button.internal
    self:refreshOfferView()
end

function trainingUI:onCancelSelection(_button)
    self.selectedOfferId = nil
    self:refreshOfferView()
end

function trainingUI:onPayCourse(button)
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end
    local offerId = self.selectedOfferId
    if not offerId then return end

    if button.setEnable then button:setEnable(false) end
    if self.cancelButton and self.cancelButton.setEnable then self.cancelButton:setEnable(false) end
    PZLinuxRequestTrainingPurchase(player, offerId, function(result)
        if button.setEnable then button:setEnable(true) end
        if self.cancelButton and self.cancelButton.setEnable then self.cancelButton:setEnable(true) end
        if self.isClosing then return end

        if result and result.ok then
            getSoundManager():PlayWorldSound("keyboard1", false, player:getSquare(), 0, 20, 1, true)
            self.selectedOfferId = nil
            self:applyState(result)
        else
            getSoundManager():PlayWorldSound("error", false, player:getSquare(), 0, 20, 1, true)
            -- Show the REAL reason instead of always blaming money -- a
            -- hardcoded "not enough money" for every failure was actively
            -- misleading (a player reported having $100,000 and still
            -- being refused an $80,000 course: the real reason was an
            -- offer that was no longer valid, not their balance).
            local errorCode = result and result.error
            if errorCode == "training_in_progress" then
                HaloTextHelper.addBadText(player, PZLinuxGetText("IGUI_PZLinux_Training_AlreadyInProgress"))
            elseif errorCode == "not_enough_money" then
                HaloTextHelper.addBadText(player, PZLinuxGetText("IGUI_PZLinux_Training_NotEnoughMoney"))
            elseif errorCode == "invalid_course" then
                -- The offer clicked is no longer valid server-side (bought
                -- out from under the player, or the week rolled over
                -- between refreshes) -- resync the list instead of leaving
                -- a phantom card the player could keep retrying forever.
                self.selectedOfferId = nil
                HaloTextHelper.addBadText(player, PZLinuxGetText("IGUI_PZLinux_Training_CourseNoLongerAvailable"))
                self:refresh()
            else
                HaloTextHelper.addBadText(player, PZLinuxGetText("IGUI_PZLinux_Training_PurchaseFailed"))
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
