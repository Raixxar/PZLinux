require "ISUI/Maps/ISWorldMapSymbols"
require "ISUI/Maps/ISWorldMap"
require "ISUI/ISPanelJoypad"
require "ISUI/Maps/ISMap"
require "ZoneCheck"

local debug = 1
local quests = {
    [1] = { baseName = "Base.RoseBagSeed", weight = 0.1 },
    [2] = { baseName = "Base.PoppyBagSeed", weight = 0.1 },
    [3] = { baseName = "Base.LavenderBagSeed", weight = 0.1 },
    [4] = { baseName = "Base.BarleyBagSeed", weight = 0.1 },
    [5] = { baseName = "Base.RyeBagSeed", weight = 0.1 },
    [6] = { baseName = "Base.SugarBeetBagSeed", weight = 0.1 },
    [7] = { baseName = "Base.WheatBagSeed", weight = 0.1 },
    [8] = { baseName = "Base.ChamomileBagSeed", weight = 0.1 },
    [9] = { baseName = "Base.MarigoldBagSeed", weight = 0.1 },
    [10] = { baseName = "Base.LettuceBagSeed", weight = 0.1 },
    [11] = { baseName = "Base.BellPepperBagSeed", weight = 0.1 },
    [12] = { baseName = "Base.CauliflowerBagSeed", weight = 0.1 },
    [13] = { baseName = "Base.CucumberBagSeed", weight = 0.1 },
    [14] = { baseName = "Base.LeekBagSeed", weight = 0.1 },
    [15] = { baseName = "Base.LemonGrassBagSeed", weight = 0.1 },
    [16] = { baseName = "Base.ZucchiniBagSeed", weight = 0.1 },
    [17] = { baseName = "Base.WatermelonBagSeed", weight = 0.1 },
    [18] = { baseName = "Base.HabaneroBagSeed", weight = 0.1 },
    [19] = { baseName = "Base.JalapenoBagSeed", weight = 0.1 },
    [20] = { baseName = "Base.BlackSageBagSeed", weight = 0.1 },
    [21] = { baseName = "Base.BroadleafPlantainBagSeed", weight = 0.1 },
    [22] = { baseName = "Base.ComfreyBagSeed", weight = 0.1 },
    [23] = { baseName = "Base.CommonMallowBagSeed", weight = 0.1 },
    [24] = { baseName = "Base.HempBagSeed", weight = 0.1 },
    [25] = { baseName = "Base.HopsBagSeed", weight = 0.1 },
    [26] = { baseName = "Base.MintBagSeed", weight = 0.1 },
    [27] = { baseName = "Base.TurnipBagSeed", weight = 0.1 },
    [28] = { baseName = "Base.WildGarlicBagSeed", weight = 0.1 },
    [29] = { baseName = "Base.PumpkinBagSeed", weight = 0.1 },
}

function DebugtMenu_AddContext(player, context, worldobjects)
    if debug == 1 then
        context:addOption("Add Icon Map", player, DebugMenu_OnMap)
    end
end

function DebugMenu_OnMap(x, y, message)
    local x = 450
    local y = 9792
    local message = "CONTRACT Package $29038"
    contractsDrawOnMap(x, y, message)
end

function DebugMenu_OnUse(player)
    local inv = getPlayer():getInventory()
    local parcel = inv:AddItem('Base.Parcel_Large')
    local parcelInv = parcel:getInventory()

    local weightPackage = 0
    while weightPackage < 9 do
        local itemIdRand = ZombRand(1, #quests + 1)
        local quest = quests[itemIdRand]
        if quest then 
            local object = quest.baseName
            local weight = quest.weight
            weightPackage = weightPackage + quest.weight
            print(weightPackage)
            parcelInv:AddItem(object)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(DebugtMenu_AddContext)