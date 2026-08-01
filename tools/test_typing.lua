local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_typing.lua$") or "."

local worldSeconds = 0
local randomRanges = {}
local playedSounds = {}

PZLinux = {
    Config = {
        UI = {
            typingDelayMin = 1,
            typingDelayMax = 3,
            messageDelayMin = 20,
            messageDelayMax = 100,
        },
    },
}

function ZombRand(minimum, maximum)
    table.insert(randomRanges, { minimum, maximum })
    return minimum
end

function getGameTime()
    return {
        getWorldAgeHours = function()
            return worldSeconds / 3600
        end,
    }
end

function getSoundManager()
    return {
        PlayWorldSound = function(_, soundName)
            table.insert(playedSounds, soundName)
            return { setVolume = function() end }
        end,
    }
end

dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxTyping.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function runCoroutine(callback)
    local thread = coroutine.create(callback)
    while coroutine.status(thread) ~= "dead" do
        local ok, errorMessage = coroutine.resume(thread)
        if not ok then error(errorMessage) end
        worldSeconds = worldSeconds + 1
    end
end

local label = { values = {} }
function label:setName(value)
    table.insert(self.values, value)
end

local completed = false
runCoroutine(function()
    completed = PZLinux.Typing.typeLabel({ isClosing = false }, label, "é漢", nil, {
        prefix = "> ",
        sound = false,
        endSound = false,
    })
end)

assertEqual(completed, true, "UTF-8 typing completes")
assertEqual(#label.values, 3, "UTF-8 characters are appended atomically")
assertEqual(label.values[1], "> ", "prefix is displayed first")
assertEqual(label.values[2], "> é", "accented character remains intact")
assertEqual(label.values[3], "> é漢", "Asian character remains intact")
assertEqual(randomRanges[1][1], 1, "typing minimum delay")
assertEqual(randomRanges[1][2], 4, "typing maximum delay is inclusive")

local closingUi = { isClosing = false }
local interrupted
local waitingThread = coroutine.create(function()
    interrupted = PZLinux.Typing.wait(closingUi)
end)
assert(coroutine.resume(waitingThread), "wait coroutine starts")
closingUi.isClosing = true
assert(coroutine.resume(waitingThread), "wait coroutine stops")
assertEqual(interrupted, false, "closing an UI interrupts its typing wait")
assertEqual(#playedSounds, 0, "disabled sounds remain silent")

print("PZLinux typing tests OK")
