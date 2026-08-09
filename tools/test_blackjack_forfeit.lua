-- Regression test for a real gameplay bug: closing/minimizing the betting
-- panel mid-hand of Blackjack silently abandoned the hand. Race and Poker
-- are both settled before the panel actually closes (settleRaceBeforeClose,
-- cashOutPokerBeforeClose), but Blackjack had no equivalent -- the bet
-- already taken at Deal time was never credited back, and the orphaned
-- server-side session just got silently overwritten the next time the
-- player dealt a new hand, with no trace of where that money went.
--
-- Also guards the debounce added against a click firing the Deal/Hit/Stand
-- handler twice almost simultaneously (mechanical mouse double-click
-- defects, a real double-click, or a click racing the button's own
-- :setEnable(false) before it takes effect).

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_blackjack_forfeit.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

local forfeitBlock = variablesSource:match("function PZLinuxBlackjackForfeit.-\nend")
assert(forfeitBlock, "PZLinuxBlackjackForfeit must exist")
assert(forfeitBlock:find('PZLinuxBlackjackFinish(player, session, "push")', 1, true),
    "forfeiting an in-progress hand must settle it as a push (the bet is returned, not lost) " ..
    "since walking away isn't a loss the player actually played out")
assert(forfeitBlock:find("if not session or session.finished then", 1, true),
    "forfeiting must be a safe no-op when there's no in-progress hand to abandon, " ..
    "since the panel calls this on every close regardless of blackjack state")

local requestForfeitBlock = variablesSource:match("function PZLinuxRequestBlackjackForfeit.-\nend")
assert(requestForfeitBlock, "PZLinuxRequestBlackjackForfeit (the client-facing wrapper) must exist")
assert(requestForfeitBlock:find('PZLinuxSendClientCommand("PZLinuxBlackjackForfeit"', 1, true),
    "the forfeit request must go through the same client/server command dispatch as Start/Hit/Stand")

local serverCommandsSource = readFile(luaRoot .. "/server/PZLinuxServerCommands.lua")
assert(serverCommandsSource:find("PZLinuxBlackjackForfeit = PZLinuxServerBlackjackForfeit", 1, true),
    "the forfeit command must be registered in the server's command dispatch table, " ..
    "or the client request has nothing to reach")

local bettingSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxBetting.lua")
local settleGamesBlock = bettingSource:match("function PZLinuxBettingUI:settleGamesBeforeClose.-\nend")
assert(settleGamesBlock, "PZLinuxBettingUI:settleGamesBeforeClose must exist")
assert(settleGamesBlock:find("forfeitBlackjackBeforeClose", 1, true),
    "closing/minimizing the betting panel must also settle an in-progress Blackjack hand, " ..
    "the same way it already settles Race and Poker -- otherwise a hand's bet is silently orphaned")

local forfeitBeforeCloseBlock = bettingSource:match("function PZLinuxBettingUI:forfeitBlackjackBeforeClose.-\nend")
assert(forfeitBeforeCloseBlock, "PZLinuxBettingUI:forfeitBlackjackBeforeClose must exist")
assert(forfeitBeforeCloseBlock:find("PZLinuxRequestBlackjackForfeit", 1, true),
    "forfeitBlackjackBeforeClose must actually request the server-side forfeit")

-- Debounce: every Blackjack action handler must check it before doing
-- anything else, or a double-fired click can still slip through.
for _, handlerName in ipairs({ "onBlackjackDeal", "onBlackjackHit", "onBlackjackStand" }) do
    local handlerBlock = bettingSource:match("function PZLinuxBettingUI:" .. handlerName .. ".-\nend")
    assert(handlerBlock, "PZLinuxBettingUI:" .. handlerName .. " must exist")
    assert(handlerBlock:find("PZLinuxBlackjackDebounced(self)", 1, true),
        handlerName .. " must check the debounce guard before acting on the click")
end

print("PZLinux blackjack forfeit/debounce tests OK")
