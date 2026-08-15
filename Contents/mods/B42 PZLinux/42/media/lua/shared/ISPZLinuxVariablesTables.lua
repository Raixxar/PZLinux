PZLinux = PZLinux or {}

require "PZLinux/PZLinuxConfig"
require "PZLinux/PZLinuxTyping"
require "PZLinux/PZLinuxWorldInteractions"
require "PZLinux/PZLinuxMissionLocations"
require "PZLinux/PZLinuxGamblingData"
require "PZLinux/PZLinuxRaceEngine"
require "PZLinux/PZLinuxRaceSchedule"
require "PZLinux/PZLinuxRequestsData"
require "PZLinux/PZLinuxContractsData"
require "PZLinux/PZLinuxContractRequestData"
require "PZLinux/PZLinuxContractMission"
require "PZLinux/PZLinuxMailData"
require "PZLinux/PZLinuxDarkWebData"
require "PZLinux/PZLinuxTradingData"
require "PZLinux/PZLinuxTrainingData"
require "PZLinux/PZLinuxEconomy"
require "PZLinux/PZLinuxInventoryCash"
require "PZLinux/PZLinuxPokerConfig"
require "PZLinux/PZLinuxPokerEngine"

function PZLinux.getPlayer(player)
    if player and type(player) == "number" and getSpecificPlayer then
        return getSpecificPlayer(player)
    end

    if player and type(player) ~= "number" then
        return player
    end

    if getPlayer then
        return getPlayer()
    end

    return nil
end

-- Belt and suspenders (v1.0.8): reputation lives in a nested table
-- (md.pzlinux.player.reputation), unlike almost every other value in this
-- mod, which uses flat top-level modData keys -- the pattern this mod has
-- actually exercised for years (328 usages) without a reported persistence
-- issue, versus this nested one (a couple dozen, reputation/mail/contract-
-- receipt bookkeeping only). A player reported their reputation looking
-- reset to neutral after restarting the game, alongside their bank balance
-- looking wrong too -- exactly what a nested value failing to round-trip
-- through a save/reload would look like, since every reader here already
-- silently falls back to the neutral baseline (1) when it reads nil, with
-- no way to tell "genuinely new character" from "value was lost". Mirroring
-- it onto a flat backup key gives it the same round-trip guarantee as
-- everything else, and lets a lost nested value be recovered instead of
-- silently resetting.
function PZLinux.getModData(player)
    local playerObj = PZLinux.getPlayer(player)
    if not playerObj then return nil, nil, nil end

    local md = playerObj:getModData()
    md.pzlinux = md.pzlinux or {}
    md.pzlinux.player = md.pzlinux.player or {}
    md.pzlinux.mails = md.pzlinux.mails or {}
    md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}
    md.pzlinux.mails.nextid = md.pzlinux.mails.nextid or 1

    local reputation = tonumber(md.pzlinux.player.reputation)
    if reputation == nil then
        local backupReputation = tonumber(md.PZLinuxReputationBackup)
        if backupReputation ~= nil then
            print(string.format(
                "[PZLinux Reputation] RECOVERED reputation from backup key player=%s reputation=%d (nested value was nil)",
                tostring(PZLinuxGetPlayerKey(playerObj)), backupReputation))
            reputation = backupReputation
        else
            reputation = 1
        end
    end
    md.pzlinux.player.reputation = reputation
    md.PZLinuxReputationBackup = reputation

    return md, md.pzlinux, playerObj
end

function PZLinux.getMailData(player, id)
    local md, pzlinux = PZLinux.getModData(player)
    if not pzlinux then return nil, md end

    if id then
        pzlinux.mails[id] = pzlinux.mails[id] or {}
        return pzlinux.mails[id], md
    end

    return pzlinux.mails, md
end

function PZLinuxGetPlayer(player)
    return PZLinux.getPlayer(player)
end

function PZLinuxGetModData(player)
    return PZLinux.getModData(player)
end

function PZLinuxGetMailData(player, id)
    return PZLinux.getMailData(player, id)
end

PZLinux.TextFallbacks = PZLinux.TextFallbacks or {
    IGUI_PZLinux_Betting_Balance = "Bank Balance: $",
    IGUI_PZLinux_Betting_ZombieRace = "ZOMBIE RACE",
    IGUI_PZLinux_Betting_Blackjack = "BLACKJACK",
    IGUI_PZLinux_Betting_Poker = "TEXAS HOLD'EM",
    IGUI_PZLinux_Betting_LoadingRace = "Loading race card...",
    IGUI_PZLinux_Betting_Error = "Betting service unavailable",
    IGUI_PZLinux_Betting_InvalidBet = "Invalid bet",
    IGUI_PZLinux_Betting_NotEnoughMoney = "Not enough money",
    IGUI_PZLinux_Betting_StartingRace = "Starting race...",
    IGUI_PZLinux_Betting_BetOn = "Bet on?",
    IGUI_PZLinux_Betting_Amount = "Amount",
    IGUI_PZLinux_Betting_StartRace = "START THE RACE!",
    IGUI_PZLinux_Betting_YourBet = "Your bet: ",
    IGUI_PZLinux_Betting_RaceWinner = "%s HAS WON!",
    IGUI_PZLinux_Betting_BlackjackTitle = "BLACKJACK",
    IGUI_PZLinux_Betting_Deal = "DEAL",
    IGUI_PZLinux_Betting_Dealing = "Dealing...",
    IGUI_PZLinux_Betting_Hit = "HIT",
    IGUI_PZLinux_Betting_Stand = "STAND",
    IGUI_PZLinux_Betting_Dealer = "Dealer: ",
    IGUI_PZLinux_Betting_Player = "Player: ",
    IGUI_PZLinux_Betting_Payout = "Payout: $",
    IGUI_PZLinux_Betting_PokerLobby = "TEXAS HOLD'EM LOBBY",
    IGUI_PZLinux_Betting_PokerBuyIn = "Buy-in",
    IGUI_PZLinux_Betting_PokerInvalidBuyIn = "Buy-in outside lobby limits",
    IGUI_PZLinux_Betting_PokerJoining = "Joining table...",
    IGUI_PZLinux_Betting_PokerError = "Poker error",
    IGUI_PZLinux_Betting_PokerTable = "POKER TABLE",
    IGUI_PZLinux_Betting_PokerBoard = "Board:",
    IGUI_PZLinux_Betting_PokerAmount = "Amount",
    IGUI_PZLinux_Betting_PokerFold = "FOLD",
    IGUI_PZLinux_Betting_PokerCheck = "CHECK",
    IGUI_PZLinux_Betting_PokerCall = "CALL",
    IGUI_PZLinux_Betting_PokerBet = "BET",
    IGUI_PZLinux_Betting_PokerRaise = "RAISE",
    IGUI_PZLinux_Betting_PokerAllIn = "ALL-IN",
    IGUI_PZLinux_Betting_PokerNextHand = "NEXT HAND",
    IGUI_PZLinux_Betting_PokerCashOut = "CASH OUT",
    IGUI_PZLinux_Betting_PokerClosed = "Poker session closed:",
    IGUI_PZLinux_Betting_PokerBusted = "Out of chips - leave the table to buy in again",
    IGUI_PZLinux_Betting_PokerTableWon = "Table won - cash out your chips",
    IGUI_PZLinux_Betting_PokerCurrentHand = "Current hand",
    IGUI_PZLinux_Betting_PokerWinChance = "Win chance",
    IGUI_PZLinux_Betting_PokerHandRoyalFlush = "Royal flush",
    IGUI_PZLinux_Betting_PokerHandStraightFlush = "Straight flush",
    IGUI_PZLinux_Betting_PokerHandFourKind = "Four of a kind",
    IGUI_PZLinux_Betting_PokerHandFullHouse = "Full house",
    IGUI_PZLinux_Betting_PokerHandFlush = "Flush",
    IGUI_PZLinux_Betting_PokerHandStraight = "Straight",
    IGUI_PZLinux_Betting_PokerHandThreeKind = "Three of a kind",
    IGUI_PZLinux_Betting_PokerHandTwoPair = "Two pair",
    IGUI_PZLinux_Betting_PokerHandPair = "Pair",
    IGUI_PZLinux_Betting_PokerHandHighCard = "High card",
    IGUI_PZLinux_Betting_RacePool = "%d bettors | Pool $%d | Max bet $%d",
    IGUI_PZLinux_Betting_RaceBetLimit = "Maximum bet: $%d",
    IGUI_PZLinux_Betting_RaceScheduleTitle = "RACES - FIVE DEPARTURES PER DAY",
    IGUI_PZLinux_Betting_RaceNoResult = "No recent result",
    IGUI_PZLinux_Betting_RaceResultWin = "WIN +$%d",
    IGUI_PZLinux_Betting_RaceResultLose = "LOST $%d",
    IGUI_PZLinux_Betting_RaceJackpot = "JACKPOT +$%d",
    IGUI_PZLinux_Betting_RaceTicket = "BET $%d ON #%d",
    IGUI_PZLinux_Betting_RacePlaceBet = "PLACE BET",
    IGUI_PZLinux_Betting_RaceBackSchedule = "SCHEDULE",
    IGUI_PZLinux_Betting_RaceSavingBet = "Saving ticket...",
    IGUI_PZLinux_Context_DepositMailItems = "Deposit the requested email items",
    IGUI_PZLinux_Context_Mailbox = "Mailbox",
    IGUI_PZLinux_Context_TakeContractPackage = "Take the contract package",
    IGUI_PZLinux_Context_PrepareCargo = "Prepare the cargo for helicopter pickup",
    IGUI_PZLinux_Context_ProtectBuilding = "Protect the building",
    IGUI_PZLinux_Context_MarkSectorClear = "Mark the sector as clear",
    IGUI_PZLinux_Context_CutTarget = "Cut off the target's head",
    IGUI_PZLinux_Context_TakeZombieBlood = "Collect zombie blood",
    IGUI_PZLinux_Context_CaptureZombie = "Capture a zombie",
    IGUI_PZLinux_Context_RepairComputer = "Repair the computer",
    IGUI_PZLinux_Context_ATM = "ATM",
    IGUI_PZLinux_Mailbox_Leave = "LEAVE",
    IGUI_PZLinux_Mailbox_Check = "CHECK MAILBOX",
    IGUI_PZLinux_Mailbox_TakeItems = "COLLECT ITEMS",
    IGUI_PZLinux_Mailbox_SendContract = "SEND AND COMPLETE CONTRACT",
    IGUI_PZLinux_Mailbox_TakeAndSend = "COLLECT ITEMS + SEND CONTRACT",
    IGUI_PZLinux_Reputation_Button = "REPUTATION",
    IGUI_PZLinux_Reputation_Title = "NETWORK REPUTATION",
    IGUI_PZLinux_Reputation_Loading = "Loading reputation...",
    IGUI_PZLinux_Reputation_Unavailable = "Reputation service unavailable.",
    IGUI_PZLinux_Reputation_Score = "Score: %s (range %s to %s)",
    IGUI_PZLinux_Reputation_Status = "Status: %s",
    IGUI_PZLinux_Reputation_PriceModifier = "Purchase prices: %s",
    IGUI_PZLinux_Reputation_MailFrequency = "Mail frequency: %s",
    IGUI_PZLinux_Reputation_MailReduced = "REDUCED",
    IGUI_PZLinux_Reputation_MailNormal = "NORMAL",
    IGUI_PZLinux_Reputation_MailImproved = "IMPROVED",
    IGUI_PZLinux_Reputation_CompletionGain = "Contract or mail mission completed: +%s",
    IGUI_PZLinux_Reputation_CancelPenalty = "Contract cancelled: -%s",
    IGUI_PZLinux_Reputation_Decay = "Without activity, reputation gradually returns to neutral.",
    IGUI_PZLinux_Reputation_NextStatus = "Next status: %s (%s points)",
    IGUI_PZLinux_Reputation_MaxStatus = "Highest reputation status reached.",
    IGUI_PZLinux_Reputation_Back = "BACK",
    IGUI_PZLinux_Reputation_StatusBlacklisted = "BLACKLISTED",
    IGUI_PZLinux_Reputation_StatusDistrusted = "DISTRUSTED",
    IGUI_PZLinux_Reputation_StatusNeutral = "NEUTRAL",
    IGUI_PZLinux_Reputation_StatusKnown = "KNOWN",
    IGUI_PZLinux_Reputation_StatusReliable = "RELIABLE",
    IGUI_PZLinux_Reputation_StatusPreferred = "PREFERRED",
    IGUI_PZLinux_Contracts_CompletionPaid = "You have been paid for your contract.",
    IGUI_PZLinux_Contracts_CompletionAmount = "Total money earned: $%s",
    IGUI_PZLinux_Contracts_CompletionZombies = "Total zombies killed: %s",
    IGUI_PZLinux_StolenNote_Title = "Torn Note",
    IGUI_PZLinux_StolenNote_1 = "Sorry, survival comes first!",
    IGUI_PZLinux_StolenNote_2 = "That's life!",
    IGUI_PZLinux_StolenNote_3 = "Should've hidden it better.",
    IGUI_PZLinux_StolenNote_4 = "Finders keepers.",
    IGUI_PZLinux_StolenNote_5 = "Better luck with the next delivery.",
    IGUI_PZLinux_StolenNote_6 = "The apocalypse has bills too.",
    IGUI_PZLinux_StolenNote_7 = "Consider it a survival tax.",
    IGUI_PZLinux_StolenNote_8 = "Someone needed it more than you. Or just wanted it.",
    IGUI_PZLinux_StolenNote_9 = "Not all heroes wear masks. This one did.",
    IGUI_PZLinux_StolenNote_10 = "Thanks for the donation!",
    IGUI_PZLinux_StolenNote_11 = "Someone's apocalypse just got a little easier. Not yours.",
    IGUI_PZLinux_StolenNote_12 = "Guess it wasn't meant to be.",
    IGUI_PZLinux_StolenNote_13 = "Easy come, easy go.",
    IGUI_PZLinux_StolenNote_14 = "The Knox Event doesn't do refunds.",
    IGUI_PZLinux_StolenNote_15 = "You snooze, you lose. Someone else didn't snooze.",
    IGUI_PZLinux_StolenNote_16 = "Well, that's one way to lose weight.",
    IGUI_PZLinux_StolenNote_17 = "At least it wasn't your legs.",
    IGUI_PZLinux_StolenNote_18 = "Free enterprise, zombie-apocalypse style.",
    IGUI_PZLinux_StolenNote_19 = "Karma's just late on some deliveries.",
    IGUI_PZLinux_StolenNote_20 = "Next time, maybe tip the courier.",
    -- Auto Parts/Medical/Weapon contract item names (see
    -- PZLinuxContractRequestData.lua). The Auto Parts ones exist to
    -- disambiguate between three quality tiers that PZ's own vanilla item
    -- name can't tell apart (Base.NormalSuspension1/2/3 all display as the
    -- same "Suspension - Regular", etc.) -- Medical/Weapon names are
    -- translated here too for consistency, since the physical contract
    -- note always uses this text regardless of contract type.
    IGUI_PZLinux_ContractPart_CarBattery3 = "Battery: Resistant",
    IGUI_PZLinux_ContractPart_CarBattery2 = "Battery: Sport",
    IGUI_PZLinux_ContractPart_CarBattery1 = "Battery: Standard",
    IGUI_PZLinux_ContractPart_ModernBrake3 = "Performance brakes: Resistant",
    IGUI_PZLinux_ContractPart_ModernBrake2 = "Performance brakes: Sport",
    IGUI_PZLinux_ContractPart_ModernBrake1 = "Performance brakes: Standard",
    IGUI_PZLinux_ContractPart_ModernCarMuffler3 = "Performance silencers: Resistant",
    IGUI_PZLinux_ContractPart_ModernCarMuffler2 = "Performance silencers: Sport",
    IGUI_PZLinux_ContractPart_ModernCarMuffler1 = "Performance silencers: Standard",
    IGUI_PZLinux_ContractPart_ModernSuspension3 = "Performance suspension: Resistant",
    IGUI_PZLinux_ContractPart_ModernSuspension2 = "Performance suspension: Sport",
    IGUI_PZLinux_ContractPart_ModernSuspension1 = "Performance suspension: Standard",
    IGUI_PZLinux_ContractPart_NormalBrake3 = "Standard brakes: Resistant",
    IGUI_PZLinux_ContractPart_NormalBrake2 = "Standard brakes: Sport",
    IGUI_PZLinux_ContractPart_NormalBrake1 = "Standard brakes: Standard",
    IGUI_PZLinux_ContractPart_NormalCarMuffler3 = "Standard silencers: Resistant",
    IGUI_PZLinux_ContractPart_NormalCarMuffler2 = "Standard silencers: Sport",
    IGUI_PZLinux_ContractPart_NormalCarMuffler1 = "Standard silencers: Standard",
    IGUI_PZLinux_ContractPart_NormalSuspension3 = "Standard suspension: Resistant",
    IGUI_PZLinux_ContractPart_NormalSuspension2 = "Standard suspension: Sport",
    IGUI_PZLinux_ContractPart_NormalSuspension1 = "Standard suspension: Standard",
    IGUI_PZLinux_ContractPart_Bandaid = "Bandage: Adhesive",
    IGUI_PZLinux_ContractPart_Bandage = "Bandage",
    IGUI_PZLinux_ContractPart_AlcoholWipes = "Alcohol Wipes",
    IGUI_PZLinux_ContractPart_Disinfectant = "Bottle of Disinfectant",
    IGUI_PZLinux_ContractPart_AlcoholedCottonBalls = "Cotton Balls Doused in Alcohol",
    IGUI_PZLinux_ContractPart_Antibiotics = "Antibiotics",
    IGUI_PZLinux_ContractPart_PillsAntiDep = "Antidepressants",
    IGUI_PZLinux_ContractPart_PillsBeta = "Beta Blockers",
    IGUI_PZLinux_ContractPart_Pills = "Painkillers",
    IGUI_PZLinux_ContractPart_PillsSleepingTablets = "Sleeping Pills",
    IGUI_PZLinux_ContractPart_PillsVitamins = "Caffeine Pills",
    IGUI_PZLinux_ContractPart_Pistol3 = "B-F Pistol",
    IGUI_PZLinux_ContractPart_Pistol2 = "M1911 Pistol",
    IGUI_PZLinux_ContractPart_RevolverShort = "SN38 Revolver",
    IGUI_PZLinux_ContractPart_Revolver = "Patrol Revolver",
    IGUI_PZLinux_ContractPart_Pistol = "M9 Pistol",
    IGUI_PZLinux_ContractPart_RevolverLong = "Magnum",
    IGUI_PZLinux_ContractPart_DoubleBarrelShotgun = "Double Barrel Shotgun",
    IGUI_PZLinux_ContractPart_Shotgun = "JS-2000 Shotgun",
    IGUI_PZLinux_ContractPart_DoubleBarrelShotgunSawnoff = "Sawed-off Double Barrel Shotgun",
    IGUI_PZLinux_ContractPart_ShotgunSawnoff = "Sawed-off JS-2000 Shotgun",
    IGUI_PZLinux_ContractPart_AssaultRifle2 = "M1A Rifle",
    IGUI_PZLinux_ContractPart_AssaultRifle = "M16 Assault Rifle",
    IGUI_PZLinux_ContractPart_VarmintRifle = "MSR700 Rifle",
    IGUI_PZLinux_ContractPart_HuntingRifle = "MSR788 Rifle",

    IGUI_PZLinux_Training_Title = "PZLinux Training",
    IGUI_PZLinux_Training_Buy = "Start",
    IGUI_PZLinux_Training_Cancel = "Cancel",
    IGUI_PZLinux_Training_Completed = "Training complete: +%s XP",
    IGUI_PZLinux_Training_InProgress = "In progress: %s",
    IGUI_PZLinux_Training_StayHere = "Stay here to keep training. Progress pauses if you leave.",
    IGUI_PZLinux_Training_ChooseCourse = "This week's courses:",
    IGUI_PZLinux_Training_Detail = "+%s XP - $%s - about %s in-game hours",
    IGUI_PZLinux_Training_AlreadyInProgress = "Finish your current training first",
    IGUI_PZLinux_Training_Electricity = "Electrical Engineering",
    IGUI_PZLinux_Training_Mechanics = "Auto Mechanics",
    IGUI_PZLinux_Training_Cooking = "Culinary Arts",
    IGUI_PZLinux_Training_Farming = "Agriculture",
    IGUI_PZLinux_Training_Woodwork = "Carpentry",
    IGUI_PZLinux_Training_Metalworking = "Metalworking",
    IGUI_PZLinux_Training_Tailoring = "Tailoring",
    IGUI_PZLinux_Training_FirstAid = "First Aid",
    IGUI_PZLinux_Training_Fishing = "Fishing",
    IGUI_PZLinux_Training_Trapping = "Trapping",
    IGUI_PZLinux_Training_Foraging = "Foraging",
    IGUI_PZLinux_Training_Husbandry = "Animal Husbandry",
    IGUI_PZLinux_Training_Blacksmith = "Blacksmithing",
    IGUI_PZLinux_Training_Masonry = "Masonry",
    IGUI_PZLinux_Training_Pottery = "Pottery",
}

function PZLinuxGetText(key)
    if getText then
        local translated = getText(key)
        if translated and translated ~= key then
            return translated
        end
    end
    return PZLinux.TextFallbacks[key] or key
end

-- Never pass extra arguments to the native getText(key, ...) call: an
-- earlier version did (via disposable "__PZLINUX_VALUE_N__" markers, asking
-- the native translator to substitute them so the real values could be
-- gsub'd in afterward, with a pcall fallback if that native call errored).
-- In practice that produced blank values in real gameplay for several
-- multi-argument reputation lines with no error and no exception -- the
-- native call silently consumed/dropped the "%s" placeholders without
-- inserting the markers, so neither the marker gsub nor the "%s" gsub
-- fallback ever found anything to replace. A plain zero-argument getText(key)
-- lookup, with every substitution done here in Lua via gsub, sidesteps
-- that native behavior entirely and is simple enough to fully unit-test.
function PZLinuxFormatText(key, fallback, ...)
    local argumentCount = select("#", ...)
    local values = { ... }
    local template = fallback or key

    if getText then
        local translated = getText(key)
        if translated and translated ~= key then template = translated end
    end

    for index = 1, argumentCount do
        local replacement = tostring(values[index] or "")
        local substitutions
        template, substitutions = template:gsub("%%s", function() return replacement end, 1)
        if substitutions == 0 then
            template, substitutions = template:gsub("%%" .. tostring(index), function() return replacement end, 1)
        end
        if substitutions == 0 then template = template .. " " .. replacement end
    end
    return template
end

PZLinux.callbacks = PZLinux.callbacks or {}
PZLinux.blackjackSessions = PZLinux.blackjackSessions or {}
PZLinux.raceSessions = PZLinux.raceSessions or {}
PZLinux.darkWebBuySessions = PZLinux.darkWebBuySessions or {}
PZLinux.darkWebSellSessions = PZLinux.darkWebSellSessions or {}
PZLinux.hackingSessions = PZLinux.hackingSessions or {}
PZLinux.contractPreviews = PZLinux.contractPreviews or {}

-- A fresh, unique-per-process value (a bare table's own tostring() is its
-- memory address, which is as good as guaranteed unique for the lifetime of
-- this Lua state) used to tell "this process just started, so any
-- memory-only session table is legitimately empty" apart from "this process
-- has been running the whole time and a memory-only session went missing
-- for some OTHER reason". See PZLinuxRegisterInterruptedSession/
-- PZLinuxApplyInterruptedSessionRollbacks below -- a player found a real
-- money exploit in Hacking's Auto mode built on exactly this ambiguity
-- (v1.0.10): "when I close the computer, my cards come back, and I can
-- redo Auto with them indefinitely" -- the interrupted-session rollback,
-- meant only to make a player whole after a genuine server restart mid-hack
-- (PZLinux.hackingSessions is memory-only, sessions.hacking is persisted),
-- has no way today to tell that apart from any other reason
-- PZLinux.hackingSessions[key] might be empty while sessions.hacking is
-- still set -- restoring the cards either way. Stamping every interrupted-
-- session entry with the boot ID active when it was written, and only ever
-- rolling one back once that boot ID no longer matches the current one,
-- makes the rollback fire only across an actual restart -- which is the
-- only way this SHOULD legitimately happen, since nothing else can make a
-- memory-only table forget an entry mid-process.
PZLinux.serverBootId = PZLinux.serverBootId or tostring({})

function PZLinuxGetPlayerKey(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return "unknown" end
    if playerObj.getUsername then
        return tostring(playerObj:getUsername())
    end
    return tostring(playerObj)
end

function PZLinuxTransmitPlayerModData(player)
    local playerObj = PZLinuxGetPlayer(player)
    if playerObj and playerObj.transmitModData then
        playerObj:transmitModData()
    end
end

function PZLinuxSyncAddedContainerItem(container, item)
    if not container or not item then return false end
    if isServer and isServer() and sendAddItemToContainer then
        sendAddItemToContainer(container, item)
    end
    return true
end

function PZLinuxRemoveContainerItem(container, item)
    if not container or not item then return false end
    if isServer and isServer() and sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    container:Remove(item)
    return true
end

function PZLinuxSyncAddedInventoryItem(player, item)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return false end
    return PZLinuxSyncAddedContainerItem(playerObj:getInventory(), item)
end

function PZLinuxRemoveInventoryItem(player, item)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return false end
    return PZLinuxRemoveContainerItem(playerObj:getInventory(), item)
end

-- Dark Web and Buy Goods deliveries share the exact same 10% theft roll
-- (see PZLinuxDarkWebApplyDeliverOrders and PZLinuxRequestsApplyDelivery).
-- The existing HaloText bad-text bubble on theft is easy to miss, so this
-- also drops a small torn note into the player's inventory with one of 20
-- random flavor lines -- a tangible, findable explanation even if the
-- HaloText is missed. (A centered ISModalDialog popup was tried and
-- dropped: forcing a click-through confirmation while the player might be
-- mid-danger is worse than the confusion it was meant to fix; plain
-- HaloText plus this note is the shipped design.) Shared by both callers
-- so the note and its message pool never drift apart between the systems.
--
-- The note text is resolved with PZLinuxGetText, same as every other
-- shared/server-executed string in this file (see PZLinuxFormatFloorLabel):
-- on a dedicated server this resolves in the server's own configured
-- language rather than each connecting player's individual client
-- language. That's an accepted, pre-existing trade-off in this codebase,
-- not something new introduced here.
local PZLINUX_STOLEN_NOTE_MESSAGE_COUNT = 20

function PZLinuxCreateStolenOrderNote(player)
    local playerObj = PZLinuxGetPlayer(player)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return nil end

    local note = inventory:AddItem("Base.Note")
    if not note then return nil end

    local messageIndex = ZombRand(1, PZLINUX_STOLEN_NOTE_MESSAGE_COUNT + 1)
    local message = PZLinuxGetText("IGUI_PZLinux_StolenNote_" .. messageIndex)

    note:setName(PZLinuxGetText("IGUI_PZLinux_StolenNote_Title"))
    note:setCanBeWrite(true)
    note:addPage(1, message)
    PZLinuxSyncAddedInventoryItem(playerObj, note)
    return note
end

-- Belt and suspenders (v1.0.8): a player reported their bank balance
-- looking "really different" after restarting the game. If modData.PZLinuxBank
-- ever comes back nil for a reason other than "this character never had a
-- balance" -- a save/reload round-trip glitch, most plausibly -- the code
-- below couldn't tell that apart from a genuinely new character, and just
-- rolled a fresh random $500-$4000 starting balance over the real one,
-- with no record anywhere of what happened. PZLinuxBankBackup mirrors the
-- balance onto a second, independent top-level key on every write; if the
-- primary key is ever missing, this recovers the last known real balance
-- from the backup instead of silently replacing it with a random one. A
-- genuinely new character has both keys nil, so the random roll still
-- happens exactly as before in that case.
function PZLinuxLoadBankBalance(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end

    local modData = playerObj:getModData()
    local balance = tonumber(modData.PZLinuxBank)
    if balance == nil then
        local backupBalance = tonumber(modData.PZLinuxBankBackup)
        if backupBalance ~= nil then
            print(string.format(
                "[PZLinux Bank] RECOVERED balance from backup key player=%s balance=%d (primary key was nil)",
                tostring(PZLinuxGetPlayerKey(playerObj)), backupBalance))
            balance = backupBalance
        else
            -- Configurable via sandbox options (PZLinux.StartingBalanceMin/
            -- Max) so a server can set both to 0 and remove the "die, make
            -- a new character, get free money" loop entirely -- see
            -- PZLinuxGetStartingBalanceMin/Max.
            local minStart = PZLinuxGetStartingBalanceMin()
            local maxStart = math.max(minStart, PZLinuxGetStartingBalanceMax())
            balance = maxStart > minStart and ZombRand(minStart, maxStart) or minStart
        end
        modData.PZLinuxBank = balance
        PZLinuxTransmitPlayerModData(playerObj)
    end

    balance = math.max(0, math.floor(balance))
    modData.PZLinuxBank = balance
    modData.PZLinuxBankBackup = balance
    return balance
end

function PZLinuxSetBankBalance(player, balance)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end

    balance = PZLinuxNormalizeMoney(balance)
    local modData = playerObj:getModData()
    modData.PZLinuxBank = balance
    modData.PZLinuxBankBackup = balance
    PZLinuxTransmitPlayerModData(playerObj)
    return balance
end

function PZLinuxApplyBankDebit(player, amount, reason, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    local previousBalance = PZLinuxLoadBankBalance(player)

    if amount <= 0 then
        return { ok = false, error = "invalid_amount", amount = amount, balance = previousBalance, previousBalance = previousBalance, reason = reason, requestId = requestId }
    end

    if previousBalance < amount then
        return { ok = false, error = "not_enough_money", amount = amount, balance = previousBalance, previousBalance = previousBalance, reason = reason, requestId = requestId }
    end

    local balance = PZLinuxSetBankBalance(player, previousBalance - amount)
    return { ok = true, amount = amount, balance = balance, previousBalance = previousBalance, reason = reason, requestId = requestId }
end

function PZLinuxApplyBankCredit(player, amount, reason, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    local previousBalance = PZLinuxLoadBankBalance(player)

    if amount <= 0 then
        return { ok = false, error = "invalid_amount", amount = amount, balance = previousBalance, previousBalance = previousBalance, reason = reason, requestId = requestId }
    end

    local balance = PZLinuxSetBankBalance(player, previousBalance + amount)
    return { ok = true, amount = amount, balance = balance, previousBalance = previousBalance, reason = reason, requestId = requestId }
end

function PZLinuxGetInterruptedSessions(player)
    local _, pzlinux = PZLinuxGetModData(player)
    if not pzlinux then return nil end
    pzlinux.interruptedSessions = pzlinux.interruptedSessions or {}
    return pzlinux.interruptedSessions
end

function PZLinuxRegisterInterruptedSession(player, key, data)
    local playerObj = PZLinuxGetPlayer(player)
    local sessions = PZLinuxGetInterruptedSessions(playerObj)
    if not sessions or not key then return end
    data = data or {}
    data.bootId = PZLinux.serverBootId
    sessions[key] = data
    PZLinuxTransmitPlayerModData(playerObj)
end

function PZLinuxClearInterruptedSession(player, key)
    local playerObj = PZLinuxGetPlayer(player)
    local sessions = PZLinuxGetInterruptedSessions(playerObj)
    if not sessions or not key or not sessions[key] then return end
    sessions[key] = nil
    PZLinuxTransmitPlayerModData(playerObj)
end

function PZLinuxApplyInterruptedSessionRollbacks(player)
    local playerObj = PZLinuxGetPlayer(player)
    local sessions = PZLinuxGetInterruptedSessions(playerObj)
    if not playerObj or not sessions then return { ok = false, error = "no_player" } end

    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local applied = {}

    local blackjack = sessions.blackjack
    if blackjack and blackjack.bootId ~= PZLinux.serverBootId and not PZLinux.blackjackSessions[playerKey] then
        local amount = PZLinuxNormalizeMoney(blackjack.amount)
        if amount > 0 then
            local credit = PZLinuxApplyBankCredit(playerObj, amount, "rollback-blackjack", blackjack.requestId)
            applied.blackjack = credit.amount or amount
        end
        -- Temporary diagnostic logging for a reported bug (a Blackjack bet
        -- sometimes not actually being lost -- balance unchanged after a
        -- loss, "like free gambling"). This refund path exists to make a
        -- player whole if their hand never gets a Finish call (server
        -- restart/reload mid-hand, since PZLinux.blackjackSessions is
        -- memory-only while this interrupted-session flag is persisted in
        -- modData) -- but it runs before EVERY single idempotent command,
        -- for any reason, so if it is ever misfiring on top of a hand that
        -- actually did resolve normally, this is exactly where a spurious
        -- refund canceling out a real loss would happen. Safe to remove
        -- once the root cause is confirmed.
        print(string.format(
            "[PZLinux Blackjack] ROLLBACK player=%s originalRequestId=%s amount=%d",
            tostring(playerKey), tostring(blackjack.requestId), amount))
        sessions.blackjack = nil
    end

    local race = sessions.race
    if race and race.bootId ~= PZLinux.serverBootId and not PZLinux.raceSessions[playerKey] then
        local amount = PZLinuxNormalizeMoney(race.amount)
        if amount > 0 then
            local credit = PZLinuxApplyBankCredit(playerObj, amount, "rollback-zombie-race", race.requestId)
            applied.race = credit.amount or amount
        end
        sessions.race = nil
    end

    local hacking = sessions.hacking
    if hacking and hacking.bootId ~= PZLinux.serverBootId and not PZLinux.hackingSessions[playerKey] then
        local inventory = playerObj:getInventory()
        local restored = 0
        local pendingCardTypes = {}
        if inventory then
            for _, fullType in ipairs(hacking.cardTypes or {}) do
                if fullType then
                    local card = inventory:AddItem(fullType)
                    if card and PZLinuxSyncAddedInventoryItem(playerObj, card) then
                        restored = restored + 1
                    else
                        if card then inventory:Remove(card) end
                        table.insert(pendingCardTypes, fullType)
                    end
                end
            end
        end
        applied.hackingCards = restored
        if #pendingCardTypes == 0 then
            sessions.hacking = nil
        else
            hacking.cardTypes = pendingCardTypes
        end
    end

    local poker = sessions.poker
    if poker and poker.bootId ~= PZLinux.serverBootId
    and (not PZLinux.Poker or not PZLinux.Poker.Sessions or not PZLinux.Poker.Sessions[playerKey]) then
        local refund = PZLinuxNormalizeMoney(poker.stack)
        if refund > 0 then
            local credit = PZLinuxApplyBankCredit(playerObj, refund, "rollback-poker", poker.requestId)
            applied.poker = credit.amount or refund
        end
        sessions.poker = nil
    end

    if applied.blackjack or applied.race or applied.hackingCards or applied.poker then
        PZLinuxTransmitPlayerModData(playerObj)
    end

    return { ok = true, applied = applied, balance = PZLinuxLoadBankBalance(playerObj) }
end

local PZLINUX_ATM_MIN_CASH = PZLinux.Config.ATM.minCash
local PZLINUX_ATM_MAX_CASH = PZLinux.Config.ATM.maxCash

function PZLinuxAtmTransmitModData(atmObject)
    if atmObject and atmObject.transmitModData then
        atmObject:transmitModData()
    end
end

-- Every ATM the "Refill an ATM" contract can target (the atmRefill mission
-- location pool) starts out almost empty -- rolled within
-- AtmRefill.targetCashMin/targetCashMax (1-501 $ by default) instead of the
-- general ATM range -- to make it visually obvious there is barely anything
-- left, so the contract feels like it actually matters. This only affects
-- the INITIAL roll: the ongoing cap (regen ceiling, deposit ceiling) stays
-- the general ATM.maxCash, so a real refill deposit (1,000-5,000 $) can
-- actually raise its balance instead of being clamped right back down to
-- the same near-empty range it started in.
function PZLinuxAtmIsContractTargetLocation(x, y, z)
    local pool = PZLinux.MissionLocations and PZLinux.MissionLocations.pools
        and PZLinux.MissionLocations.pools.atmRefill
    if not pool or not pool.byCityId then return false end
    for _, entries in pairs(pool.byCityId) do
        for _, entry in ipairs(entries) do
            if entry.x == x and entry.y == y and entry.z == z then
                return true
            end
        end
    end
    return false
end

-- Returns rollMin, rollMax (the range for this ATM's very first cash roll)
-- and capMax (the ceiling applied afterward, for clamping/regen/deposits).
local function PZLinuxAtmCashRange(atmObject)
    if atmObject and atmObject.getSquare then
        local square = atmObject:getSquare()
        if square and PZLinuxAtmIsContractTargetLocation(square:getX(), square:getY(), square:getZ()) then
            return tonumber(PZLinux.Config.AtmRefill.targetCashMin) or PZLINUX_ATM_MIN_CASH,
                tonumber(PZLinux.Config.AtmRefill.targetCashMax) or PZLINUX_ATM_MAX_CASH,
                PZLINUX_ATM_MAX_CASH
        end
    end
    return PZLINUX_ATM_MIN_CASH, PZLINUX_ATM_MAX_CASH, PZLINUX_ATM_MAX_CASH
end

-- Finds the currently active (accepted, not yet deposited/completed/
-- cancelled) "Refill an ATM" world contract targeting these exact
-- coordinates, if any. PZLinuxContractsGetWorldData is defined later in
-- this same file/chunk, which is fine: Lua resolves global function calls
-- at call time, not at parse time. Guarded with a nil check so this stays
-- a harmless no-op in contexts (e.g. isolated unit tests) that only load a
-- narrow slice of this file without the contract world-data system.
local function PZLinuxAtmFindActiveRefillContract(x, y, z)
    if not PZLinuxContractsGetWorldData then return nil end
    local worldData = PZLinuxContractsGetWorldData()
    for _, record in pairs(worldData.active) do
        if record.contractId == 13 and record.status == "accepted"
        and record.locationX == x and record.locationY == y and record.locationZ == z then
            return record
        end
    end
    return nil
end

function PZLinuxAtmLoadCash(atmObject)
    if not atmObject then return 0 end

    local rollMin, rollMax, capMax = PZLinuxAtmCashRange(atmObject)
    local modData = atmObject:getModData()

    -- Escape valve for players who've been farming a lot of physical cash
    -- and keep hitting "ATM full" everywhere: every time a fresh "Refill an
    -- ATM" contract targeting this ATM is accepted, its balance drops back
    -- down to a near-empty random roll -- even if it had climbed all the
    -- way to maxCash -- guaranteeing at least one machine on the map has
    -- real deposit room again. This never touches any player's bank
    -- balance; it only resets the machine's own cash. Only applied once
    -- per contract instance (tracked via PZLinuxAtmResetForContract), and
    -- only the server ever does this.
    if not (isClient and isClient()) and atmObject.getSquare then
        local square = atmObject:getSquare()
        if square then
            local activeRefill = PZLinuxAtmFindActiveRefillContract(square:getX(), square:getY(), square:getZ())
            if activeRefill and modData.PZLinuxAtmResetForContract ~= activeRefill.id then
                modData.PZLinuxAtmCash = ZombRand(rollMin, rollMax + 1)
                modData.PZLinuxAtmCashUpdatedHour = getGameTime and getGameTime():getWorldAgeHours() or 0
                modData.PZLinuxAtmResetForContract = activeRefill.id
                modData.PZLinuxAtmWithdrawnTotal = 0
                modData.PZLinuxAtmRegenGranted = 0
                PZLinuxAtmTransmitModData(atmObject)
            end
        end
    end

    local atmCash = tonumber(modData.PZLinuxAtmCash)
    if atmCash == nil then
        if isClient and isClient() then
            return 0
        end
        atmCash = ZombRand(rollMin, rollMax + 1)
        modData.PZLinuxAtmCash = atmCash
        modData.PZLinuxAtmCashUpdatedHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        PZLinuxAtmTransmitModData(atmObject)
    end

    -- Clamping here (not just on new deposits) self-heals any ATM left over
    -- from before maxCash was lowered, or from before deposits were capped
    -- at all -- otherwise a single machine could keep holding an arbitrarily
    -- large sum indefinitely.
    atmCash = math.min(capMax, math.max(0, math.floor(atmCash)))

    -- Cash slowly regenerates over in-game time (a cash truck service,
    -- narratively), but only ever refunds cash actually withdrawn from
    -- THIS specific ATM, up to a hard lifetime cap (restockCap). Without
    -- this, regen would climb toward capMax purely from elapsed world time
    -- -- even on an ATM nobody ever withdraws from -- and every ATM a
    -- player has ever visited once would eventually sit permanently pinned
    -- near its cap, making deposits impossible there forever. Only the
    -- server ever advances this; clients just read the value.
    if not (isClient and isClient()) then
        local currentHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        local lastHour = tonumber(modData.PZLinuxAtmCashUpdatedHour)
        if lastHour == nil then
            modData.PZLinuxAtmCashUpdatedHour = currentHour
        else
            local elapsedHours = currentHour - lastHour
            if elapsedHours > 0 then
                local restockPerHour = tonumber(PZLinux.Config.ATM.restockPerHour) or 0
                local restockCap = tonumber(PZLinux.Config.ATM.restockCap) or 15000
                local withdrawnTotal = tonumber(modData.PZLinuxAtmWithdrawnTotal) or 0
                local regenGranted = tonumber(modData.PZLinuxAtmRegenGranted) or 0
                local regenBudget = math.max(0, math.min(withdrawnTotal, restockCap) - regenGranted)
                if restockPerHour > 0 and regenBudget > 0 and atmCash < capMax then
                    local regenAmount = math.min(elapsedHours * restockPerHour, regenBudget, capMax - atmCash)
                    if regenAmount > 0 then
                        atmCash = atmCash + regenAmount
                        modData.PZLinuxAtmRegenGranted = regenGranted + regenAmount
                    end
                end
                modData.PZLinuxAtmCashUpdatedHour = currentHour
            end
        end
    end

    modData.PZLinuxAtmCash = atmCash
    return atmCash
end

function PZLinuxAtmSaveCash(atmObject, atmCash)
    if not atmObject then return 0 end

    local modData = atmObject:getModData()
    modData.PZLinuxAtmCash = math.max(0, math.floor(tonumber(atmCash) or 0))
    modData.PZLinuxAtmCashUpdatedHour = getGameTime and getGameTime():getWorldAgeHours() or 0
    PZLinuxAtmTransmitModData(atmObject)
    return modData.PZLinuxAtmCash
end

function PZLinuxGetAtmReference(atmObject)
    if not atmObject or not atmObject.getSquare then return nil end

    local square = atmObject:getSquare()
    if not square then return nil end

    local spriteName = nil
    local sprite = atmObject:getSprite()
    if sprite and sprite.getName then
        spriteName = sprite:getName()
    end

    return {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        sprite = spriteName,
    }
end

function PZLinuxFindAtmObject(atmRef)
    if not atmRef or not getCell then return nil end

    local x = tonumber(atmRef.x)
    local y = tonumber(atmRef.y)
    local z = tonumber(atmRef.z)
    if not x or not y or not z then return nil end

    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local sprite = obj and obj:getSprite()
        local spriteName = sprite and sprite:getName()
        if spriteName and (not atmRef.sprite or spriteName == atmRef.sprite) then
            -- Exact match, not a substring search (see ISContextStreetMailBox.lua
            -- for the bug class this avoids: a substring pattern can match an
            -- unrelated sprite that merely starts with the same digits).
            if spriteName == "location_business_bank_01_67"
            or spriteName == "location_business_bank_01_66"
            or spriteName == "location_business_bank_01_65"
            or spriteName == "location_business_bank_01_64" then
                return obj
            end
        end
    end

    return nil
end

function PZLinuxApplyAtmWithdrawal(player, atmRef, amount, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    local atmObject = PZLinuxFindAtmObject(atmRef)
    local previousBalance = PZLinuxLoadBankBalance(player)
    local atmCash = PZLinuxAtmLoadCash(atmObject)

    if amount <= 0 then
        return { ok = false, error = "invalid_amount", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash }
    end
    if not atmObject then
        return { ok = false, error = "atm_not_found", requestId = requestId, amount = amount, balance = previousBalance, atmCash = 0 }
    end
    if previousBalance < amount then
        return { ok = false, error = "not_enough_bank", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash }
    end
    if atmCash < amount then
        return { ok = false, error = "not_enough_atm_cash", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash }
    end

    local added = PZLinuxAddInventoryCash(player, amount)
    if added ~= amount then
        return { ok = false, error = "cash_add_failed", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash }
    end

    local balance = PZLinuxSetBankBalance(player, previousBalance - amount)
    atmCash = PZLinuxAtmSaveCash(atmObject, atmCash - amount)

    -- Tracked so passive regen (see PZLinuxAtmLoadCash) only ever refunds
    -- cash actually taken out of this specific ATM, never more.
    local modData = atmObject:getModData()
    modData.PZLinuxAtmWithdrawnTotal = (tonumber(modData.PZLinuxAtmWithdrawnTotal) or 0) + amount

    print(string.format(
        "[PZLinux ATM] WITHDRAW player=%s amount=%d balance=%d atmCash=%d",
        tostring(PZLinuxGetPlayerKey(player)), amount, balance, atmCash))

    return { ok = true, type = "withdrawal", requestId = requestId, amount = amount, balance = balance, previousBalance = previousBalance, atmCash = atmCash }
end

function PZLinuxGetAtmState(player, atmRef, requestId)
    local atmObject = PZLinuxFindAtmObject(atmRef)
    local balance = PZLinuxLoadBankBalance(player)
    if not atmObject then
        return { ok = false, error = "atm_not_found", requestId = requestId, balance = balance, atmCash = 0 }
    end

    return { ok = true, type = "sync", requestId = requestId, balance = balance, atmCash = PZLinuxAtmLoadCash(atmObject) }
end

function PZLinuxApplyAtmDeposit(player, atmRef, amount, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    local atmObject = PZLinuxFindAtmObject(atmRef)
    local previousBalance = PZLinuxLoadBankBalance(player)
    local atmCash = PZLinuxAtmLoadCash(atmObject)
    local inventoryCash = PZLinuxCountInventoryCash(player)

    if amount <= 0 then
        return { ok = false, error = "invalid_amount", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = inventoryCash }
    end
    if not atmObject then
        return { ok = false, error = "atm_not_found", requestId = requestId, amount = amount, balance = previousBalance, atmCash = 0, inventoryCash = inventoryCash }
    end
    if inventoryCash < amount then
        print(string.format(
            "[PZLinux ATM] DEPOSIT REJECTED player=%s requested=%d detectedInventoryCash=%d -- if this looks wrong, check for a money-reskin mod whose item isn't being recognized as cash (see PZLinux.CustomMoneyItems in sandbox-options.txt)",
            tostring(PZLinuxGetPlayerKey(player)), amount, inventoryCash))
        return { ok = false, error = "not_enough_inventory_cash", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = inventoryCash }
    end
    -- Capped, not just clamped on load: without this, one player could
    -- deposit an arbitrarily large sum for another player to withdraw
    -- elsewhere -- an easy, untraceable way to hand over money in MP.
    local _, _, maxCashForThisAtm = PZLinuxAtmCashRange(atmObject)
    if atmCash + amount > maxCashForThisAtm then
        return { ok = false, error = "atm_full", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = inventoryCash }
    end

    local removed = PZLinuxRemoveInventoryCash(player, amount)
    if removed ~= amount then
        return { ok = false, error = "cash_remove_failed", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = PZLinuxCountInventoryCash(player) }
    end

    local balance = PZLinuxSetBankBalance(player, previousBalance + amount)
    atmCash = PZLinuxAtmSaveCash(atmObject, atmCash + amount)

    print(string.format(
        "[PZLinux ATM] DEPOSIT player=%s amount=%d balance=%d atmCash=%d",
        tostring(PZLinuxGetPlayerKey(player)), amount, balance, atmCash))

    return { ok = true, type = "deposit", requestId = requestId, amount = amount, balance = balance, previousBalance = previousBalance, atmCash = atmCash, inventoryCash = PZLinuxCountInventoryCash(player) }
end

function PZLinuxNextRequestId(prefix)
    PZLinux.nextRequestId = (PZLinux.nextRequestId or 0) + 1
    local tick = 0
    if getGameTime then
        tick = math.floor(getGameTime():getWorldAgeHours() * 3600)
    end
    return tostring(prefix or "pzlinux") .. "-" .. tostring(tick) .. "-" .. tostring(PZLinux.nextRequestId)
end

function PZLinuxRegisterCallback(requestId, callback)
    if requestId and type(callback) == "function" then
        PZLinux.callbacks[requestId] = callback
    end
end

function PZLinuxDispatchCallback(args)
    if not args or not args.requestId then return end

    local callback = PZLinux.callbacks[args.requestId]
    if callback then
        PZLinux.callbacks[args.requestId] = nil
        callback(args)
    end
end

function PZLinuxSendClientCommand(command, args)
    if isClient and isClient() and sendClientCommand then
        sendClientCommand("PZLinux", command, args or {})
        return true
    end
    return false
end

function PZLinuxRequestBankSync(player, callback)
    local requestId = PZLinuxNextRequestId("bank-sync")
    PZLinuxRegisterCallback(requestId, callback)

    if PZLinuxSendClientCommand("PZLinuxBankRequestSync", { requestId = requestId }) then
        return requestId
    end

    PZLinuxDispatchCallback({ ok = true, requestId = requestId, balance = PZLinuxLoadBankBalance(player), reason = "sync" })
    return requestId
end

function PZLinuxRequestBankDebit(player, amount, reason, callback)
    local requestId = PZLinuxNextRequestId("bank-debit")
    PZLinuxRegisterCallback(requestId, callback)

    if PZLinuxSendClientCommand("PZLinuxBankDebit", { requestId = requestId, amount = amount, reason = reason }) then
        return requestId
    end

    PZLinuxDispatchCallback(PZLinuxApplyBankDebit(player, amount, reason, requestId))
    return requestId
end

function PZLinuxRequestAtmSync(player, atmObject, callback)
    local requestId = PZLinuxNextRequestId("atm-sync")
    local atmRef = PZLinuxGetAtmReference(atmObject)
    PZLinuxRegisterCallback(requestId, callback)

    if PZLinuxSendClientCommand("PZLinuxAtmRequestSync", { requestId = requestId, atm = atmRef }) then
        return requestId
    end

    PZLinuxDispatchCallback(PZLinuxGetAtmState(player, atmRef, requestId))
    return requestId
end

function PZLinuxRequestAtmWithdrawal(player, atmObject, amount, callback)
    local requestId = PZLinuxNextRequestId("atm-withdrawal")
    local atmRef = PZLinuxGetAtmReference(atmObject)
    PZLinuxRegisterCallback(requestId, callback)

    if PZLinuxSendClientCommand("PZLinuxAtmWithdrawal", { requestId = requestId, atm = atmRef, amount = amount }) then
        return requestId
    end

    PZLinuxDispatchCallback(PZLinuxApplyAtmWithdrawal(player, atmRef, amount, requestId))
    return requestId
end

function PZLinuxRequestAtmDeposit(player, atmObject, amount, callback)
    local requestId = PZLinuxNextRequestId("atm-deposit")
    local atmRef = PZLinuxGetAtmReference(atmObject)
    PZLinuxRegisterCallback(requestId, callback)

    if PZLinuxSendClientCommand("PZLinuxAtmDeposit", { requestId = requestId, atm = atmRef, amount = amount }) then
        return requestId
    end

    PZLinuxDispatchCallback(PZLinuxApplyAtmDeposit(player, atmRef, amount, requestId))
    return requestId
end

require "PZLinux/PZLinuxDarkWeb"

local PZLINUX_BLACKJACK_RANKS = PZLinux.Config.Blackjack.ranks
local PZLINUX_BLACKJACK_SUITS = PZLinux.Config.Blackjack.suits
local PZLINUX_BLACKJACK_RANK_LABELS = { A = "A", T = "10", J = "J", Q = "Q", K = "K" }
local PZLINUX_BLACKJACK_SUIT_LABELS = { C = "C", D = "D", H = "H", S = "S" }

function PZLinuxBlackjackCreateDeck()
    local deck = {}
    for _, suit in ipairs(PZLINUX_BLACKJACK_SUITS) do
        for _, rank in ipairs(PZLINUX_BLACKJACK_RANKS) do
            table.insert(deck, {
                rank = rank,
                suit = suit,
                label = (PZLINUX_BLACKJACK_RANK_LABELS[rank] or rank) .. (PZLINUX_BLACKJACK_SUIT_LABELS[suit] or suit),
            })
        end
    end

    for i = #deck, 2, -1 do
        local j = ZombRand(1, i + 1)
        deck[i], deck[j] = deck[j], deck[i]
    end

    return deck
end

function PZLinuxBlackjackDraw(deck)
    if not deck or #deck == 0 then return nil end
    return table.remove(deck, #deck)
end

function PZLinuxBlackjackCardValue(card)
    if not card then return 0 end
    if card.rank == "A" then return 11 end
    if card.rank == "K" or card.rank == "Q" or card.rank == "J" then return 10 end
    return tonumber(card.rank) or 0
end

function PZLinuxBlackjackHandValue(hand)
    local value = 0
    local aces = 0

    for _, card in ipairs(hand or {}) do
        value = value + PZLinuxBlackjackCardValue(card)
        if card.rank == "A" then
            aces = aces + 1
        end
    end

    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end

    return value
end

function PZLinuxBlackjackIsNatural(hand)
    return hand and #hand == 2 and PZLinuxBlackjackHandValue(hand) == 21
end

function PZLinuxBlackjackCopyHand(hand, hideHole)
    local copy = {}
    for index, card in ipairs(hand or {}) do
        if hideHole and index > 1 then
            table.insert(copy, { rank = "?", suit = "?", label = "??" })
        else
            table.insert(copy, { rank = card.rank, suit = card.suit, label = card.label })
        end
    end
    return copy
end

function PZLinuxBlackjackOutcomeMessage(outcome)
    if outcome == "blackjack" then return "BLACKJACK!" end
    if outcome == "win" then return "You win!" end
    if outcome == "push" then return "Push." end
    if outcome == "lose" then return "You lose." end
    return "Playing..."
end

function PZLinuxBlackjackBuildState(player, session)
    local hideDealerHole = not session.finished
    return {
        ok = true,
        requestId = session.requestId,
        tableId = session.tableId,
        bet = session.bet,
        balance = PZLinuxLoadBankBalance(player),
        previousBalance = session.previousBalance,
        payout = session.payout or 0,
        outcome = session.outcome,
        message = PZLinuxBlackjackOutcomeMessage(session.outcome),
        finished = session.finished == true,
        playerHand = PZLinuxBlackjackCopyHand(session.playerHand, false),
        dealerHand = PZLinuxBlackjackCopyHand(session.dealerHand, hideDealerHole),
        playerValue = PZLinuxBlackjackHandValue(session.playerHand),
        dealerValue = hideDealerHole and PZLinuxBlackjackCardValue(session.dealerHand[1]) or PZLinuxBlackjackHandValue(session.dealerHand),
        dealerHidden = hideDealerHole,
    }
end

function PZLinuxBlackjackFinish(player, session, outcome)
    session.finished = true
    session.outcome = outcome
    session.payout = 0

    if outcome == "blackjack" then
        session.payout = math.floor(session.bet * 2.5)
    elseif outcome == "win" then
        session.payout = session.bet * 2
    elseif outcome == "push" then
        session.payout = session.bet
    end

    if session.payout > 0 then
        PZLinuxApplyBankCredit(player, session.payout, "blackjack", session.requestId)
    end

    -- Temporary diagnostic logging, see PZLinuxBlackjackStart. Logs the
    -- final outcome, bet and payout for every hand, so a server log can be
    -- matched up against the START logs to see exactly which hands did or
    -- didn't actually move money. Safe to remove once the root cause is
    -- confirmed.
    print(string.format(
        "[PZLinux Blackjack] FINISH player=%s requestId=%s outcome=%s bet=%d payout=%d",
        tostring(PZLinuxGetPlayerKey(player)), tostring(session.requestId), tostring(outcome),
        session.bet, session.payout))

    PZLinuxClearInterruptedSession(player, "blackjack")
    local state = PZLinuxBlackjackBuildState(player, session)
    PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)] = nil
    return state
end

function PZLinuxBlackjackStart(player, tableId, amount, requestId)
    amount = PZLinuxNormalizeMoney(amount)

    -- Fixed-stakes tables (like the Poker lobbies): each table caps how
    -- much a single hand can risk, regardless of bankroll, so a lucky
    -- streak can't compound a small bet into an enormous one in just a
    -- couple of hands the way an unbounded bet could. See
    -- PZLinuxBlackjackGetTable in PZLinuxConfig.lua.
    local tableDef = PZLinuxBlackjackGetTable(tableId)
    if not tableDef then
        return { ok = false, error = "invalid_table", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if amount < tableDef.minBet or amount > tableDef.maxBet then
        return {
            ok = false,
            error = "bet_out_of_range",
            requestId = requestId,
            tableId = tableId,
            minBet = tableDef.minBet,
            maxBet = tableDef.maxBet,
            balance = PZLinuxLoadBankBalance(player),
        }
    end

    -- Temporary diagnostic logging for a reported bug (bets sometimes not
    -- taken, letting several hands be played "for free"). Logs whether a
    -- previous session was still sitting around unfinished when a new hand
    -- starts, and the exact debit outcome/balance for every single hand.
    -- Safe to remove once the root cause is confirmed.
    local staleSession = PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)]
    print(string.format(
        "[PZLinux Blackjack] START player=%s requestId=%s table=%s amount=%d staleSessionPresent=%s staleSessionFinished=%s",
        tostring(PZLinuxGetPlayerKey(player)), tostring(requestId), tostring(tableId), amount,
        tostring(staleSession ~= nil), tostring(staleSession and staleSession.finished)))

    local debit = PZLinuxApplyBankDebit(player, amount, "blackjack", requestId)
    print(string.format(
        "[PZLinux Blackjack] START DEBIT player=%s requestId=%s ok=%s balanceAfter=%s",
        tostring(PZLinuxGetPlayerKey(player)), tostring(requestId), tostring(debit.ok), tostring(debit.balance)))
    if not debit.ok then
        debit.game = "blackjack"
        return debit
    end

    PZLinuxRegisterInterruptedSession(player, "blackjack", {
        amount = amount,
        requestId = requestId,
    })

    local deck = PZLinuxBlackjackCreateDeck()
    local session = {
        requestId = requestId,
        tableId = tableId,
        bet = amount,
        previousBalance = debit.previousBalance,
        deck = deck,
        playerHand = { PZLinuxBlackjackDraw(deck), PZLinuxBlackjackDraw(deck) },
        dealerHand = { PZLinuxBlackjackDraw(deck), PZLinuxBlackjackDraw(deck) },
        finished = false,
    }

    PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)] = session

    local playerNatural = PZLinuxBlackjackIsNatural(session.playerHand)
    local dealerNatural = PZLinuxBlackjackIsNatural(session.dealerHand)
    if playerNatural and dealerNatural then
        return PZLinuxBlackjackFinish(player, session, "push")
    elseif playerNatural then
        return PZLinuxBlackjackFinish(player, session, "blackjack")
    elseif dealerNatural then
        return PZLinuxBlackjackFinish(player, session, "lose")
    end

    return PZLinuxBlackjackBuildState(player, session)
end

function PZLinuxBlackjackHit(player, requestId)
    local session = PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)]
    if not session then
        return { ok = false, error = "no_blackjack_session", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    session.requestId = requestId or session.requestId
    table.insert(session.playerHand, PZLinuxBlackjackDraw(session.deck))
    if PZLinuxBlackjackHandValue(session.playerHand) > 21 then
        return PZLinuxBlackjackFinish(player, session, "lose")
    end

    return PZLinuxBlackjackBuildState(player, session)
end

function PZLinuxBlackjackStand(player, requestId)
    local session = PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)]
    if not session then
        return { ok = false, error = "no_blackjack_session", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    session.requestId = requestId or session.requestId
    while PZLinuxBlackjackHandValue(session.dealerHand) < 17 do
        table.insert(session.dealerHand, PZLinuxBlackjackDraw(session.deck))
    end

    local playerValue = PZLinuxBlackjackHandValue(session.playerHand)
    local dealerValue = PZLinuxBlackjackHandValue(session.dealerHand)

    if dealerValue > 21 or playerValue > dealerValue then
        return PZLinuxBlackjackFinish(player, session, "win")
    elseif playerValue == dealerValue then
        return PZLinuxBlackjackFinish(player, session, "push")
    end

    return PZLinuxBlackjackFinish(player, session, "lose")
end

-- Closing/minimizing the betting panel mid-hand used to just abandon the
-- hand outright: Race and Poker are settled first (settleRaceBeforeClose /
-- cashOutPokerBeforeClose), but Blackjack had no equivalent, so the
-- in-progress session was silently left behind server-side. If the player
-- reopened the panel and dealt a new hand, PZLinuxBlackjackStart would
-- overwrite that orphaned session without ever crediting back the bet it
-- had already taken -- money debited for a hand that was never played to
-- a result and never refunded. Treated as a push (the bet is simply
-- returned) since walking away isn't a loss the player actually played
-- out, and the dealer's hidden hole card is never revealed for it either.
function PZLinuxBlackjackForfeit(player, requestId)
    local session = PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)]
    if not session or session.finished then
        return { ok = true, requestId = requestId, forfeited = false, balance = PZLinuxLoadBankBalance(player) }
    end

    local state = PZLinuxBlackjackFinish(player, session, "push")
    state.forfeited = true
    return state
end

function PZLinuxRequestBlackjackForfeit(player, callback)
    local requestId = PZLinuxNextRequestId("blackjack-forfeit")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxBlackjackForfeit", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxBlackjackForfeit(player, requestId))
    return requestId
end

function PZLinuxRequestBlackjackStart(player, tableId, amount, callback)
    local requestId = PZLinuxNextRequestId("blackjack-start")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxBlackjackStart", { requestId = requestId, tableId = tableId, amount = amount }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxBlackjackStart(player, tableId, amount, requestId))
    return requestId
end

function PZLinuxRequestBlackjackHit(player, callback)
    local requestId = PZLinuxNextRequestId("blackjack-hit")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxBlackjackHit", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxBlackjackHit(player, requestId))
    return requestId
end

function PZLinuxRequestBlackjackStand(player, callback)
    local requestId = PZLinuxNextRequestId("blackjack-stand")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxBlackjackStand", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxBlackjackStand(player, requestId))
    return requestId
end

function PZLinuxRaceCreateCard(player, requestId)
    local playerKey = PZLinuxGetPlayerKey(player)
    local activeSession = PZLinux.raceSessions[playerKey]
    if activeSession and activeSession.status == "running" then
        return { ok = false, error = "race_in_progress", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    local runners = PZLinuxRaceGenerateCard(PZLinuxRaceRunnerPool, PZLinux.Race.runnerCount)
    local pool = PZLinuxRaceCreateBettingPool(runners)

    local session = { requestId = requestId, runners = runners, pool = pool }
    PZLinux.raceSessions[playerKey] = session

    return {
        ok = true,
        requestId = requestId,
        runners = runners,
        pool = pool,
        balance = PZLinuxLoadBankBalance(player),
    }
end

function PZLinuxRaceStart(player, selectedRunner, amount, requestId)
    selectedRunner = tonumber(selectedRunner)
    amount = PZLinuxNormalizeMoney(amount)

    local session = PZLinux.raceSessions[PZLinuxGetPlayerKey(player)]
    if not session or type(session.runners) ~= "table" then
        return { ok = false, error = "no_race_card", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    if not selectedRunner or selectedRunner < 1 or selectedRunner > #session.runners then
        return { ok = false, error = "invalid_runner", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if not session.pool or amount > (tonumber(session.pool.maximumBet) or 0) then
        return {
            ok = false,
            error = "bet_above_pool_limit",
            requestId = requestId,
            maximumBet = session.pool and session.pool.maximumBet or 0,
            balance = PZLinuxLoadBankBalance(player),
        }
    end

    local debit = PZLinuxApplyBankDebit(player, amount, "zombie-race", requestId)
    if not debit.ok then
        debit.game = "zombie-race"
        debit.runners = session.runners
        return debit
    end

    local winnerId = PZLinuxRaceSimulateWinner(session.runners)
    local winner = session.runners[winnerId]
    local selected = session.runners[selectedRunner]
    local finalOdds = PZLinuxRaceCalculateFinalOdds(
        amount,
        session.pool.poolTotal,
        selected.poolStake,
        session.pool.takeoutRate
    )
    local payout = PZLinuxRaceCalculatePayout(
        amount,
        session.pool.poolTotal,
        winner.poolStake,
        winnerId == selectedRunner,
        session.pool.takeoutRate
    )

    session.raceId = tostring(requestId or PZLinuxNextRequestId("race"))
    session.requestId = requestId
    session.selectedRunner = selectedRunner
    session.amount = amount
    session.previousBalance = debit.previousBalance
    session.winnerId = winnerId
    session.finalOdds = finalOdds
    session.payout = payout
    session.outcome = payout > 0 and "win" or "lose"
    session.status = "running"
    PZLinuxRegisterInterruptedSession(player, "race", {
        amount = amount,
        requestId = requestId,
    })

    print(string.format(
        "[PZLinux Race] BET player=%s amount=%d selectedRunner=%d winnerId=%d outcome=%s payout=%d balance=%d",
        tostring(PZLinuxGetPlayerKey(player)), amount, selectedRunner, winnerId, tostring(session.outcome),
        payout, debit.balance))

    return {
        ok = true,
        requestId = requestId,
        raceId = session.raceId,
        selectedRunner = selectedRunner,
        amount = amount,
        previousBalance = debit.previousBalance,
        balance = debit.balance,
        runners = session.runners,
        pool = session.pool,
        finalOdds = finalOdds,
        winnerId = winnerId,
        status = session.status,
    }
end

function PZLinuxRaceFinish(player, raceId, requestId)
    local playerKey = PZLinuxGetPlayerKey(player)
    local session = PZLinux.raceSessions[playerKey]
    if not session or session.status ~= "running" then
        return { ok = false, error = "no_race_in_progress", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end
    if tostring(session.raceId) ~= tostring(raceId or "") then
        return { ok = false, error = "invalid_race", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    session.status = "settled"
    if session.payout > 0 then
        PZLinuxApplyBankCredit(player, session.payout, "zombie-race", requestId)
    end

    print(string.format(
        "[PZLinux Race] SETTLE player=%s raceId=%s payout=%d balance=%d",
        tostring(playerKey), tostring(session.raceId), session.payout, PZLinuxLoadBankBalance(player)))

    PZLinuxClearInterruptedSession(player, "race")
    PZLinux.raceSessions[playerKey] = nil
    return {
        ok = true,
        requestId = requestId,
        raceId = session.raceId,
        selectedRunner = session.selectedRunner,
        amount = session.amount,
        previousBalance = session.previousBalance,
        balance = PZLinuxLoadBankBalance(player),
        winnerId = session.winnerId,
        finalOdds = session.finalOdds,
        payout = session.payout,
        outcome = session.outcome,
        status = session.status,
    }
end

function PZLinuxRequestRaceCard(player, callback)
    local requestId = PZLinuxNextRequestId("race-card")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRaceCard", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRaceCreateCard(player, requestId))
    return requestId
end

function PZLinuxRequestRaceStart(player, selectedRunner, amount, callback)
    local requestId = PZLinuxNextRequestId("race-start")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRaceStart", { requestId = requestId, selectedRunner = selectedRunner, amount = amount }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRaceStart(player, selectedRunner, amount, requestId))
    return requestId
end

function PZLinuxRequestRaceFinish(player, raceId, callback)
    local requestId = PZLinuxNextRequestId("race-finish")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRaceFinish", { requestId = requestId, raceId = raceId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRaceFinish(player, raceId, requestId))
    return requestId
end

function PZLinuxRequestPokerStart(player, lobbyId, buyIn, callback)
    local requestId = PZLinuxNextRequestId("poker-start")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxPokerStart", { requestId = requestId, lobbyId = lobbyId, buyIn = buyIn }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxPokerCreateSession(player, lobbyId, buyIn, requestId))
    return requestId
end

function PZLinuxRequestPokerAction(player, sessionId, action, amount, callback)
    local requestId = PZLinuxNextRequestId("poker-action")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxPokerAction", { requestId = requestId, sessionId = sessionId, action = action, amount = amount }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxPokerAction(player, action, amount, sessionId, requestId))
    return requestId
end

function PZLinuxRequestPokerCashOut(player, sessionId, callback)
    local requestId = PZLinuxNextRequestId("poker-cashout")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxPokerCashOut", { requestId = requestId, sessionId = sessionId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxPokerCashOut(player, sessionId, requestId))
    return requestId
end

function PZLinuxRequestPokerRestoreSession(player, callback)
    local requestId = PZLinuxNextRequestId("poker-restore")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxPokerRestoreSession", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxPokerRestoreSession(player, requestId))
    return requestId
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= "PZLinux" then return end
        if command == "PZLinuxContractZombieRemoved" then
            PZLinuxRemoveReplicatedZombie(args and args.target)
            return
        end
        if command == "PZLinuxContractDeadBodyRemoved" then
            PZLinuxRemoveReplicatedDeadBody(args and args.target)
            return
        end
        if command == "PZLinuxBankSync"
        or command == "PZLinuxBankDebitResult"
        or command == "PZLinuxAtmSyncResult"
        or command == "PZLinuxAtmTransactionResult"
        or command == "PZLinuxBlackjackState"
        or command == "PZLinuxRaceCardResult"
        or command == "PZLinuxRaceStartResult"
        or command == "PZLinuxRaceFinishResult"
        or command == "PZLinuxRaceScheduleResult"
        or command == "PZLinuxPokerState"
        or command == "PZLinuxDarkWebOffersResult"
        or command == "PZLinuxDarkWebBuyResult"
        or command == "PZLinuxDarkWebSellOffersResult"
        or command == "PZLinuxDarkWebSellResult"
        or command == "PZLinuxDarkWebRedeemSalesResult"
        or command == "PZLinuxDarkWebDeliverOrdersResult"
        or command == "PZLinuxTrainingStateResult"
        or command == "PZLinuxTrainingPurchaseResult"
        or command == "PZLinuxTrainingTickResult"
        or command == "PZLinuxTradingSnapshotResult"
        or command == "PZLinuxTradingBuyResult"
        or command == "PZLinuxTradingSellResult"
        or command == "PZLinuxContractsBoardResult"
        or command == "PZLinuxContractPreviewResult"
        or command == "PZLinuxContractSyncResult"
        or command == "PZLinuxContractAcceptResult"
        or command == "PZLinuxContractCancelResult"
        or command == "PZLinuxContractDepositResult"
        or command == "PZLinuxContractAtmRefillDepositResult"
        or command == "PZLinuxContractCompleteResult"
        or command == "PZLinuxContractCompletionAckResult"
        or command == "PZLinuxContractWorldEventResult"
        or command == "PZLinuxContractAdminForceResult"
        or command == "PZLinuxContractAdminAddFundsResult"
        -- This one was never listed here at all -- in real MP (not solo,
        -- which calls the callback directly without going through this
        -- dispatcher) the "Force a random mail mission" admin action would
        -- silently never report back to the client, even though the
        -- server-side mail really was created. Found while adding the
        -- three admin-balance results just below.
        or command == "PZLinuxContractAdminForceMailResult"
        or command == "PZLinuxAdminListOnlinePlayersResult"
        or command == "PZLinuxAdminGetPlayerBalanceResult"
        or command == "PZLinuxAdminSetPlayerBalanceResult"
        or command == "PZLinuxRequestOrderResult"
        or command == "PZLinuxRequestGetCategoriesResult"
        or command == "PZLinuxRequestRejectCategoryResult"
        or command == "PZLinuxRequestDeliverResult"
        or command == "PZLinuxSellGetOffersResult"
        or command == "PZLinuxSellNegotiateResult"
        or command == "PZLinuxSellSellResult"
        or command == "PZLinuxSellRedeemPackageResult"
        or command == "PZLinuxRequestSpawnVehicleResult"
        or command == "PZLinuxRequestConfirmVehicleResult"
        or command == "PZLinuxMailboxStateResult"
        or command == "PZLinuxReputationSnapshotResult"
        or command == "PZLinuxMailAcceptResult"
        or command == "PZLinuxMailDeleteResult"
        or command == "PZLinuxMailCompleteResult"
        or command == "PZLinuxMailGenerateResult"
        or command == "PZLinuxHackingStartResult"
        or command == "PZLinuxHackingAutoResult"
        or command == "PZLinuxHackingGuessResult"
        or command == "PZLinuxHackingTransferResult" then
            if args and args.balance then
                PZLinuxSetBankBalance(PZLinuxGetPlayer(), args.balance)
            end
            if args and args.tradingSnapshot then
                PZLinuxTradingStoreSnapshot(args.tradingSnapshot)
            end
            if args and args.worldContractId then
                local playerObj = PZLinuxGetPlayer()
                local modData = playerObj and playerObj:getModData()
                if modData then modData.PZLinuxContractId = args.worldContractId end
            end
            if args and args.reputation ~= nil then
                local _, pzlinux = PZLinuxGetModData(PZLinuxGetPlayer())
                if pzlinux then pzlinux.player.reputation = tonumber(args.reputation) or pzlinux.player.reputation end
            end
            if (command == "PZLinuxContractSyncResult"
            or command == "PZLinuxContractAcceptResult"
            or command == "PZLinuxContractDepositResult"
            or command == "PZLinuxContractAtmRefillDepositResult"
            or command == "PZLinuxContractWorldEventResult") and args then
                local playerObj = PZLinuxGetPlayer()
                local modData = playerObj and playerObj:getModData()
                if modData then
                    if args.worldContractId ~= nil then modData.PZLinuxContractId = args.worldContractId end
                    if args.worldStatus ~= nil then modData.PZLinuxContractWorldStatus = args.worldStatus end
                    if args.activeContract ~= nil then modData.PZLinuxActiveContract = args.activeContract end
                    if args.zombieTarget ~= nil then modData.PZLinuxOnZombieToKill = args.zombieTarget end
                    if args.zombieCount ~= nil then modData.PZLinuxOnZombieDead = args.zombieCount end
                    if args.contractManhunt ~= nil then modData.PZLinuxContractManhunt = args.contractManhunt end
                    if args.contractCargo ~= nil then modData.PZLinuxContractCargo = args.contractCargo end
                    if args.contractProtect ~= nil then modData.PZLinuxContractProtect = args.contractProtect end
                    if args.contractPickUp ~= nil then modData.PZLinuxContractPickUp = args.contractPickUp end
                    if args.contractBlood ~= nil then modData.PZLinuxContractBlood = args.contractBlood end
                    if args.contractCapture ~= nil then modData.PZLinuxContractCapture = args.contractCapture end
                    if args.contractKillZombie ~= nil then modData.PZLinuxContractKillZombie = args.contractKillZombie end
                    if args.contractCar ~= nil then modData.PZLinuxContractCar = args.contractCar end
                    if args.contractMedical ~= nil then modData.PZLinuxContractMedical = args.contractMedical end
                    if args.contractWeapon ~= nil then modData.PZLinuxContractWeapon = args.contractWeapon end
                    if args.contractSendComputer ~= nil then modData.PZLinuxContractSendComputer = args.contractSendComputer end
                    if args.contractSendFridge ~= nil then modData.PZLinuxContractSendFridge = args.contractSendFridge end
                    if args.contractAtmRefill ~= nil then modData.PZLinuxContractAtmRefill = args.contractAtmRefill end
                    if args.atmAmount ~= nil then modData.PZLinuxContractAtmAmount = args.atmAmount end
                    if args.info ~= nil then modData.PZLinuxContractInfo = args.info end
                    if args.infoName ~= nil then modData.PZLinuxContractInfoName = args.infoName end
                    if args.infoCount ~= nil then modData.PZLinuxContractInfoCount = args.infoCount end
                    if args.contractId ~= nil then modData.PZLinuxContractTypeId = args.contractId end
                    if args.locationX ~= nil then modData.PZLinuxContractLocationX = args.locationX end
                    if args.locationY ~= nil then modData.PZLinuxContractLocationY = args.locationY end
                    if args.locationZ ~= nil then modData.PZLinuxContractLocationZ = args.locationZ end
                end
            end
            -- A paid vehicle Request only sets PZLinuxOnItemRequestCar/location
            -- fields in the server's own modData copy. Every other command above
            -- explicitly mirrors its result fields into the client's local
            -- modData; this one did not, so in real MP the client's background
            -- spawn poll (checkAndSpawnVehicle) never saw the pending request and
            -- nothing ever spawned, even though the order itself (debit, map
            -- marker from the raw response) worked fine.
            if command == "PZLinuxRequestOrderResult" and args and args.ok
            and tonumber(args.contractId) == 9 then
                local playerObj = PZLinuxGetPlayer()
                local modData = playerObj and playerObj:getModData()
                if modData then
                    modData.PZLinuxOnItemRequestCar = 1
                    modData.PZLinuxActiveRequest = 1
                    if args.vehicleName ~= nil then modData.PZLinuxOnItemRequestCarName = args.vehicleName end
                    if args.locationX ~= nil then modData.PZLinuxRequestLocationX = args.locationX end
                    if args.locationY ~= nil then modData.PZLinuxRequestLocationY = args.locationY end
                    if args.locationZ ~= nil then modData.PZLinuxRequestLocationZ = args.locationZ end
                    if args.deliveryId ~= nil then modData.PZLinuxRequestVehicleDeliveryId = args.deliveryId end
                end
            end
            PZLinuxDispatchCallback(args)
        end
    end)
end

function PZLinuxRequestsGetDefinition(contractId)
    return PZLinuxRequestDefinitions[tonumber(contractId)]
end

function PZLinuxRequestsContains(entries, baseName)
    for _, entry in ipairs(entries or {}) do
        local value = type(entry) == "table" and entry.baseName or entry
        if value == baseName then return entry end
    end
    return nil
end

function PZLinuxRequestsFindVehicleLocation(x, y, z)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z) or 0
    if not x or not y then return nil end

    for _, location in ipairs(PZLinuxRequestVehicleLocations or {}) do
        if tonumber(location.x) == x and tonumber(location.y) == y and tonumber(location.z or 0) == z then
            return location
        end
    end
    return nil
end

function PZLinuxRequestsSanitizeItems(definition, items)
    local clean = {}
    for _, item in ipairs(items or {}) do
        local itemName = type(item) == "table" and item.name or item
        if PZLinuxRequestsContains(definition.items, itemName) then
            table.insert(clean, { name = itemName })
        end
        if #clean >= 6 then break end
    end
    return clean
end

function PZLinuxRequestsBuildOrder(player, state, requestId)
    state = state or {}
    local contractId = tonumber(state.contractId)
    local definition = PZLinuxRequestsGetDefinition(contractId)
    if not definition then
        return { ok = false, error = "invalid_request", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    local unitPrice = PZLinuxRequestsCalculateUnitPrice(player, definition)
    if contractId == 9 then
        local vehicleName = state.vehicleName
        local vehicle = PZLinuxRequestsContains(definition.vehicles, vehicleName)
        if not vehicle then
            return { ok = false, error = "invalid_vehicle", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
        end
        local location = PZLinuxRequestsFindVehicleLocation(state.locationX, state.locationY, state.locationZ)
        if not location then
            return { ok = false, error = "invalid_vehicle_location", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
        end
        local amount = math.ceil(unitPrice * (tonumber(vehicle.delta) or 1))
        return {
            ok = true,
            requestId = requestId,
            contractId = contractId,
            amount = amount,
            vehicleName = vehicleName,
            locationX = location.x,
            locationY = location.y,
            locationZ = location.z or 0,
            locationName = location.name or "",
            balance = PZLinuxLoadBankBalance(player),
        }
    end

    local cleanItems = PZLinuxRequestsSanitizeItems(definition, state.items)
    if #cleanItems == 0 then
        return { ok = false, error = "invalid_request_items", requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    end

    return {
        ok = true,
        requestId = requestId,
        contractId = contractId,
        amount = #cleanItems * unitPrice,
        items = cleanItems,
        balance = PZLinuxLoadBankBalance(player),
    }
end

-- A counter that increments every 24 in-game hours since world start. Used
-- (instead of a rolling real-time or calendar-day cooldown) so a category's
-- daily roll -- or a failed/declined Request -- is blocked only "for the
-- rest of today" and always retriable once the game day changes: checking a
-- day counter difference instead of "is it still the same calendar day"
-- avoids letting a player fail right before midnight and retry a couple of
-- in-game minutes later at 00:01.
function PZLinuxRequestsCurrentGameDay()
    if not getGameTime then return 0 end
    return math.floor(getGameTime():getWorldAgeHours() / 24)
end

-- All catalog category ids (13 item categories plus the vehicle one, id 9).
local function PZLinuxRequestsAllCategoryIds()
    local ids = {}
    for contractId in pairs(PZLinuxRequestDefinitions or {}) do
        table.insert(ids, tonumber(contractId))
    end
    table.sort(ids)
    return ids
end

-- The chance of finding a seller shrinks as the world ages (fewer survivors
-- left): it starts high and ramps linearly down to a harsher floor over a
-- configurable number of in-game days, then stays capped there.
function PZLinuxRequestsCurrentCategoryAvailableChancePercent()
    local cfg = PZLinux.Config.Requests
    local startPercent = tonumber(cfg.unavailableChancePercentStart) or 50
    local maxPercent = tonumber(cfg.unavailableChancePercentMax) or 75
    local rampDays = math.max(1, tonumber(cfg.unavailableRampGameDays) or 30)
    local progress = math.min(1, PZLinuxRequestsCurrentGameDay() / rampDays)
    local unavailablePercent = startPercent + (maxPercent - startPercent) * progress
    return 100 - unavailablePercent
end

-- Rolls, once per game day and cached in the player's own modData, whether
-- each category has a seller willing to trade at all today -- deliberately
-- rare, so finding one feels like an actual event instead of an on-demand
-- shop. The roll is decided up front for every category at once so the
-- Request menu can show only what is actually available today (a quick
-- check), rather than making the player "search" one at a time.
-- Returns the player's modData, freshly rolled for today if needed. Callers
-- must reuse this same reference rather than calling getModData() again, so
-- everything within one logical operation sees the same roll.
local function PZLinuxRequestsEnsureCategoryRoll(playerObj)
    local modData = playerObj:getModData()
    local currentDay = PZLinuxRequestsCurrentGameDay()
    if tonumber(modData.PZLinuxRequestCategoryDay) == currentDay
    and type(modData.PZLinuxRequestCategoryAvailable) == "table" then
        return modData
    end

    local chancePercent = PZLinuxRequestsCurrentCategoryAvailableChancePercent()
    local available = {}
    for _, contractId in ipairs(PZLinuxRequestsAllCategoryIds()) do
        available[tostring(contractId)] = (ZombRand(1, 101) <= chancePercent) and 1 or 0
    end
    modData.PZLinuxRequestCategoryDay = currentDay
    modData.PZLinuxRequestCategoryAvailable = available
    -- A category already bought from or explicitly refused today is hidden
    -- until the next roll, exactly like one where no seller showed up at
    -- all -- the same seller doesn't have infinite stock to sell twice.
    modData.PZLinuxRequestCategoryConsumed = {}
    PZLinuxTransmitPlayerModData(playerObj)
    return modData
end

-- True only if today's roll found a seller for this category AND the player
-- has not already bought from or declined that offer today.
function PZLinuxRequestsIsCategoryAvailable(playerObj, contractId)
    local modData = PZLinuxRequestsEnsureCategoryRoll(playerObj)
    local key = tostring(tonumber(contractId))
    local rolled = tonumber(modData.PZLinuxRequestCategoryAvailable[key]) == 1
    local consumed = modData.PZLinuxRequestCategoryConsumed and modData.PZLinuxRequestCategoryConsumed[key]
    return rolled and not consumed
end

local function PZLinuxRequestsIsCategoryAvailableIn(modData, contractId)
    local key = tostring(tonumber(contractId))
    local rolled = tonumber(modData.PZLinuxRequestCategoryAvailable[key]) == 1
    local consumed = modData.PZLinuxRequestCategoryConsumed and modData.PZLinuxRequestCategoryConsumed[key]
    return rolled and not consumed
end

-- Marks a category as spent for the rest of today, whether because the
-- player bought from it or declined the offered price -- either way, this
-- seller is done for today and the category disappears from the list until
-- the next game day's roll.
local function PZLinuxRequestsMarkCategoryConsumed(playerObj, contractId)
    local modData = PZLinuxRequestsEnsureCategoryRoll(playerObj)
    modData.PZLinuxRequestCategoryConsumed = modData.PZLinuxRequestCategoryConsumed or {}
    modData.PZLinuxRequestCategoryConsumed[tostring(tonumber(contractId))] = 1
    PZLinuxTransmitPlayerModData(playerObj)
end

function PZLinuxRequestsGetAvailableCategories(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = PZLinuxRequestsEnsureCategoryRoll(playerObj)

    local ids = {}
    for _, contractId in ipairs(PZLinuxRequestsAllCategoryIds()) do
        if PZLinuxRequestsIsCategoryAvailableIn(modData, contractId) then
            table.insert(ids, contractId)
        end
    end

    return {
        ok = true,
        requestId = requestId,
        day = PZLinuxRequestsCurrentGameDay(),
        available = ids,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

-- Refusing an offered price burns today's opportunity for that category just
-- like finding no seller at all would, so the player cannot keep re-rolling
-- the offer by repeatedly opening and declining it.
function PZLinuxRequestsRejectCategory(player, contractId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    PZLinuxRequestsMarkCategoryConsumed(playerObj, contractId)
    return { ok = true, requestId = requestId, contractId = tonumber(contractId) }
end

-- Same fix, same reason as PZLinuxDarkWebQueueDecode/Encode
-- (PZLinuxDarkWeb.lua): the pending Buy Goods delivery queue used to be an
-- array of tables (modData.PZLinuxOnItemRequest = { { {items=...} }, ... })
-- -- the same nested-modData shape a real player's server logs confirmed
-- doesn't reliably persist between separate purchase commands for the
-- structurally identical Dark Web queue. A Buy Goods order can be up to 6
-- different item names at once (not just one item repeated, like Dark
-- Web), so each queued order is encoded as its item names joined with ",",
-- and separate orders are joined with ";" -- e.g.
-- "Base.Apple,Base.Apple,Base.Banana;Base.CannedBeans".
function PZLinuxRequestsQueueDecode(queueString)
    local queue = {}
    if type(queueString) ~= "string" or queueString == "" then return queue end
    for batchString in queueString:gmatch("[^;]+") do
        local items = {}
        for itemName in batchString:gmatch("[^,]+") do
            table.insert(items, { name = itemName })
        end
        if #items > 0 then
            table.insert(queue, { items = items })
        end
    end
    return queue
end

function PZLinuxRequestsQueueEncode(queue)
    local batchParts = {}
    for _, batch in ipairs(queue or {}) do
        local itemNames = {}
        for _, item in ipairs(batch.items or {}) do
            table.insert(itemNames, tostring(item.name))
        end
        table.insert(batchParts, table.concat(itemNames, ","))
    end
    return table.concat(batchParts, ";")
end

function PZLinuxRequestsApplyOrder(player, state, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local order = PZLinuxRequestsBuildOrder(playerObj, state, requestId)
    if not order.ok then return order end

    local modData = playerObj:getModData()

    -- Defense in depth: even though the client only shows categories the
    -- daily roll already made available, re-check server-side in case the
    -- client's view is stale (e.g. the roll changed, or the offer was
    -- already declined in another session).
    if not PZLinuxRequestsIsCategoryAvailable(playerObj, order.contractId) then
        return {
            ok = false,
            error = "category_unavailable",
            requestId = requestId,
            contractId = order.contractId,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    local hasPendingVehicle = tonumber(modData.PZLinuxOnItemRequestCar) == 1
    local hasPendingItems = type(modData.PZLinuxOnItemRequestQueue) == "string" and modData.PZLinuxOnItemRequestQueue ~= ""

    -- A vehicle delivery only clears PZLinuxOnItemRequestCar once the client
    -- visually confirms it while standing next to it. The vehicle (and its
    -- key) are only created once the player first gets within range of the
    -- delivery point (see checkAndSpawnVehicle's dist < 50 gate); before
    -- that, nothing exists yet, so self-healing here must NEVER clear the
    -- flag for a delivery that was never actually spawned -- doing so would
    -- silently make the player lose the vehicle and key they already paid
    -- for, with no way to ever collect them. Only heal once we can prove the
    -- vehicle was already spawned server-side (the player got their key; the
    -- only thing lost was the final visual-confirmation round-trip), and
    -- only after a generous grace period so this never cancels a delivery
    -- that is still legitimately in progress.
    if hasPendingVehicle then
        -- A pending flag with no recorded order time predates this field (an
        -- older save) and is therefore always eligible for healing too.
        local orderedHour = tonumber(modData.PZLinuxRequestVehicleOrderedHour) or 0
        local currentHour = getGameTime and getGameTime():getWorldAgeHours() or nil
        local vehicleDeliveryGraceHours = 2
        local staleDeliveryId = tostring(modData.PZLinuxRequestVehicleDeliveryId or "")
        local alreadySpawned = staleDeliveryId ~= "" and PZLinuxRequestsFindDeliveredVehicle(staleDeliveryId) ~= nil
        if currentHour and alreadySpawned and (currentHour - orderedHour) >= vehicleDeliveryGraceHours then
            print("[PZLinux Vehicle] clearing stale pending flag for "
                .. tostring(PZLinuxGetPlayerKey(playerObj))
                .. " deliveryId=" .. staleDeliveryId
                .. " (vehicle already delivered, only the visual confirmation was lost)")
            modData.PZLinuxOnItemRequestCar = 0
            modData.PZLinuxActiveRequest = 0
            modData.PZLinuxRequestVehicleDeliveryId = nil
            modData.PZLinuxRequestVehicleKeyId = 0
            PZLinuxTransmitPlayerModData(playerObj)
            hasPendingVehicle = false
        end
    end

    if (order.contractId == 9 and (hasPendingVehicle or hasPendingItems))
    or (order.contractId ~= 9 and hasPendingVehicle) then
        return {
            ok = false,
            error = "request_delivery_pending",
            requestId = requestId,
            contractId = order.contractId,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    local debit = PZLinuxApplyBankDebit(playerObj, order.amount, "request-order", requestId)
    if not debit.ok then
        debit.contractId = order.contractId
        return debit
    end

    modData.PZLinuxActiveRequest = 1
    if order.contractId == 9 then
        modData.PZLinuxOnItemRequestCar = 1
        modData.PZLinuxOnItemRequestCarName = order.vehicleName
        modData.PZLinuxRequestLocationX = order.locationX
        modData.PZLinuxRequestLocationY = order.locationY
        modData.PZLinuxRequestLocationZ = order.locationZ
        modData.PZLinuxRequestVehicleDeliveryId = table.concat({
            "PZLinuxVehicle",
            PZLinuxGetPlayerKey(playerObj),
            tostring(getGameTime and math.floor(getGameTime():getWorldAgeHours() * 3600) or 0),
            tostring(ZombRand(100000, 1000000)),
        }, "-")
        modData.PZLinuxRequestVehicleKeyId = 0
        modData.PZLinuxRequestVehicleOrderedHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        modData.PZLinuxOnItemRequestQueue = ""
        order.deliveryId = modData.PZLinuxRequestVehicleDeliveryId
    else
        modData.PZLinuxOnItemRequestCar = 0
        local queue = PZLinuxRequestsQueueDecode(modData.PZLinuxOnItemRequestQueue)
        table.insert(queue, { items = order.items })
        modData.PZLinuxOnItemRequestQueue = PZLinuxRequestsQueueEncode(queue)
        -- Same diagnostic pattern as the Dark Web buy path
        -- (PZLinuxDarkWeb.lua) -- kept alongside it since it's what
        -- actually surfaced the real root cause there.
        print(string.format(
            "[PZLinux Requests] ORDER player=%s contractId=%s queueLenAfter=%d",
            tostring(PZLinuxGetPlayerKey(playerObj)), tostring(order.contractId), #queue))
        if addXp then addXp(playerObj, Perks.PlantScavenging, 3) end
    end
    PZLinuxTransmitPlayerModData(playerObj)

    -- This seller sold what they had: the category disappears from the list
    -- until tomorrow's roll, exactly like a declined offer would.
    PZLinuxRequestsMarkCategoryConsumed(playerObj, order.contractId)

    order.balance = PZLinuxLoadBankBalance(playerObj)
    return order
end

function PZLinuxRequestsApplyDelivery(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local modData = playerObj:getModData()
    local queue = PZLinuxRequestsQueueDecode(modData.PZLinuxOnItemRequestQueue)
    -- Same unconditional-before-any-early-return diagnostic as the Dark Web
    -- delivery path (PZLinuxDarkWeb.lua) -- printed no matter what state is
    -- found, so a mailbox visit that turns up nothing still leaves a log
    -- trace showing exactly why.
    print(string.format(
        "[PZLinux Requests] DELIVER player=%s activeRequest=%s rawQueueLen=%d decodedQueueLen=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(modData.PZLinuxActiveRequest),
        #tostring(modData.PZLinuxOnItemRequestQueue or ""), #queue))

    if modData.PZLinuxActiveRequest ~= 1 then
        return { ok = true, requestId = requestId, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if #queue == 0 then
        modData.PZLinuxActiveRequest = 0
        modData.PZLinuxOnItemRequestQueue = ""
        return { ok = true, requestId = requestId, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if ZombRand(1, 101) <= 10 then
        modData.PZLinuxActiveRequest = 0
        modData.PZLinuxOnItemRequestQueue = ""
        PZLinuxTransmitPlayerModData(playerObj)
        PZLinuxCreateStolenOrderNote(playerObj)
        return { ok = true, requestId = requestId, lost = true, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local delivered = 0
    local inventory = playerObj:getInventory()
    if not inventory then
        return { ok = false, error = "missing_inventory", requestId = requestId, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    while #queue > 0 do
        local batch = queue[#queue]
        if not batch.items or #batch.items == 0 then
            table.remove(queue, #queue)
            modData.PZLinuxOnItemRequestQueue = PZLinuxRequestsQueueEncode(queue)
            return { ok = false, error = "invalid_pending_request", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local parcel = inventory:AddItem("Base.Parcel_Large")
        if not parcel then
            return { ok = false, error = "parcel_creation_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        local parcelInv = parcel:getInventory()
        local batchDelivered = 0
        for _, item in ipairs(batch.items) do
            local created = item and item.name and parcelInv:AddItem(item.name)
            if not created then
                inventory:Remove(parcel)
                return { ok = false, error = "item_creation_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
            end
            batchDelivered = batchDelivered + 1
        end

        if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
            inventory:Remove(parcel)
            return { ok = false, error = "parcel_sync_failed", requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
        end

        table.remove(queue, #queue)
        -- v1.0.8 (kept): transmitting after every single removal, not just
        -- once at the end, means a mid-loop disconnect leaves the
        -- already-delivered entries marked gone rather than betting on one
        -- final transmit at the end of the loop to have covered all of
        -- them.
        modData.PZLinuxOnItemRequestQueue = PZLinuxRequestsQueueEncode(queue)
        delivered = delivered + batchDelivered
        PZLinuxTransmitPlayerModData(playerObj)
    end
    modData.PZLinuxActiveRequest = 0
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
end

-- ===========================================================================
-- Sell Surplus: the inverse of Requests, Dark Web-styled. Every sellable item
-- (every Request item except vehicles) independently has a small chance of
-- being wanted today, for a specific random quantity; the player must own at
-- least that many to sell (no partial sale). Price is a fraction of the
-- item's reference value, with a rare chance of a much better one-off offer,
-- and an optional negotiation minigame that can raise the price further or
-- make the buyer walk away entirely. The sale only completes at a mailbox.
-- ===========================================================================

-- Flattens every Request item (all categories except the vehicle one, id 9)
-- into one static list, each tagged with its category's reference price.
-- Cached since the source data never changes at runtime.
local PZLinuxSellItemCatalogCache = nil
local function PZLinuxSellItemCatalog()
    if PZLinuxSellItemCatalogCache then return PZLinuxSellItemCatalogCache end
    local catalog = {}
    for _, contractId in ipairs(PZLinuxRequestsAllCategoryIds()) do
        if contractId ~= 9 then
            local definition = PZLinuxRequestDefinitions[contractId]
            if definition and type(definition.items) == "table" then
                for _, itemName in ipairs(definition.items) do
                    table.insert(catalog, { name = itemName, price = tonumber(definition.price) or 0 })
                end
            end
        end
    end
    PZLinuxSellItemCatalogCache = catalog
    return catalog
end

local function PZLinuxSellCountInventoryItem(playerObj, itemName)
    local items = playerObj:getInventory():getItems()
    local count = 0
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getFullType and item:getFullType() == itemName then
            count = count + 1
        end
    end
    return count
end

-- Rolls, once per game day and cached in the player's own modData, whether
-- each item is wanted today, for what quantity, and at what price. Items not
-- wanted simply do not appear in the offer list -- their absence means
-- nobody wants to buy them today.
local function PZLinuxSellEnsureDemandRoll(playerObj)
    local modData = playerObj:getModData()
    local currentDay = PZLinuxRequestsCurrentGameDay()
    if tonumber(modData.PZLinuxSellDemandDay) == currentDay
    and type(modData.PZLinuxSellDemand) == "table" then
        return modData
    end

    local cfg = PZLinux.Config.Sell
    local demand = {}
    for _, entry in ipairs(PZLinuxSellItemCatalog()) do
        if ZombRand(1, 101) <= cfg.demandChancePercent then
            local quantity = ZombRand(cfg.quantityMin, cfg.quantityMax + 1)
            local greatDeal = ZombRand(1, 101) <= cfg.greatDealChancePercent
            local pricePercent = greatDeal
                and ZombRand(cfg.greatDealMinPercent, cfg.greatDealMaxPercent + 1)
                or ZombRand(cfg.basePricePercentMin, cfg.basePricePercentMax + 1)
            local unitPrice = math.floor(entry.price * pricePercent / 100)
            demand[entry.name] = {
                quantity = quantity,
                total = unitPrice * quantity,
                greatDeal = greatDeal,
            }
        end
    end
    modData.PZLinuxSellDemandDay = currentDay
    modData.PZLinuxSellDemand = demand
    -- Items whose negotiation failed (buyer walked away) or that were
    -- already sold are hidden for the rest of the day even though their
    -- demand entry above technically still exists.
    modData.PZLinuxSellWithdrawn = {}
    modData.PZLinuxSellSoldToday = {}
    PZLinuxTransmitPlayerModData(playerObj)
    return modData
end

local function PZLinuxSellIsItemActive(modData, itemName)
    local demand = modData.PZLinuxSellDemand[itemName]
    if not demand then return nil end
    if modData.PZLinuxSellWithdrawn and modData.PZLinuxSellWithdrawn[itemName] then return nil end
    if modData.PZLinuxSellSoldToday and modData.PZLinuxSellSoldToday[itemName] then return nil end
    return demand
end

function PZLinuxSellGetOffers(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = PZLinuxSellEnsureDemandRoll(playerObj)

    local offers = {}
    for _, entry in ipairs(PZLinuxSellItemCatalog()) do
        local demand = PZLinuxSellIsItemActive(modData, entry.name)
        if demand then
            table.insert(offers, {
                name = entry.name,
                quantity = demand.quantity,
                total = demand.total,
                greatDeal = demand.greatDeal,
            })
        end
    end

    return {
        ok = true,
        requestId = requestId,
        day = PZLinuxRequestsCurrentGameDay(),
        offers = offers,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

-- A 50/50 haggle: on success the offered total goes up by a fixed amount and
-- the player may negotiate again or sell; on failure the buyer withdraws
-- entirely and this item cannot be sold again until tomorrow's roll.
function PZLinuxSellNegotiate(player, itemName, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = PZLinuxSellEnsureDemandRoll(playerObj)

    local demand = PZLinuxSellIsItemActive(modData, itemName)
    if not demand then
        return { ok = false, error = "no_demand", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local cfg = PZLinux.Config.Sell
    local succeeded = ZombRand(1, 101) <= (tonumber(cfg.negotiateSuccessChancePercent) or 50)
    if succeeded then
        demand.total = demand.total + (tonumber(cfg.negotiateIncrement) or 100)
        PZLinuxTransmitPlayerModData(playerObj)
        return {
            ok = true,
            requestId = requestId,
            itemName = itemName,
            withdrawn = false,
            quantity = demand.quantity,
            total = demand.total,
            greatDeal = demand.greatDeal,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    modData.PZLinuxSellWithdrawn = modData.PZLinuxSellWithdrawn or {}
    modData.PZLinuxSellWithdrawn[itemName] = 1
    PZLinuxTransmitPlayerModData(playerObj)
    return {
        ok = true,
        requestId = requestId,
        itemName = itemName,
        withdrawn = true,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

-- Sells immediately, Dark Web style: the player must already own at least
-- the demanded quantity (no partial sale), which is removed right away and
-- replaced with a single priced package that must still be dropped at a
-- mailbox to actually get paid.
function PZLinuxSellApplySell(player, itemName, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = PZLinuxSellEnsureDemandRoll(playerObj)

    local demand = PZLinuxSellIsItemActive(modData, itemName)
    if not demand then
        return { ok = false, error = "no_demand", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    if not inventory then
        return { ok = false, error = "missing_inventory", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if PZLinuxSellCountInventoryItem(playerObj, itemName) < demand.quantity then
        return { ok = false, error = "missing_items", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local removedCount = 0
    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        if removedCount >= demand.quantity then break end
        local item = items:get(index)
        if item and item.getFullType and item:getFullType() == itemName then
            inventory:Remove(item)
            removedCount = removedCount + 1
        end
    end

    local total = demand.total
    local greatDeal = demand.greatDeal

    local parcel = inventory:AddItem("Base.SuspiciousPackage")
    if not parcel then
        return { ok = false, error = "sale_parcel_creation_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    parcel:setName("$" .. tostring(total))
    parcel:getModData().PZLinuxSellSaleAmount = total
    if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
        inventory:Remove(parcel)
        return { ok = false, error = "sale_parcel_sync_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    modData.PZLinuxSellSoldToday = modData.PZLinuxSellSoldToday or {}
    modData.PZLinuxSellSoldToday[itemName] = 1
    PZLinuxTransmitPlayerModData(playerObj)

    print("[PZLinux Sell] sold " .. tostring(itemName) .. " x" .. tostring(removedCount)
        .. " for " .. tostring(PZLinuxGetPlayerKey(playerObj)) .. " total=" .. tostring(total))

    return {
        ok = true,
        requestId = requestId,
        itemName = itemName,
        sold = removedCount,
        total = total,
        greatDeal = greatDeal,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxSellApplyRedeemPackage(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local items = inventory:getItems()
    local amount = 0
    local redeemed = 0

    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if item and item:getFullType() == "Base.SuspiciousPackage" then
            local itemModData = item:getModData()
            local packageAmount = tonumber(itemModData.PZLinuxSellSaleAmount)
            if packageAmount and packageAmount > 0 then
                amount = amount + PZLinuxNormalizeMoney(packageAmount)
                redeemed = redeemed + 1
                PZLinuxRemoveInventoryItem(playerObj, item)
            end
        end
    end

    local credit = nil
    if amount > 0 then
        credit = PZLinuxApplyBankCredit(playerObj, amount, "sell-surplus", requestId)
    end

    PZLinuxTransmitPlayerModData(playerObj)
    if redeemed > 0 then
        print(string.format(
            "[PZLinux Sell] REDEEM player=%s packages=%d total=%d balance=%d",
            tostring(PZLinuxGetPlayerKey(playerObj)), redeemed, amount,
            credit and credit.balance or PZLinuxLoadBankBalance(playerObj)))
    end
    return {
        ok = true,
        requestId = requestId,
        sold = redeemed,
        total = amount,
        balance = credit and credit.balance or PZLinuxLoadBankBalance(playerObj),
    }
end

-- Training: buy XP for money, gated by time spent actually keeping the
-- panel open -- the same way vanilla reading a skill book takes real
-- in-game time and stops the moment you stop reading. Deliberately NOT a
-- passive "elapsed world-hours regardless of presence" mechanic (like ATM
-- cash regen): the panel has to stay open the whole time, like a training
-- video playing. Measured in IN-GAME hours (getGameTime():getWorldAgeHours(),
-- the same time source every other schedule in this mod already uses),
-- not real wall-clock time, to land in the same ballpark as vanilla
-- reading a skill book (commonly 2-5 in-game hours) rather than an
-- arbitrary real-time wait -- and it means a player who speeds up game
-- time (the normal >> controls, same as while reading in vanilla) speeds
-- through a course too, exactly like reading does. Progress is stored as
-- accumulated in-game hours (PZLinuxTrainingActiveProgressHours) rather
-- than a start time, and only ever advances through
-- PZLinuxTrainingApplyProgressTick, which measures the elapsed world age
-- itself (against the last tick's world age, refreshed to "now" every
-- time the panel opens) rather than trusting anything the client reports.

function PZLinuxTrainingEncodeList(ids)
    return table.concat(ids or {}, ",")
end

function PZLinuxTrainingDecodeList(text)
    local ids = {}
    if type(text) ~= "string" or text == "" then return ids end
    for id in text:gmatch("[^,]+") do
        table.insert(ids, id)
    end
    return ids
end

function PZLinuxTrainingListContains(text, id)
    for _, existing in ipairs(PZLinuxTrainingDecodeList(text)) do
        if existing == id then return true end
    end
    return false
end

-- Removing an entry doesn't touch a permanent record anywhere -- there
-- isn't one (see the comment on PZLinuxTrainingEnsureWeeklyOffers below).
-- This only ever shrinks TODAY's offer list once one of the 3 is
-- completed, exactly like PZLinuxRequestsMarkCategoryConsumed already
-- does for Buy Goods: gone for the rest of today, back in the pool with
-- the same odds as anything else on tomorrow's fresh roll.
function PZLinuxTrainingRemoveFromList(text, id)
    local remaining = {}
    for _, existing in ipairs(PZLinuxTrainingDecodeList(text)) do
        if existing ~= id then table.insert(remaining, existing) end
    end
    return PZLinuxTrainingEncodeList(remaining)
end

-- A daily reroll (matching Buy Goods' own daily category refresh,
-- PZLinuxRequestsCurrentGameDay) turned out to be too generous once
-- there's no permanent cap on how many courses a character can ever buy
-- -- with 3 fresh options appearing every single in-game day, a player
-- who plays through several in-game days in one sitting could plausibly
-- see (and afford) far more XP than intended. Rerolling only once a
-- week slows that pace down to something deliberate, while every other
-- rule stays the same: 3 offers, drawn from every (skill, tier)
-- combination -- e.g. "electricity_100" and "electricity_800" are two
-- separate offers -- and completing one is NOT tracked forever, it's only
-- ever removed from THIS WEEK's 3 offers (so a player can't re-pay and
-- redo the exact same one again before the next reroll), while the
-- following week's fresh roll draws from the full pool again with normal
-- odds -- explicitly by design, so a player who only wants to spend
-- $10,000 at a time can, and the same 100 XP course has a real chance of
-- coming back around, rather than every course being a permanent
-- one-shot per character. Also excludes whichever one the player is
-- currently mid-training on (no point re-offering something already
-- bought and in progress).
function PZLinuxTrainingCurrentGameWeek()
    if not getGameTime then return 0 end
    return math.floor(getGameTime():getWorldAgeHours() / (24 * 7))
end

function PZLinuxTrainingEnsureWeeklyOffers(modData)
    local thisWeek = PZLinuxTrainingCurrentGameWeek()
    -- Deliberately gated on the WEEK NUMBER alone, not on whether the list
    -- still has anything left in it. A player who buys and finishes all 3
    -- of this week's offers ends up with PZLinuxTrainingOffersList == ""
    -- while still squarely inside the same week -- that emptiness is the
    -- CORRECT, expected state (see PZLinuxTrainingRemoveFromList above),
    -- not a sign a fresh roll is due. Rerolling on an empty-but-same-week
    -- list would let a player who clears their weekly offers immediately
    -- get a brand new set instead of waiting out the week, defeating the
    -- entire point of the weekly cadence.
    if tonumber(modData.PZLinuxTrainingOffersWeek) == thisWeek then
        return
    end

    local activeCourse = modData.PZLinuxTrainingActiveCourse or ""
    local eligible = {}
    for _, offerId in ipairs(PZLinuxTrainingAllOfferIds()) do
        if offerId ~= activeCourse then
            table.insert(eligible, offerId)
        end
    end

    for index = #eligible, 2, -1 do
        local swapIndex = ZombRand(1, index + 1)
        eligible[index], eligible[swapIndex] = eligible[swapIndex], eligible[index]
    end

    local offerCount = math.min(PZLinuxTrainingConfig.offerCount, #eligible)
    local offers = {}
    for i = 1, offerCount do
        table.insert(offers, eligible[i])
    end

    modData.PZLinuxTrainingOffersWeek = thisWeek
    modData.PZLinuxTrainingOffersList = PZLinuxTrainingEncodeList(offers)
end

local function PZLinuxTrainingWorldAgeHours()
    if not getGameTime then return 0 end
    return getGameTime():getWorldAgeHours()
end

local function PZLinuxTrainingBuildActiveState(modData)
    local courseId = modData.PZLinuxTrainingActiveCourse
    if not courseId or courseId == "" then return nil end

    -- durationHours/xp are snapshotted at purchase time (below) rather than
    -- re-resolved from the tier table on every read, so an in-progress
    -- training is never affected if the tier list itself changes later.
    local durationHours = tonumber(modData.PZLinuxTrainingActiveDurationHours) or 3
    local progressHours = tonumber(modData.PZLinuxTrainingActiveProgressHours) or 0
    return {
        courseId = courseId,
        perk = modData.PZLinuxTrainingActivePerk,
        xp = tonumber(modData.PZLinuxTrainingActiveXp) or 0,
        durationHours = durationHours,
        progressHours = progressHours,
        progress = durationHours > 0 and math.min(1, progressHours / durationHours) or 0,
    }
end

function PZLinuxTrainingGetState(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    PZLinuxTrainingEnsureWeeklyOffers(modData)

    -- Establishes a fresh baseline for THIS viewing session -- opening the
    -- panel (or reloading its state) must never count the gap since the
    -- player was last here as progress, only in-game time that passes
    -- from this point on, ticked explicitly by
    -- PZLinuxTrainingApplyProgressTick while the panel stays open.
    if modData.PZLinuxTrainingActiveCourse and modData.PZLinuxTrainingActiveCourse ~= "" then
        modData.PZLinuxTrainingLastTickHour = PZLinuxTrainingWorldAgeHours()
    end

    local offerIds = PZLinuxTrainingDecodeList(modData.PZLinuxTrainingOffersList)
    local offers = {}
    for _, offerId in ipairs(offerIds) do
        local course, tier = PZLinuxTrainingResolveOffer(offerId)
        if course and tier then
            table.insert(offers, {
                id = offerId,
                nameKey = course.nameKey,
                xp = tier.xp,
                price = tier.price,
                durationHours = tier.durationHours,
            })
        end
    end

    return {
        ok = true,
        requestId = requestId,
        offers = offers,
        active = PZLinuxTrainingBuildActiveState(modData),
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxTrainingApplyPurchase(player, courseId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    PZLinuxTrainingEnsureWeeklyOffers(modData)

    if modData.PZLinuxTrainingActiveCourse and modData.PZLinuxTrainingActiveCourse ~= "" then
        return { ok = false, error = "training_in_progress", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if not courseId or not PZLinuxTrainingListContains(modData.PZLinuxTrainingOffersList, courseId) then
        return { ok = false, error = "invalid_course", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local course, tier = PZLinuxTrainingResolveOffer(courseId)
    if not course or not tier then
        return { ok = false, error = "invalid_course", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    -- No separate "already completed" check needed: a course finished
    -- earlier today was already removed from PZLinuxTrainingOffersList
    -- (see the completion branch of PZLinuxTrainingApplyProgressTick), so
    -- the membership check above already refuses it -- there's no
    -- permanent completed-forever record to also check here.

    local debit = PZLinuxApplyBankDebit(playerObj, tier.price, "training-purchase", requestId)
    if not debit.ok then return debit end

    modData.PZLinuxTrainingActiveCourse = courseId
    modData.PZLinuxTrainingActivePerk = course.perk
    modData.PZLinuxTrainingActiveXp = tier.xp
    modData.PZLinuxTrainingActiveDurationHours = tier.durationHours
    modData.PZLinuxTrainingActiveProgressHours = 0
    modData.PZLinuxTrainingLastTickHour = PZLinuxTrainingWorldAgeHours()
    PZLinuxTransmitPlayerModData(playerObj)

    print(string.format(
        "[PZLinux Training] START player=%s course=%s perk=%s xp=%d price=%d durationHours=%d balance=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), courseId, tostring(course.perk),
        tier.xp, tier.price, tier.durationHours, debit.balance))

    return {
        ok = true,
        requestId = requestId,
        active = PZLinuxTrainingBuildActiveState(modData),
        balance = debit.balance,
    }
end

function PZLinuxTrainingApplyProgressTick(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    local courseId = modData.PZLinuxTrainingActiveCourse
    if not courseId or courseId == "" then
        return { ok = false, error = "no_active_training", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local now = PZLinuxTrainingWorldAgeHours()
    local lastTick = tonumber(modData.PZLinuxTrainingLastTickHour) or now
    -- Generously bounded (not tightly clamped like a client-reported value
    -- would need to be): the world clock is server-authoritative, so a
    -- normal tick's delta is only ever as large as legitimate game-speed
    -- controls allow. This just guards against a genuinely stale baseline
    -- somehow surviving without a reset (a missed PZLinuxTrainingGetState
    -- call) counting a huge, unearned jump.
    local deltaHours = math.max(0, math.min(now - lastTick, PZLinuxTrainingConfig.maxTickDeltaHours))
    modData.PZLinuxTrainingLastTickHour = now

    local durationHours = tonumber(modData.PZLinuxTrainingActiveDurationHours) or 3
    local progressHours = (tonumber(modData.PZLinuxTrainingActiveProgressHours) or 0) + deltaHours
    modData.PZLinuxTrainingActiveProgressHours = progressHours

    if progressHours < durationHours then
        PZLinuxTransmitPlayerModData(playerObj)
        return {
            ok = true,
            requestId = requestId,
            completed = false,
            active = PZLinuxTrainingBuildActiveState(modData),
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    -- Complete: grant XP through the real vanilla channel (addXp), which
    -- already applies whatever XP multipliers the player currently has
    -- (Fast Learner, boosted-XP moodles, etc.) exactly like every other
    -- source of XP in the game -- nothing bespoke needed here to honor
    -- that.
    local xpAmount = tonumber(modData.PZLinuxTrainingActiveXp) or 0
    local perkName = modData.PZLinuxTrainingActivePerk
    local perk = perkName and Perks and Perks.FromString and Perks.FromString(perkName) or nil
    if addXp and perk then addXp(playerObj, perk, xpAmount) end

    -- Not tracked forever -- just removed from TODAY's offer list, same
    -- as PZLinuxRequestsMarkCategoryConsumed does for a bought Buy Goods
    -- category, so it can't be re-paid and redone again today, but has a
    -- normal chance of coming back around on a future day's roll.
    modData.PZLinuxTrainingOffersList = PZLinuxTrainingRemoveFromList(modData.PZLinuxTrainingOffersList, courseId)

    modData.PZLinuxTrainingActiveCourse = ""
    modData.PZLinuxTrainingActivePerk = nil
    modData.PZLinuxTrainingActiveXp = nil
    modData.PZLinuxTrainingActiveDurationHours = nil
    modData.PZLinuxTrainingActiveProgressHours = nil
    modData.PZLinuxTrainingLastTickHour = nil
    PZLinuxTransmitPlayerModData(playerObj)

    print(string.format(
        "[PZLinux Training] COMPLETE player=%s course=%s perk=%s xpGranted=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), courseId, tostring(perkName), xpAmount))

    return {
        ok = true,
        requestId = requestId,
        completed = true,
        completedCourse = courseId,
        xpGranted = xpAmount,
        active = nil,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxRequestTrainingState(player, callback)
    local requestId = PZLinuxNextRequestId("training-state")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTrainingState", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTrainingGetState(player, requestId))
    return requestId
end

function PZLinuxRequestTrainingPurchase(player, courseId, callback)
    local requestId = PZLinuxNextRequestId("training-purchase")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTrainingPurchase", { requestId = requestId, courseId = courseId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTrainingApplyPurchase(player, courseId, requestId))
    return requestId
end

function PZLinuxRequestTrainingTick(player, callback)
    local requestId = PZLinuxNextRequestId("training-tick")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTrainingTick", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTrainingApplyProgressTick(player, requestId))
    return requestId
end

function PZLinuxRequestsFindDeliveredVehicle(deliveryId)
    if not deliveryId or deliveryId == "" or not getCell then return nil end

    local ok, found = pcall(function()
        -- IsoCell:getVehicles() returns a java.util.Set (confirmed in the game's
        -- own bytecode), which has no :get(index) method, only :size() and
        -- :toArray() -- hence the "tried to call nil" crashes when it was
        -- iterated like an ArrayList. Converting to an array first (the same
        -- pattern the game itself uses for other Set-returning APIs, e.g.
        -- item:getTags():toArray() in Vehicles.lua) makes it safely iterable.
        local vehicles = getCell():getVehicles()
        local vehicleArray = vehicles and vehicles.toArray and vehicles:toArray() or nil
        if not vehicleArray then return nil end

        -- While the vehicle scan above was broken, every retry that failed to
        -- find the already-delivered vehicle spawned a brand new one instead,
        -- stacking duplicates. Keep only the first (canonical) match and clean
        -- up any extras so a save affected by that bug self-heals, and so a
        -- future regression can never stack free vehicles again.
        local canonical
        for _, vehicle in ipairs(vehicleArray) do
            local data = vehicle and vehicle.getModData and vehicle:getModData() or nil
            if data and tostring(data.PZLinuxRequestVehicleDeliveryId or "") == tostring(deliveryId) then
                if not canonical then
                    canonical = vehicle
                elseif PZLinuxContractsRemoveWorldEntity then
                    print("[PZLinux Vehicle] removed duplicate delivery=" .. tostring(deliveryId))
                    PZLinuxContractsRemoveWorldEntity(vehicle)
                end
            end
        end
        return canonical
    end)
    if not ok then
        print("[PZLinux Vehicle] delivered-vehicle scan failed: " .. tostring(found))
        return nil
    end
    return found
end

local function PZLinuxRequestsGetVehicleNetworkId(vehicle)
    local vehicleId = vehicle and vehicle.getId and tonumber(vehicle:getId()) or nil
    if vehicleId == nil then return nil end
    if not (isServer and isServer()) then return vehicleId end
    if vehicleId < 0 then return nil end

    local managerClass = rawget(_G, "VehicleManager")
    local manager = managerClass and managerClass.instance or nil
    if manager and manager.getVehicleByID and not manager:getVehicleByID(vehicleId) then
        return nil
    end
    return vehicleId
end

local function PZLinuxRequestsFindVehicleKey(inventory, keyId)
    if not inventory or not keyId or keyId <= 0 then return nil end
    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getKeyId and tonumber(item:getKeyId()) == tonumber(keyId) then return item end
    end
    return nil
end

local function PZLinuxRequestsEnsureVehicleKey(playerObj, keyId)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return nil, "missing_inventory" end
    local existingKey = PZLinuxRequestsFindVehicleKey(inventory, keyId)
    if existingKey then return existingKey end

    local key = instanceItem("Base.Key_Blank")
    if not key then return nil, "key_creation_failed" end
    key:setKeyId(keyId)
    key:setName("Pirated Key #" .. tostring(keyId))
    local keyItem = inventory:AddItem(key)
    if not keyItem or not PZLinuxSyncAddedInventoryItem(playerObj, keyItem) then
        if keyItem then inventory:Remove(keyItem) end
        return nil, "key_sync_failed"
    end
    return keyItem
end

local function PZLinuxRequestsEnsureDeliveryVehicleKey(playerObj, modData, vehicle)
    local keyId = tonumber(modData.PZLinuxRequestVehicleKeyId) or 0
    local vehicleKeyId = vehicle and vehicle.getKeyId and tonumber(vehicle:getKeyId()) or 0
    if keyId <= 0 and vehicleKeyId > 0 then keyId = vehicleKeyId end
    if keyId <= 0 then keyId = ZombRand(100000, 1000000) end

    if tonumber(modData.PZLinuxRequestVehicleKeyId) ~= keyId then
        modData.PZLinuxRequestVehicleKeyId = keyId
        PZLinuxTransmitPlayerModData(playerObj)
    end
    if vehicle and vehicle.setKeyId and vehicleKeyId ~= keyId then
        vehicle:setKeyId(keyId)
    end

    local keyItem, keyError = PZLinuxRequestsEnsureVehicleKey(playerObj, keyId)
    return keyItem, keyError, keyId
end

local function PZLinuxRequestsRefreshVehicleNetwork(vehicle)
    if not vehicle then return end
    if vehicle.isExistInTheWorld and not vehicle:isExistInTheWorld() and vehicle.addToWorld then
        vehicle:addToWorld()
    end
    if vehicle.transmitModData then vehicle:transmitModData() end
    if vehicle.updateParts then vehicle:updateParts() end
    local managerClass = rawget(_G, "VehicleManager")
    local manager = managerClass and managerClass.instance or nil
    if manager and manager.serverUpdate and isServer and isServer() then manager:serverUpdate() end
end

function PZLinuxRequestsApplySpawnVehicle(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = playerObj:getModData()
    if modData.PZLinuxOnItemRequestCar ~= 1 then
        return { ok = true, requestId = requestId, spawned = false, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local vehicleScript = tostring(modData.PZLinuxOnItemRequestCarName or "")
    local definition = PZLinuxRequestsGetDefinition(9)
    if not definition or not PZLinuxRequestsContains(definition.vehicles, vehicleScript) then
        return { ok = false, error = "invalid_pending_vehicle", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local location = PZLinuxRequestsFindVehicleLocation(
        modData.PZLinuxRequestLocationX,
        modData.PZLinuxRequestLocationY,
        modData.PZLinuxRequestLocationZ
    )
    if not location then
        return { ok = false, error = "missing_vehicle_location", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local x, y, z = tonumber(location.x), tonumber(location.y), tonumber(location.z) or 0
    if not PZLinuxIsPlayerNearPosition(playerObj, x, y, z, 50) then
        return { ok = true, requestId = requestId, spawned = false, tooFar = true, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local deliveryId = tostring(modData.PZLinuxRequestVehicleDeliveryId or "")
    if deliveryId == "" then
        deliveryId = table.concat({
            "PZLinuxVehicle",
            PZLinuxGetPlayerKey(playerObj),
            tostring(getGameTime and math.floor(getGameTime():getWorldAgeHours() * 3600) or 0),
            tostring(ZombRand(100000, 1000000)),
        }, "-")
        modData.PZLinuxRequestVehicleDeliveryId = deliveryId
    end

    local existingVehicle = PZLinuxRequestsFindDeliveredVehicle(deliveryId)
    if existingVehicle then
        local keyItem, keyError = PZLinuxRequestsEnsureDeliveryVehicleKey(playerObj, modData, existingVehicle)
        if not keyItem then
            return { ok = false, error = keyError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
        end
        PZLinuxRequestsRefreshVehicleNetwork(existingVehicle)
        local vehicleId = PZLinuxRequestsGetVehicleNetworkId(existingVehicle)
        if vehicleId == nil then
            print("[PZLinux Vehicle] waiting for network registration delivery=" .. deliveryId)
            return {
                ok = false,
                error = "vehicle_not_networked",
                retry = true,
                requestId = requestId,
                deliveryId = deliveryId,
                balance = PZLinuxLoadBankBalance(playerObj),
            }
        end
        print("[PZLinux Vehicle] reused delivery=" .. deliveryId
            .. " vehicleId=" .. tostring(vehicleId))
        return {
            ok = true,
            requestId = requestId,
            spawned = true,
            existing = true,
            deliveryId = deliveryId,
            vehicleId = vehicleId,
            spawnX = existingVehicle:getX(),
            spawnY = existingVehicle:getY(),
            spawnZ = existingVehicle:getZ(),
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local level = math.floor(tonumber(z) or 0)
    local square
    for radius = 0, 5 do
        for offsetX = -radius, radius do
            for offsetY = -radius, radius do
                if radius == 0 or math.abs(offsetX) == radius or math.abs(offsetY) == radius then
                    local candidate = getCell():getGridSquare(centerX + offsetX, centerY + offsetY, level)
                    if candidate and candidate:isFree(false) then
                        square = candidate
                        break
                    end
                end
            end
            if square then break end
        end
        if square then break end
    end
    if not square then
        return { ok = false, error = "missing_square", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local keyItem, keyError, uniqueKeyId = PZLinuxRequestsEnsureDeliveryVehicleKey(playerObj, modData, nil)
    if not keyItem then
        return { ok = false, error = keyError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local vehicle
    if addVehicleDebug then
        vehicle = addVehicleDebug(vehicleScript, IsoDirections.S, nil, square)
    end
    if not vehicle then
        PZLinuxRemoveInventoryItem(playerObj, keyItem)
        return { ok = false, error = "vehicle_spawn_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    vehicle:setKeyId(uniqueKeyId)
    vehicle:repair()
    local vehicleData = vehicle:getModData()
    vehicleData.PZLinuxRequestVehicleDeliveryId = deliveryId
    vehicleData.PZLinuxRequestVehicleOwner = PZLinuxGetPlayerKey(playerObj)
    vehicleData.PZLinuxRequestVehicleScript = vehicleScript
    PZLinuxRequestsRefreshVehicleNetwork(vehicle)
    PZLinuxTransmitPlayerModData(playerObj)
    local vehicleId = PZLinuxRequestsGetVehicleNetworkId(vehicle)
    if vehicleId == nil then
        print("[PZLinux Vehicle] spawned but waiting for network registration delivery=" .. deliveryId)
        return {
            ok = false,
            error = "vehicle_not_networked",
            retry = true,
            requestId = requestId,
            deliveryId = deliveryId,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end
    print("[PZLinux Vehicle] spawned delivery=" .. deliveryId
        .. " vehicleId=" .. tostring(vehicleId)
        .. " at " .. tostring(vehicle:getX()) .. "," .. tostring(vehicle:getY()) .. "," .. tostring(vehicle:getZ()))
    return {
        ok = true,
        requestId = requestId,
        spawned = true,
        deliveryId = deliveryId,
        vehicleId = vehicleId,
        spawnX = vehicle:getX(),
        spawnY = vehicle:getY(),
        spawnZ = vehicle:getZ(),
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxRequestsApplyConfirmVehicle(player, deliveryId, vehicleId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local modData = playerObj:getModData()
    if modData.PZLinuxOnItemRequestCar ~= 1 then
        return { ok = true, requestId = requestId, confirmed = true, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local canonicalDeliveryId = tostring(modData.PZLinuxRequestVehicleDeliveryId or "")
    local requestedDeliveryId = tostring(deliveryId or "")
    if canonicalDeliveryId == "" or requestedDeliveryId == "" or requestedDeliveryId ~= canonicalDeliveryId then
        return { ok = false, error = "invalid_vehicle_delivery", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local vehicle = PZLinuxRequestsFindDeliveredVehicle(canonicalDeliveryId)
    if not vehicle then
        return { ok = false, error = "vehicle_not_found", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    local canonicalVehicleId = PZLinuxRequestsGetVehicleNetworkId(vehicle)
    if canonicalVehicleId == nil then
        return { ok = false, error = "vehicle_not_networked", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    if tonumber(vehicleId) == nil or canonicalVehicleId ~= tonumber(vehicleId) then
        return { ok = false, error = "vehicle_not_found", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    if not PZLinuxIsPlayerNearPosition(playerObj, vehicle:getX(), vehicle:getY(), vehicle:getZ(), 50) then
        return { ok = false, error = "too_far_from_vehicle", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    modData.PZLinuxOnItemRequestCar = 0
    modData.PZLinuxActiveRequest = 0
    modData.PZLinuxRequestVehicleDeliveryId = nil
    modData.PZLinuxRequestVehicleKeyId = 0
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, confirmed = true, balance = PZLinuxLoadBankBalance(playerObj) }
end

function PZLinuxRequestOrder(player, state, callback)
    local requestId = PZLinuxNextRequestId("request-order")
    PZLinuxRegisterCallback(requestId, callback)
    state = state or {}
    state.requestId = requestId
    if PZLinuxSendClientCommand("PZLinuxRequestOrder", state) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsApplyOrder(player, state, requestId))
    return requestId
end

function PZLinuxRequestGetCategories(player, callback)
    local requestId = PZLinuxNextRequestId("request-get-categories")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRequestGetCategories", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsGetAvailableCategories(player, requestId))
    return requestId
end

function PZLinuxRequestRejectCategory(player, contractId, callback)
    local requestId = PZLinuxNextRequestId("request-reject-category")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, contractId = tonumber(contractId) }
    if PZLinuxSendClientCommand("PZLinuxRequestRejectCategory", args) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsRejectCategory(player, contractId, requestId))
    return requestId
end

function PZLinuxRequestDeliver(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("request-deliver")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRequestDeliver", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsApplyDelivery(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestSellGetOffers(player, callback)
    local requestId = PZLinuxNextRequestId("sell-get-offers")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxSellGetOffers", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxSellGetOffers(player, requestId))
    return requestId
end

function PZLinuxRequestSellNegotiate(player, itemName, callback)
    local requestId = PZLinuxNextRequestId("sell-negotiate")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, itemName = itemName }
    if PZLinuxSendClientCommand("PZLinuxSellNegotiate", args) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxSellNegotiate(player, itemName, requestId))
    return requestId
end

function PZLinuxRequestSellSell(player, itemName, callback)
    local requestId = PZLinuxNextRequestId("sell-sell")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, itemName = itemName }
    if PZLinuxSendClientCommand("PZLinuxSellSell", args) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxSellApplySell(player, itemName, requestId))
    return requestId
end

function PZLinuxRequestSellRedeemPackage(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("sell-redeem-package")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxSellRedeemPackage", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxSellApplyRedeemPackage(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestMailboxActionState(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("mailbox-state")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxMailboxState", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailboxGetActionState(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestSpawnVehicle(player, callback)
    local requestId = PZLinuxNextRequestId("request-vehicle")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRequestSpawnVehicle", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsApplySpawnVehicle(player, requestId))
    return requestId
end

function PZLinuxRequestConfirmVehicle(player, deliveryId, vehicleId, callback)
    local requestId = PZLinuxNextRequestId("request-vehicle-confirm")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, deliveryId = deliveryId, vehicleId = vehicleId }
    if PZLinuxSendClientCommand("PZLinuxRequestConfirmVehicle", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxRequestsApplyConfirmVehicle(player, deliveryId, vehicleId, requestId))
    return requestId
end

function PZLinuxTradingGetCompanyByCode(code)
    if not code then return nil end
    for _, company in ipairs(PZLinuxTradingCompanyNameTable or {}) do
        if company.code == code then
            return company
        end
    end
    return nil
end

function PZLinuxTradingGetDataName(code)
    return "PZLinuxTrading" .. tostring(code or "")
end

function PZLinuxTradingCopyHistory(history)
    local copy = {}
    for _, price in ipairs(history or {}) do
        table.insert(copy, tonumber(price) or 0)
    end
    return copy
end

function PZLinuxTradingTransmitCompany(code)
    local dataName = PZLinuxTradingGetDataName(code)
    if isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit(dataName)
    end
end

function PZLinuxTradingGetCompanyHistory(code)
    local company = PZLinuxTradingGetCompanyByCode(code)
    if not company then return nil end

    local dataName = PZLinuxTradingGetDataName(code)
    local companyData = ModData.getOrCreate(dataName)
    companyData.dataName = companyData.dataName or {}

    if #companyData.dataName == 0 then
        local tempPrice = company.price
        for _ = 1, 48 do
            tempPrice = PZLinuxTradingGenerateNextPrice(tempPrice, 5, 25)
            table.insert(companyData.dataName, tempPrice)
        end
        PZLinuxTradingTransmitCompany(code)
    end

    while #companyData.dataName < 48 do
        table.insert(companyData.dataName, PZLinuxTradingGenerateNextPrice(companyData.dataName[#companyData.dataName] or company.price, 5, 25))
    end
    while #companyData.dataName > 48 do
        table.remove(companyData.dataName, 1)
    end

    return companyData.dataName
end

function PZLinuxTradingInitializePrices()
    local tradingData = ModData.getOrCreate("PZLinuxTrading")
    if not tradingData.PZLinuxTrading then
        tradingData.PZLinuxTrading = 1
    end

    for _, company in ipairs(PZLinuxTradingCompanyNameTable or {}) do
        PZLinuxTradingGetCompanyHistory(company.code)
    end

    if isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit("PZLinuxTrading")
    end
end

function PZLinuxTradingUpdatePrices()
    PZLinuxTradingInitializePrices()
    for _, company in ipairs(PZLinuxTradingCompanyNameTable or {}) do
        local history = PZLinuxTradingGetCompanyHistory(company.code)
        local lastPrice = history[#history] or company.price
        table.insert(history, PZLinuxTradingGenerateNextPrice(lastPrice, 5, 5))
        if #history > 48 then
            table.remove(history, 1)
        end
        PZLinuxTradingTransmitCompany(company.code)
    end
end

function PZLinuxTradingSyncToWorldHour()
    local tradingData = ModData.getOrCreate("PZLinuxTrading")
    PZLinuxTradingInitializePrices()

    local worldHour = getGameTime and math.ceil(getGameTime():getWorldAgeHours()) or 0
    if not tradingData.PZLinuxLastPriceHour then
        tradingData.PZLinuxLastPriceHour = worldHour
    end

    local delta = math.max(0, worldHour - tonumber(tradingData.PZLinuxLastPriceHour))
    delta = math.min(delta, 48)
    for _ = 1, delta do
        PZLinuxTradingUpdatePrices()
    end

    tradingData.PZLinuxLastPriceHour = worldHour
    if isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit("PZLinuxTrading")
    end
end

function PZLinuxTradingBuildSnapshot(player)
    PZLinuxTradingSyncToWorldHour()

    local playerObj = PZLinuxGetPlayer(player)
    local playerModData = playerObj and playerObj:getModData() or {}
    local companies = {}

    for _, company in ipairs(PZLinuxTradingCompanyNameTable or {}) do
        local history = PZLinuxTradingGetCompanyHistory(company.code)
        local firstPrice = tonumber(history[24] or history[1] or company.price) or company.price
        local lastPrice = tonumber(history[#history] or company.price) or company.price
        local secondLastPrice = tonumber(history[#history - 1] or lastPrice) or lastPrice
        local h1 = 0
        local d1 = 0
        if secondLastPrice > 0 then
            h1 = ((lastPrice - secondLastPrice) / secondLastPrice) * 100
        end
        if firstPrice > 0 then
            d1 = ((lastPrice - firstPrice) / firstPrice) * 100
        end

        table.insert(companies, {
            name = company.name,
            code = company.code,
            price = lastPrice,
            firstPrice = firstPrice,
            secondLastPrice = secondLastPrice,
            h1 = h1,
            d1 = d1,
            history = PZLinuxTradingCopyHistory(history),
            quantity = tonumber(playerModData["ZLinuxPlayerWallet" .. company.code]) or 0,
        })
    end

    return {
        companies = companies,
        feeRate = PZLinuxTradingGetFeeRate(),
    }
end

function PZLinuxTradingStoreSnapshot(snapshot)
    if not snapshot or type(snapshot.companies) ~= "table" or not ModData then return end

    for _, company in ipairs(snapshot.companies) do
        if company.code and type(company.history) == "table" then
            local globalData = ModData.getOrCreate(PZLinuxTradingGetDataName(company.code))
            globalData.dataName = PZLinuxTradingCopyHistory(company.history)
        end
    end
end

function PZLinuxTradingGetSnapshot(player, requestId)
    local snapshot = PZLinuxTradingBuildSnapshot(player)
    return {
        ok = true,
        requestId = requestId,
        balance = PZLinuxLoadBankBalance(player),
        tradingSnapshot = snapshot,
    }
end

function PZLinuxTradingGetWalletKey(code)
    return "ZLinuxPlayerWallet" .. tostring(code or "")
end

function PZLinuxTradingApplyBuy(player, code, quantity, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local company = PZLinuxTradingGetCompanyByCode(code)
    quantity = PZLinuxNormalizeMoney(quantity)
    if not company or quantity <= 0 then
        return { ok = false, error = "invalid_trading_order", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    PZLinuxTradingSyncToWorldHour()
    local history = PZLinuxTradingGetCompanyHistory(company.code)
    local price = PZLinuxTradingNormalizePrice(history[#history] or company.price)
    local transaction = PZLinuxTradingCalculateTransaction(price * quantity, "buy")
    local debit = PZLinuxApplyBankDebit(playerObj, transaction.netAmount, "trading-buy", requestId)
    if not debit.ok then
        debit.code = company.code
        debit.quantity = quantity
        debit.price = price
        debit.grossAmount = transaction.grossAmount
        debit.fee = transaction.fee
        debit.netAmount = transaction.netAmount
        debit.tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj)
        return debit
    end

    local modData = playerObj:getModData()
    local walletKey = PZLinuxTradingGetWalletKey(company.code)
    modData[walletKey] = PZLinuxNormalizeMoney(modData[walletKey]) + quantity
    PZLinuxTransmitPlayerModData(playerObj)

    print(string.format(
        "[PZLinux Trading] BUY player=%s code=%s qty=%d price=%d netAmount=%d balance=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(company.code), quantity, price,
        transaction.netAmount, PZLinuxLoadBankBalance(playerObj)))

    return {
        ok = true,
        requestId = requestId,
        type = "buy",
        code = company.code,
        quantity = quantity,
        price = price,
        amount = transaction.netAmount,
        grossAmount = transaction.grossAmount,
        fee = transaction.fee,
        netAmount = transaction.netAmount,
        balance = PZLinuxLoadBankBalance(playerObj),
        previousBalance = debit.previousBalance,
        walletQuantity = modData[walletKey],
        tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj),
    }
end

function PZLinuxTradingApplySell(player, code, quantity, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local company = PZLinuxTradingGetCompanyByCode(code)
    quantity = PZLinuxNormalizeMoney(quantity)
    if not company or quantity <= 0 then
        return { ok = false, error = "invalid_trading_order", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    PZLinuxTradingSyncToWorldHour()
    local modData = playerObj:getModData()
    local walletKey = PZLinuxTradingGetWalletKey(company.code)
    local currentQuantity = PZLinuxNormalizeMoney(modData[walletKey])
    if currentQuantity < quantity then
        return {
            ok = false,
            error = "not_enough_tokens",
            requestId = requestId,
            code = company.code,
            quantity = quantity,
            walletQuantity = currentQuantity,
            balance = PZLinuxLoadBankBalance(playerObj),
            tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj),
        }
    end

    local history = PZLinuxTradingGetCompanyHistory(company.code)
    local price = PZLinuxTradingNormalizePrice(history[#history] or company.price)
    local transaction = PZLinuxTradingCalculateTransaction(price * quantity, "sell")
    local credit = PZLinuxApplyBankCredit(playerObj, transaction.netAmount, "trading-sell", requestId)
    if not credit.ok then
        credit.code = company.code
        credit.quantity = quantity
        credit.price = price
        credit.grossAmount = transaction.grossAmount
        credit.fee = transaction.fee
        credit.netAmount = transaction.netAmount
        credit.tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj)
        return credit
    end

    modData[walletKey] = currentQuantity - quantity
    PZLinuxTransmitPlayerModData(playerObj)

    print(string.format(
        "[PZLinux Trading] SELL player=%s code=%s qty=%d price=%d netAmount=%d balance=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(company.code), quantity, price,
        transaction.netAmount, PZLinuxLoadBankBalance(playerObj)))

    return {
        ok = true,
        requestId = requestId,
        type = "sell",
        code = company.code,
        quantity = quantity,
        price = price,
        amount = transaction.netAmount,
        grossAmount = transaction.grossAmount,
        fee = transaction.fee,
        netAmount = transaction.netAmount,
        balance = PZLinuxLoadBankBalance(playerObj),
        previousBalance = credit.previousBalance,
        walletQuantity = modData[walletKey],
        tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj),
    }
end

function PZLinuxRequestTradingSnapshot(player, callback)
    local requestId = PZLinuxNextRequestId("trading-snapshot")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTradingSnapshot", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTradingGetSnapshot(player, requestId))
    return requestId
end

function PZLinuxRequestTradingBuy(player, code, quantity, callback)
    local requestId = PZLinuxNextRequestId("trading-buy")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTradingBuy", { requestId = requestId, code = code, quantity = quantity }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTradingApplyBuy(player, code, quantity, requestId))
    return requestId
end

function PZLinuxRequestTradingSell(player, code, quantity, callback)
    local requestId = PZLinuxNextRequestId("trading-sell")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxTradingSell", { requestId = requestId, code = code, quantity = quantity }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxTradingApplySell(player, code, quantity, requestId))
    return requestId
end

function PZLinuxUpdateTradingPrices(player)
    if isClient and isClient() then
        PZLinuxRequestTradingSnapshot(player or PZLinuxGetPlayer(), nil)
        return
    end
    PZLinuxTradingUpdatePrices()
end

function PZLinuxTrading_initializePrices(player)
    if isClient and isClient() then
        PZLinuxRequestTradingSnapshot(player or PZLinuxGetPlayer(), nil)
        return
    end
    PZLinuxTradingInitializePrices()
end

function PZLinuxContractsGetDefinition(contractId)
    contractId = tonumber(contractId)
    for _, definition in ipairs(PZLinuxContractDefinitions or {}) do
        if definition.id == contractId then
            return definition
        end
    end
    return nil
end

function PZLinuxContractsGetCompanyCode(index)
    local company = PZLinuxTradingCompanyNameTable and PZLinuxTradingCompanyNameTable[index]
    if company and company.code then return company.code end
    return "CCC"
end

function PZLinuxContractsBuildContract(definition)
    local randomId = ZombRand(1, #(PZLinuxTradingCompanyNameTable or {}) + 1)
    local randomCityId = PZLinuxGetRandomContractCityId(definition.id)
    local companyCode = PZLinuxContractsGetCompanyCode(randomId)
    local cityName = ""
    if definition.city and PZLinuxContractCities[randomCityId] then
        cityName = " - " .. PZLinuxContractCities[randomCityId]
    end

    PZLinuxTradingSyncToWorldHour()
    local history = PZLinuxTradingGetCompanyHistory(companyCode) or {}
    local lastPrice = tonumber(history[#history]) or 1
    local maxRewardBase = lastPrice + 1
    local reward = PZLinux.Economy.roundPrice(ZombRand(lastPrice, maxRewardBase) + definition.reward, "nearest")

    return {
        id = definition.id,
        name = "Execute a contract for " .. companyCode .. " - Difficulty: " .. definition.difficulty .. "/5" .. cityName,
        code = companyCode,
        reward = reward,
        questName = definition.questName,
        cityId = randomCityId,
        difficulty = definition.difficulty,
    }
end

function PZLinuxContractsShuffle(list)
    for index = #list, 2, -1 do
        local randomIndex = ZombRand(1, index + 1)
        list[index], list[randomIndex] = list[randomIndex], list[index]
    end
end

local function PZLinuxContractsRecordBelongsToBoard(record, generatedHour)
    local recordGeneratedHour = tonumber(record and record.boardGeneratedHour)
    generatedHour = tonumber(generatedHour)
    if not generatedHour then return false end
    if recordGeneratedHour then return recordGeneratedHour == generatedHour end

    local acceptedHour = tonumber(record and record.acceptedHour)
    if not acceptedHour then return false end
    if generatedHour == 168 and acceptedHour < 168 then return true end
    local refreshHours = math.max(1, tonumber(PZLinux.Config.Contracts.boardRefreshHours) or 168)
    return acceptedHour >= generatedHour - 1 and acceptedHour < generatedHour + refreshHours
end

local function PZLinuxContractsPruneConsumedBoardContracts(boardData)
    if type(boardData.contracts) ~= "table" or not boardData.generatedHour then return false end

    local consumed = {}
    local worldData = PZLinuxContractsGetWorldData()
    for _, record in pairs(worldData.active or {}) do
        if record.boardContractId and PZLinuxContractsRecordBelongsToBoard(record, boardData.generatedHour) then
            consumed[tonumber(record.boardContractId)] = true
        end
    end

    local changed = false
    for index = #boardData.contracts, 1, -1 do
        local contractId = tonumber(boardData.contracts[index].id)
        local adminForced = boardData.adminForcedContracts
            and boardData.adminForcedContracts[tostring(contractId)] == true
        if consumed[contractId] and not adminForced then
            table.remove(boardData.contracts, index)
            changed = true
        end
    end
    if changed then PZLinux.contractPreviews = {} end
    return changed
end

function PZLinuxContractsGetBoardData()
    local boardData = ModData.getOrCreate("PZLinuxContractsBoard")
    local worldHour = getGameTime and math.max(0, math.ceil(getGameTime():getWorldAgeHours())) or 0
    local refreshHours = math.max(1, tonumber(PZLinux.Config.Contracts.boardRefreshHours) or 168)
    local scheduleVersion = 2
    local needsScheduleMigration = tonumber(boardData.scheduleVersion) ~= scheduleVersion
    local generatedHour = tonumber(boardData.generatedHour)
    local refreshDue = generatedHour and (worldHour - generatedHour) >= refreshHours

    if type(boardData.contracts) ~= "table" or not generatedHour or refreshDue or needsScheduleMigration then
        PZLinux.contractPreviews = {}
        local pool = {}
        for _, definition in ipairs(PZLinuxContractDefinitions or {}) do
            table.insert(pool, PZLinuxContractsBuildContract(definition))
        end
        PZLinuxContractsShuffle(pool)

        local selected = {}
        local count = ZombRand(1, 9)
        while #selected < count do
            for _, contract in ipairs(pool) do
                table.insert(selected, contract)
                if #selected >= count then break end
            end
        end

        boardData.contracts = selected
        boardData.adminForcedContracts = {}
        boardData.generatedHour = worldHour
        boardData.scheduleVersion = scheduleVersion
        boardData.nextRefreshHour = worldHour + refreshHours
        print("[PZLinux Contracts] board refreshed at world hour "
            .. tostring(worldHour) .. ", next refresh at " .. tostring(boardData.nextRefreshHour)
            .. ", offers=" .. tostring(#selected))
        if isServer and isServer() and ModData and ModData.transmit then
            ModData.transmit("PZLinuxContractsBoard")
        end
    end

    if PZLinuxContractsPruneConsumedBoardContracts(boardData)
    and isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit("PZLinuxContractsBoard")
    end

    return boardData
end

function PZLinuxContractsGetBoard(player, requestId)
    local boardData = PZLinuxContractsGetBoardData()
    return {
        ok = true,
        requestId = requestId,
        balance = PZLinuxLoadBankBalance(player),
        contracts = boardData.contracts or {},
        generatedHour = boardData.generatedHour,
        nextRefreshHour = boardData.nextRefreshHour,
    }
end

local function PZLinuxContractsHasAdminAccess(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return false end
    if not (isClient and isClient()) and not (isServer and isServer()) then return true end
    local accessLevel = playerObj.getAccessLevel and playerObj:getAccessLevel() or ""
    accessLevel = tostring(accessLevel):lower()
    return accessLevel == "admin" or accessLevel == "administrator"
end

function PZLinuxContractsAdminForceBoard(player, contractId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    local definition = PZLinuxContractsGetDefinition(contractId)
    if not definition then return { ok = false, error = "invalid_contract", requestId = requestId } end

    local boardData = PZLinuxContractsGetBoardData()
    boardData.adminForcedContracts = boardData.adminForcedContracts or {}
    for index = #(boardData.contracts or {}), 1, -1 do
        if tonumber(boardData.contracts[index].id) == tonumber(definition.id) then
            table.remove(boardData.contracts, index)
        end
    end
    table.insert(boardData.contracts, 1, PZLinuxContractsBuildContract(definition))
    boardData.adminForcedContracts[tostring(definition.id)] = true
    PZLinux.contractPreviews = {}
    if isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit("PZLinuxContractsBoard")
    end
    print("[PZLinux Admin] " .. tostring(playerObj:getUsername())
        .. " forced contract " .. tostring(definition.id) .. " on the shared board")
    return {
        ok = true,
        requestId = requestId,
        contractId = definition.id,
        contracts = boardData.contracts,
    }
end

function PZLinuxContractsAdminAddFunds(player, amount, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    local credit = PZLinuxApplyBankCredit(playerObj, amount, "admin-add-funds", requestId)
    if credit.ok then
        print("[PZLinux Admin] " .. tostring(playerObj:getUsername())
            .. " added $" .. tostring(credit.amount) .. " to their own bank balance"
            .. " (new balance $" .. tostring(credit.balance) .. ")")
    end
    return credit
end

function PZLinuxContractsAdminForceMail(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    -- Reuses the same random-mail generator as the normal scheduled flow
    -- (PZLinuxMailCreateRandom), so a forced mail is indistinguishable from
    -- one the player would have received naturally -- same random type
    -- (ads/ammo/medical), same allowlist, same reward rules.
    local result = PZLinuxMailCreateRandom(playerObj, requestId)
    if result.ok then
        print("[PZLinux Admin] " .. tostring(playerObj:getUsername())
            .. " forced a random mail mission (id " .. tostring(result.mailId)
            .. ", type " .. tostring(result.mailType) .. ")")
    end
    return result
end

-- Player-balance moderation tools (v1.0.9): after fixing several real
-- money bugs (Hacking, Poker) this session, an admin still had no way to
-- actually inspect or correct an affected player's account -- only
-- "add funds to my own balance" existed. Scoped deliberately to currently
-- CONNECTED players only: reaching an offline player's saved data would
-- mean reading their save file directly, a much bigger and riskier
-- undertaking than resolving an online IsoPlayer through getOnlinePlayers().
local function PZLinuxAdminFindOnlinePlayerByUsername(username)
    if not username or username == "" or not getOnlinePlayers then return nil end
    local target = tostring(username):lower()
    local players = getOnlinePlayers()
    if not players then return nil end
    for index = 0, players:size() - 1 do
        local candidate = players:get(index)
        if candidate and candidate.getUsername and tostring(candidate:getUsername()):lower() == target then
            return candidate
        end
    end
    return nil
end

function PZLinuxAdminListOnlinePlayers(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    local list = {}
    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players then
            for index = 0, players:size() - 1 do
                local candidate = players:get(index)
                if candidate and candidate.getUsername then
                    table.insert(list, {
                        username = tostring(candidate:getUsername()),
                        balance = PZLinuxLoadBankBalance(candidate),
                    })
                end
            end
        end
    end
    if #list == 0 then
        -- Solo, or getOnlinePlayers() returned nothing usable: list the
        -- admin's own character so the panel isn't just empty in solo.
        table.insert(list, {
            username = tostring(playerObj.getUsername and playerObj:getUsername() or "you"),
            balance = PZLinuxLoadBankBalance(playerObj),
        })
    end

    return { ok = true, requestId = requestId, players = list }
end

function PZLinuxAdminGetPlayerBalance(player, targetUsername, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    local target = PZLinuxAdminFindOnlinePlayerByUsername(targetUsername)
    if not target then
        return { ok = false, error = "player_not_found", requestId = requestId }
    end

    return {
        ok = true,
        requestId = requestId,
        username = tostring(target:getUsername()),
        balance = PZLinuxLoadBankBalance(target),
    }
end

function PZLinuxAdminSetPlayerBalance(player, targetUsername, amount, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    if not PZLinuxContractsHasAdminAccess(playerObj) then
        return { ok = false, error = "admin_required", requestId = requestId }
    end

    local target = PZLinuxAdminFindOnlinePlayerByUsername(targetUsername)
    if not target then
        return { ok = false, error = "player_not_found", requestId = requestId }
    end

    local previousBalance = PZLinuxLoadBankBalance(target)
    local newBalance = PZLinuxSetBankBalance(target, amount)

    print(string.format(
        "[PZLinux Admin] %s set %s's bank balance from $%d to $%d",
        tostring(playerObj.getUsername and playerObj:getUsername() or "unknown"),
        tostring(target:getUsername()), previousBalance, newBalance))

    return {
        ok = true,
        requestId = requestId,
        username = tostring(target:getUsername()),
        previousBalance = previousBalance,
        balance = newBalance,
    }
end

function PZLinuxContractsFindBoardContract(contractId)
    contractId = tonumber(contractId)
    local boardData = PZLinuxContractsGetBoardData()
    for _, boardContract in ipairs(boardData.contracts or {}) do
        if tonumber(boardContract.id) == contractId then
            return boardContract, boardData
        end
    end
    return nil, boardData
end

local function PZLinuxContractsRemoveBoardContract(contractId, generatedHour)
    contractId = tonumber(contractId)
    local boardData = ModData.getOrCreate("PZLinuxContractsBoard")
    if not contractId or tonumber(boardData.generatedHour) ~= tonumber(generatedHour) then return false end

    for index = #(boardData.contracts or {}), 1, -1 do
        if tonumber(boardData.contracts[index].id) == contractId then
            table.remove(boardData.contracts, index)
            if boardData.adminForcedContracts then
                boardData.adminForcedContracts[tostring(contractId)] = nil
            end
            PZLinux.contractPreviews = {}
            if isServer and isServer() and ModData and ModData.transmit then
                ModData.transmit("PZLinuxContractsBoard")
            end
            return true
        end
    end
    return false
end

function PZLinuxContractsCopyPreview(preview, requestId, player)
    local result = { ok = true, requestId = requestId, balance = PZLinuxLoadBankBalance(player) }
    for key, value in pairs(preview or {}) do
        if type(value) ~= "table" then result[key] = value end
    end
    return result
end

function PZLinuxContractsGetPreview(player, contractId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    contractId = tonumber(contractId)
    if not PZLinuxContractsGetDefinition(contractId) then
        return { ok = false, error = "invalid_contract", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local modData = playerObj:getModData()
    if (tonumber(modData.PZLinuxActiveContract) or 0) ~= 0 then
        return { ok = false, error = "contract_already_active", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local selectedContract, boardData = PZLinuxContractsFindBoardContract(contractId)
    if not selectedContract then
        return { ok = false, error = "contract_not_available", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local cacheKey = playerKey .. ":" .. tostring(contractId)
    local preview = PZLinux.contractPreviews[cacheKey]
    if not preview or tonumber(preview.boardGeneratedHour) ~= tonumber(boardData.generatedHour) then
        local errorCode
        preview, errorCode = PZLinuxContractsBuildMission(selectedContract)
        if not preview then
            return { ok = false, error = errorCode or "contract_preview_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
        end
        preview.boardGeneratedHour = tonumber(boardData.generatedHour) or 0
        PZLinux.contractPreviews[cacheKey] = preview
    end

    return PZLinuxContractsCopyPreview(preview, requestId, playerObj)
end

function PZLinuxContractsGetWorldData()
    local worldData = ModData.getOrCreate("PZLinuxContractsWorld")
    worldData.nextId = tonumber(worldData.nextId) or 1
    worldData.active = worldData.active or {}
    worldData.byPlayer = worldData.byPlayer or {}
    return worldData
end

function PZLinuxContractsTransmitWorldData()
    if isServer and isServer() and ModData and ModData.transmit then
        ModData.transmit("PZLinuxContractsWorld")
    end
end

function PZLinuxContractsGetWorldContract(contractWorldId)
    if not contractWorldId or contractWorldId == "" then return nil end
    local worldData = PZLinuxContractsGetWorldData()
    return worldData.active[tostring(contractWorldId)]
end

function PZLinuxContractsCreateWorldContract(player, selectedContract, contractId, mission)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return nil end

    mission = mission or {}
    local worldData = PZLinuxContractsGetWorldData()
    local worldId = "PZLinuxContract-" .. tostring(worldData.nextId)
    worldData.nextId = worldData.nextId + 1

    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local record = {
        id = worldId,
        contractId = tonumber(contractId),
        boardContractId = tonumber(selectedContract and selectedContract.id) or tonumber(contractId),
        boardGeneratedHour = tonumber(mission.boardGeneratedHour) or 0,
        status = "accepted",
        acceptedBy = playerKey,
        owner = playerKey,
        claimableBy = "any",
        acceptedHour = getGameTime and getGameTime():getWorldAgeHours() or 0,
        reward = PZLinuxNormalizeMoney(mission.reward),
        code = selectedContract and selectedContract.code or "",
        questName = selectedContract and selectedContract.questName or "",
        cityId = selectedContract and selectedContract.cityId or 0,
        locationX = tonumber(mission.locationX) or 0,
        locationY = tonumber(mission.locationY) or 0,
        locationZ = tonumber(mission.locationZ) or 0,
        info = mission.info or "",
        infoName = mission.infoName or "",
        infoCount = PZLinuxNormalizeMoney(mission.infoCount),
        note = mission.note or "",
        fullNote = mission.fullNote or "",
        targetName = mission.targetName or "",
        zombieToKill = PZLinuxNormalizeMoney(mission.zombieToKill),
        atmAmount = PZLinuxNormalizeMoney(mission.atmAmount),
        zombieCount = 0,
        playerZombieKills = playerObj.getZombieKills and tonumber(playerObj:getZombieKills()) or 0,
        pendingZombieKillCredits = 0,
        spawned = false,
        deliveredBy = "",
        completedBy = "",
    }

    worldData.active[worldId] = record
    worldData.byPlayer[playerKey] = worldId
    PZLinuxContractsTransmitWorldData()
    return record
end

function PZLinuxContractsBuildNoteText(record)
    if not record then return "" end
    local noteText = PZLinuxContractsSanitizeNoteText(record.fullNote or record.note or "")
    if tonumber(record.contractId) == 1 then
        noteText = PZLinuxContractsSetKillProgress(noteText, record.zombieCount, record.zombieToKill)
    end
    return noteText
end

function PZLinuxContractsReplaceContractNote(player, record)
    local playerObj = PZLinuxGetPlayer(player)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory or not record then return false end

    local items = inventory:getItems()
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if item and item:getType() == "Note" and item:getName() == "Contract" then
            PZLinuxRemoveInventoryItem(playerObj, item)
        end
    end

    local note = inventory:AddItem("Base.Note")
    if not note then return false end
    note:setName("Contract")
    note:setCanBeWrite(true)
    note:addPage(1, PZLinuxContractsBuildNoteText(record))
    PZLinuxContractsTagEntity(note, record.id, "contract_note")
    PZLinuxSyncAddedInventoryItem(playerObj, note)
    return true
end

function PZLinuxContractsEnsureContractNote(player, record)
    local playerObj = PZLinuxGetPlayer(player)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory or not record then return false end

    local items = inventory:getItems()
    local expectedText = PZLinuxContractsBuildNoteText(record)
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item:getType() == "Note"
        and item:getName() == "Contract"
        and PZLinuxContractsGetEntityContractId(item) == record.id then
            if item.seePage and item:seePage(1) == expectedText then return true end
            break
        end
    end
    return PZLinuxContractsReplaceContractNote(playerObj, record)
end

function PZLinuxContractsSyncWorldRecordToPlayer(player, record)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not record then return end

    local modData = playerObj:getModData()
    modData.PZLinuxContractId = record.id
    modData.PZLinuxContractTypeId = tonumber(record.contractId) or 0
    modData.PZLinuxContractWorldStatus = tostring(record.status or "")
    modData.PZLinuxActiveContract = PZLinuxContractsCanonicalActiveState(record.status)
    modData.PZLinuxOnReward = PZLinuxNormalizeMoney(record.reward)
    modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. tostring(record.code or "")
    modData.PZLinuxContractLocationX = tonumber(record.locationX) or 0
    modData.PZLinuxContractLocationY = tonumber(record.locationY) or 0
    modData.PZLinuxContractLocationZ = tonumber(record.locationZ) or 0
    modData.PZLinuxContractInfo = record.info or ""
    modData.PZLinuxContractInfoName = record.infoName or ""
    modData.PZLinuxContractInfoCount = PZLinuxNormalizeMoney(record.infoCount)
    modData.PZLinuxContractNote = record.note or ""
    modData.PZLinuxContractTargetName = record.targetName or ""
    modData.PZLinuxOnZombieToKill = PZLinuxNormalizeMoney(record.zombieToKill)
    modData.PZLinuxOnZombieDead = PZLinuxNormalizeMoney(record.zombieCount)
    modData.PZLinuxContractAtmAmount = PZLinuxNormalizeMoney(record.atmAmount)
    PZLinuxContractsSetTypeFlags(modData, record.contractId)
    if record.status == "spawned" then
        if tonumber(record.contractId) == 3 then modData.PZLinuxContractManhunt = 2 end
        if tonumber(record.contractId) == 7 then modData.PZLinuxContractCargo = 2 end
    elseif record.status == "target_down" then
        modData.PZLinuxContractManhunt = 2
    elseif record.status == "protect_started" then
        modData.PZLinuxContractProtect = 2
    elseif record.status == "protect_clear" then
        modData.PZLinuxContractProtect = 3
    elseif record.status == "objective_taken" then
        if tonumber(record.contractId) == 2 then modData.PZLinuxContractPickUp = 3 end
        if tonumber(record.contractId) == 3 then modData.PZLinuxContractManhunt = 3 end
        if tonumber(record.contractId) == 4 then modData.PZLinuxContractBlood = 3 end
        if tonumber(record.contractId) == 6 then modData.PZLinuxContractCapture = 3 end
    elseif record.status == "ready_to_complete" or record.status == "deposited" then
        modData.PZLinuxActiveContract = 9
        if tonumber(record.contractId) == 7 then modData.PZLinuxContractCargo = 3 end
        if tonumber(record.contractId) == 8 then modData.PZLinuxContractProtect = 3 end
    end
    PZLinuxTransmitPlayerModData(playerObj)
end

function PZLinuxContractsGetActiveState(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData, pzlinux = PZLinuxGetModData(playerObj)
    local worldData = PZLinuxContractsGetWorldData()
    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local worldContractId = modData.PZLinuxContractId
    if not worldContractId or worldContractId == "" then
        worldContractId = worldData.byPlayer[playerKey]
    end
    local record = worldContractId and worldData.active[tostring(worldContractId)] or nil
    if not record then
        worldContractId = worldData.byPlayer[playerKey]
        record = worldContractId and worldData.active[tostring(worldContractId)] or nil
    end
    if record and (record.status == "completed" or record.status == "cancelled") then
        if worldData.byPlayer[playerKey] == record.id then
            worldData.byPlayer[playerKey] = nil
            PZLinuxContractsTransmitWorldData()
        end
        if modData.PZLinuxContractId == record.id then
            PZLinuxContractsClearState(modData)
            PZLinuxTransmitPlayerModData(playerObj)
        end
        record = nil
    end
    if record then
        PZLinuxContractsReconcilePlayerZombieKills(playerObj, record)
        PZLinuxContractsSyncWorldRecordToPlayer(playerObj, record)
        PZLinuxContractsEnsureContractNote(playerObj, record)
    end

    return {
        ok = true,
        requestId = requestId,
        hasActiveContract = record ~= nil,
        worldContractId = record and record.id or modData.PZLinuxContractId,
        contractId = record and record.contractId or modData.PZLinuxContractTypeId,
        activeContract = modData.PZLinuxActiveContract or 0,
        zombieTarget = record and record.zombieToKill or modData.PZLinuxOnZombieToKill,
        zombieCount = record and record.zombieCount or modData.PZLinuxOnZombieDead,
        locationX = record and record.locationX or modData.PZLinuxContractLocationX,
        locationY = record and record.locationY or modData.PZLinuxContractLocationY,
        locationZ = record and record.locationZ or modData.PZLinuxContractLocationZ,
        contractKillZombie = modData.PZLinuxContractKillZombie,
        contractPickUp = modData.PZLinuxContractPickUp,
        contractManhunt = modData.PZLinuxContractManhunt,
        contractBlood = modData.PZLinuxContractBlood,
        contractCar = modData.PZLinuxContractCar,
        contractCapture = modData.PZLinuxContractCapture,
        contractCargo = modData.PZLinuxContractCargo,
        contractProtect = modData.PZLinuxContractProtect,
        contractMedical = modData.PZLinuxContractMedical,
        contractWeapon = modData.PZLinuxContractWeapon,
        contractSendComputer = modData.PZLinuxContractSendComputer,
        contractSendFridge = modData.PZLinuxContractSendFridge,
        contractAtmRefill = modData.PZLinuxContractAtmRefill,
        atmAmount = record and record.atmAmount or modData.PZLinuxContractAtmAmount,
        -- Needed by Auto Parts/Medical/Weapon contracts (5, 9, 10) to
        -- recognize a matching item at a mailbox: without these, a
        -- reconnect leaves modData.PZLinuxContractInfo stale/nil on the
        -- client, so PZLinuxContractsHasDepositItems never finds a match
        -- and the delivery option silently never appears again, even
        -- though the world contract is still active server-side.
        info = record and record.info or modData.PZLinuxContractInfo,
        infoName = record and record.infoName or modData.PZLinuxContractInfoName,
        infoCount = record and record.infoCount or modData.PZLinuxContractInfoCount,
        completionReceipt = pzlinux.contracts and pzlinux.contracts.pendingCompletion or nil,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxContractsSetTypeFlags(modData, contractId)
    if not modData then return end
    contractId = tonumber(contractId)
    if contractId == 1 then modData.PZLinuxContractKillZombie = 1 end
    if contractId == 2 then modData.PZLinuxContractPickUp = 1 end
    if contractId == 3 then modData.PZLinuxContractManhunt = 1 end
    if contractId == 4 then modData.PZLinuxContractBlood = 1 end
    if contractId == 5 then modData.PZLinuxContractCar = 1 end
    if contractId == 6 then modData.PZLinuxContractCapture = 1 end
    if contractId == 7 then modData.PZLinuxContractCargo = 1 end
    if contractId == 8 then modData.PZLinuxContractProtect = 1 end
    if contractId == 9 then modData.PZLinuxContractMedical = 1 end
    if contractId == 10 then modData.PZLinuxContractWeapon = 1 end
    if contractId == 11 then modData.PZLinuxContractSendComputer = 1 end
    if contractId == 12 then modData.PZLinuxContractSendFridge = 1 end
    if contractId == 13 then modData.PZLinuxContractAtmRefill = 1 end
end

function PZLinuxContractsMarkWorldContract(contractWorldId, status, player)
    local record = PZLinuxContractsGetWorldContract(contractWorldId)
    if not record then return nil end

    local worldData = PZLinuxContractsGetWorldData()
    record.status = status or record.status
    if player then
        local playerKey = PZLinuxGetPlayerKey(player)
        if status == "deposited" then
            record.deliveredBy = playerKey
            record.owner = playerKey
        end
        if status == "completed" then
            record.completedBy = playerKey
            record.owner = playerKey
        end
        if status == "cancelled" then record.cancelledBy = playerKey end
        if (status == "completed" or status == "cancelled") and worldData.byPlayer[playerKey] == record.id then
            worldData.byPlayer[playerKey] = nil
        end
    end
    record.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or record.updatedHour
    PZLinuxContractsTransmitWorldData()
    return record
end

function PZLinuxContractsTagEntity(entity, contractWorldId, objectiveType, transmit)
    if not entity or not contractWorldId then return end
    if entity.getModData then
        local data = entity:getModData()
        data.PZLinuxContractId = contractWorldId
        data.PZLinuxContractObjective = objectiveType or ""
    end
    if transmit ~= false and entity.transmitModData then
        entity:transmitModData()
    end
end

function PZLinuxContractsGetEntityContractId(entity)
    if not entity or not entity.getModData then return nil end
    local data = entity:getModData()
    return data and data.PZLinuxContractId
end

function PZLinuxContractsClearState(modData)
    if not modData then return end
    modData.PZLinuxContractLocationX = 0
    modData.PZLinuxContractLocationY = 0
    modData.PZLinuxContractLocationZ = 0
    modData.PZLinuxContractId = ""
    modData.PZLinuxContractTypeId = 0
    modData.PZLinuxContractWorldStatus = ""
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxActiveContract = 0
    modData.PZLinuxContractNote = ""
    modData.PZLinuxContractInfo = ""
    modData.PZLinuxContractInfoName = ""
    modData.PZLinuxContractInfoCount = 0
    modData.PZLinuxContractTargetName = ""
    modData.PZLinuxContractKillZombie = 0
    modData.PZLinuxContractPickUp = 0
    modData.PZLinuxContractManhunt = 0
    modData.PZLinuxContractBlood = 0
    modData.PZLinuxContractCar = 0
    modData.PZLinuxContractCapture = 0
    modData.PZLinuxContractCargo = 0
    modData.PZLinuxContractProtect = 0
    modData.PZLinuxContractMedical = 0
    modData.PZLinuxContractWeapon = 0
    modData.PZLinuxContractSendComputer = 0
    modData.PZLinuxContractSendFridge = 0
    modData.PZLinuxContractAtmRefill = 0
    modData.PZLinuxContractAtmAmount = 0
end

function PZLinuxContractsRemoveContractNote(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return false end
    local inventory = playerObj:getInventory()
    if not inventory then return false end

    local items = inventory:getItems()
    local removed = false
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if item and item:getType() == "Note" and item:getName() == "Contract" then
            removed = PZLinuxRemoveInventoryItem(playerObj, item) or removed
        end
    end
    return removed
end

function PZLinuxContractsUpdateCompanyPrice(dataName, direction)
    if not dataName then return end

    local code = tostring(dataName):gsub("^PZLinuxTrading", "")
    local history = PZLinuxTradingGetCompanyHistory(code)
    if not history then return end

    local lastPrice = tonumber(history[#history]) or 1
    local newPrice = PZLinux.Economy.contractCompanyNextPrice(lastPrice, direction)

    table.insert(history, newPrice)
    if #history > 48 then
        table.remove(history, 1)
    end
    PZLinuxTradingTransmitCompany(code)
end

function PZLinuxContractsApplyAccept(player, state, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    state = state or {}
    local contractId = tonumber(state.contractId)
    local definition = PZLinuxContractsGetDefinition(contractId)
    if not definition then
        return { ok = false, error = "invalid_contract", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local modData = playerObj:getModData()
    if (tonumber(modData.PZLinuxActiveContract) or 0) ~= 0 then
        return { ok = false, error = "contract_already_active", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local selectedContract, boardData = PZLinuxContractsFindBoardContract(contractId)
    if not selectedContract then
        return { ok = false, error = "contract_not_available", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local previewResult = PZLinuxContractsGetPreview(playerObj, contractId, requestId)
    if not previewResult.ok then return previewResult end
    local effectiveReward = PZLinuxNormalizeMoney(previewResult.reward)

    -- "Refill an ATM" requires the player to already have the full amount in
    -- their own bank account -- otherwise they could never withdraw it at
    -- all, from any ATM. The actual difficulty is gathering that much
    -- physical cash by withdrawing (possibly emptying) several ATMs around
    -- town, then carrying it all to the one hardcoded target -- this
    -- contract itself never touches the bank or hands over any cash; it
    -- only gates acceptance and later validates the deposit.
    if contractId == 13 then
        local requiredAmount = PZLinuxNormalizeMoney(previewResult.atmAmount)
        if PZLinuxLoadBankBalance(playerObj) < requiredAmount then
            return {
                ok = false,
                error = "insufficient_funds_for_contract",
                requestId = requestId,
                requiredAmount = requiredAmount,
                balance = PZLinuxLoadBankBalance(playerObj),
            }
        end
    end

    PZLinuxContractsClearState(modData)
    modData.PZLinuxActiveContract = 1
    modData.PZLinuxOnZombieDead = 0
    modData.PZLinuxOnReward = PZLinuxNormalizeMoney(effectiveReward)
    modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. tostring(selectedContract.code or "")
    modData.PZLinuxContractLocationX = tonumber(previewResult.locationX) or 0
    modData.PZLinuxContractLocationY = tonumber(previewResult.locationY) or 0
    modData.PZLinuxContractLocationZ = tonumber(previewResult.locationZ) or 0
    modData.PZLinuxContractInfo = previewResult.info or ""
    modData.PZLinuxContractInfoName = previewResult.infoName or ""
    modData.PZLinuxContractInfoCount = PZLinuxNormalizeMoney(previewResult.infoCount)
    modData.PZLinuxContractNote = previewResult.note or ""
    modData.PZLinuxContractTargetName = previewResult.targetName or ""
    modData.PZLinuxOnZombieToKill = PZLinuxNormalizeMoney(previewResult.zombieToKill)
    PZLinuxContractsSetTypeFlags(modData, contractId)

    if contractId == 13 then
        -- Nothing is debited or handed over here: the player must go
        -- withdraw the physical cash themselves, from any ATM(s) they like,
        -- using the ordinary withdrawal mechanic (possibly emptying several
        -- along the way if no single one holds enough), then carry it all
        -- to the one hardcoded target ATM to deposit it.
        modData.PZLinuxContractAtmAmount = PZLinuxNormalizeMoney(previewResult.atmAmount)
    end

    local worldRecord = PZLinuxContractsCreateWorldContract(playerObj, selectedContract, contractId, previewResult)
    if not worldRecord then
        PZLinuxContractsClearState(modData)
        return { ok = false, error = "contract_creation_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    modData.PZLinuxContractId = worldRecord.id
    PZLinuxContractsReplaceContractNote(playerObj, worldRecord)
    PZLinuxContractsRemoveBoardContract(contractId, boardData.generatedHour)

    local cacheKey = PZLinuxGetPlayerKey(playerObj) .. ":" .. tostring(contractId)
    PZLinux.contractPreviews[cacheKey] = nil

    PZLinuxTransmitPlayerModData(playerObj)
    print(string.format(
        "[PZLinux Contracts] ACCEPT player=%s contractId=%d worldRecord=%s reward=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), contractId, tostring(worldRecord.id), effectiveReward))
    return {
        ok = true,
        requestId = requestId,
        contractId = contractId,
        code = selectedContract.code,
        reward = effectiveReward,
        questName = selectedContract.questName,
        cityId = selectedContract.cityId,
        locationId = previewResult.locationId,
        locationPool = previewResult.locationPool,
        locationX = modData.PZLinuxContractLocationX,
        locationY = modData.PZLinuxContractLocationY,
        locationZ = modData.PZLinuxContractLocationZ,
        locationCity = previewResult.locationCity,
        locationDescription = previewResult.locationDescription,
        locationDescriptionKey = previewResult.locationDescriptionKey,
        info = modData.PZLinuxContractInfo,
        infoName = modData.PZLinuxContractInfoName,
        infoCount = modData.PZLinuxContractInfoCount,
        targetName = modData.PZLinuxContractTargetName,
        zombieToKill = modData.PZLinuxOnZombieToKill,
        note = modData.PZLinuxContractNote,
        fullNote = previewResult.fullNote,
        worldContractId = modData.PZLinuxContractId,
        balance = PZLinuxLoadBankBalance(playerObj),
        activeContract = modData.PZLinuxActiveContract,
        contractKillZombie = modData.PZLinuxContractKillZombie,
        contractPickUp = modData.PZLinuxContractPickUp,
        contractManhunt = modData.PZLinuxContractManhunt,
        contractBlood = modData.PZLinuxContractBlood,
        contractCar = modData.PZLinuxContractCar,
        contractCapture = modData.PZLinuxContractCapture,
        contractCargo = modData.PZLinuxContractCargo,
        contractProtect = modData.PZLinuxContractProtect,
        contractMedical = modData.PZLinuxContractMedical,
        contractWeapon = modData.PZLinuxContractWeapon,
        contractSendComputer = modData.PZLinuxContractSendComputer,
        contractSendFridge = modData.PZLinuxContractSendFridge,
        contractAtmRefill = modData.PZLinuxContractAtmRefill,
        atmAmount = modData.PZLinuxContractAtmAmount,
    }
end

function PZLinuxContractsApplyCancel(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    if (tonumber(modData.PZLinuxActiveContract) or 0) ~= 1 then
        return { ok = false, error = "no_active_contract", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    -- Nothing to refund here: "Refill an ATM" never debits the bank or hands
    -- over cash at accept time, so cancelling has no special money to undo
    -- -- any cash the player already withdrew themselves along the way is
    -- simply theirs, exactly like it would be outside this contract.
    local dataName = modData.PZLinuxContractCompanyUp
    local reputationPenalty = PZLinux.Economy.contractCancelPenalty()
    local reputation = PZLinuxApplyReputationDelta(playerObj, -reputationPenalty)
    PZLinuxContractsUpdateCompanyPrice(dataName, "down")
    PZLinuxContractsMarkWorldContract(modData.PZLinuxContractId, "cancelled", playerObj)
    PZLinuxContractsRemoveContractNote(playerObj)
    PZLinuxContractsClearState(modData)
    PZLinuxTransmitPlayerModData(playerObj)

    print(string.format(
        "[PZLinux Contracts] CANCEL player=%s reputationPenalty=%d reputation=%s",
        tostring(PZLinuxGetPlayerKey(playerObj)), reputationPenalty, tostring(reputation)))

    return {
        ok = true,
        requestId = requestId,
        balance = PZLinuxLoadBankBalance(playerObj),
        reputation = reputation,
        reputationPenalty = reputationPenalty,
    }
end

function PZLinuxContractsBagContainsCorpse(bag)
    if not bag or not bag.getInventory then return false end
    local inventory = bag:getInventory()
    if not inventory then return false end
    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and (item:getFullType() == "Base.CorpseMale" or item:getFullType() == "Base.CorpseFemale") then
            return true
        end
    end
    return false
end

function PZLinuxContractsIsMoveableSprite(item, sprites)
    if not item or not instanceof or not instanceof(item, "Moveable") then return false end
    local worldSprite = item:getWorldSprite()
    for _, sprite in ipairs(sprites or {}) do
        if worldSprite == sprite then return true end
    end
    return false
end

function PZLinuxContractsIsComputerMoveable(item)
    return PZLinuxContractsIsMoveableSprite(item, {
        "appliances_com_01_72",
        "appliances_com_01_73",
        "appliances_com_01_74",
        "appliances_com_01_75",
    })
end

function PZLinuxContractsIsFridgeMoveable(item)
    return PZLinuxContractsIsMoveableSprite(item, {
        "appliances_refrigeration_01_0",
        "appliances_refrigeration_01_1",
        "appliances_refrigeration_01_2",
        "appliances_refrigeration_01_3",
        "appliances_refrigeration_01_4",
        "appliances_refrigeration_01_5",
        "appliances_refrigeration_01_6",
        "appliances_refrigeration_01_7",
        "appliances_refrigeration_01_8",
        "appliances_refrigeration_01_9",
        "appliances_refrigeration_01_10",
        "appliances_refrigeration_01_11",
        "appliances_refrigeration_01_12",
        "appliances_refrigeration_01_13",
        "appliances_refrigeration_01_14",
        "appliances_refrigeration_01_15",
        "appliances_refrigeration_01_22",
        "appliances_refrigeration_01_23",
        "appliances_refrigeration_01_24",
        "appliances_refrigeration_01_25",
        "appliances_refrigeration_01_26",
        "appliances_refrigeration_01_27",
        "appliances_refrigeration_01_28",
        "appliances_refrigeration_01_29",
        "appliances_refrigeration_01_30",
        "appliances_refrigeration_01_31",
        "appliances_refrigeration_01_32",
        "appliances_refrigeration_01_33",
        "appliances_refrigeration_01_34",
        "appliances_refrigeration_01_35",
        "appliances_refrigeration_01_36",
        "appliances_refrigeration_01_37",
        "appliances_refrigeration_01_40",
        "appliances_refrigeration_01_41",
        "appliances_refrigeration_01_42",
        "appliances_refrigeration_01_43",
    })
end

function PZLinuxContractsItemMatchesDelivery(item, modData, totalCountForContract)
    if not item or not modData then return false end
    local fullType = item:getFullType()
    local itemContractId = PZLinuxContractsGetEntityContractId(item)
    if itemContractId and itemContractId == modData.PZLinuxContractId then
        return fullType == "Base.Bag_ProtectiveCaseSmall"
            or fullType == "Base.Bag_Mail"
            or fullType == "Base.EmptyJar"
    end
    if fullType == "Base.Bag_ProtectiveCaseSmall" and modData.PZLinuxContractPickUp == 3 then return true end
    if PZLinuxContractsIsComputerMoveable(item) and modData.PZLinuxContractSendComputer == 1 then return true end
    if PZLinuxContractsIsFridgeMoveable(item) and modData.PZLinuxContractSendFridge == 1 then return true end
    if fullType == "Base.Bag_Mail" and PZLinuxContractsBagContainsCorpse(item) and modData.PZLinuxContractManhunt == 3 then return true end
    if fullType == "Base.EmptyJar" and modData.PZLinuxContractBlood == 3 then return true end
    if fullType == "Base.Bag_Mail" and PZLinuxContractsBagContainsCorpse(item) and modData.PZLinuxContractCapture == 3 then return true end
    if fullType == modData.PZLinuxContractInfo and modData.PZLinuxContractMedical == 1 and totalCountForContract then return true end
    if fullType == modData.PZLinuxContractInfo and modData.PZLinuxContractCar == 1 and totalCountForContract then return true end
    if fullType == modData.PZLinuxContractInfo and modData.PZLinuxContractWeapon == 1 and totalCountForContract then return true end
    return false
end

function PZLinuxContractsHasDepositItems(player)
    local playerObj = PZLinuxGetPlayer(player)
    local inventory = playerObj and playerObj:getInventory()
    local modData = playerObj and playerObj:getModData()
    if not inventory or not modData or (tonumber(modData.PZLinuxActiveContract) or 0) ~= 1 then return false end

    local items = inventory:getItems()
    local requiredType = modData.PZLinuxContractInfo
    local itemCount = 0
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and requiredType and item:getFullType() == requiredType then itemCount = itemCount + 1 end
    end

    local requiredCount = tonumber(modData.PZLinuxContractInfoCount) or 0
    local totalCountForContract = requiredCount > 0 and itemCount >= requiredCount
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local itemContractId = PZLinuxContractsGetEntityContractId(item)
        local sameWorldContract = not modData.PZLinuxContractId or modData.PZLinuxContractId == ""
            or not itemContractId or itemContractId == modData.PZLinuxContractId
        if sameWorldContract and PZLinuxContractsItemMatchesDelivery(item, modData, totalCountForContract) then
            return true
        end
    end
    return false
end

function PZLinuxMailboxGetActionState(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then return { ok = false, error = mailboxError, requestId = requestId } end

    local modData = playerObj:getModData()
    local hasDarkWebPickup = modData.PZLinuxOnItemBuyOnDarkWebStatus == 1
        and type(modData.PZLinuxOnItemBuyOnDarkWebQueue) == "string"
        and modData.PZLinuxOnItemBuyOnDarkWebQueue ~= ""
    local hasRequestPickup = modData.PZLinuxActiveRequest == 1
        and type(modData.PZLinuxOnItemRequestQueue) == "string"
        and modData.PZLinuxOnItemRequestQueue ~= ""

    return {
        ok = true,
        requestId = requestId,
        hasPickup = hasDarkWebPickup or hasRequestPickup,
        hasContractDeposit = PZLinuxContractsHasDepositItems(playerObj),
    }
end

function PZLinuxContractsApplyDeposit(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventory = playerObj:getInventory()
    local modData = playerObj:getModData()
    local items = inventory:getItems()
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local itemContractId = PZLinuxContractsGetEntityContractId(item)
        local taggedRecord = PZLinuxContractsGetWorldContract(itemContractId)
        if taggedRecord and taggedRecord.status ~= "completed" and taggedRecord.status ~= "cancelled" then
            PZLinuxContractsSyncWorldRecordToPlayer(playerObj, taggedRecord)
            modData = playerObj:getModData()
            break
        end
    end

    local itemCount = 0
    local requiredType = modData.PZLinuxContractInfo
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and requiredType and item:getFullType() == requiredType then
            itemCount = itemCount + 1
        end
    end

    local totalCountForContract = false
    if modData.PZLinuxContractInfoCount and itemCount >= modData.PZLinuxContractInfoCount then
        totalCountForContract = tonumber(modData.PZLinuxContractInfoCount) > 0
    end

    local removed = 0
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        local itemContractId = PZLinuxContractsGetEntityContractId(item)
        local sameWorldContract = not modData.PZLinuxContractId or modData.PZLinuxContractId == "" or not itemContractId or itemContractId == modData.PZLinuxContractId
        if sameWorldContract and PZLinuxContractsItemMatchesDelivery(item, modData, totalCountForContract) then
            if PZLinuxRemoveInventoryItem(playerObj, item) then
                removed = removed + 1
                if tonumber(modData.PZLinuxContractInfoCount) and tonumber(modData.PZLinuxContractInfoCount) > 0 then
                    modData.PZLinuxContractInfoCount = math.max(0, tonumber(modData.PZLinuxContractInfoCount) - 1)
                end
            end
        end
    end

    if removed > 0 and (not modData.PZLinuxContractInfoCount or tonumber(modData.PZLinuxContractInfoCount) <= 0) then
        modData.PZLinuxActiveContract = 9
        PZLinuxContractsMarkWorldContract(modData.PZLinuxContractId, "deposited", playerObj)
    end

    PZLinuxTransmitPlayerModData(playerObj)
    return {
        ok = true,
        requestId = requestId,
        removed = removed,
        worldContractId = modData.PZLinuxContractId,
        activeContract = modData.PZLinuxActiveContract,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

-- Depositing the withdrawn cash at the exact hardcoded ATM the contract
-- targets: removes the physical cash the player is carrying, refunds that
-- same amount to the bank (the withdrawal was only ever temporary), tops up
-- the target ATM's own cash reserve (the actual point of the contract), and
-- advances the contract to "ready to complete" so the existing generic
-- PZLinuxContractsApplyComplete pays out the reward.
function PZLinuxContractsApplyAtmRefillDeposit(player, atmRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    if tonumber(modData.PZLinuxContractAtmRefill) ~= 1 or tonumber(modData.PZLinuxActiveContract) ~= 1 then
        return { ok = false, error = "no_active_contract", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local targetX = tonumber(modData.PZLinuxContractLocationX)
    local targetY = tonumber(modData.PZLinuxContractLocationY)
    local targetZ = tonumber(modData.PZLinuxContractLocationZ)
    local refX = tonumber(atmRef and atmRef.x)
    local refY = tonumber(atmRef and atmRef.y)
    local refZ = tonumber(atmRef and atmRef.z)
    if refX ~= targetX or refY ~= targetY or refZ ~= targetZ then
        return { ok = false, error = "wrong_atm", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local atmObject = PZLinuxFindAtmObject(atmRef)
    if not atmObject then
        return { ok = false, error = "atm_not_found", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local amount = PZLinuxNormalizeMoney(modData.PZLinuxContractAtmAmount)
    if amount <= 0 then
        return { ok = false, error = "invalid_amount", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local inventoryCash = PZLinuxCountInventoryCash(playerObj)
    if inventoryCash < amount then
        return {
            ok = false,
            error = "not_enough_inventory_cash",
            requestId = requestId,
            inventoryCash = inventoryCash,
            balance = PZLinuxLoadBankBalance(playerObj),
        }
    end

    local removed = PZLinuxRemoveInventoryCash(playerObj, amount)
    if removed ~= amount then
        return { ok = false, error = "cash_remove_failed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local credit = PZLinuxApplyBankCredit(playerObj, amount, "atm-refill-refund", requestId)

    -- Clamp rather than reject: the player already handed over the cash and
    -- must still get their refund + reward regardless of whether this ATM
    -- happens to already be near its cap (e.g. from its own slow regen).
    -- The cap here is the general ATM.maxCash, not AtmRefill.targetCashMax
    -- (which only governs this ATM's near-empty starting roll) -- otherwise
    -- the deposit itself, always far larger than targetCashMax, would get
    -- clamped right back down to almost nothing and never actually refill it.
    local atmCash = PZLinuxAtmLoadCash(atmObject)
    local maxCash = tonumber(PZLinux.Config.ATM.maxCash) or 50000
    PZLinuxAtmSaveCash(atmObject, math.min(maxCash, atmCash + amount))

    modData.PZLinuxActiveContract = 9
    PZLinuxContractsMarkWorldContract(modData.PZLinuxContractId, "deposited", playerObj)
    PZLinuxTransmitPlayerModData(playerObj)

    return {
        ok = true,
        requestId = requestId,
        amount = amount,
        worldContractId = modData.PZLinuxContractId,
        activeContract = modData.PZLinuxActiveContract,
        balance = credit.balance or PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxContractsApplyComplete(player, _state, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData, pzlinux = PZLinuxGetModData(playerObj)
    local activeContract = tonumber(modData and modData.PZLinuxActiveContract)
    if not modData or (activeContract ~= 9 and activeContract ~= 10) then
        return { ok = false, error = "contract_not_completed", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local zombieCount = PZLinuxNormalizeMoney(modData.PZLinuxOnZombieDead)
    local reward = PZLinuxNormalizeMoney(modData.PZLinuxOnReward)
    local moneyEarned = reward + zombieCount * 5
    local completedContractTypeId = tonumber(modData.PZLinuxContractTypeId) or 0
    local credit = PZLinuxApplyBankCredit(playerObj, moneyEarned, "contract-complete", requestId)
    if not credit.ok then return credit end

    local completedWorldContractId = modData.PZLinuxContractId
    local completionReceiptId = completedWorldContractId
    if not completionReceiptId or completionReceiptId == "" then
        completionReceiptId = "legacy:" .. tostring(requestId)
    end
    pzlinux.contracts = pzlinux.contracts or {}
    local completionReceipt = {
        id = tostring(completionReceiptId),
        worldContractId = completedWorldContractId,
        contractId = completedContractTypeId,
        amount = moneyEarned,
        moneyEarned = moneyEarned,
        zombieCount = zombieCount,
        completedHour = getGameTime and getGameTime():getWorldAgeHours() or 0,
    }
    pzlinux.contracts.pendingCompletion = completionReceipt
    PZLinuxContractsUpdateCompanyPrice(modData.PZLinuxContractCompanyUp, "up")
    PZLinuxContractsMarkWorldContract(completedWorldContractId, "completed", playerObj)
    PZLinuxContractsRemoveContractNote(playerObj)
    PZLinuxContractsClearState(modData)
    PZLinuxApplyReputationDelta(playerObj, PZLinux.Economy.contractCompleteReward())
    PZLinuxTransmitPlayerModData(playerObj)

    return {
        ok = true,
        requestId = requestId,
        amount = moneyEarned,
        zombieCount = zombieCount,
        balance = PZLinuxLoadBankBalance(playerObj),
        reputation = pzlinux.player.reputation,
        completionReceipt = completionReceipt,
        tradingSnapshot = PZLinuxTradingBuildSnapshot(playerObj),
    }
end

function PZLinuxContractsAcknowledgeCompletion(player, receiptId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local _, pzlinux = PZLinuxGetModData(playerObj)
    pzlinux.contracts = pzlinux.contracts or {}
    local receipt = pzlinux.contracts.pendingCompletion
    if receipt and tostring(receipt.id) ~= tostring(receiptId or "") then
        return { ok = false, error = "receipt_mismatch", requestId = requestId }
    end
    pzlinux.contracts.pendingCompletion = nil
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, receiptId = receiptId }
end

function PZLinuxApplyReputationDelta(player, amount)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 1 end

    local _, pzlinux = PZLinuxGetModData(playerObj)
    if not pzlinux then return 1 end

    pzlinux.player.reputation = PZLinux.Economy.applyReputationDelta(pzlinux.player.reputation, amount)
    PZLinuxTransmitPlayerModData(playerObj)
    return pzlinux.player.reputation
end

function PZLinuxApplyReputationDecay(player, amount)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 1 end
    local _, pzlinux = PZLinuxGetModData(playerObj)
    if not pzlinux then return 1 end

    pzlinux.player.reputation = PZLinux.Economy.decayReputation(pzlinux.player.reputation, amount)
    PZLinuxTransmitPlayerModData(playerObj)
    return pzlinux.player.reputation
end

function PZLinuxReputationGetSnapshot(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local _, pzlinux = PZLinuxGetModData(playerObj)
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    local reputation = tonumber(pzlinux and pzlinux.player and pzlinux.player.reputation)
        or tonumber(config.baseline) or 1
    local baseline = tonumber(config.baseline) or 1
    local multiplier = PZLinux.Economy.reputationPurchaseMultiplier(reputation)
    local status, nextThreshold, nextStatus = PZLinux.Economy.reputationTier(reputation)

    local mailFrequency = "normal"
    if reputation < baseline then mailFrequency = "reduced"
    elseif reputation > baseline then mailFrequency = "improved" end

    return {
        ok = true,
        requestId = requestId,
        reputation = reputation,
        minimum = tonumber(config.minimum) or -99,
        maximum = tonumber(config.maximum) or 200,
        baseline = baseline,
        purchaseMultiplier = multiplier,
        purchaseModifierPercent = (multiplier - 1) * 100,
        status = status,
        nextStatus = nextStatus,
        nextThreshold = nextThreshold,
        pointsToNext = nextThreshold and math.max(0, nextThreshold - reputation) or nil,
        mailFrequency = mailFrequency,
        completionReward = PZLinux.Economy.contractCompleteReward(),
        cancellationPenalty = PZLinux.Economy.contractCancelPenalty(),
    }
end

function PZLinuxRequestReputationSnapshot(player, callback)
    local requestId = PZLinuxNextRequestId("reputation-snapshot")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxReputationSnapshot", { requestId = requestId }) then return requestId end
    PZLinuxDispatchCallback(PZLinuxReputationGetSnapshot(player, requestId))
    return requestId
end

function PZLinuxContractsTransmitSquareObject(square, obj)
    if square and square.transmitAddObjectToSquare then
        local objectIndex = obj and obj.getObjectIndex and obj:getObjectIndex() or -1
        square:transmitAddObjectToSquare(obj, objectIndex)
    end
    if obj and obj.transmitCompleteItemToClients then obj:transmitCompleteItemToClients() end
    if obj and obj.transmitUpdatedSpriteToClients then obj:transmitUpdatedSpriteToClients() end
    if square and square.transmitModdata then square:transmitModdata() end
end

local PZLinuxCargoObjectVersion = 3
local PZLinuxManhuntTargetVersion = 4
PZLinux.ManhuntTargets = PZLinux.ManhuntTargets or {}

local function PZLinuxContractsFindCargoObject(x, y, z, contractWorldId)
    if not getCell then return false end
    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local level = math.floor(tonumber(z) or 0)

    for offsetX = -5, 5 do
        for offsetY = -5, 5 do
            local square = getCell():getGridSquare(centerX + offsetX, centerY + offsetY, level)
            if square then
                for index = square:getObjects():size() - 1, 0, -1 do
                    local obj = square:getObjects():get(index)
                    if tostring(PZLinuxContractsGetEntityContractId(obj) or "") == tostring(contractWorldId or "")
                    and PZLinuxContractsGetEntityObjective(obj) == "cargo" then
                        return obj, square
                    end
                end
            end
        end
    end
    return nil, nil
end

local function PZLinuxContractsRemoveCargoObjectFromSquare(obj, square)
    if not obj or not square then return false end
    if square.transmitRemoveItemFromSquare then
        square:transmitRemoveItemFromSquare(obj)
    else
        square:removeTileObject(obj)
    end
    return true
end

function PZLinuxContractsRemoveCargoObject(x, y, z, contractWorldId)
    local obj, square = PZLinuxContractsFindCargoObject(x, y, z, contractWorldId)
    return PZLinuxContractsRemoveCargoObjectFromSquare(obj, square)
end

function PZLinuxContractsSpawnCargoObject(x, y, z, contractWorldId)
    if not getCell or not IsoThumpable then return false end
    local existingObject, existingSquare = PZLinuxContractsFindCargoObject(x, y, z, contractWorldId)
    if existingObject then
        local existingData = existingObject:getModData()
        if tonumber(existingData.PZLinuxCargoVersion) == PZLinuxCargoObjectVersion then
            existingData.PZLinuxContractId = contractWorldId
            existingData.PZLinuxContractObjective = "cargo"
            PZLinuxContractsTransmitSquareObject(existingSquare, existingObject)
            if existingObject.transmitModData then existingObject:transmitModData() end
            print("[PZLinux Cargo] reused and retransmitted v3 crate at "
                .. tostring(existingSquare:getX()) .. "," .. tostring(existingSquare:getY()) .. "," .. tostring(existingSquare:getZ())
                .. " contract=" .. tostring(contractWorldId))
            return true, false, existingSquare:getX(), existingSquare:getY(), existingSquare:getZ()
        end

        PZLinuxContractsRemoveCargoObjectFromSquare(existingObject, existingSquare)
        print("[PZLinux Cargo] replaced legacy crate version="
            .. tostring(existingData.PZLinuxCargoVersion or 0)
            .. " contract=" .. tostring(contractWorldId))
    end
    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local level = math.floor(tonumber(z) or 0)
    local square
    local fallbackSquare

    for radius = 0, 5 do
        for offsetX = -radius, radius do
            for offsetY = -radius, radius do
                if radius == 0 or math.abs(offsetX) == radius or math.abs(offsetY) == radius then
                    local candidate = getCell():getGridSquare(centerX + offsetX, centerY + offsetY, level)
                    if candidate then
                        fallbackSquare = fallbackSquare or candidate
                        if candidate:isFree(false) then
                            square = candidate
                            break
                        end
                    end
                end
            end
            if square then break end
        end
        if square then break end
    end
    square = square or fallbackSquare
    if not square then
        print("[PZLinux Cargo] spawn failed: no loaded square near "
            .. tostring(centerX) .. "," .. tostring(centerY) .. "," .. tostring(level)
            .. " contract=" .. tostring(contractWorldId))
        return false
    end

    local cargoSprite = tostring(PZLinux.Config.Contracts.cargoSprite or "carpentry_01_19")
    local obj = IsoThumpable.new(getCell(), square, cargoSprite, false, {})
    if not obj then
        print("[PZLinux Cargo] spawn failed: IsoThumpable creation returned nil"
            .. " contract=" .. tostring(contractWorldId))
        return false
    end
    obj:setName("PZLinux Cargo")
    obj:setAlphaAndTarget(1.0)
    obj:setIsThumpable(false)
    obj:setIsDismantable(false)
    obj:setCanBarricade(false)
    obj:setCanPassThrough(true)
    obj:setBlockAllTheSquare(false)
    local data = obj:getModData()
    data.PZLinuxContractId = contractWorldId
    data.PZLinuxContractObjective = "cargo"
    data.PZLinuxCargoVersion = PZLinuxCargoObjectVersion
    square:AddSpecialObject(obj)
    if obj.addToWorld then obj:addToWorld() end
    PZLinuxContractsTransmitSquareObject(square, obj)
    if obj.transmitModData then obj:transmitModData() end

    print("[PZLinux Cargo] spawned v3 crate sprite=" .. cargoSprite .. " at "
        .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
        .. " contract=" .. tostring(contractWorldId))
    return true, true, square:getX(), square:getY(), square:getZ()
end

local function PZLinuxContractsFindZombieSpawnSquare(x, y, z)
    if not getCell then return nil end
    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local level = math.floor(tonumber(z) or 0)

    local searchRadius = tonumber(PZLinux.Config.Contracts.objectiveSpawnSearchRadius) or 15
    for radius = 0, math.max(5, math.floor(searchRadius)) do
        for offsetX = -radius, radius do
            for offsetY = -radius, radius do
                if radius == 0 or math.abs(offsetX) == radius or math.abs(offsetY) == radius then
                    local square = getCell():getGridSquare(centerX + offsetX, centerY + offsetY, level)
                    if square and square:isFree(false) then return square end
                end
            end
        end
    end
    return nil
end

local function PZLinuxContractsFirstSpawnedZombie(spawned)
    if not spawned then return nil end
    if spawned.size and spawned.get and spawned:size() > 0 then return spawned:get(0) end
    return spawned[1]
end

local function PZLinuxContractsGetZombieOnlineId(zombie)
    if not zombie then return -1 end
    if zombie.getOnlineID then return tonumber(zombie:getOnlineID()) or -1 end
    return tonumber(zombie.OnlineID) or -1
end

local function PZLinuxContractsConfigureManhuntZombie(zombie, prepareReplication)
    if not zombie then return false end
    local data = zombie:getModData()
    data.PZLinuxManhuntVersion = PZLinuxManhuntTargetVersion
    if zombie.setTarget then zombie:setTarget(nil) end
    -- A useless server zombie is removed from B42's population replication before
    -- clients receive it. The client neutralizes it only after it becomes visible.
    if prepareReplication ~= false and zombie.setUseless then zombie:setUseless(false) end
    if zombie.setCanWalk then zombie:setCanWalk(false) end
    if zombie.setAlwaysKnockedDown then zombie:setAlwaysKnockedDown(true) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(true) end
    if zombie.resetModelNextFrame then zombie:resetModelNextFrame() end
    return true
end

function PZLinuxContractsSpawnZombieAt(x, y, z, contractWorldId, objectiveType)
    local square = PZLinuxContractsFindZombieSpawnSquare(x, y, z)
    if not square then
        print("[PZLinux Manhunt][server] no loaded free square near "
            .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
            .. " objective=" .. tostring(objectiveType)
            .. " contract=" .. tostring(contractWorldId))
        return false
    end

    local zombie
    local spawnMethod = "none"
    if addZombiesInOutfit then
        local ok, spawnedOrError = pcall(
            addZombiesInOutfit,
            square:getX(), square:getY(), square:getZ(), 1, nil, nil,
            false, false, false, objectiveType == "manhunt", 1
        )
        if ok then
            zombie = PZLinuxContractsFirstSpawnedZombie(spawnedOrError)
            if zombie then spawnMethod = "addZombiesInOutfit" end
        else
            print("[PZLinux Manhunt][server] addZombiesInOutfit failed: " .. tostring(spawnedOrError))
        end
    end
    if not zombie and createZombie then
        zombie = createZombie(square:getX(), square:getY(), square:getZ(), nil, 0, IsoDirections.S)
        if zombie then spawnMethod = "createZombie" end
    end
    if not zombie then
        print("[PZLinux Manhunt][server] no spawn helper created a zombie at "
            .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
            .. " contract=" .. tostring(contractWorldId))
        return false
    end

    if zombie.isExistInTheWorld and not zombie:isExistInTheWorld() and zombie.addToWorld then
        zombie:addToWorld()
    end
    PZLinuxContractsTagEntity(zombie, contractWorldId, objectiveType or "zombie", objectiveType ~= "manhunt")
    if objectiveType == "manhunt" then
        PZLinuxContractsConfigureManhuntZombie(zombie)
    end
    return true, zombie, square, spawnMethod
end

local function PZLinuxContractsFindTaggedZombies(contractWorldId, objectiveType)
    local matches = {}
    if not getCell then return matches end
    local zombies = getCell():getZombieList()
    if not zombies then return matches end

    for index = 0, zombies:size() - 1 do
        local zombie = zombies:get(index)
        if zombie
        and (not zombie.isDead or not zombie:isDead())
        and tostring(PZLinuxContractsGetEntityContractId(zombie) or "") == tostring(contractWorldId or "")
        and PZLinuxContractsGetEntityObjective(zombie) == objectiveType then
            table.insert(matches, zombie)
        end
    end
    return matches
end

local function PZLinuxContractsCountTaggedZombies(contractWorldId, objectiveType)
    if not getCell then return 0 end
    local zombies = getCell():getZombieList()
    if not zombies then return 0 end

    local count = 0
    for index = 0, zombies:size() - 1 do
        local zombie = zombies:get(index)
        if zombie
        and (not zombie.isDead or not zombie:isDead())
        and tostring(PZLinuxContractsGetEntityContractId(zombie) or "") == tostring(contractWorldId or "")
        and PZLinuxContractsGetEntityObjective(zombie) == objectiveType then
            count = count + 1
        end
    end
    return count
end

local function PZLinuxContractsEnsureManhuntZombie(record)
    if not record then return false, 0 end
    local runtimeTarget = PZLinux.ManhuntTargets[tostring(record.id)]
    if runtimeTarget
    and (not runtimeTarget.isDead or not runtimeTarget:isDead())
    and runtimeTarget.getSquare and runtimeTarget:getSquare() then
        PZLinuxContractsTagEntity(runtimeTarget, record.id, "manhunt", false)
        PZLinuxContractsConfigureManhuntZombie(runtimeTarget)
        return true, 0, runtimeTarget:getX(), runtimeTarget:getY(), runtimeTarget:getZ(),
            PZLinuxContractsGetZombieOnlineId(runtimeTarget)
    end
    PZLinux.ManhuntTargets[tostring(record.id)] = nil

    local existingTargets = PZLinuxContractsFindTaggedZombies(record.id, "manhunt")
    local existingZombie
    local searchRadius = tonumber(PZLinux.Config.Contracts.objectiveSpawnSearchRadius) or 15
    for _, candidate in ipairs(existingTargets) do
        local candidateData = candidate:getModData()
        local candidateDistance = math.max(
            math.abs(candidate:getX() - (tonumber(record.locationX) or 0)),
            math.abs(candidate:getY() - (tonumber(record.locationY) or 0))
        )
        if not existingZombie
        and tonumber(candidateData.PZLinuxManhuntVersion) == PZLinuxManhuntTargetVersion
        and candidateDistance <= searchRadius then
            existingZombie = candidate
        else
            PZLinuxContractsRemoveWorldEntity(candidate)
        end
    end
    if existingZombie then
        local existingOnlineId = PZLinuxContractsGetZombieOnlineId(existingZombie)
        PZLinux.ManhuntTargets[tostring(record.id)] = existingZombie
        PZLinuxContractsConfigureManhuntZombie(existingZombie)
        print("[PZLinux Manhunt][server] reused canonical target v4 onlineId="
            .. tostring(existingOnlineId)
            .. " removedDuplicates=" .. tostring(math.max(0, #existingTargets - 1))
            .. " at " .. tostring(existingZombie:getX()) .. ","
            .. tostring(existingZombie:getY()) .. "," .. tostring(existingZombie:getZ())
            .. " contract=" .. tostring(record.id))
        return true, 0, existingZombie:getX(), existingZombie:getY(), existingZombie:getZ(),
            existingOnlineId
    end
    local created, zombie, square, spawnMethod = PZLinuxContractsSpawnZombieAt(
        record.locationX,
        record.locationY,
        record.locationZ,
        record.id,
        "manhunt"
    )
    if not created then return false, 0 end
    PZLinux.ManhuntTargets[tostring(record.id)] = zombie
    local onlineId = PZLinuxContractsGetZombieOnlineId(zombie)
    local inWorld = not zombie.isExistInTheWorld or zombie:isExistInTheWorld()
    print("[PZLinux Manhunt][server] spawned network target v4 method=" .. tostring(spawnMethod)
        .. " onlineId=" .. tostring(onlineId)
        .. " inWorld=" .. tostring(inWorld)
        .. " at " .. tostring(square and square:getX() or zombie:getX()) .. ","
        .. tostring(square and square:getY() or zombie:getY()) .. ","
        .. tostring(square and square:getZ() or zombie:getZ())
        .. " contract=" .. tostring(record.id))
    return true, 1,
        square and square:getX() or zombie:getX(),
        square and square:getY() or zombie:getY(),
        square and square:getZ() or zombie:getZ(),
        onlineId
end

function PZLinuxContractsMaintainManhuntTargets()
    for contractWorldId, zombie in pairs(PZLinux.ManhuntTargets or {}) do
        local record = PZLinuxContractsGetWorldContract(contractWorldId)
        if not record or not PZLinuxContractsIsRecordStatus(record, "spawned")
        or not zombie or (zombie.isDead and zombie:isDead())
        or not zombie.getSquare or not zombie:getSquare() then
            PZLinux.ManhuntTargets[contractWorldId] = nil
        else
            PZLinuxContractsConfigureManhuntZombie(zombie, false)
        end
    end
end

local function PZLinuxContractsSpawnProtectZombies(record, count)
    if not record then return 0 end
    local spawnedCount = 0
    for _ = 1, math.max(0, tonumber(count) or 0) do
        local radius = ZombRand(20, 50)
        local direction = ZombRand(1, 5)
        local spawnX = tonumber(record.locationX) or 0
        local spawnY = tonumber(record.locationY) or 0
        if direction == 1 then spawnX, spawnY = spawnX + radius, spawnY + radius end
        if direction == 2 then spawnX, spawnY = spawnX - radius, spawnY - radius end
        if direction == 3 then spawnX, spawnY = spawnX + radius, spawnY - radius end
        if direction == 4 then spawnX, spawnY = spawnX - radius, spawnY + radius end
        if PZLinuxContractsSpawnZombieAt(spawnX, spawnY, record.locationZ, record.id, "protect") then
            spawnedCount = spawnedCount + 1
        end
    end
    return spawnedCount
end

function PZLinuxContractsSpawnProtectHorde(x, y, z, contractWorldId)
    local count = ZombRand(50, 200)
    return PZLinuxContractsSpawnProtectZombies({
        id = contractWorldId,
        locationX = x,
        locationY = y,
        locationZ = z,
    }, count)
end

function PZLinuxContractsGiveContractCase(playerObj, contractWorldId)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return false end

    local parcel = inventory:AddItem("Base.Bag_ProtectiveCaseSmall")
    if not parcel then return false end
    parcel:setName("Contract case")
    PZLinuxContractsTagEntity(parcel, contractWorldId, "package")
    local parcelInv = parcel:getInventory()
    local bonusRand = ZombRand(1, 6)
    parcelInv:AddItem("Base.Note")
    if bonusRand == 1 then
        parcelInv:AddItem("Base.Revolver")
        for _ = 1, ZombRand(1, 2000) do
            parcelInv:AddItem("Base.Money")
        end
    elseif bonusRand == 2 then
        parcelInv:AddItem("Base.Revolver")
    end
    PZLinuxSyncAddedInventoryItem(playerObj, parcel)
    return true
end

function PZLinuxContractsGiveMailCorpseBag(playerObj, bagName, contractWorldId)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return false end

    local parcel = inventory:AddItem("Base.Bag_Mail")
    if not parcel then return false end
    parcel:setName(bagName or "Contract target")
    PZLinuxContractsTagEntity(parcel, contractWorldId, "corpse")
    local corpse = parcel:getInventory():AddItem("Base.CorpseMale")
    PZLinuxContractsTagEntity(corpse, contractWorldId, "corpse")
    PZLinuxSyncAddedInventoryItem(playerObj, parcel)
    return true
end

function PZLinuxContractsGiveBloodJar(playerObj, contractWorldId)
    local inventory = playerObj and playerObj:getInventory()
    if not inventory then return false end

    local jar = inventory:AddItem("Base.EmptyJar")
    if not jar then return false end
    jar:setName("Blood for contract")
    PZLinuxContractsTagEntity(jar, contractWorldId, "blood")
    if jar.getFluidContainer and jar:getFluidContainer() then
        jar:getFluidContainer():addFluid(FluidType.Blood, 1)
    end
    PZLinuxSyncAddedInventoryItem(playerObj, jar)
    return true
end

function PZLinuxContractsGetEntityObjective(entity)
    if not entity or not entity.getModData then return nil end
    local data = entity:getModData()
    return data and data.PZLinuxContractObjective or nil
end

function PZLinuxContractsGetPlayerWorldRecord(player, expectedContractId)
    local playerObj = PZLinuxGetPlayer(player)
    local modData = playerObj and playerObj:getModData()
    if not playerObj or not modData then return nil end

    local worldData = PZLinuxContractsGetWorldData()
    local playerKey = PZLinuxGetPlayerKey(playerObj)
    local expectedId = tonumber(expectedContractId)
    local function isOwnedActiveRecord(candidate)
        if not candidate or tonumber(candidate.contractId) ~= expectedId then return false end
        if candidate.status == "completed" or candidate.status == "cancelled" then return false end
        local acceptedBy = tostring(candidate.acceptedBy or candidate.owner or "")
        return acceptedBy == playerKey
    end

    local requestedId = tostring(modData.PZLinuxContractId or "")
    local record = worldData.active[requestedId]
    if not isOwnedActiveRecord(record) then
        local indexedId = tostring(worldData.byPlayer[playerKey] or "")
        record = worldData.active[indexedId]
    end
    if not isOwnedActiveRecord(record) then
        record = nil
        for _, candidate in pairs(worldData.active) do
            if isOwnedActiveRecord(candidate)
            and (not record or (tonumber(candidate.acceptedHour) or 0) > (tonumber(record.acceptedHour) or 0)) then
                record = candidate
            end
        end
    end
    if not record then return nil end

    if requestedId ~= tostring(record.id) or worldData.byPlayer[playerKey] ~= record.id then
        print("[PZLinux Contracts][server] repaired active contract index player="
            .. tostring(playerKey)
            .. " requested=" .. tostring(requestedId)
            .. " canonical=" .. tostring(record.id))
        worldData.byPlayer[playerKey] = record.id
        PZLinuxContractsTransmitWorldData()
        PZLinuxContractsSyncWorldRecordToPlayer(playerObj, record)
    end
    return record
end

function PZLinuxContractsIsRecordStatus(record, ...)
    if not record then return false end
    for index = 1, select("#", ...) do
        if record.status == select(index, ...) then return true end
    end
    return false
end

function PZLinuxContractsValidateCanonicalInteraction(player, record, targetRef, maxDistance)
    local object, targetError = PZLinuxValidateWorldInteraction(player, targetRef, "object", maxDistance or 2)
    if targetError then return nil, targetError end
    local square = object:getSquare()
    if not square or math.abs(square:getZ() - (tonumber(record.locationZ) or 0)) > 0.1 then
        return nil, "wrong_contract_location"
    end
    local distance = math.max(
        math.abs(square:getX() - (tonumber(record.locationX) or 0)),
        math.abs(square:getY() - (tonumber(record.locationY) or 0))
    )
    if distance > 5 then return nil, "wrong_contract_location" end
    return object, nil
end

local function PZLinuxContractsFindManhuntRecordForBody(body)
    if not body or not body.getSquare then return nil end
    local square = body:getSquare()
    if not square then return nil end

    local taggedRecord = PZLinuxContractsGetWorldContract(PZLinuxContractsGetEntityContractId(body))
    if taggedRecord
    and tonumber(taggedRecord.contractId) == 3
    and PZLinuxContractsIsRecordStatus(taggedRecord, "target_down") then
        return taggedRecord
    end

    local worldData = PZLinuxContractsGetWorldData()
    for _, record in pairs(worldData.active or {}) do
        if tonumber(record.contractId) == 3
        and PZLinuxContractsIsRecordStatus(record, "target_down") then
            local targetX = tonumber(record.targetDeathX) or tonumber(record.locationX) or 0
            local targetY = tonumber(record.targetDeathY) or tonumber(record.locationY) or 0
            local targetZ = tonumber(record.targetDeathZ) or tonumber(record.locationZ) or 0
            local distance = math.max(
                math.abs(square:getX() - targetX),
                math.abs(square:getY() - targetY)
            )
            if square:getZ() == targetZ and distance <= 2 then return record end
        end
    end
    return nil
end

function PZLinuxContractsRemoveWorldEntity(entity)
    if not entity then return false end
    if entity.setTarget then entity:setTarget(nil) end
    if entity.setUseless then entity:setUseless(true) end
    if entity.removeFromWorld then entity:removeFromWorld() end
    if entity.removeFromSquare then entity:removeFromSquare() end
    return true
end

function PZLinuxContractsSyncRecordToParticipants(record)
    if not record then return end
    local synced = {}
    local function syncPlayer(playerObj)
        if not playerObj or synced[playerObj] then return end
        local modData = playerObj:getModData()
        if modData and modData.PZLinuxContractId == record.id then
            synced[playerObj] = true
            PZLinuxContractsSyncWorldRecordToPlayer(playerObj, record)
        end
    end

    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players then
            for index = 0, players:size() - 1 do syncPlayer(players:get(index)) end
        end
    end
    if getPlayer then syncPlayer(getPlayer()) end
end

function PZLinuxContractsUpdateKillNote(playerObj, record)
    if not playerObj or not record then return false end
    return PZLinuxContractsReplaceContractNote(playerObj, record)
end

function PZLinuxContractsIsPlayerCharacter(character)
    if not character then return false end
    if instanceof then return instanceof(character, "IsoPlayer") end
    return character.getUsername ~= nil or character.getPlayerNum ~= nil
end

function PZLinuxContractsCreditZombieKill(player, record, amount)
    if not PZLinuxContractsIsPlayerCharacter(player) then return false end
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not record then return false end
    local contractId = tonumber(record.contractId)
    local credited = math.max(1, math.floor(tonumber(amount) or 1))
    local previousCount = tonumber(record.zombieCount) or 0
    if contractId == 1 then
        local zombieTarget = tonumber(record.zombieToKill) or 0
        if zombieTarget <= 0 then
            zombieTarget = 10
            record.zombieToKill = zombieTarget
        end
        credited = math.min(credited, math.max(0, zombieTarget - previousCount))
        if credited <= 0 then return false end
    elseif contractId == 4 then
        credited = math.min(credited, math.max(0, 1 - previousCount))
        if credited <= 0 then return false end
    end
    record.zombieCount = previousCount + credited
    if contractId == 1 then
        local zombieTarget = tonumber(record.zombieToKill) or 10
        if record.zombieCount >= zombieTarget then
            record.status = "ready_to_complete"
        else
            record.status = "in_progress"
        end
    elseif contractId == 8 and record.zombieCount >= 10 then
        record.status = "protect_clear"
    end
    record.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or record.updatedHour
    PZLinuxContractsSyncRecordToParticipants(record)
    if contractId == 1 then
        PZLinuxContractsUpdateKillNote(playerObj, record)
    end
    PZLinuxContractsTransmitWorldData()
    print("[PZLinux Contracts] credited " .. tostring(credited)
        .. " zombie kill(s) to " .. tostring(PZLinuxGetPlayerKey(playerObj))
        .. " contract=" .. tostring(record.id)
        .. " progress=" .. tostring(record.zombieCount)
        .. "/" .. tostring(record.zombieToKill or 0))
    return true
end

function PZLinuxContractsReconcilePlayerZombieKills(player, suppliedRecord)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not playerObj.getZombieKills then return false end

    local record = suppliedRecord
    if not record then
        local modData = playerObj:getModData()
        record = modData and PZLinuxContractsGetWorldContract(modData.PZLinuxContractId) or nil
    end
    if not record or not PZLinuxContractsIsRecordStatus(record, "accepted", "in_progress") then
        return false
    end

    local contractId = tonumber(record.contractId)
    if contractId ~= 1 and contractId ~= 4 then return false end

    local currentKills = math.max(0, math.floor(tonumber(playerObj:getZombieKills()) or 0))
    local previousKills = tonumber(record.playerZombieKills)
    record.playerZombieKills = currentKills
    if previousKills == nil or currentKills < previousKills then
        record.pendingZombieKillCredits = 0
        PZLinuxContractsTransmitWorldData()
        return false
    end
    if currentKills == previousKills then
        return false
    end

    local observedKills = currentKills - previousKills
    local pendingCredits = math.max(0, math.floor(tonumber(record.pendingZombieKillCredits) or 0))
    local absorbedKills = math.min(observedKills, pendingCredits)
    record.pendingZombieKillCredits = pendingCredits - absorbedKills
    local uncreditedKills = observedKills - absorbedKills
    if uncreditedKills <= 0 then
        PZLinuxContractsTransmitWorldData()
        return false
    end

    return PZLinuxContractsCreditZombieKill(playerObj, record, uncreditedKills)
end

function PZLinuxContractsResolveZombieKiller(zombie)
    if not zombie then return nil, "missing_zombie" end

    local attacker = zombie.getAttackedBy and zombie:getAttackedBy() or nil
    if PZLinuxContractsIsPlayerCharacter(attacker) then
        return PZLinuxGetPlayer(attacker), "attacked_by"
    end

    local ownerOk, authOwnerPlayer = pcall(function()
        return zombie.authOwnerPlayer
    end)
    if ownerOk and PZLinuxContractsIsPlayerCharacter(authOwnerPlayer) then
        return PZLinuxGetPlayer(authOwnerPlayer), "network_owner"
    end

    return nil, "unattributed"
end

local function PZLinuxContractsResolveManhuntDeath(zombie, taggedRecord, objectiveType)
    if taggedRecord
    and objectiveType == "manhunt"
    and PZLinuxContractsIsRecordStatus(taggedRecord, "spawned") then
        return taggedRecord, "moddata"
    end

    local deadOnlineId = PZLinuxContractsGetZombieOnlineId(zombie)
    for contractWorldId, target in pairs(PZLinux.ManhuntTargets or {}) do
        local sameEntity = target == zombie
        local targetOnlineId = PZLinuxContractsGetZombieOnlineId(target)
        local sameOnlineId = deadOnlineId >= 0 and targetOnlineId == deadOnlineId
        if sameEntity or sameOnlineId then
            local record = PZLinuxContractsGetWorldContract(contractWorldId)
            if record and PZLinuxContractsIsRecordStatus(record, "spawned") then
                return record, sameEntity and "runtime_entity" or "online_id"
            end
        end
    end
    return nil, "unmatched"
end

function PZLinuxContractsApplyServerZombieDeath(zombie)
    if not zombie then return false end
    local contractWorldId = PZLinuxContractsGetEntityContractId(zombie)
    local objectiveType = PZLinuxContractsGetEntityObjective(zombie)
    local taggedRecord = PZLinuxContractsGetWorldContract(contractWorldId)
    local changed = false

    local manhuntRecord, manhuntSource = PZLinuxContractsResolveManhuntDeath(zombie, taggedRecord, objectiveType)
    if manhuntRecord then
        taggedRecord = manhuntRecord
        objectiveType = "manhunt"
        PZLinux.ManhuntTargets[tostring(manhuntRecord.id)] = nil
        manhuntRecord.status = "target_down"
        manhuntRecord.targetKilled = true
        manhuntRecord.targetDeathX = zombie:getX()
        manhuntRecord.targetDeathY = zombie:getY()
        manhuntRecord.targetDeathZ = zombie:getZ()
        manhuntRecord.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or manhuntRecord.updatedHour
        print("[PZLinux Manhunt][server] target down contract=" .. tostring(manhuntRecord.id)
            .. " resolvedBy=" .. tostring(manhuntSource)
            .. " at=" .. tostring(manhuntRecord.targetDeathX) .. ","
            .. tostring(manhuntRecord.targetDeathY) .. "," .. tostring(manhuntRecord.targetDeathZ))
        PZLinuxContractsSyncRecordToParticipants(manhuntRecord)
        changed = true
    end

    local attacker, attackerSource = PZLinuxContractsResolveZombieKiller(zombie)
    if PZLinuxContractsIsPlayerCharacter(attacker) then
        if taggedRecord and objectiveType == "protect" and PZLinuxContractsIsRecordStatus(taggedRecord, "protect_started") then
            changed = PZLinuxContractsCreditZombieKill(attacker, taggedRecord) or changed
        end

        local activeRecord = PZLinuxContractsGetPlayerWorldRecord(attacker, 1)
            or PZLinuxContractsGetPlayerWorldRecord(attacker, 4)
        if activeRecord and tonumber(activeRecord.contractId) == 4
        and (tonumber(activeRecord.zombieCount) or 0) >= 1 then
            activeRecord = nil
        end
        if activeRecord and PZLinuxContractsIsRecordStatus(activeRecord, "accepted", "in_progress") then
            local reconciled = PZLinuxContractsReconcilePlayerZombieKills(attacker, activeRecord)
            if reconciled then
                changed = true
            else
                activeRecord.pendingZombieKillCredits =
                    math.max(0, math.floor(tonumber(activeRecord.pendingZombieKillCredits) or 0)) + 1
                changed = PZLinuxContractsCreditZombieKill(attacker, activeRecord) or changed
                if changed then
                    print("[PZLinux Contracts] zombie killer resolved from "
                        .. tostring(attackerSource) .. " contract=" .. tostring(activeRecord.id))
                end
            end
        end
    end

    if changed then PZLinuxContractsTransmitWorldData() end
    return changed
end

function PZLinuxContractsApplyWorldEvent(player, eventName, args, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    args = args or {}
    local worldRecord
    local contractWorldId
    local spawned = 0
    local spawnX
    local spawnY
    local spawnZ
    local spawnEntityId
    local function reject(errorCode)
        return { ok = false, error = errorCode, requestId = requestId, event = eventName }
    end
    local function usePlayerRecord(expectedContractId, ...)
        local record = PZLinuxContractsGetPlayerWorldRecord(playerObj, expectedContractId)
        if not record then return nil, "invalid_active_contract" end
        if not PZLinuxContractsIsRecordStatus(record, ...) then return nil, "invalid_contract_state" end
        worldRecord = record
        contractWorldId = record.id
        return record, nil
    end

    if eventName == "zombieKilled" then
        return reject("server_event_only")
    elseif eventName == "spawnManhunt" then
        local playerModData = playerObj:getModData()
        print("[PZLinux Manhunt][server] spawn request player="
            .. tostring(playerObj.getUsername and playerObj:getUsername() or "unknown")
            .. " active=" .. tostring(playerModData.PZLinuxActiveContract)
            .. " flag=" .. tostring(playerModData.PZLinuxContractManhunt)
            .. " worldContract=" .. tostring(playerModData.PZLinuxContractId))
        local record, recordError = usePlayerRecord(3, "accepted", "spawned")
        if recordError then
            print("[PZLinux Manhunt][server] rejected: " .. tostring(recordError))
            return reject(recordError)
        end
        local activationRadius = tonumber(PZLinux.Config.Contracts.objectiveActivationRadius) or 80
        if not PZLinuxIsPlayerNearPosition(
            playerObj,
            record.locationX,
            record.locationY,
            record.locationZ,
            activationRadius
        ) then
            print("[PZLinux Manhunt][server] rejected: too_far_from_contract player="
                .. tostring(math.floor(playerObj:getX())) .. "," .. tostring(math.floor(playerObj:getY()))
                .. " target=" .. tostring(record.locationX) .. "," .. tostring(record.locationY))
            return reject("too_far_from_contract")
        end
        local restored
        restored, spawned, spawnX, spawnY, spawnZ, spawnEntityId = PZLinuxContractsEnsureManhuntZombie(record)
        if not restored then
            print("[PZLinux Manhunt][server] rejected: spawn_failed contract=" .. tostring(record.id))
            return reject("spawn_failed")
        end
        record.spawned = true
        record.status = "spawned"
        record.spawnX = spawnX
        record.spawnY = spawnY
        record.spawnZ = spawnZ
        record.spawnEntityId = spawnEntityId
    elseif eventName == "spawnCargo" then
        local record, recordError = usePlayerRecord(7, "accepted", "spawned")
        if recordError then return reject(recordError) end
        if not PZLinuxIsPlayerNearPosition(playerObj, record.locationX, record.locationY, record.locationZ, 50) then return reject("too_far_from_contract") end
        local cargoReady, cargoCreated
        cargoReady, cargoCreated, spawnX, spawnY, spawnZ = PZLinuxContractsSpawnCargoObject(
            record.locationX,
            record.locationY,
            record.locationZ,
            record.id
        )
        if not cargoReady then return reject("spawn_failed") end
        spawned = cargoCreated and 1 or 0
        record.spawned = true
        record.status = "spawned"
        record.spawnX = spawnX
        record.spawnY = spawnY
        record.spawnZ = spawnZ
    elseif eventName == "clearCargo" then
        return reject("server_event_only")
    elseif eventName == "startProtect" then
        local record, recordError = usePlayerRecord(8, "accepted")
        if recordError then return reject(recordError) end
        local _, targetError = PZLinuxContractsValidateCanonicalInteraction(playerObj, record, args.target, 2)
        if targetError then return reject(targetError) end
        spawned = PZLinuxContractsSpawnProtectHorde(record.locationX, record.locationY, record.locationZ, record.id)
        record.spawned = true
        record.status = "protect_started"
        record.spawnedCount = spawned
    elseif eventName == "restoreProtect" then
        local record, recordError = usePlayerRecord(8, "protect_started")
        if recordError then return reject(recordError) end
        if not PZLinuxIsPlayerNearPosition(playerObj, record.locationX, record.locationY, record.locationZ, 50) then return reject("too_far_from_contract") end
        local remaining = math.max(0, 10 - (tonumber(record.zombieCount) or 0))
        local active = PZLinuxContractsCountTaggedZombies(record.id, "protect")
        spawned = PZLinuxContractsSpawnProtectZombies(record, math.max(0, remaining - active))
        record.spawnedCount = (tonumber(record.spawnedCount) or 0) + spawned
    elseif eventName == "finishProtect" then
        local record, recordError = usePlayerRecord(8, "protect_clear")
        if recordError then return reject(recordError) end
        local _, targetError = PZLinuxContractsValidateCanonicalInteraction(playerObj, record, args.target, 2)
        if targetError then return reject(targetError) end
        record.status = "ready_to_complete"
    elseif eventName == "pickupPackage" then
        local record, recordError = usePlayerRecord(2, "accepted", "in_progress")
        if recordError then return reject(recordError) end
        local packageRadius = tonumber(PZLinux.Config.Contracts.packageInteractionRadius) or 5
        if not PZLinuxIsPlayerNearPosition(playerObj, record.locationX, record.locationY, record.locationZ, packageRadius) then
            return reject("too_far_from_contract")
        end
        if not PZLinuxContractsGiveContractCase(playerObj, record.id) then return reject("item_creation_failed") end
        record.status = "objective_taken"
    elseif eventName == "takeCargo" then
        local record, recordError = usePlayerRecord(7, "accepted", "spawned")
        if recordError then return reject(recordError) end
        local cargoRadius = tonumber(PZLinux.Config.Contracts.packageInteractionRadius) or 5
        if not PZLinuxIsPlayerNearPosition(playerObj, record.locationX, record.locationY, record.locationZ, cargoRadius) then
            return reject("too_far_from_contract")
        end
        PZLinuxContractsRemoveCargoObject(record.locationX, record.locationY, record.locationZ, record.id)
        worldRecord.status = "ready_to_complete"
    elseif eventName == "decapitate" then
        local body, targetError = PZLinuxValidateWorldInteraction(playerObj, args.target, "body", 2)
        if targetError then return reject(targetError) end
        if body.isZombie and not body:isZombie() then return reject("invalid_contract_target") end
        worldRecord = PZLinuxContractsFindManhuntRecordForBody(body)
        if not worldRecord then return reject("invalid_contract_target") end
        contractWorldId = worldRecord.id
        PZLinuxContractsSyncWorldRecordToPlayer(playerObj, worldRecord)
        if not PZLinuxContractsGiveMailCorpseBag(playerObj, "Cut target", worldRecord.id) then return reject("item_creation_failed") end
        PZLinuxContractsRemoveWorldEntity(body)
        worldRecord.status = "objective_taken"
    elseif eventName == "blood" then
        local record, recordError = usePlayerRecord(4, "accepted", "in_progress")
        if recordError then return reject(recordError) end
        if (tonumber(record.zombieCount) or 0) < 1 then return reject("no_verified_zombie_kill") end
        local body, targetError = PZLinuxValidateWorldInteraction(playerObj, args.target, "body", 2)
        if targetError then return reject(targetError) end
        if body.isZombie and not body:isZombie() then return reject("invalid_contract_target") end
        if not PZLinuxContractsGiveBloodJar(playerObj, record.id) then return reject("item_creation_failed") end
        record.status = "objective_taken"
    elseif eventName == "capture" then
        local record, recordError = usePlayerRecord(6, "accepted", "in_progress")
        if recordError then return reject(recordError) end
        local zombie, targetError = PZLinuxValidateWorldInteraction(playerObj, args.target, "zombie", 2)
        if targetError then return reject(targetError) end
        if zombie.isDead and zombie:isDead() then return reject("invalid_contract_target") end
        if not PZLinuxContractsGiveMailCorpseBag(playerObj, "Zombie captured alive", record.id) then return reject("item_creation_failed") end
        PZLinuxContractsRemoveWorldEntity(zombie)
        record.status = "objective_taken"
    else
        return reject("invalid_event")
    end

    PZLinuxContractsSyncWorldRecordToPlayer(playerObj, worldRecord)
    local modData = playerObj:getModData()
    local _, pzlinux = PZLinuxGetModData(playerObj)
    worldRecord.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or worldRecord.updatedHour
    PZLinuxContractsTransmitWorldData()
    return {
        ok = true,
        requestId = requestId,
        event = eventName,
        worldContractId = contractWorldId,
        contractId = worldRecord and worldRecord.contractId or nil,
        worldStatus = worldRecord and worldRecord.status or "",
        spawned = spawned,
        spawnX = spawnX,
        spawnY = spawnY,
        spawnZ = spawnZ,
        spawnEntityId = spawnEntityId,
        locationX = worldRecord and worldRecord.locationX or nil,
        locationY = worldRecord and worldRecord.locationY or nil,
        locationZ = worldRecord and worldRecord.locationZ or nil,
        activeContract = modData.PZLinuxActiveContract,
        zombieCount = modData.PZLinuxOnZombieDead,
        contractManhunt = modData.PZLinuxContractManhunt,
        contractCargo = modData.PZLinuxContractCargo,
        contractProtect = modData.PZLinuxContractProtect,
        contractPickUp = modData.PZLinuxContractPickUp,
        contractBlood = modData.PZLinuxContractBlood,
        contractCapture = modData.PZLinuxContractCapture,
        reputation = pzlinux and pzlinux.player and pzlinux.player.reputation or 1,
    }
end

function PZLinuxRequestContractWorldEvent(player, eventName, args, callback)
    local requestId = PZLinuxNextRequestId("contract-world")
    PZLinuxRegisterCallback(requestId, callback)
    args = args or {}
    args.requestId = requestId
    args.event = eventName
    if PZLinuxSendClientCommand("PZLinuxContractWorldEvent", args) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyWorldEvent(player, eventName, args, requestId))
    return requestId
end

function PZLinuxRequestContractsBoard(player, callback)
    local requestId = PZLinuxNextRequestId("contracts-board")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxContractsBoard", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsGetBoard(player, requestId))
    return requestId
end

function PZLinuxRequestAdminForceContract(player, contractId, callback)
    local requestId = PZLinuxNextRequestId("contract-admin-force")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, contractId = tonumber(contractId) }
    if PZLinuxSendClientCommand("PZLinuxContractAdminForce", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxContractsAdminForceBoard(player, contractId, requestId))
    return requestId
end

function PZLinuxRequestAdminAddFunds(player, amount, callback)
    local requestId = PZLinuxNextRequestId("admin-add-funds")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, amount = tonumber(amount) }
    if PZLinuxSendClientCommand("PZLinuxContractAdminAddFunds", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxContractsAdminAddFunds(player, amount, requestId))
    return requestId
end

function PZLinuxRequestAdminForceMail(player, callback)
    local requestId = PZLinuxNextRequestId("admin-force-mail")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId }
    if PZLinuxSendClientCommand("PZLinuxContractAdminForceMail", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxContractsAdminForceMail(player, requestId))
    return requestId
end

function PZLinuxRequestAdminListOnlinePlayers(player, callback)
    local requestId = PZLinuxNextRequestId("admin-list-players")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId }
    if PZLinuxSendClientCommand("PZLinuxAdminListOnlinePlayers", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxAdminListOnlinePlayers(player, requestId))
    return requestId
end

function PZLinuxRequestAdminGetPlayerBalance(player, targetUsername, callback)
    local requestId = PZLinuxNextRequestId("admin-get-balance")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, targetUsername = targetUsername }
    if PZLinuxSendClientCommand("PZLinuxAdminGetPlayerBalance", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxAdminGetPlayerBalance(player, targetUsername, requestId))
    return requestId
end

function PZLinuxRequestAdminSetPlayerBalance(player, targetUsername, amount, callback)
    local requestId = PZLinuxNextRequestId("admin-set-balance")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, targetUsername = targetUsername, amount = tonumber(amount) }
    if PZLinuxSendClientCommand("PZLinuxAdminSetPlayerBalance", args) then return requestId end
    PZLinuxDispatchCallback(PZLinuxAdminSetPlayerBalance(player, targetUsername, amount, requestId))
    return requestId
end

function PZLinuxRequestContractSync(player, callback)
    local requestId = PZLinuxNextRequestId("contract-sync")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxContractSync", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsGetActiveState(player, requestId))
    return requestId
end

function PZLinuxRequestContractPreview(player, contractId, callback)
    local requestId = PZLinuxNextRequestId("contract-preview")
    PZLinuxRegisterCallback(requestId, callback)
    local state = { requestId = requestId, contractId = tonumber(contractId) }
    if PZLinuxSendClientCommand("PZLinuxContractPreview", state) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsGetPreview(player, contractId, requestId))
    return requestId
end

function PZLinuxRequestContractAccept(player, contractId, callback)
    local requestId = PZLinuxNextRequestId("contract-accept")
    PZLinuxRegisterCallback(requestId, callback)
    local state = { requestId = requestId, contractId = tonumber(contractId) }
    if PZLinuxSendClientCommand("PZLinuxContractAccept", state) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyAccept(player, state, requestId))
    return requestId
end

function PZLinuxRequestContractCancel(player, callback)
    local requestId = PZLinuxNextRequestId("contract-cancel")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxContractCancel", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyCancel(player, requestId))
    return requestId
end

function PZLinuxRequestContractDeposit(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("contract-deposit")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxContractDeposit", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyDeposit(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestContractAtmRefillDeposit(player, atmObject, callback)
    local requestId = PZLinuxNextRequestId("contract-atm-refill-deposit")
    local atmRef = PZLinuxGetAtmReference(atmObject)
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxContractAtmRefillDeposit", { requestId = requestId, atm = atmRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyAtmRefillDeposit(player, atmRef, requestId))
    return requestId
end

function PZLinuxRequestContractComplete(player, callback)
    local requestId = PZLinuxNextRequestId("contract-complete")
    PZLinuxRegisterCallback(requestId, callback)
    local state = { requestId = requestId }
    if PZLinuxSendClientCommand("PZLinuxContractComplete", state) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsApplyComplete(player, state, requestId))
    return requestId
end

function PZLinuxRequestContractCompletionAck(player, receiptId, callback)
    local requestId = PZLinuxNextRequestId("contract-completion-ack")
    PZLinuxRegisterCallback(requestId, callback)
    local state = { requestId = requestId, receiptId = tostring(receiptId or "") }
    if PZLinuxSendClientCommand("PZLinuxContractCompletionAck", state) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxContractsAcknowledgeCompletion(player, state.receiptId, requestId))
    return requestId
end

function generateUsername()
    local prefixes = {"Xx", "Dark", "Neo", "Cyber", "Red", "Blue", "Fire", "Frost", "Shadow", "Ghost"}
    local suffixes = {"99", "77", "Pro", "X", "V2", "Elite", "Bot", "Z", "Master", "King"}
    local middle = {"_", ".", ""}

    local name = prefixes[ZombRand(1, #prefixes + 1)] ..
                 middle[ZombRand(1, #middle + 1)] ..
                 suffixes[ZombRand(1, #suffixes + 1)]

    return name
end

function PZLinuxGenerateRandomName()
    local names = {
        { id = 1, first = "Jame", last = "Smith" },
        { id = 2, first = "Mary", last = "Johnson" },
        { id = 3, first = "Robert", last = "Williams" },
        { id = 4, first = "Patricia", last = "Brown" },
        { id = 5, first = "John", last = "Jones" },
        { id = 6, first = "Jennifer", last = "Garcia" },
        { id = 7, first = "Michael", last = "Miller" },
        { id = 8, first = "Linda", last = "Davis" },
        { id = 9, first = "William", last = "Rodriguez" },
        { id = 10, first = "Elizabeth", last = "Martinez" },
        { id = 11, first = "David", last = "Hernandez" },
        { id = 12, first = "Barbara", last = "Lopez" },
        { id = 13, first = "Richard", last = "Gonzalez" },
        { id = 14, first = "Susan", last = "Wilson" },
        { id = 15, first = "Joseph", last = "Anderson" },
        { id = 16, first = "Jessica", last = "Thomas" },
        { id = 17, first = "Thomas", last = "Taylor" },
        { id = 18, first = "Sarah", last = "Moore" },
        { id = 19, first = "Charles", last = "Jackson" },
        { id = 20, first = "Karen", last = "Martin" },
        { id = 21, first = "Christopher", last = "Lee" },
        { id = 22, first = "Nancy", last = "Perez" },
        { id = 23, first = "Daniel", last = "Thompson" },
        { id = 24, first = "Betty", last = "White" },
        { id = 25, first = "Matthew", last = "Harris" },
        { id = 26, first = "Sandra", last = "Sanchez" },
        { id = 27, first = "Anthony", last = "Clark" },
        { id = 28, first = "Ashley", last = "Ramirez" },
        { id = 29, first = "Mark", last = "Lewis" },
        { id = 30, first = "Donna", last = "Robinson" },
        { id = 31, first = "Paul", last = "Walker" },
        { id = 32, first = "Emily", last = "Young" },
        { id = 33, first = "Steven", last = "Allen" },
        { id = 34, first = "Stephanie", last = "King" },
        { id = 35, first = "Andrew", last = "Wright" },
        { id = 36, first = "Melissa", last = "Scott" },
        { id = 37, first = "Kenneth", last = "Torres" },
        { id = 38, first = "Amy", last = "Nguyen" },
        { id = 39, first = "Joshua", last = "Hill" },
        { id = 40, first = "Angela", last = "Flores" },
        { id = 41, first = "Kevin", last = "Green" },
        { id = 42, first = "Sharon", last = "Adams" },
        { id = 43, first = "Brian", last = "Nelson" },
        { id = 44, first = "Laura", last = "Baker" },
        { id = 45, first = "George", last = "Hall" },
        { id = 46, first = "Kimberly", last = "Rivera" },
        { id = 47, first = "Edward", last = "Campbell" },
        { id = 48, first = "Deborah", last = "Mitchell" },
        { id = 49, first = "Jason", last = "Carter" },
        { id = 50, first = "Michelle", last = "Roberts" },
        { id = 51, first = "Jeffrey", last = "Gomez" },
        { id = 52, first = "Emily", last = "Phillips" },
        { id = 53, first = "Ryan", last = "Evans" },
        { id = 54, first = "Carol", last = "Turner" },
        { id = 55, first = "Jacob", last = "Diaz" },
        { id = 56, first = "Rebecca", last = "Parker" },
        { id = 57, first = "Gary", last = "Edwards" },
        { id = 58, first = "Cynthia", last = "Collins" },
        { id = 59, first = "Nicholas", last = "Stewart" },
        { id = 60, first = "Kathleen", last = "Morris" },
        { id = 61, first = "Eric", last = "Rogers" },
        { id = 62, first = "Shirley", last = "Reed" },
        { id = 63, first = "Stephen", last = "Cook" },
        { id = 64, first = "Anna", last = "Morgan" },
        { id = 65, first = "Jonathan", last = "Bell" },
        { id = 66, first = "Brenda", last = "Murphy" },
        { id = 67, first = "Larry", last = "Bailey" },
        { id = 68, first = "Emma", last = "Rivera" },
        { id = 69, first = "Justin", last = "Cooper" },
        { id = 70, first = "Pamela", last = "Richardson" },
        { id = 71, first = "Scott", last = "Cox" },
        { id = 72, first = "Nicole", last = "Howard" },
        { id = 73, first = "Brandon", last = "Ward" },
        { id = 74, first = "Megan", last = "Torres" },
        { id = 75, first = "Benjamin", last = "Peterson" },
        { id = 76, first = "Julie", last = "Gray" },
        { id = 77, first = "Samuel", last = "Ramirez" },
        { id = 78, first = "Hannah", last = "James" },
        { id = 79, first = "Gregory", last = "Watson" },
        { id = 80, first = "Victoria", last = "Brooks" },
        { id = 81, first = "Frank", last = "Kelly" },
        { id = 82, first = "Olivia", last = "Sanders" },
        { id = 83, first = "Alexander", last = "Price" },
        { id = 84, first = "Christina", last = "Bennett" },
        { id = 85, first = "Raymond", last = "Wood" },
        { id = 86, first = "Diane", last = "Barnes" },
        { id = 87, first = "Patrick", last = "Ross" },
        { id = 88, first = "Evelyn", last = "Henderson" },
        { id = 89, first = "Jack", last = "Coleman" },
        { id = 90, first = "Rachel", last = "Jenkins" },
        { id = 91, first = "Dennis", last = "Perry" },
        { id = 92, first = "Grace", last = "Powell" },
        { id = 93, first = "Jerry", last = "Long" },
        { id = 94, first = "Lauren", last = "Patterson" },
        { id = 95, first = "Tyler", last = "Hughes" },
        { id = 96, first = "Alice", last = "Flores" },
        { id = 97, first = "Aaron", last = "Washington" },
        { id = 98, first = "Jacqueline", last = "Butler" },
        { id = 99, first = "Jose", last = "Simmons" },
        { id = 100, first = "Katherine", last = "Foster" },
    }
    local firstNameId = ZombRand(#names) + 1
    local lastNameId  = ZombRand(#names) + 1
    local targetName = names[firstNameId].first .. " " .. names[lastNameId].last
    return targetName
end

function PZLinuxMailFormatDate()
    local gt = getGameTime()
    if not gt then return "1993-07-09 09:00" end
    return string.format("%04d-%02d-%02d %02d:%02d", gt:getYear(), gt:getMonth() + 1, gt:getDay(), gt:getHour(), gt:getMinutes())
end

function PZLinuxMailFindInboxItem(mails, mailId)
    mailId = tonumber(mailId)
    if not mails or not mails.inbox or not mailId then return nil, nil end
    for index = 1, #mails.inbox do
        if tonumber(mails.inbox[index].id) == mailId then
            return mails.inbox[index], index
        end
    end
    return nil, nil
end

function PZLinuxMailRandomDeliveryItem(mailType)
    local items = PZLinuxMailDeliveryItems[mailType]
    if not items or #items == 0 then return nil end
    return items[ZombRand(#items) + 1]
end

-- Builds a localized floor label from an absolute Z level, matching this
-- mod's existing convention that z=0 is street/ground level (see the Ekron
-- ATM contract target and RELEASE.md's "per absolute Z level" reward
-- wording). Ground floor and floors below street level get their own
-- dedicated wording instead of "Floor 0"/"Floor -1", since a bare number
-- there reads as a typo rather than a location. French and English name
-- floors differently around ground level (rez-de-chaussée vs 1st Floor,
-- depending on convention), so this always keeps z=0 as its own explicit
-- "Ground Floor" label instead of trying to guess an offset per language.
function PZLinuxFormatFloorLabel(z)
    z = tonumber(z) or 0
    if z == 0 then
        return PZLinuxGetText("IGUI_PZLinux_Mail_FloorGround")
    elseif z > 0 then
        return PZLinuxFormatText("IGUI_PZLinux_Mail_FloorAbove", "Floor %s", z)
    else
        return PZLinuxFormatText("IGUI_PZLinux_Mail_FloorBelow", "Basement %s", -z)
    end
end

function PZLinuxMailNormalizeRecord(player, mailId)
    local md, pzlinux = PZLinuxGetModData(player)
    if not pzlinux then return nil, nil, nil end

    mailId = tonumber(mailId)
    local inboxMail = PZLinuxMailFindInboxItem(pzlinux.mails, mailId)
    local mail = pzlinux.mails[mailId]
    if not mail and inboxMail then
        mail = {}
        pzlinux.mails[mailId] = mail
    end
    if not mail then return nil, md, pzlinux end

    if inboxMail then
        mail.id = mail.id or inboxMail.id
        mail.name = mail.name or inboxMail.name
        mail.type = mail.type or inboxMail.type
        mail.date = mail.date or inboxMail.date
        mail.from = mail.from or inboxMail.from
        mail.read = inboxMail.read
    end

    mail.id = mail.id or mailId
    mail.status = mail.status or 1
    mail.sender = mail.sender or mail.from or PZLinuxGenerateRandomName()
    mail.seed = mail.seed or ZombRand(1, mail.type == "ads" and 21 or 4)

    if mail.type == "ammo" or mail.type == "medical" then
        local loc = nil
        if not mail.x or not mail.y or not mail.z or not mail.city then
            loc = PZLinuxGetRandomMissionLocation("mails", mail.type)
        end
        if loc then
            -- loc.name was never a field on mission location entries (they
            -- use loc.city/loc.building), so this used to always resolve to
            -- nil and leave mail.city unset -- the exact "city missing from
            -- the mail description" bug reported by players.
            mail.city = mail.city or loc.city
            mail.building = mail.building or loc.building
            mail.x = mail.x or loc.x
            mail.y = mail.y or loc.y
            mail.z = mail.z or loc.z
        end
        mail.quantity = tonumber(mail.quantity) or ZombRand(1, 6)
        mail.object = mail.object or PZLinuxMailRandomDeliveryItem(mail.type)
    end

    return mail, md, pzlinux
end

function PZLinuxMailCreateRandom(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, pzlinux = PZLinuxGetModData(playerObj)
    if not pzlinux then return { ok = false, error = "no_player", requestId = requestId } end

    pzlinux.mails.inbox = pzlinux.mails.inbox or {}
    pzlinux.mails.nextid = tonumber(pzlinux.mails.nextid) or 1

    local mailDefinition = PZLinuxMailTable[ZombRand(#PZLinuxMailTable) + 1]
    if not mailDefinition then return { ok = false, error = "missing_mail_definition", requestId = requestId } end

    local mailId = pzlinux.mails.nextid
    local mail = {
        id = mailId,
        name = mailDefinition.baseName,
        type = mailDefinition.type,
        date = PZLinuxMailFormatDate(),
        from = PZLinuxGenerateRandomName(),
        read = false,
        status = 1,
    }
    pzlinux.mails[mailId] = mail
    PZLinuxMailNormalizeRecord(playerObj, mailId)
    table.insert(pzlinux.mails.inbox, 1, mail)
    pzlinux.mails.nextid = mailId + 1

    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, mailId = mailId, mailType = mail.type, inboxCount = #pzlinux.mails.inbox }
end

function PZLinuxMailScheduleNext(player)
    local md, pzlinux = PZLinuxGetModData(player)
    if not pzlinux or not getGameTime then return nil end

    local now = getGameTime():getWorldAgeHours()
    pzlinux.player.reputation = tonumber(pzlinux.player.reputation) or 1
    local delayMax = PZLinux.Economy.mailDelayMax(pzlinux.player.reputation)
    local delay = ZombRand(48, delayMax)
    if not pzlinux.mails.nextat or pzlinux.mails.nextat <= now then
        pzlinux.mails.nextat = now + delay
        PZLinuxTransmitPlayerModData(player)
    end
    return pzlinux.mails.nextat, md
end

function PZLinuxMailTickPlayer(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player" } end
    local _, pzlinux = PZLinuxGetModData(playerObj)
    if not pzlinux or not getGameTime then return { ok = false, error = "no_player" } end

    local now = getGameTime():getWorldAgeHours()
    if not pzlinux.mails.nextat then
        PZLinuxMailScheduleNext(playerObj)
        return { ok = true, generated = false, nextat = pzlinux.mails.nextat }
    end

    if now >= pzlinux.mails.nextat then
        local result = PZLinuxMailCreateRandom(playerObj)
        PZLinuxMailScheduleNext(playerObj)
        result.nextat = pzlinux.mails.nextat
        return result
    end
    return { ok = true, generated = false, nextat = pzlinux.mails.nextat }
end

function PZLinuxMailApplyAccept(player, mailId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local mail = PZLinuxMailNormalizeRecord(playerObj, mailId)
    if not mail then return { ok = false, error = "missing_mail", requestId = requestId, mailId = mailId } end
    if mail.type == "ads" then return { ok = false, error = "ads_cannot_be_accepted", requestId = requestId, mailId = mailId } end
    if mail.status == 10 then return { ok = false, error = "mail_already_completed", requestId = requestId, mailId = mailId } end

    mail.status = 2
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, mailId = tonumber(mailId), status = mail.status, object = mail.object, quantity = mail.quantity, x = mail.x, y = mail.y, z = mail.z, city = mail.city }
end

function PZLinuxMailApplyDelete(player, mailId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    local md, pzlinux = PZLinuxGetModData(playerObj)
    if not playerObj or not pzlinux then return { ok = false, error = "no_player", requestId = requestId } end

    local mail = pzlinux.mails[tonumber(mailId)]
    local inboxMail, inboxIndex = PZLinuxMailFindInboxItem(pzlinux.mails, mailId)
    local x = mail and mail.x or inboxMail and inboxMail.x
    local y = mail and mail.y or inboxMail and inboxMail.y
    pzlinux.mails[tonumber(mailId)] = nil
    if inboxIndex then table.remove(pzlinux.mails.inbox, inboxIndex) end

    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, mailId = tonumber(mailId), x = x, y = y, inboxCount = #(pzlinux.mails.inbox or {}), md = md and true or false }
end

function PZLinuxMailInventoryItemMatches(item, fullType)
    if not item or not fullType then return false end
    if item.getFullType and item:getFullType() == fullType then return true end
    if item.getType and item:getType() == fullType then return true end
    return false
end

function PZLinuxMailCountInventoryItems(player, fullType)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local inventory = playerObj:getInventory()
    if not inventory then return 0 end
    local count = 0
    for index = 0, inventory:getItems():size() - 1 do
        if PZLinuxMailInventoryItemMatches(inventory:getItems():get(index), fullType) then
            count = count + 1
        end
    end
    return count
end

function PZLinuxMailRemoveInventoryItems(player, fullType, quantity)
    local playerObj = PZLinuxGetPlayer(player)
    quantity = math.max(0, tonumber(quantity) or 0)
    if not playerObj or quantity <= 0 then return 0 end
    local inventory = playerObj:getInventory()
    if not inventory then return 0 end

    local removed = 0
    for index = inventory:getItems():size() - 1, 0, -1 do
        local item = inventory:getItems():get(index)
        if PZLinuxMailInventoryItemMatches(item, fullType) then
            if PZLinuxRemoveInventoryItem(playerObj, item) then
                removed = removed + 1
            end
            if removed >= quantity then break end
        end
    end
    return removed
end

function PZLinuxMailGiveReward(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local inventory = playerObj:getInventory()
    local parcel = inventory and inventory:AddItem("Base.Present_ExtraLarge")
    if not parcel then return 0 end

    parcel:setName("A gift to thank you")
    local parcelInv = parcel:getInventory()
    local bonusRand = ZombRand(1, 6)
    local added = 0
    local function PZLinuxMailAddRewardItem(fullType)
        local item = parcelInv:AddItem(fullType)
        if not item then return false end
        added = added + 1
        return true
    end

    for _ = 1, bonusRand do
        local entry = PZLinuxDarkWebItemsTable[ZombRand(#PZLinuxDarkWebItemsTable) + 1]
        if entry and entry.id and #entry.id > 0 then
            local one = entry.id[ZombRand(#entry.id) + 1]
            if not PZLinuxMailAddRewardItem(one) then
                inventory:Remove(parcel)
                return 0, nil
            end
        end
    end

    if bonusRand == 1 then
        if not PZLinuxMailAddRewardItem("Base.Revolver") then
            inventory:Remove(parcel)
            return 0, nil
        end
        for _ = 1, ZombRand(100, 301) do
            if not PZLinuxMailAddRewardItem("Base.Money") then
                inventory:Remove(parcel)
                return 0, nil
            end
        end
    elseif bonusRand == 2 then
        if not PZLinuxMailAddRewardItem("Base.Revolver") then
            inventory:Remove(parcel)
            return 0, nil
        end
    end

    if not PZLinuxSyncAddedInventoryItem(playerObj, parcel) then
        inventory:Remove(parcel)
        return 0, nil
    end
    return added, parcel
end

-- Delivers any mail-mission gifts still owed to the player, one separate
-- parcel per completed mission, the same way Dark Web/Request orders are
-- picked up: only created once the player actually checks a mailbox,
-- never handed over the instant the mission is completed.
function PZLinuxMailApplyRewardDelivery(player, mailboxRef, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local _, mailboxError = PZLinuxValidateMailboxInteraction(playerObj, mailboxRef)
    if mailboxError then
        return { ok = false, error = mailboxError, requestId = requestId }
    end

    local modData = playerObj:getModData()
    local pending = math.max(0, tonumber(modData.PZLinuxOnMailReward) or 0)
    if pending <= 0 then
        return { ok = true, requestId = requestId, delivered = 0 }
    end

    local delivered = 0
    while pending > 0 do
        local _, parcel = PZLinuxMailGiveReward(playerObj)
        if not parcel then break end
        delivered = delivered + 1
        pending = pending - 1
    end

    modData.PZLinuxOnMailReward = pending
    PZLinuxTransmitPlayerModData(playerObj)
    if delivered > 0 then
        print(string.format(
            "[PZLinux Mail] REWARD DELIVERED player=%s delivered=%d remaining=%d",
            tostring(PZLinuxGetPlayerKey(playerObj)), delivered, pending))
    end
    return { ok = true, requestId = requestId, delivered = delivered, remaining = pending }
end

function PZLinuxMailApplyComplete(player, mailId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local mail, md, pzlinux = PZLinuxMailNormalizeRecord(playerObj, mailId)
    if not mail then return { ok = false, error = "missing_mail", requestId = requestId, mailId = mailId } end
    if mail.status ~= 2 then return { ok = false, error = "mail_not_accepted", requestId = requestId, mailId = mailId, status = mail.status } end

    local playerSquare = playerObj:getSquare()
    if playerSquare and mail.x and mail.y then
        -- Must match isNearTarget's metric and threshold (client, PZLinuxUtils.lua):
        -- Chebyshev distance, <= 5. The context-menu deposit option is only ever
        -- shown to the player when a mailbox satisfies that same check, so
        -- enforcing a tighter/different metric here (Manhattan <= 3) rejected
        -- deliveries the player had no way to know would fail -- the option
        -- was visible and the right item was in hand, yet completion silently
        -- failed with a generic "Mail delivery rejected" every time the two
        -- squares weren't roughly axis-aligned.
        local distance = math.max(
            math.abs(playerSquare:getX() - tonumber(mail.x)),
            math.abs(playerSquare:getY() - tonumber(mail.y))
        )
        if distance > 5 then
            return { ok = false, error = "too_far", requestId = requestId, mailId = mailId, distance = distance }
        end
    end

    local quantity = math.max(1, tonumber(mail.quantity) or 1)
    local available = PZLinuxMailCountInventoryItems(playerObj, mail.object)
    if available < quantity then
        return { ok = false, error = "missing_items", requestId = requestId, mailId = mailId, object = mail.object, quantity = quantity, available = available }
    end

    local removed = PZLinuxMailRemoveInventoryItems(playerObj, mail.object, quantity)
    if removed < quantity then
        return { ok = false, error = "remove_failed", requestId = requestId, mailId = mailId, object = mail.object, quantity = quantity, removed = removed }
    end

    -- The gift is no longer handed over immediately here -- it's deferred to
    -- the next mailbox visit (PZLinuxMailApplyRewardDelivery), the same way
    -- Dark Web and Request orders already work in this mod. A counter (not
    -- a flag) supports several completed missions stacking up their own
    -- separate gift before the player next checks a mailbox.
    md.PZLinuxOnMailReward = (tonumber(md.PZLinuxOnMailReward) or 0) + 1

    local reputation = PZLinuxApplyReputationDelta(playerObj, PZLinux.Economy.contractCompleteReward())
    mail.status = 10
    PZLinuxTransmitPlayerModData(playerObj)
    print(string.format(
        "[PZLinux Mail] COMPLETE player=%s mailId=%s object=%s quantity=%d reputation=%s pendingRewards=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(mailId), tostring(mail.object), quantity,
        tostring(reputation), tonumber(md.PZLinuxOnMailReward) or 0))
    return { ok = true, requestId = requestId, mailId = tonumber(mailId), status = 10, removed = removed, object = mail.object, quantity = quantity, rewardPending = true, reputation = reputation, x = mail.x, y = mail.y, inboxCount = pzlinux and pzlinux.mails and #(pzlinux.mails.inbox or {}) or 0 }
end

function PZLinuxRequestMailAccept(player, mailId, callback)
    local requestId = PZLinuxNextRequestId("mail-accept")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxMailAccept", { requestId = requestId, mailId = mailId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailApplyAccept(player, mailId, requestId))
    return requestId
end

function PZLinuxRequestMailDelete(player, mailId, callback)
    local requestId = PZLinuxNextRequestId("mail-delete")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxMailDelete", { requestId = requestId, mailId = mailId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailApplyDelete(player, mailId, requestId))
    return requestId
end

function PZLinuxRequestMailComplete(player, mailId, callback)
    local requestId = PZLinuxNextRequestId("mail-complete")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxMailComplete", { requestId = requestId, mailId = mailId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailApplyComplete(player, mailId, requestId))
    return requestId
end

function PZLinuxRequestMailRewardDelivery(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("mail-reward-delivery")
    PZLinuxRegisterCallback(requestId, callback)
    local args = { requestId = requestId, mailbox = mailboxRef }
    if PZLinuxSendClientCommand("PZLinuxMailRewardDelivery", args) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailApplyRewardDelivery(player, mailboxRef, requestId))
    return requestId
end

function PZLinuxRequestMailGenerate(player, callback)
    local requestId = PZLinuxNextRequestId("mail-generate")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxMailGenerate", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxMailCreateRandom(player, requestId))
    return requestId
end

PZLinuxHackingCardTypes = PZLinuxHackingCardTypes or {
    ["Base.CreditCard"] = true,
    ["Base.CreditCard_Stolen"] = true,
}

function PZLinuxHackingIsCard(item)
    return item and item.getFullType and PZLinuxHackingCardTypes[item:getFullType()] == true
end

-- A player reported carrying credit cards that Hacking still reported as
-- "No Credit Card...". They were inside an equipped bag rather than the
-- top-level inventory -- an earlier version of this fix recursed into
-- nested containers to find them there too, but that was deliberately
-- reverted: this mod consistently only ever looks at the player's direct,
-- top-level inventory for every other "do I have item X" check (Dark
-- Web's sell/buy matching, Contract deposit checks, etc.), and the
-- request was to keep Hacking consistent with that -- cards need to be in
-- the main inventory, not buried in a bag, same as everywhere else in
-- this mod.
function PZLinuxHackingCountCards(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end
    local inventory = playerObj:getInventory()
    if not inventory then return 0 end
    local count = 0
    for index = 0, inventory:getItems():size() - 1 do
        if PZLinuxHackingIsCard(inventory:getItems():get(index)) then
            count = count + 1
        end
    end
    return count
end

function PZLinuxHackingRemoveCards(player, maxCount)
    local playerObj = PZLinuxGetPlayer(player)
    maxCount = tonumber(maxCount) or 1
    if not playerObj or maxCount <= 0 then return 0, nil end
    local inventory = playerObj:getInventory()
    if not inventory then return 0, nil end

    local removed = 0
    local firstName = nil
    local cardTypes = {}
    for index = inventory:getItems():size() - 1, 0, -1 do
        local item = inventory:getItems():get(index)
        if PZLinuxHackingIsCard(item) then
            -- Only record the name/type -- and count it -- once removal
            -- actually succeeds, so a failed removal can never leave
            -- cardTypes claiming a card was taken that's still physically
            -- there (this used to insert unconditionally, before the
            -- success check -- kept from the reverted fix, still a real
            -- correctness improvement on its own).
            local itemName = item:getName()
            local itemFullType = item:getFullType()
            if PZLinuxRemoveInventoryItem(playerObj, item) then
                firstName = firstName or itemName
                table.insert(cardTypes, itemFullType)
                removed = removed + 1
                if removed >= maxCount then break end
            end
        end
    end
    return removed, firstName, cardTypes
end

function PZLinuxHackingGeneratePassword()
    local passwordNumbers = {}
    while #passwordNumbers < 4 do
        local num = ZombRand(0, 10)
        local exists = false
        for _, value in ipairs(passwordNumbers) do
            if value == num then
                exists = true
                break
            end
        end
        if not exists then table.insert(passwordNumbers, num) end
    end
    return passwordNumbers
end

function PZLinuxHackingGetSession(player)
    return PZLinux.hackingSessions[PZLinuxGetPlayerKey(player)]
end

function PZLinuxHackingSetSession(player, session)
    PZLinux.hackingSessions[PZLinuxGetPlayerKey(player)] = session
end

function PZLinuxHackingClearSession(player)
    PZLinux.hackingSessions[PZLinuxGetPlayerKey(player)] = nil
end

function PZLinuxHackingBuildGuessFeedback(session, guess)
    local passwordStr = tostring(guess or "")
    if #passwordStr ~= 4 then return { ok = false, error = "invalid_guess" } end

    local realDigits = { session.password[1], session.password[2], session.password[3], session.password[4] }
    local guessDigits = {
        tonumber(passwordStr:sub(1, 1)),
        tonumber(passwordStr:sub(2, 2)),
        tonumber(passwordStr:sub(3, 3)),
        tonumber(passwordStr:sub(4, 4)),
    }
    local revealedPassword = ""
    for index = 1, 4 do
        revealedPassword = revealedPassword .. (guessDigits[index] == session.password[index] and tostring(guessDigits[index]) or "*")
    end

    local correctCount = 0
    local misplacedCount = 0
    for index = 1, 4 do
        if guessDigits[index] and guessDigits[index] == realDigits[index] then
            correctCount = correctCount + 1
            realDigits[index] = nil
            guessDigits[index] = nil
        end
    end

    for index = 1, 4 do
        local guessDigit = guessDigits[index]
        if guessDigit then
            for realIndex = 1, 4 do
                if realDigits[realIndex] and realDigits[realIndex] == guessDigit then
                    misplacedCount = misplacedCount + 1
                    realDigits[realIndex] = nil
                    break
                end
            end
        end
    end

    return {
        ok = true,
        unlocked = revealedPassword == passwordStr,
        revealedPassword = revealedPassword,
        correctCount = correctCount,
        misplacedCount = misplacedCount,
    }
end

-- Belt and suspenders (v1.0.9), alongside the client-side fix for a real
-- duplicate-money exploit + crash (see the comment above hackTransfert in
-- PZLinuxHacking.lua for the full client-side mechanism): starting a new
-- hack used to unconditionally overwrite any existing session, with no
-- check for one already sitting there unlocked and not yet transferred.
-- Refusing that here closes the possibility from the server's side too,
-- regardless of whatever state the client's UI is in.
local function PZLinuxHackingRejectIfPendingTransfer(playerObj, requestId)
    local session = PZLinuxHackingGetSession(playerObj)
    if session and session.unlocked and not session.transferred then
        return { ok = false, error = "session_pending_transfer", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    return nil
end

function PZLinuxHackingStartManual(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local pendingRejection = PZLinuxHackingRejectIfPendingTransfer(playerObj, requestId)
    if pendingRejection then return pendingRejection end

    local removed, cardName, cardTypes = PZLinuxHackingRemoveCards(playerObj, 1)
    if removed <= 0 then
        return { ok = false, error = "no_card", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end
    PZLinuxRegisterInterruptedSession(playerObj, "hacking", {
        mode = "manual",
        requestId = requestId,
        cardTypes = cardTypes,
    })

    local skillLevel = playerObj:getPerkLevel(Perks.Electricity) or 0
    local amount = PZLinuxNormalizeMoney(ZombRand(5, 1000) * (skillLevel + 1))
    local password = PZLinuxHackingGeneratePassword()
    local session = {
        mode = "manual",
        amount = amount,
        remaining = amount,
        password = password,
        tries = 0,
        maxTries = 6,
        unlocked = false,
        transferred = false,
        cardName = cardName,
    }
    PZLinuxHackingSetSession(playerObj, session)
    if addXp then addXp(playerObj, Perks.Electricity, 1) end

    -- Never logs the password itself, or anything derived from it -- only
    -- the amount at stake and how many tries are available. Same rule for
    -- every hacking log below: the code stays exclusively in-session,
    -- server-side, never printed.
    print(string.format(
        "[PZLinux Hacking] START MANUAL player=%s amount=%d maxTries=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), amount, session.maxTries))

    return {
        ok = true,
        requestId = requestId,
        amount = amount,
        cardName = cardName,
        passwordLength = #password,
        maxTries = session.maxTries,
        balance = PZLinuxLoadBankBalance(playerObj),
    }
end

function PZLinuxHackingAuto(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local pendingRejection = PZLinuxHackingRejectIfPendingTransfer(playerObj, requestId)
    if pendingRejection then return pendingRejection end

    local available = PZLinuxHackingCountCards(playerObj)
    if available <= 0 then
        return { ok = false, error = "no_card", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local removed, _, cardTypes = PZLinuxHackingRemoveCards(playerObj, available)
    PZLinuxRegisterInterruptedSession(playerObj, "hacking", {
        mode = "auto",
        requestId = requestId,
        cardTypes = cardTypes,
    })
    local skillLevel = playerObj:getPerkLevel(Perks.Electricity) or 0
    local valuePerCard = PZLinuxNormalizeMoney(ZombRand(300, 501) * (skillLevel + 1))
    local amount = PZLinuxNormalizeMoney(valuePerCard * removed)
    local session = {
        mode = "auto",
        amount = amount,
        remaining = amount,
        unlocked = true,
        transferred = false,
        cardCount = removed,
    }
    PZLinuxHackingSetSession(playerObj, session)
    if addXp then addXp(playerObj, Perks.Electricity, math.max(1, removed)) end

    print(string.format(
        "[PZLinux Hacking] START AUTO player=%s cardCount=%d amount=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), removed, amount))

    return { ok = true, requestId = requestId, amount = amount, cardCount = removed, balance = PZLinuxLoadBankBalance(playerObj) }
end

function PZLinuxHackingGuess(player, guess, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local session = PZLinuxHackingGetSession(playerObj)
    if not session or session.mode ~= "manual" or session.transferred then
        return { ok = false, error = "missing_session", requestId = requestId }
    end
    if session.locked then
        return { ok = false, error = "account_locked", requestId = requestId, tries = session.tries, maxTries = session.maxTries }
    end

    local feedback = PZLinuxHackingBuildGuessFeedback(session, guess)
    if not feedback.ok then
        feedback.requestId = requestId
        return feedback
    end

    if feedback.unlocked then
        session.unlocked = true
        if addXp then addXp(playerObj, Perks.Electricity, 3) end
    else
        session.tries = (tonumber(session.tries) or 0) + 1
        if session.tries >= session.maxTries then
            session.locked = true
            -- The cards are already gone for good at this point (removed
            -- from inventory the moment the hack started) -- a locked-out
            -- session has nothing left worth restoring. Clearing the
            -- in-memory session too (not just the persisted interrupted-
            -- session flag) matters: leaving it behind used to mean
            -- PZLinux.hackingSessions[key] stayed occupied by a dead,
            -- locked session with sessions.hacking already nil -- the exact
            -- inverted mismatch of the bug fixed above (session present,
            -- interrupted-session flag absent, instead of the other way
            -- around), just one this asymmetry can't turn into a card
            -- duplication since there was nothing left to restore either
            -- way. Still worth closing so PZLinuxHackingClearSession/
            -- PZLinuxClearInterruptedSession are called together on every
            -- path that ends a session, with no exceptions to keep track of.
            PZLinuxHackingClearSession(playerObj)
            PZLinuxClearInterruptedSession(playerObj, "hacking")
        end
    end

    feedback.requestId = requestId
    feedback.amount = session.amount
    feedback.tries = session.tries
    feedback.maxTries = session.maxTries
    feedback.locked = session.locked == true
    feedback.balance = PZLinuxLoadBankBalance(playerObj)

    -- Deliberately never logs the guess itself, the real password, or the
    -- correct/misplaced breakdown -- only whether this attempt succeeded
    -- and how many tries have been used, which reveals nothing about the
    -- code.
    print(string.format(
        "[PZLinux Hacking] GUESS player=%s result=%s tries=%d/%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), feedback.unlocked and "correct" or (feedback.locked and "locked_out" or "wrong"),
        session.tries, session.maxTries))

    return feedback
end

function PZLinuxHackingTransfer(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local session = PZLinuxHackingGetSession(playerObj)
    if not session then return { ok = false, error = "missing_session", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) } end
    if session.locked or not session.unlocked then return { ok = false, error = "account_locked", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) } end
    if session.transferred then return { ok = false, error = "already_transferred", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) } end

    local amount = PZLinuxNormalizeMoney(session.remaining or session.amount)
    if amount <= 0 then
        PZLinuxHackingClearSession(playerObj)
        PZLinuxClearInterruptedSession(playerObj, "hacking")
        return { ok = false, error = "empty_account", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local credit = PZLinuxApplyBankCredit(playerObj, amount, "hacking-transfer", requestId)
    if not credit.ok then return credit end
    session.transferred = true
    session.remaining = 0
    PZLinuxHackingClearSession(playerObj)
    PZLinuxClearInterruptedSession(playerObj, "hacking")

    print(string.format(
        "[PZLinux Hacking] TRANSFER player=%s mode=%s amount=%d balance=%d",
        tostring(PZLinuxGetPlayerKey(playerObj)), tostring(session.mode), amount, credit.balance))

    credit.mode = session.mode
    credit.hackedAmount = amount
    return credit
end

function PZLinuxRequestHackingStart(player, callback)
    local requestId = PZLinuxNextRequestId("hacking-start")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxHackingStart", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxHackingStartManual(player, requestId))
    return requestId
end

function PZLinuxRequestHackingAuto(player, callback)
    local requestId = PZLinuxNextRequestId("hacking-auto")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxHackingAuto", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxHackingAuto(player, requestId))
    return requestId
end

function PZLinuxRequestHackingGuess(player, guess, callback)
    local requestId = PZLinuxNextRequestId("hacking-guess")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxHackingGuess", { requestId = requestId, guess = guess }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxHackingGuess(player, guess, requestId))
    return requestId
end

function PZLinuxRequestHackingTransfer(player, callback)
    local requestId = PZLinuxNextRequestId("hacking-transfer")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxHackingTransfer", { requestId = requestId }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxHackingTransfer(player, requestId))
    return requestId
end
