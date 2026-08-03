PZLinux = PZLinux or {}

local function PZLinuxContractsRoundReward(value)
    return PZLinux.Economy.roundPrice(value, "nearest")
end

local function PZLinuxContractsMissionRequest(entries, minimum, maximum)
    if type(entries) ~= "table" or #entries == 0 then return nil end
    local request = entries[ZombRand(#entries) + 1]
    if not request then return nil end

    local count = minimum or 1
    if maximum and maximum > count then
        count = ZombRand(count, maximum + 1)
    end
    return request, count
end

function PZLinuxContractsFormatKillProgress(zombieCount, zombieTarget)
    return "* Zombies killed: " .. tostring(math.max(0, tonumber(zombieCount) or 0))
        .. " / " .. tostring(math.max(0, tonumber(zombieTarget) or 0))
end

function PZLinuxContractsSetKillProgress(noteText, zombieCount, zombieTarget)
    local note = tostring(noteText or "")
    local progress = PZLinuxContractsFormatKillProgress(zombieCount, zombieTarget)
    local replacements
    note, replacements = note:gsub("%* Zombies killed: %d+ / %d+", progress, 1)
    if replacements == 0 then
        note = note:gsub("\n%s*%* Zombies to kill: %d+", "", 1)
        note = note:gsub("\n%s*Total zombies killed: %d+", "", 1)
        note = note:gsub("%s+$", "") .. "\n\n" .. progress
    end
    return note
end

function PZLinuxContractsSanitizeNoteText(noteText)
    local note = tostring(noteText or "")
    note = note:gsub("^:[ \t]*\r?\n%*[ \t]*\r?\n?", "", 1)
    note = note:gsub("^All around the world:[ \t]*\r?\n", "", 1)
    return note
end

function PZLinuxContractsCanonicalActiveState(status)
    if status == "completed" or status == "cancelled" then return 0 end
    if status == "ready_to_complete" or status == "deposited" then return 9 end
    return 1
end

local function PZLinuxContractsMissionNote(mission)
    local locationLine = ""
    if mission.locationCity ~= "" and mission.locationDescription ~= "" then
        locationLine = mission.locationCity .. ":\n* " .. mission.locationDescription
    end
    if mission.contractId == 8 then
        if locationLine ~= "" then locationLine = locationLine .. "\n" end
        locationLine = locationLine .. "* Zombies to kill: 10"
    end
    if mission.contractId == 13 and mission.atmAmount > 0 then
        if locationLine ~= "" then locationLine = locationLine .. "\n" end
        locationLine = locationLine .. "* Amount to deposit: $" .. tostring(mission.atmAmount)
    end

    local contractNote = "* [" .. tostring(mission.code) .. "] " .. tostring(mission.questName)
        .. " for $" .. tostring(mission.reward)
    if mission.infoCount > 0 and mission.infoName ~= "" then
        contractNote = contractNote .. "\n* " .. tostring(mission.infoCount) .. " " .. mission.infoName
    end

    local fullNote = contractNote
    if locationLine ~= "" then
        fullNote = locationLine .. "\n" .. fullNote
    end
    if mission.contractId == 1 and mission.zombieToKill > 0 then
        fullNote = fullNote .. "\n\n" .. PZLinuxContractsFormatKillProgress(0, mission.zombieToKill)
    end
    return contractNote, fullNote
end

function PZLinuxContractsBuildMission(selectedContract)
    if type(selectedContract) ~= "table" then return nil, "invalid_contract" end

    local contractId = tonumber(selectedContract.id)
    local mission = {
        contractId = contractId,
        code = tostring(selectedContract.code or ""),
        questName = tostring(selectedContract.questName or ""),
        cityId = tonumber(selectedContract.cityId) or 0,
        difficulty = tonumber(selectedContract.difficulty) or 0,
        reward = tonumber(selectedContract.reward) or 0,
        locationId = "",
        locationPool = "",
        locationX = 0,
        locationY = 0,
        locationZ = 0,
        locationCity = "",
        locationDescription = "",
        locationDescriptionKey = "",
        info = "",
        infoName = "",
        infoCount = 0,
        targetName = "",
        zombieToKill = 0,
        atmAmount = 0,
    }

    local poolName = PZLinuxGetContractLocationPoolName(contractId)
    if poolName then
        local location = PZLinuxGetRandomPoolLocation(poolName, mission.cityId)
        if not location then return nil, "missing_contract_location" end

        mission.locationId = tostring(location.id or "")
        mission.locationPool = poolName
        mission.locationX = tonumber(location.x) or 0
        mission.locationY = tonumber(location.y) or 0
        mission.locationZ = tonumber(location.z) or 0
        mission.locationCity = tostring(location.city or PZLinuxContractCities[mission.cityId] or "")
        mission.locationDescription = tostring(location.rawDescription or location.description or "")
        mission.locationDescriptionKey = tostring(location.descriptionKey or "")
        mission.reward = PZLinuxApplyLocationRewardModifier(mission.reward, mission.locationZ)
    end

    if contractId == 1 then
        mission.zombieToKill = ZombRand(1, 6) * 10
        mission.reward = mission.reward + mission.zombieToKill * 100
    elseif contractId == 3 then
        mission.targetName = PZLinuxContractsRandomTargetName()
    elseif contractId == 5 then
        local request, count = PZLinuxContractsMissionRequest(PZLinuxContractAutoPartRequests, 1, 1)
        if not request then return nil, "missing_contract_request" end
        mission.info = request.baseName
        mission.infoName = request.name
        mission.infoCount = count
        mission.reward = mission.reward * request.delta
    elseif contractId == 9 then
        local request, count = PZLinuxContractsMissionRequest(PZLinuxContractMedicalRequests, 1, 10)
        if not request then return nil, "missing_contract_request" end
        mission.info = request.baseName
        mission.infoName = request.name
        mission.infoCount = count
        mission.reward = mission.reward * request.delta
    elseif contractId == 10 then
        local request, count = PZLinuxContractsMissionRequest(PZLinuxContractWeaponRequests, 1, 5)
        if not request then return nil, "missing_contract_request" end
        mission.info = request.baseName
        mission.infoName = request.name
        mission.infoCount = count
        mission.reward = mission.reward * request.delta
    elseif contractId == 11 or contractId == 12 then
        mission.infoCount = 1
    elseif contractId == 13 then
        -- Location comes from the "atmRefill" pool above (a single fixed,
        -- wall-mounted ATM in Ekron) -- only the refill amount is rolled here.
        local atmCfg = PZLinux.Config.AtmRefill
        local minSteps = math.floor(atmCfg.amountMin / atmCfg.amountStep)
        local maxSteps = math.floor(atmCfg.amountMax / atmCfg.amountStep)
        mission.atmAmount = ZombRand(minSteps, maxSteps + 1) * atmCfg.amountStep
    end

    mission.reward = PZLinuxContractsRoundReward(mission.reward)
    mission.note, mission.fullNote = PZLinuxContractsMissionNote(mission)
    return mission
end
