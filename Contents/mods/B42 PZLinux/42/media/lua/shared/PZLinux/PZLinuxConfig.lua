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

PZLinux.Config.Blackjack = PZLinux.Config.Blackjack or {
    ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" },
    suits = { "C", "D", "H", "S" },
}
