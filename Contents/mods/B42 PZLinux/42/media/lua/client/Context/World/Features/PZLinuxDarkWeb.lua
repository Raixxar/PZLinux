-- Dark Web UI - by Raixxar 
-- Updated : 25/01/25

darkWebUI = ISPanel:derive("darkWebUI")

local LAST_CONNECTION_TIME = 0
local ITEMS_MAX = ZombRand(5,50)
local currentOffers = {}
local getItemName = nil

local darkWebItems = {
    -- HUNDGUNS 
    { id = {"Base.Revolver_Short"}, Price = 375 }, 
    { id = {"Base.Pistol"}, Price = 450 },
    { id = {"Base.Pistol2"}, Price = 675 },
    { id = {"Base.Revolver"}, Price = 787 },
    { id = {"Base.Pistol3"}, Price = 750 },
    { id = {"Base.Revolver_Long"}, Price = 1000 },
    --SHOTGUNS
    { id = {"Base.DoubleBarrelShotgun"}, Price = 1500 },
    { id = {"Base.Shotgun"}, Price = 1500 },
    { id = {"Base.DoubleBarrelShotgunSawnoff"}, Price = 2100 },
    { id = {"Base.ShotgunSawnoff"}, Price = 2275 },
    -- RIFLES
    { id = {"Base.AssaultRifle"}, Price = 2000 },
    { id = {"Base.VarmintRifle"}, Price = 2000 },
    { id = {"Base.AssaultRifle2"}, Price = 2400 },
    { id = {"Base.HuntingRifle"}, Price = 2400 },
    -- AMMOS
    { id = {"Base.Bullets9mmBox"}, Price = 100},
    { id = {"Base.Bullets38Box"}, Price = 175},
    { id = {"Base.Bullets44Box"}, Price = 190},
    { id = {"Base.223Box"}, Price = 300 },
    { id = {"Base.308Box"}, Price = 300 },
    { id = {"Base.ShotgunShellsBox"}, Price = 450 },
    { id = {"Base.Bullets45Box"}, Price = 500 },
    { id = {"Base.556Box"}, Price = 600 },
    { id = {"Base.9mmClip"}, Price = 500 },
    { id = {"Base.45Clip"}, Price = 500 },
    { id = {"Base.44Clip"}, Price = 500 },
    { id = {"Base.223Clip"}, Price = 700 },
    { id = {"Base.308Clip"}, Price = 700 },
    { id = {"Base.556Clip"}, Price = 1000 },
    { id = {"Base.M14Clip"}, Price = 1000 },
    { id = {"Base.223BulletsMold"}, Price = 800 },
    { id = {"Base.308BulletsMold"}, Price = 800 },
    { id = {"Base.9mmBulletsMold"}, Price = 800 },
    { id = {"Base.ShotgunShellsMold"}, Price = 800 },
    --SCOPE
    { id = {"Base.IronSight"}, Price = 500 },
    { id = {"Base.RedDot"}, Price = 1000 },
    { id = {"Base.x8Scope"}, Price = 4000 },
    { id = {"Base.x2Scope"}, Price = 1500 },
    { id = {"Base.x4Scope"}, Price = 2000 },
    -- SLING
    { id = {"Base.AmmoStraps"}, Price = 2500 },
    -- HACKING
    { id = {"Base.CreditCard"}, Price = 1000 },
    { id = {"Base.IDcard"}, Price = 1000 },
    -- EXPLOSIVES
    { id = {"Base.SmokeBomb"}, Price = 100 },
    { id = {"Base.Molotov"}, Price = 150 },
    { id = {"Base.Aerosolbomb"}, Price = 150 },
    { id = {"Base.FlameTrap"}, Price = 150 },
    { id = {"Base.PipeBomb"}, Price = 150 },
    { id = {"Base.AerosolbombTriggered"}, Price = 300 },
    { id = {"Base.AerosolbombRemote"}, Price = 300 },
    -- AXES
    { id = {"Base.BaseballBat_RailSpike"}, Price = 800 },
    { id = {"Base.BaseballBat_Sawblade"}, Price = 800 },
    { id = {"Base.ScrapWeapon_Brake"}, Price = 400 },
    { id = {"Base.EntrenchingTool"}, Price = 250 },
    { id = {"Base.FieldHockeyStick_Sawblade"}, Price = 933 },
    { id = {"Base.Axe"}, Price = 533 },
    { id = {"Base.ScrapWeaponGardenFork"}, Price = 400 },
    { id = {"Base.HandScythe"}, Price = 600 },
    { id = {"Base.HandScytheForged"}, Price = 600 },
    { id = {"Base.HandAxeForged"}, Price = 350 },
    { id = {"Base.IceAxe"}, Price = 350 },
    { id = {"Base.MetalPipe_Railspike"}, Price = 400 },
    { id = {"Base.JawboneBovide_Axe"}, Price = 600 },
    { id = {"Base.LongHandle_Railspike"}, Price = 700 },
    { id = {"Base.LongHandle_Sawblade"}, Price = 700 },
    { id = {"Base.StoneAxeLarge"}, Price = 867 },
    { id = {"Base.MeatCleaverForged"}, Price = 400 },
    { id = {"Base.BaseballBat_Metal_Sawblade"}, Price = 800 },
    { id = {"Base.PickAxeForged"}, Price = 667 },
    { id = {"Base.Axe_Sawblade"}, Price = 457 },
    { id = {"Base.Axe_Sawblade_Hatchet"}, Price = 280 },
    { id = {"Base.Axe_ScrapCleaver"}, Price = 867 },
    { id = {"Base.ShortBat_RailSpike"}, Price = 533 },
    { id = {"Base.WoodAxeForged"}, Price = 867 },
    -- LONG BLUNTS
    { id = {"Base.BaseballBat_Can"}, Price = 900 },
    { id = {"Base.BaseballBat_Spiked"}, Price = 800 },
    { id = {"Base.BlockMaul"}, Price = 1000 },
    { id = {"Base.CrowbarForged"}, Price = 600 },
    { id = {"Base.BaseballBat_Metal_Bolts"}, Price = 917 },
    { id = {"Base.BaseballBat_Metal"}, Price = 800 },
    { id = {"Base.Sledgehammer"}, Price = 667 },
    --- SHORT BLUNTS
    { id = {"Base.Mace"}, Price = 280 },
    { id = {"Base.SpikedShortBat"}, Price = 300 },
    -- LONG BLADES
    { id = {"Base.CrudeShortSword"}, Price = 667 },
    { id = {"Base.CrudeSword"}, Price = 1500 },
    { id = {"Base.Katana"}, Price = 8000 },
    { id = {"Base.Machete"}, Price = 1000 },
    { id = {"Base.Machete_Crude"}, Price = 1000 },
    { id = {"Base.MacheteForged"}, Price = 1000 },
    { id = {"Base.ShortSword"}, Price = 1000 },
    { id = {"Base.Sword"}, Price = 2000 },
    -- SHORT BLADES
    { id = {"Base.FightingKnife"}, Price = 600 },
    { id = {"Base.HandguardDagger"}, Price = 600 },
    { id = {"Base.LargeKnife"}, Price = 600 },
    { id = {"Base.KnifeParing"}, Price = 600 },
    { id = {"Base.HuntingKnife"}, Price = 600 },
    { id = {"Base.KitchenKnife"}, Price = 600 },
    { id = {"Base.KitchenKnifeForged"}, Price = 600 },
    { id = {"Base.HuntingKnifeForged"}, Price = 600 },
    { id = {"Base.KnifePocket"}, Price = 800 },
    -- SPEARS
    { id = {"Base.SpearLong"}, Price = 444 },
    { id = {"Base.SpearShort"}, Price = 417 },
    -- RECIPES
    { id = {"Base.SmithingMag8"}, Price = 500 },
    { id = {"Base.ArmorMag5"}, Price = 500 },
    { id = {"Base.WeaponMag4"}, Price = 500 },
    { id = {"Base.SmithingMag5"}, Price = 500 },
    { id = {"Base.ArmorMag2"}, Price = 500 },
    { id = {"Base.ArmorMag4"}, Price = 500 },
    { id = {"Base.ArmorMag7"}, Price = 500 },
    { id = {"Base.ElectronicsMag3"}, Price = 500 },
    { id = {"Base.ElectronicsMag4"}, Price = 500 },
    { id = {"Base.ElectronicsMag2"}, Price = 500 },
    { id = {"Base.SmithingMag7"}, Price = 500 },
    { id = {"Base.ArmorMag3"}, Price = 500 },
    { id = {"Base.ArmorMag6"}, Price = 500 },
    { id = {"Base.EngineerMagazine2"}, Price = 500 },
    { id = {"Base.WeaponMag5"}, Price = 500 },
    { id = {"Base.PrimitiveToolMag1"}, Price = 500 },
    { id = {"Base.ElectronicsMag1"}, Price = 500 },
    { id = {"Base.ArmorSchematic"}, Price = 500 },
    { id = {"Base.ExplosiveSchematic"}, Price = 500 },
    { id = {"Base.MeleeWeaponSchematic"}, Price = 500 },
    -- MEDICAL
    { id = {"Base.Antibiotics"}, Price = 1500 },
    { id = {"Base.PillsAntiDep"}, Price = 500 },
    { id = {"Base.PillsBeta"}, Price = 500 },
    { id = {"Base.Pills"}, Price = 100 },
    { id = {"Base.PillsSleepingTablets"}, Price = 200 },
    { id = {"Base.PillsVitamins"}, Price = 100 },
    { id = {"Base.CigarettePack"}, Price = 50 },
    { id = {"Base.CigaretteCarton"}, Price = 500 },
    { id = {"Base.CigarBox"}, Price = 1000 },
    -- EQUIPMENT
    { id = {"Base.Bag_ALICEpack_Army"}, Price = 2000 },
    -- VEHICLE
    { id = {"Base.PetrolCan"}, Price = 3000 },
    -- ELECTRONICS
    { id = {"Base.Generator"}, Price = 5000 },
    { id = {"Base.ElectronicsScrap"}, Price = 50 },
    -- CLOTHING
    { id = {"Base.Socks_Heavy"}, Price = 50 },
    { id = {"Base.Socks_Long"}, Price = 50},
    { id = {"Base.Socks_Long_White"}, Price = 50 },
    { id = {"Base.Socks_Long_Black"}, Price = 50 },
    { id = {"Base.Socks_Ankle"}, Price = 50 }, 
    { id = {"Base.Socks_Ankle_White"}, Price = 50 },
    { id = {"Base.Socks_Ankle_Black"}, Price = 50 },
    { id = {"Base.Bra_Straps_AnimalPrint"}, Price = 100 },
    { id = {"Base.Bra_Straps_FrillyBlack"}, Price = 100 },
    { id = {"Base.Bra_Straps_Black"}, Price = 100 },
    { id = {"Base.Bra_Straps_FrillyPink"}, Price = 100 },
    { id = {"Base.Bra_Straps_FrillyRed"}, Price = 100 },
    { id = {"Base.Bra_Straps_Hide"}, Price = 100 },
    { id = {"Base.Bra_Strapless_AnimalPrint"}, Price = 100 },
    { id = {"Base.Bra_Strapless_FrillyBlack"}, Price = 100 },
    { id = {"Base.Bra_Strapless_Black"}, Price = 100 },
    { id = {"Base.Bra_Strapless_FrillyPink"}, Price = 100 },
    { id = {"Base.Bra_Strapless_FrillyRed"}, Price = 100 },
    { id = {"Base.Bra_Strapless_RedSpots"}, Price = 100 },
    { id = {"Base.Bra_Strapless_Hide"}, Price = 100 },
    { id = {"Base.Bra_Strapless_White"}, Price = 100 },
    { id = {"Base.Bra_Straps_White"}, Price = 100 },
    { id = {"Base.Bikini_Pattern01"}, Price = 150 },
    { id = {"Base.Briefs_SmallTrunks_Black"}, Price = 200 },
    { id = {"Base.Briefs_SmallTrunks_Blue"}, Price = 200 },
    { id = {"Base.Briefs_SmallTrunks_Red"}, Price = 200 },
    { id = {"Base.Underpants_AnimalPrint"}, Price = 200 },
    { id = {"Base.FrillyUnderpants_Black"}, Price = 200 },
    { id = {"Base.Underpants_Black"}, Price = 200 },
    { id = {"Base.FrillyUnderpants_Pink"}, Price = 200 },
    { id = {"Base.FrillyUnderpants_Red"}, Price = 200 },
    { id = {"Base.Underpants_RedSpots"}, Price = 200 },
    { id = {"Base.Underpants_Hide"}, Price = 200 },
    { id = {"Base.Underpants_White"}, Price = 200 },
    -- ARMOR
    { id = {"Base.Hat_Beret"}, Price = 500 },
    { id = {"Base.Hat_BalaclavaFull"}, Price = 500 },
    { id = {"Base.Hat_Police"}, Price = 500 },
    { id = {"Base.Hat_Army"}, Price = 1000 },
    { id = {"Base.Hat_ArmyDesertNew"}, Price = 1000 },
    { id = {"Base.Hat_ArmyDesert"}, Price = 1000 },
    { id = {"Base.Hat_CrashHelmet_Police"}, Price = 1000 },
    { id = {"Base.Hat_RiotHelmet"}, Price = 1000 },
    { id = {"Base.Hat_ArmyWWII"}, Price = 1000 },
    { id = {"Base.Hat_SPHhelmet"}, Price = 1000 },
    { id = {"Base.ShinKneeGuard_L_Metal", "Base.ShinKneeGuard_R_Metal"}, Price = 1000 },
    { id = {"Base.Shoulderpad_Articulated_L_Metal", "Base.Shoulderpad_Articulated_R_Metal"}, Price = 1000 }, 
    { id = {"Base.Thigh_ArticMetal_R", "Base.Thigh_ArticMetal_L"}, Price = 1000 }, 
    { id = {"Base.ElbowPad_Right_Tactical"}, Price = 1000 },
    { id = {"Base.Vambrace_BodyArmour_Left_Army"}, Price = 1000 },
    { id = {"Base.GreaveBodyArmour_Right_Army"}, Price = 1000 },
    { id = {"Base.Shoes_ArmyBoots"}, Price = 1000 },
    { id = {"Base.Shoes_ArmyBootsDesert"}, Price = 1000 },
    { id = {"Base.Shoulderpad_MetalScrap_L", "Base.Shoulderpad_MetalScrap_R"}, Price = 1500 },
    { id = {"Base.Hat_GasMask_nofilter"}, Price = 1500 },
    { id = {"Base.Chainmail_SleeveFull_L", "Base.Chainmail_SleeveFull_R"}, Price = 2000 }, 
    { id = {"Base.Hat_GasMask"}, Price = 2000 },
    { id = {"Base.Vest_BulletArmy"}, Price = 5000 }, 
    { id = {"Base.Vest_BulletPolice"}, Price = 5000 }, 
    { id = {"Base.Vest_BulletSWAT"}, Price = 5000 },
    -- GOLD
    { id = {"Base.Medal_Bronze"}, Price = 100 },
    { id = {"Base.Medal_Gold"}, Price = 500 },
    { id = {"Base.Medal_Silver"}, Price = 250 },
    { id = {"Base.Necklace_Gold"}, Price = 600 },
    { id = {"Base.Necklace_GoldDiamond"}, Price = 800 },
    { id = {"Base.Necklace_GoldRuby"}, Price = 650 },
    { id = {"Base.Necklace_Silver"}, Price = 300 },
    { id = {"Base.Necklace_SilverCrucifix"}, Price = 250 },
    { id = {"Base.Necklace_SilverDiamond"}, Price = 150 },
    { id = {"Base.Necklace_SilverSapphire"}, Price = 200 },
    { id = {"Base.Necklace_YingYang"}, Price = 10 },
    { id = {"Base.NecklaceLong_Amber"}, Price = 50 },
    { id = {"Base.NecklaceLong_GoldDiamond"}, Price = 1000, },
    { id = {"Base.NecklaceLong_Gold"}, Price = 850, },
    { id = {"Base.NecklaceLong_SilverDiamond"}, Price = 450 },
    { id = {"Base.NecklaceLong_SilverEmerald"}, Price = 450 },
    { id = {"Base.NecklaceLong_SilverSapphire"}, Price = 450 },
    { id = {"Base.NecklaceLong_Silver"}, Price = 250 },
    { id = {"Base.NoseRing_Gold"}, Price = 100, },
    { id = {"Base.NoseRing_Silver"}, Price = 50 },
    { id = {"Base.NoseStud_Gold"}, Price = 80, },
    { id = {"Base.NoseStud_Silver"}, Price = 40 },
    { id = {"Base.Earring_Dangly_Diamond"}, Price = 100, },
    { id = {"Base.Earring_Dangly_Emerald"}, Price = 100, },
    { id = {"Base.Earring_Dangly_Pearl"}, Price = 100, },
    { id = {"Base.Earring_Dangly_Ruby"}, Price = 100, },
    { id = {"Base.Earring_Dangly_Sapphire"}, Price = 100, },
    { id = {"Base.Earring_Stone_Emerald"}, Price = 100, },
    { id = {"Base.Earring_Stud_Gold"}, Price = 250, },
    { id = {"Base.Earring_LoopLrg_Gold"}, Price = 250, },
    { id = {"Base.Earring_LoopLrg_Silver"}, Price = 80 },
    { id = {"Base.Earring_LoopMed_Gold"}, Price = 100, },
    { id = {"Base.Earring_LoopMed_Silver"}, Price = 80 },
    { id = {"Base.Earring_Pearl"}, Price = 60, },
    { id = {"Base.Earring_Stone_Ruby"}, Price = 60, },
    { id = {"Base.Earring_Stone_Sapphire"}, Price = 60, },
    { id = {"Base.Earring_Stud_Silver"}, Price = 50 },
    { id = {"Base.Earring_LoopSmall_Gold_Both", "Base.Earring_LoopSmall_Gold_Top"}, Price = 50, },
    { id = {"Base.Earring_LoopSmall_Silver_Both", "Base.Earring_LoopSmall_Silver_Top"}, Price = 50, },
    { id = {"Base.Bracelet_BangleRightGold", "Base.Bracelet_BangleLeftGold"}, Price = 300 },
    { id = {"Base.Bracelet_BangleRightSilver", "Base.Bracelet_BangleLeftSilver"}, Price = 250 },
    { id = {"Base.Bracelet_ChainRightGold", "Base.Bracelet_ChainLeftGold"}, Price = 250 },
    { id = {"Base.Bracelet_ChainRightSilver", "Base.Bracelet_ChainLeftSilver"}, Price = 150 },
    { id = {"Base.WristWatch_Right_ClassicGold", "Base.WristWatch_Left_ClassicGold"}, Price = 1500 },
    { id = {"WristWatch_Right_Expensive", "Base.WristWatch_Left_Expensive"}, Price = 1500 },
    { id = {"Base.Ring_Right_MiddleFinger_GoldDiamond", "Base.Ring_Left_MiddleFinger_GoldDiamond", "Base.Ring_Right_RingFinger_GoldDiamond", "Base.Ring_Left_RingFinger_GoldDiamond"}, Price = 500 },
    { id = {"Base.Ring_Right_MiddleFinger_GoldRuby", "Base.Ring_Left_MiddleFinger_GoldRuby", "Base.Ring_Right_RingFinger_GoldRuby", "Base.Ring_Left_RingFinger_GoldRuby"}, Price = 500 },
    { id = {"Base.Ring_Right_MiddleFinger_Gold", "Base.Ring_Left_MiddleFinger_Gold", "Base.Ring_Right_RingFinger_Gold","Base.Ring_Left_RingFinger_Gold"}, Price = 500 },
    { id = {"Base.Ring_Right_MiddleFinger_SilverDiamond", "Base.Ring_Left_MiddleFinger_SilverDiamond", "Base.Ring_Right_RingFinger_SilverDiamond", "Base.Ring_Left_RingFinger_SilverDiamond"}, Price = 300 },
    { id = {"Base.Ring_Right_MiddleFinger_Silver", "Base.Ring_Left_MiddleFinger_Silver", "Base.Ring_Right_RingFinger_Silver", "Base.Ring_Left_RingFinger_Silver"}, Price = 300 },
    { id = {"Base.BellyButton_DangleGoldRuby"}, Price = 150 },
    { id = {"Base.BellyButton_DangleGold"}, Price = 250 },
    { id = {"Base.BellyButton_DangleSilverDiamond"}, Price = 150 },
    { id = {"Base.BellyButton_DangleSilver"}, Price = 50 },
    { id = {"Base.BellyButton_RingGoldDiamond"}, Price = 150 },
    { id = {"Base.BellyButton_RingGoldRuby"}, Price = 150 },
    { id = {"Base.BellyButton_RingGold"}, Price = 250 },
    { id = {"Base.BellyButton_RingSilverAmethyst"}, Price = 75 },
    { id = {"Base.BellyButton_RingSilverDiamond"}, Price = 75 },
    { id = {"Base.BellyButton_RingSilverRuby"}, Price = 75 },
    { id = {"Base.BellyButton_RingSilver"}, Price = 50 },
    { id = {"Base.BellyButton_StudGoldDiamond"}, Price = 150 },
    { id = {"Base.BellyButton_StudGold"}, Price = 150 },
    { id = {"Base.BellyButton_StudSilverDiamond"}, Price = 75 },
    { id = {"Base.BellyButton_StudSilver"}, Price = 50 }
}

-- GEN WEB OFFERS
function GenerateDarkWebOffers()
    local getHourTime = math.ceil(getGameTime():getWorldAgeHours())

    if getHourTime < 24 then
        getHourTime = 24
    end

    if (getHourTime - LAST_CONNECTION_TIME) < 24 then
        return
    end
    
    currentOffers = {}
    LAST_CONNECTION_TIME = getHourTime
    local player = getSpecificPlayer(0)

    for i = 1, ITEMS_MAX do
        local randomItem = darkWebItems[ZombRand(#darkWebItems) + 1]
        if randomItem.id and #randomItem.id > 0 then

            local perkLevel = player:getPerkLevel(Perks.PlantScavenging)
            local buyMaxMultiplier = 3.0 - (2.0 * perkLevel / 10)
            local sellMinMultiplier = 0.5 + (0.025 * perkLevel)
            local sellMaxMultiplier = 0.75 + (0.025 * perkLevel)

            local getHourTime = math.ceil(getGameTime():getWorldAgeHours()/2190)
            local rawPrice = math.ceil((ZombRand(randomItem.Price, randomItem.Price * buyMaxMultiplier))/10) * 10 * getHourTime
            local transactionType = "Buy"
            local transactionQty = 1

            table.insert(currentOffers, {
                item = { id = randomItem.id },
                price = rawPrice,
                transactionType = transactionType,
                transactionQty = transactionQty
            })
        end
    end
end

-- CONSTRUCTOR
function darkWebUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.width = width
    o.height = height
    o.player = player
    o.filterMode = "all"
    o.searchTextLower = ""
    o.isClosing = false
    return o
end

-- INIT
function darkWebUI:initialise()
    ISPanel.initialise(self)

    self.topBar = ISPanel:new(0, 0, self.width, self.height)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.topBar.borderColor = {r=0, g=0, b=0, a=0}
    self.topBar:setVisible(true)
    self:addChild(self.topBar)

    self.topBar.parent = self

    function self.topBar:onMouseDown(x, y)
        self.parent.isDragging = true
        self.parent.initialX = self.parent:getX()
        self.parent.initialY = self.parent:getY()
        self.parent.mouseStartX = getMouseX()
        self.parent.mouseStartY = getMouseY()
    end

    function self.topBar:onMouseMove(x, y)
        if self.parent.isDragging then
            local curMouseX = getMouseX()
            local curMouseY = getMouseY()
            local dx = curMouseX - self.parent.mouseStartX
            local dy = curMouseY - self.parent.mouseStartY
            self.parent:setX(self.parent.initialX + dx)
            self.parent:setY(self.parent.initialY + dy)
        end
    end

    function self.topBar:onMouseUp(x, y)
        self.parent.isDragging = false
        local modData = getPlayer():getModData()
        modData.PZLinuxUIX = self.parent:getX()
        modData.PZLinuxUIY = self.parent:getY()
    end

    self.stopButton = ISButton:new(self.width * 0.0728, self.height * 0.923, self.width * 0.045, self.height * 0.027, "X", self, self.onCloseX)
    self.stopButton.backgroundColor = {r=0.5, g=0, b=0, a=0.5}
    self.stopButton.borderColor = {r=0, g=0, b=0, a=1}
    self.stopButton:setVisible(true)
    self.stopButton:initialise()
    self.stopButton:setAnchorRight(true)
    self.topBar:addChild(self.stopButton)

    self.titleLabel = ISLabel:new(self.width * 0.20, self.height * 0.17, self.height * 0.025, "Bank balance: $"  .. tostring(loadAtmBalance()), 0, 1, 0, 1, UIFont.Small, true)
    self.topBar.backgroundColor = {r=0, g=0, b=0, a=0}
    self.titleLabel:setVisible(false)
    self.titleLabel:initialise()
    self.topBar:addChild(self.titleLabel)

    local modData = getPlayer():getModData()
    if modData.PZLinuxUISFX == 0 then
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    else
        self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
        self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
        self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
        self.skipAnimationButton:setVisible(true)
        self.skipAnimationButton:initialise()
        self.topBar:addChild(self.skipAnimationButton)
    end

    self.minimizeButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimize)
    self.minimizeButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeButton:setVisible(true)
    self.minimizeButton:initialise()
    self.topBar:addChild(self.minimizeButton)

    self.minimizeBackButton = ISButton:new(self.width * 0.70, self.height * 0.17, self.width * 0.030, self.height * 0.025, "-", self, self.onMinimizeBack)
    self.minimizeBackButton.textColor = {r=0, g=1, b=0, a=1}
    self.minimizeBackButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.minimizeBackButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.minimizeBackButton:setVisible(false)
    self.minimizeBackButton:initialise()
    self.topBar:addChild(self.minimizeBackButton)

    self.closeButton = ISButton:new(self.width * 0.73, self.height * 0.17, self.width * 0.030, self.height * 0.025, "x", self, self.onClose)
    self.closeButton.textColor = {r=0, g=1, b=0, a=1}
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.closeButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.closeButton:setVisible(true)
    self.closeButton:initialise()
    self.topBar:addChild(self.closeButton)

    self.filterAllBtn = ISButton:new(self.width * 0.20, self.height * 0.20, self.width * 0.08, self.height * 0.025, "All", self, self.OnFilter)
    self.filterAllBtn.internal = "all"
    self.filterAllBtn:setVisible(false)
    self.filterAllBtn:initialise()
    self:addChild(self.filterAllBtn)

    self.searchBtn = ISButton:new(self.width * 0.28, self.height * 0.20, self.width * 0.08, self.height * 0.025, "Search", self, self.OnSearch)
    self.searchBtn.internal = "search"
    self.searchBtn:setVisible(false)
    self.searchBtn:initialise()
    self:addChild(self.searchBtn)

    self.shoppingBuyButton = ISButton:new(self.width * 0.35, self.width * 0.32, self.width * 0.25, self.height * 0.08, "BUY", self, self.onBuy)
    self.shoppingBuyButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingBuyButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingBuyButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingBuyButton:setVisible(true)
    self.shoppingBuyButton:initialise()
    self.topBar:addChild(self.shoppingBuyButton)

    self.shoppingSellButton = ISButton:new(self.width * 0.35, self.width * 0.43, self.width * 0.25, self.height * 0.08, "SELL", self, self.onSell)
    self.shoppingSellButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingSellButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingSellButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingSellButton:setVisible(true)
    self.shoppingSellButton:initialise()
    self.topBar:addChild(self.shoppingSellButton)

    self.shoppingHelpButton = ISButton:new(self.width * 0.35, self.width * 0.54, self.width * 0.25, self.height * 0.08, "HELP", self, self.onHelp)
    self.shoppingHelpButton.textColor = {r=0, g=1, b=0, a=1}
    self.shoppingHelpButton.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.shoppingHelpButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.shoppingHelpButton:setVisible(true)
    self.shoppingHelpButton:initialise()
    self.topBar:addChild(self.shoppingHelpButton)

    self.searchField = ISTextEntryBox:new("", self.width * 0.363, self.height * 0.199, self.width * 0.399, self.height * 0.025)
    self.searchField.onCommandEntered = function(entry) self:onCommandEnter() end
    self.searchField:setVisible(false)
    self.searchField:initialise()
    self:addChild(self.searchField)

    self.scrollPanel = ISPanel:new(self.width * 0.193, self.height * 0.228, self.width * 0.568, self.height * 0.48)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    self.offerBackgrounds = {}
    self.offerIcons = {}
    self.offerLabels = {}
    self.offerPriceLabels = {}
    self.transactionBtns = {}
    self.transactionQtys = {}

    local rowHeight = self.height * 0.045
    local totalHeight = 100 * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    for i = 1, ITEMS_MAX do
        local yOffset = 5 + (i - 1) * rowHeight
        local offerBackground = ISPanel:new(5, yOffset, self.scrollPanel.width - 23, rowHeight)
        offerBackground.backgroundColor = {r=0, g=0, b=0, a=0}
        offerBackground.borderColor     = {r=0, g=0, b=0, a=0}
        offerBackground:initialise()
        self.scrollPanel:addChild(offerBackground)
        self.offerBackgrounds[i] = offerBackground

        local iconSize = 28
        local iconY    = (rowHeight - iconSize) / 2
        local iconImg  = ISImage:new(5, iconY, iconSize, iconSize, nil)
        iconImg:initialise()
        offerBackground:addChild(iconImg)
        self.offerIcons[i] = iconImg

        local labelNameX = 5 + iconSize + 5
        local labelNameY = (rowHeight - 16) / 2
        local nameLabel  = ISLabel:new(labelNameX, labelNameY, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        nameLabel:initialise()
        offerBackground:addChild(nameLabel)
        self.offerLabels[i] = nameLabel

        local labelPriceX = self.width * 0.355
        local priceLabel = ISLabel:new(labelPriceX, labelNameY, 20, "", 0, 1, 0, 1, UIFont.Small, true)
        priceLabel:initialise()
        offerBackground:addChild(priceLabel)
        self.offerPriceLabels[i] = priceLabel
        
        local buttonWidth, buttonHeight = self.width * 0.08, self.height * 0.025
        local transactionQty = ISTextEntryBox:new("0", self.width * 0.415, (rowHeight - buttonHeight - 2) / 2, self.width * 0.03, self.height * 0.024)
        transactionQty.backgroundColor = {r=0, g=0, b=0, a=1}
        transactionQty.internal = i
        transactionQty:setVisible(true)
        transactionQty:initialise()
        transactionQty:setOnlyNumbers(true)
        offerBackground:addChild(transactionQty)
        self.transactionQtys[i] = transactionQty
       
        local transactionBtn = ISButton:new(offerBackground.width - buttonWidth - 10, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight, "", self, function(self, btn)
            local quantityTrading = tonumber(transactionQty:getText()) or 0
            self:OnBuyItem(btn, quantityTrading)
        end)
        transactionBtn.internal = i
        transactionBtn:setVisible(false)
        transactionBtn:initialise()
        offerBackground:addChild(transactionBtn)
        self.transactionBtns[i] = transactionBtn


        function offerBackground:onMouseMove(dx, dy)
            self.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0.3}
        end
        function offerBackground:onMouseMoveOutside(dx, dy)
            self.backgroundColor = {r=0, g=0, b=0, a=0}
        end
    end
end

-- STOP
function darkWebUI:onStop(button)
    self.isClosing = true

    Events.OnKeyStartPressed.Remove(self.onKeyEvent)
    Events.OnKeyPressed.Remove(self.onKeyEvent)
    Events.OnKeyKeepPressed.Remove(self.onKeyEvent)

    if self.updateCoroutineFunc then
        Events.OnTick.Remove(self.updateCoroutineFunc)
        self.updateCoroutineFunc = nil
    end

    if self.loadingMessage then
        self.scrollPanel:removeChild(self.loadingMessage)
        self.loadingMessage = nil
    end

    if self.centeredImage then
        self.centeredImage:removeFromUIManager()
        self.centeredImage = nil
    end
    
    self:removeFromUIManager()
    self.terminalCoroutine = nil
end

-- LOGOUT
function darkWebUI:onMinimize(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function darkWebUI:onMinimizeBack(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 3
end


-- LOGOUT
function darkWebUI:onClose(button)
    self.isClosing = true
    self:removeFromUIManager()
    local modData = getPlayer():getModData()
    modData.PZLinuxUIOpenMenu = 1
end

function darkWebUI:onCloseX(button)
    self.isClosing = true
    getPlayer():StopAllActionQueue()
end

function darkWebUI:onSFXOn(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxUISFX = 0
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOff)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=1, g=0, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

function darkWebUI:onSFXOff(button)
    local modData = getPlayer():getModData()
    modData.PZLinuxUISFX = 1
    self.skipAnimationButton:close()
    self.skipAnimationButton = ISButton:new(self.width * 0.66, self.height * 0.17, self.width * 0.030, self.height * 0.025, "SFX", self, self.onSFXOn)
    self.skipAnimationButton.textColor = {r=1, g=1, b=1, a=1}
    self.skipAnimationButton.backgroundColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton.borderColor = {r=0, g=1, b=0, a=0.5}
    self.skipAnimationButton:setVisible(true)
    self.skipAnimationButton:initialise()
    self.topBar:addChild(self.skipAnimationButton)
end

-- UPDATE UI
function darkWebUI:startUI()
    self.titleLabel:setVisible(true)
    self.minimizeButton:setVisible(true)
    self.closeButton:setVisible(true)
    self.filterAllBtn:setVisible(false)
    self.searchField:setVisible(false)
    self.searchBtn:setVisible(false)
    self.scrollPanel:setVisible(false)
    self.scrollPanel:addScrollBars(false)
end

function darkWebUI:onBuy()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.titleLabel:setVisible(true)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)
    self.closeButton:setVisible(true)
    self.filterAllBtn:setVisible(true)
    self.searchField:setVisible(true)
    self.searchBtn:setVisible(true)
    self.scrollPanel:setVisible(true)
    self.scrollPanel:addScrollBars(true)

    local lineIndex = 1
    for i, rowData in ipairs(currentOffers) do
        if self:FilterMatch(rowData) then
            local firstId
            if type(rowData.item.id) == "table" then
                firstId = rowData.item.id[1]
            else
                firstId = rowData.item.id
            end
            local scriptItem = getScriptManager():FindItem(firstId)
            local isValid = scriptItem and scriptItem:getDisplayName() and scriptItem:getDisplayName():match("%S")

            if isValid then
                if lineIndex <= ITEMS_MAX then
                    local iconName = scriptItem:getIcon()
                    local iconTex  = getTexture(iconName) or getTexture("Item_" .. iconName)

                    if iconTex and self.offerIcons[lineIndex] then
                        self.offerIcons[lineIndex].texture = iconTex
                        self.offerIcons[lineIndex]:setVisible(true)
                    elseif self.offerIcons[lineIndex] then
                        self.offerIcons[lineIndex].texture = nil
                        self.offerIcons[lineIndex]:setVisible(false)
                    end

                    if self.offerLabels[lineIndex] then
                        local displayName = scriptItem:getDisplayName()
                        if #displayName > 37 then
                            displayName = displayName:sub(1, 35) .. "..."
                        end
                        self.offerLabels[lineIndex]:setName(displayName)
                    end

                    if self.offerPriceLabels[lineIndex] then
                        self.offerPriceLabels[lineIndex]:setName("$" .. tostring(rowData.price))
                    end

                    if self.transactionBtns[lineIndex] then
                        self.transactionBtns[lineIndex].internal = i
                        if rowData.transactionType == "Buy" then
                            self.transactionBtns[lineIndex]:setTitle("Buy")
                            self.transactionBtns[lineIndex].backgroundColor = {r=0, g=0.6, b=0, a=1}
                        end
                        self.transactionBtns[lineIndex]:setVisible(true)
                    end

                    lineIndex = lineIndex + 1
                end
            end
        end
    end

    for j = lineIndex, ITEMS_MAX do
        if self.offerIcons[j] then
            self.offerIcons[j]:setVisible(false)
        end
        if self.offerLabels[j] then
            self.offerLabels[j]:setName("")
        end
        if self.offerPriceLabels[j] then
            self.offerPriceLabels[j]:setName("")
        end
        if self.transactionBtns[j] then
            self.transactionBtns[j]:setVisible(false)
        end
        if self.transactionQtys[j] then
            self.transactionQtys[j]:setVisible(false)
        end
    end

    if self.loadingMessage then
        self.scrollPanel:removeChild(self.loadingMessage)
        self.loadingMessage = nil
    end
end

function darkWebUI:onSell()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)

    local yOffset = 30
    local itemsToSell = {}
    local itemCount = 0

    local playerObj = getPlayer()
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)

    for _, itemData in ipairs(darkWebItems) do
        local itemIds = itemData.id
        local itemPrice = itemData.Price
        local firstItemId = type(itemIds) == "table" and itemIds[1] or itemIds
        
        itemCount = 0
        for i = 1, containers:size() do
            local container = containers:get(i - 1)
            local items = container:getItems()
        
            if type(itemIds) == "table" then
                for _, id in ipairs(itemIds) do
                    for j = 0, items:size() - 1 do
                        local item = items:get(j)
                        if item:getFullType() == id then
                            itemCount = itemCount + 1
                        end
                    end
                end
            else
                local foundItem = container:FindAndReturn(itemIds)
                if foundItem then
                    itemCount = container:getItemCount(itemIds)
                end
            end
        end

        if itemCount > 0 then
            local scriptItem = getScriptManager():FindItem(firstItemId)
            local itemName = scriptItem and scriptItem:getDisplayName() or "Unknown Item"
            local iconName = scriptItem and scriptItem:getIcon()
            local iconTex = iconName and (getTexture(iconName) or getTexture("Item_" .. iconName)) or nil

            local player = getPlayer()
            local perkLevel = player:getPerkLevel(Perks.PlantScavenging)
            local sellMinMultiplier = 0.5 + (0.025 * perkLevel)
            local sellMaxMultiplier = 0.75 + (0.025 * perkLevel)
            local rawPrice = math.ceil(ZombRand(itemPrice * sellMinMultiplier, itemPrice * sellMaxMultiplier))

            table.insert(itemsToSell, { 
                id = itemIds, 
                name = itemName, 
                count = itemCount, 
                price = rawPrice, 
                icon = iconTex 
            })
        end
    end

    self.scrollPanel = ISPanel:new(self.width * 0.193, self.height * 0.228, self.width * 0.568, self.height * 0.48)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    self.offerBackgrounds = {}
    self.offerIcons = {}
    self.offerLabels = {}
    self.offerPriceLabels = {}
    self.transactionBtns = {}
    self.transactionQtysSell = {}

    local rowHeight = self.height * 0.045
    local totalHeight = 100 * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    local yOffset = 0
    for _, item in ipairs(itemsToSell) do
        if item.icon then
            local itemIcon = ISImage:new(self.width * 0.01, yOffset, 20, 20, item.icon)
            self.scrollPanel:addChild(itemIcon)
        end

        local iconSize = 28
        local itemSellLabel = ISLabel:new(self.width * 0.059, yOffset, 20, item.name, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(itemSellLabel)

        local priceLabel = ISLabel:new(self.width * 0.41, yOffset, 20, " $" .. item.price, 0, 1, 0, 1, UIFont.Small, true)
        self.scrollPanel:addChild(priceLabel)

        local buttonWidth, buttonHeight = self.width * 0.08, self.height * 0.025
        local sellButton = ISButton:new(self.width * 0.48, yOffset, buttonWidth, buttonHeight, "SELL", self, self.onSellItem)
        sellButton.backgroundColor = {r=0.6, g=0, b=0, a=1}
        sellButton.internal = item.id
        sellButton.price = item.price
        sellButton.count = item.count
        self.scrollPanel:addChild(sellButton)

        yOffset = yOffset + 30
    end
end

-- FILTER
function darkWebUI:OnFilter(button)
    if button.internal == "all" then
        self.filterMode = "all"
    end
    self.searchField:setText("")
    self.searchTextLower = ""
    self:onBuy()
end

function darkWebUI:FilterMatch(rowData)
    if self.filterMode == "all" then
        return true
    elseif self.filterMode == "search" then    
        if type(rowData.item.id) == "table" then
            firstId = rowData.item.id[1]
        else
            firstId = rowData.item.id
        end    
        local scriptItem = getScriptManager():FindItem(firstId)
        if not scriptItem then
            return false
        end
        
        local itemName = scriptItem:getDisplayName()
        if type(itemName) ~= "string" then
            return false
        end
        local itemNameLower = string.lower(itemName)
        return string.find(itemNameLower, self.searchTextLower, 1, true) ~= nil
    end
    return true
end

-- SEARCH
function darkWebUI:onCommandEnter()
    self:OnSearch()
end

function darkWebUI:OnSearch()
    local searchText = self.searchField:getText()
    if self.noResultsWindow then
        self.noResultsWindow:setVisible(false)
    end
    if self.emptySearchWindow then
        self.emptySearchWindow:setVisible(false)
    end
    if not searchText then
        searchText = ""
    end
    if searchText ~= "" then
        self.searchTextLower = string.lower(searchText)
        self.filterMode = "search"
        self:onBuy()
    else
        self.filterMode = "all"
        self.searchTextLower = ""
        self:onBuy()
    end
end

-- CLICK BUY SELL
function darkWebUI:OnBuyItem(button, quantityTrading)
    local globalVolume = getCore():getOptionSoundVolume() / 10
    if self.isClosing then
        return
    end

    local playerObj = getPlayer()
    local offer = currentOffers[button.internal]
    if not offer then return end
    local transactionType = offer.transactionType
    local transactionQty = tonumber(quantityTrading)
    local inv = playerObj:getInventory()

    for i = 1, transactionQty do
        local checkBalance = tonumber(loadAtmBalance())
        if i > 1 then globalVolume = 0 end
        if checkBalance >= offer.price then
            local itemToAdd = nil
            if type(offer.item.id) == "table" then
                itemToAdd = offer.item.id[1]
            else
                itemToAdd = offer.item.id
            end
            inv:AddItem(itemToAdd)
            getSoundManager():PlayWorldSound("buy", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)

            local newBalance = checkBalance - offer.price
            saveAtmBalance(newBalance)
            self.titleLabel:setName("Bank balance: $"  .. tostring(loadAtmBalance()))
        else
            getSoundManager():PlayWorldSound("error", false, getSpecificPlayer(0):getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        end
    end
end

local function removeItemOnTick()
    local playerObj = getPlayer()
    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    for k = items:size() - 1, 0, -1 do
        local checkItem = items:get(k)
        if checkItem:getName() == getItemName then
            inventory:Remove(checkItem)
            Events.OnTick.Remove(removeItemOnTick)
            break
        end
    end
end

function darkWebUI:onSellItem(button)
    local globalVolume = getCore():getOptionSoundVolume() / 10
    local itemIds = button.internal
    local price = button.price
    local count = button.count
    local playerObj = getPlayer()
    local inv = playerObj:getInventory()
    local itemsToSell = {}

    local items = inv:getItems()
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if type(itemIds) == "table" then
            for _, id in ipairs(itemIds) do
                if item:getFullType() == id then
                    table.insert(itemsToSell, item)
                end
            end
        else
            if item:getFullType() == itemIds then
                table.insert(itemsToSell, item)
            end
        end
    end

    for _, item in ipairs(itemsToSell) do
        getItemName = item:getName()
        itemToSell = inv:FindAndReturn(item:getFullType())
        if itemToSell then
            inv:Remove(itemToSell)
        end
    end

    if #itemsToSell > 0 then
        getSoundManager():PlayWorldSound("sold", false, playerObj:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
        local newBalance = price * count
        local parcel = inv:AddItem('Base.SuspiciousPackage')
        parcel:setName("$" .. tostring(newBalance))
    else
        getSoundManager():PlayWorldSound("error", false, playerObj:getSquare(), 0, 50, 1, true):setVolume(globalVolume)
    end
end

function darkWebUI:onHelp()
    self.shoppingBuyButton:setVisible(false)
    self.shoppingSellButton:setVisible(false)
    self.shoppingHelpButton:setVisible(false)
    self.minimizeButton:setVisible(false)
    self.minimizeBackButton:setVisible(true)

    local yOffset = 30

    local helpMessageTitle = "To sell an item, it must be in the main inventory. Once in the inventory,\nclicking 'Sell' will sell all items of that type and a suspicious package\nwill appear in your inventory. To complete the sale, you need to send\nthe item via a mailbox\n\nHere is the list of items that can be bought and sold:"
    local helpMessage = ISLabel:new(self.width * 0.2, self.height * 0.25, 20, helpMessageTitle, 0, 1, 0, 1, UIFont.Small, true)
    self:addChild(helpMessage)
    yOffset = yOffset + 30

    self.scrollPanel = ISPanel:new(self.width * 0.2, self.height * 0.34, self.width * 0.568, self.height * 0.35)
    self.scrollPanel:initialise()
    self.scrollPanel:instantiate()
    function self.scrollPanel:prerender()
        ISPanel.prerender(self)
        self:setStencilRect(0, 0, self.width, self.height)
    end
    function self.scrollPanel:postrender()
        self:clearStencilRect()
        ISPanel.postrender(self)
    end

    self.scrollPanel:setScrollChildren(true)
    self.scrollPanel.backgroundColor = {r=0.02, g=0.15, b=0.02, a=0}
    self.scrollPanel.borderColor     = {r=0, g=0.5, b=0, a=0}
    self:addChild(self.scrollPanel)

    local rowHeight = self.height * 0.045
    local totalHeight = #darkWebItems * rowHeight + 10
    self.scrollPanel:setScrollHeight(totalHeight)
    self.scrollPanel.onMouseWheel = function(self, del)
        if self:getScrollHeight() > 0 then
            self:setYScroll(self:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    local yOffset = 0
    for _, itemData in ipairs(darkWebItems) do
        local itemIds = itemData.id
        local itemPrice = itemData.Price
        local firstItemId = type(itemIds) == "table" and itemIds[1] or itemIds

        local scriptItem = getScriptManager():FindItem(firstItemId)
        local itemName = scriptItem and scriptItem:getDisplayName() or "Unknown Item"
        local iconName = scriptItem and scriptItem:getIcon()
        local iconTex = iconName and (getTexture(iconName) or getTexture("Item_" .. iconName)) or nil

        if iconTex and itemName ~= "Unknown Item" then
            local itemIcon = ISImage:new(self.width * 0.01, yOffset, 20, 20, iconTex)
            self.scrollPanel:addChild(itemIcon)

            local itemLabel = ISLabel:new(self.width * 0.059, yOffset, 20, itemName, 0, 1, 0, 1, UIFont.Small, true)
            self.scrollPanel:addChild(itemLabel)
            yOffset = yOffset + 30
        end

    end
end

-- UI
function darkWebMenu_ShowUI(player)
    GenerateDarkWebOffers()
    local texture = getTexture("media/ui/oldCRT.png")
    if not texture then return end

    local realScreenW = getCore():getScreenWidth()
    local realScreenH = getCore():getScreenHeight()

    local maxW = realScreenW * 0.70
    local maxH = realScreenH * 0.70
    local texW = texture:getWidth()
    local texH = texture:getHeight()

    local ratioX, ratioY = maxW / texW, maxH / texH
    local scale  = math.min(ratioX, ratioY)
    local finalW, finalH = math.floor(texW * scale), math.floor(texH * scale)
    
    local modData = getPlayer():getModData()
    local uiX = modData.PZLinuxUIX or (realScreenW - finalW) / 2
    local uiY = modData.PZLinuxUIY or (realScreenH - finalH) / 2

    local ui = darkWebUI:new(uiX, uiY, finalW, finalH, player)
    local centeredImage = ISImage:new(0, 0, finalW, finalH, texture)

    centeredImage.scaled = true
    centeredImage.scaledWidth = finalW
    centeredImage.scaledHeight = finalH

    ui:addChild(centeredImage)
    ui.centeredImage = centeredImage
    ui:initialise()
    ui:addToUIManager()
    ui:startUI()
    
    return ui 
end