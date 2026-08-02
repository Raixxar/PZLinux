-- Request UI - by Raixxar
-- Updated : 25/02/25

requestUI = ISPanel:derive("requestUI")

local PZLinuxOnItemRequestName = ""
local PZLinuxRequestPriceDelta = 1
local PZLinuxOnItemRequest = {}
local PZLinuxOnItemRequestCount = 0

local PZLinuxRequestCatalog = {}
for contractId, definition in ipairs(PZLinuxRequestDefinitions or {}) do
    local textKey = PZLinuxRequestCategoryTextKeys and PZLinuxRequestCategoryTextKeys[contractId]
    local translatedName = textKey and PZLinuxGetText(textKey) or definition.baseName
    PZLinuxRequestCatalog[contractId] = { id = contractId, name = translatedName }
end

local function PZLinuxCalculateRequestUnitPrice(playerObj, contractData)
    if not contractData then return 0 end
    local definition = PZLinuxRequestsGetDefinition(contractData.id)
    return PZLinuxRequestsCalculateUnitPrice(playerObj, definition or contractData)
end

local function PZLinuxRequestText(key)
    return PZLinuxGetText(key)
end

local function PZLinuxRequestFormatText(key, ...)
    local template = PZLinuxRequestText(key)
    local ok, result = pcall(string.format, template, ...)
    return ok and result or template
end

local function PZLinuxRequestSetConversation(ui, message)
    local panel = ui and ui.loadingMessage
    if not panel then return end

    panel.text = "<RGB:0,1,0>" .. tostring(message or "")
    panel:paginate()

    local maxYScroll = math.max(0, panel:getScrollHeight() - panel:getHeight())
    if panel.vscroll then panel.vscroll:setVisible(maxYScroll > 0) end
    panel:setYScroll(-maxYScroll)
end

-- CONSTRUCTOR
function requestUI:new(x, y, width, height, player)
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
function requestUI:initialise()
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

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, PZLinuxRequestFormatText("IGUI_PZLinux_Request_Balance", tostring(loadAtmBalance())), 0, 1, 0, 1, UIFont.Small, true)
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

    self:refreshContracts()
end

function requestUI:refreshContracts()
    if self.prevButton then self.prevButton:setVisible(false) end
    if self.nextButton then self.nextButton:setVisible(false) end
    for _, contractButton in ipairs(self.contractButtons or {}) do
        contractButton:setVisible(false)
    end
    self.contractButtons = {}

    local y = 0.20
    local itemsPerPage = 8
    local currentPage = self.currentPage or 1
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #PZLinuxRequestCatalog)

    for i = startIndex, endIndex do
        local contract = PZLinuxRequestCatalog[i]
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

    self.prevButton = ISButton:new(self.width * 0.454, self.height * 0.68, self.width * 0.030, self.height * 0.025, "<", self, function()
        if currentPage == 1 then currentPage = 2 end
        self.currentPage = currentPage - 1
        self:refreshContracts()
    end)
    self.prevButton:initialise()
    self.topBar:addChild(self.prevButton)

    if endIndex < #PZLinuxRequestCatalog then
        self.nextButton = ISButton:new(self.width * 0.484, self.height * 0.68, self.width * 0.030, self.height * 0.025, ">", self, function()
            self.currentPage = currentPage + 1
            self:refreshContracts()
        end)
        self.nextButton:initialise()
        self.topBar:addChild(self.nextButton)
    end
end

function requestUI:onSelectContract(button)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)
    self.prevButton:setVisible(false)
    self.nextButton:setVisible(false)
    for _, contractButton in ipairs(self.contractButtons) do
        contractButton:setVisible(false)
    end
    self:onContractId(button.contractId)
end

function requestUI:onContractId(contract)
    local globalVolume = getCore():getOptionSoundVolume() / 50
    local player = PZLinuxGetPlayer(self.player)

    if not self.typingMessage then
        self.typingMessage = ISLabel:new(self.width * 0.20, self.height * 0.65, self.height * 0.025, "", 0, 1, 0, 1, UIFont.Small, true)
        self.typingMessage:initialise()
        self.topBar:addChild(self.typingMessage)
    end

    if not self.loadingMessage then
        self.loadingMessage = ISRichTextPanel:new(self.width * 0.20, self.height * 0.22, self.width * 0.57, self.height * 0.36)
        self.loadingMessage.backgroundColor = {r=0, g=0, b=0, a=0}
        self.loadingMessage.borderColor = {r=0, g=0, b=0, a=0}
        self.loadingMessage.autosetheight = false
        self.loadingMessage:setVisible(true)
        self.loadingMessage:initialise()
        self.loadingMessage:instantiate()
        self.topBar:addChild(self.loadingMessage)
    end

    local function typeText(label, text, callback)
        if PZLinux.Typing.typeLabel(self, label, text, player, { volume = globalVolume }) and callback then
            callback()
        end
    end

    self.terminalCoroutine = coroutine.create(function()
        local message = PZLinuxRequestText("IGUI_PZLinux_Request_WaitParticipants")

        PZLinuxRequestSetConversation(self, message)
        if not PZLinux.Typing.waitProfile(self, "message") then return end
        if self.isClosing then return end

        local waitUser = ZombRand(1, 4)
        if waitUser == 1 then
            message = PZLinuxRequestText("IGUI_PZLinux_Request_NobodyJoined")
            PZLinuxRequestSetConversation(self, message)
            return
        end

        getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        local sellerName = generateUsername()
        local playerName = PZLinuxFormatIRCName(generatePseudo(string.lower(PZLinuxGetPlayer(self.player):getUsername())))

        message = PZLinuxRequestFormatText("IGUI_PZLinux_Request_UserJoined", sellerName)
        PZLinuxRequestSetConversation(self, message)
        sellerName = PZLinuxFormatIRCName(sellerName)

        if not PZLinux.Typing.waitProfile(self, "message") then return end


        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = sellerName .. PZLinuxRequestFormatText("IGUI_PZLinux_Request_LookingFor", PZLinuxRequestCatalog[contract].name)
        PZLinuxRequestSetConversation(self, message)

        if not PZLinux.Typing.waitProfile(self, "message") then return end

        if self.isClosing then return end

        local interestedText = PZLinuxRequestText("IGUI_PZLinux_Request_PlayerInterested")
        typeText(self.typingMessage, interestedText, function()
            message = message .. "\n" .. playerName .. interestedText
            PZLinuxRequestSetConversation(self, message)
            self.typingMessage:setName("")
        end)

        if not PZLinux.Typing.waitProfile(self, "message") then return end

        if self.isClosing then return end

        local quests = PZLinuxRequestsGetOfferPool(contract)
        local locations = {}
        if contract == 9 then  -- Car
            locations = PZLinuxGetMissionLocationPool and PZLinuxGetMissionLocationPool("vehicles") or {}
        end

        local locationName = ""
        local weightPackage = 0
        local maxItems = ZombRand(4,7)
        local itemCount = 0
        local batch = { items = {} }
        local selectedVehicleOffer = nil
        PZLinuxRequestPriceDelta = 1

        while weightPackage <= 9.5 and itemCount < maxItems do
            local itemIdRand = ZombRand(1, #quests + 1)
            local offer = quests[itemIdRand]
            if offer then
                table.insert(batch.items, { name = offer.baseName })
                weightPackage = weightPackage + offer.weight
                itemCount = itemCount + 1
                if contract == 9 then selectedVehicleOffer = offer end
            end
        end

        PZLinuxOnItemRequest = {}
        PZLinuxOnItemRequestCount = itemCount
        table.insert(PZLinuxOnItemRequest, batch)

        if contract == 9 and #locations > 0 then
            local randomLocation = ZombRand(1, #locations + 1)
            local location = locations[randomLocation]
            if selectedVehicleOffer and location then
                PZLinuxRequestPriceDelta = selectedVehicleOffer.delta
                self.pendingRequestLocationX = location.x
                self.pendingRequestLocationY = location.y
                self.pendingRequestLocationZ = location.z
                self.pendingRequestLocationName = PZLinuxGetMissionLocationDescription(location)
                locationName = self.pendingRequestLocationName
            end
        end

        local produceName = ""
        local lastBatch = PZLinuxOnItemRequest[#PZLinuxOnItemRequest]
        for _, entry in ipairs(lastBatch.items) do
            local itemBaseName = entry.name
            local checkProduceName = getScriptManager():FindItem(itemBaseName)
            local produceNameValide = checkProduceName and checkProduceName:getDisplayName() and checkProduceName:getDisplayName():match("%S")
            if produceNameValide then
                produceName = produceName .. "\n" .. sellerName .. checkProduceName:getDisplayName()
            else
                produceName = produceName .. "\n" .. sellerName .. PZLinuxRequestCatalog[contract].name
            end

            if contract == 9 then
                PZLinuxOnItemRequestName = entry.name
                local vehicle = getScriptManager():getVehicle(entry.name)
                if vehicle then
                    produceName = getText("IGUI_VehicleName" .. vehicle:getName())
                else
                    produceName = entry.name
                end
            end
        end

        if contract == 9 then
            table.remove(PZLinuxOnItemRequest, #PZLinuxOnItemRequest)
            getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. PZLinuxRequestFormatText("IGUI_PZLinux_Request_SellerVehicleOffer", PZLinuxOnItemRequestCount, produceName)
            PZLinuxRequestSetConversation(self, message)
        else
            getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. PZLinuxRequestFormatText("IGUI_PZLinux_Request_SellerItemOffer", PZLinuxOnItemRequestCount)
            PZLinuxRequestSetConversation(self, message)
        end

        if not PZLinux.Typing.waitProfile(self, "message") then return end

        if contract == 9 then
            if self.isClosing then return end
            getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
            message = message .. "\n" .. sellerName .. PZLinuxRequestFormatText("IGUI_PZLinux_Request_VehicleLocation", locationName)
            PZLinuxRequestSetConversation(self, message)

            if not PZLinux.Typing.waitProfile(self, "message") then return end
        end

        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, PZLinuxGetPlayer(self.player):getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. PZLinuxRequestText("IGUI_PZLinux_Request_Deal")
        PZLinuxRequestSetConversation(self, message)

        local requestPrice = PZLinuxCalculateRequestUnitPrice(PZLinuxGetPlayer(self.player), PZLinuxRequestCatalog[contract])

        local totalRequestPrice = PZLinuxOnItemRequestCount * requestPrice * PZLinuxRequestPriceDelta
        self.pendingRequestTotal = totalRequestPrice
        message = message .. "\n\n" .. PZLinuxRequestFormatText("IGUI_PZLinux_Request_Total", totalRequestPrice)
        PZLinuxRequestSetConversation(self, message)

        local playerBalance = loadAtmBalance(self.player)
        local noButton = PZLinuxRequestText("IGUI_PZLinux_Request_No")
        local actionButtonWidth = self.width * 0.20
        if playerBalance < totalRequestPrice then
            noButton = PZLinuxRequestText("IGUI_PZLinux_Request_NotEnoughMoney")
        else
            self.yesButton = ISButton:new(self.width * 0.28, self.height * 0.65, actionButtonWidth, 25, PZLinuxRequestText("IGUI_PZLinux_Request_Yes"), self, self.onYesButton)
            self.yesButton.id = contract
            self.yesButton.totalPrice = totalRequestPrice
            self.yesButton:initialise()
            self.yesButton:instantiate()
            self.topBar:addChild(self.yesButton)
        end
        self.noButton = ISButton:new(self.width * 0.52, self.height * 0.65, actionButtonWidth, 25, noButton, self, self.onMinimizeBack)
        self.noButton:initialise()
        self.noButton:instantiate()
        self.topBar:addChild(self.noButton)
    end)

    self.updateCoroutineFunc = function()
        if self.terminalCoroutine and coroutine.status(self.terminalCoroutine) ~= "dead" then
            local ok, err = coroutine.resume(self.terminalCoroutine)
            if not ok then
                print("PZLinux coroutine error:", tostring(err))
                Events.OnTick.Remove(self.updateCoroutineFunc)
                self.updateCoroutineFunc = nil
                self.terminalCoroutine = nil
            end
        else
            Events.OnTick.Remove(self.updateCoroutineFunc)
            self.updateCoroutineFunc = nil
            self.terminalCoroutine = nil
        end
    end
    Events.OnTick.Add(self.updateCoroutineFunc)
end

function requestUI:onYesButton(button)
    local playerObj = PZLinuxGetPlayer(self.player)
    if not playerObj then return end

    local modData = PZLinuxGetModData(playerObj)
    if not modData then return end
    local totalPrice = button.totalPrice or self.pendingRequestTotal
    if not totalPrice then
        local requestPrice = PZLinuxCalculateRequestUnitPrice(playerObj, PZLinuxRequestCatalog[button.id])
        totalPrice = PZLinuxOnItemRequestCount * requestPrice * PZLinuxRequestPriceDelta
    end

    local playerBalance = loadAtmBalance(playerObj)
    if playerBalance < totalPrice then
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(getCore():getOptionSoundVolume() / 50)
        HaloTextHelper.addBadText(playerObj, PZLinuxRequestText("IGUI_PZLinux_Request_NotEnoughMoney"))
        return
    end

    local items = {}
    local lastBatch = PZLinuxOnItemRequest[1]
    if lastBatch and type(lastBatch.items) == "table" then
        for _, item in ipairs(lastBatch.items) do
            table.insert(items, { name = item.name })
        end
    end

    local requestState = {
        contractId = button.id,
        items = items,
        vehicleName = PZLinuxOnItemRequestName,
        locationX = self.pendingRequestLocationX,
        locationY = self.pendingRequestLocationY,
        locationZ = self.pendingRequestLocationZ,
        locationName = self.pendingRequestLocationName,
    }

    PZLinuxRequestOrder(playerObj, requestState, function(result)
        if not result or not result.ok then
            getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 20, 1, true):setVolume(getCore():getOptionSoundVolume() / 50)
            HaloTextHelper.addBadText(playerObj, PZLinuxRequestText("IGUI_PZLinux_Request_Rejected"))
            return
        end

        if result.balance then
            saveAtmBalance(result.balance, playerObj)
            self.titleLabel:setName(PZLinuxRequestFormatText("IGUI_PZLinux_Request_Balance", tostring(result.balance)))
        end

        self.isClosing = true
        self:removeFromUIManager()

        if result.contractId == 9 then
            contractsDrawOnMap(result.locationX, result.locationY, PZLinuxRequestText("IGUI_PZLinux_Request_CarRequested"))
            requestMenu_ShowUI(playerObj)
            return
        end

        modData.PZLinuxUIOpenMenu = 8
        HaloTextHelper.addGoodText(playerObj, PZLinuxRequestText("IGUI_PZLinux_Request_MailboxAvailable"))
    end)
end

-- LOGOUT
function requestUI:onMinimize(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function requestUI:onMinimizeBack(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 8
end

-- CLOSE
function requestUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = PZLinuxGetPlayer(self.player):getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function requestUI:onCloseX(_button)
    self.isClosing = true
    PZLinuxGetPlayer(self.player):StopAllActionQueue()

end


function requestMenu_ShowUI(player)
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

    local ui = requestUI:new(uiX, uiY, finalW, finalH, player)
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
