function PZLinuxMailGenerateBodyAmmo(sender, id)
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
