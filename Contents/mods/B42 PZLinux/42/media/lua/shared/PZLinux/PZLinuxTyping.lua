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

local function PZLinuxTypingNow()
    return math.ceil(getGameTime():getWorldAgeHours() * 3600)
end

function PZLinux.Typing.wait(ui, minimum, maximum, multiplier)
    local minDelay = minimum or PZLinuxTypingConfigNumber("messageDelayMin", 20)
    local maxDelay = maximum or PZLinuxTypingConfigNumber("messageDelayMax", 100)
    local duration = PZLinuxTypingRandomDelay(minDelay, maxDelay) * (tonumber(multiplier) or 1)
    local deadline = PZLinuxTypingNow() + duration

    while PZLinuxTypingNow() < deadline do
        if ui and ui.isClosing then return false end
        coroutine.yield()
    end
    return not (ui and ui.isClosing)
end

function PZLinux.Typing.typeLabel(ui, label, text, playerObj, options)
    options = options or {}
    local message = tostring(options.prefix or "")
    local volume = tonumber(options.volume)
    local minDelay = options.minDelay or PZLinuxTypingConfigNumber("typingDelayMin", 1)
    local maxDelay = options.maxDelay or PZLinuxTypingConfigNumber("typingDelayMax", 3)

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
