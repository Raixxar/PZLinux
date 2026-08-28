-- Round-robin rating tournament for the poker AI engines.
--
-- Two numbers come out of this, because poker needs both.
--
-- bb/100 -- big blinds won per 100 hands -- is what cash-game professionals
-- actually use to measure a player, and it is the honest primary metric here:
-- it says by how much one engine beats another, not merely that it does. It is
-- reported with a standard error, because a bb/100 figure without one is
-- close to meaningless at these sample sizes.
--
-- TrueSkill is the secondary number: one comparable scalar for the ordering.
-- It is used rather than Elo because Elo was built for two-player win/lose
-- games, and forcing a five-way table into it means decomposing every table
-- into pairs and updating each independently -- which double-counts the
-- evidence and can never say how sure it is. TrueSkill takes the whole
-- finishing order at once and carries its own uncertainty, so the table can
-- report the conservative mu - 3*sigma: the skill the evidence supports
-- rather than the skill the point estimate flatters.
--
-- Both numbers are still needed. TrueSkill ranks on finishing order and
-- discards margin, so it says who beats whom; bb/100 says by how much. An
-- engine that wins small pots constantly and one that wins rarely but huge
-- can rate identically on the first and differ wildly on the second.
--
-- Variance is the real enemy. A single hand swings hundreds of big blinds on
-- card luck alone, which is why poker AI research leans on duplicate matches:
-- deal the identical cards to every lineup and rotate who sits where, so the
-- luck cancels and only the decisions differ. This runs that scheme --
-- PZLinuxPokerCreateDeck is replaced with a pre-generated deck book drawn
-- from its own random stream, and each table is replayed once per seat
-- rotation with the identical book. Every engine therefore holds every hand
-- from every position.
--
-- Usage:
--   lua tools/poker_tournament.lua [rounds] [hands] [seed] [samples]

math.randomseed(20260827)

ZombRand = function(a, b)
    if b then return math.random(a, b - 1) end
    return math.random(0, a - 1)
end

PZLinuxGetPlayer = function(player) return player end
PZLinuxGetPlayerKey = function() return "tournament" end
PZLinuxNormalizeMoney = function(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
PZLinuxLoadBankBalance = function() return 100000000 end
PZLinuxApplyBankDebit = function(_, amount) return { ok = true, amount = amount, balance = 100000000 } end
PZLinuxApplyBankCredit = function(_, amount) return { ok = true, amount = amount, balance = 100000000 } end
PZLinuxNextRequestId = function(prefix) return tostring(prefix) .. "-1" end
PZLinuxRegisterInterruptedSession = function() end
PZLinuxClearInterruptedSession = function() end

local report = print
print = function() end

dofile("tools/poker_trueskill.lua")

local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"
for _, file in ipairs({
    "PZLinuxPokerAIRegistry", "PZLinuxPokerConfig", "PZLinuxPokerAISkill",
    "PZLinuxPokerAIReads", "PZLinuxPokerAIZombieBrain", "PZLinuxPokerAIDrunkard",
    "PZLinuxPokerAISurvivor", "PZLinuxPokerAIShark",
    "PZLinuxPokerAITestZombieHunter", "PZLinuxPokerAITestCheater",
    "PZLinuxPokerEngine",
}) do
    dofile(luaRoot .. "/shared/PZLinux/" .. file .. ".lua")
end

local ROUNDS = tonumber(arg[1]) or 12
local HANDS = tonumber(arg[2]) or 200
local SEED = tonumber(arg[3]) or 1
local SAMPLES = tonumber(arg[4]) or 30
local SEATS = 5
-- 100 big blinds, the standard cash-game buy-in. Deeper stacks make bb/100
-- meaningless: at 2000bb deep a single pot can be worth thousands of bb/100
-- and the metric stops describing a win rate at all.
local START_STACK = 100 * (PZLinuxPokerGetLobby("micro").bigBlind)

-- The field. Engines with skill knobs enter at several levels, so the ladder
-- is rated rather than assumed. The TEST engines are entered too -- one plays
-- blind, one sees every card -- as the floor and ceiling to measure against.
-- The default field is everything. "competent" drops the engines that cannot
-- punish a mistake -- ZombieBrain, the Drunkard and the blind TEST_hunter --
-- because a field full of them rewards loose aggression and inverts the skill
-- ladder. Rating an engine only means something relative to who it played.
local FIELD_NAME = arg[5] or "all"
local FIELD_ALL = {
    { key = "zombiebrain",   engine = "zombiebrain", params = {} },
    { key = "drunkard",      engine = "drunkard",    params = {} },
    { key = "survivor_s1",   engine = "survivor",    params = { skill = 1 } },
    { key = "survivor_s3",   engine = "survivor",    params = { skill = 3 } },
    { key = "survivor_s5",   engine = "survivor",    params = { skill = 5 } },
    { key = "shark_s1",      engine = "shark",       params = { skill = 1 } },
    { key = "shark_s3",      engine = "shark",       params = { skill = 3 } },
    { key = "shark_s5",      engine = "shark",       params = { skill = 5 } },
    { key = "TEST_cheater",  engine = "test_cheater",      params = {} },
    { key = "TEST_hunter",   engine = "test_zombiehunter", params = {} },
}

local FIELD = {}
for _, entry in ipairs(FIELD_ALL) do
    local exploitable = entry.key == "zombiebrain" or entry.key == "drunkard" or entry.key == "TEST_hunter"
    if FIELD_NAME ~= "competent" or not exploitable then
        FIELD[#FIELD + 1] = entry
    end
end

-- A random stream of its own, so the cards a table sees never depend on how
-- much randomness the engines happened to consume. Without this, duplicate
-- dealing is impossible: change a decision and every later card changes with
-- it, which is exactly the luck this is trying to cancel.
local function DeckRandom(seed)
    local state = seed % 2147483647
    if state <= 0 then state = state + 2147483646 end
    return function(maxExclusive)
        state = (state * 48271) % 2147483647
        return state % maxExclusive
    end
end

-- One shuffled deck per hand, generated up front and replayed for every seat
-- rotation of the same round.
local function BuildDeckBook(seed, hands)
    local random = DeckRandom(seed)
    local book = {}
    for handIndex = 1, hands + 2 do
        local deck = PZLinuxPokerCreateOrderedDeck()
        for index = #deck, 2, -1 do
            local swap = random(index) + 1
            deck[index], deck[swap] = deck[swap], deck[index]
        end
        book[handIndex] = deck
    end
    return book
end

local deckBook, deckCursor = nil, 0
local realCreateDeck = PZLinuxPokerCreateDeck
PZLinuxPokerCreateDeck = function()
    if not deckBook then return realCreateDeck() end
    deckCursor = deckCursor + 1
    local source = deckBook[deckCursor] or deckBook[#deckBook]
    local copy = {}
    for index, card in ipairs(source) do copy[index] = card end
    return copy
end

-- Plays one table to completion and returns net chips per seat, in the order
-- the lineup was given. Seat 1 is the human chair: it folds and pays blinds,
-- so it neither feeds the table nor competes with it.
local function playTable(lineup, book, rngSeed)
    deckBook, deckCursor = book, 0
    math.randomseed(rngSeed)

    PZLinux.Poker.Sessions = {}
    local player = {}
    local opened = PZLinuxPokerCreateSession(player, "micro", 200, "tournament")
    if not opened.ok then return nil end
    local session = PZLinuxPokerGetSession(player)

    session.seats[1].stack = START_STACK
    for index, entry in ipairs(lineup) do
        local seat = session.seats[index + 1]
        local params = { equitySamples = SAMPLES }
        for key, value in pairs(entry.params) do params[key] = value end
        seat.aiEngine = entry.engine
        seat.aiParams = PZLinuxPokerResolveEngineParams(PZLinuxPokerGetAI(entry.engine), params)
        seat.aiMemory = nil
        seat.stack = START_STACK
        local engine = PZLinuxPokerGetAI(entry.engine)
        if engine.createSeat then
            engine:createSeat(seat, nil, { params = seat.aiParams, random = ZombRand, randomRange = ZombRand })
        end
    end

    local invested = {}
    for index = 1, #lineup do invested[index] = START_STACK end

    local hands = 0
    PZLinuxPokerStartHand(session)

    -- Signature of the opening deal by seat, used to prove that a rotation
    -- really did see the same cards rather than merely being told it would.
    local firstDeal = {}
    for index = 1, #session.seats do
        local cards = session.seats[index].cards or {}
        firstDeal[index] = (cards[1] and cards[1].label or "?") .. (cards[2] and cards[2].label or "?")
    end
    firstDeal = table.concat(firstDeal, ",")
    local guard = 0
    while hands < HANDS and guard < HANDS * 40 do
        guard = guard + 1
        if session.phase == "hand_complete" or session.phase == "finished" then
            hands = hands + 1
            session.seats[1].stack = START_STACK
            for index, seat in ipairs(session.seats) do
                seat.eliminated = false
                if index > 1 and seat.stack <= 0 then
                    -- A busted engine rebuys, and the rebuy is charged to it.
                    seat.stack = START_STACK
                    invested[index - 1] = invested[index - 1] + START_STACK
                end
            end
            session.status = "active"
            PZLinux.Poker.Sessions[session.playerKey] = session
            session.phase = "hand_complete"
            PZLinuxPokerStartHand(session)
        elseif session.awaitingPlayer then
            local legal = PZLinuxPokerBuildSnapshot(session).legalActions or {}
            PZLinuxPokerAction(player, legal.check and "check" or "fold", 0, session.sessionId, "seat1")
        else
            break
        end
    end

    local net = {}
    for index = 1, #lineup do
        net[index] = session.seats[index + 1].stack - invested[index]
    end
    deckBook = nil
    return net, hands, firstDeal
end

-- ------------------------------------------------------------------ ratings

local stats = {}
for _, entry in ipairs(FIELD) do
    stats[entry.key] = { key = entry.key, hands = 0, chips = 0,
                         rating = PZLinuxTrueSkillNew(),
                         tables = 0, bbSamples = {}, wins = 0, losses = 0, ties = 0 }
end

local BIG_BLIND = PZLinuxPokerGetLobby("micro").bigBlind

-- One TrueSkill update per table, taking the whole finishing order together.
-- The head-to-head tallies are kept alongside purely for reading the results;
-- nothing is rated from them.
local function applyTableResult(keys, net)
    local ratings, ranks = {}, {}
    local order = {}
    for index = 1, #keys do order[index] = index end
    table.sort(order, function(a, b) return net[a] > net[b] end)

    -- Equal chip counts share a rank, which TrueSkill treats as a draw.
    local rankOf = {}
    local position = 0
    for listIndex, seatIndex in ipairs(order) do
        if listIndex == 1 or net[seatIndex] < net[order[listIndex - 1]] then
            position = listIndex
        end
        rankOf[seatIndex] = position
    end

    for index = 1, #keys do
        ratings[index] = stats[keys[index]].rating
        ranks[index] = rankOf[index]
    end
    PZLinuxTrueSkillRate(ratings, ranks)

    for i = 1, #keys do
        for j = i + 1, #keys do
            local a, b = stats[keys[i]], stats[keys[j]]
            if net[i] > net[j] then a.wins = a.wins + 1 b.losses = b.losses + 1
            elseif net[i] < net[j] then a.losses = a.losses + 1 b.wins = b.wins + 1
            else a.ties = a.ties + 1 b.ties = b.ties + 1 end
        end
    end
end

-- ---------------------------------------------------------------- the event

local pick = DeckRandom(SEED * 7919 + 13)

-- The five least-played engines, shuffled first so ties do not always break
-- the same way. A blind random draw leaves some engines with a third of the
-- hands of others, and their standard errors show it.
local function chooseLineup()
    local pool = {}
    for _, entry in ipairs(FIELD) do pool[#pool + 1] = entry end
    for index = #pool, 2, -1 do
        local swap = pick(index) + 1
        pool[index], pool[swap] = pool[swap], pool[index]
    end
    table.sort(pool, function(a, b) return stats[a.key].tables < stats[b.key].tables end)
    local chosen = {}
    for index = 1, SEATS do chosen[index] = pool[index] end
    return chosen
end

report(string.format("PZLinux poker tournament: field=%s, %d rounds x %d seat rotations x %d hands, %d bb blinds",
    FIELD_NAME, ROUNDS, SEATS, HANDS, BIG_BLIND))
report("duplicate dealing on: every rotation of a round sees the identical cards")

local startClock = os.clock()
local duplicateBroken = 0
for round = 1, ROUNDS do
    local lineup = chooseLineup()
    local book = BuildDeckBook(SEED * 1000 + round, HANDS)
    local roundDeal = nil

    -- Duplicate: the same deals, played from every seat by every engine.
    for rotation = 0, SEATS - 1 do
        local rotated = {}
        for index = 1, SEATS do
            rotated[index] = lineup[((index - 1 + rotation) % SEATS) + 1]
        end
        local net, hands, dealSignature = playTable(rotated, book, SEED * 100000 + round * 100 + rotation)
        if roundDeal == nil then
            roundDeal = dealSignature
        elseif dealSignature ~= roundDeal then
            duplicateBroken = duplicateBroken + 1
        end
        if net then
            local keys = {}
            for index, entry in ipairs(rotated) do
                keys[index] = entry.key
                local stat = stats[entry.key]
                stat.hands = stat.hands + hands
                stat.chips = stat.chips + net[index]
                stat.tables = stat.tables + 1
                stat.bbSamples[#stat.bbSamples + 1] = net[index] / BIG_BLIND / hands * 100
            end
            applyTableResult(keys, net)
        end
    end
    report(string.format("  round %2d/%d done (%.0fs elapsed)", round, ROUNDS, os.clock() - startClock))
end

-- ----------------------------------------------------------------- results

local ranked = {}
for _, entry in ipairs(FIELD) do ranked[#ranked + 1] = stats[entry.key] end

for _, stat in ipairs(ranked) do
    stat.bb100 = stat.hands > 0 and (stat.chips / BIG_BLIND / stat.hands * 100) or 0
    local mean, count = 0, #stat.bbSamples
    for _, value in ipairs(stat.bbSamples) do mean = mean + value end
    mean = count > 0 and mean / count or 0
    local variance = 0
    for _, value in ipairs(stat.bbSamples) do variance = variance + (value - mean) ^ 2 end
    variance = count > 1 and variance / (count - 1) or 0
    stat.stderr = count > 0 and math.sqrt(variance / count) or 0
end

table.sort(ranked, function(a, b) return a.bb100 > b.bb100 end)

report("")
if duplicateBroken == 0 then
    report("duplicate dealing verified: every rotation of every round saw identical hole cards")
else
    report(string.format("WARNING: duplicate dealing broke in %d rotations -- results carry card luck",
        duplicateBroken))
end
report("")
report(string.format("%-14s %10s %9s %8s %7s %7s %7s %s",
    "engine", "bb/100", "stderr", "skill", "mu", "sigma", "tables", "W-L-T"))
for _, stat in ipairs(ranked) do
    report(string.format("%-14s %+10.2f %9.2f %8.2f %7.2f %7.2f %7d %d-%d-%d",
        stat.key, stat.bb100, stat.stderr,
        PZLinuxTrueSkillConservative(stat.rating), stat.rating.mu, stat.rating.sigma,
        stat.tables, stat.wins, stat.losses, stat.ties))
end

-- The same field ordered by what TrueSkill believes rather than by money.
local bySkill = {}
for _, stat in ipairs(ranked) do bySkill[#bySkill + 1] = stat end
table.sort(bySkill, function(a, b)
    return PZLinuxTrueSkillConservative(a.rating) > PZLinuxTrueSkillConservative(b.rating)
end)
report("")
report("ranked by TrueSkill (conservative mu - 3*sigma):")
for place, stat in ipairs(bySkill) do
    report(string.format("  %2d. %-14s skill %6.2f   bb/100 %+9.2f",
        place, stat.key, PZLinuxTrueSkillConservative(stat.rating), stat.bb100))
end
report("")
report(string.format("total %.0fs", os.clock() - startClock))
