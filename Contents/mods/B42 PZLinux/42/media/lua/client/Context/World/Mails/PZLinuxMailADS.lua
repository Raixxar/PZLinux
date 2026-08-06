function PZLinuxMailGenerateBodyADS(sender, id)
    local player = PZLinuxGetPlayer()
    if not player then return "" end

    local name = PZLinuxPrettifyName(player:getUsername())
    local mail = PZLinuxMailNormalizeRecord(player, id)
    if not mail then return "" end
    mail.sender = mail.sender or sender

    local message = ""

    if mail.seed == 1 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_1", [[
Hello %s,
Still fighting zombies with junk gear?
Upgrade NOW with our PRE-APOC SURVIVAL KIT™.
Batteries included. Morals not included.
Order today. Survive tomorrow.
Click before we’re eaten.
- %s
]], name, mail.sender)

    elseif mail.seed == 2 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_2", [[
Hello %s,
Is your base cold?
Is your generator loud?
Try our SILENT TECH SOLUTIONS today!
No warranty after the apocalypse.
Limited stock. Very limited lives.

Regards,
%s
]], name, mail.sender)
    elseif mail.seed == 3 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_3", [[
Doctors hate this ONE trick!
Hack, trade, survive smarter than others.
Earn money from your bunker!
100% legit*
*legit-ish.

— %s
]], mail.sender)
    elseif mail.seed == 4 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_4", [[
%s !
Got skills? Got nerves?
We’ve got “jobs” no one else wants.
High risk. Questionable ethics.
Great rewards.
Reply fast.

— %s
]], name, mail.sender)
    elseif mail.seed == 5 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_5", [[
Hello survivor, %s
Tired of receiving our emails?
To unsubscribe, simply reply with
YOUR PASSWORD and BASE LOCATION.
Easy. Fast. Totally safe.*

— %s
]], name, mail.sender)
    elseif mail.seed == 6 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_6", [[
%s, Generators fail. Friends betray.
But our gear NEVER lets you down.*
Buy now. Regret later.
Or regret dying.
Your choice.

— %s
]], name, mail.sender)
    elseif mail.seed == 7 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_7", [[
This is not spam.
This is an OPPORTUNITY.
Miss it and someone else gets richer.
Reply “YES” to proceed.
Reply “NO” to stay poor.

— %s
]], mail.sender)
    elseif mail.seed == 8 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_8", [[
You have been selected for a
VERY LEGAL business opportunity.
High profit. Low questions.
Moral compass not required.
Apply before midnight.

— %s
]], mail.sender)
    elseif mail.seed == 9 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_9", [[
Relax %s. We don’t judge.
In fact, we PAY for that.
Discreet jobs available now.
Delete this message after reading.
Or don’t. We already copied it.

— %s
]], name, mail.sender)
    elseif mail.seed == 10 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_10", [[
Food is temporary.
Ammo is limited.
Knowledge is power.
Subscribe today.
Unsubscribe never.

— %s
]], mail.sender)
    elseif mail.seed == 11 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_11", [[
Hello lucky survivor!
You’ve won a FREE survival reward!
Just reply to claim it now.
Hurry, zombies are faster than emails.
— Rewards Team*
%s
]], mail.sender)
    elseif mail.seed == 12 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_12", [[
Hello %s, Your name was randomly selected.*
You won rare equipment and cash!
Claim within 24 hours.
After that, we keep it.
*Very random.
%s
]], name, mail.sender)
    elseif mail.seed == 13 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_13", [[
Unbelievable news!
You won our APOCALYPSE LOTTERY.
Prizes include gear, money, or mystery boxes.
Reply “CLAIM” to proceed.
Good luck. You’ll need it.
%s
]], mail.sender)
    elseif mail.seed == 14 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_14", [[
Hello name_in_database[893] ! That’s right.
No effort. No skill. Lorem Ipsum !
Just pure luck.
Claim your reward now.
Before someone else does.
%s
]], mail.sender)
    elseif mail.seed == 15 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_15", [[
Hi %s We appreciate loyal survivors like you.
Enjoy this exclusive reward.
Click to receive your prize.
No refunds. No survivors.
— Customer Care
%s
]], name, mail.sender)
    elseif mail.seed == 16 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_16", [[
You were selected for a hidden giveaway.
Very few survivors qualify.
Very few survive either.
Claim now.
Discretion advised.
%s
]], mail.sender)
    elseif mail.seed == 17 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_17", [[
1 survivor.
1000 zombies.
And YOU won a prize.
Don’t ask how.
Just take it.
%s
]], mail.sender)
    elseif mail.seed == 18 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_18", [[
Hello USER_0001, %s
Our system detected a WIN event.
Prize: ???
Location: UNKNOWN
Proceed anyway? Y/N
%s
]], mail.sender, name)
    elseif mail.seed == 19 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_19", [[
Hi Knox Country,
You have been selected for SELECT * FROM rewards;
If error persists, blame the apocalypse.
Do not reply.
Actually, reply.
- %s
]], name)
    elseif mail.seed == 20 then
        message = PZLinuxFormatText("IGUI_PZLinux_MailAds_20", [[
Nothing beats a Knox 2 holiday and right now you can save £50 per person.
That's £200 off for a family of 4. we've got millions of free child place holidays available with 22kg of baggage included.
book now with Knox 2 holidays. package holidays you can trust!
- %s
]], mail.sender)
    end
    return message
end
