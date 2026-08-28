-- TEST_Cheater: a test instrument, not an opponent.
--
-- It looks at everyone's hole cards, which the engine view permits, and uses
-- them to answer one question exactly: given every hand at this table, how
-- often does mine win? It then calls when that beats the price and folds when
-- it does not. It never bets and never raises, so it can only ever win money
-- other engines chose to put in.
--
-- On the river there is nothing left to deal, so its answer is not an estimate
-- at all -- it knows whether it wins, and its call/fold is provably correct.
-- Earlier streets it enumerates or samples the remaining board against known
-- hands, which is still strictly better information than any honest engine can
-- have.
--
-- Why it exists: it is the ceiling. A passive player who never puts in a chip
-- voluntarily and only ever makes correct calls is the most a pure calling
-- strategy can win against a given table. Any honest engine that outruns it is
-- winning through betting and fold equity rather than card reading, and any
-- honest engine well below it is leaving money in bad calls. That makes it a
-- yardstick no amount of tuning can move.
--
-- Not for a live lobby: it sees hole cards. The mod's shady bots are a
-- deliberate flavour choice made per lobby -- this one is a measuring device.

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}
PZLinux.Poker.AI = PZLinux.Poker.AI or {}
PZLinux.Poker.AI.Engines = PZLinux.Poker.AI.Engines or {}

local Cheater = {
    id = "test_cheater",
    name = "TEST_Cheater",
    testOnly = true,
}

-- Params, all optional:
--
--   samples      board run-outs to try when cards are still to come. The
--                river needs none, so this only costs anything earlier
--   callMargin   percentage points of edge over the price it insists on;
--                zero is the mathematically correct threshold
function Cheater:defaults()
    return {
        samples = 200,
        callMargin = 0,
    }
end

-- Everything this table can still produce: a full deck minus every card the
-- cheater can see, which -- since it can see all of them -- is exactly the
-- set of cards still to come.
local function CheaterUnseenCards(session, seats)
    local seen = {}
    for _, card in ipairs(session.community or {}) do seen[card.label] = true end
    for _, seat in ipairs(seats) do
        for _, card in ipairs(seat.cards or {}) do seen[card.label] = true end
    end
    local unseen = {}
    for _, card in ipairs(PZLinuxPokerCreateOrderedDeck()) do
        if not seen[card.label] then table.insert(unseen, card) end
    end
    return unseen
end

local function CheaterHandValue(holeCards, board)
    local cards = {}
    for _, card in ipairs(holeCards) do table.insert(cards, card) end
    for _, card in ipairs(board) do table.insert(cards, card) end
    return PZLinuxPokerEvaluateHand(cards)
end

-- Share of the pot this seat wins against known hands over a given board:
-- 1 for a clean win, 1/n in an n-way tie, 0 when beaten.
local function CheaterShareOnBoard(context, opponents, board)
    local mine = CheaterHandValue(context.seat.cards, board)
    local tied = 1
    for _, opponent in ipairs(opponents) do
        local theirs = CheaterHandValue(opponent.cards, board)
        local comparison = PZLinuxPokerCompareHands(theirs, mine)
        if comparison > 0 then return 0 end
        if comparison == 0 then tied = tied + 1 end
    end
    return 1 / tied
end

function Cheater:decide(context)
    local session = context.session

    local opponents = {}
    for index, seat in ipairs(session.seats or {}) do
        if index ~= context.seatIndex and seat.inHand and not seat.folded and #(seat.cards or {}) == 2 then
            table.insert(opponents, seat)
        end
    end

    -- Nobody left to beat, or no hand to reason about: never fold for free,
    -- never pay to find out.
    if #opponents == 0 or #(context.seat.cards or {}) ~= 2 then
        return context.toCall > 0 and { action = "fold" } or { action = "check" }
    end

    local board = {}
    for _, card in ipairs(session.community or {}) do table.insert(board, card) end
    local missing = 5 - #board

    local share
    if missing <= 0 then
        -- The river. No estimate involved -- this is the answer.
        share = CheaterShareOnBoard(context, opponents, board)
    else
        -- Every seat's cards, this one's included, so the unseen set is
        -- genuinely only what is still to come.
        local known = { context.seat }
        for _, opponent in ipairs(opponents) do table.insert(known, opponent) end
        local unseen = CheaterUnseenCards(session, known)

        if missing == 1 then
            -- One card to come is small enough to enumerate, so the turn gets
            -- the same exactness as the river rather than a sample of it.
            local total = 0
            for _, card in ipairs(unseen) do
                local runout = { card }
                for _, boardCard in ipairs(board) do table.insert(runout, boardCard) end
                total = total + CheaterShareOnBoard(context, opponents, runout)
            end
            share = total / #unseen
        else
            local samples = math.max(1, math.floor(context.params.samples or 200))
            local total = 0
            for _ = 1, samples do
                local drawn = {}
                local used = {}
                for _ = 1, missing do
                    local pick
                    repeat
                        pick = context.random(#unseen) + 1
                    until not used[pick]
                    used[pick] = true
                    table.insert(drawn, unseen[pick])
                end
                for _, boardCard in ipairs(board) do table.insert(drawn, boardCard) end
                total = total + CheaterShareOnBoard(context, opponents, drawn)
            end
            share = total / samples
        end
    end

    if context.toCall <= 0 then
        -- It never bets, so a free card is always taken.
        return { action = "check" }
    end

    local equityPercent = share * 100
    local pricePercent = context.potOdds * 100 + (context.params.callMargin or 0)
    if equityPercent >= pricePercent then
        return { action = "call" }
    end
    return { action = "fold" }
end

if PZLinuxPokerRegisterAI then
    PZLinuxPokerRegisterAI(Cheater)
else
    PZLinux.Poker.AI.Engines[Cheater.id] = Cheater
end
