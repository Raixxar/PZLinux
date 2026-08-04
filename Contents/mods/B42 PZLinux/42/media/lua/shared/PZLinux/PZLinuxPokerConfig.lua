PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}

PZLinux.Poker.SaveVersion = 1

PZLinux.Poker.Config = PZLinux.Poker.Config or {
    opponentCount = 5,
    minBuyInBigBlinds = 50,
    maxBuyInBigBlinds = 100,
    aiStackMinBigBlinds = 50,
    aiStackMaxBigBlinds = 100,
    aiDecisionDelayTicks = 20,
    rakePercent = 0,
    maxActionHistory = 12,
    lobbies = {
        { id = "micro", smallBlind = 5, bigBlind = 10 },
        { id = "low", smallBlind = 50, bigBlind = 100 },
        { id = "high", smallBlind = 500, bigBlind = 1000 },
        { id = "elite", smallBlind = 5000, bigBlind = 10000 },
    },
    aiDifficultyWeights = { 25, 25, 25, 15, 10 },
    aiBluffChance = {
        [1] = 18,
        [2] = 14,
        [3] = 10,
        [4] = 8,
        [5] = 6,
    },
    names = {
        first = { "Alex", "Morgan", "Casey", "Jordan", "Taylor", "Riley", "Quinn", "Sam", "Drew", "Avery", "Jamie", "Reese" },
        last = { "Stone", "Cross", "Vale", "Reed", "Fox", "Blake", "Wells", "King", "Cole", "Shaw", "Moss", "Page" },
    },
}
PZLinux.Poker.Config.equitySimulationCount = PZLinux.Poker.Config.equitySimulationCount or 300

function PZLinuxPokerGetLobby(lobbyId)
    for _, lobby in ipairs(PZLinux.Poker.Config.lobbies or {}) do
        if lobby.id == lobbyId then
            return lobby
        end
    end
    return nil
end

function PZLinuxPokerGetBuyInLimits(lobby)
    if not lobby then return 0, 0 end
    local minBuyIn = (tonumber(PZLinux.Poker.Config.minBuyInBigBlinds) or 50) * lobby.bigBlind
    local maxBuyIn = (tonumber(PZLinux.Poker.Config.maxBuyInBigBlinds) or 100) * lobby.bigBlind
    return minBuyIn, maxBuyIn
end
