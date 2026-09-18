-- Blackjack used to build and shuffle a brand new 52-card deck for every
-- single hand. That quietly made the game unbeatable by skill: with the deck
-- reset between hands, every hand is drawn from exactly the same fixed
-- distribution, so nothing a player observes in one hand carries any
-- information into the next one and there is nothing to count.
--
-- Real casinos deal from a *shoe* of several decks rather than reshuffling
-- between hands. That persistence is the whole reason card counting exists:
-- cards already dealt stay gone, so the composition of what is left drifts
-- away from the fresh-deck average and a player who tracks it knows something
-- the fresh-shuffle player cannot.
--
-- There is deliberately no cut card here. A real casino stops dealing partway
-- through the shoe precisely to cap how much an advantage player can take off
-- the house, but the house in this mod pays out of an infinite supply of
-- in-game currency and loses nothing it needs protecting from. So the shoe is
-- dealt all the way down to its last card, which is the deepest penetration
-- possible and makes a carefully kept count as valuable as it can be. The
-- table bet limits (PZLinuxConfig.lua) already do the only capping the
-- economy actually needs.
--
-- This module owns the shoe and the pure rules of the game: card values,
-- hand totals, when the dealer draws, who won and what that pays. Like
-- PZLinuxPokerEngine.lua it is deliberately free of any game-engine
-- dependency, so all of it can be exercised directly without the rest of the
-- mod loaded -- which is what lets tools/test_blackjack_counting.lua play
-- hundreds of thousands of real hands and measure whether counting the shoe
-- actually pays.

PZLinux = PZLinux or {}
PZLinux.Blackjack = PZLinux.Blackjack or {}

-- Live shoes, keyed by table id: the shoe belongs to the table, not to whoever
-- happens to be sitting at it. In multiplayer that means everyone playing the
-- same table is dealt from one shared shoe, exactly as a real table works --
-- keying it per player would have given each of them a private shoe, so two
-- players could be dealt the same card at the same time and neither one's
-- count would describe what the table was actually dealing.
--
-- Memory-only and per-process on purpose: a server restart dealing a fresh
-- shoe is exactly what a real casino does when a table reopens, and a count
-- carried across a restart would be counting cards nobody at the table ever
-- saw.
PZLinux.Blackjack.Shoes = PZLinux.Blackjack.Shoes or {}

local PZLINUX_BLACKJACK_FALLBACK_RANKS = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
local PZLINUX_BLACKJACK_FALLBACK_SUITS = { "C", "D", "H", "S" }
local PZLINUX_BLACKJACK_RANK_LABELS = { A = "A", T = "10", J = "J", Q = "Q", K = "K" }
local PZLINUX_BLACKJACK_SUIT_LABELS = { C = "C", D = "D", H = "H", S = "S" }

-- Resolved lazily rather than at load time: every file under media/lua is
-- loaded by the game in its own order, so PZLinux.Config is not guaranteed to
-- exist yet while this file is being read.
local function PZLinuxBlackjackShoeConfig()
    return (PZLinux.Config and PZLinux.Config.Blackjack) or {}
end

local function PZLinuxBlackjackShoeRandomRange(minInclusive, maxExclusive)
    if ZombRand then return ZombRand(minInclusive, maxExclusive) end
    return math.random(minInclusive, maxExclusive - 1)
end

-- How many 52-card decks a given table deals from. Clamped to the configured
-- bounds so a bad table definition can never produce a zero-card shoe (which
-- would deal nothing) or an absurdly deep one.
function PZLinuxBlackjackShoeDecksForTable(tableDef)
    local config = PZLinuxBlackjackShoeConfig()
    local minimum = config.deckMin or 1
    local maximum = config.deckMax or 3
    local decks = tonumber(tableDef and tableDef.decks) or minimum

    decks = math.floor(decks)
    if decks < minimum then decks = minimum end
    if decks > maximum then decks = maximum end
    return decks
end

function PZLinuxBlackjackShoeShuffleCards(cards)
    for index = #cards, 2, -1 do
        local swapIndex = PZLinuxBlackjackShoeRandomRange(1, index + 1)
        cards[index], cards[swapIndex] = cards[swapIndex], cards[index]
    end
    return cards
end

-- Refills a shoe in place. Reusing the same cards table matters: an
-- in-progress hand holds a direct reference to it (session.deck), so
-- replacing the table instead of its contents would leave that hand drawing
-- from the retired shoe.
function PZLinuxBlackjackShoeFill(shoe)
    local config = PZLinuxBlackjackShoeConfig()
    local ranks = config.ranks or PZLINUX_BLACKJACK_FALLBACK_RANKS
    local suits = config.suits or PZLINUX_BLACKJACK_FALLBACK_SUITS

    local cards = shoe.cards
    for index = #cards, 1, -1 do cards[index] = nil end

    for _ = 1, shoe.decks do
        for _, suit in ipairs(suits) do
            for _, rank in ipairs(ranks) do
                table.insert(cards, {
                    rank = rank,
                    suit = suit,
                    label = (PZLINUX_BLACKJACK_RANK_LABELS[rank] or rank) .. (PZLINUX_BLACKJACK_SUIT_LABELS[suit] or suit),
                })
            end
        end
    end

    PZLinuxBlackjackShoeShuffleCards(cards)
    shoe.size = #cards
    shoe.dealt = 0
    -- Bumped on every shuffle this shoe ever gets. The shuffled flag below
    -- only answers "did a shuffle happen since the last hand *I* was dealt",
    -- which is not enough at a shared table: another player's hand can turn
    -- the shoe over between two of mine. Comparing this id against the one
    -- seen on the previous hand answers it for anyone at the table.
    shoe.shuffleId = (shoe.shuffleId or 0) + 1
    return shoe
end

function PZLinuxBlackjackShoeCreate(decks, tableId)
    local shoe = {
        tableId = tableId,
        decks = decks or 1,
        cards = {},
        size = 0,
        dealt = 0,
        shuffleId = 0,
        shuffled = true,
    }
    return PZLinuxBlackjackShoeFill(shoe)
end

-- With no cut card, a shoe is only retired once it is genuinely out of cards
-- -- which is the one moment a counter's count resets to zero.
function PZLinuxBlackjackShoeNeedsShuffle(shoe)
    if not shoe or not shoe.cards then return true end
    return #shoe.cards == 0
end

-- Returns the table's shoe, which the next hand dealt at that table comes out
-- of whoever is playing it. shoe.shuffled reports whether a shuffle happened
-- since the previous hand at this table -- either because this call started a
-- fresh shoe, or because the previous hand ran the old one dry. Moving between
-- tables needs no special handling: each table simply keeps its own shoe, and
-- a player coming back to a table it left rejoins that table's shoe exactly
-- where the table has since dealt it to.
function PZLinuxBlackjackShoeAcquire(tableDef)
    local decks = PZLinuxBlackjackShoeDecksForTable(tableDef)
    local tableId = tableDef and tableDef.id
    local shoe = PZLinux.Blackjack.Shoes[tableId]

    if shoe and shoe.decks == decks and not PZLinuxBlackjackShoeNeedsShuffle(shoe) then
        shoe.shuffled = false
        return shoe
    end

    -- A shoe that is out of cards, or whose table has been reconfigured to
    -- deal a different number of decks, is replaced in place so that any hand
    -- still holding this shoe keeps drawing from the live one.
    if shoe then
        shoe.decks = decks
        PZLinuxBlackjackShoeFill(shoe)
        shoe.shuffled = true
        return shoe
    end

    shoe = PZLinuxBlackjackShoeCreate(decks, tableId)
    PZLinux.Blackjack.Shoes[tableId] = shoe
    return shoe
end

function PZLinuxBlackjackShoeDraw(shoe)
    if not shoe or not shoe.cards then return nil end
    if #shoe.cards == 0 then
        -- Dealing to the last card means a hand can genuinely empty the shoe
        -- part way through. The rest of that hand comes from a fresh shuffle,
        -- and shoe.shuffled stays set so the hand still in progress -- and the
        -- player counting it -- is told the shoe turned over.
        PZLinuxBlackjackShoeFill(shoe)
        shoe.shuffled = true
    end

    local card = table.remove(shoe.cards, #shoe.cards)
    if card then shoe.dealt = (shoe.dealt or 0) + 1 end
    return card
end

-- The only shoe information sent to the client. Deliberately just the shape
-- of the shoe (how many decks, how much of it is left, which shuffle it is on)
-- and never the composition of what remains: the player still has to do the
-- counting themselves from the cards they were actually shown.
function PZLinuxBlackjackShoeState(shoe)
    if not shoe then return nil end
    return {
        decks = shoe.decks,
        shuffleId = shoe.shuffleId,
        size = shoe.size,
        remaining = #shoe.cards,
        shuffled = shoe.shuffled == true,
    }
end

-- The rules of the hand, kept here rather than in the server file so that the
-- money math and the dealer's behavior can be simulated exactly as played.

function PZLinuxBlackjackCardValue(card)
    if not card then return 0 end
    if card.rank == "A" then return 11 end
    if card.rank == "K" or card.rank == "Q" or card.rank == "J" then return 10 end
    return tonumber(card.rank) or 0
end

function PZLinuxBlackjackHandValue(hand)
    local value = 0
    local aces = 0

    for _, card in ipairs(hand or {}) do
        value = value + PZLinuxBlackjackCardValue(card)
        if card.rank == "A" then
            aces = aces + 1
        end
    end

    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end

    return value
end

function PZLinuxBlackjackIsNatural(hand)
    return hand and #hand == 2 and PZLinuxBlackjackHandValue(hand) == 21
end

-- The house rule this game is dealt under: the dealer draws to 16 and stands
-- on all 17s, soft ones included.
function PZLinuxBlackjackDealerShouldHit(hand)
    return PZLinuxBlackjackHandValue(hand) < 17
end

-- Naturals settle immediately, before either side can draw.
function PZLinuxBlackjackResolveNaturals(playerHand, dealerHand)
    local playerNatural = PZLinuxBlackjackIsNatural(playerHand)
    local dealerNatural = PZLinuxBlackjackIsNatural(dealerHand)

    if playerNatural and dealerNatural then return "push" end
    if playerNatural then return "blackjack" end
    if dealerNatural then return "lose" end
    return nil
end

function PZLinuxBlackjackResolveStand(playerValue, dealerValue)
    if dealerValue > 21 or playerValue > dealerValue then return "win" end
    if playerValue == dealerValue then return "push" end
    return "lose"
end

-- Real casino odds: 3:2 on a natural, 1:1 on a win, stake returned on a push.
-- Returned as the total credited back, so a losing hand pays nothing and a
-- push pays the stake straight back.
function PZLinuxBlackjackPayout(outcome, bet)
    bet = bet or 0
    if outcome == "blackjack" then return math.floor(bet * 2.5) end
    if outcome == "win" then return bet * 2 end
    if outcome == "push" then return bet end
    return 0
end
