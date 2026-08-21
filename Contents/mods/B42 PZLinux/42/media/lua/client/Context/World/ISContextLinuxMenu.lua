linuxUI = ISPanel:derive("linuxUI")

local STAY_CONNECTED_TIME = 0
local CONNECTED_TO_INTERNET_TIME = 0
local PZLinuxVersion = "v1.0.15"

local function PZLinuxMainShowConnectRequired(ui)
    ui.promptLabel:setName(PZLinuxGetText("IGUI_PZLinux_Main_ConnectFirst"))
end

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
        local modData = PZLinuxGetModData(topBar.parent.player)
        if modData then
            modData.PZLinuxUIX = topBar.parent:getX()
            modData.PZLinuxUIY = topBar.parent:getY()
        end
    end

    self.closeButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
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
    self.promptLabel = ISLabel:new(self.width * 0.20, self.height * 0.195, self.height * 0.025,
        PZLinuxFormatText("IGUI_PZLinux_Main_Welcome", "Welcome to PZLinux %s.", PZLinuxVersion),
        0, 1, 0, 1, UIFont.Small, true)
    self.promptLabel:setVisible(false)
    self.promptLabel:initialise()
    self.topBar:addChild(self.promptLabel)

    self.helpLabel = ISLabel:new(self.width * 0.20, self.height * 0.40, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
    self.helpLabel:setVisible(false)
    self.helpLabel:initialise()
    self.topBar:addChild(self.helpLabel)

    self.notConnectButton = ISButton:new(self.width * 0.20, self.height * 0.17, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_NotConnected"), self, self.onNetworkStatus)
    self.notConnectButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.notConnectButton.borderColor = {r=0, g=0, b=0, a=1}
    self.notConnectButton:setVisible(true)
    self.notConnectButton:initialise()
    self.topBar:addChild(self.notConnectButton)

    self.connectButton = ISButton:new(self.width * 0.20, self.height * 0.17, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Connected"), self, self.onNetworkStatus)
    self.connectButton.backgroundColor = {r=0, g=0.5, b=0, a=0.5}
    self.connectButton.borderColor = {r=0, g=0, b=0, a=1}
    self.connectButton:setVisible(false)
    self.connectButton:initialise()
    self.topBar:addChild(self.connectButton)

    self.internetButton = ISButton:new(self.width * 0.20, self.height * 0.23, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Connect"), self, self.onInternet)
    self.internetButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.internetButton.textColor = {r=0, g=1, b=0, a=1}
    self.internetButton.borderColor = {r=0, g=0, b=0, a=0}
    self.internetButton:setVisible(false)
    self.internetButton:initialise()
    self.topBar:addChild(self.internetButton)

    self.mailLabel = ISLabel:new(self.width * 0.71, self.height * 0.155, self.height * 0.05, "[@]", 0, 1, 0, 1, UIFont.Small, true)
    self.mailLabel:setVisible(false)
    self.mailLabel:initialise()
    self.topBar:addChild(self.mailLabel)

    local md = PZLinuxGetModData(self.player)
    if md then
        md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}
        for _, mail in ipairs(md.pzlinux.mails.inbox) do
            if mail.read == false then
                self.mailLabel:setVisible(true)
            end
        end
    end

    self.darkWebButton = ISButton:new(self.width * 0.20, self.height * 0.26, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_DarkWeb"), self, self.onDarkWeb)
    self.darkWebButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.darkWebButton.textColor = {r=0, g=1, b=0, a=1}
    self.darkWebButton.borderColor = {r=0, g=0, b=0, a=0}
    self.darkWebButton:setVisible(false)
    self.darkWebButton:initialise()
    self.topBar:addChild(self.darkWebButton)

    self.tradingButton = ISButton:new(self.width * 0.20, self.height * 0.29, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Trading"), self, self.onTrading)
    self.tradingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.tradingButton.textColor = {r=0, g=1, b=0, a=1}
    self.tradingButton.borderColor = {r=0, g=0, b=0, a=0}
    self.tradingButton:setVisible(false)
    self.tradingButton:initialise()
    self.topBar:addChild(self.tradingButton)

    self.walletButton = ISButton:new(self.width * 0.20, self.height * 0.32, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Wallet"), self, self.onWallet)
    self.walletButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.walletButton.textColor = {r=0, g=1, b=0, a=1}
    self.walletButton.borderColor = {r=0, g=0, b=0, a=0}
    self.walletButton:setVisible(false)
    self.walletButton:initialise()
    self.topBar:addChild(self.walletButton)

    self.hackingIdButton = ISButton:new(self.width * 0.20, self.height * 0.35, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_HackCard"), self, self.onHackingId)
    self.hackingIdButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.hackingIdButton.textColor = {r=0, g=1, b=0, a=1}
    self.hackingIdButton.borderColor = {r=0, g=0, b=0, a=0}
    self.hackingIdButton:setVisible(false)
    self.hackingIdButton:initialise()
    self.topBar:addChild(self.hackingIdButton)

    self.contractsButton = ISButton:new(self.width * 0.20, self.height * 0.38, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Contracts"), self, self.onContracts)
    self.contractsButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.contractsButton.textColor = {r=0, g=1, b=0, a=1}
    self.contractsButton.borderColor = {r=0, g=0, b=0, a=0}
    self.contractsButton:setVisible(false)
    self.contractsButton:initialise()
    self.topBar:addChild(self.contractsButton)

    self.requestButton = ISButton:new(self.width * 0.20, self.height * 0.41, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_BuyGoods"), self, self.onRequest)
    self.requestButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.requestButton.textColor = {r=0, g=1, b=0, a=1}
    self.requestButton.borderColor = {r=0, g=0, b=0, a=0}
    self.requestButton:setVisible(false)
    self.requestButton:initialise()
    self.topBar:addChild(self.requestButton)

    -- Grouped directly below BUY GOODS since both are the same feature pair
    -- (buying and selling everyday goods), rather than at the bottom of the
    -- list.
    self.sellButton = ISButton:new(self.width * 0.20, self.height * 0.44, self.width * 0.05, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Sell_Title"), self, self.onSell)
    self.sellButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.sellButton.textColor = {r=0, g=1, b=0, a=1}
    self.sellButton.borderColor = {r=0, g=0, b=0, a=0}
    self.sellButton:setVisible(false)
    self.sellButton:initialise()
    self.topBar:addChild(self.sellButton)

    self.bettingButton = ISButton:new(self.width * 0.20, self.height * 0.47, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_OnlineBetting"), self, self.onBetting)
    self.bettingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.bettingButton.textColor = {r=0, g=1, b=0, a=1}
    self.bettingButton.borderColor = {r=0, g=0, b=0, a=0}
    self.bettingButton:setVisible(false)
    self.bettingButton:initialise()
    self.topBar:addChild(self.bettingButton)

    self.mailButton = ISButton:new(self.width * 0.20, self.height * 0.50, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Mail"), self, self.onMail)
    self.mailButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.mailButton.textColor = {r=0, g=1, b=0, a=1}
    self.mailButton.borderColor = {r=0, g=0, b=0, a=0}
    self.mailButton:setVisible(false)
    self.mailButton:initialise()
    self.topBar:addChild(self.mailButton)

    self.reputationButton = ISButton:new(self.width * 0.20, self.height * 0.53, self.width * 0.05, self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Reputation_Button"), self, self.onReputation)
    self.reputationButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.reputationButton.textColor = {r=0, g=1, b=0, a=1}
    self.reputationButton.borderColor = {r=0, g=0, b=0, a=0}
    self.reputationButton:setVisible(false)
    self.reputationButton:initialise()
    self.topBar:addChild(self.reputationButton)

    self.conditionButton = ISButton:new(self.width * 0.20, self.height * 0.56, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_CheckCondition"), self, self.onCondition)
    self.conditionButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.conditionButton.textColor = {r=0, g=1, b=0, a=1}
    self.conditionButton.borderColor = {r=0, g=0, b=0, a=0}
    self.conditionButton:setVisible(false)
    self.conditionButton:initialise()
    self.topBar:addChild(self.conditionButton)

    self.trainingButton = ISButton:new(self.width * 0.20, self.height * 0.59, self.width * 0.05,
        self.height * 0.025, PZLinuxGetText("IGUI_PZLinux_Main_Training"), self, self.onTraining)
    self.trainingButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.trainingButton.textColor = {r=0, g=1, b=0, a=1}
    self.trainingButton.borderColor = {r=0, g=0, b=0, a=0}
    self.trainingButton:setVisible(false)
    self.trainingButton:initialise()
    self.topBar:addChild(self.trainingButton)
end

-- CLOSE
function linuxUI:onCloseX(_button)
    self.isClosing = true
    local player = PZLinuxGetPlayer(self.player)
    if player then
        PZLinuxRequestContractSync(player)
        player:StopAllActionQueue()
    end
end

function linuxUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
end

function linuxUI.onNetworkStatus(_self, _button)
end

function linuxUI:onBoot()
    local player = PZLinuxGetPlayer(self.player)
    if not player then return end

    local modData = player:getModData()
    local globalVolume = getCore():getOptionSoundVolume() / 50

    if modData.PZLinuxComputerCondition <= 25 then
        getSoundManager():PlayWorldSound("computerBootLow", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    elseif modData.PZLinuxComputerCondition <= 50 then
        getSoundManager():PlayWorldSound("computerBootMedium", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    else
        getSoundManager():PlayWorldSound("computerBoot", false, player:getSquare(), 0, 20, 1, true):setVolume(globalVolume)
    end

    self.bootMessages = {
        "<RGB:0,1,0>PZLinux version " .. PZLinuxVersion .. " (POSIX compliant)",
        "Copyright (c) 1991 The PZLinux Project",
        "The Regents of the University of Louisville, Kentucky, USA",
        "Booting PZLinux...",
        "Loading kernel version 1.0.0 (Wed Feb 6 12:00:00 UTC 1991)",
        "Memory: 4096k/4096k available (512k kernel, 256k reserved, 1024k shared)",
        "Kernel command line: root=/dev/hda1 ro",
        "Checking 386/387 coupling... OK",
        "Calibrating delay loop... 5.27 BogoMIPS",
        "Checking BIOS EDD... OK",
        "Detecting hardware...",
        " ide0: BM-DMA at 0x1f0-0x1f7,0x3f6 on IRQ 14",
        " ide1: BM-DMA at 0x170-0x177,0x376 on IRQ 15",
        " hda: CONNER CP-3204F, 420MB, CHS=683/16/38, UDMA(16)",
        " hdb: MAXTOR 7213AT, 213MB, CHS=683/16/38, UDMA(16)",
        " hdc: CD-ROM 2X, ATAPI CD/DVD-ROM drive",
        " Floppy drive(s): fd0 is 1.44M",
        " FDC 0 is a post-1991 82077",
        "Partition check:",
        " hda: hda1 hda2",
        " hdb: hdb1",
        "RAMDISK: Compressed image found at block 0",
        "Mounting root filesystem...",
        "EXT2-fs: mounted filesystem with ordered data mode.",
        "VFS: Mounted root (ext2 filesystem) readonly on device 03:01.",
        "Freeing unused kernel memory: 128k freed",
        "INIT: version 1.0 booting",
        "Setting hostname to pzlinux.local",
        "Checking filesystems",
        "/dev/hda1: clean, 3021/32768 files, 10540/131072 blocks",
        "/dev/hdb1: clean, 2498/16384 files, 7340/65536 blocks",
        "Mounting local filesystems... done",
        "Initializing random number generator... done",
        "Starting system log daemon: syslogd, klogd",
        "Starting network services: inetd, named",
        "Starting virtual terminals: tty1 tty2 tty3 tty4",
        "PZLinux  " .. PZLinuxVersion .. " (tty1)</RGB>"
    }

    self.terminalCoroutine = coroutine.create(function()
        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local initialDelay = elapsed + 1
        while elapsed < initialDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        for _, line in ipairs(self.bootMessages) do
            if self.isClosing then return end

            self.bootOutput.text = self.bootOutput.text .. "\n" .. line
            self.bootOutput:paginate()

            local maxYScroll = self.bootOutput:getScrollHeight() - self.bootOutput:getHeight()
            if maxYScroll > 0 then
                self.bootOutput:setYScroll(-maxYScroll)
            end

            local lineDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(1, 10)
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
    self.requestButton:setVisible(true)
    self.bettingButton:setVisible(true)
    self.mailButton:setVisible(true)
    self.reputationButton:setVisible(true)
    self.conditionButton:setVisible(true)
    self.sellButton:setVisible(true)
    self.trainingButton:setVisible(true)
end

function linuxUI:onInternet()
    if self.isConnected == false then
        CONNECTED_TO_INTERNET_TIME = math.ceil(getGameTime():getWorldAgeHours())
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()
        self.isConnected = true

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 2
        PZLinuxTrading_initializePrices(self.player)
    end
end

function linuxUI:onDarkWeb()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 3
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onTrading()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 4
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onWallet()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 5
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onHackingId()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 6
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onContracts()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 7
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onRequest()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 8
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onBetting()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 9
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onMail()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 10
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onReputation()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 11
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onCondition()
    self.promptLabel:setVisible(false)
    self.helpLabel:setVisible(false)
    self:onClose()

    local modData = PZLinuxGetModData(self.player)
    if not modData then return end
    modData.PZLinuxUIOpenMenu = 20
end

function linuxUI:onSell()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 12
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onTraining()
    if self.isConnected == true then
        self.promptLabel:setVisible(false)
        self.helpLabel:setVisible(false)
        self:onClose()

        local modData = PZLinuxGetModData(self.player)
        if not modData then return end
        modData.PZLinuxUIOpenMenu = 13
    else
        PZLinuxMainShowConnectRequired(self)
    end
end

function linuxUI:onConnect()
    self.notConnectButton:setVisible(false)
    self.connectButton:setVisible(true)
end

-- UI
function linuxMenu_ShowUI(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

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

    local modData = playerObj:getModData()
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = linuxUI:new(uiX, uiY, finalW, finalH, playerObj)
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

    return ui
end

-- CONTEXT MENU
function linuxMenu_AddContext(player, context, worldobjects)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local modData = playerObj:getModData()
    modData.PZLinuxUIX = nil
    modData.PZLinuxUIY = nil
    local squareClicked = playerObj:getSquare()
    local targetX, targetY, targetZ = squareClicked:getX(), squareClicked:getY(), squareClicked:getZ()

    local function PZLinuxLinuxMenuTryObject(obj, square)
        local sprite = obj and obj.getSprite and obj:getSprite()
        local spriteName = sprite and sprite.getName and sprite:getName()
        -- Exact match, not a substring search -- see
        -- ISContextStreetMailBox.lua for the bug class this avoids.
        if spriteName ~= "appliances_com_01_75"
        and spriteName ~= "appliances_com_01_74"
        and spriteName ~= "appliances_com_01_73"
        and spriteName ~= "appliances_com_01_72" then
            return false
        end
        if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or
         (getSandboxOptions():getElecShutModifier() > -1 and
         (getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30) < getSandboxOptions():getElecShutModifier())) then
            return false
        end
        local x, y, z = square:getX(), square:getY(), square:getZ()
        if not isNearTargetCapture(x, y, z, targetX, targetY, targetZ) then return false end

        -- Repair used to only ever appear below 15%, so a single repair
        -- attempt (which adds a random amount well above that threshold
        -- almost every time) immediately made the option disappear again,
        -- leaving the computer stuck well short of full health instead of
        -- being repairable back to 100% over multiple attempts. It now
        -- shows any time the computer is below a "healthy" 80% buffer, so
        -- players can keep repairing (spending Electronic Scrap each time)
        -- until it's actually back to full condition, without the option
        -- nagging over every single point of cosmetic wear near 100%.
        if not obj:getModData().statusCondition then obj:getModData().statusCondition = ZombRand(1,100) end
        if obj:getModData().statusCondition < 80 then
            context:addOption(PZLinuxGetText("IGUI_PZLinux_Context_RepairComputer"), obj, linuxMenu_OnRepare, playerObj, x, y, z, spriteName)
        end
        if obj:getModData().statusCondition > 0 then
            context:addOption("PZLinux", obj, linuxMenu_OnUse, playerObj, x, y, z, spriteName)
        end
        return true
    end

    -- worldobjects is the list vanilla decided to show a menu for on the
    -- clicked square(s) -- it can skip a computer placed on top of
    -- furniture (a counter, a table) in favor of the furniture itself,
    -- even though the computer is still really there. Rescanning each of
    -- those squares' FULL object list (not just what vanilla picked out)
    -- catches that case without widening which squares get considered at
    -- all -- isNearTargetCapture above still gates it to the player's
    -- immediate surroundings either way.
    local checkedSquares = {}
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoObject") then
            local square = obj.getSquare and obj:getSquare()
            if square and not checkedSquares[square] then
                checkedSquares[square] = true
                local found = false
                local squareObjects = square:getObjects()
                for index = 0, squareObjects:size() - 1 do
                    if PZLinuxLinuxMenuTryObject(squareObjects:get(index), square) then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
    end
end

function linuxMenu_OnUse(obj, player, x, y, z, sprite, _square)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    playerObj:getModData().PZLinuxComputerCondition = tonumber(obj:getModData().statusCondition) or 0
    ISTimedActionQueue.add(ISPZLinuxAction:new(playerObj, obj))
end

function linuxMenu_OnRepare(obj, player, x, y, z, sprite, _square)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local playerSquare = playerObj:getSquare()
    if math.abs(playerSquare:getX() - x) + math.abs(playerSquare:getY() - y) > 1 then
        local freeSquare = PZLinuxGetAdjacentFreeSquare(x, y, z, sprite)
        if freeSquare then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, freeSquare))
        end
    end
    ISTimedActionQueue.add(ISPZLinuxRepareAction:new(playerObj, obj))
end

Events.OnFillWorldObjectContextMenu.Add(linuxMenu_AddContext)
