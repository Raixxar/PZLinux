PZLinux = PZLinux or {}
PZLinux.Typing = PZLinux.Typing or {}

local function PZLinuxTypingConfigNumber(key, fallback)
    local uiConfig = PZLinux.Config and PZLinux.Config.UI or {}
    return tonumber(uiConfig[key]) or fallback
end

local function PZLinuxTypingRandomDelay(minimum, maximum)
    minimum = math.max(0, math.floor(tonumber(minimum) or 0))
    maximum = math.max(minimum, math.floor(tonumber(maximum) or minimum))
    if maximum == minimum then return minimum end
    return ZombRand(minimum, maximum + 1)
end

local function PZLinuxTypingCharacters(value)
    local characters = {}
    for character in tostring(value or ""):gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
        table.insert(characters, character)
    end
    return characters
end

-- A virtual clock that advances with real time at normal/paused speed, but
-- faster than real time when the player fast-forwards (getGameSpeed() > 1).
-- Using wall-clock time directly kept every dialogue/typing delay stuck at
-- real-time pace regardless of game speed; using world age directly would
-- instead freeze every dialogue while the game is paused, since world time
-- does not advance then. Accumulating real-time deltas scaled by the current
-- speed gets both right with a single clock.
local PZLinuxTypingVirtualClockMs = 0
local PZLinuxTypingLastRealMs = nil

local function PZLinuxTypingNowMs()
    local timestampProvider = rawget(_G, "getTimestampMs")
    local nowReal = timestampProvider and tonumber(timestampProvider()) or nil
    if not nowReal then
        return math.ceil(getGameTime():getWorldAgeHours() * 3600000)
    end

    if not PZLinuxTypingLastRealMs then
        PZLinuxTypingLastRealMs = nowReal
        return PZLinuxTypingVirtualClockMs
    end

    local deltaReal = nowReal - PZLinuxTypingLastRealMs
    PZLinuxTypingLastRealMs = nowReal
    if deltaReal > 0 then
        local speedProvider = rawget(_G, "getGameSpeed")
        local speed = speedProvider and tonumber(speedProvider()) or 1
        if not speed or speed <= 0 then speed = 1 end
        PZLinuxTypingVirtualClockMs = PZLinuxTypingVirtualClockMs + deltaReal * speed
    end
    return PZLinuxTypingVirtualClockMs
end

local PZLinuxTypingProfiles = {
    message = { minKey = "messageDelayMinMs", maxKey = "messageDelayMaxMs", minimum = 1800, maximum = 4200 },
    systemStatus = { minKey = "systemStatusDelayMinMs", maxKey = "systemStatusDelayMaxMs", minimum = 400, maximum = 1000 },
    atmPrompt = { minKey = "atmPromptDelayMinMs", maxKey = "atmPromptDelayMaxMs", minimum = 250, maximum = 650 },
    atmStatus = { minKey = "atmStatusDelayMinMs", maxKey = "atmStatusDelayMaxMs", minimum = 350, maximum = 850 },
}

function PZLinux.Typing.wait(ui, minimum, maximum, multiplier)
    local minDelay = minimum or PZLinuxTypingConfigNumber("messageDelayMinMs", 1800)
    local maxDelay = maximum or PZLinuxTypingConfigNumber("messageDelayMaxMs", 4200)
    local duration = PZLinuxTypingRandomDelay(minDelay, maxDelay) * (tonumber(multiplier) or 1)
    local deadline = PZLinuxTypingNowMs() + duration

    while PZLinuxTypingNowMs() < deadline do
        if ui and ui.isClosing then return false end
        coroutine.yield()
    end
    return not (ui and ui.isClosing)
end

function PZLinux.Typing.waitProfile(ui, profileName, multiplier)
    local profile = PZLinuxTypingProfiles[profileName] or PZLinuxTypingProfiles.message
    local minimum = PZLinuxTypingConfigNumber(profile.minKey, profile.minimum)
    local maximum = PZLinuxTypingConfigNumber(profile.maxKey, profile.maximum)
    return PZLinux.Typing.wait(ui, minimum, maximum, multiplier)
end

function PZLinux.Typing.typeLabel(ui, label, text, playerObj, options)
    options = options or {}
    local message = tostring(options.prefix or "")
    local volume = tonumber(options.volume)
    local minDelay = options.minDelay or PZLinuxTypingConfigNumber("typingDelayMinMs", 90)
    local maxDelay = options.maxDelay or PZLinuxTypingConfigNumber("typingDelayMaxMs", 180)

    if label then label:setName(message) end
    for _, character in ipairs(PZLinuxTypingCharacters(text)) do
        if ui and ui.isClosing then return false end

        if playerObj and options.sound ~= false then
            local soundName = options.soundName
                or tostring(options.soundPrefix or "typingKeyboard") .. tostring(ZombRand(1, 10))
            local sound = getSoundManager():PlayWorldSound(soundName, false, playerObj:getSquare(), 0, 20, 1, true)
            if sound and volume then sound:setVolume(volume) end
        end

        message = message .. character
        if label then label:setName(message) end
        if not PZLinux.Typing.wait(ui, minDelay, maxDelay, 1) then return false end
    end

    if playerObj and options.endSound ~= false then
        local sound = getSoundManager():PlayWorldSound(options.endSound or "typingKeyboardEnd", false, playerObj:getSquare(), 0, 20, 1, true)
        if sound and volume then sound:setVolume(volume) end
    end
    return true
end
