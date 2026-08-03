PZLinux = PZLinux or {}
PZLinux.Config = PZLinux.Config or {}

PZLinux.Config.ATM = PZLinux.Config.ATM or {
    minCash = 10000,
    maxCash = 50000,
}

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
}
