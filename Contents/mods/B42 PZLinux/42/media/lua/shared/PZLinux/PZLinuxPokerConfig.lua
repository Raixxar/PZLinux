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
    -- Capped so even the top table's max buy-in ($10,000, at 100x its big
    -- blind) stays well below the single best-paying contract ($14,000) --
    -- gambling is meant to stay a fun distraction, never a substitute for
    -- Contracts as the mod's one reliable income source. Same philosophy
    -- as the Blackjack tables (PZLinuxConfig.lua).
    -- Each lobby picks the AI engine for every seat it creates from its own
    -- aiEngines list: an engine id registered through PZLinuxPokerRegisterAI
    -- (see PZLinuxPokerAIRegistry.lua) and a 0.0 to 1.0 chance of a newly
    -- seated opponent using it. Chances are normalised by their sum, so a
    -- single entry at 1.0 means "every seat at this table plays this way".
    -- Today every lobby is pure Zombie Brain, which is exactly how the
    -- tables played before engines were separable; new engines get mixed in
    -- by adding entries here and lowering this one, per lobby, without
    -- touching the poker engine itself.
    -- An entry may also carry params, which reach the engine as
    -- context.params and are documented by that engine rather than here.
    -- Below, they buy what the tables never had before: the money you sit
    -- down with decides how good the players across from you are. Micro is
    -- mostly level 1-2 opposition, elite is mostly level 4-5. Delete a
    -- params line and that lobby falls back to aiDifficultyWeights below,
    -- which is the flat spread every table used to share.
    lobbies = {
        { id = "micro", smallBlind = 1, bigBlind = 2,
          aiEngines = { { id = "zombiebrain", chance = 1.0,
                          params = { difficultyWeights = { 45, 30, 15, 7, 3 } } } } },
        { id = "low", smallBlind = 5, bigBlind = 10,
          aiEngines = { { id = "zombiebrain", chance = 1.0,
                          params = { difficultyWeights = { 25, 30, 25, 14, 6 } } } } },
        { id = "high", smallBlind = 20, bigBlind = 40,
          aiEngines = { { id = "zombiebrain", chance = 1.0,
                          params = { difficultyWeights = { 10, 20, 30, 25, 15 } } } } },
        { id = "elite", smallBlind = 50, bigBlind = 100,
          aiEngines = { { id = "zombiebrain", chance = 1.0,
                          params = { difficultyWeights = { 3, 10, 22, 35, 30 } } } } },
    },
    -- Used for any lobby that does not declare its own aiEngines list.
    defaultAIEngines = { { id = "zombiebrain", chance = 1.0 } },
    -- Fallback skill spread for any lobby or engine that names no
    -- difficultyWeights params of its own.
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
