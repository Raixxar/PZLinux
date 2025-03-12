function isNearTarget(x, y, z, targetX, targetY, targetZ)
    return math.max(math.abs(x - targetX), math.abs(y - targetY)) <= 5 and z == targetZ
end

function isNearTargetCapture(x, y, z, targetX, targetY, targetZ)
    return math.max(math.abs(x - targetX), math.abs(y - targetY)) <= 2 and z == targetZ
end

function getAdjacentFreeSquare(x, y, z, sprite)
    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil end

    local directions = {
        {x - 1, y, z},
        {x + 1, y, z},
        {x, y - 1, z},
        {x, y + 1, z}
    }

    if sprite == "location_business_bank_01_67" then directions = { {x, y + 1, z} } end
    if sprite == "location_business_bank_01_66" then directions = { {x + 1, y, z} } end
    if sprite == "location_business_bank_01_65" then directions = { {x, y - 1, z} } end
    if sprite == "location_business_bank_01_64" then directions = { {x - 1, y, z} } end
    if sprite == "appliances_com_01_75" then directions = { {x - 1, y, z} } end 
    if sprite == "appliances_com_01_74" then directions = { {x, y - 1, z} } end
    if sprite == "appliances_com_01_73" then directions = { {x + 1, y, z} } end
    if sprite == "appliances_com_01_72" then directions = { {x, y + 1, z} } end
    if sprite == "location_business_bank_01_67" then directions = { {x, y - 1, z} } end
    if sprite == "location_business_bank_01_66" then directions = { {x - 1, y, z} } end
    if sprite == "location_business_bank_01_65" then directions = { {x, y + 1, z} } end
    if sprite == "location_business_bank_01_64" then directions = { {x + 1, y, z} } end
    if sprite == "street_decoration_01_8" then directions = { {x, y + 1, z} } end
    if sprite == "street_decoration_01_9" then directions = { {x + 1, y, z} } end
    if sprite == "street_decoration_01_10" then directions = { {x, y - 1, z} } end
    if sprite == "street_decoration_01_11" then directions = { {x - 1, y, z} } end
    if sprite == "street_decoration_01_18" then directions = { {x + 1, y, z} } end
    if sprite == "street_decoration_01_19" then directions = { {x, y + 1, z} } end
    if sprite == "street_decoration_01_20" then directions = { {x - 1, y, z} } end
    if sprite == "street_decoration_01_21" then directions = { {x, y - 1, z} } end

    for _, coord in ipairs(directions) do
        local freeSquare = getCell():getGridSquare(coord[1], coord[2], coord[3])
        if freeSquare and freeSquare:isFree(false) then
            return freeSquare
        end
    end
    return nil
end

function reverseString(str)
    return str:reverse()
end

function generatePseudo(playerName)
    local reversedName = reverseString(playerName)
    local position = 3

    if #reversedName > position then
        local symbol = "_"
        reversedName = reversedName:sub(1, position) .. symbol .. reversedName:sub(position + 1)
    end

    return "<" .. reversedName .. "> "
end

function generateUsername()
    local prefixes = {"Xx", "Dark", "Neo", "Cyber", "Red", "Blue", "Fire", "Frost", "Shadow", "Ghost"}
    local suffixes = {"99", "77", "Pro", "X", "V2", "Elite", "Bot", "Z", "Master", "King"}
    local middle = {"_", ".", ""}

    local name = prefixes[ZombRand(1, #prefixes + 1)] ..
                 middle[ZombRand(1, #middle + 1)] ..
                 suffixes[ZombRand(1, #suffixes + 1)]
    
    return name
end

function bagContainsCorpse(bag)
    if not bag then return false end
    local inv = bag:getInventory()
    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if item:getFullType() == "Base.CorpseMale" then
            return true
        end
    end
    return false
end

function contractsDrawOnMap(x, y, message)
    ISWorldMap.ShowWorldMap(0)
    ISWorldMap.HideWorldMap(0)
    WorldMapVisited.getInstance():setVisitedInCells(x, y, x + 10, y + 10)
    local mapSymbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTexture("Circle", x, y)
    local mapText = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTranslatedText(message, UIFont.SdfCaveat, x + 20, y)
    mapSymbol:setRGBA(0, 0, 0, 1.0)
    mapSymbol:setAnchor(0.5, 0.5)
    mapText:setRGBA(0, 0, 0, 1.0)
end

function contractsRemoveDrawOnMap(x, y)
    ISWorldMap.ShowWorldMap(0)
    ISWorldMap.HideWorldMap(0)
    local count = ISWorldMap_instance.mapAPI:getSymbolsAPI():getSymbolCount()
    for i = 1, count do
        local symbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():getSymbolByIndex(i)
        if symbol then
            local wx = math.floor(symbol:getWorldX())
            if wx == math.floor(x) then
                local wy = math.floor(symbol:getWorldY())
                if wy == math.floor(y) then
                    ISWorldMap_instance.mapAPI:getSymbolsAPI():removeSymbolByIndex(i)
                    break
                end
            end
        end
    end
end

function getNearbyGenerator(square, consommation)
    if not square then return nil end
    local cell = getWorld():getCell()
    local generator = nil

    for i = 0, square:getObjects():size() - 1 do
        local obj = square:getObjects():get(i)
        if instanceof(obj, "IsoGenerator") and obj:isActivated() then
            generator = obj
            break
        end
    end

    if not generator then
        for z = -5, 5 do
            for x = -20, 20 do
                for y = -20, 20 do
                    local checkSquare = cell:getGridSquare(square:getX() + x, square:getY() + y, square:getZ() + z)
                    if checkSquare then
                        for i = 0, checkSquare:getObjects():size() - 1 do
                            local obj = checkSquare:getObjects():get(i)
                            if instanceof(obj, "IsoGenerator") and obj:isActivated() then
                                generator = obj
                                break
                            end
                        end
                    end
                    if generator then break end
                end
                if generator then break end
            end
        end
    end

    if generator and consommation then
        local fuelAmount = generator:getFuel()
        if fuelAmount > consommation then
            generator:setFuel(fuelAmount - consommation)
        else
            generator:setFuel(0)
            generator:setActivated(false)
        end
    end

    return generator
end

function ISGeneratorInfoWindow.getRichText(object, displayStats)
	local square = object:getSquare()
	if not displayStats then
		local text = " <INDENT:10> "
		if square and not square:isOutside() and square:getBuilding() then
			text = text .. " <RED> " .. getText("IGUI_Generator_IsToxic")
		end
		return text
	end
	local fuel = math.ceil(object:getFuel())
	local condition = object:getCondition()
	local text = getText("IGUI_Generator_FuelAmount", fuel) .. " <LINE> " .. getText("IGUI_Generator_Condition", condition) .. " <LINE> "
	if object:isActivated() then
		text = text ..  " <LINE> " .. getText("IGUI_PowerConsumption") .. ": <LINE> ";
		text = text .. " <INDENT:10> "
		local items = object:getItemsPowered()
		for i=0,items:size()-1 do
			text = text .. "   " .. items:get(i) .. " <LINE> ";
		end

        if getPlayer():getModData().PZLinuxIsPowered and getPlayer():getModData().PZLinuxIsPowered == 1 then
            text = text .. "Desktop Computer" .. " (0.02 L/h) <LINE> "
        end

        if getPlayer():getModData().ATMIsPowered and getPlayer():getModData().ATMIsPowered == 1 then
            text = text .. "ATM" .. " (0.01 L/h) <LINE> "
        end

		text = text .. getText("IGUI_Generator_TypeGas") .. " (0.02 L/h) <LINE> "
		text = text .. getText("IGUI_Total") .. ": " .. luautils.round(object:getTotalPowerUsing(), 3) .. " L/h <LINE> ";
	end
	if square and not square:isOutside() and square:getBuilding() then
		text = text .. " <LINE> <RED> " .. getText("IGUI_Generator_IsToxic")
	end
	return text
end

function PZLinuxUseFuel()
    local square = getPlayer():getSquare()
    if getPlayer():getModData().PZLinuxIsPowered and getPlayer():getModData().PZLinuxIsPowered == 1 then
        getNearbyGenerator(square, 0.0003)
    end

    if getPlayer():getModData().ATMIsPowered and getPlayer():getModData().ATMIsPowered == 1 then
        getNearbyGenerator(square, 0.0002)
    end
end
Events.EveryOneMinute.Add(PZLinuxUseFuel)