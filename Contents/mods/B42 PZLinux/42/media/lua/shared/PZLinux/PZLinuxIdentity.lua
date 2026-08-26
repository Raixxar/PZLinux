PZLinux = PZLinux or {}

local PZLINUX_IDENTITY_DATA = "PZLinuxCharacterIdentityRegistry"
local PZLINUX_IDENTITY_VERSION = 1

local function PZLinuxIdentityResolvePlayer(player)
    if PZLinuxGetPlayer then return PZLinuxGetPlayer(player) end
    if player and type(player) ~= "number" then return player end
    if player and getSpecificPlayer then return getSpecificPlayer(player) end
    if getPlayer then return getPlayer() end
    return nil
end

local function PZLinuxIdentityWorldHour()
    return getGameTime and getGameTime():getWorldAgeHours() or 0
end

local function PZLinuxIdentityTableHasEntries(value)
    if type(value) ~= "table" then return false end
    local hasEntries = false
    for _ in pairs(value) do hasEntries = true end
    return hasEntries
end

function PZLinuxIdentityIsPlayerDead(player)
    local playerObj = PZLinuxIdentityResolvePlayer(player)
    if not playerObj then return false end
    local ok, dead = pcall(function() return playerObj:isDead() end)
    return ok and dead == true
end

function PZLinuxIdentityIsAuthoritative()
    if isClient and isClient() then
        return isServer and isServer() or false
    end
    return true
end

local function PZLinuxIdentityIsLocalSinglePlayer()
    if isClient and isClient() then return false end
    if isServer and isServer() then return false end
    return true
end

local function PZLinuxIdentityGetLocalPlayerSlot(playerObj)
    if playerObj and playerObj.getPlayerNum then
        local ok, value = pcall(function() return playerObj:getPlayerNum() end)
        value = ok and tonumber(value) or nil
        if value and value >= 0 then return math.floor(value) end
    end
    return 0
end

function PZLinuxGetCharacterAccount(player)
    local playerObj = PZLinuxIdentityResolvePlayer(player)
    if playerObj and playerObj.getUsername then
        local username = tostring(playerObj:getUsername() or "")
        if username ~= "" then return username end
    end
    return "local-player"
end

function PZLinuxIdentityGetRegistry()
    if not ModData or not ModData.getOrCreate then return nil end
    local registry = ModData.getOrCreate(PZLINUX_IDENTITY_DATA)
    registry.version = PZLINUX_IDENTITY_VERSION
    registry.nextId = math.max(1, math.floor(tonumber(registry.nextId) or 1))
    registry.characters = registry.characters or {}
    registry.nativeCharacters = registry.nativeCharacters or {}
    return registry
end

local function PZLinuxIdentityGetNativeKeys(player)
    local playerObj = PZLinuxIdentityResolvePlayer(player)
    if not playerObj then return {} end
    local keys = {}
    local account = PZLinuxGetCharacterAccount(playerObj)

    -- B42.20 exposes the public field as sqlId. Do not probe hypothetical
    -- Java accessors here: Kahlua logs/raises missing reflected methods even
    -- inside pcall, which can abort unrelated server commands such as contract
    -- synchronization. The descriptor below remains the portable fallback.
    local sqlId = nil
    local fieldOk, fieldValue = pcall(function() return playerObj.sqlId end)
    if fieldOk then sqlId = tonumber(fieldValue) end
    if not sqlId then
        fieldOk, fieldValue = pcall(function() return playerObj.sqlID end)
        if fieldOk then sqlId = tonumber(fieldValue) end
    end
    if sqlId and sqlId > 0 then
        table.insert(keys, account .. ":sql:" .. tostring(math.floor(sqlId)))
    end

    local descriptorOk, descriptorId = pcall(function()
        local descriptor = playerObj:getDescriptor()
        return descriptor and descriptor:getID() or nil
    end)
    descriptorId = descriptorOk and tonumber(descriptorId) or nil
    if descriptorId and descriptorId > 0 then
        table.insert(keys, account .. ":descriptor:" .. tostring(math.floor(descriptorId)))
    end

    -- In B42.20 single-player, player ModData and the native descriptor can be
    -- unavailable or unstable across reloads before the server-style SQL ID
    -- exists. A local-only account+slot key keeps the same survivor attached to
    -- its persistent ledgers without allowing username-based ownership in MP.
    if PZLinuxIdentityIsLocalSinglePlayer() then
        table.insert(keys, account .. ":solo:" .. tostring(PZLinuxIdentityGetLocalPlayerSlot(playerObj)))
    end
    return keys
end

function PZLinuxGetCharacterNativeKey(player)
    return PZLinuxIdentityGetNativeKeys(player)[1]
end

function PZLinuxGetCharacterId(player, createIfMissing)
    local playerObj = PZLinuxIdentityResolvePlayer(player)
    local modData = playerObj and playerObj.getModData and playerObj:getModData() or nil
    if not modData then return nil end

    local previousCharacterId = tostring(modData.PZLinuxCharacterId or "")
    local previousAccount = tostring(modData.PZLinuxCharacterAccount or "")
    local previousNativeKey = tostring(modData.PZLinuxCharacterNativeKey or "")
    local characterId = previousCharacterId
    if not PZLinuxIdentityIsAuthoritative() then
        return characterId ~= "" and characterId or nil
    end

    local registry = PZLinuxIdentityGetRegistry()
    if not registry then return nil end
    local account = PZLinuxGetCharacterAccount(playerObj)
    local nativeKeys = PZLinuxIdentityGetNativeKeys(playerObj)
    local nativeKey = nativeKeys[1]
    local playerIsDead = PZLinuxIdentityIsPlayerDead(playerObj)
    local previousRecord = characterId ~= "" and registry.characters[characterId] or nil
    local preserveDeceasedIdentity = playerIsDead
        and previousRecord
        and previousRecord.account == account
        and previousRecord.status == "deceased"
    local nativeCharacterId = nil
    if not preserveDeceasedIdentity then
        for _, key in ipairs(nativeKeys) do
            if registry.nativeCharacters[key] then
                nativeCharacterId = registry.nativeCharacters[key]
                break
            end
        end
    end
    if preserveDeceasedIdentity then
        characterId = tostring(characterId)
    elseif nativeCharacterId then
        local nativeRecord = registry.characters[tostring(nativeCharacterId)]
        local replaceDeceased = createIfMissing ~= false
            and nativeRecord
            and nativeRecord.status == "deceased"
            and not playerIsDead
        if replaceDeceased then
            for _, key in ipairs(nativeKeys) do
                if registry.nativeCharacters[key] == nativeCharacterId then
                    registry.nativeCharacters[key] = nil
                end
            end
            characterId = ""
        else
            characterId = tostring(nativeCharacterId)
        end
    elseif characterId ~= "" then
        local existingRecord = registry.characters[characterId]
        local wrongAccount = existingRecord and existingRecord.account ~= account
        local hasNativeBinding = existingRecord and (existingRecord.nativeKey
            or PZLinuxIdentityTableHasEntries(existingRecord.nativeKeys))
        local matchingNativeCharacter = false
        for _, key in ipairs(nativeKeys) do
            if existingRecord
            and (existingRecord.nativeKey == key
                or (existingRecord.nativeKeys and existingRecord.nativeKeys[key])) then
                matchingNativeCharacter = true
                break
            end
        end
        local wrongNativeCharacter = hasNativeBinding and #nativeKeys > 0 and not matchingNativeCharacter
        local replaceDeceased = createIfMissing ~= false
            and existingRecord
            and existingRecord.status == "deceased"
            and not playerIsDead
        if wrongAccount or wrongNativeCharacter or replaceDeceased then characterId = "" end
    end

    if characterId == "" then
        if createIfMissing == false then return nil end
        characterId = "PZLinuxCharacter-" .. tostring(registry.nextId)
        registry.nextId = registry.nextId + 1
    end

    local record = registry.characters[characterId] or {
        account = account,
        createdHour = PZLinuxIdentityWorldHour(),
        status = "active",
    }
    record.account = account
    record.nativeKeys = record.nativeKeys or {}
    if not preserveDeceasedIdentity then
        for _, key in ipairs(nativeKeys) do
            record.nativeKeys[key] = true
            registry.nativeCharacters[key] = characterId
        end
        if nativeKey then record.nativeKey = nativeKey end
    end
    registry.characters[characterId] = record
    local numericId = tonumber(characterId:match("(%d+)$"))
    if numericId then registry.nextId = math.max(registry.nextId, numericId + 1) end

    modData.PZLinuxCharacterId = characterId
    modData.PZLinuxCharacterAccount = account
    if nativeKey and not preserveDeceasedIdentity then modData.PZLinuxCharacterNativeKey = nativeKey end
    if playerObj.transmitModData
    and (previousCharacterId ~= characterId
        or previousAccount ~= account
        or (nativeKey and previousNativeKey ~= nativeKey)) then
        playerObj:transmitModData()
    end
    return characterId
end

function PZLinuxGetCharacterKey(player, createIfMissing)
    local characterId = PZLinuxGetCharacterId(player, createIfMissing)
    if not characterId then return nil end
    return PZLinuxGetCharacterAccount(player) .. ":" .. characterId
end

function PZLinuxMarkCharacterDead(player)
    local playerObj = PZLinuxIdentityResolvePlayer(player)
    local characterId = PZLinuxGetCharacterId(playerObj, false)
    local registry = characterId and PZLinuxIdentityGetRegistry() or nil
    local record = registry and registry.characters[characterId] or nil
    if not record then return false end
    record.status = "deceased"
    record.deathHour = PZLinuxIdentityWorldHour()
    return true
end
