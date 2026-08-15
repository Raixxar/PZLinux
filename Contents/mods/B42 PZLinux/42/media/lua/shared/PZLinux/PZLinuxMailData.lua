PZLinux = PZLinux or {}

PZLinuxMailTable = PZLinuxMailTable or {
    { baseName = "CONGRATULATIONS!", type = "ads" },
    { baseName = "THE WINNER IS", type = "ads" },
    { baseName = "HOLIDAY FOR FREE", type = "ads" },
    { baseName = "Need Ammo", type = "ammo" },
    { baseName = "Medical supplies", type = "medical" },
}

-- Base.223Box used to be in the ammo pool too -- dead since .223 was
-- removed from the game in Build 42.14 (replaced by 5.56, already present
-- here as Base.556Box) -- removed rather than renamed to avoid listing
-- 556Box twice. See PZLinuxDarkWebData.lua's own cleanup of the same
-- stale id for the full explanation.
PZLinuxMailDeliveryItems = PZLinuxMailDeliveryItems or {
    ammo = {"Base.308Box", "Base.Bullets38Box", "Base.Bullets44Box", "Base.Bullets45Box", "Base.556Box", "Base.Bullets9mmBox", "Base.ShotgunShellsBox"},
    medical = {"Base.Bandage", "Base.Bandaid", "Base.AlcoholWipes", "Base.Antibiotics", "Base.PillsAntiDep", "Base.PillsBeta", "Base.Pills"},
}
