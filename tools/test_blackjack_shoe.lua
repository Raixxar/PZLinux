-- Regression test for the Blackjack shoe. Blackjack used to shuffle a brand
-- new 52-card deck for every single hand, which quietly made the game
-- unbeatable by skill: with the deck reset between hands, nothing a player
-- observes in one hand tells them anything about the next, so there is
-- nothing to count. Hands are now dealt from a persistent 1-3 deck shoe that
-- is dealt down to its last card before being reshuffled, which is the one
-- property card counting depends on -- so it is worth guarding, since a well-meaning "just deal a
-- fresh deck each hand" change would silently remove the whole feature while
-- leaving every other test passing.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_blackjack_shoe.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- Both files are engine-free on purpose, so the dealing and reshuffle rules
-- can be exercised for real here rather than only pattern-matched.
PZLinux = {}
dofile(luaRoot .. "/shared/PZLinux/PZLinuxConfig.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxBlackjackEngine.lua")

local config = PZLinux.Config.Blackjack

assert(config.deckMin == 1, "the shallowest table must still deal from a full single deck")
assert(config.deckMax == 3, "no table may deal from more than three decks, or the shoe stops being countable at all")
-- No cut card on purpose: the house pays from an infinite supply of in-game
-- currency, so there is nothing to protect by cutting a count short, and
-- dealing the shoe out completely is the deepest penetration possible.
assert(config.shoePenetration == nil,
    "the shoe must have no cut card, so a count stays good all the way to the last card")

-- Deck count is the difficulty dial: cheap tables stay countable, high-stakes
-- tables bury the count. It must never invert, or the biggest payouts would
-- also be the easiest ones to count.
local previousDecks = 0
for _, tableDef in ipairs(config.tables) do
    assert(tableDef.decks, "every Blackjack table must declare how many decks it deals from")
    assert(tableDef.decks >= config.deckMin and tableDef.decks <= config.deckMax,
        "a table's deck count must stay within the configured bounds")
    assert(tableDef.decks >= previousDecks,
        "higher-stakes tables must never deal from fewer decks than cheaper ones, " ..
        "or counting would be easiest exactly where it pays most")
    previousDecks = tableDef.decks
end

local microTable = assert(PZLinuxBlackjackGetTable("micro"))
local eliteTable = assert(PZLinuxBlackjackGetTable("elite"))

assert(PZLinuxBlackjackShoeDecksForTable(microTable) == 1, "the micro table deals single deck")
assert(PZLinuxBlackjackShoeDecksForTable(eliteTable) == 3, "the elite table deals a three-deck shoe")
assert(PZLinuxBlackjackShoeDecksForTable({ decks = 99 }) == config.deckMax,
    "a bad table definition must be clamped, never trusted")
assert(PZLinuxBlackjackShoeDecksForTable({ decks = 0 }) == config.deckMin,
    "a zero-deck table would deal nothing at all")
assert(PZLinuxBlackjackShoeDecksForTable(nil) == config.deckMin, "a missing table must still produce a dealable shoe")

local ranksPerDeck = #config.ranks * #config.suits
assert(ranksPerDeck == 52, "a deck is 52 cards")

local singleShoe = PZLinuxBlackjackShoeCreate(1, "micro")
assert(#singleShoe.cards == 52 and singleShoe.size == 52, "a one-deck shoe holds one full deck")
local tripleShoe = PZLinuxBlackjackShoeCreate(3, "elite")
assert(#tripleShoe.cards == 156 and tripleShoe.size == 156, "a three-deck shoe holds three full decks")

-- Composition, not just count: a three-deck shoe must contain exactly three
-- of every card, or the values a counter tracks would be wrong.
local occurrences = {}
while #tripleShoe.cards > 0 do
    local card = PZLinuxBlackjackShoeDraw(tripleShoe)
    local key = card.rank .. card.suit
    occurrences[key] = (occurrences[key] or 0) + 1
end
local distinct = 0
for key, count in pairs(occurrences) do
    assert(count == 3, "a three-deck shoe must hold exactly three of " .. key .. ", found " .. count)
    distinct = distinct + 1
end
assert(distinct == 52, "a shoe must hold every one of the 52 distinct cards")

-- Shuffling must actually reorder. Two independently shuffled 52-card decks
-- landing in the same order is astronomically unlikely, so an identical order
-- means the shuffle silently did nothing.
local firstOrder, secondOrder = {}, {}
for index, card in ipairs(PZLinuxBlackjackShoeCreate(1, "micro").cards) do firstOrder[index] = card.rank .. card.suit end
for index, card in ipairs(PZLinuxBlackjackShoeCreate(1, "micro").cards) do secondOrder[index] = card.rank .. card.suit end
local identical = true
for index = 1, #firstOrder do
    if firstOrder[index] ~= secondOrder[index] then identical = false break end
end
assert(not identical, "shuffling must reorder the shoe")

-- THE point of the whole change: cards dealt in one hand are still gone at
-- the start of the next one. If this reverts to a fresh deck per hand, the
-- remaining count resets to full here and counting means nothing.
PZLinux.Blackjack.Shoes = {}
local shoe = PZLinuxBlackjackShoeAcquire(microTable)
assert(shoe.shuffled, "the first hand dealt at a table opens a fresh shoe")
for _ = 1, 10 do PZLinuxBlackjackShoeDraw(shoe) end
assert(#shoe.cards == 42, "ten dealt cards must leave the shoe")

local sameShoe = PZLinuxBlackjackShoeAcquire(microTable)
assert(sameShoe == shoe, "the next hand must be dealt from the same shoe, not a new one")
assert(#sameShoe.cards == 42, "already-dealt cards must not come back between hands")
assert(sameShoe.shuffled == false, "a continuing shoe must not be reported as freshly shuffled")

-- A player who tracked every ace out of the shoe must genuinely be able to
-- rely on that: the rest of the shoe really does hold none.
PZLinux.Blackjack.Shoes = {}
local countedShoe = PZLinuxBlackjackShoeAcquire(microTable)
local acesSeen = 0
local drawn = {}
for index = #countedShoe.cards, 1, -1 do
    if countedShoe.cards[index].rank == "A" then
        table.insert(drawn, table.remove(countedShoe.cards, index))
        acesSeen = acesSeen + 1
    end
end
assert(acesSeen == 4, "a single deck holds four aces")
while #countedShoe.cards > 0 do
    assert(PZLinuxBlackjackShoeDraw(countedShoe).rank ~= "A",
        "once every ace has been dealt, no further ace may appear before the shoe is reshuffled")
end

-- The shoe stays in play until its very last card, and is only retired once
-- it is genuinely empty. Retiring it any earlier would throw away the part of
-- the shoe a count is worth the most in.
PZLinux.Blackjack.Shoes = {}
local deepShoe = PZLinuxBlackjackShoeAcquire(eliteTable)
while #deepShoe.cards > 0 do
    assert(not PZLinuxBlackjackShoeNeedsShuffle(deepShoe),
        "the shoe must keep dealing while it still holds cards, right down to the last one")
    PZLinuxBlackjackShoeDraw(deepShoe)
end
assert(PZLinuxBlackjackShoeNeedsShuffle(deepShoe), "an emptied shoe must be retired")

local reshuffled = PZLinuxBlackjackShoeAcquire(eliteTable)
assert(reshuffled.shuffled, "a reshuffle must be reported, so a player knows their count is now worthless")
assert(#reshuffled.cards == reshuffled.size and reshuffled.size == 156, "a retired shoe is replaced by a full one")
assert(reshuffled.cards == deepShoe.cards,
    "a refilled shoe must reuse its own cards table, or an in-progress hand would keep drawing from the retired shoe")

-- The shoe belongs to the table, not to the player. Every table keeps its own,
-- so moving between tables neither carries a count over nor destroys the one
-- left behind: coming back finds that table's shoe where the table has since
-- dealt it to.
PZLinux.Blackjack.Shoes = {}
local microShoe = PZLinuxBlackjackShoeAcquire(microTable)
for _ = 1, 5 do PZLinuxBlackjackShoeDraw(microShoe) end
local eliteShoe = PZLinuxBlackjackShoeAcquire(eliteTable)
assert(eliteShoe ~= microShoe, "each table must deal from its own shoe")
assert(#eliteShoe.cards == 156 and eliteShoe.shuffled,
    "a table dealt from for the first time opens a full, freshly shuffled shoe of its own deck count")
assert(#microShoe.cards == 47, "playing another table must not disturb the shoe left behind")
assert(PZLinuxBlackjackShoeAcquire(microTable) == microShoe,
    "returning to a table must resume that table's shoe, not open a new one")

-- In multiplayer every player at a table is dealt from that one shared shoe,
-- exactly like a real table. Per-player shoes would have let two players be
-- dealt the same card at the same moment, and neither one's count would
-- describe what the table was actually dealing.
PZLinux.Blackjack.Shoes = {}
local firstPlayerShoe = PZLinuxBlackjackShoeAcquire(microTable)
local dealtToFirstPlayer = {}
for _ = 1, 4 do table.insert(dealtToFirstPlayer, PZLinuxBlackjackShoeDraw(firstPlayerShoe)) end

local secondPlayerShoe = PZLinuxBlackjackShoeAcquire(microTable)
assert(secondPlayerShoe == firstPlayerShoe, "two players at the same table must share one shoe")
assert(#secondPlayerShoe.cards == 48, "cards another player was dealt must already be gone from the shoe")
for _, card in ipairs(dealtToFirstPlayer) do
    for _, remaining in ipairs(secondPlayerShoe.cards) do
        assert(card ~= remaining, "a card dealt to one player must not still be dealable to another")
    end
end

-- A shared shoe can be turned over by somebody else's hand between two of
-- mine, which the per-hand shuffled flag alone cannot express -- it only
-- covers shuffles since this player's own previous hand. The shuffle id is
-- what a player at a shared table compares against.
PZLinux.Blackjack.Shoes = {}
local trackedShoe = PZLinuxBlackjackShoeAcquire(eliteTable)
local firstShuffleId = trackedShoe.shuffleId
assert(type(firstShuffleId) == "number", "a shoe must report which shuffle it is on")
assert(PZLinuxBlackjackShoeAcquire(eliteTable).shuffleId == firstShuffleId,
    "a shoe still in play must stay on the same shuffle id")
while #trackedShoe.cards > 0 do PZLinuxBlackjackShoeDraw(trackedShoe) end
assert(PZLinuxBlackjackShoeAcquire(eliteTable).shuffleId == firstShuffleId + 1,
    "every reshuffle must advance the shuffle id, or a player could never tell a shoe turned over " ..
    "during somebody else's hand")

-- With no cut card a hand can genuinely empty the shoe part way through, so
-- an exhausted shoe must reshuffle on the spot rather than deal a nil card --
-- and it must say that it did, or a hand could straddle a shuffle without the
-- player ever being told their count died.
local dryShoe = PZLinuxBlackjackShoeCreate(1, "micro")
for _ = 1, 52 do PZLinuxBlackjackShoeDraw(dryShoe) end
assert(#dryShoe.cards == 0, "the shoe is empty")
dryShoe.shuffled = false
assert(PZLinuxBlackjackShoeDraw(dryShoe) ~= nil, "an exhausted shoe must refill rather than deal nothing")
assert(dryShoe.shuffled, "a shoe that turned over mid-hand must report the shuffle")
assert(#dryShoe.cards == 51, "the refilled shoe must be a full deck minus the card just dealt")

-- Only the shape of the shoe is ever sent to the client: telling the client
-- what is left in the shoe would do the counting for the player.
local state = PZLinuxBlackjackShoeState(PZLinuxBlackjackShoeCreate(2, "high"))
assert(state.decks == 2 and state.size == 104 and state.remaining == 104, "shoe state reports deck count and depth")
assert(state.shuffleId == 1, "shoe state reports which shuffle the table is on")
assert(state.cards == nil, "the shoe's remaining cards must never be exposed to the client")
assert(PZLinuxBlackjackShoeState(nil) == nil, "no shoe means no shoe state")

-- Server wiring: a hand must take its cards from the persistent shoe, and the
-- shoe must be resolved once per hand (at deal time) so it can never be
-- reshuffled from under a hand already in progress.
local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
assert(variablesSource:find('require "PZLinux/PZLinuxBlackjackEngine"', 1, true),
    "the blackjack engine must be loaded by the shared code")

local startBlock = variablesSource:match("function PZLinuxBlackjackStart.-\nend")
assert(startBlock, "PZLinuxBlackjackStart must exist")
assert(not startBlock:find("PZLinuxBlackjackCreateDeck", 1, true),
    "a hand must not build its own fresh deck, or nothing carries over between hands and counting is impossible")
local acquireCount = select(2, startBlock:gsub("PZLinuxBlackjackShoeAcquire", ""))
assert(acquireCount == 1, "exactly one shoe must be resolved per hand")
assert(startBlock:find("PZLinuxBlackjackShoeAcquire(tableDef)", 1, true),
    "the shoe must be resolved from the table being played, not from the player: the shoe belongs " ..
    "to the table and is shared by everyone dealt at it")

for _, functionName in ipairs({ "PZLinuxBlackjackHit", "PZLinuxBlackjackStand" }) do
    local block = variablesSource:match("function " .. functionName .. ".-\nend")
    assert(block, functionName .. " must exist")
    assert(block:find("PZLinuxBlackjackSessionDraw(session)", 1, true),
        functionName .. " must draw from the session's shoe, not from a private copy of a deck")
    assert(not block:find("PZLinuxBlackjackShoeAcquire", 1, true),
        functionName .. " must never resolve a shoe mid-hand, or the deck could be reshuffled in the middle of a hand")
end

local buildStateBlock = variablesSource:match("function PZLinuxBlackjackBuildState.-\nend")
assert(buildStateBlock, "PZLinuxBlackjackBuildState must exist")
assert(buildStateBlock:find("shoeRemaining", 1, true) and buildStateBlock:find("shoeDecks", 1, true),
    "the client must be told how deep the shoe is and how much of it is left, " ..
    "since a player at a real table can see both")
assert(buildStateBlock:find("shoeShuffleId = shoeState and shoeState.shuffleId", 1, true),
    "the client must be told which shuffle the table is on, since at a shared table another player's " ..
    "hand can turn the shoe over between two of this player's hands")
assert(buildStateBlock:find("shoeShuffled = shoeState ~= nil and shoeState.shuffled == true", 1, true),
    "the shuffled flag must be read live from the shoe, not captured when the hand was dealt: " ..
    "with no cut card a hand can turn the shoe over part way through")
assert(not buildStateBlock:find("shoeCards", 1, true),
    "the remaining cards must never be sent to the client")

-- Client wiring: the panel must display only public shoe shape/depth data, not
-- the shoe contents. This is enough for players to track the count themselves
-- without the UI doing the counting for them.
local bettingSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxBetting.lua")
local oldDisabledMarker = "PAR" .. "KED"
assert(not bettingSource:find(oldDisabledMarker, 1, true),
    "the Blackjack shoe UI comments should stay concise and avoid the old parking marker")
assert(not bettingSource:find("Shoe label UI is disabled until its translation keys exist", 1, true),
    "the Blackjack shoe label should no longer be described as disabled")
assert(bettingSource:find("self.blackjackShoeLabel = ISLabel:new", 1, true),
    "the Blackjack panel must create a visible shoe label")
assert(bettingSource:find("function PZLinuxBettingUI:updateBlackjackShoeLabel(result)", 1, true),
    "the Blackjack panel must have a live shoe label renderer")
assert(not bettingSource:find("-- function PZLinuxBettingUI:updateBlackjackShoeLabel(result)", 1, true),
    "the Blackjack shoe label renderer must not be left commented out")
assert(bettingSource:find("self:updateBlackjackShoeLabel(nil)", 1, true),
    "the Blackjack panel must initialize and refresh the shoe label before a hand is dealt")
assert(bettingSource:find("self:updateBlackjackShoeLabel(result)", 1, true),
    "the Blackjack panel must refresh the shoe label from live hand state")
assert(bettingSource:find("result.shoeDecks", 1, true), "the client label must render the shoe deck count")
assert(bettingSource:find("result.shoeRemaining", 1, true), "the client label must render cards remaining")
assert(bettingSource:find("blackjackShoeShuffleIdsByTable", 1, true),
    "the client must remember the last shoe shuffle id it saw per table")
assert(bettingSource:find("local shuffleId = result and result.shoeShuffleId", 1, true),
    "the client must read the monotonic shoe shuffle id, not only the transient shuffled flag")
assert(bettingSource:find("previousShuffleId ~= nil and previousShuffleId ~= shuffleId", 1, true),
    "a changed shoeShuffleId must be treated as a shuffle even if another player cleared the flag")
assert(bettingSource:find("self.blackjackShoeShuffleIdsByTable[tableKey] = shuffleId", 1, true),
    "the client must update its per-table shuffle id memory after every live state")
assert(bettingSource:find("if shuffled then", 1, true),
    "the label must use the derived shuffled state that includes shoeShuffleId changes")
assert(not bettingSource:find("if result and result.shoeShuffled then", 1, true),
    "the label must not depend only on the transient shoeShuffled flag")
assert(not bettingSource:find("shoeCards", 1, true),
    "the client label must not depend on the remaining card identities")

for _, key in ipairs({
    "IGUI_PZLinux_Betting_BlackjackShoe",
    "IGUI_PZLinux_Betting_BlackjackShoeIdle",
    "IGUI_PZLinux_Betting_BlackjackShuffled",
}) do
    assert(bettingSource:find('"' .. key .. '"', 1, true),
        key .. " must be used by the live Blackjack shoe UI")
    assert(variablesSource:find(key, 1, true),
        key .. " must have a shared fallback for engine-free contexts")
end

print("Blackjack shoe audit OK")
