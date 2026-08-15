PZLinuxContractTargetNames = PZLinuxContractTargetNames or {
    { first = "Jame", last = "Smith" },
    { first = "Mary", last = "Johnson" },
    { first = "Robert", last = "Williams" },
    { first = "Patricia", last = "Brown" },
    { first = "John", last = "Jones" },
    { first = "Jennifer", last = "Garcia" },
    { first = "Michael", last = "Miller" },
    { first = "Linda", last = "Davis" },
    { first = "William", last = "Rodriguez" },
    { first = "Elizabeth", last = "Martinez" },
    { first = "David", last = "Hernandez" },
    { first = "Barbara", last = "Lopez" },
    { first = "Richard", last = "Gonzalez" },
    { first = "Susan", last = "Wilson" },
    { first = "Joseph", last = "Anderson" },
    { first = "Jessica", last = "Thomas" },
    { first = "Thomas", last = "Taylor" },
    { first = "Sarah", last = "Moore" },
    { first = "Charles", last = "Jackson" },
    { first = "Karen", last = "Martin" },
    { first = "Christopher", last = "Lee" },
    { first = "Nancy", last = "Perez" },
    { first = "Daniel", last = "Thompson" },
    { first = "Betty", last = "White" },
    { first = "Matthew", last = "Harris" },
    { first = "Sandra", last = "Sanchez" },
    { first = "Anthony", last = "Clark" },
    { first = "Ashley", last = "Ramirez" },
    { first = "Mark", last = "Lewis" },
    { first = "Donna", last = "Robinson" },
    { first = "Paul", last = "Walker" },
    { first = "Emily", last = "Young" },
    { first = "Steven", last = "Allen" },
    { first = "Stephanie", last = "King" },
    { first = "Andrew", last = "Wright" },
    { first = "Melissa", last = "Scott" },
    { first = "Kenneth", last = "Torres" },
    { first = "Amy", last = "Nguyen" },
    { first = "Joshua", last = "Hill" },
    { first = "Angela", last = "Flores" },
    { first = "Kevin", last = "Green" },
    { first = "Sharon", last = "Adams" },
    { first = "Brian", last = "Nelson" },
    { first = "Laura", last = "Baker" },
    { first = "George", last = "Hall" },
    { first = "Kimberly", last = "Rivera" },
    { first = "Edward", last = "Campbell" },
    { first = "Deborah", last = "Mitchell" },
    { first = "Jason", last = "Carter" },
    { first = "Michelle", last = "Roberts" },
    { first = "Jeffrey", last = "Gomez" },
    { first = "Emily", last = "Phillips" },
    { first = "Ryan", last = "Evans" },
    { first = "Carol", last = "Turner" },
    { first = "Jacob", last = "Diaz" },
    { first = "Rebecca", last = "Parker" },
    { first = "Gary", last = "Edwards" },
    { first = "Cynthia", last = "Collins" },
    { first = "Nicholas", last = "Stewart" },
    { first = "Kathleen", last = "Morris" },
    { first = "Eric", last = "Rogers" },
    { first = "Shirley", last = "Reed" },
    { first = "Stephen", last = "Cook" },
    { first = "Anna", last = "Morgan" },
    { first = "Jonathan", last = "Bell" },
    { first = "Brenda", last = "Murphy" },
    { first = "Larry", last = "Bailey" },
    { first = "Emma", last = "Rivera" },
    { first = "Justin", last = "Cooper" },
    { first = "Pamela", last = "Richardson" },
    { first = "Scott", last = "Cox" },
    { first = "Nicole", last = "Howard" },
    { first = "Brandon", last = "Ward" },
    { first = "Megan", last = "Torres" },
    { first = "Benjamin", last = "Peterson" },
    { first = "Julie", last = "Gray" },
    { first = "Samuel", last = "Ramirez" },
    { first = "Hannah", last = "James" },
    { first = "Gregory", last = "Watson" },
    { first = "Victoria", last = "Brooks" },
    { first = "Frank", last = "Kelly" },
    { first = "Olivia", last = "Sanders" },
    { first = "Alexander", last = "Price" },
    { first = "Christina", last = "Bennett" },
    { first = "Raymond", last = "Wood" },
    { first = "Diane", last = "Barnes" },
    { first = "Patrick", last = "Ross" },
    { first = "Evelyn", last = "Henderson" },
    { first = "Jack", last = "Coleman" },
    { first = "Rachel", last = "Jenkins" },
    { first = "Dennis", last = "Perry" },
    { first = "Grace", last = "Powell" },
    { first = "Jerry", last = "Long" },
    { first = "Lauren", last = "Patterson" },
    { first = "Tyler", last = "Hughes" },
    { first = "Alice", last = "Flores" },
    { first = "Aaron", last = "Washington" },
    { first = "Jacqueline", last = "Butler" },
    { first = "Jose", last = "Simmons" },
    { first = "Katherine", last = "Foster" },
}

function PZLinuxContractsRandomTargetName()
    local firstName = PZLinuxContractTargetNames[ZombRand(1, #PZLinuxContractTargetNames + 1)]
    local lastName = PZLinuxContractTargetNames[ZombRand(1, #PZLinuxContractTargetNames + 1)]
    return firstName.first .. " " .. lastName.last
end

-- Every "name" here used to be a plain hardcoded English string, both
-- displayed as-is regardless of the player's language AND (for the Auto
-- Parts pool specifically) the only thing that could tell apart the three
-- quality tiers of a given part: PZ's own vanilla item name is IDENTICAL
-- across all of e.g. Base.NormalSuspension1/2/3 ("Suspension - Regular"
-- for all three -- see media/lua/shared/Translate/EN/ItemName.json), so a
-- player told to bring "a Suspension" with no further detail had no way to
-- know which of the three they actually needed. Now a translation key
-- (resolved via PZLinuxGetText, English fallback in PZLinux.TextFallbacks)
-- instead, so this text is both disambiguating AND properly localized.
-- Weapon/medical vanilla names are already unique per item (no ambiguity
-- issue there), but are translated here too for consistency/completeness,
-- since PZLinuxContractsMissionNote always uses this name directly in the
-- physical note text regardless of contract type.
PZLinuxContractAutoPartRequests = PZLinuxContractAutoPartRequests or {
    { baseName = "Base.CarBattery3", nameKey = "IGUI_PZLinux_ContractPart_CarBattery3", delta = 1 },
    { baseName = "Base.CarBattery2", nameKey = "IGUI_PZLinux_ContractPart_CarBattery2", delta = 0.9 },
    { baseName = "Base.CarBattery1", nameKey = "IGUI_PZLinux_ContractPart_CarBattery1", delta = 0.8 },
    { baseName = "Base.ModernBrake3", nameKey = "IGUI_PZLinux_ContractPart_ModernBrake3", delta = 1 },
    { baseName = "Base.ModernBrake2", nameKey = "IGUI_PZLinux_ContractPart_ModernBrake2", delta = 0.9 },
    { baseName = "Base.ModernBrake1", nameKey = "IGUI_PZLinux_ContractPart_ModernBrake1", delta = 0.8 },
    { baseName = "Base.ModernCarMuffler3", nameKey = "IGUI_PZLinux_ContractPart_ModernCarMuffler3", delta = 1 },
    { baseName = "Base.ModernCarMuffler2", nameKey = "IGUI_PZLinux_ContractPart_ModernCarMuffler2", delta = 0.9 },
    { baseName = "Base.ModernCarMuffler1", nameKey = "IGUI_PZLinux_ContractPart_ModernCarMuffler1", delta = 0.8 },
    { baseName = "Base.ModernSuspension3", nameKey = "IGUI_PZLinux_ContractPart_ModernSuspension3", delta = 1 },
    { baseName = "Base.ModernSuspension2", nameKey = "IGUI_PZLinux_ContractPart_ModernSuspension2", delta = 0.9 },
    { baseName = "Base.ModernSuspension1", nameKey = "IGUI_PZLinux_ContractPart_ModernSuspension1", delta = 0.8 },
    { baseName = "Base.NormalBrake3", nameKey = "IGUI_PZLinux_ContractPart_NormalBrake3", delta = 0.7 },
    { baseName = "Base.NormalBrake2", nameKey = "IGUI_PZLinux_ContractPart_NormalBrake2", delta = 0.6 },
    { baseName = "Base.NormalBrake1", nameKey = "IGUI_PZLinux_ContractPart_NormalBrake1", delta = 0.5 },
    { baseName = "Base.NormalCarMuffler3", nameKey = "IGUI_PZLinux_ContractPart_NormalCarMuffler3", delta = 0.7 },
    { baseName = "Base.NormalCarMuffler2", nameKey = "IGUI_PZLinux_ContractPart_NormalCarMuffler2", delta = 0.6 },
    { baseName = "Base.NormalCarMuffler1", nameKey = "IGUI_PZLinux_ContractPart_NormalCarMuffler1", delta = 0.5 },
    { baseName = "Base.NormalSuspension3", nameKey = "IGUI_PZLinux_ContractPart_NormalSuspension3", delta = 0.7 },
    { baseName = "Base.NormalSuspension2", nameKey = "IGUI_PZLinux_ContractPart_NormalSuspension2", delta = 0.6 },
    { baseName = "Base.NormalSuspension1", nameKey = "IGUI_PZLinux_ContractPart_NormalSuspension1", delta = 0.5 },
}

function PZLinuxContractsRandomAutoPartRequest()
    return PZLinuxContractAutoPartRequests[ZombRand(1, #PZLinuxContractAutoPartRequests + 1)]
end

PZLinuxContractMedicalRequests = PZLinuxContractMedicalRequests or {
    { baseName = "Base.Bandaid", nameKey = "IGUI_PZLinux_ContractPart_Bandaid", delta = 0.5 },
    { baseName = "Base.Bandage", nameKey = "IGUI_PZLinux_ContractPart_Bandage", delta = 0.6 },
    { baseName = "Base.AlcoholWipes", nameKey = "IGUI_PZLinux_ContractPart_AlcoholWipes", delta = 0.8 },
    { baseName = "Base.Disinfectant", nameKey = "IGUI_PZLinux_ContractPart_Disinfectant", delta = 1.2 },
    { baseName = "Base.AlcoholedCottonBalls", nameKey = "IGUI_PZLinux_ContractPart_AlcoholedCottonBalls", delta = 0.7 },
    { baseName = "Base.Antibiotics", nameKey = "IGUI_PZLinux_ContractPart_Antibiotics", delta = 1.5 },
    { baseName = "Base.PillsAntiDep", nameKey = "IGUI_PZLinux_ContractPart_PillsAntiDep", delta = 1.1 },
    { baseName = "Base.PillsBeta", nameKey = "IGUI_PZLinux_ContractPart_PillsBeta", delta = 1 },
    { baseName = "Base.Pills", nameKey = "IGUI_PZLinux_ContractPart_Pills", delta = 1.3 },
    { baseName = "Base.PillsSleepingTablets", nameKey = "IGUI_PZLinux_ContractPart_PillsSleepingTablets", delta = 0.8 },
    { baseName = "Base.PillsVitamins", nameKey = "IGUI_PZLinux_ContractPart_PillsVitamins", delta = 0.7 },
}

function PZLinuxContractsRandomMedicalRequest()
    return PZLinuxContractMedicalRequests[ZombRand(1, #PZLinuxContractMedicalRequests + 1)]
end

-- The Pistol3/Revolver_Short/Revolver name fields used to say "D-E Pistol"
-- / "M36 Revolver" / "M625 Revolver" -- stale B41-era in-mod nicknames that
-- no longer match these items' own current B42 vanilla names ("B-F
-- Pistol" / "SN38 Revolver" / "Patrol Revolver"). Updated to match, so the
-- note doesn't send a player looking for a name the game itself no longer
-- uses anywhere.
PZLinuxContractWeaponRequests = PZLinuxContractWeaponRequests or {
    { baseName = "Base.Pistol3", nameKey = "IGUI_PZLinux_ContractPart_Pistol3", delta = 0.3 },
    { baseName = "Base.Pistol2", nameKey = "IGUI_PZLinux_ContractPart_Pistol2", delta = 0.3 },
    { baseName = "Base.Revolver_Short", nameKey = "IGUI_PZLinux_ContractPart_RevolverShort", delta = 0.5 },
    { baseName = "Base.Revolver", nameKey = "IGUI_PZLinux_ContractPart_Revolver", delta = 0.4 },
    { baseName = "Base.Pistol", nameKey = "IGUI_PZLinux_ContractPart_Pistol", delta = 0.3 },
    { baseName = "Base.Revolver_Long", nameKey = "IGUI_PZLinux_ContractPart_RevolverLong", delta = 0.5 },
    { baseName = "Base.DoubleBarrelShotgun", nameKey = "IGUI_PZLinux_ContractPart_DoubleBarrelShotgun", delta = 1.2 },
    { baseName = "Base.Shotgun", nameKey = "IGUI_PZLinux_ContractPart_Shotgun", delta = 1.2 },
    { baseName = "Base.DoubleBarrelShotgunSawnoff", nameKey = "IGUI_PZLinux_ContractPart_DoubleBarrelShotgunSawnoff", delta = 1.2 },
    { baseName = "Base.ShotgunSawnoff", nameKey = "IGUI_PZLinux_ContractPart_ShotgunSawnoff", delta = 1.2 },
    { baseName = "Base.AssaultRifle2", nameKey = "IGUI_PZLinux_ContractPart_AssaultRifle2", delta = 1.5 },
    { baseName = "Base.AssaultRifle", nameKey = "IGUI_PZLinux_ContractPart_AssaultRifle", delta = 1.5 },
    { baseName = "Base.VarmintRifle", nameKey = "IGUI_PZLinux_ContractPart_VarmintRifle", delta = 1.5 },
    { baseName = "Base.HuntingRifle", nameKey = "IGUI_PZLinux_ContractPart_HuntingRifle", delta = 1.5 },
}

function PZLinuxContractsRandomWeaponRequest()
    return PZLinuxContractWeaponRequests[ZombRand(1, #PZLinuxContractWeaponRequests + 1)]
end
