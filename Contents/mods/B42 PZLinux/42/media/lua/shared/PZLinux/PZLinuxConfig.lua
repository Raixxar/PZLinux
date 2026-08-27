PZLinux = PZLinux or {}
PZLinux.Config = PZLinux.Config or {}

-- General ATM cash reserve range, used by every ordinary ATM on the map
-- (the single "Refill an ATM" contract target ATM is deliberately kept much
-- smaller instead -- see AtmRefill.targetCashMin/targetCashMax below -- so
-- that contract feels like it actually matters). Player deposits are hard
-- capped at maxCash (see PZLinuxApplyAtmDeposit): without that cap, one
-- player could deposit an arbitrarily large sum for another player to
-- withdraw elsewhere -- an easy, untraceable way to hand over money in MP.
PZLinux.Config.ATM = PZLinux.Config.ATM or {
    minCash = 10000,
    maxCash = 50000,
    -- Cash slowly regenerates over in-game time (a cash truck service,
    -- narratively), so withdrawals alone can never permanently drain every
    -- ATM on the map. Regen only ever refunds cash that was actually
    -- withdrawn from that specific ATM (never grows a machine no one has
    -- touched), and is additionally hard-capped at restockCap lifetime --
    -- without that second cap, an ATM withdrawn from heavily over a long
    -- game could still regen all the way up to maxCash on its own and
    -- permanently block deposits there, even though every dollar of that
    -- regen was "earned back" by real withdrawals.
    restockPerHour = 500,
    restockCap = 15000,
}
PZLinux.Config.ATM.minCash = tonumber(PZLinux.Config.ATM.minCash) or 10000
PZLinux.Config.ATM.maxCash = tonumber(PZLinux.Config.ATM.maxCash) or 50000
PZLinux.Config.ATM.restockPerHour = tonumber(PZLinux.Config.ATM.restockPerHour) or 500
PZLinux.Config.ATM.restockCap = tonumber(PZLinux.Config.ATM.restockCap) or 15000

-- Mailbox deliveries may temporarily overload a character up to an absolute
-- carried-weight limit of 80. Individual parcels remain capped at 60 so large
-- orders are split into persistent parts instead of arriving all at once.
PZLinux.Config.Deliveries = PZLinux.Config.Deliveries or {
    maxCarryWeight = 80,
    maxParcelWeight = 60,
}
PZLinux.Config.Deliveries.maxCarryWeight =
    math.max(1, tonumber(PZLinux.Config.Deliveries.maxCarryWeight) or 80)
PZLinux.Config.Deliveries.maxParcelWeight = math.min(
    PZLinux.Config.Deliveries.maxCarryWeight,
    math.max(1, tonumber(PZLinux.Config.Deliveries.maxParcelWeight) or 60)
)

PZLinux.Config.Contracts = PZLinux.Config.Contracts or {
    packageInteractionRadius = 5,
    objectiveActivationRadius = 80,
    objectiveSpawnSearchRadius = 15,
    boardRefreshHours = 168,
    cargoSprite = "carpentry_01_19",
}
PZLinux.Config.Contracts.boardRefreshHours = tonumber(PZLinux.Config.Contracts.boardRefreshHours) or 168
PZLinux.Config.Contracts.objectiveActivationRadius =
    tonumber(PZLinux.Config.Contracts.objectiveActivationRadius) or 80
PZLinux.Config.Contracts.objectiveSpawnSearchRadius =
    tonumber(PZLinux.Config.Contracts.objectiveSpawnSearchRadius) or 15
PZLinux.Config.Contracts.cargoSprite = PZLinux.Config.Contracts.cargoSprite or "carpentry_01_19"

-- "Refill an ATM" (contract id 13). Its single wall-mounted ATM location
-- lives in the "atmRefill" pool in PZLinuxMissionLocations.lua, alongside
-- every other contract location, so it is never hardcoded here too. The
-- amount to refill is rolled fresh per mission between amountMin and
-- amountMax in amountStep increments (e.g. $1,000-$5,000 by $100). Physical
-- cash weighs roughly 0.5kg per $100 bundle, so this range (5kg-25kg) is
-- deliberately kept realistic to actually carry in one trip, unlike the
-- earlier $10k-$60k range which would have weighed 50-300kg. The player must
-- already have that much in their bank account to even accept the contract
-- (otherwise they could never withdraw it at all). The contract itself never
-- touches the bank or hands over any cash -- the actual difficulty is having
-- to withdraw that much physical cash from ATMs around town (possibly
-- emptying several of them) and carry it all to the one hardcoded target to
-- deposit it.
-- targetCashMin/targetCashMax: unlike ordinary ATMs (PZLinux.Config.ATM,
-- 10,000-50,000 $), every ATM this contract can target is a small
-- wall-mounted branch machine, fixed in place (never removable/movable from
-- the world) and modeled as almost empty -- 1-501 $ -- to make it visibly
-- obvious there is barely anything left, so depositing the 1,000-5,000 $ the
-- player carries in actually feels like it matters.
PZLinux.Config.AtmRefill = PZLinux.Config.AtmRefill or {
    amountMin = 1000,
    amountMax = 5000,
    amountStep = 100,
    targetCashMin = 1,
    targetCashMax = 501,
}
PZLinux.Config.AtmRefill.amountMin = tonumber(PZLinux.Config.AtmRefill.amountMin) or 1000
PZLinux.Config.AtmRefill.amountMax = tonumber(PZLinux.Config.AtmRefill.amountMax) or 5000
PZLinux.Config.AtmRefill.amountStep = tonumber(PZLinux.Config.AtmRefill.amountStep) or 100
PZLinux.Config.AtmRefill.targetCashMin = tonumber(PZLinux.Config.AtmRefill.targetCashMin) or 1
PZLinux.Config.AtmRefill.targetCashMax = tonumber(PZLinux.Config.AtmRefill.targetCashMax) or 501

PZLinux.Config.Reputation = PZLinux.Config.Reputation or {
    baseline = 1,
    minimum = -99,
    maximum = 200,
    contractCompleteReward = 10,
    contractCancelPenalty = 10,
    purchaseSurchargePerPoint = 0.01,
    maximumPurchaseSurcharge = 1.00,
    purchaseDiscountPerPoint = 0.0025,
    maximumPurchaseDiscount = 0.25,
}

PZLinux.Config.Economy = PZLinux.Config.Economy or {
    scarcityPeriodHours = 2190,
    scarcityMaximumMultiplier = 8,
    priceRoundingTiers = {
        { maximum = 99, step = 5 },
        { maximum = 999, step = 10 },
        { maximum = 9999, step = 50 },
        { maximum = 49999, step = 100 },
        { step = 500 },
    },
}

PZLinux.Config.UI = PZLinux.Config.UI or {
    typingDelayMinMs = 90,
    typingDelayMaxMs = 180,
    messageDelayMinMs = 1800,
    messageDelayMaxMs = 4200,
    systemStatusDelayMinMs = 400,
    systemStatusDelayMaxMs = 1000,
    atmPromptDelayMinMs = 250,
    atmPromptDelayMaxMs = 650,
    atmStatusDelayMinMs = 350,
    atmStatusDelayMaxMs = 850,
}

-- Once per game day, each Request category independently rolls whether a
-- seller is willing to trade at all today (deliberately rare, so finding one
-- feels like an actual event rather than an on-demand shop). Only categories
-- that rolled available are shown in the Request menu; refusing an offered
-- price hides that category the same way, until the next game day's roll.
-- The chance of finding nobody rises over time (fewer survivors left as the
-- world ages): it starts at unavailableChancePercentStart and ramps linearly
-- up to unavailableChancePercentMax over unavailableRampGameDays in-game
-- days, then stays capped there.
PZLinux.Config.Requests = PZLinux.Config.Requests or {
    unavailableChancePercentStart = 50,
    unavailableChancePercentMax = 75,
    unavailableRampGameDays = 180,
}
PZLinux.Config.Requests.unavailableChancePercentStart =
    tonumber(PZLinux.Config.Requests.unavailableChancePercentStart) or 50
PZLinux.Config.Requests.unavailableChancePercentMax =
    tonumber(PZLinux.Config.Requests.unavailableChancePercentMax) or 75
PZLinux.Config.Requests.unavailableRampGameDays =
    tonumber(PZLinux.Config.Requests.unavailableRampGameDays) or 180

-- Sell Surplus: the inverse of Requests, Dark Web-styled. Every sellable item
-- independently has a small daily chance of being wanted, for a random
-- quantity the player must fully own to sell (no partial sale). The base
-- price is deliberately bad (a fraction of the item's reference value) so
-- this never becomes a real income source, with a rare chance of a much
-- better one-off offer instead, plus an optional 50/50 negotiation minigame.
PZLinux.Config.Sell = PZLinux.Config.Sell or {
    demandChancePercent = 15,
    quantityMin = 1,
    quantityMax = 10,
    basePricePercentMin = 15,
    basePricePercentMax = 25,
    greatDealChancePercent = 10,
    greatDealMinPercent = 25,
    greatDealMaxPercent = 75,
    negotiateIncrement = 100,
    negotiateSuccessChancePercent = 50,
}
PZLinux.Config.Sell.demandChancePercent =
    tonumber(PZLinux.Config.Sell.demandChancePercent) or 15
PZLinux.Config.Sell.quantityMin =
    tonumber(PZLinux.Config.Sell.quantityMin) or 1
PZLinux.Config.Sell.quantityMax =
    tonumber(PZLinux.Config.Sell.quantityMax) or 10
PZLinux.Config.Sell.basePricePercentMin =
    tonumber(PZLinux.Config.Sell.basePricePercentMin) or 15
PZLinux.Config.Sell.basePricePercentMax =
    tonumber(PZLinux.Config.Sell.basePricePercentMax) or 25
PZLinux.Config.Sell.greatDealChancePercent =
    tonumber(PZLinux.Config.Sell.greatDealChancePercent) or 10
PZLinux.Config.Sell.greatDealMinPercent =
    tonumber(PZLinux.Config.Sell.greatDealMinPercent) or 25
PZLinux.Config.Sell.greatDealMaxPercent =
    tonumber(PZLinux.Config.Sell.greatDealMaxPercent) or 75
PZLinux.Config.Sell.negotiateIncrement =
    tonumber(PZLinux.Config.Sell.negotiateIncrement) or 100
PZLinux.Config.Sell.negotiateSuccessChancePercent =
    tonumber(PZLinux.Config.Sell.negotiateSuccessChancePercent) or 50

PZLinux.Config.Blackjack = PZLinux.Config.Blackjack or {
    ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" },
    suits = { "C", "D", "H", "S" },
    -- Fixed-stakes tables, same idea as the Poker lobbies (PZLinuxPokerConfig.lua):
    -- a real casino caps every table's bet regardless of bankroll, rather than
    -- letting a lucky streak compound a small bet into an enormous one in just
    -- a couple of hands. Deliberately NOT scaled by world-age price inflation --
    -- these are fixed stakes, like a real table's posted limits never move.
    -- Capped so even the best case (a natural blackjack, 2.5x, at the top
    -- table's max bet) stays below the single best-paying contract ($14,000)
    -- -- gambling is meant to stay a fun distraction, never a substitute for
    -- Contracts as the mod's one reliable income source.
    tables = {
        { id = "micro", minBet = 10, maxBet = 100 },
        { id = "low", minBet = 50, maxBet = 500 },
        { id = "high", minBet = 200, maxBet = 1000 },
        { id = "elite", minBet = 1000, maxBet = 5000 },
    },
}

function PZLinuxBlackjackGetTable(tableId)
    for _, tableDef in ipairs(PZLinux.Config.Blackjack.tables or {}) do
        if tableDef.id == tableId then
            return tableDef
        end
    end
    return nil
end
