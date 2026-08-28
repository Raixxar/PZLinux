-- Covers the pluggable poker AI registry: lobby engine mixes, per-seat
-- engine assignment, custom engine registration, and the guarantee that
-- an engine can only ever express an intent -- never move chips itself.

math.randomseed(20260826)

ZombRand = function(a, b)
    if b then return math.random(a, b - 1) end
    return math.random(0, a - 1)
end

PZLinuxGetPlayer = function(player) return player end
PZLinuxGetPlayerKey = function() return "test" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
PZLinuxLoadBankBalance = function() return 100000 end
PZLinuxApplyBankDebit = function(_, amount) return { ok = true, amount = amount, balance = 100000 - amount } end
PZLinuxApplyBankCredit = function(_, amount) return { ok = true, amount = amount, balance = 100000 + amount } end
PZLinuxNextRequestId = function(prefix) return tostring(prefix) .. "-1" end
PZLinuxRegisterInterruptedSession = function() end
PZLinuxClearInterruptedSession = function() end

local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIRegistry.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerConfig.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAISkill.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIReads.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIZombieBrain.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIDrunkard.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAISurvivor.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIShark.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAITestZombieHunter.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAITestCheater.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerEngine.lua")

-- The shipped engine registers itself at load time and is the fallback.
assert(PZLinuxPokerGetAI("zombiebrain"), "the Zombie Brain engine must register itself on load")
assert(PZLinuxPokerGetFallbackAI().id == "zombiebrain", "Zombie Brain must remain the fallback engine")

-- The stakes ladder. Every bracket must be seatable, and the mix must be the
-- one the design intends -- who is sitting at a table is what makes it easy or
-- brutal, so a silent change here changes the game.
local READING_ENGINES = { survivor = true, shark = true }
local readerShare = {}
for _, lobby in ipairs(PZLinux.Poker.Config.lobbies) do
    local candidates, total = PZLinuxPokerGetLobbyAIEngines(lobby)
    assert(#candidates > 0, "lobby " .. lobby.id .. " must be able to fill a seat")
    assert(total > 0.99 and total < 1.01,
        string.format("lobby %s chances should sum to 1.0 for readability, got %.2f", lobby.id, total))

    local readers = 0
    for _, candidate in ipairs(candidates) do
        assert(PZLinuxPokerGetAI(candidate.id), "lobby " .. lobby.id .. " names an unregistered engine")
        -- One engine plays blind, another sees every hole card. Neither
        -- belongs at a table a player sits down at.
        assert(not candidate.engine.testOnly,
            "lobby " .. lobby.id .. " must never seat the TEST engine " .. candidate.id)
        if READING_ENGINES[candidate.id] then readers = readers + candidate.chance end
    end
    readerShare[lobby.id] = readers / total
end

-- Opposition that can actually punish a mistake must grow with the stakes.
assert(readerShare.micro < readerShare.low, "low must be tougher than micro")
assert(readerShare.low < readerShare.high, "high must be tougher than low")
assert(readerShare.high < readerShare.elite, "elite must be the toughest table")
assert(readerShare.micro == 0, "micro must contain no engine that punishes loose play")
assert(readerShare.elite == 1, "elite must be nothing but engines that punish")

-- Elite is brutal by construction: every seat is a maximum-skill reader with
-- no tell to read.
for _, entry in ipairs(PZLinuxPokerGetLobby("elite").aiEngines) do
    assert(entry.params and entry.params.skill == 5,
        "every elite seat must be a top-skill engine, " .. entry.id .. " is not")
    assert((entry.params.sizingTell or 0) == 0,
        "elite seats must not hand the player a tell")
end

-- The readable seat at high stakes: strong play, but its bet size leaks.
local tellSeats = 0
for _, entry in ipairs(PZLinuxPokerGetLobby("high").aiEngines) do
    if (entry.params or {}).sizingTell and entry.params.sizingTell > 0 then
        tellSeats = tellSeats + 1
        assert((entry.params.sizingError or 0) == 0,
            "a seat meant to be read must not blur its own tell with sizing jitter")
    end
end
assert(tellSeats == 1, "the high lobby must offer exactly one readable seat")

-- A lobby with no list of its own falls back to the shared default.
assert(PZLinuxPokerPickAIEngineId({ id = "unconfigured" }) == "zombiebrain",
    "a lobby with no aiEngines list must fall back to the default mix")

-- Registration rejects anything that cannot actually play.
assert(PZLinuxPokerRegisterAI(nil) == nil, "a nil engine must be rejected")
assert(PZLinuxPokerRegisterAI({ decide = function() end }) == nil, "an engine with no id must be rejected")
assert(PZLinuxPokerRegisterAI({ id = "broken" }) == nil, "an engine with no decide function must be rejected")
assert(PZLinuxPokerGetAI("broken") == nil, "a rejected engine must not enter the registry")

-- Every AI seat records the engine driving it, and engines get a chance to
-- set up their own per-seat state.
PZLinux.Poker.Sessions = {}
local player = {}
local snapshot = PZLinuxPokerCreateSession(player, "micro", 150, "registry-start")
assert(snapshot.ok, "the table must open")
local session = PZLinuxPokerGetSession(player)
local microEngines = {}
for _, entry in ipairs(PZLinuxPokerGetLobby("micro").aiEngines) do microEngines[entry.id] = true end
for index = 2, #session.seats do
    local seat = session.seats[index]
    assert(microEngines[seat.aiEngine],
        "seat " .. index .. " must record an engine the lobby actually offers, got " ..
        tostring(seat.aiEngine))
    -- Every seat carries a skill level whether or not its engine uses one:
    -- the field predates the registry and existing tools read it.
    assert(seat.difficulty >= 1 and seat.difficulty <= 5,
        "every seat must carry a skill level in 1..5, got " .. tostring(seat.difficulty))
end
assert(snapshot.seats[2].aiEngine == nil, "the engine driving a seat must stay server-side")

-- A second engine, mixed in per lobby. Chances are normalised by their sum,
-- so 0.5/0.5 really does split roughly evenly rather than depending on the
-- author keeping the total at exactly 1.0.
local seenCoinFlip = { zombiebrain = 0, coinflip = 0 }
PZLinuxPokerRegisterAI({
    id = "coinflip",
    name = "Coin Flip",
    createSeat = function(_, seat) seat.coinFlipSeat = true end,
    decide = function(_, context)
        if context.toCall > 0 and context.random(2) == 0 then return { action = "fold" } end
        return { action = "call" }
    end,
})
local mixedLobby = {
    id = "mixed", smallBlind = 1, bigBlind = 2,
    aiEngines = { { id = "zombiebrain", chance = 0.5 }, { id = "coinflip", chance = 0.5 } },
}
for _ = 1, 4000 do
    seenCoinFlip[PZLinuxPokerPickAIEngineId(mixedLobby)] = seenCoinFlip[PZLinuxPokerPickAIEngineId(mixedLobby)] + 1
end
assert(seenCoinFlip.zombiebrain > 1200 and seenCoinFlip.coinflip > 1200,
    string.format("a 0.5/0.5 mix must seat both engines, got %d/%d",
        seenCoinFlip.zombiebrain, seenCoinFlip.coinflip))

-- A chance of 0.0 means the engine is listed but never seated, and an
-- engine id nobody registered is skipped instead of breaking the lobby.
local zeroLobby = {
    id = "zero", smallBlind = 1, bigBlind = 2,
    aiEngines = {
        { id = "zombiebrain", chance = 1.0 },
        { id = "coinflip", chance = 0.0 },
        { id = "engine-from-a-mod-that-was-uninstalled", chance = 5.0 },
    },
}
for _ = 1, 200 do
    assert(PZLinuxPokerPickAIEngineId(zeroLobby) == "zombiebrain",
        "a 0.0 chance and an unregistered id must never be seated")
end

-- An engine that returns nonsense must not be able to damage the table.
-- The applier is the only code that touches chips, so a raise far larger
-- than the stack is clamped to an all-in rather than conjuring the
-- difference, and the table's chips still add up once the hand is paid out.
PZLinuxPokerRegisterAI({
    id = "cheater",
    decide = function(_, context)
        if context.toCall > 0 then return { action = "raise", amount = 999999999 } end
        return { action = "raise", amount = 999999999 }
    end,
})
PZLinux.Poker.Sessions = {}
local cheatPlayer = {}
assert(PZLinuxPokerCreateSession(cheatPlayer, "micro", 150, "cheat-start").ok, "the clamp table must open")
local cheatSession = PZLinuxPokerGetSession(cheatPlayer)

-- Chips in play: what a seat still holds plus what it has pushed in. Note
-- that committed is only cleared by the next deal, so once a hand is paid
-- out the stacks alone hold every chip at the table.
local function cheatTableChips(includeCommitted)
    local total = 0
    for _, seat in ipairs(cheatSession.seats) do
        total = total + seat.stack + (includeCommitted and (seat.committed or 0) or 0)
    end
    return total
end

local chipsBefore = cheatTableChips(true)
for index = 2, #cheatSession.seats do
    cheatSession.seats[index].aiEngine = "cheater"
end
-- The player folds, so the hand plays out purely between engines and the
-- session is never settled out from under the assertions below.
local cheatResult = PZLinuxPokerAction(cheatPlayer, "fold", 0, cheatSession.sessionId, "cheat-fold")
assert(cheatResult.phase == "hand_complete", "the shove-everything hand must finish, got " .. tostring(cheatResult.phase))

local sawAllIn = false
for index = 2, #cheatSession.seats do
    local seat = cheatSession.seats[index]
    assert(seat.stack >= 0, "no engine may drive a stack negative")
    if seat.committed > 0 and seat.stack == 0 then sawAllIn = true end
end
assert(sawAllIn, "a raise beyond the stack must be clamped to an all-in, not refused")
assert(cheatTableChips(false) == chipsBefore,
    string.format("chips must never be created at the table, %d became %d",
        chipsBefore, cheatTableChips(false)))

-- Folding costs nothing to a player who is owed nothing, so an engine that
-- asks to fold with no bet in front of it is checked instead. Otherwise a
-- careless engine throws away live hands -- and the pots attached to them --
-- for free.
PZLinuxPokerRegisterAI({ id = "alwaysfold", decide = function() return { action = "fold" } end })
PZLinux.Poker.Sessions = {}
local freePlayer = {}
assert(PZLinuxPokerCreateSession(freePlayer, "micro", 150, "free-start").ok, "the free-fold table must open")
local freeSession = PZLinuxPokerGetSession(freePlayer)

-- Hand-built rather than fished for with a seed: the flop, nothing owed,
-- and the player first to act.
for _ = 1, 3 do table.insert(freeSession.community, PZLinuxPokerDraw(freeSession.deck)) end
freeSession.phase = "flop"
freeSession.currentBet = 0
freeSession.minRaise = freeSession.bigBlind
for index, seat in ipairs(freeSession.seats) do
    seat.bet = 0
    seat.acted = false
    seat.folded = false
    seat.allIn = false
    seat.inHand = true
    seat.state = "active"
    if index > 1 then seat.aiEngine = "alwaysfold" end
end
freeSession.turn = 1
freeSession.awaitingPlayer = true
PZLinuxPokerAction(freePlayer, "check", 0, freeSession.sessionId, "free-check")
for index = 2, #freeSession.seats do
    local seat = freeSession.seats[index]
    assert(not seat.folded, "seat " .. index .. " must not fold a hand it can see for free")
    assert(seat.lastAction == "CHECK",
        "seat " .. index .. " must check instead, got " .. tostring(seat.lastAction))
end

-- A seat whose engine vanished mid-session (its mod was uninstalled) must
-- keep playing on the fallback rather than freezing the table.
PZLinux.Poker.Sessions = {}
local orphanPlayer = {}
assert(PZLinuxPokerCreateSession(orphanPlayer, "micro", 150, "orphan-start").ok, "the fallback table must open")
local orphanSession = PZLinuxPokerGetSession(orphanPlayer)
for index = 2, #orphanSession.seats do
    orphanSession.seats[index].aiEngine = "engine-from-a-mod-that-was-uninstalled"
end
local orphanResult = PZLinuxPokerAction(orphanPlayer, "fold", 0, orphanSession.sessionId, "orphan-fold")
assert(orphanResult.phase == "hand_complete",
    "seats with a missing engine must finish the hand on the fallback, got " .. tostring(orphanResult.phase))

-- Declared defaults. A lobby that names no params, half of them, or one with
-- the wrong type must still seat a working opponent: before this existed,
-- bluffChance = 5 and difficultyWeights = "hard" both crashed the AI turn
-- outright, and a typo'd key silently did nothing at all.
PZLinuxPokerRegisterAI({
    id = "defaulter",
    defaults = { aggression = 0.5, weights = { 1, 2, 3 }, label = "calm" },
    decide = function(_, context) return { action = "call" } end,
})
local defaulter = PZLinuxPokerGetAI("defaulter")

local resolvedNil = PZLinuxPokerResolveEngineParams(defaulter, nil)
assert(resolvedNil.aggression == 0.5 and resolvedNil.label == "calm",
    "params that are absent entirely must fall back to the engine's defaults")
assert(resolvedNil.weights[2] == 2, "nested default tables must come through")

local resolvedPartial = PZLinuxPokerResolveEngineParams(defaulter, { aggression = 0.9 })
assert(resolvedPartial.aggression == 0.9, "a named param must win over the default")
assert(resolvedPartial.label == "calm", "params left unnamed must keep their default")

local resolvedBadType = PZLinuxPokerResolveEngineParams(defaulter, { aggression = "high", weights = 7 })
assert(resolvedBadType.aggression == 0.5, "a wrongly typed param must fall back to its default")
assert(resolvedBadType.weights[3] == 3, "a wrongly typed table param must fall back too")

local resolvedTypo = PZLinuxPokerResolveEngineParams(defaulter, { agression = 0.9 })
assert(resolvedTypo.agression == nil, "a param the engine never declared must be dropped")
assert(resolvedTypo.aggression == 0.5, "a typo must not quietly override the real key")

assert(PZLinuxPokerResolveEngineParams(defaulter, "nonsense").aggression == 0.5,
    "params that are not even a table must fall back wholesale")

-- Defaults are deep copied out, so one seat's resolution cannot poison the
-- next seat's.
local firstResolve = PZLinuxPokerResolveEngineParams(defaulter, nil)
firstResolve.weights[1] = 99
assert(PZLinuxPokerResolveEngineParams(defaulter, nil).weights[1] == 1,
    "resolving params must not mutate the engine's declared defaults")

-- An engine that declares nothing keeps the old pass-through behaviour.
PZLinuxPokerRegisterAI({ id = "schemaless", decide = function() return { action = "call" } end })
local passthrough = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI("schemaless"), { anything = 1 })
assert(passthrough.anything == 1, "an engine with no declared defaults must keep its params untouched")

-- End to end: the exact malformed configs that used to crash an AI turn.
local badConfigs = {
    { bluffChance = 5 },
    { difficultyWeights = "hard" },
    { difficultyWeights = {} },
    { difficultyWeights = { 1, 1 } },
    { difficutlyWeights = { 0, 0, 0, 0, 100 } },
}
local savedMicroEngines = PZLinux.Poker.Config.lobbies[1].aiEngines
for caseIndex, badParams in ipairs(badConfigs) do
    PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = "zombiebrain", chance = 1.0, params = badParams } }
    PZLinux.Poker.Sessions = {}
    local badPlayer = {}
    local opened = PZLinuxPokerCreateSession(badPlayer, "micro", 150, "bad-" .. caseIndex)
    assert(opened.ok, "malformed params must not stop a table opening, case " .. caseIndex)
    local badSession = PZLinuxPokerGetSession(badPlayer)
    for index = 2, #badSession.seats do
        local difficulty = badSession.seats[index].difficulty
        assert(difficulty >= 1 and difficulty <= 5,
            "case " .. caseIndex .. " seat " .. index .. " got skill " .. tostring(difficulty))
    end
    -- And the hand plays, rather than erroring on the first AI turn.
    PZLinuxPokerAction(badPlayer, "fold", 0, badSession.sessionId, "bad-fold-" .. caseIndex)
end
PZLinux.Poker.Config.lobbies[1].aiEngines = savedMicroEngines

-- Relative weights: a list that does not sum to 100 still distributes across
-- exactly the levels it names.
local twoLevel = { difficultyWeights = { 1, 1 } }
local seen = {}
for _ = 1, 500 do
    local seat = {}
    PZLinuxPokerGetAI("zombiebrain"):createSeat(seat, nil, {
        params = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI("zombiebrain"), twoLevel),
        random = function(maxExclusive) return ZombRand(maxExclusive) end,
    })
    seen[seat.difficulty] = true
end
assert(seen[1] and seen[2], "weights { 1, 1 } must seat both level 1 and level 2")
assert(not seen[3] and not seen[4] and not seen[5],
    "weights { 1, 1 } must never seat a level the list does not name")

-- Engines are handed a copy of the table, never the table itself. Lua passes
-- tables by reference, so without this an engine could mint chips into its own
-- stack, deal itself aces, or rewrite the board -- and still return a
-- perfectly legal action for the applier to wave through, because the damage
-- happens before the return. Seeing everything stays deliberate; changing it
-- must not be possible.
local villainSaw = {}
PZLinuxPokerRegisterAI({
    id = "villain",
    decide = function(_, context)
        local session = context.session
        context.seat.stack = context.seat.stack + 5000
        -- Sentinel labels no real deck can produce, so the assertions below
        -- hold no matter which street the hand reached.
        context.seat.cards[1] = { rank = "A", suit = "S", value = 14, label = "XX" }
        context.seat.cards[2] = { rank = "A", suit = "H", value = 14, label = "XX" }
        session.community[1] = { rank = "A", suit = "D", value = 14, label = "XX" }
        session.seats[1].stack = 0
        villainSaw.deck = session.deck
        villainSaw.humanCards = session.seats[1].cards[1] and session.seats[1].cards[1].label or nil
        villainSaw.memory = context.memory
        context.memory.turns = (context.memory.turns or 0) + 1
        return { action = "call" }
    end,
})

PZLinux.Poker.Sessions = {}
local villainPlayer = {}
assert(PZLinuxPokerCreateSession(villainPlayer, "micro", 150, "villain-start").ok, "the villain table must open")
local villainSession = PZLinuxPokerGetSession(villainPlayer)
local villainChipsBefore = 0
for index, seat in ipairs(villainSession.seats) do
    villainChipsBefore = villainChipsBefore + seat.stack + (seat.committed or 0)
    if index > 1 then seat.aiEngine = "villain" end
end
local humanStackBefore = villainSession.seats[1].stack

PZLinuxPokerAction(villainPlayer, "fold", 0, villainSession.sessionId, "villain-fold")

local villainChipsAfter = 0
for _, seat in ipairs(villainSession.seats) do villainChipsAfter = villainChipsAfter + seat.stack end
assert(villainChipsAfter == villainChipsBefore,
    string.format("an engine must not mint chips, %d became %d", villainChipsBefore, villainChipsAfter))
local function villainForgedCards(session)
    for _, seat in ipairs(session.seats) do
        for _, card in ipairs(seat.cards or {}) do
            if card.label == "XX" then return true end
        end
    end
    for _, card in ipairs(session.community or {}) do
        if card.label == "XX" then return true end
    end
    return false
end
assert(not villainForgedCards(villainSession),
    "an engine must not deal itself new cards or rewrite the board")
assert(villainSession.seats[1].stack == humanStackBefore or villainSession.seats[1].folded,
    "an engine must not reach into the human's stack")

-- Peeking stays a feature: a shady bot is in keeping with the mod. Reading
-- the undealt deck is not peeking, it is knowing every future card, so the
-- view withholds it.
assert(villainSaw.humanCards ~= nil, "engines may still read opponents' hole cards")
assert(villainSaw.deck == nil, "engines must not see the undealt deck")

-- context.memory is the sanctioned writable surface, and it persists.
assert(type(villainSaw.memory) == "table", "engines must get a scratch memory table")
assert((villainSession.seats[2].aiMemory or {}).turns and villainSession.seats[2].aiMemory.turns > 0,
    "writes to context.memory must survive the decision")

-- The view itself: everything an engine needs to reason, and no deck.
local viewSession = PZLinuxPokerGetSession(villainPlayer)
local view = PZLinuxPokerBuildEngineView(viewSession)
assert(view.deck == nil, "the engine view must never carry the deck")
assert(#view.seats == #viewSession.seats, "the engine view must show every seat")
view.seats[2].stack = -1
assert(viewSession.seats[2].stack ~= -1, "the engine view must be a copy, not the live table")

-- ZombieBrain's own skill spread still has to rise across the brackets that
-- still seat it, since that is what its difficultyWeights params are for.
local function averageSkill(lobbyId, samples)
    local lobby = PZLinuxPokerGetLobby(lobbyId)
    local entry
    for _, candidate in ipairs(lobby.aiEngines) do
        if candidate.id == "zombiebrain" then entry = candidate end
    end
    if not entry then return nil end
    local engine = PZLinuxPokerGetAI("zombiebrain")
    local total = 0
    for _ = 1, samples do
        local seat = {}
        engine:createSeat(seat, lobby, {
            params = PZLinuxPokerResolveEngineParams(engine, entry.params),
            random = function(maxExclusive) return ZombRand(maxExclusive) end,
        })
        total = total + seat.difficulty
    end
    return total / samples
end

local microSkill = averageSkill("micro", 3000)
local lowSkill = averageSkill("low", 3000)
assert(microSkill and lowSkill, "micro and low must still seat ZombieBrain")
assert(microSkill < lowSkill,
    string.format("ZombieBrain must be weaker at micro than at low, got %.2f vs %.2f",
        microSkill, lowSkill))

print(string.format("  ZombieBrain average skill: micro %.2f, low %.2f", microSkill, lowSkill))
print("PZLinux poker AI registry tests OK")
