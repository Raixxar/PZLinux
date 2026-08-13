-- Regression test for the "PZLinux Admin - Player Balances" tool: after
-- fixing several real money bugs (Hacking, Poker) this session, an admin
-- had no way to inspect or correct an affected player's account -- only
-- "add funds to my own balance" existed. Scoped to currently connected
-- players only (see the comment above PZLinuxAdminFindOnlinePlayerByUsername
-- in ISPZLinuxVariablesTables.lua for why offline players are out of scope).

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_admin_balance.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- ---------------------------------------------------------------------
-- Functional tests: extract the real functions (including the local
-- username-resolution helper they share) and exercise them directly.
-- ---------------------------------------------------------------------

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local adminBlock = variablesSource:match(
    "local function PZLinuxAdminFindOnlinePlayerByUsername.-\nend\n\n"
    .. "function PZLinuxAdminSetPlayerBalance.-\nend"
)
PZLinuxTestAssert(adminBlock, "the admin balance functions must exist as one contiguous block")

PZLinuxGetPlayer = function(player) return player end
-- Stubbed here instead of extracted, so admin-vs-non-admin can be toggled
-- freely; PZLinuxContractsHasAdminAccess's own logic isn't what's being
-- tested by this file.
local adminAccess = true
PZLinuxContractsHasAdminAccess = function() return adminAccess end

local balances = {}
PZLinuxLoadBankBalance = function(player) return balances[player] or 0 end
PZLinuxSetBankBalance = function(player, amount)
    balances[player] = math.max(0, math.floor(tonumber(amount) or 0))
    return balances[player]
end

local function fakePlayer(username, balance)
    local player = { username = username }
    function player:getUsername() return self.username end
    balances[player] = balance
    return player
end

local onlinePlayers = {}
getOnlinePlayers = function()
    local list = { values = onlinePlayers }
    function list:size() return #self.values end
    function list:get(index) return self.values[index + 1] end
    return list
end

assert(loadstring((adminBlock:gsub("^local function", "function", 1))))()

local alice = fakePlayer("Alice", 5000)
local bob = fakePlayer("Bob", 12000)
onlinePlayers = { alice, bob }

-- 1. List online players.
local listResult = PZLinuxAdminListOnlinePlayers({}, "list-1")
PZLinuxTestAssert(listResult.ok, "listing online players must succeed for an admin")
PZLinuxTestAssert(#listResult.players == 2, "both connected players must be listed")
local byName = {}
for _, entry in ipairs(listResult.players) do byName[entry.username] = entry.balance end
PZLinuxTestAssert(byName.Alice == 5000 and byName.Bob == 12000,
    "each listed player's balance must be their real, current balance")

-- 2. Get a specific player's balance.
local getResult = PZLinuxAdminGetPlayerBalance({}, "bob", "get-1")
PZLinuxTestAssert(getResult.ok and getResult.balance == 12000,
    "username lookup must be case-insensitive and return the real balance")

local getMissing = PZLinuxAdminGetPlayerBalance({}, "nobody", "get-2")
PZLinuxTestAssert(not getMissing.ok and getMissing.error == "player_not_found",
    "looking up a username that isn't currently connected must fail clearly")

-- 3. Set a player's balance.
local setResult = PZLinuxAdminSetPlayerBalance({}, "Alice", 999, "set-1")
PZLinuxTestAssert(setResult.ok and setResult.previousBalance == 5000 and setResult.balance == 999,
    "setting a balance must report both the old and new value")
PZLinuxTestAssert(balances[alice] == 999, "the target player's real balance must actually change")
PZLinuxTestAssert(balances[bob] == 12000, "a different, untargeted player's balance must be untouched")

local setMissing = PZLinuxAdminSetPlayerBalance({}, "nobody", 1, "set-2")
PZLinuxTestAssert(not setMissing.ok and setMissing.error == "player_not_found",
    "setting a balance for a disconnected/unknown username must fail clearly, not silently no-op")

-- 4. Every one of the three must be refused for a non-admin caller, and
-- must not have touched anything.
adminAccess = false
local deniedList = PZLinuxAdminListOnlinePlayers({}, "deny-1")
local deniedGet = PZLinuxAdminGetPlayerBalance({}, "Alice", "deny-2")
local deniedSet = PZLinuxAdminSetPlayerBalance({}, "Alice", 1, "deny-3")
PZLinuxTestAssert(not deniedList.ok and deniedList.error == "admin_required", "listing must require admin access")
PZLinuxTestAssert(not deniedGet.ok and deniedGet.error == "admin_required", "getting a balance must require admin access")
PZLinuxTestAssert(not deniedSet.ok and deniedSet.error == "admin_required", "setting a balance must require admin access")
PZLinuxTestAssert(balances[alice] == 999, "a denied set-balance attempt must not change anything")

print("PZLinux admin balance functional tests OK")

-- ---------------------------------------------------------------------
-- Source-level checks: server command registration, client wrappers, the
-- client result-dispatcher (including the pre-existing gap this also
-- fixed), and the admin menu wiring.
-- ---------------------------------------------------------------------

local serverCommandsSource = readFile(luaRoot .. "/server/PZLinuxServerCommands.lua")
for _, entry in ipairs({
    "PZLinuxAdminListOnlinePlayers = PZLinuxServerAdminListOnlinePlayers",
    "PZLinuxAdminGetPlayerBalance = PZLinuxServerAdminGetPlayerBalance",
    "PZLinuxAdminSetPlayerBalance = PZLinuxServerAdminSetPlayerBalance",
}) do
    PZLinuxTestAssert(serverCommandsSource:find(entry, 1, true),
        "the server command dispatch table must register: " .. entry)
end

for _, fn in ipairs({
    "PZLinuxRequestAdminListOnlinePlayers",
    "PZLinuxRequestAdminGetPlayerBalance",
    "PZLinuxRequestAdminSetPlayerBalance",
}) do
    PZLinuxTestAssert(variablesSource:find("function " .. fn, 1, true),
        "the client-facing wrapper must exist: " .. fn)
end

-- The client-side Events.OnServerCommand dispatcher must recognize all
-- three new result commands, plus PZLinuxContractAdminForceMailResult --
-- found missing entirely while adding these (real MP, not solo, would
-- silently never deliver that one's response to its callback).
for _, resultCommand in ipairs({
    "PZLinuxContractAdminForceMailResult",
    "PZLinuxAdminListOnlinePlayersResult",
    "PZLinuxAdminGetPlayerBalanceResult",
    "PZLinuxAdminSetPlayerBalanceResult",
}) do
    PZLinuxTestAssert(variablesSource:find('command == "' .. resultCommand .. '"', 1, true),
        "the client's Events.OnServerCommand dispatcher must recognize: " .. resultCommand)
end

local debugMenuSource = readFile(luaRoot .. "/client/Context/World/ISContextDebug.lua")
PZLinuxTestAssert(debugMenuSource:find("PZLinuxAdminBalanceMenu_ShowUI", 1, true),
    "the admin debug menu must offer a way to open the player-balances panel")

local adminBalanceUiSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxAdminBalance.lua")
PZLinuxTestAssert(adminBalanceUiSource:find("function PZLinuxAdminBalanceMenu_ShowUI", 1, true),
    "PZLinuxAdminBalanceMenu_ShowUI must actually be defined")
PZLinuxTestAssert(adminBalanceUiSource:find("PZLinuxRequestAdminListOnlinePlayers(self.player,", 1, true),
    "the panel must actually request the online player list")
PZLinuxTestAssert(adminBalanceUiSource:find("PZLinuxRequestAdminSetPlayerBalance(self.player,", 1, true),
    "the panel must actually request the balance change")

-- The target player must only ever be settable by clicking a real row in
-- the online-players list, never free-typed -- since this tool is scoped
-- to online players only, every valid target is already a row in that
-- list, so a separate editable username field would only add a typo risk
-- (mistarget real money) for no actual capability gained.
PZLinuxTestAssert(not adminBalanceUiSource:find("ISTextEntryBox:new(\"Username\"", 1, true),
    "the target player must not be a free-typed field")
PZLinuxTestAssert(adminBalanceUiSource:find("self.selectedUsername = tostring(entry.username)", 1, true),
    "the target player must only be settable by clicking a row in the online-players list")
PZLinuxTestAssert(adminBalanceUiSource:find("local username = self.selectedUsername", 1, true),
    "setting a balance must use the click-selected username, not a typed one")

print("PZLinux admin balance source-level tests OK")
