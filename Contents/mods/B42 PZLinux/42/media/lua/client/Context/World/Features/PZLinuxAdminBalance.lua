-- PZLinux Admin - Player Balances. A plain debug/admin utility panel (not
-- styled as an in-world computer screen, unlike every player-facing panel
-- in this mod) that lists currently connected players with their bank
-- balance and lets an admin correct one -- built after several real money
-- bugs (Hacking, Poker) needed a way to fix an affected player's account
-- directly instead of only preventing the bug going forward. Deliberately
-- scoped to online players only: reaching an offline player's saved data
-- would mean reading their save file directly, out of scope here. Every
-- server-side function this calls (PZLinuxAdmin*) independently re-checks
-- admin access itself -- this menu being admin-only is a convenience, not
-- the actual security boundary.

adminBalanceUI = ISPanel:derive("adminBalanceUI")

-- CONSTRUCTOR
function adminBalanceUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.95}
    o.borderColor = {r=0.5, g=0, b=0, a=1}
    o.width = width
    o.height = height
    o.player = player
    o.isClosing = false
    return o
end

-- INIT
function adminBalanceUI:initialise()
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

    self.titleLabel = ISLabel:new(self.width * 0.05, self.height * 0.04, self.height * 0.03, "PZLinux Admin - Player Balances", 1, 0.3, 0.3, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    self.closeButton = ISButton:new(self.width * 0.90, self.height * 0.03, self.width * 0.06, self.height * 0.04, "X", self, self.onClose)
    self.closeButton.backgroundColor = {r=0.4, g=0, b=0, a=1}
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    -- Online players list: username + current balance, click a row to load
    -- it into the fields below.
    self.playerList = ISScrollingListBox:new(self.width * 0.05, self.height * 0.12, self.width * 0.90, self.height * 0.55)
    self.playerList:initialise()
    self.playerList:instantiate()
    self.playerList.itemheight = self.height * 0.045
    self.playerList.font = UIFont.Small
    self.playerList.drawBorder = true
    self.playerList.doDrawItem = adminBalanceUI.drawPlayerItem
    self.playerList.onMouseDown = function(_, x, y)
        ISScrollingListBox.onMouseDown(self.playerList, x, y)
        self:onPlayerClicked()
    end
    self.topBar:addChild(self.playerList)

    self.refreshButton = ISButton:new(self.width * 0.05, self.height * 0.69, self.width * 0.20, self.height * 0.04, "Refresh", self, self.onRefresh)
    self.refreshButton:initialise()
    self.topBar:addChild(self.refreshButton)

    -- Deliberately a read-only label, not a text entry: this tool only
    -- ever reaches currently connected players, so every valid target is
    -- already a row in the list above. Letting the target be free-typed
    -- instead of only ever set by clicking a real row would just add a
    -- typo risk (a mistyped name either fails harmlessly or, worse, is
    -- easy to misread as "the right player" right before setting real
    -- money) for zero actual capability gained.
    self.selectedUsername = nil
    self.targetLabel = ISLabel:new(self.width * 0.05, self.height * 0.76, self.height * 0.03, "Target: none selected (click a player above)", 1, 1, 1, 1, UIFont.Small, true)
    self.targetLabel:initialise()
    self.topBar:addChild(self.targetLabel)

    self.newBalanceEntry = ISTextEntryBox:new("New Balance", self.width * 0.50, self.height * 0.76, self.width * 0.30, self.height * 0.05)
    self.newBalanceEntry:initialise()
    self.newBalanceEntry:instantiate()
    self.newBalanceEntry:setOnlyNumbers(true)
    self.topBar:addChild(self.newBalanceEntry)

    self.setBalanceButton = ISButton:new(self.width * 0.05, self.height * 0.85, self.width * 0.40, self.height * 0.05, "Set Balance", self, self.onSetBalance)
    self.setBalanceButton.backgroundColor = {r=0.3, g=0, b=0, a=1}
    self.setBalanceButton:initialise()
    self.topBar:addChild(self.setBalanceButton)

    self.statusLabel = ISLabel:new(self.width * 0.05, self.height * 0.93, self.height * 0.03, "", 1, 1, 0, 1, UIFont.Small, true)
    self.statusLabel:initialise()
    self.topBar:addChild(self.statusLabel)

    self:refreshPlayerList()
end

function adminBalanceUI:drawPlayerItem(y, item, alt)
    local entry = item.item
    if self.selected == item.index then
        self:drawRect(0, y, self.width, self.itemheight, 0.3, 0.5, 0, 0)
    elseif alt then
        self:drawRect(0, y, self.width, self.itemheight, 0.1, 0, 0, 0)
    end
    self:drawText(tostring(entry.username), 10, y + 6, 0, 1, 0, 1)
    self:drawText("$" .. tostring(entry.balance), self.width * 0.65, y + 6, 1, 1, 0, 1)
    return y + self.itemheight
end

function adminBalanceUI:onPlayerClicked()
    local item = self.playerList.items[self.playerList.selected]
    if not item then return end
    local entry = item.item
    self.selectedUsername = tostring(entry.username)
    self.targetLabel:setName("Target: " .. self.selectedUsername .. " (current: $" .. tostring(entry.balance) .. ")")
    self.newBalanceEntry:setText(tostring(entry.balance))
    self.statusLabel:setName("")
end

function adminBalanceUI:refreshPlayerList()
    if not self.playerList then return end
    PZLinuxRequestAdminListOnlinePlayers(self.player, function(result)
        if self.isClosing then return end
        if not result or not result.ok then
            self.statusLabel:setName("Failed to load player list: " .. tostring(result and result.error or "no response"))
            return
        end
        if self.playerList.clear then
            self.playerList:clear()
        else
            self.playerList.items = {}
            self.playerList.selected = 0
        end
        for _, entry in ipairs(result.players or {}) do
            self.playerList:addItem(entry.username, entry)
        end
    end)
end

function adminBalanceUI:onRefresh()
    self.statusLabel:setName("Refreshing...")
    self:refreshPlayerList()
end

function adminBalanceUI:onSetBalance()
    if self.setBalanceInProgress then return end
    local username = self.selectedUsername
    if not username or username == "" then
        self.statusLabel:setName("Click a player in the list first")
        return
    end
    local amount = tonumber(self.newBalanceEntry:getText())
    if not amount or amount < 0 then
        self.statusLabel:setName("Enter a valid balance (0 or more)")
        return
    end

    self.setBalanceInProgress = true
    self.setBalanceButton:setEnable(false)
    self.statusLabel:setName("Applying...")
    PZLinuxRequestAdminSetPlayerBalance(self.player, username, amount, function(result)
        self.setBalanceInProgress = false
        if self.isClosing then return end
        self.setBalanceButton:setEnable(true)
        if not result or not result.ok then
            self.statusLabel:setName("Failed: " .. tostring(result and result.error or "no response"))
            return
        end
        self.statusLabel:setName(string.format(
            "%s: $%d -> $%d",
            tostring(result.username), tonumber(result.previousBalance) or 0, tonumber(result.balance) or 0))
        self.targetLabel:setName("Target: " .. tostring(result.username) .. " (current: $" .. tostring(result.balance) .. ")")
        self:refreshPlayerList()
    end)
end

function adminBalanceUI:onClose(_button)
    self.isClosing = true
    self:removeFromUIManager()
end

function PZLinuxAdminBalanceMenu_ShowUI(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()
    local width = math.min(600, realScreenW * 0.45)
    local height = math.min(520, realScreenH * 0.65)
    local x = (realScreenW - width) / 2
    local y = (realScreenH - height) / 2

    local ui = adminBalanceUI:new(x, y, width, height, playerObj)
    ui:initialise()
    ui:addToUIManager()
    return ui
end
