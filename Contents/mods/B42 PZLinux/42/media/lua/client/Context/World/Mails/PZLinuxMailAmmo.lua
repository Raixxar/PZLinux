function PZLinuxMailGenerateBodyAmmo(sender, id)
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
    if not mail.quantity then mail.quantity = PZLinuxMailAmmoAmount() end
    if not mail.object then mail.object = PZLinuxMailAmmoType() end
    if not mail.sender then mail.sender = sender end
    if not mail.seed then mail.seed = seed end

    local scriptItem = getScriptManager():FindItem(mail.object)
    local displayName = scriptItem and scriptItem:getDisplayName() or mail.object

    local message = ""

    if mail.seed == 1 then
        message = string.format([[
Hello %s,
For several weeks now, we have been facing relentless waves of zombies, and our ammunition supplies are critically low. If these attacks continue at this pace, we won’t survive much longer. Could you provide us with These supplies could mean the difference between holding our ground or being overrun. Please deliver the ammunition.

Quantity : %d 
Object : %s
Location : %s

Stay safe, and thank you for considering our request.

Sincerely,
%s
]], name, mail.quantity, displayName, mail.city, mail.sender)

    elseif mail.seed == 2 then
        message = string.format([[
Hello %s,
We are reaching out because the situation here has become critical. Several survivors spoke highly of you, and we hope they were right. Zombie activity has increased drastically in our area, and we are almost out of ammunition. If you can deliver them to the location below, you may save more lives than you realize.

Quantity : %d 
Object : %s
Location : %s

We know this is dangerous. Whatever you decide, thank you for reading this.

Regards,
%s
]], name, mail.quantity, displayName, mail.city, mail.sender)
    elseif mail.seed == 3 then
        message = string.format([[
Hello %s,
We don’t know how long we can keep this place secured, but we were told you might listen. Every night, the dead come closer, and every day our ammunition runs lower. We are doing everything we can, but it’s no longer enough. Please bring them to the following location as soon as possible: 

Quantity : %d 
Object : %s
Location : %s

No matter your answer, we appreciate you taking the time to read this.
Stay alive out there.

— %s
]], name, mail.quantity, displayName, mail.city, mail.sender)
    end
    return message
end

function PZLinuxMailAmmoType()
    local ammoTypes = {"Base.223Box", "Base.308Box", "Base.Bullets38Box", "Base.Bullets44Box", "Base.Bullets45Box", "Base.556Box", "Base.Bullets9mmBox", "Base.ShotgunShellsBox" }
    local idx = ZombRand(#ammoTypes) + 1
    return ammoTypes[idx]
end

function PZLinuxMailAmmoAmount()
    local idx = ZombRand(1, 6)
    return idx
end

function PZLinuxMailLocation()
    local locations = {
        { name = "In a trash can in Ekron", x = 683, y = 9920, z = 0 },
        { name = "In a trash can in March Ridge", x = 10178, y = 12668, z = 0 },
        { name = "In a trash can in March Ridge", x = 10048, y = 12776, z = 0 },
        { name = "In a trash can in Irvington", x = 2579, y = 14473, z = 0 },
        { name = "In a trash can in Irvington", x = 3100, y = 14489, z = 0 },
        { name = "In a trash can in Muldraugh", x = 10635, y = 10041, z = 0 },
        { name = "In a trash can in Muldraugh", x = 10644, y = 9767, z = 0 },
    }
    local idx = ZombRand(#locations) + 1
    return locations[idx]
end
