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
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerAIZombieBrain.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxPokerEngine.lua")

-- The shipped engine registers itself at load time and is the fallback.
assert(PZLinuxPokerGetAI("zombiebrain"), "the Zombie Brain engine must register itself on load")
assert(PZLinuxPokerGetFallbackAI().id == "zombiebrain", "Zombie Brain must remain the fallback engine")

-- Every lobby is pure Zombie Brain today. If that ever changes by accident
-- rather than by design, the tables silently start playing differently.
for _, lobby in ipairs(PZLinux.Poker.Config.lobbies) do
    local candidates = PZLinuxPokerGetLobbyAIEngines(lobby)
    assert(#candidates == 1, "lobby " .. lobby.id .. " must list exactly one AI engine")
    assert(candidates[1].id == "zombiebrain", "lobby " .. lobby.id .. " must be seated with Zombie Brain")
    assert(candidates[1].chance == 1.0, "lobby " .. lobby.id .. " must seat Zombie Brain at chance 1.0")
    assert(PZLinuxPokerPickAIEngineId(lobby) == "zombiebrain", "lobby " .. lobby.id .. " must pick Zombie Brain")
end

-- Params ride along with the entry that won the draw, reach the engine as
-- context.params, and are copied per seat so that no engine can write back
-- into the shared lobby config.
local paramLobby = {
    id = "params", smallBlind = 1, bigBlind = 2,
    aiEngines = { { id = "zombiebrain", chance = 1.0,
                    params = { difficultyWeights = { 0, 0, 0, 0, 100 } } } },
}
local paramEntry = PZLinuxPokerPickAIEngineEntry(paramLobby)
assert(paramEntry.id == "zombiebrain", "the entry must name its engine")
assert(paramEntry.params.difficultyWeights[5] == 100, "the entry must carry its params")

local copied = PZLinuxPokerCopyEngineParams(paramLobby.aiEngines[1].params)
copied.difficultyWeights[5] = 1
assert(paramLobby.aiEngines[1].params.difficultyWeights[5] == 100,
    "writing to a seat's params must not reach the shared lobby config")

-- Same engine id, different params, different table personality. This is
-- the whole point: no second engine needed to seat stronger players.
PZLinux.Poker.Sessions = {}
local sharkPlayer = {}
PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = "zombiebrain", chance = 1.0,
    params = { difficultyWeights = { 0, 0, 0, 0, 100 } } } }
assert(PZLinuxPokerCreateSession(sharkPlayer, "micro", 150, "params-start").ok, "the params table must open")
local sharkSession = PZLinuxPokerGetSession(sharkPlayer)
for index = 2, #sharkSession.seats do
    assert(sharkSession.seats[index].difficulty == 5,
        "params must steer the skill roll, seat " .. index .. " got " ..
        tostring(sharkSession.seats[index].difficulty))
    assert(sharkSession.seats[index].aiParams.difficultyWeights[5] == 100,
        "each seat must keep its own copy of the params it was seated with")
end
sharkSession.seats[2].aiParams.difficultyWeights[5] = 1
assert(sharkSession.seats[3].aiParams.difficultyWeights[5] == 100,
    "one seat's params must not be shared with another seat")
PZLinux.Poker.Config.lobbies[1].aiEngines = { { id = "zombiebrain", chance = 1.0,
    params = { difficultyWeights = { 45, 30, 15, 7, 3 } } } }

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
for index = 2, #session.seats do
    local seat = session.seats[index]
    assert(seat.aiEngine == "zombiebrain", "seat " .. index .. " must record its engine id")
    assert(seat.difficulty >= 1 and seat.difficulty <= 5,
        "Zombie Brain must roll a skill level in 1..5, got " .. tostring(seat.difficulty))
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

-- The stakes ladder itself. Sitting down with more money must mean facing
-- better players -- the gap the modular engines were meant to close. Skill
-- is rolled, not assigned, so this samples rather than asserting a single
-- table.
local function averageSkill(lobbyId, samples)
    local lobby = PZLinuxPokerGetLobby(lobbyId)
    local total, count = 0, 0
    for _ = 1, samples do
        local seat = {}
        local entry = PZLinuxPokerPickAIEngineEntry(lobby)
        local engine = PZLinuxPokerGetAI(entry.id)
        engine:createSeat(seat, lobby, {
            params = PZLinuxPokerCopyEngineParams(entry.params),
            random = function(maxExclusive) return ZombRand(maxExclusive) end,
        })
        total = total + seat.difficulty
        count = count + 1
    end
    return total / count
end

local skill = {}
for _, lobbyId in ipairs({ "micro", "low", "high", "elite" }) do
    skill[lobbyId] = averageSkill(lobbyId, 3000)
end
assert(skill.micro < skill.low and skill.low < skill.high and skill.high < skill.elite,
    string.format("average opponent skill must rise with the stakes, got %.2f / %.2f / %.2f / %.2f",
        skill.micro, skill.low, skill.high, skill.elite))
assert(skill.elite - skill.micro > 1.0,
    string.format("the gap between micro and elite must be worth noticing, got %.2f",
        skill.elite - skill.micro))

print(string.format("  average opponent skill: micro %.2f, low %.2f, high %.2f, elite %.2f",
    skill.micro, skill.low, skill.high, skill.elite))
print("PZLinux poker AI registry tests OK")
