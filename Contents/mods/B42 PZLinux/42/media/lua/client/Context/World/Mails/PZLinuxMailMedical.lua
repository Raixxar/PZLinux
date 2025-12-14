function PZLinuxMailGenerateBodyMedical(sender, id)
    local name = PZLinuxPrettifyName(getPlayer():getUsername())
    local seed = ZombRand(1, 4)

    local player = getPlayer()
    local md = player:getModData()

    local loc = PZLinuxMailLocation()

    md.pzlinux = md.pzlinux or {}
    md.pzlinux.mails = md.pzlinux.mails or {}
    md.pzlinux.mails[id] = md.pzlinux.mails[id] or {}
    local mail = md.pzlinux.mails[id]
    if not mail.status then mail.status = 1 end
    if not mail.city then mail.city = loc.name end
    if not mail.x then mail.x = loc.x end
    if not mail.y then mail.y = loc.y end
    if not mail.z then mail.z = loc.z end
    if not mail.quantity then mail.quantity = PZLinuxMailMedicalAmount() end
    if not mail.object then mail.object = PZLinuxMailMedicalType() end
    if not mail.sender then mail.sender = sender end
    if not mail.seed then mail.seed = seed end

    local scriptItem = getScriptManager():FindItem(mail.object)
    local displayName = scriptItem and scriptItem:getDisplayName() or mail.object

    local message = ""

    if mail.seed == 1 then
        message = string.format([[
Hello %s,
We’re running out of medical supplies and the situation is getting worse by the hour. Wounds are getting infected, fevers won’t break, and we can’t keep people stable much longer. If you can help, please bring the following to this location as soon as possible:

Quantity : %d
Object : %s
Location : %s

Whatever you decide, thank you for reading this.
Stay alive out there.
— %s
]], name, mail.quantity, displayName, mail.city, mail.sender)

    elseif mail.seed == 2 then
        message = string.format([[
Hello %s,
I’m writing with shaking hands. We have survivors here—some hurt, some sick—and we’re down to almost nothing. If you have any spare meds, please bring them quickly. Even a small amount could save lives.

Quantity : %d
Object : %s
Location : %s

We owe you, even if you can’t make it.
— %s
]], name, mail.quantity, displayName, mail.city, mail.sender)
    elseif mail.seed == 3 then
        message = string.format([[
Hello %s,
We thought we could manage on bandages and luck. We were wrong. Pain is constant, infections are spreading, and we’re out of proper medication. If you’re still out there and able, please deliver:

Quantity : %d
Object : %s
Location : %s

No pressure—just… hope.
— %s
]], name, mail.quantity, displayName, mail.city, mail.sender)
    end
    return message
end

function PZLinuxMailMedicalType()
    local ammoTypes = { 
        "Base.Bandage", 
        "Base.Bandaid", 
        "Base.AlcoholWipes",
        "Base.Antibiotics",
        "Base.PillsAntiDep",
        "Base.PillsBeta",
        "Base.Pills",
    }
    local idx = ZombRand(#ammoTypes) + 1
    return ammoTypes[idx]
end

function PZLinuxMailMedicalAmount()
    local idx = ZombRand(1, 6)
    return idx
end

function PZLinuxMailLocation()
    local locations = {
        { name = "In a trash can in Echo Creek", x = 3571, y = 10913, z = 0 },
        { name = "In a trash can in Echo Creek", x = 3524, y = 10886, z = 0 },
        { name = "In a trash can in Rosewood", x = 8147, y = 11492, z = 0 },
        { name = "In a trash can in Rosewood", x = 8070, y = 11469, z = 0 },
        { name = "In a trash can in West Point", x = 11421, y = 6772, z = 0 },
        { name = "In a trash can in West Point", x = 12100, y = 6786, z = 0 },
        { name = "In a trash can in Riverside", x = 6604, y = 5222, z = 0 },
        { name = "In a trash can in Riverside", x = 6467, y = 5440, z = 0 },
        { name = "In a trash can in Brandenburg", x = 2140, y = 6439, z = 0 },
        { name = "In a trash can in Brandenburg", x = 2099, y = 6022, z = 0 },
    }
    local idx = ZombRand(#locations) + 1
    return locations[idx]
end
