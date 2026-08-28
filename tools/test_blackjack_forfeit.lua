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
--
-- And guards a second, subtler real bug reported by a player: "I lose and
-- my balance doesn't go down, it's like free gambling". The Close/Minimize/
-- Leave buttons were never disabled the way Hit/Stand disable each other,
-- so clicking Stand and then immediately Leave (very natural once you see
-- you've lost) could send a Forfeit request that reaches the server before
-- -- or races -- the Stand response for the very same hand. Forfeit refunds
-- as a "push" any hand it finds still open, so it could silently cancel out
-- a real loss (or a real win) that was already in flight. The fix makes a
-- close-triggered forfeit wait for any in-flight Deal/Hit/Stand response
-- before deciding whether there's still a hand to abandon.

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
assert(forfeitBeforeCloseBlock:find("if self.blackjackActionInFlight then", 1, true),
    "forfeitBlackjackBeforeClose must defer instead of firing while a Deal/Hit/Stand request is " ..
    "still in flight, or it can race ahead of that request and refund a hand that actually resolved")
assert(forfeitBeforeCloseBlock:find("self.blackjackPendingForfeitAfterAction = afterForfeit", 1, true),
    "a deferred forfeit must remember its continuation so the panel still actually closes once " ..
    "the in-flight action lands, instead of hanging forever")

local runPendingForfeitBlock = bettingSource:match("function PZLinuxBettingUI:blackjackRunPendingForfeit.-\nend")
assert(runPendingForfeitBlock, "PZLinuxBettingUI:blackjackRunPendingForfeit must exist to resume a deferred close")

-- Every Blackjack action handler must track its own in-flight state around
-- the request/response, or the deferral above has nothing to wait on.
for _, handlerName in ipairs({ "onBlackjackDeal", "onBlackjackHit", "onBlackjackStand" }) do
    local handlerBlock = bettingSource:match("function PZLinuxBettingUI:" .. handlerName .. ".-\nend")
    assert(handlerBlock, "PZLinuxBettingUI:" .. handlerName .. " must exist")
    assert(handlerBlock:find("self.blackjackActionInFlight = true", 1, true),
        handlerName .. " must mark itself in flight before sending its request")
    assert(handlerBlock:find("self.blackjackActionInFlight = false", 1, true),
        handlerName .. " must clear the in-flight flag once its response lands")
    assert(handlerBlock:find("self:blackjackRunPendingForfeit()", 1, true),
        handlerName .. " must resume any forfeit that was deferred while it was in flight, " ..
        "or closing the panel right after this action can hang forever")
end

-- Debounce: every Blackjack action handler must check it before doing
-- anything else, or a double-fired click can still slip through.
for _, handlerName in ipairs({ "onBlackjackDeal", "onBlackjackHit", "onBlackjackStand" }) do
    local handlerBlock = bettingSource:match("function PZLinuxBettingUI:" .. handlerName .. ".-\nend")
    assert(handlerBlock, "PZLinuxBettingUI:" .. handlerName .. " must exist")
    assert(handlerBlock:find("PZLinuxBlackjackDebounced(self)", 1, true),
        handlerName .. " must check the debounce guard before acting on the click")
end

assert(variablesSource:find("local function PZLinuxBlackjackLogAction", 1, true),
    "Blackjack must keep a shared structured action logger for production troubleshooting")
assert(variablesSource:find('PZLinuxBlackjackLogAction("ACTION REJECT"', 1, true),
    "Blackjack rejected actions must be logged with their reason")

local function assertServerBlackjackLog(functionName, needle)
    local block = variablesSource:match("function " .. functionName .. ".-\nend")
    assert(block, functionName .. " must exist")
    assert(block:find(needle, 1, true),
        functionName .. " must log enough context to troubleshoot player actions")
end

assertServerBlackjackLog("PZLinuxBlackjackStart", 'PZLinuxBlackjackLogAction("START"')
assertServerBlackjackLog("PZLinuxBlackjackStart", 'PZLinuxBlackjackLogAction("START DEBIT"')
assertServerBlackjackLog("PZLinuxBlackjackStart", 'PZLinuxBlackjackLogAction("DEAL"')
assertServerBlackjackLog("PZLinuxBlackjackHit", 'PZLinuxBlackjackLogAction("HIT"')
assertServerBlackjackLog("PZLinuxBlackjackStand", 'PZLinuxBlackjackLogAction("STAND"')
assertServerBlackjackLog("PZLinuxBlackjackForfeit", 'PZLinuxBlackjackLogAction("FORFEIT"')
assertServerBlackjackLog("PZLinuxBlackjackFinish", 'PZLinuxBlackjackLogAction("FINISH"')

print("PZLinux blackjack forfeit/debounce tests OK")
