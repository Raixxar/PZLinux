-- Regression test for a player-reported bug: a player with $100,000 in
-- their bank account was told "I need money in my bank account" when
-- trying to buy an $80,000 course. Root cause: onPayCourse showed that
-- exact hardcoded string for EVERY purchase failure other than
-- "training_in_progress" -- including "invalid_course" (the offer they
-- clicked was no longer valid, e.g. bought out from under them or the
-- week rolled over between refreshes), which had nothing to do with their
-- balance at all. Every real server error code must now map to its own
-- honest message instead of a one-size-fits-all wrong claim about money.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_training_purchase_errors.lua$") or "."
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

local source = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxTraining.lua")
local block = source:match("function trainingUI:onPayCourse.-\nend")
PZLinuxTestAssert(block, "trainingUI:onPayCourse must exist")
local onPayCourse = assert(loadstring(block:gsub("^function trainingUI:onPayCourse%(button%)", "return function(self, button)", 1)))()

-- Structural guard: the old catch-all must be gone for good.
PZLinuxTestAssert(not block:find("I need money in my bank account", 1, true),
    "the hardcoded catch-all money message must never come back")

PZLinuxGetPlayer = function(p) return p end
PZLinuxGetText = function(key) return key end
getSoundManager = function()
    return { PlayWorldSound = function() return {} end }
end
local badTextShown
HaloTextHelper = { addBadText = function(_player, text) badTextShown = text end }

local requestedOfferId
local scriptedResult
PZLinuxRequestTrainingPurchase = function(_player, offerId, callback)
    requestedOfferId = offerId
    callback(scriptedResult)
end

local function newFakeButton()
    local calls = {}
    return {
        setEnable = function(_self, v) table.insert(calls, v) end,
        _enableCalls = calls,
    }
end

local function newSelf(selectedOfferId)
    local refreshCalls = 0
    return {
        selectedOfferId = selectedOfferId,
        cancelButton = newFakeButton(),
        applyState = function() end,
        refresh = function() refreshCalls = refreshCalls + 1 end,
        isClosing = false,
        player = { getSquare = function() return nil end },
        _refreshCalls = function() return refreshCalls end,
    }
end

-- 1. training_in_progress -- unrelated to money, must show its own message.
do
    local s = newSelf("electricity_400")
    scriptedResult = { ok = false, error = "training_in_progress" }
    onPayCourse(s, newFakeButton())
    PZLinuxTestAssert(badTextShown == "IGUI_PZLinux_Training_AlreadyInProgress",
        "training_in_progress must show the AlreadyInProgress message, got " .. tostring(badTextShown))
end

-- 2. not_enough_money -- the one case where blaming money is correct.
do
    local s = newSelf("electricity_400")
    scriptedResult = { ok = false, error = "not_enough_money" }
    onPayCourse(s, newFakeButton())
    PZLinuxTestAssert(badTextShown == "IGUI_PZLinux_Training_NotEnoughMoney",
        "not_enough_money must show the NotEnoughMoney message, got " .. tostring(badTextShown))
end

-- 3. invalid_course -- the exact bug reported: must NOT blame money, must
-- clear the stale selection, and must resync the list from the server.
do
    local s = newSelf("electricity_800")
    scriptedResult = { ok = false, error = "invalid_course" }
    onPayCourse(s, newFakeButton())
    PZLinuxTestAssert(badTextShown == "IGUI_PZLinux_Training_CourseNoLongerAvailable",
        "invalid_course must show CourseNoLongerAvailable, not a money message, got " .. tostring(badTextShown))
    PZLinuxTestAssert(s.selectedOfferId == nil, "invalid_course must clear the stale selection")
    PZLinuxTestAssert(s._refreshCalls() == 1, "invalid_course must trigger a refresh to resync the offer list")
end

-- 4. Any other/unexpected error code -- an honest generic message, never
-- the wrong specific claim about money.
do
    local s = newSelf("electricity_400")
    scriptedResult = { ok = false, error = "internal_error" }
    onPayCourse(s, newFakeButton())
    PZLinuxTestAssert(badTextShown == "IGUI_PZLinux_Training_PurchaseFailed",
        "an unknown error code must fall back to a generic honest message, got " .. tostring(badTextShown))
end

-- 5. Sanity: the actually-selected offer id is what gets sent to the
-- server, not something stale left over on the button itself.
do
    local s = newSelf("cooking_200")
    scriptedResult = { ok = false, error = "not_enough_money" }
    onPayCourse(s, newFakeButton())
    PZLinuxTestAssert(requestedOfferId == "cooking_200",
        "the purchase request must use self.selectedOfferId, got " .. tostring(requestedOfferId))
end

print("PZLinux Training purchase error mapping tests OK")
