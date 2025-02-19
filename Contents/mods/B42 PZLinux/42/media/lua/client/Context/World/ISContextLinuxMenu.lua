linuxUI = ISPanel:derive("linuxUI")

local STAY_CONNECTED_TIME = 0
local CONNECTED_TO_INTERNET_TIME = 0

-- CONSTRUCTOR
function linuxUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    o.isConnected = false
    o.isDragging = false
    return o
end

-- INIT
function linuxUI:initialise()
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
    end

    self.closeButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onClose)
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=0, b=0, a=1}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.closeButton:setAnchorRight(true)
    self.topBar:addChild(self.closeButton)

    self.bootOutput = ISRichTextPanel:new(self.width * 0.15, self.height * 0.25, self.width * 0.65, self.height * 0.45)
    self.bootOutput.backgroundColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.borderColor = {r=0, g=0, b=0, a=0}
    self.bootOutput.autosetheight = false
    self.bootOutput:setVisible(true)
    self.bootOutput:initialise()
    self.topBar:addChild(self.bootOutput)

    -- PROMPT CLI
    self.promptLabel = ISLabel:new(self.width * 0.20, self.height * 0.195, self.height * 0.025, "Welcome to PZLinux v.0.1.7-rc1.", 0, 1, 0, 1, UIFont.Small, true)
    self.promptLabel:setVisible(false)
    self.promptLabel:initialise()
    self.topBar:addChild(self.promptLabel)

    self.helpLabel = ISLabel:new(self.width * 0.20, self.height * 0.40, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.helpLabel:setVisible(false)
    self.helpLabel:initialise()
    self.topBar:addChild(self.helpLabel)

    self.notConnectButton = ISButton:new(self.width * 0.20, self.height * 0.17, self.width * 0.05, self.height * 0.025, "NOT CONNECTED", self, self.onStop)
    self.notConnectButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.notConnectButton.borderColor = {r=0, g=0, b=0, a=1}
    self.notConnectButton:setVisible(true)
    self.notConnectButton:initialise()
    self.topBar:addChild(self.notConnectButton)

    self.connectButton = ISButton:new(self.width * 0.20, self.height * 0.17, self.width * 0.05, self.height * 0.025, "CONNECTED", self, self.onStop)
    self.connectButton.backgroundColor = {r=0, g=0.5, b=0, a=0.5}
    self.connectButton.borderColor = {r=0, g=0, b=0, a=1}
    self.connectButton:setVisible(false)
    self.connectButton:initialise()
    self.topBar:addChild(self.connectButton)

    self.internetButton = ISButton:new(self.width * 0.20, self.height * 0.23, self.width * 0.05, self.height * 0.025, "CONNECT", self, self.onInternet)
    self.internetButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.internetButton.textColor = {r=0, g=1, b=0, a=1}
    self.internetButton.borderColor = {r=0, g=0, b=0, a=0}
    self.internetButton:setVisible(false)
    self.internetButton:initialise()
    self.topBar:addChild(self.internetButton)

    self.darkWebButton = ISButton:new(self.width * 0.20, self.height * 0.26, self.width * 0.05, self.height * 0.025, "DARK WEB", self, self.onDarkWeb)
    self.darkWebButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.darkWebButton.textColor = {r=0, g=1, b=0, a=1}
    self.darkWebButton.borderColor = {r=0, g=0, b=0, a=0}
    self.darkWebButton:setVisible(false)
    self.darkWebButton:initialise()
    self.topBar:addChild(self.darkWebButton)

    self.tradingButton = ISButton:new(self.width * 0.20, self.height * 0.29, self.width * 0.05, self.height * 0.025, "TRADING", self, self.onTrading)
    self.tradingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.tradingButton.textColor = {r=0, g=1, b=0, a=1}
    self.tradingButton.borderColor = {r=0, g=0, b=0, a=0}
    self.tradingButton:setVisible(false)
    self.tradingButton:initialise()
    self.topBar:addChild(self.tradingButton)

    self.walletButton = ISButton:new(self.width * 0.20, self.height * 0.32, self.width * 0.05, self.height * 0.025, "WALLET", self, self.onWallet)
    self.walletButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.walletButton.textColor = {r=0, g=1, b=0, a=1}
    self.walletButton.borderColor = {r=0, g=0, b=0, a=0}
    self.walletButton:setVisible(false)
    self.walletButton:initialise()
    self.topBar:addChild(self.walletButton)

    self.hackingIdButton = ISButton:new(self.width * 0.20, self.height * 0.35, self.width * 0.05, self.height * 0.025, "HACK AN ID CARD", self, self.onHackingId)
    self.hackingIdButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.hackingIdButton.textColor = {r=0, g=1, b=0, a=1}
    self.hackingIdButton.borderColor = {r=0, g=0, b=0, a=0}
    self.hackingIdButton:setVisible(false)
    self.hackingIdButton:initialise()
    self.topBar:addChild(self.hackingIdButton)

    self.contractsButton = ISButton:new(self.width * 0.20, self.height * 0.38, self.width * 0.05, self.height * 0.025, "CONTRACTS", self, self.onContracts)
    self.contractsButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.contractsButton.textColor = {r=0, g=1, b=0, a=1}
    self.contractsButton.borderColor = {r=0, g=0, b=0, a=0}
    self.contractsButton:setVisible(false)
    self.contractsButton:initialise()
    self.topBar:addChild(self.contractsButton)
end

-- CLOSE
function linuxUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
end

function linuxUI:onBoot()
    local player = getSpecificPlayer(0)
    local globalVolume = getCore():getOptionSoundVolume() / 10
    getSoundManager():PlayWorldSound("computerBoot", false, player:getSquare(), 0, 100, 1, true):setVolume(globalVolume)
    self.bootMessages = {
        "<RGB:0,1,0>PZLinux version v.0.1.7-rc1 (POSIX compliant)",
        "Copyright (c) 1991 The PZLinux Project",
        "The Regents of the University of Louisville, Kentucky, USA",
        "",
        "Booting PZLinux...",
        "Loading kernel version 1.0.0 (Wed Feb 6 12:00:00 UTC 1991)",
        "Memory: 4096k/4096k available (512k kernel, 256k reserved, 1024k shared)",
        "Kernel command line: root=/dev/hda1 ro",
        "",
        "Checking 386/387 coupling... OK",
        "Calibrating delay loop... 5.27 BogoMIPS",
        "Checking BIOS EDD... OK",
        "",
        "Detecting hardware...",
        " ide0: BM-DMA at 0x1f0-0x1f7,0x3f6 on IRQ 14",
        " ide1: BM-DMA at 0x170-0x177,0x376 on IRQ 15",
        " hda: CONNER CP-3204F, 420MB, CHS=683/16/38, UDMA(16)",
        " hdb: MAXTOR 7213AT, 213MB, CHS=683/16/38, UDMA(16)",
        " hdc: CD-ROM 2X, ATAPI CD/DVD-ROM drive",
        " Floppy drive(s): fd0 is 1.44M",
        " FDC 0 is a post-1991 82077",
        "",
        "Partition check:",
        " hda: hda1 hda2",
        " hdb: hdb1",
        "",
        "RAMDISK: Compressed image found at block 0",
        "",
        "Mounting root filesystem...",
        "EXT2-fs: mounted filesystem with ordered data mode.",
        "VFS: Mounted root (ext2 filesystem) readonly on device 03:01.",
        "Freeing unused kernel memory: 128k freed",
        "",
        "INIT: version 1.0 booting",
        "Setting hostname to pzlinux.local",
        "Checking filesystems",
        "/dev/hda1: clean, 3021/32768 files, 10540/131072 blocks",
        "/dev/hdb1: clean, 2498/16384 files, 7340/65536 blocks",
        "",
        "Mounting local filesystems... done",
        "Initializing random number generator... done",
        "Starting system log daemon: syslogd, klogd",
        "Starting network services: inetd, named",
        "Starting virtual terminals: tty1 tty2 tty3 tty4",
        "",
        "PZLinux v.0.1.7-rc1 (tty1)</RGB>"
    }

    self.terminalCoroutine = coroutine.create(function()
        local elapsed = 0
        local initialDelay = 2.0
        while elapsed < initialDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = elapsed + 0.016
        end

        for _, line in ipairs(self.bootMessages) do
            if self.isClosing then return end

            self.bootOutput.text = self.bootOutput.text .. "\n" .. line
            self.bootOutput:paginate()

            local maxYScroll = self.bootOutput:getScrollHeight() - self.bootOutput:getHeight()
            if maxYScroll > 0 then
                self.bootOutput:setYScroll(-maxYScroll)
            end

            local lineDelay = ZombRand(1, 10) / 15 
            elapsed = 0
            while elapsed < lineDelay do
                coroutine.yield()
                elapsed = elapsed + 0.016
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
            self:onPrompt()
        end
    end
    Events.OnTick.Add(self.updateCoroutineFunc)
end

function linuxUI:onPrompt()
    self.bootOutput:setVisible(false)
    self.promptLabel:setVisible(true)
    self.internetButton:setVisible(true)
    self.darkWebButton:setVisible(true)
    self.tradingButton:setVisible(true)
    self.walletButton:setVisible(true)
    self.hackingIdButton:setVisible(true)
    self.contractsButton:setVisible(true)
end

function linuxUI:onHackingId()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        hackingMenu_ShowUI(player)
    else
        self.promptLabel:setName("You need to connect first. Click on 'CONNECT'")
    end
end

function linuxUI:onInternet()
    if self.isConnected == false then
        CONNECTED_TO_INTERNET_TIME = math.ceil(getGameTime():getWorldAgeHours())
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        self.isConnected = true
        connectMenu_ShowUI(player)
    end
end

function linuxUI:onDarkWeb()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        darkWebMenu_ShowUI(player)
    else
        self.promptLabel:setName("You need to connect first. Click on 'CONNECT'")
    end
end

function linuxUI:onTrading()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        tradingMenu_ShowUI(player)
    else
        self.promptLabel:setName("You need to connect first. Click on 'CONNECT'")
    end
end

function linuxUI:onWallet()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        walletMenu_ShowUI(player)
    else
        self.promptLabel:setName("You need to connect first. Click on 'CONNECT'")
    end
end

function linuxUI:onContracts()
    if self.isConnected == true then
        --self.promptLabel:setVisible(false)
        --self.helpLabel:setVisible(false)
        --self:onClose()
        --contractsMenu_ShowUI(player)
        self.promptLabel:setName("Available in a future update.")
    else
        self.promptLabel:setName("Available in a future update.")
    end
end

function linuxUI:onConnect()
    self.notConnectButton:setVisible(false)
    self.connectButton:setVisible(true)
end

-- UI
function linuxMenu_ShowUI(player)
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
    local uiX, uiY = (realScreenW - finalW) / 2, (realScreenH - finalH) / 2

    local ui = linuxUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)
    
    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()

    local getHourTime = math.ceil(getGameTime():getWorldAgeHours())
    if getHourTime < 24 then
        getHourTime = 24
    end

    if getHourTime < CONNECTED_TO_INTERNET_TIME + 24 then
        ui.isConnected = true
        ui:onConnect()
    end

    if getHourTime < STAY_CONNECTED_TIME + 24 then
        ui:onPrompt()
    else
        ui:onBoot()
        STAY_CONNECTED_TIME = getHourTime
    end
end

-- CONTEXT MENU
function linuxMenu_AddContext(player, context, worldobjects)
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoObject") then
            local sprite = obj:getSprite()
            if sprite and sprite:getName() then
                if string.find(sprite:getName(), "appliances_com_01_75")
                or string.find(sprite:getName(), "appliances_com_01_74")
                or string.find(sprite:getName(), "appliances_com_01_73") 
                or string.find(sprite:getName(), "appliances_com_01_72") then
                    local square = obj:getSquare()
                    if square and ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or 
                     (getSandboxOptions():getElecShutModifier() > -1 and 
                     (getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30) < getSandboxOptions():getElecShutModifier())) then
                        context:addOption("PZLinux", obj, linuxMenu_OnUse, player)
                        break
                    end
                end
            end
        end
    end
end

function linuxMenu_OnUse(worldObject, player)
    CancelAction(player)
    linuxMenu_ShowUI(player)
end

Events.OnFillWorldObjectContextMenu.Add(linuxMenu_AddContext)
