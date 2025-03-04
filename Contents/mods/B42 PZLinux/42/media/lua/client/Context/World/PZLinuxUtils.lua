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