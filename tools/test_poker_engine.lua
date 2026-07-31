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

-- Local test harness only. Project Zomboid loads the mod with require paths from media/lua.
dofile("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerConfig.lua")
dofile("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerEngine.lua")

local function card(label)
    local rank = label:sub(1, 1)
    local suit = label:sub(2, 2)
    local values = { T = 10, J = 11, Q = 12, K = 13, A = 14 }
    local value = values[rank] or tonumber(rank)
    return { rank = rank, suit = suit, value = value, label = label }
end

local function hand(labels)
    local cards = {}
    for token in labels:gmatch("%S+") do
        table.insert(cards, card(token))
    end
    return PZLinuxPokerEvaluateHand(cards)
end

local function assertName(labels, expected)
    local result = hand(labels)
    assert(result.name == expected, labels .. " expected " .. expected .. " got " .. tostring(result.name))
end

math.randomseed(42)

local deck = PZLinuxPokerCreateDeck()
assert(#deck == 52, "deck must contain 52 cards")
local seen = {}
for _, c in ipairs(deck) do
    assert(not seen[c.label], "duplicate card " .. c.label)
    seen[c.label] = true
end

assertName("AH KH QH JH TH 2C 3D", "royal_flush")
assertName("9H 8H 7H 6H 5H AC KD", "straight_flush")
assertName("AH AD AC AS 2C 3D 4H", "four_kind")
assertName("AH AD AC KC KD 2S 3H", "full_house")
assertName("AH JH 8H 4H 2H KC QD", "flush")
assertName("AH 2D 3C 4S 5H KC QD", "straight")
assertName("AH AD AC KS QD 2C 3H", "three_kind")
assertName("AH AD KC KD QS 2C 3H", "two_pair")
assertName("AH AD KC QS 9D 2C 3H", "pair")
assertName("AH KD QC 9S 7D 4C 2H", "high_card")

local pairAces = hand("AH AD KC QS 9D 2C 3H")
local pairKings = hand("KH KD AC QS 9D 2C 3H")
assert(PZLinuxPokerCompareHands(pairAces, pairKings) > 0, "pair aces should beat pair kings")

print("PZLinux poker engine tests OK")
