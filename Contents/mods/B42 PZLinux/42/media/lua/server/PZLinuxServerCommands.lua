if isClient() then return end

local PZLINUX_MODULE = "PZLinux"
local PZLINUX_IDEMPOTENCY_MAX_AGE_HOURS = 2
local PZLINUX_IDEMPOTENCY_MAX_PER_PLAYER = 128

PZLinux = PZLinux or {}
PZLinux.serverIdempotency = PZLinux.serverIdempotency or {}

local function PZLinuxServerSend(player, command, args)
    if not sendServerCommand then return end
    sendServerCommand(player, PZLINUX_MODULE, command, args or {})
end

local function PZLinuxServerBroadcast(command, args)
    if not sendServerCommand then return end
    sendServerCommand(PZLINUX_MODULE, command, args or {})
end

local function PZLinuxServerGetWorldHours()
    if getGameTime then
        return getGameTime():getWorldAgeHours()
    end
    return 0
end

local function PZLinuxServerGetIdempotencyBucket(player)
    local playerKey = PZLinuxGetPlayerKey(player)
    PZLinux.serverIdempotency[playerKey] = PZLinux.serverIdempotency[playerKey] or {
        records = {},
        order = {},
    }
    return PZLinux.serverIdempotency[playerKey]
end

local function PZLinuxServerTrimIdempotencyBucket(bucket)
    local now = PZLinuxServerGetWorldHours()
    local writeIndex = 1
    for readIndex = 1, #bucket.order do
        local key = bucket.order[readIndex]
        local record = bucket.records[key]
        if record and now - (record.createdAt or now) <= PZLINUX_IDEMPOTENCY_MAX_AGE_HOURS then
            bucket.order[writeIndex] = key
            writeIndex = writeIndex + 1
        else
            bucket.records[key] = nil
        end
    end
    for index = #bucket.order, writeIndex, -1 do
        bucket.order[index] = nil
    end

    while #bucket.order > PZLINUX_IDEMPOTENCY_MAX_PER_PLAYER do
        local key = table.remove(bucket.order, 1)
        if key then bucket.records[key] = nil end
    end
end

local function PZLinuxServerProcessIdempotent(player, command, args, responseCommand, worker)
    args = args or {}
    PZLinuxApplyInterruptedSessionRollbacks(player)

    local requestId = args.requestId
    if not requestId then
        PZLinuxServerSend(player, responseCommand, worker())
        return
    end

    local bucket = PZLinuxServerGetIdempotencyBucket(player)
    PZLinuxServerTrimIdempotencyBucket(bucket)

    local key = tostring(command) .. ":" .. tostring(requestId)
    local cached = bucket.records[key]
    if cached then
        PZLinuxServerSend(player, responseCommand, cached.result)
        return
    end

    local result = worker()
    bucket.records[key] = {
        createdAt = PZLinuxServerGetWorldHours(),
        result = result,
    }
    table.insert(bucket.order, key)
    PZLinuxServerSend(player, responseCommand, result)
end

local function PZLinuxServerBankRequestSync(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxBankRequestSync", args, "PZLinuxBankSync", function()
        return {
            ok = true,
            requestId = args and args.requestId,
            balance = PZLinuxLoadBankBalance(player),
            reason = "sync",
        }
    end)
end

local function PZLinuxServerBankDebit(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxBankDebit", args, "PZLinuxBankDebitResult", function()
        return PZLinuxApplyBankDebit(player, args and args.amount, args and args.reason, args and args.requestId)
    end)
end

local function PZLinuxServerAtmWithdrawal(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxAtmWithdrawal", args, "PZLinuxAtmTransactionResult", function()
        return PZLinuxApplyAtmWithdrawal(player, args and args.atm, args and args.amount, args and args.requestId)
    end)
end

local function PZLinuxServerAtmRequestSync(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxAtmRequestSync", args, "PZLinuxAtmSyncResult", function()
        return PZLinuxGetAtmState(player, args and args.atm, args and args.requestId)
    end)
end

local function PZLinuxServerAtmDeposit(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxAtmDeposit", args, "PZLinuxAtmTransactionResult", function()
        return PZLinuxApplyAtmDeposit(player, args and args.atm, args and args.amount, args and args.requestId)
    end)
end

local function PZLinuxServerBlackjackStart(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxBlackjackStart", args, "PZLinuxBlackjackState", function()
        return PZLinuxBlackjackStart(player, args and args.amount, args and args.requestId)
    end)
end

local function PZLinuxServerBlackjackHit(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxBlackjackHit", args, "PZLinuxBlackjackState", function()
        return PZLinuxBlackjackHit(player, args and args.requestId)
    end)
end

local function PZLinuxServerBlackjackStand(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxBlackjackStand", args, "PZLinuxBlackjackState", function()
        return PZLinuxBlackjackStand(player, args and args.requestId)
    end)
end

local function PZLinuxServerRaceSchedule(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxRaceSchedule", args, "PZLinuxRaceScheduleResult", function()
        return PZLinuxRaceScheduleSnapshot(player, args and args.requestId)
    end)
end

local function PZLinuxServerRaceScheduleBet(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxRaceScheduleBet", args, "PZLinuxRaceScheduleResult", function()
        return PZLinuxRaceSchedulePlaceBet(
            player,
            args and args.raceId,
            args and args.selectedRunner,
            args and args.amount,
            args and args.requestId
        )
    end)
end

local function PZLinuxServerPokerStart(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxPokerStart", args, "PZLinuxPokerState", function()
        return PZLinuxPokerCreateSession(player, args and args.lobbyId, args and args.buyIn, args and args.requestId)
    end)
end

local function PZLinuxServerPokerAction(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxPokerAction", args, "PZLinuxPokerState", function()
        return PZLinuxPokerAction(player, args and args.action, args and args.amount, args and args.sessionId, args and args.requestId)
    end)
end

local function PZLinuxServerPokerCashOut(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxPokerCashOut", args, "PZLinuxPokerState", function()
        return PZLinuxPokerCashOut(player, args and args.sessionId, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebRequestOffers(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebRequestOffers", args, "PZLinuxDarkWebOffersResult", function()
        return PZLinuxDarkWebGetBuyOffers(player, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebBuy(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebBuy", args, "PZLinuxDarkWebBuyResult", function()
        return PZLinuxDarkWebApplyBuy(player, args and args.offerIndex, args and args.quantity, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebSellOffers(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebSellOffers", args, "PZLinuxDarkWebSellOffersResult", function()
        return PZLinuxDarkWebBuildSellOffers(player, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebSell(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebSell", args, "PZLinuxDarkWebSellResult", function()
        return PZLinuxDarkWebApplySell(player, args and args.offerIndex, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebRedeemSales(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebRedeemSales", args, "PZLinuxDarkWebRedeemSalesResult", function()
        return PZLinuxDarkWebApplyRedeemSales(player, args and args.mailbox, args and args.requestId)
    end)
end

local function PZLinuxServerDarkWebDeliverOrders(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxDarkWebDeliverOrders", args, "PZLinuxDarkWebDeliverOrdersResult", function()
        return PZLinuxDarkWebApplyDeliverOrders(player, args and args.mailbox, args and args.requestId)
    end)
end

local function PZLinuxServerTradingSnapshot(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxTradingSnapshot", args, "PZLinuxTradingSnapshotResult", function()
        return PZLinuxTradingGetSnapshot(player, args and args.requestId)
    end)
end

local function PZLinuxServerTradingBuy(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxTradingBuy", args, "PZLinuxTradingBuyResult", function()
        return PZLinuxTradingApplyBuy(player, args and args.code, args and args.quantity, args and args.requestId)
    end)
end

local function PZLinuxServerTradingSell(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxTradingSell", args, "PZLinuxTradingSellResult", function()
        return PZLinuxTradingApplySell(player, args and args.code, args and args.quantity, args and args.requestId)
    end)
end

local function PZLinuxServerContractsBoard(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractsBoard", args, "PZLinuxContractsBoardResult", function()
        return PZLinuxContractsGetBoard(player, args and args.requestId)
    end)
end

local function PZLinuxServerContractPreview(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractPreview", args, "PZLinuxContractPreviewResult", function()
        return PZLinuxContractsGetPreview(player, args and args.contractId, args and args.requestId)
    end)
end

local function PZLinuxServerContractSync(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractSync", args, "PZLinuxContractSyncResult", function()
        return PZLinuxContractsGetActiveState(player, args and args.requestId)
    end)
end

local function PZLinuxServerContractAccept(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractAccept", args, "PZLinuxContractAcceptResult", function()
        return PZLinuxContractsApplyAccept(player, args, args and args.requestId)
    end)
end

local function PZLinuxServerContractCancel(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractCancel", args, "PZLinuxContractCancelResult", function()
        return PZLinuxContractsApplyCancel(player, args and args.requestId)
    end)
end

local function PZLinuxServerContractDeposit(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractDeposit", args, "PZLinuxContractDepositResult", function()
        return PZLinuxContractsApplyDeposit(player, args and args.mailbox, args and args.requestId)
    end)
end

local function PZLinuxServerContractComplete(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractComplete", args, "PZLinuxContractCompleteResult", function()
        return PZLinuxContractsApplyComplete(player, args, args and args.requestId)
    end)
end

local function PZLinuxServerContractCompletionAck(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractCompletionAck", args, "PZLinuxContractCompletionAckResult", function()
        return PZLinuxContractsAcknowledgeCompletion(
            player,
            args and args.receiptId,
            args and args.requestId
        )
    end)
end

local function PZLinuxServerContractWorldEvent(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxContractWorldEvent", args, "PZLinuxContractWorldEventResult", function()
        local result = PZLinuxContractsApplyWorldEvent(player, args and args.event, args, args and args.requestId)
        if result and result.ok and args and args.event == "capture" then
            PZLinuxServerBroadcast("PZLinuxContractZombieRemoved", { target = args.target })
        end
        return result
    end)
end

local function PZLinuxServerRequestOrder(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxRequestOrder", args, "PZLinuxRequestOrderResult", function()
        return PZLinuxRequestsApplyOrder(player, args, args and args.requestId)
    end)
end

local function PZLinuxServerRequestDeliver(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxRequestDeliver", args, "PZLinuxRequestDeliverResult", function()
        return PZLinuxRequestsApplyDelivery(player, args and args.mailbox, args and args.requestId)
    end)
end

local function PZLinuxServerMailboxState(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxMailboxState", args, "PZLinuxMailboxStateResult", function()
        return PZLinuxMailboxGetActionState(player, args and args.mailbox, args and args.requestId)
    end)
end

local function PZLinuxServerReputationSnapshot(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxReputationSnapshot", args, "PZLinuxReputationSnapshotResult", function()
        return PZLinuxReputationGetSnapshot(player, args and args.requestId)
    end)
end

local function PZLinuxServerRequestSpawnVehicle(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxRequestSpawnVehicle", args, "PZLinuxRequestSpawnVehicleResult", function()
        return PZLinuxRequestsApplySpawnVehicle(player, args and args.requestId)
    end)
end

local function PZLinuxServerMailAccept(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxMailAccept", args, "PZLinuxMailAcceptResult", function()
        return PZLinuxMailApplyAccept(player, args and args.mailId, args and args.requestId)
    end)
end

local function PZLinuxServerMailDelete(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxMailDelete", args, "PZLinuxMailDeleteResult", function()
        return PZLinuxMailApplyDelete(player, args and args.mailId, args and args.requestId)
    end)
end

local function PZLinuxServerMailComplete(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxMailComplete", args, "PZLinuxMailCompleteResult", function()
        return PZLinuxMailApplyComplete(player, args and args.mailId, args and args.requestId)
    end)
end

local function PZLinuxServerMailGenerate(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxMailGenerate", args, "PZLinuxMailGenerateResult", function()
        return PZLinuxMailCreateRandom(player, args and args.requestId)
    end)
end

local function PZLinuxServerHackingStart(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxHackingStart", args, "PZLinuxHackingStartResult", function()
        return PZLinuxHackingStartManual(player, args and args.requestId)
    end)
end

local function PZLinuxServerHackingAuto(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxHackingAuto", args, "PZLinuxHackingAutoResult", function()
        return PZLinuxHackingAuto(player, args and args.requestId)
    end)
end

local function PZLinuxServerHackingGuess(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxHackingGuess", args, "PZLinuxHackingGuessResult", function()
        return PZLinuxHackingGuess(player, args and args.guess, args and args.requestId)
    end)
end

local function PZLinuxServerHackingTransfer(player, args)
    PZLinuxServerProcessIdempotent(player, "PZLinuxHackingTransfer", args, "PZLinuxHackingTransferResult", function()
        return PZLinuxHackingTransfer(player, args and args.requestId)
    end)
end

local PZLINUX_SERVER_COMMANDS = {
    PZLinuxBankRequestSync = PZLinuxServerBankRequestSync,
    PZLinuxBankDebit = PZLinuxServerBankDebit,
    PZLinuxAtmRequestSync = PZLinuxServerAtmRequestSync,
    PZLinuxAtmWithdrawal = PZLinuxServerAtmWithdrawal,
    PZLinuxAtmDeposit = PZLinuxServerAtmDeposit,
    PZLinuxBlackjackStart = PZLinuxServerBlackjackStart,
    PZLinuxBlackjackHit = PZLinuxServerBlackjackHit,
    PZLinuxBlackjackStand = PZLinuxServerBlackjackStand,
    PZLinuxRaceSchedule = PZLinuxServerRaceSchedule,
    PZLinuxRaceScheduleBet = PZLinuxServerRaceScheduleBet,
    PZLinuxPokerStart = PZLinuxServerPokerStart,
    PZLinuxPokerAction = PZLinuxServerPokerAction,
    PZLinuxPokerCashOut = PZLinuxServerPokerCashOut,
    PZLinuxDarkWebRequestOffers = PZLinuxServerDarkWebRequestOffers,
    PZLinuxDarkWebBuy = PZLinuxServerDarkWebBuy,
    PZLinuxDarkWebSellOffers = PZLinuxServerDarkWebSellOffers,
    PZLinuxDarkWebSell = PZLinuxServerDarkWebSell,
    PZLinuxDarkWebRedeemSales = PZLinuxServerDarkWebRedeemSales,
    PZLinuxDarkWebDeliverOrders = PZLinuxServerDarkWebDeliverOrders,
    PZLinuxTradingSnapshot = PZLinuxServerTradingSnapshot,
    PZLinuxTradingBuy = PZLinuxServerTradingBuy,
    PZLinuxTradingSell = PZLinuxServerTradingSell,
    PZLinuxContractsBoard = PZLinuxServerContractsBoard,
    PZLinuxContractPreview = PZLinuxServerContractPreview,
    PZLinuxContractSync = PZLinuxServerContractSync,
    PZLinuxContractAccept = PZLinuxServerContractAccept,
    PZLinuxContractCancel = PZLinuxServerContractCancel,
    PZLinuxContractDeposit = PZLinuxServerContractDeposit,
    PZLinuxContractComplete = PZLinuxServerContractComplete,
    PZLinuxContractCompletionAck = PZLinuxServerContractCompletionAck,
    PZLinuxContractWorldEvent = PZLinuxServerContractWorldEvent,
    PZLinuxRequestOrder = PZLinuxServerRequestOrder,
    PZLinuxRequestDeliver = PZLinuxServerRequestDeliver,
    PZLinuxMailboxState = PZLinuxServerMailboxState,
    PZLinuxReputationSnapshot = PZLinuxServerReputationSnapshot,
    PZLinuxRequestSpawnVehicle = PZLinuxServerRequestSpawnVehicle,
    PZLinuxMailAccept = PZLinuxServerMailAccept,
    PZLinuxMailDelete = PZLinuxServerMailDelete,
    PZLinuxMailComplete = PZLinuxServerMailComplete,
    PZLinuxMailGenerate = PZLinuxServerMailGenerate,
    PZLinuxHackingStart = PZLinuxServerHackingStart,
    PZLinuxHackingAuto = PZLinuxServerHackingAuto,
    PZLinuxHackingGuess = PZLinuxServerHackingGuess,
    PZLinuxHackingTransfer = PZLinuxServerHackingTransfer,
}

local function PZLinuxOnClientCommand(module, command, player, args)
    if module ~= PZLINUX_MODULE then return end

    local handler = PZLINUX_SERVER_COMMANDS[command]
    if handler then
        handler(player, args or {})
    end
end

Events.OnClientCommand.Add(PZLinuxOnClientCommand)

local function PZLinuxServerOnZombieDead(zombie)
    PZLinuxContractsApplyServerZombieDeath(zombie)
end

Events.OnZombieDead.Add(PZLinuxServerOnZombieDead)

local function PZLinuxServerForEachOnlinePlayer(callback)
    if not getOnlinePlayers then return end
    local players = getOnlinePlayers()
    if not players then return end
    for index = 0, players:size() - 1 do
        local playerObj = players:get(index)
        if playerObj then callback(playerObj) end
    end
end

Events.EveryOneMinute.Add(function()
    PZLinuxServerForEachOnlinePlayer(PZLinuxContractsReconcilePlayerZombieKills)
end)

Events.EveryTenMinutes.Add(function()
    PZLinuxRaceScheduleTick()
    PZLinuxServerForEachOnlinePlayer(function(playerObj)
        PZLinuxRaceScheduleProcessPlayer(playerObj)
        PZLinuxApplyReputationDecay(playerObj, 0.001)
        if isServer and isServer() then
            PZLinuxMailTickPlayer(playerObj)
        end
    end)
end)
