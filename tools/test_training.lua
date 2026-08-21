-- Regression test for the Training feature (buy XP with money, gated by
-- time spent actually keeping the panel open -- moved up from the v1.1.0
-- roadmap into v1.0.10 as a goodwill feature after a heavy bugfix cycle).
--
-- Covers: the (skill, tier) offer catalog resolves correctly; offers
-- reroll weekly (not daily -- a daily reroll turned out to be too
-- generous once nothing is ever permanently used up) and exclude the
-- currently-active course; purchasing debits money and enforces
-- single-course-at-a-time; progress only accumulates through explicit
-- ticks (never just from elapsed time read passively); completing grants
-- XP through the real addXp channel (so vanilla multipliers apply) and
-- removes only that exact (skill, tier) pair from THIS WEEK's offers, not
-- forever -- it has a normal chance of reappearing on a future week's
-- roll; re-opening the panel resets the tick baseline so time away is
-- never counted.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_training.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- ---------------------------------------------------------------------
-- 1. Load the real data file and confirm the catalog shape.
-- ---------------------------------------------------------------------

local dataSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxTrainingData.lua")
assert(loadstring(dataSource))()

PZLinuxTestAssert(#PZLinuxTrainingCourses == 15, "expected 15 trainable skills, found " .. #PZLinuxTrainingCourses)
PZLinuxTestAssert(#PZLinuxTrainingTiers == 4, "expected 4 XP tiers, found " .. #PZLinuxTrainingTiers)

-- No combat/physical-conditioning perk snuck into the roster.
local forbiddenPerks = {
    Aiming = true, Axe = true, Blunt = true, LongBlade = true, SmallBlade = true, SmallBlunt = true,
    Spear = true, Combat = true, Reloading = true, Fitness = true, Strength = true, Sprinting = true,
    Nimble = true, Lightfoot = true, Sneak = true,
}
for _, course in ipairs(PZLinuxTrainingCourses) do
    PZLinuxTestAssert(not forbiddenPerks[course.perk], course.perk .. " must not be a Training-purchasable skill")
end

-- Tier price ranges and doubled durations are part of the balance contract.
local expectedTiers = {
    [100] = { minPrice = 5000, maxPrice = 15000, durationHours = 4 },
    [200] = { minPrice = 10000, maxPrice = 25000, durationHours = 6 },
    [400] = { minPrice = 20000, maxPrice = 40000, durationHours = 8 },
    [800] = { minPrice = 30000, maxPrice = 80000, durationHours = 10 },
}
local previousRate = 0
for _, tier in ipairs(PZLinuxTrainingTiers) do
    local expected = expectedTiers[tier.xp]
    PZLinuxTestAssert(expected ~= nil, "unexpected Training XP tier: " .. tostring(tier.xp))
    PZLinuxTestAssert(tier.minPrice == expected.minPrice and tier.maxPrice == expected.maxPrice,
        tostring(tier.xp) .. " XP must use its configured random price range")
    PZLinuxTestAssert(tier.durationHours == expected.durationHours,
        tostring(tier.xp) .. " XP must use its doubled duration")
    local rate = tier.xp / tier.durationHours
    PZLinuxTestAssert(rate > previousRate, "each bigger tier must have strictly better XP/hour than the last")
    previousRate = rate
end

PZLinuxTestAssert(#PZLinuxTrainingAllOfferIds() == 60, "15 skills x 4 tiers must produce 60 distinct offers")
PZLinuxTestAssert(PZLinuxTrainingConfig.priceRoundingStep == 100,
    "Training prices must be rounded to the nearest $100")

local course, tier = PZLinuxTrainingResolveOffer("electricity_400")
PZLinuxTestAssert(course and course.id == "electricity" and course.perk == "Electricity",
    "electricity_400 must resolve to the Electricity course")
PZLinuxTestAssert(tier and tier.xp == 400 and tier.minPrice == 20000
    and tier.maxPrice == 40000 and tier.durationHours == 8,
    "electricity_400 must resolve to the 400xp/$20000-$40000/8h tier")

local noCourse, noTier = PZLinuxTrainingResolveOffer("electricity_999")
PZLinuxTestAssert(not noCourse and not noTier, "a nonexistent tier must not resolve")
noCourse, noTier = PZLinuxTrainingResolveOffer("not_a_real_skill_400")
PZLinuxTestAssert(not noCourse and not noTier, "a nonexistent skill must not resolve")

print("PZLinux Training catalog tests OK")

-- ---------------------------------------------------------------------
-- 2. Functional tests against the real server functions.
-- ---------------------------------------------------------------------

PZLinux = { Config = { ATM = { minCash = 0, maxCash = 100 } } }
Perks = { FromString = function(name) return name end, Electricity = "Electricity" }
addXp = function() end
local worldAgeHours = 100
getGameTime = function() return { getWorldAgeHours = function() return worldAgeHours end } end
ZombRand = function(a, b) if b then return a end return 0 end

local function extract(source, pattern)
    local block = source:match(pattern)
    assert(block, "pattern not found: " .. pattern)
    return block
end

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

local playerModData
local characterSequence = 0
local currentCharacterKey
local persistentModData = {}
ModData = {
    getOrCreate = function(name)
        persistentModData[name] = persistentModData[name] or {}
        return persistentModData[name]
    end,
}
local FakePlayer = {}
FakePlayer.__index = FakePlayer
function FakePlayer:getModData() return playerModData end
function FakePlayer:getUsername() return "TestPlayer" end
local fakePlayer = setmetatable({}, FakePlayer)

function PZLinuxGetPlayer(p) return p end
function PZLinuxGetPlayerKey(player) return player and player:getUsername() or "?" end
function PZLinuxGetCharacterKey(_player, _createIfMissing) return currentCharacterKey end
function PZLinuxIdentityIsAuthoritative() return true end
function PZLinuxLoadBankBalance(player) return playerModData.pzlinux.player.bankBalance or 0 end
function PZLinuxSetBankBalance(player, amount) playerModData.pzlinux.player.bankBalance = amount return amount end
function PZLinuxApplyBankDebit(player, amount, reason, requestId)
    local prev = PZLinuxLoadBankBalance(player)
    if prev < amount then return { ok = false, error = "not_enough_money", requestId = requestId, balance = prev } end
    local bal = PZLinuxSetBankBalance(player, prev - amount)
    return { ok = true, amount = amount, balance = bal, previousBalance = prev, reason = reason, requestId = requestId }
end
function PZLinuxTransmitPlayerModData(_player) end

local pieces = {
    "PZLinuxTrainingEncodeList", "PZLinuxTrainingDecodeList", "PZLinuxTrainingListContains",
    "PZLinuxTrainingRemoveFromList", "PZLinuxTrainingGetLedger", "PZLinuxTrainingGetCanonicalState",
    "PZLinuxTrainingSyncPlayerMirror", "PZLinuxTrainingCurrentGameWeek", "PZLinuxTrainingRollPrice",
    "PZLinuxTrainingGetOfferPrice", "PZLinuxTrainingEnsureWeeklyOffers",
    "PZLinuxTrainingGetState", "PZLinuxTrainingApplyPurchase", "PZLinuxTrainingApplyProgressTick",
}
for _, name in ipairs(pieces) do
    local block = extract(variablesSource, "function " .. name .. ".-\nend\n")
    assert(loadstring(block))()
end
for _, name in ipairs({
    "PZLinuxTrainingCopyValue", "PZLinuxTrainingMigrateLegacyState",
    "PZLinuxTrainingWorldAgeHours", "PZLinuxTrainingBuildActiveState",
}) do
    local block = extract(variablesSource, "local function " .. name .. ".-\nend\n"):gsub("^local function", "function", 1)
    assert(loadstring(block))()
end

PZLINUX_TRAINING_LEDGER_DATA = "PZLinuxTrainingLedger"
PZLINUX_TRAINING_LEDGER_VERSION = 1
PZLINUX_TRAINING_MIRROR_FIELDS = {
    "PZLinuxTrainingOffersWeek", "PZLinuxTrainingOffersList",
    "PZLinuxTrainingOffersGeneratedHour", "PZLinuxTrainingOffersRefreshHour",
    "PZLinuxTrainingOfferPrices", "PZLinuxTrainingActiveCourse",
    "PZLinuxTrainingActivePerk", "PZLinuxTrainingActiveXp",
    "PZLinuxTrainingActivePrice", "PZLinuxTrainingActiveDurationHours",
    "PZLinuxTrainingActiveProgressHours", "PZLinuxTrainingLastTickHour",
}

do
    local minimumRoll = ZombRand
    local previousEconomy = PZLinux.Economy
    for _, trainingTier in ipairs(PZLinuxTrainingTiers) do
        PZLinuxTestAssert(PZLinuxTrainingRollPrice(trainingTier) == trainingTier.minPrice,
            tostring(trainingTier.xp) .. " XP must be able to roll its minimum price")
    end

    ZombRand = function(_minimum, maximum) return maximum - 1 end
    for _, trainingTier in ipairs(PZLinuxTrainingTiers) do
        PZLinuxTestAssert(PZLinuxTrainingRollPrice(trainingTier) == trainingTier.maxPrice,
            tostring(trainingTier.xp) .. " XP must be able to roll its maximum price")
    end

    ZombRand = function(_minimum, _maximum) return 10456 end
    PZLinux.Economy = { scarcityMultiplier = function() return 1 end }
    PZLinuxTestAssert(PZLinuxTrainingRollPrice(PZLinuxTrainingTiers[1]) == 10500,
        "$10456 must round to the nearest hundred after a x1 scarcity multiplier")

    PZLinux.Economy = { scarcityMultiplier = function() return 2 end }
    PZLinuxTestAssert(PZLinuxTrainingRollPrice(PZLinuxTrainingTiers[1]) == 20900,
        "Training must apply world scarcity before rounding the final quote")

    PZLinux.Economy = previousEconomy
    ZombRand = minimumRoll
end

local function resetPlayer()
    characterSequence = characterSequence + 1
    currentCharacterKey = "TestPlayer:PZLinuxCharacter-" .. tostring(characterSequence)
    playerModData = { pzlinux = { player = { bankBalance = 1000000 } } }
    return fakePlayer
end

-- --- Weekly offers: exactly 3, all resolve to real (skill, tier) pairs. ---
do
    local player = resetPlayer()
    local state = PZLinuxTrainingGetState(player, "req-a")
    PZLinuxTestAssert(state.ok and #state.offers == 3, "exactly 3 weekly offers must be rolled")
    for _, offer in ipairs(state.offers) do
        local c, t = PZLinuxTrainingResolveOffer(offer.id)
        PZLinuxTestAssert(c and t, "every offered id must resolve to a real course/tier")
        PZLinuxTestAssert(offer.xp == t.xp and offer.durationHours == t.durationHours,
            "the offer's reported xp/duration must match its tier")
        PZLinuxTestAssert(offer.price >= t.minPrice and offer.price <= t.maxPrice,
            "the authoritative offer price must stay inside its tier range")
    end
    PZLinuxTestAssert(state.active == nil, "a fresh player must have no active training")
end

-- --- Every generated list remains fixed for a full 168 in-game hours from
-- generation, instead of refreshing at a calendar-week boundary. ---
do
    local player = resetPlayer()
    local before = PZLinuxTrainingGetState(player, "req-week-a")
    local refreshHour = before.refreshHour

    worldAgeHours = worldAgeHours + (24 * 7) - 1
    local stillSameWeek = PZLinuxTrainingGetState(player, "req-week-b")
    PZLinuxTestAssert(stillSameWeek.offers[1].id == before.offers[1].id
        and stillSameWeek.offers[2].id == before.offers[2].id
        and stillSameWeek.offers[3].id == before.offers[3].id,
        "the offers must remain fixed for the complete seven-day window")
    PZLinuxTestAssert(stillSameWeek.offers[1].price == before.offers[1].price
        and stillSameWeek.offers[2].price == before.offers[2].price
        and stillSameWeek.offers[3].price == before.offers[3].price,
        "reopening during the cycle must preserve every quoted price")
    PZLinuxTestAssert(refreshHour == stillSameWeek.refreshHour,
        "reopening must not extend or shorten the existing refresh deadline")

    worldAgeHours = worldAgeHours + 2
    local nextWeek = PZLinuxTrainingGetState(player, "req-week-c")
    PZLinuxTestAssert(tonumber(playerModData.PZLinuxTrainingOffersWeek) == PZLinuxTrainingCurrentGameWeek(),
        "crossing a 7-day boundary must roll a fresh week's offers")
    PZLinuxTestAssert(#nextWeek.offers == 3, "the new week must still offer exactly 3 courses")
end

-- --- MP regression: stale player ModData must never replace the canonical
-- server list or its prices between opening the UI and confirming payment. ---
do
    local player = resetPlayer()
    local before = PZLinuxTrainingGetState(player, "req-mp-open")
    local expected = {}
    for index, offer in ipairs(before.offers) do
        expected[index] = { id = offer.id, price = offer.price }
    end

    playerModData.PZLinuxTrainingOffersWeek = nil
    playerModData.PZLinuxTrainingOffersList = "electricity_800"
    playerModData.PZLinuxTrainingOfferPrices = { electricity_800 = 1 }

    local reopened = PZLinuxTrainingGetState(player, "req-mp-reopen")
    for index, offer in ipairs(reopened.offers) do
        PZLinuxTestAssert(offer.id == expected[index].id and offer.price == expected[index].price,
            "a stale MP player mirror must not reroll or reprice canonical offer " .. tostring(index))
    end

    local previousBalance = PZLinuxLoadBankBalance(player)
    local purchase = PZLinuxTrainingApplyPurchase(player, expected[1].id, "req-mp-buy")
    PZLinuxTestAssert(purchase.ok, "an offer returned by the server must still be purchasable after reopening")
    PZLinuxTestAssert(purchase.balance == previousBalance - expected[1].price,
        "Training must debit the exact canonical quoted price")
end

-- --- Purchase debits money, sets active state, and blocks a 2nd purchase
-- while one is already in progress (single-concurrency, as decided). ---
do
    local player = resetPlayer()
    local state = PZLinuxTrainingGetState(player, "req-b")
    local firstOfferId = state.offers[1].id
    local firstOfferPrice = state.offers[1].price

    local purchase = PZLinuxTrainingApplyPurchase(player, firstOfferId, "req-buy-1")
    PZLinuxTestAssert(purchase.ok, "a valid offer purchase must succeed")
    PZLinuxTestAssert(purchase.balance == 1000000 - firstOfferPrice,
        "the exact persisted offer price must be debited")
    PZLinuxTestAssert(purchase.active and purchase.active.courseId == firstOfferId, "the purchased course must become active")
    PZLinuxTestAssert(purchase.active.progress == 0, "a freshly purchased course must start at 0 progress")

    local secondOfferId = state.offers[2].id
    local blocked = PZLinuxTrainingApplyPurchase(player, secondOfferId, "req-buy-2")
    PZLinuxTestAssert(not blocked.ok and blocked.error == "training_in_progress",
        "a second purchase must be refused while one course is already active")
end

-- --- Purchasing something not in today's offers, or already completed,
-- must be refused. ---
do
    local player = resetPlayer()
    PZLinuxTrainingGetState(player, "req-c")
    local rejected = PZLinuxTrainingApplyPurchase(player, "electricity_999", "req-buy-bad")
    PZLinuxTestAssert(not rejected.ok and rejected.error == "invalid_course", "an unresolvable offer id must be refused")
end

-- --- Progress only accumulates through explicit ticks, using in-game
-- hours elapsed -- not from time simply passing while unobserved. ---
do
    local player = resetPlayer()
    local state = PZLinuxTrainingGetState(player, "req-d")
    local offerId = state.offers[1].id
    local _, tier = PZLinuxTrainingResolveOffer(offerId)
    PZLinuxTrainingApplyPurchase(player, offerId, "req-buy-d")

    -- Time passes with the panel closed (no ticks sent) -- must NOT count.
    worldAgeHours = worldAgeHours + 10

    -- Re-opening the panel must reset the baseline to "now", discarding
    -- the 10-hour gap that just passed unobserved.
    local reopened = PZLinuxTrainingGetState(player, "req-reopen")
    PZLinuxTestAssert(reopened.active.progress == 0,
        "time that passed while the panel was closed must not count as progress")

    -- Now actively "watching": each tick advances by however much game
    -- time passed since the last tick.
    worldAgeHours = worldAgeHours + 1
    local tick1 = PZLinuxTrainingApplyProgressTick(player, "req-tick-1")
    PZLinuxTestAssert(tick1.ok and not tick1.completed, "a partial tick must not complete the course")
    PZLinuxTestAssert(math.abs(tick1.active.progressHours - 1) < 0.001,
        "1 in-game hour must have accumulated, got " .. tostring(tick1.active.progressHours))
end

-- --- Completing a course grants XP via addXp (respecting multipliers by
-- construction, since it's the same channel every other XP grant uses).
-- By explicit design (corrected after an initial "permanently done
-- forever" pass -- the request was for a player to be able to spend just
-- $10,000 at a time without a smaller tier being a permanent one-shot),
-- completing a course only removes it from TODAY's offers -- it is NOT
-- tracked forever, and has a normal chance of coming back on a future
-- day's roll, exactly like a Buy Goods category that was already bought
-- today. ---
do
    local player = resetPlayer()
    local state = PZLinuxTrainingGetState(player, "req-e")
    local offerId = state.offers[1].id
    local course, tier = PZLinuxTrainingResolveOffer(offerId)
    PZLinuxTrainingApplyPurchase(player, offerId, "req-buy-e")

    local grantedPerk, grantedAmount = nil, nil
    addXp = function(_player, perk, amount) grantedPerk = perk; grantedAmount = amount end

    -- Many small ticks accumulating the total, the way real client pings
    -- would (each individual tick's delta is generously bounded by
    -- PZLinuxTrainingConfig.maxTickDeltaHours -- a single tick jumping the
    -- entire course duration in one go, like a real client never would,
    -- is exactly what that bound exists to not trust).
    local final
    local stepHours = 0.5
    local elapsed = 0
    while elapsed < tier.durationHours do
        worldAgeHours = worldAgeHours + stepHours
        elapsed = elapsed + stepHours
        final = PZLinuxTrainingApplyProgressTick(player, "req-tick-" .. tostring(elapsed))
        PZLinuxTestAssert(final.ok, "every tick while training is active must succeed")
    end
    PZLinuxTestAssert(final.completed, "accumulating the full duration across many ticks must complete the course")
    PZLinuxTestAssert(final.xpGranted == tier.xp, "the full tier XP must be reported as granted")
    PZLinuxTestAssert(grantedPerk == course.perk and grantedAmount == tier.xp,
        "addXp must be called with the course's real perk and the tier's full xp amount")
    PZLinuxTestAssert(final.active == nil, "no course must be active immediately after completion")

    PZLinuxTestAssert(not PZLinuxTrainingListContains(playerModData.PZLinuxTrainingOffersList, offerId),
        "a just-completed offer must be removed from today's remaining offers")

    -- Same day: re-buying the exact same offer must fail, since it's no
    -- longer part of today's list (not because of any permanent record).
    local sameDay = PZLinuxTrainingApplyPurchase(player, offerId, "req-buy-again-same-day")
    PZLinuxTestAssert(not sameDay.ok and sameDay.error == "invalid_course",
        "buying the exact same offer again the same day it was completed must fail")

    -- A new purchase of something else must still be allowed immediately
    -- (nothing is active anymore).
    local remainingOffers = PZLinuxTrainingDecodeList(playerModData.PZLinuxTrainingOffersList)
    if #remainingOffers > 0 then
        local again = PZLinuxTrainingApplyPurchase(player, remainingOffers[1], "req-buy-other")
        PZLinuxTestAssert(again.ok, "a different course from today's remaining offers must still be purchasable")
    end
end

-- --- Finishing ALL of this week's offers must NOT trigger an early
-- reroll -- the player must still wait out the full 7 in-game days,
-- exactly like finishing only one does. From player feedback: completing
-- every offer made a brand new list appear immediately instead of
-- waiting for the week to roll over. ---
do
    local player = resetPlayer()
    local state = PZLinuxTrainingGetState(player, "req-f")
    local weekAtStart = tonumber(playerModData.PZLinuxTrainingOffersWeek)
    local offerIds = { state.offers[1].id, state.offers[2].id, state.offers[3].id }

    for _, offerId in ipairs(offerIds) do
        local _, tier = PZLinuxTrainingResolveOffer(offerId)
        PZLinuxTrainingApplyPurchase(player, offerId, "req-buy-f-" .. offerId)
        local elapsed = 0
        local stepHours = 0.5
        local result
        while elapsed < tier.durationHours do
            worldAgeHours = worldAgeHours + stepHours
            elapsed = elapsed + stepHours
            result = PZLinuxTrainingApplyProgressTick(player, "req-tick-f-" .. offerId .. "-" .. tostring(elapsed))
        end
        PZLinuxTestAssert(result.completed, "each of this week's 3 offers must be completable in turn")
    end

    PZLinuxTestAssert(playerModData.PZLinuxTrainingOffersList == "",
        "finishing every offer this week must leave the list genuinely empty, not silently refilled")

    -- Re-opening the panel (PZLinuxTrainingGetState, same call a reopened
    -- UI makes) must NOT reroll just because the list is empty -- only a
    -- real 7-day boundary may do that.
    local afterAllDone = PZLinuxTrainingGetState(player, "req-g")
    PZLinuxTestAssert(#afterAllDone.offers == 0,
        "finishing every offer must leave zero offers until the week actually rolls over, not refill immediately")
    PZLinuxTestAssert(tonumber(playerModData.PZLinuxTrainingOffersWeek) == weekAtStart,
        "the tracked offer week must not advance just because the list emptied out")

    -- Only once the 7-day boundary is actually crossed does a fresh set
    -- of 3 appear again.
    worldAgeHours = worldAgeHours + 24 * 7
    local nextWeekState = PZLinuxTrainingGetState(player, "req-h")
    PZLinuxTestAssert(#nextWeekState.offers == 3,
        "crossing the 7-day boundary after finishing every offer must roll a fresh set of 3")
end

-- --- No permanent "completed forever" record exists anywhere in the
-- source -- structural guard against this regressing back to the
-- original (rejected) design. ---
do
    local ensureBlock = extract(variablesSource, "function PZLinuxTrainingEnsureWeeklyOffers.-\nend\n")
    PZLinuxTestAssert(not ensureBlock:find("Completed", 1, true),
        "the weekly offer roll must never filter against a permanent completed-forever list")
    local tickBlock = extract(variablesSource, "function PZLinuxTrainingApplyProgressTick.-\nend\n")
    PZLinuxTestAssert(not tickBlock:find("CompletedList", 1, true),
        "completing a course must never write to a permanent completed-forever list")
end

print("PZLinux Training functional tests OK")

-- ---------------------------------------------------------------------
-- 3. Translation coverage: every Training key has an EN fallback and a
-- translation in all 20 supported languages.
-- ---------------------------------------------------------------------

local trainingKeys = {
    "IGUI_PZLinux_Training_Title", "IGUI_PZLinux_Training_Buy", "IGUI_PZLinux_Training_Cancel",
    "IGUI_PZLinux_Training_Completed",
    "IGUI_PZLinux_Training_InProgress", "IGUI_PZLinux_Training_StayHere", "IGUI_PZLinux_Training_ChooseCourse",
    "IGUI_PZLinux_Training_Detail", "IGUI_PZLinux_Training_AlreadyInProgress",
    "IGUI_PZLinux_Training_NotEnoughMoney", "IGUI_PZLinux_Training_CourseNoLongerAvailable",
    "IGUI_PZLinux_Training_PurchaseFailed",
    "IGUI_PZLinux_Training_Electricity", "IGUI_PZLinux_Training_Mechanics", "IGUI_PZLinux_Training_Cooking",
    "IGUI_PZLinux_Training_Farming", "IGUI_PZLinux_Training_Woodwork", "IGUI_PZLinux_Training_Metalworking",
    "IGUI_PZLinux_Training_Tailoring", "IGUI_PZLinux_Training_FirstAid", "IGUI_PZLinux_Training_Fishing",
    "IGUI_PZLinux_Training_Trapping", "IGUI_PZLinux_Training_Foraging", "IGUI_PZLinux_Training_Husbandry",
    "IGUI_PZLinux_Training_Blacksmith", "IGUI_PZLinux_Training_Masonry", "IGUI_PZLinux_Training_Pottery",
}

local fallbackBlock = variablesSource:match("PZLinux%.TextFallbacks = PZLinux%.TextFallbacks or %{.-\n%}")
PZLinuxTestAssert(fallbackBlock, "the shared text fallback table must exist")
for _, key in ipairs(trainingKeys) do
    PZLinuxTestAssert(fallbackBlock:find(key, 1, true), "PZLinux.TextFallbacks must define an English fallback for " .. key)
end

local languages = { "CH", "CN", "CS", "DE", "EN", "ES", "FR", "HU", "IT", "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RU", "TH", "TR", "UA" }
for _, lang in ipairs(languages) do
    local content = readFile(luaRoot .. "/shared/Translate/" .. lang .. "/IG_UI.json")
    for _, key in ipairs(trainingKeys) do
        PZLinuxTestAssert(content:find('"' .. key .. '"', 1, true), lang .. "/IG_UI.json must define " .. key)
    end
end

print("PZLinux Training translation tests OK")

-- ---------------------------------------------------------------------
-- 4. Menu wiring: the app is registered end to end.
-- ---------------------------------------------------------------------

local menuSource = readFile(luaRoot .. "/client/Context/World/ISContextLinuxMenu.lua")
PZLinuxTestAssert(menuSource:find('self.trainingButton = ISButton:new', 1, true), "the Training button must exist in the boot menu")
PZLinuxTestAssert(menuSource:find("function linuxUI:onTraining()", 1, true), "the onTraining handler must exist")
PZLinuxTestAssert(menuSource:find("modData.PZLinuxUIOpenMenu = 13", 1, true), "onTraining must request menu id 13")
PZLinuxTestAssert(menuSource:find("self.trainingButton:setVisible(true)", 1, true),
    "onPrompt must reveal the Training button after boot")

local dispatchSource = readFile(luaRoot .. "/shared/TimedActions/ISPZLinuxAction.lua")
PZLinuxTestAssert(dispatchSource:find("modData.PZLinuxUIOpenMenu == 13", 1, true)
    and dispatchSource:find("trainingMenu_ShowUI(self.character)", 1, true),
    "menu id 13 must dispatch to trainingMenu_ShowUI")

print("PZLinux Training menu wiring tests OK")
