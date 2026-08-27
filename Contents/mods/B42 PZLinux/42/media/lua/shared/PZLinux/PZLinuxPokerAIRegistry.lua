-- Poker AI engine registry.
--
-- Every AI opponent seated at a poker table is driven by a named engine
-- registered here. The engine decides only what action to take; all chip
-- movement, pot bookkeeping and history writing stays in
-- PZLinuxPokerEngine.lua (PZLinuxPokerApplyAIDecision) so that money
-- handling lives in exactly one audited place -- a bad or third-party
-- engine can play badly, but it cannot invent chips.
--
-- Load order note: this file only creates tables and functions, and every
-- engine registers itself into PZLinux.Poker.AI.Engines at load time.
-- Lobbies reference engines by string id and resolve them at runtime, so
-- the order in which Project Zomboid loads these shared files does not
-- matter.
--
-- Engine contract:
--   engine.id          string, unique, used by lobby config
--   engine.name        display name (optional, defaults to id)
--   engine.decide      function(engine, context) -> decision
--   engine.createSeat  function(engine, seat, lobby, context) (optional)
--                      called once when the AI seat is created, for
--                      engine-specific per-seat state (skill, style, ...)
--
-- decide() receives a context table:
--   session, seat, seatIndex, toCall, pot, potOdds,
--   currentBet, minRaise, bigBlind, strength,
--   random(maxExclusive), randomRange(minInclusive, maxExclusive)
--
-- decide() returns { action = "fold" | "check" | "call" | "raise",
--                    amount = <total chips to put in on a raise> }
-- An unknown or missing return is treated as check when nothing is owed
-- and fold otherwise.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}
PZLinux.Poker.AI.FallbackEngineId = PZLinux.Poker.AI.FallbackEngineId or "zombiebrain"

local function PZLinuxPokerAIDefaultRandom(maxExclusive)
    if ZombRand then return ZombRand(maxExclusive) end
    return math.random(0, maxExclusive - 1)
end

function PZLinuxPokerRegisterAI(engine)
    if type(engine) ~= "table" then return nil, "invalid_engine" end
    local id = tostring(engine.id or "")
    if id == "" then return nil, "missing_id" end
    if type(engine.decide) ~= "function" then return nil, "missing_decide" end
    engine.id = id
    engine.name = engine.name or id
    PZLinux.Poker.AI.Engines[id] = engine
    return engine
end

function PZLinuxPokerGetAI(engineId)
    if engineId == nil then return nil end
    return PZLinux.Poker.AI.Engines[tostring(engineId)]
end

function PZLinuxPokerGetFallbackAI()
    return PZLinuxPokerGetAI(PZLinux.Poker.AI.FallbackEngineId)
end

function PZLinuxPokerListAI()
    local ids = {}
    for id in pairs(PZLinux.Poker.AI.Engines) do table.insert(ids, id) end
    table.sort(ids)
    return ids
end

-- Resolves a lobby's engine mix into the list actually usable right now:
-- entries with a chance at or below zero are dropped, and so are entries
-- naming an engine that is not registered (a mod that adds engines can be
-- uninstalled without breaking every lobby that mentioned them).
function PZLinuxPokerGetLobbyAIEngines(lobby)
    local configured = (lobby and lobby.aiEngines)
        or (PZLinux.Poker.Config and PZLinux.Poker.Config.defaultAIEngines)
        or {}
    local candidates = {}
    local total = 0
    for _, entry in ipairs(configured) do
        local id = entry and tostring(entry.id or "")
        local chance = tonumber(entry and entry.chance) or 0
        local engine = id ~= "" and PZLinuxPokerGetAI(id) or nil
        if engine and chance > 0 then
            table.insert(candidates, { id = id, chance = chance, engine = engine })
            total = total + chance
        end
    end
    return candidates, total
end

-- Weighted pick. Chances are written as 0.0 to 1.0 per entry and are
-- normalised by their sum, so a lobby listing a single engine at 1.0
-- always yields that engine, and a lobby listing 0.7 / 0.3 splits 70/30
-- whether or not the author kept the sum at exactly 1.0.
function PZLinuxPokerPickAIEngineId(lobby, randomFn)
    local candidates, total = PZLinuxPokerGetLobbyAIEngines(lobby)
    if #candidates == 0 then
        local fallback = PZLinuxPokerGetFallbackAI()
        return fallback and fallback.id or nil
    end
    -- Single-candidate lobbies skip the draw entirely so that the default
    -- configuration consumes no randomness it did not consume before.
    if #candidates == 1 then return candidates[1].id end

    randomFn = randomFn or PZLinuxPokerAIDefaultRandom
    local roll = (randomFn(100000) + 1) / 100000 * total
    local running = 0
    for _, candidate in ipairs(candidates) do
        running = running + candidate.chance
        if roll <= running then return candidate.id end
    end
    return candidates[#candidates].id
end
