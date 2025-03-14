local debug = 0
function DebugtMenu_AddContext(player, context, worldobjects)
    if debug == 1 then
        context:addOption("Debug-1", player, DebugMenu_OnDebug1)
        context:addOption("Debug-2", player, DebugMenu_OnDebug2)
    end
end

function DebugMenu_OnDebug1(x, y, message)
    local x = 450
    local y = 9792
    local message = "test"
    ISWorldMap.ShowWorldMap(0)
    ISWorldMap.HideWorldMap(0)
    WorldMapVisited.getInstance():setVisitedInCells(x, y, x + 10, y + 10)
    local mapSymbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTexture("Circle", x, y)
    local mapText = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTranslatedText(message, UIFont.SdfCaveat, x + 20, y)
    mapSymbol:setRGBA(0, 0, 0, 1.0)
    mapSymbol:setAnchor(0.5, 0.5)
    mapText:setRGBA(0, 0, 0, 1.0)
end

function DebugMenu_OnDebug2()
    local priceMultiplier = SandboxVars.PZLinux.PriceMultiplier or 1.0
    print(priceMultiplier)
end

Events.OnFillWorldObjectContextMenu.Add(DebugtMenu_AddContext)
