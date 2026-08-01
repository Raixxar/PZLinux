PZLinux = PZLinux or {}
PZLinux.Config = PZLinux.Config or {}

PZLinux.Config.ATM = PZLinux.Config.ATM or {
    minCash = 10000,
    maxCash = 50000,
}

PZLinux.Config.Contracts = PZLinux.Config.Contracts or {
    packageInteractionRadius = 5,
}

PZLinux.Config.UI = PZLinux.Config.UI or {
    typingDelayMin = 2,
    typingDelayMax = 5,
    messageDelayMin = 80,
    messageDelayMax = 180,
    systemStatusDelayMin = 20,
    systemStatusDelayMax = 100,
    atmPromptDelayMin = 5,
    atmPromptDelayMax = 15,
    atmStatusDelayMin = 8,
    atmStatusDelayMax = 20,
}

PZLinux.Config.Blackjack = PZLinux.Config.Blackjack or {
    ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" },
    suits = { "C", "D", "H", "S" },
}
