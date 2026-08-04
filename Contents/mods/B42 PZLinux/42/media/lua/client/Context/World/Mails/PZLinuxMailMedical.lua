function PZLinuxMailGenerateBodyMedical(sender, id)
    local player = PZLinuxGetPlayer()
    if not player then return "" end

    local name = PZLinuxPrettifyName(player:getUsername())
    local mail = PZLinuxMailNormalizeRecord(player, id)
    if not mail then return "" end
    mail.sender = mail.sender or sender

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
