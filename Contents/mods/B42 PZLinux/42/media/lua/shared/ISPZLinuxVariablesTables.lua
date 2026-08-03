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

function PZLinux.getModData(player)
    local playerObj = PZLinux.getPlayer(player)
    if not playerObj then return nil, nil, nil end

    local md = playerObj:getModData()
    md.pzlinux = md.pzlinux or {}
    md.pzlinux.player = md.pzlinux.player or {}
    md.pzlinux.mails = md.pzlinux.mails or {}
    md.pzlinux.mails.inbox = md.pzlinux.mails.inbox or {}
    md.pzlinux.mails.nextid = md.pzlinux.mails.nextid or 1
    md.pzlinux.player.reputation = tonumber(md.pzlinux.player.reputation) or 1

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

function PZLinuxFormatText(key, fallback, ...)
    local argumentCount = select("#", ...)
    local values = { ... }
    local markers = {}
    local template = fallback or key

    if getText then
        local translated
        if argumentCount > 0 then
            for index = 1, argumentCount do
                markers[index] = "__PZLINUX_VALUE_" .. tostring(index) .. "__"
            end
            local translatedOk
            translatedOk, translated = pcall(getText, key, unpack(markers, 1, argumentCount))
            if not translatedOk then translated = getText(key) end
        else
            translated = getText(key)
        end
        if translated and translated ~= key then template = translated end
    end

    for index = 1, argumentCount do
        local replacement = tostring(values[index] or "")
        local substitutions = 0
        if markers[index] then
            template, substitutions = template:gsub(markers[index], function() return replacement end, 1)
        end
        if substitutions == 0 then
            template, substitutions = template:gsub("%%s", function() return replacement end, 1)
        end
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

function PZLinuxLoadBankBalance(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end

    local modData = playerObj:getModData()
    local balance = tonumber(modData.PZLinuxBank)
    if balance == nil then
        balance = ZombRand(500, 4000)
        modData.PZLinuxBank = balance
        PZLinuxTransmitPlayerModData(playerObj)
    end

    balance = math.max(0, math.floor(balance))
    modData.PZLinuxBank = balance
    return balance
end

function PZLinuxSetBankBalance(player, balance)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 0 end

    balance = PZLinuxNormalizeMoney(balance)
    playerObj:getModData().PZLinuxBank = balance
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
    if blackjack and not PZLinux.blackjackSessions[playerKey] then
        local amount = PZLinuxNormalizeMoney(blackjack.amount)
        if amount > 0 then
            local credit = PZLinuxApplyBankCredit(playerObj, amount, "rollback-blackjack", blackjack.requestId)
            applied.blackjack = credit.amount or amount
        end
        sessions.blackjack = nil
    end

    local race = sessions.race
    if race and not PZLinux.raceSessions[playerKey] then
        local amount = PZLinuxNormalizeMoney(race.amount)
        if amount > 0 then
            local credit = PZLinuxApplyBankCredit(playerObj, amount, "rollback-zombie-race", race.requestId)
            applied.race = credit.amount or amount
        end
        sessions.race = nil
    end

    local hacking = sessions.hacking
    if hacking and not PZLinux.hackingSessions[playerKey] then
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
    if poker and (not PZLinux.Poker or not PZLinux.Poker.Sessions or not PZLinux.Poker.Sessions[playerKey]) then
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

function PZLinuxAtmLoadCash(atmObject)
    if not atmObject then return 0 end

    local modData = atmObject:getModData()
    local atmCash = tonumber(modData.PZLinuxAtmCash)
    if atmCash == nil then
        if isClient and isClient() then
            return 0
        end
        atmCash = ZombRand(PZLINUX_ATM_MIN_CASH, PZLINUX_ATM_MAX_CASH + 1)
        modData.PZLinuxAtmCash = atmCash
        PZLinuxAtmTransmitModData(atmObject)
    end

    atmCash = math.max(0, math.floor(atmCash))
    modData.PZLinuxAtmCash = atmCash
    return atmCash
end

function PZLinuxAtmSaveCash(atmObject, atmCash)
    if not atmObject then return 0 end

    local modData = atmObject:getModData()
    modData.PZLinuxAtmCash = math.max(0, math.floor(tonumber(atmCash) or 0))
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
            if string.find(spriteName, "location_business_bank_01_67")
            or string.find(spriteName, "location_business_bank_01_66")
            or string.find(spriteName, "location_business_bank_01_65")
            or string.find(spriteName, "location_business_bank_01_64") then
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
        return { ok = false, error = "not_enough_inventory_cash", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = inventoryCash }
    end

    local removed = PZLinuxRemoveInventoryCash(player, amount)
    if removed ~= amount then
        return { ok = false, error = "cash_remove_failed", requestId = requestId, amount = amount, balance = previousBalance, atmCash = atmCash, inventoryCash = PZLinuxCountInventoryCash(player) }
    end

    local balance = PZLinuxSetBankBalance(player, previousBalance + amount)
    atmCash = PZLinuxAtmSaveCash(atmObject, atmCash + amount)

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

    PZLinuxClearInterruptedSession(player, "blackjack")
    local state = PZLinuxBlackjackBuildState(player, session)
    PZLinux.blackjackSessions[PZLinuxGetPlayerKey(player)] = nil
    return state
end

function PZLinuxBlackjackStart(player, amount, requestId)
    amount = PZLinuxNormalizeMoney(amount)
    local debit = PZLinuxApplyBankDebit(player, amount, "blackjack", requestId)
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

function PZLinuxRequestBlackjackStart(player, amount, callback)
    local requestId = PZLinuxNextRequestId("blackjack-start")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxBlackjackStart", { requestId = requestId, amount = amount }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxBlackjackStart(player, amount, requestId))
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

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= "PZLinux" then return end
        if command == "PZLinuxContractZombieRemoved" then
            PZLinuxRemoveReplicatedZombie(args and args.target)
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
        or command == "PZLinuxTradingSnapshotResult"
        or command == "PZLinuxTradingBuyResult"
        or command == "PZLinuxTradingSellResult"
        or command == "PZLinuxContractsBoardResult"
        or command == "PZLinuxContractPreviewResult"
        or command == "PZLinuxContractSyncResult"
        or command == "PZLinuxContractAcceptResult"
        or command == "PZLinuxContractCancelResult"
        or command == "PZLinuxContractDepositResult"
        or command == "PZLinuxContractCompleteResult"
        or command == "PZLinuxContractCompletionAckResult"
        or command == "PZLinuxContractWorldEventResult"
        or command == "PZLinuxContractAdminForceResult"
        or command == "PZLinuxRequestOrderResult"
        or command == "PZLinuxRequestDeliverResult"
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
                    if args.contractId ~= nil then modData.PZLinuxContractTypeId = args.contractId end
                    if args.locationX ~= nil then modData.PZLinuxContractLocationX = args.locationX end
                    if args.locationY ~= nil then modData.PZLinuxContractLocationY = args.locationY end
                    if args.locationZ ~= nil then modData.PZLinuxContractLocationZ = args.locationZ end
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

function PZLinuxRequestsApplyOrder(player, state, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local order = PZLinuxRequestsBuildOrder(playerObj, state, requestId)
    if not order.ok then return order end

    local modData = playerObj:getModData()
    local hasPendingVehicle = tonumber(modData.PZLinuxOnItemRequestCar) == 1
    local hasPendingItems = type(modData.PZLinuxOnItemRequest) == "table" and #modData.PZLinuxOnItemRequest > 0
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
        modData.PZLinuxOnItemRequest = {}
        order.deliveryId = modData.PZLinuxRequestVehicleDeliveryId
    else
        modData.PZLinuxOnItemRequestCar = 0
        modData.PZLinuxOnItemRequest = modData.PZLinuxOnItemRequest or {}
        table.insert(modData.PZLinuxOnItemRequest, { { items = order.items } })
        if addXp then addXp(playerObj, Perks.PlantScavenging, 3) end
    end
    PZLinuxTransmitPlayerModData(playerObj)

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
    if modData.PZLinuxActiveRequest ~= 1 or type(modData.PZLinuxOnItemRequest) ~= "table" or #modData.PZLinuxOnItemRequest == 0 then
        return { ok = true, requestId = requestId, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    if ZombRand(1, 101) <= 10 then
        modData.PZLinuxActiveRequest = 0
        modData.PZLinuxOnItemRequest = {}
        PZLinuxTransmitPlayerModData(playerObj)
        return { ok = true, requestId = requestId, lost = true, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local delivered = 0
    local inventory = playerObj:getInventory()
    if not inventory then
        return { ok = false, error = "missing_inventory", requestId = requestId, delivered = 0, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    while #modData.PZLinuxOnItemRequest > 0 do
        local wrapper = modData.PZLinuxOnItemRequest[#modData.PZLinuxOnItemRequest]
        local batch = wrapper and wrapper[1]
        if not batch or type(batch.items) ~= "table" or #batch.items == 0 then
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

        table.remove(modData.PZLinuxOnItemRequest, #modData.PZLinuxOnItemRequest)
        delivered = delivered + batchDelivered
        PZLinuxTransmitPlayerModData(playerObj)
    end
    modData.PZLinuxActiveRequest = 0
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, delivered = delivered, balance = PZLinuxLoadBankBalance(playerObj) }
end

local function PZLinuxRequestsFindDeliveredVehicle(deliveryId)
    if not deliveryId or deliveryId == "" or not getCell then return nil end
    local vehicles = getCell():getVehicles()
    if not vehicles then return nil end

    for index = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(index)
        local data = vehicle and vehicle.getModData and vehicle:getModData() or nil
        if data and tostring(data.PZLinuxRequestVehicleDeliveryId or "") == tostring(deliveryId) then
            return vehicle
        end
    end
    return nil
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

function PZLinuxRequestDeliver(player, mailboxRef, callback)
    local requestId = PZLinuxNextRequestId("request-deliver")
    PZLinuxRegisterCallback(requestId, callback)
    if PZLinuxSendClientCommand("PZLinuxRequestDeliver", { requestId = requestId, mailbox = mailboxRef }) then
        return requestId
    end
    PZLinuxDispatchCallback(PZLinuxRequestsApplyDelivery(player, mailboxRef, requestId))
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
    }
end

function PZLinuxContractsApplyCancel(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

    local modData = playerObj:getModData()
    if (tonumber(modData.PZLinuxActiveContract) or 0) ~= 1 then
        return { ok = false, error = "no_active_contract", requestId = requestId, balance = PZLinuxLoadBankBalance(playerObj) }
    end

    local dataName = modData.PZLinuxContractCompanyUp
    local reputationPenalty = PZLinux.Economy.contractCancelPenalty()
    local reputation = PZLinuxApplyReputationDelta(playerObj, -reputationPenalty)
    PZLinuxContractsUpdateCompanyPrice(dataName, "down")
    PZLinuxContractsMarkWorldContract(modData.PZLinuxContractId, "cancelled", playerObj)
    PZLinuxContractsRemoveContractNote(playerObj)
    PZLinuxContractsClearState(modData)
    PZLinuxTransmitPlayerModData(playerObj)

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
        and type(modData.PZLinuxOnItemBuyOnDarkWeb) == "table"
        and #modData.PZLinuxOnItemBuyOnDarkWeb > 0
    local hasRequestPickup = modData.PZLinuxActiveRequest == 1
        and type(modData.PZLinuxOnItemRequest) == "table"
        and #modData.PZLinuxOnItemRequest > 0

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

local function PZLinuxContractsSnapshotZombies()
    local snapshot = {}
    if not getCell then return snapshot end
    local zombies = getCell():getZombieList()
    if not zombies then return snapshot end
    for index = 0, zombies:size() - 1 do
        snapshot[zombies:get(index)] = true
    end
    return snapshot
end

local function PZLinuxContractsFindNewZombie(snapshot, x, y, z)
    if not getCell then return nil end
    local zombies = getCell():getZombieList()
    if not zombies then return nil end
    for index = zombies:size() - 1, 0, -1 do
        local zombie = zombies:get(index)
        if zombie and not snapshot[zombie]
        and (not zombie.isDead or not zombie:isDead())
        and math.abs(zombie:getX() - x) <= 2
        and math.abs(zombie:getY() - y) <= 2
        and math.abs(zombie:getZ() - z) <= 0.1 then
            return zombie
        end
    end
    return nil
end

local function PZLinuxContractsGetZombieOnlineId(zombie)
    if not zombie then return -1 end
    if zombie.getOnlineID then return tonumber(zombie:getOnlineID()) or -1 end
    return tonumber(zombie.OnlineID) or -1
end

local function PZLinuxContractsConfigureManhuntZombie(zombie, transmit, prepareReplication)
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
    if transmit ~= false then
        local networkAI = zombie.getNetworkCharacterAI and zombie:getNetworkCharacterAI() or nil
        if networkAI and networkAI.extraUpdate then networkAI:extraUpdate() end
    end
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
    if objectiveType == "manhunt" and addZombieSitting then
        local snapshot = PZLinuxContractsSnapshotZombies()
        local ok, spawnError = pcall(addZombieSitting, square:getX(), square:getY(), square:getZ())
        if ok then
            zombie = PZLinuxContractsFindNewZombie(
                snapshot,
                square:getX(),
                square:getY(),
                square:getZ()
            )
            if zombie then spawnMethod = "addZombieSitting" end
        else
            print("[PZLinux Manhunt][server] addZombieSitting failed: " .. tostring(spawnError))
        end
    end
    if not zombie and addZombiesInOutfit then
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
            PZLinuxContractsConfigureManhuntZombie(zombie, false, false)
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
    local record = modData and PZLinuxContractsGetWorldContract(modData.PZLinuxContractId) or nil
    if not record or tonumber(record.contractId) ~= tonumber(expectedContractId) then return nil end
    if record.status == "completed" or record.status == "cancelled" then return nil end
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

function PZLinuxContractsApplyServerZombieDeath(zombie)
    if not zombie then return false end
    local contractWorldId = PZLinuxContractsGetEntityContractId(zombie)
    local objectiveType = PZLinuxContractsGetEntityObjective(zombie)
    local taggedRecord = PZLinuxContractsGetWorldContract(contractWorldId)
    local changed = false

    if taggedRecord and objectiveType == "manhunt" and PZLinuxContractsIsRecordStatus(taggedRecord, "spawned") then
        PZLinux.ManhuntTargets[tostring(taggedRecord.id)] = nil
        taggedRecord.status = "target_down"
        taggedRecord.targetKilled = true
        taggedRecord.targetDeathX = zombie:getX()
        taggedRecord.targetDeathY = zombie:getY()
        taggedRecord.targetDeathZ = zombie:getZ()
        taggedRecord.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or taggedRecord.updatedHour
        PZLinuxContractsSyncRecordToParticipants(taggedRecord)
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
        if not PZLinuxIsPlayerNearPosition(playerObj, record.locationX, record.locationY, record.locationZ, 50) then
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
            mail.city = mail.city or loc.name
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

function PZLinuxMailApplyComplete(player, mailId, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end
    local mail, _, pzlinux = PZLinuxMailNormalizeRecord(playerObj, mailId)
    if not mail then return { ok = false, error = "missing_mail", requestId = requestId, mailId = mailId } end
    if mail.status ~= 2 then return { ok = false, error = "mail_not_accepted", requestId = requestId, mailId = mailId, status = mail.status } end

    local playerSquare = playerObj:getSquare()
    if playerSquare and mail.x and mail.y then
        local distance = math.abs(playerSquare:getX() - tonumber(mail.x)) + math.abs(playerSquare:getY() - tonumber(mail.y))
        if distance > 3 then
            return { ok = false, error = "too_far", requestId = requestId, mailId = mailId, distance = distance }
        end
    end

    local quantity = math.max(1, tonumber(mail.quantity) or 1)
    local available = PZLinuxMailCountInventoryItems(playerObj, mail.object)
    if available < quantity then
        return { ok = false, error = "missing_items", requestId = requestId, mailId = mailId, object = mail.object, quantity = quantity, available = available }
    end

    local rewardItems, rewardParcel = PZLinuxMailGiveReward(playerObj)
    if not rewardParcel then
        return { ok = false, error = "reward_creation_failed", requestId = requestId, mailId = mailId, object = mail.object, quantity = quantity }
    end

    local removed = PZLinuxMailRemoveInventoryItems(playerObj, mail.object, quantity)
    if removed < quantity then
        PZLinuxRemoveInventoryItem(playerObj, rewardParcel)
        return { ok = false, error = "remove_failed", requestId = requestId, mailId = mailId, object = mail.object, quantity = quantity, removed = removed }
    end

    local reputation = PZLinuxApplyReputationDelta(playerObj, PZLinux.Economy.contractCompleteReward())
    mail.status = 10
    PZLinuxTransmitPlayerModData(playerObj)
    return { ok = true, requestId = requestId, mailId = tonumber(mailId), status = 10, removed = removed, object = mail.object, quantity = quantity, rewardItems = rewardItems, reputation = reputation, x = mail.x, y = mail.y, inboxCount = pzlinux and pzlinux.mails and #(pzlinux.mails.inbox or {}) or 0 }
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
    ["Base.IDcard"] = true,
    ["Base.IDcard_Stolen"] = true,
    ["Base.IDcard_Female"] = true,
    ["Base.IDcard_Male"] = true,
    ["Base.CreditCard"] = true,
    ["Base.CreditCard_Stolen"] = true,
}

function PZLinuxHackingIsCard(item)
    return item and item.getFullType and PZLinuxHackingCardTypes[item:getFullType()] == true
end

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
            firstName = firstName or item:getName()
            table.insert(cardTypes, item:getFullType())
            if PZLinuxRemoveInventoryItem(playerObj, item) then
                removed = removed + 1
            end
            if removed >= maxCount then break end
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

function PZLinuxHackingStartManual(player, requestId)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return { ok = false, error = "no_player", requestId = requestId } end

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
            PZLinuxClearInterruptedSession(playerObj, "hacking")
        end
    end

    feedback.requestId = requestId
    feedback.amount = session.amount
    feedback.tries = session.tries
    feedback.maxTries = session.maxTries
    feedback.locked = session.locked == true
    feedback.balance = PZLinuxLoadBankBalance(playerObj)
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
