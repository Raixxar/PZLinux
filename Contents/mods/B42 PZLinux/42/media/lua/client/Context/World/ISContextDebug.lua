local function PZLinuxDebugHasAdminAccess(playerObj)
    if not playerObj or not playerObj.getAccessLevel then return false end
    local accessLevel = tostring(playerObj:getAccessLevel() or ""):lower()
    return accessLevel == "admin" or accessLevel == "administrator"
end

local function PZLinuxDebugCanUseMenu(playerObj)
    if isClient and isClient() then
        return PZLinuxDebugHasAdminAccess(playerObj)
    end
    return isDebugEnabled and isDebugEnabled()
end

local function PZLinuxDebugForceContract(player, contractId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return end
    PZLinuxRequestAdminForceContract(playerObj, contractId, function(result)
        if result and result.ok then
            HaloTextHelper.addGoodText(playerObj, "Contract " .. tostring(contractId) .. " added to the board")
        else
            HaloTextHelper.addBadText(playerObj, "Admin command failed: "
                .. tostring(result and result.error or "no response"))
        end
    end)
end

local function PZLinuxDebugMenuAddContext(player, context, _worldobjects)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not PZLinuxDebugCanUseMenu(playerObj) then return end

    local adminOption = context:addOption("PZLinux Admin")
    local adminMenu = ISContextMenu:getNew(context)
    context:addSubMenu(adminOption, adminMenu)
    local forceOption = adminMenu:addOption("Force contract on board")
    local forceMenu = ISContextMenu:getNew(adminMenu)
    adminMenu:addSubMenu(forceOption, forceMenu)
    for _, definition in ipairs(PZLinuxContractDefinitions or {}) do
        forceMenu:addOption(
            tostring(definition.id) .. " - " .. tostring(definition.questName),
            player,
            PZLinuxDebugForceContract,
            definition.id
        )
    end
end

Events.OnFillWorldObjectContextMenu.Add(PZLinuxDebugMenuAddContext)
