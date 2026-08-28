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
    logActions = true,
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
    -- Lobbies now mix several engines directly here: micro stays forgiving,
    -- low introduces disciplined folders, high adds readers plus one loose
    -- seat, and elite removes the soft spots entirely without changing the
    -- poker engine itself.
    -- The stakes ladder. Each bracket is a different kind of table, not the
    -- same table with bigger numbers -- who is sitting there is what makes a
    -- game easy or brutal, far more than the blinds do.
    --
    -- micro  the shallow end. ZombieBrain folds to any bet and the Drunkard
    --        plays blind, so a patient player prints money and learns the
    --        interface without being punished for it.
    --
    -- low    the first table that folds correctly. Survivors will not pay off
    --        a weak hand, so the loose play that won at micro stops working,
    --        but two Drunkards are still there to fund the lesson.
    --
    -- high   a real game: competent opposition, one Drunkard as the loose
    --        money everyone is competing for, and a Shark with a tell. That
    --        seat is the point of the bracket -- it plays well, it bets big
    --        when strong and small when weak, every time, and a player who
    --        notices gets a genuine edge. Skill 4 rather than 5 so the tell
    --        is not buried under perfect play.
    --
    -- elite  brutal on purpose. Every seat is a maximum-skill reading engine,
    --        no tells, nobody loose. With no fish at the table the player is
    --        the fish, which is exactly the intended experience -- and the
    --        reason the buy-in cap above matters.
    lobbies = {
        { id = "micro", smallBlind = 1, bigBlind = 2,
          aiEngines = {
              { id = "zombiebrain", chance = 0.55,
                params = { difficultyWeights = { 45, 30, 15, 7, 3 } } },
              { id = "drunkard", chance = 0.45 },
          } },
        { id = "low", smallBlind = 5, bigBlind = 10,
          aiEngines = {
              { id = "zombiebrain", chance = 0.30,
                params = { difficultyWeights = { 25, 30, 25, 14, 6 } } },
              { id = "drunkard", chance = 0.30 },
              { id = "survivor", chance = 0.40, params = { skill = 2 } },
          } },
        { id = "high", smallBlind = 20, bigBlind = 40,
          aiEngines = {
              { id = "drunkard", chance = 0.20 },
              { id = "survivor", chance = 0.40, params = { skill = 4 } },
              { id = "shark", chance = 0.25, params = { skill = 3 } },
              -- The readable seat: strong, but it tells you what it has.
              { id = "shark", chance = 0.15,
                params = { skill = 4, sizingTell = 0.7, sizingError = 0 } },
          } },
        { id = "elite", smallBlind = 50, bigBlind = 100,
          aiEngines = {
              { id = "survivor", chance = 0.45, params = { skill = 5 } },
              { id = "shark", chance = 0.55, params = { skill = 5 } },
          } },
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
if PZLinux.Poker.Config.logActions == nil then PZLinux.Poker.Config.logActions = true end

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
