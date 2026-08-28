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
-- A lobby may tune an engine without forking it by attaching params to its
-- aiEngines entry. The same engine id can therefore appear at two different
-- stakes with two different personalities:
--
--   aiEngines = {
--       { id = "zombiebrain", chance = 0.3, params = { difficultyWeights = { 5, 10, 25, 35, 25 } } },
--       { id = "shark",       chance = 0.7 },
--   }
--
-- Params reach the engine as context.params in both createSeat and decide.
-- Each seat gets its own deep copy, so an engine that writes to its params
-- cannot leak that change into the shared config table or into any other
-- seat.
--
-- createSeat() receives setup copies too. Writes to harmless per-seat metadata
-- such as difficulty or style are copied back after the hook returns, but live
-- gameplay fields are protected: stack, cards, bets, identity, params, memory
-- and every session/lobby table handed to the engine cannot be mutated in
-- place.
--
-- An engine should declare engine.defaults -- a table, or a function
-- returning one, when the defaults follow live config that may change after
-- load. Params from a lobby are then merged over those defaults: a key that
-- is missing keeps its default, a key whose value is the wrong type keeps its
-- default, and a key the engine never declared is dropped. All three are
-- logged once. The engine therefore always sees a complete, correctly typed
-- params table and never has to guard its own reads. An engine that declares
-- no defaults gets its lobby params passed through unchecked.
--
-- decide() receives a context table:
--   session, seat, seatIndex, toCall, pot, potOdds,
--   currentBet, minRaise, bigBlind, strength, params, memory,
--   random(maxExclusive), randomRange(minInclusive, maxExclusive)
--
-- context.session, context.seat and context.params are freshly built copies,
-- not the live table. An engine may read everything on them, opponents' hole
-- cards included, but writing to them changes nothing -- the copy is discarded
-- the moment decide() returns. The undealt deck is not exposed at all.
--
-- context.memory is the exception: a per-seat scratch table that does persist
-- across decisions, for engines that build an opponent model over a session.
-- It holds no chips and no cards, so nothing stored there can move money.
--
-- decide() returns { action = "fold" | "check" | "call" | "raise",
--                    amount = <chips this action adds on a raise> }
-- The raise amount includes any call first: when toCall is 20 and amount is
-- 60, the seat pays 20 to call and 40 more to raise.
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
            table.insert(candidates, { id = id, chance = chance, engine = engine, params = entry.params })
            total = total + chance
        end
    end
    return candidates, total
end

-- Engines flagged testOnly exist to measure the others -- one plays blind,
-- one sees every hole card. Neither belongs at a table a player sits down at,
-- so seating one says so out loud rather than failing silently.
local PZLinuxPokerTestEngineWarnings = {}

function PZLinuxPokerWarnTestEngine(engine)
    if not engine or not engine.testOnly then return end
    if PZLinuxPokerTestEngineWarnings[engine.id] then return end
    PZLinuxPokerTestEngineWarnings[engine.id] = true
    print(string.format("[PZLinux Poker] seating TEST engine %s -- diagnostics only, not for a live lobby",
        tostring(engine.id)))
end

-- Deep copy, so that a seat can never write through its params into the
-- shared lobby config -- or into another seat that drew the same entry.
function PZLinuxPokerCopyEngineParams(params)
    if type(params) ~= "table" then return {} end
    local copy = {}
    for key, value in pairs(params) do
        if type(value) == "table" then
            copy[key] = PZLinuxPokerCopyEngineParams(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- One line per problem per engine, not one per seat dealt: a mistyped param
-- in a lobby would otherwise log five times a table, every table, forever.
local PZLinuxPokerParamWarnings = {}

local function PZLinuxPokerWarnParam(engineId, key, reason)
    local warningKey = tostring(engineId) .. "|" .. tostring(key) .. "|" .. reason
    if PZLinuxPokerParamWarnings[warningKey] then return end
    PZLinuxPokerParamWarnings[warningKey] = true
    print(string.format("[PZLinux Poker] engine %s: param %s %s, using the default",
        tostring(engineId), tostring(key), reason))
end

-- Merges a lobby's params over an engine's declared defaults. A lobby that
-- names no params, names half of them, or names one with the wrong type all
-- end up with an engine running on values it can actually use -- a config
-- mistake costs a log line and a default, never a broken table.
function PZLinuxPokerResolveEngineParams(engine, params)
    local defaults = engine and engine.defaults
    if type(defaults) == "function" then defaults = defaults(engine) end
    if type(defaults) ~= "table" then
        -- No declared schema, so there is nothing to validate against.
        return PZLinuxPokerCopyEngineParams(params)
    end

    local resolved = PZLinuxPokerCopyEngineParams(defaults)
    if params ~= nil and type(params) ~= "table" then
        PZLinuxPokerWarnParam(engine and engine.id, "params", "must be a table, got " .. type(params))
        return resolved
    end
    if type(params) ~= "table" then return resolved end

    for key, value in pairs(params) do
        local default = resolved[key]
        if default == nil then
            PZLinuxPokerWarnParam(engine and engine.id, key, "is not declared by this engine")
        elseif type(value) ~= type(default) then
            PZLinuxPokerWarnParam(engine and engine.id, key,
                "expects " .. type(default) .. ", got " .. type(value))
        elseif type(value) == "table" then
            resolved[key] = PZLinuxPokerCopyEngineParams(value)
        else
            resolved[key] = value
        end
    end
    return resolved
end

-- Weighted pick. Chances are written as 0.0 to 1.0 per entry and are
-- normalised by their sum, so a lobby listing a single engine at 1.0
-- always yields that engine, and a lobby listing 0.7 / 0.3 splits 70/30
-- whether or not the author kept the sum at exactly 1.0.
--
-- Returns the whole entry, because the caller needs the params attached to
-- the winning one and not just its id.
function PZLinuxPokerPickAIEngineEntry(lobby, randomFn)
    local candidates, total = PZLinuxPokerGetLobbyAIEngines(lobby)
    if #candidates == 0 then
        local fallback = PZLinuxPokerGetFallbackAI()
        if not fallback then return nil end
        return { id = fallback.id, chance = 1, engine = fallback }
    end
    -- Single-candidate lobbies skip the draw entirely so that the default
    -- configuration consumes no randomness it did not consume before.
    if #candidates == 1 then
        PZLinuxPokerWarnTestEngine(candidates[1].engine)
        return candidates[1]
    end

    randomFn = randomFn or PZLinuxPokerAIDefaultRandom
    local roll = (randomFn(100000) + 1) / 100000 * total
    local running = 0
    for _, candidate in ipairs(candidates) do
        running = running + candidate.chance
        if roll <= running then
            PZLinuxPokerWarnTestEngine(candidate.engine)
            return candidate
        end
    end
    return candidates[#candidates]
end

function PZLinuxPokerPickAIEngineId(lobby, randomFn)
    local entry = PZLinuxPokerPickAIEngineEntry(lobby, randomFn)
    return entry and entry.id or nil
end
