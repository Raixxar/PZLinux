conditionUI = ISPanel:derive("conditionUI")

-- CONSTRUCTOR
function conditionUI:new(x, y, width, height, player)
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

-- INIT
function conditionUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar:onMouseDown(x, y)
        self.parent.isDragging = true
        self.parent.initialX = self.parent:getX()
        self.parent.initialY = self.parent:getY()
        self.parent.mouseStartX = getMouseX()
        self.parent.mouseStartY = getMouseY()
    end

    function self.topBar:onMouseMove(x, y)
        if self.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - self.parent.mouseStartX
            local dy = curMouseY - self.parent.mouseStartY
            self.parent:setX(self.parent.initialX + dx)
            self.parent:setY(self.parent.initialY + dy)
        end
    end

    function self.topBar:onMouseUp(x, y)
        self.parent.isDragging = false
        local modData = getPlayer():getModData()
        modData.PZLinuxUIX = self.parent:getX()
        modData.PZLinuxUIY = self.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    local modData = getPlayer():getModData()
    if modData.PZLinuxUISFX == 0 then
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    else
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    end

    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimize)
    self.minimizeButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeButton:setVisible(true)
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)
end

-- LOGOUT
function conditionUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

-- LOGOUT
function conditionUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function conditionUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function conditionUI:onSFXOn(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxUISFX = 0
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

function conditionUI:onSFXOff(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxUISFX = 1
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

-- ID CARD
function conditionUI:onCheckCondition()
    self.bootOutput = ISRichTextPanel:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.45)
    self.bootOutput.backgroundColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.borderColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.autosetheight = false
    self.bootOutput:setVisible(true)
    self.bootOutput:initialise()
    self.topBar:addChild(self.bootOutput)

    if getPlayer():getModData().PZLinuxComputerCondition < 25 then
        self.bootMessages = {
            "<RGB:0,1,0>Booting system...",
            "Initializing hardware check...",
            "Memory check: ",
            "Checking system RAM...",
            "RAM test successful: 8MB detected.",
            "Running RAM diagnostic...",
            "RAM error detected on slot 2... [Warning]",
            "Memory test complete. No further issues.",
            "Disk check initiated...",
            "Checking disk integrity...",
            "Checking file system with FSCK...",
            "Checking allocated sectors...",
            "Disk check complete: No bad sectors found.",
            "Performing full disk scan...",
            "Disk scan complete: 2 minor issues detected.",
            "Fixing minor issues...",
            "Reallocating damaged sectors...",
            "Disk health: 32%",
            "Running S.M.A.R.T. diagnostics...",
            "S.M.A.R.T. status: OK",
            "Checking system files...",
            "Scanning system files for corruption...",
            "No critical system file corruption detected.",
            "Running file system check...",
            "File system check complete: 24 Errors.",
            "Checking disk space...",
            "Total disk space: 250MB",
            "Free space: 20MB",
            "Checking system temperature...",
            "System temperature: 54C [Warning]",
            "Overheating detected... [Warning] CPU temp: 75°C",
            "Cooling system functioning normally.",
            "Checking peripheral devices...",
            "Checking keyboard... OK",
            "Mouse detected... OK",
            "Printer offline... [Error]",
            "Checking virtual memory settings...",
            "Virtual memory: Allocated 64MB, 55MB in use.",
            "Checking system resources...",
            "CPU usage: 15%",
            "Available memory: 6MB",
            "Checking system logs...",
            "System log: No critical errors logged.",
            "Disk log: Minor read/write delays detected.",
            "Final check...",
            "System check complete.",
            "No critical issues found.",
            "System operating at 45% efficiency.",
            "Warning: Minor performance degradation detected.",
            "Running system optimization...",
            "Optimization complete.",
            "System health: Stable.",
            "Access granted. Secure system operation restored.",
            "System report: Critical issues detected! Immediate attention required.",
            "Disk failure imminent. Backup recommended.</RGB>"
        }
    elseif getPlayer():getModData().PZLinuxComputerCondition < 50 then
        self.bootMessages = {
            "<RGB:0,1,0>Booting system...",
            "Initializing hardware check...",
            "Memory check: ",
            "Checking system RAM...",
            "RAM test detected an error on slot 2... [Warning]",
            "Attempting RAM reallocation...",
            "RAM reallocation successful. System stability: 85%",
            "Disk check initiated...",
            "Checking disk integrity...",
            "Checking file system with FSCK...",
            "Checking allocated sectors...",
            "Warning: 4 bad sectors found!",
            "Attempting sector reallocation...",
            "Reallocation successful. Data integrity maintained.",
            "Running S.M.A.R.T. diagnostics...",
            "S.M.A.R.T. status: WARNING - Disk wear detected",
            "Checking system files...",
            "Corrupt system file found: /etc/sysconfig/",
            "Attempting automatic repair...",
            "Repair successful.",
            "Checking disk space...",
            "Total disk space: 500MB",
            "Free space: 95MB (Low)",
            "Checking system temperature...",
            "System temperature: 42C (Acceptable)",
            "Checking peripheral devices...",
            "Keyboard... OK",
            "Mouse detected... OK",
            "Printer offline... [Error]",
            "Checking system resources...",
            "CPU usage: 45%",
            "Available memory: 4MB",
            "Final check...",
            "System check complete with warnings.",
            "Performance degradation detected.",
            "Recommend maintenance soon.",
            "System operational, but errors detected.</RGB>"
        }
    else
        self.bootMessages = {
            "<RGB:0,1,0>Booting system...",
            "Initializing hardware check...",
            "Memory check: ",
            "Checking system RAM...",
            "RAM test successful: 16MB detected.",
            "Running RAM diagnostic...",
            "Memory test complete. No errors found.",
            "Disk check initiated...",
            "Checking disk integrity...",
            "Checking file system with FSCK...",
            "Checking allocated sectors...",
            "Disk check complete: No bad sectors found.",
            "Running S.M.A.R.T. diagnostics...",
            "S.M.A.R.T. status: OK",
            "Checking system files...",
            "Scanning system files for corruption...",
            "No critical system file corruption detected.",
            "Checking disk space...",
            "Total disk space: 500MB",
            "Free space: 320MB",
            "Checking system temperature...",
            "System temperature: 28C (Optimal)",
            "Checking peripheral devices...",
            "Keyboard... OK",
            "Mouse detected... OK",
            "Printer online... OK",
            "Checking system resources...",
            "CPU usage: 10%",
            "Available memory: 12MB",
            "System optimization complete.",
            "System health: Optimal.",
            "System check completed successfully.</RGB>"
        }
    end

    local messages = {}
    self.terminalCoroutine = coroutine.create(function()
        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local initialDelay = elapsed + 1

        for _, line in ipairs(self.bootMessages) do
            if self.isClosing then return end

            self.bootOutput.text = self.bootOutput.text .. "\n" .. line
            self.bootOutput:paginate()

            local maxYScroll = self.bootOutput:getScrollHeight() - self.bootOutput:getHeight()
            if maxYScroll > 0 then
                self.bootOutput:setYScroll(-maxYScroll)
            end

            local lineDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(10, 20)
            while elapsed < lineDelay do
                coroutine.yield()
                elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
            end
        end
    end)

    self.updateCoroutineFunc = function()
        if coroutine.status(self.terminalCoroutine) ~= "dead" then
            coroutine.resume(self.terminalCoroutine)
        else
            Events.OnTick.Remove(self.updateCoroutineFunc)
            self.updateCoroutineFunc = nil
            self.terminalCoroutine = nil
            self:onConditionSummary()
        end
    end
    Events.OnTick.Add(self.updateCoroutineFunc)
end 

function conditionUI:onConditionSummary()
    self.bootOutput:setVisible(false)
    self.conditionSummaryButton = ISButton:new(self.width * 0.35, self.width * 0.32, self.width * 0.25, self.height * 0.08, "Computer Condition: " .. getPlayer():getModData().PZLinuxComputerCondition .. "%")
    self.conditionSummaryButton.textColor = {r=0, g=1, b=0, a=1}
    self.conditionSummaryButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.conditionSummaryButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.conditionSummaryButton:setVisible(true)
    self.conditionSummaryButton:initialise()
    self.topBar:addChild(self.conditionSummaryButton)
end


function conditionMenu_ShowUI(player)
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
    
    local modData = getPlayer():getModData()
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = conditionUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
    ui:onCheckCondition()

    return ui
end
