PZLinux = PZLinux or {}

-- Base.Stone (plain, no suffix) doesn't exist in the current game -- the
-- generic loose stone item is Base.Stone2 (displays simply as "Stone");
-- fixed in the Materials category below (found while auditing every
-- Base.* reference across this mod's item catalogs -- see also
-- PZLinuxDarkWebData.lua's own stale-item cleanup).
PZLinuxRequestDefinitions = PZLinuxRequestDefinitions or {
    [1] = { baseName = "Canned food", price = 750, defaultWeight = 1, itemWeights = { ["Base.TunaTin"] = 0.3 }, items = {"Base.TinnedBeans", "Base.CannedCarrots2", "Base.CannedChili", "Base.CannedCorn", "Base.CannedCornedBeef", "Base.CannedMushroomSoup", "Base.CannedPeaches", "Base.CannedPeas", "Base.CannedPineapple", "Base.CannedPotato2", "Base.CannedSardines", "Base.TinnedSoup", "Base.CannedBolognese", "Base.CannedTomato2", "Base.TunaTin", "Base.Dogfood", "Base.CannedMilk", "Base.CannedFruitBeverage"} },
    [2] = { baseName = "Meat", price = 1000, defaultWeight = 0.3, itemWeights = { ["Base.Baloney"] = 0.5, ["Base.Ham"] = 0.1, ["Base.Salami"] = 0.1, ["Base.Sausage"] = 0.1 }, items = {"Base.Baloney", "Base.Chicken", "Base.Ham", "Base.MincedMeat", "Base.MuttonChop", "Base.PorkChop", "Base.Salami", "Base.Sausage", "Base.Steak"} },
    [3] = { baseName = "Fish", price = 1500, defaultWeight = 10, items = {"Base.Paddlefish", "Base.FlatheadCatfish", "Base.ChannelCatfish", "Base.BlueCatfish", "Base.BlackCrappie", "Base.Bluegill", "Base.Shrimp", "Base.FreshwaterDrum", "Base.Muskellunge", "Base.SmallmouthBass", "Base.StripedBass", "Base.WhiteBass", "Base.YellowPerch"} },
    [4] = { baseName = "Fruits", price = 500, defaultWeight = 0.2, itemWeights = { ["Base.Apple"] = 0.3, ["Base.BerryBlack"] = 0.1, ["Base.BerryBlue"] = 0.1, ["Base.Cherry"] = 0.3, ["Base.Mango"] = 0.3, ["Base.Pineapple"] = 0.3, ["Base.Watermelon"] = 3 }, items = {"Base.Apple", "Base.Banana", "Base.BerryBlack", "Base.BerryBlue", "Base.Cherry", "Base.Grapes", "Base.Lemon", "Base.Lime", "Base.Mango", "Base.Orange", "Base.Peach", "Base.Pear", "Base.Pineapple", "Base.Watermelon"} },
    [5] = { baseName = "Vegetables", price = 500, defaultWeight = 0.3, itemWeights = { ["Base.Blackbeans"] = 0.1, ["Base.Broccoli"] = 0.2, ["Base.Daikon"] = 0.2, ["Base.Edamame"] = 0.1, ["Base.PepperHabanero"] = 0.1, ["Base.PepperJalapeno"] = 0.1, ["Base.Leek"] = 0.2, ["Base.Lettuce"] = 0.5, ["Base.Onion"] = 0.2, ["Base.Pickles"] = 0.1, ["Base.Pumpkin"] = 1 }, items = {"Base.Avocado", "Base.BellPepper", "Base.Blackbeans", "Base.Broccoli", "Base.Carrots", "Base.Corn", "Base.Daikon", "Base.Edamame", "Base.Eggplant", "Base.PepperHabanero", "Base.PepperJalapeno", "Base.Leek", "Base.Lettuce", "Base.Onion", "Base.Pickles", "Base.Pumpkin", "Base.Zucchini"} },
    [6] = { baseName = "Pickled food", price = 950, defaultWeight = 1, items = {"Base.CannedBellPepper", "Base.CannedBroccoli", "Base.CannedCabbage", "Base.CannedCarrots", "Base.CannedEggplant", "Base.CannedLeek", "Base.CannedPotato", "Base.CannedRedRadish", "Base.CannedTomato"} },
    [7] = { baseName = "Drink", price = 1000, defaultWeight = 1, items = {"Base.JuiceBox", "Base.Milk", "Base.PopBottle", "Base.Pop2", "Base.Pop", "Base.Pop3"} },
    [8] = { baseName = "Book", price = 800, defaultWeight = 1, itemWeights = { ["Base.Magazine"] = 0.5 }, items = {"Base.Book", "Base.Magazine"} },
    [9] = { baseName = "Car", price = 65000, defaultWeight = 10, vehicles = {
        { baseName = "Base.CarStationWagon", delta = 1.2 }, { baseName = "Base.CarStationWagon2", delta = 1.2 }, { baseName = "Base.SportsCar", delta = 4 }, { baseName = "Base.PickUpTruck", delta = 2 }, { baseName = "Base.PickUpTruckLightsFire", delta = 2.5 }, { baseName = "Base.PickUpTruckMccoy", delta = 2 }, { baseName = "Base.SmallCar", delta = 0.5 }, { baseName = "Base.CarNormal", delta = 1 }, { baseName = "Base.CarLightsPolice", delta = 2 }, { baseName = "Base.CarTaxi", delta = 1 }, { baseName = "Base.CarTaxi2", delta = 1 }, { baseName = "Base.ModernCar02", delta = 1.5 }, { baseName = "Base.StepVan", delta = 1.8 }, { baseName = "Base.StepVanMail", delta = 1.8 }, { baseName = "Base.StepVan_Heralds", delta = 1.8 }, { baseName = "Base.StepVan_Scarlet", delta = 1.8 }, { baseName = "Base.ModernCar", delta = 1.5 }, { baseName = "Base.OffRoad", delta = 3 }, { baseName = "Base.SUV", delta = 3 }, { baseName = "Base.Van", delta = 2 }, { baseName = "Base.VanAmbulance", delta = 2.5 }, { baseName = "Base.VanRadio", delta = 2 }, { baseName = "Base.VanSeats", delta = 2 }, { baseName = "Base.VanRadio_3N", delta = 2 }, { baseName = "Base.VanSpiffo", delta = 2 }, { baseName = "Base.Van_KnoxDisti", delta = 2 }, { baseName = "Base.Van_LectroMax", delta = 2 }, { baseName = "Base.Van_MassGenFac", delta = 2 }, { baseName = "Base.Van_Transit", delta = 2 }, { baseName = "Base.SmallCar02", delta = 0.5 }, { baseName = "Base.CarLuxury", delta = 4 }
    } },
    [10] = { baseName = "Repairing", price = 700, defaultWeight = 0.5, itemWeights = { ["Base.Scotchtape"] = 0.3, ["Base.Woodglue"] = 1 }, items = {"Base.Scotchtape", "Base.DuctTape", "Base.Glue", "Base.Woodglue"} },
    [11] = { baseName = "Materials", price = 650, defaultWeight = 0.1, itemWeights = { ["Base.ConcretePowder"] = 5, ["Base.PlasterPowder"] = 5, ["Base.BarbedWire"] = 1, ["Base.NailsBox"] = 0.3, ["Base.PaperclipBox"] = 0.3, ["Base.Screws"] = 0.3, ["Base.Sparklers"] = 0.2, ["Base.Charcoal"] = 8, ["Base.Dirtbag"] = 2, ["Base.Hinge"] = 0.3, ["Base.Doorknob"] = 0.5, ["Base.Gravelbag"] = 2, ["Base.SheetMetal"] = 1.5, ["Base.Nails"] = 0.01, ["Base.Plank"] = 3, ["Base.PropaneTank"] = 10, ["Base.Rope"] = 0.8, ["Base.SmallSheetMetal"] = 0.4, ["Base.Stone2"] = 1, ["Base.Tarp"] = 1, ["Base.WeldingRods"] = 1.5, ["Base.Wire"] = 0.2, ["Base.DenimStrips"] = 0.05, ["Base.LeatherStrips"] = 0.05, ["Base.RippedSheets"] = 0.05 }, items = {"Base.Aluminum", "Base.ConcretePowder", "Base.PlasterPowder", "Base.BarbedWire", "Base.NailsBox", "Base.PaperclipBox", "Base.Screws", "Base.Sparklers", "Base.Charcoal", "Base.Dirtbag", "Base.Hinge", "Base.Doorknob", "Base.Gravelbag", "Base.GunPowder", "Base.SheetMetal", "Base.Nails", "Base.Plank", "Base.PropaneTank", "Base.Rope", "Base.SmallSheetMetal", "Base.Staples", "Base.Stone2", "Base.Tarp", "Base.Thread", "Base.Twine", "Base.WeldingRods", "Base.Wire", "Base.Yarn", "Base.DenimStrips", "Base.LeatherStrips", "Base.RippedSheets"} },
    [12] = { baseName = "Paint bucket", price = 450, defaultWeight = 5, items = {"Base.PaintBlack", "Base.PaintBlue", "Base.PaintBrown", "Base.PaintCyan", "Base.PaintGreen", "Base.PaintGrey", "Base.PaintLightBlue", "Base.PaintLightBrown", "Base.PaintOrange", "Base.PaintPink", "Base.PaintPurple", "Base.PaintRed", "Base.PaintTurquoise", "Base.PaintWhite", "Base.PaintYellow", "Base.PaintbucketEmpty"} },
    [13] = { baseName = "Electronics", price = 900, defaultWeight = 0.3, itemWeights = { ["Base.Battery"] = 0.1, ["Base.TimerCrafted"] = 0.5, ["Base.TriggerCrafted"] = 0.2, ["Base.ElectricWire"] = 0.1, ["Base.ElectronicsScrap"] = 0.1, ["Base.RadioReceiver"] = 0.1, ["Base.RadioTransmitter"] = 0.1, ["Base.Receiver"] = 0.1, ["Base.ScannerModule"] = 0.1, ["Base.RemoteCraftedV1"] = 0.4, ["Base.RemoteCraftedV2"] = 0.4, ["Base.RemoteCraftedV3"] = 0.4 }, items = {"Base.Battery", "Base.Amplifier", "Base.TimerCrafted", "Base.TriggerCrafted", "Base.ElectricWire", "Base.ElectronicsScrap", "Base.MotionSensor", "Base.RadioReceiver", "Base.RadioTransmitter", "Base.Receiver", "Base.ScannerModule", "Base.RemoteCraftedV1", "Base.RemoteCraftedV2", "Base.RemoteCraftedV3", "Base.LightBulb", "Base.LightBulbRed", "Base.LightBulbGreen", "Base.LightBulbBlue", "Base.LightBulbYellow", "Base.LightBulbCyan", "Base.LightBulbMagenta", "Base.LightBulbOrange", "Base.LightBulbPurple", "Base.LightBulbPink"} },
    [14] = { baseName = "Seeds", price = 300, defaultWeight = 0.1, items = {"Base.RoseBagSeed", "Base.PoppyBagSeed", "Base.LavenderBagSeed", "Base.BarleyBagSeed", "Base.RyeBagSeed", "Base.SugarBeetBagSeed", "Base.WheatBagSeed", "Base.ChamomileBagSeed", "Base.MarigoldBagSeed", "Base.LettuceBagSeed", "Base.BellPepperBagSeed", "Base.CauliflowerBagSeed", "Base.CucumberBagSeed", "Base.LeekBagSeed", "Base.LemonGrassBagSeed", "Base.ZucchiniBagSeed", "Base.WatermelonBagSeed", "Base.HabaneroBagSeed", "Base.JalapenoBagSeed", "Base.BlackSageBagSeed", "Base.BroadleafPlantainBagSeed", "Base.ComfreyBagSeed", "Base.CommonMallowBagSeed", "Base.HempBagSeed", "Base.HopsBagSeed", "Base.MintBagSeed", "Base.TurnipBagSeed", "Base.WildGarlicBagSeed", "Base.PumpkinBagSeed"} },
}

PZLinuxRequestCategoryTextKeys = PZLinuxRequestCategoryTextKeys or {
    [1] = "IGUI_PZLinux_Request_Category_CannedFood",
    [2] = "IGUI_PZLinux_Request_Category_Meat",
    [3] = "IGUI_PZLinux_Request_Category_Fish",
    [4] = "IGUI_PZLinux_Request_Category_Fruits",
    [5] = "IGUI_PZLinux_Request_Category_Vegetables",
    [6] = "IGUI_PZLinux_Request_Category_PickledFood",
    [7] = "IGUI_PZLinux_Request_Category_Drink",
    [8] = "IGUI_PZLinux_Request_Category_Book",
    [9] = "IGUI_PZLinux_Request_Category_Car",
    [10] = "IGUI_PZLinux_Request_Category_Repairing",
    [11] = "IGUI_PZLinux_Request_Category_Materials",
    [12] = "IGUI_PZLinux_Request_Category_Paint",
    [13] = "IGUI_PZLinux_Request_Category_Electronics",
    [14] = "IGUI_PZLinux_Request_Category_Seeds",
}

function PZLinuxRequestsGetOfferPool(contractId)
    local definition = PZLinuxRequestDefinitions[tonumber(contractId)]
    if not definition then return {} end

    local offers = {}
    local source = definition.vehicles or definition.items or {}
    for _, entry in ipairs(source) do
        local baseName = type(entry) == "table" and entry.baseName or entry
        local delta = type(entry) == "table" and entry.delta or nil
        local weight = type(entry) == "table" and entry.weight or nil
        weight = weight or (definition.itemWeights and definition.itemWeights[baseName]) or definition.defaultWeight or 1
        table.insert(offers, { baseName = baseName, weight = weight, delta = delta })
    end
    return offers
end

PZLinuxRequestVehicleLocations = PZLinuxRequestVehicleLocations or (PZLinuxGetMissionLocationPool and PZLinuxGetMissionLocationPool("vehicles") or {})
