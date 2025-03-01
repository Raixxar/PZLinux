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
