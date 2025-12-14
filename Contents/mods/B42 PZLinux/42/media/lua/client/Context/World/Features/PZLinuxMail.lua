-- Mails UI - by Raixxar 
-- Updated : 13/12/25

mailUI = ISPanel:derive("mailUI")

local LAST_CONNECTION_TIME = 0
local STAY_CONNECTED_TIME = 0
local PZLinuxOnItemMailName = ""
local ZLinuxOnItemMailPriceDelta = 1
local PZLinuxOnItemMail = {}
local PZLinuxOnItemMailCount = 0
local MONTH_HOURS = 30 * 24

-- CONSTRUCTOR
function mailUI:new(x, y, width, height, player)
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
function mailUI:initialise()
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

    local player = getPlayer()
    if player then
        playerUsername = string.lower(player:getUsername()) .. "@aol.com"
    end

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, "AOL | America Online - " .. tostring(playerUsername), 0, 1, 0, 1, UIFont.Small, true)
    self.titleLabel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabel:setVisible(true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

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
   
    local startX   = self.width * 0.20
    local y        = 0.20
    local rowH     = self.height * 0.03
    local colDateW = self.width * 0.19
    local colFromW = self.width * 0.20
    local colObjW  = self.width * 0.21

    local headerX = self.width * 0.20
    local headerY = self.height * (y + 0.010)

    local headerDate = ISLabel:new(headerX, headerY, rowH, "Date", 0, 1, 0, 1, UIFont.Small, true)
    headerDate:initialise()
    self.topBar:addChild(headerDate)

    local headerFrom = ISLabel:new(headerX + colDateW, headerY, rowH, "From", 0, 1, 0, 1, UIFont.Small, true)
    headerFrom:initialise()
    self.topBar:addChild(headerFrom)

    local headerObj = ISLabel:new(headerX + colDateW + colFromW, headerY, rowH, "Object", 0, 1, 0, 1, UIFont.Small, true)
    headerObj:initialise()
    self.topBar:addChild(headerObj)

    local sepY = headerY + rowH * 0.9
    local sep = ISPanel:new(startX, sepY, self.width * 0.57, 1)
    sep.backgroundColor = { r=0, g=1, b=0, a=0.35 }
    sep.borderColor     = { r=0, g=0, b=0, a=0 }
    sep:initialise()
    self.topBar:addChild(sep)
    y = y + 0.02

    local listX = self.width * 0.20
    local listY = self.height * 0.24
    local listW = self.width * 0.57
    local listH = self.height * 0.47

    self.mailList = ISScrollingListBox:new(listX, listY, listW, listH)
    self.mailList:initialise()
    self.mailList:instantiate()
    self.mailList.itemheight = self.height * 0.04
    self.mailList.font = UIFont.Small
    self.mailList.doDrawItem = self.drawMailItem
    self.mailList.onMouseDown = function(_, x, y)
        ISScrollingListBox.onMouseDown(self.mailList, x, y)
        self:onMailClicked()
    end

    self.topBar:addChild(self.mailList)
    local md = getPlayer():getModData()
    md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}

    self.readWidgets = {}
    local function addRead(w)
        table.insert(self.readWidgets, w)
        w:setVisible(false)
    end

    self.inboxWidgets = { headerDate, headerFrom, headerObj, sep, self.mailList }

    local rx = self.width * 0.20
    local ry = self.height * 0.23
    local rw = self.width * 0.57
    local rh = self.height * 0.53

    self.readTitle = ISLabel:new(rx, ry, 20, "", 0,1,0,1, UIFont.Medium, true)
    self.readTitle:initialise()
    self.topBar:addChild(self.readTitle)
    addRead(self.readTitle)

    self.readMeta = ISLabel:new(rx, ry + 22, 20, "", 0,1,0,1, UIFont.Small, true)
    self.readMeta:initialise()
    self.topBar:addChild(self.readMeta)
    addRead(self.readMeta)

    self.readBody = ISRichTextPanel:new(rx, ry + 45, rw, rh)
    self.readBody:initialise()
    self.readBody:instantiate()
    self.readBody.background = false
    self.topBar:addChild(self.readBody)
    addRead(self.readBody)

    -- Boutons bas
    local by = self.width * 0.70
    self.btnBack = ISButton:new(rx * 1.2, by, self.width*0.08, self.height*0.03, "< Back", self, self.onBackToInbox)
    self.btnBack:initialise(); self.topBar:addChild(self.btnBack); addRead(self.btnBack)

    self.btnAccept = ISButton:new(rx * 1.2 + self.width*0.10, by, self.width*0.14, self.height*0.03, "Accept", self, self.onAcceptMail)
    self.btnAccept:initialise(); self.topBar:addChild(self.btnAccept); addRead(self.btnAccept)

    self.btnDelete = ISButton:new(rx * 1.2 + self.width*0.26, by, self.width*0.14, self.height*0.03, "Delete", self, self.onDeleteMail)
    self.btnDelete:initialise(); self.topBar:addChild(self.btnDelete); addRead(self.btnDelete)

    self.selectedMailId = nil

    self:refreshInbox()
    self:setInboxVisible(true)
end

function mailUI:setInboxVisible(visible)
    for _,w in ipairs(self.inboxWidgets or {}) do w:setVisible(visible) end
    for _,w in ipairs(self.readWidgets  or {}) do w:setVisible(not visible) end
end

function mailUI:refreshInbox()
    if not self.mailList then return end

    if self.mailList.clear then
        self.mailList:clear()
    else
        self.mailList.items = {}
        self.mailList.selected = 0
    end

    local md = getPlayer():getModData()
    md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}

    for i = 1, #md.pzlinux.mails.inbox do
        local mail = md.pzlinux.mails.inbox[i]
        self.mailList:addItem(mail.id, mail)
    end
end

function mailUI:drawMailItem(y, item, alt)
    local mail = item.item

    if self.selected == item.index then
        self:drawRect(0, y, self.width, self.itemheight, 0.3, 0, 1, 0)
    elseif alt then
        self:drawRect(0, y, self.width, self.itemheight, 0.1, 0, 0, 0)
    end

    local r, g, b = 0, 1, 0
    if mail.read then
        r, g, b = 0.6, 0.6, 0.6
    end

    self:drawText(mail.date, 10, y + 6, r, g, b, 1)
    self:drawText(mail.from, 140, y + 6, r, g, b, 1)
    self:drawText(mail.name, 300, y + 6, r, g, b, 1)

    return y + self.itemheight
end

function mailUI:onMailClicked()
    local item = self.mailList.items[self.mailList.selected]
    if not item then return end

    local mail = item.item
    mail.read = true

    self.selectedMailId = mail.id
    if mail.type == "ads" then body = PZLinuxMailGenerateBodyADS(mail.from, mail.id)
    elseif mail.type == "ammo" then body = PZLinuxMailGenerateBodyAmmo(mail.from, mail.id)
    elseif mail.type == "medical" then body = PZLinuxMailGenerateBodyMedical(mail.from, mail.id)
    end

    self.readTitle:setName(tostring(mail.name))
    self.readMeta:setName("From: " .. tostring(mail.from) .. " | Date: " .. tostring(mail.date))

    self.readBody.text = "<GREEN>" .. tostring(body) .. "</GREEN>"
    self.readBody:paginate()

    self:setInboxVisible(false)
end

function mailUI:onBackToInbox()
    self.selectedMailId = nil
    self:setInboxVisible(true)
    self:refreshInbox()
end

function mailUI:onAcceptMail()
    local md = getPlayer():getModData()
    local id = self.selectedMailId
    local mail = md.pzlinux.mails[id] 
    if not mail or mail.status == 10 or mail.status == 2 or mail.type == "ads" then return end

    mail.status = 2
    self:onBackToInbox()
    local scriptItem = getScriptManager():FindItem(mail.object)
    local displayName = scriptItem and scriptItem:getDisplayName() or mail.object
    local mapText = mail.quantity .. "* " .. displayName
    contractsDrawOnMap(mail.x, mail.y, mapText)
end

function mailUI:onDeleteMail()
    local md = getPlayer():getModData()
    md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}

    local id = self.selectedMailId
    md.pzlinux.mails[id] = nil

    for i = #md.pzlinux.mails.inbox, 1, -1 do
        if md.pzlinux.mails.inbox[i].id == self.selectedMailId then
            table.remove(md.pzlinux.mails.inbox, i)
            break
        end
    end

    self:onBackToInbox()
end

-- LOGOUT
function mailUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function mailUI:onMinimizeBack(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 8
end

-- CLOSE
function mailUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function mailUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()

end

function mailUI:onSFXOn(button)
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

function mailUI:onSFXOff(button)
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

function mailMenu_ShowUI(player)
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

    local ui = mailUI:new(uiX, uiY, finalW, finalH, player)
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
