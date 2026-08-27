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

print("PZLinux poker AI registry tests OK")
