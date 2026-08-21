PZLinux = PZLinux or {}

-- Each skill can be trained at 4 XP tiers. A base price is rolled, multiplied
-- by world-age scarcity, rounded, then persisted server-side with the weekly
-- offer so reopening the panel can never change the quote. Larger courses
-- remain more efficient, but their wider ranges and longer viewing time keep
-- Training from becoming an instant XP purchase for wealthy characters.
PZLinuxTrainingTiers = PZLinuxTrainingTiers or {
    { xp = 100, minPrice = 5000, maxPrice = 15000, durationHours = 4 },
    { xp = 200, minPrice = 10000, maxPrice = 25000, durationHours = 6 },
    { xp = 400, minPrice = 20000, maxPrice = 40000, durationHours = 8 },
    { xp = 800, minPrice = 30000, maxPrice = 80000, durationHours = 10 },
}

-- Perks are referenced by their string name (Perks.FromString(perk), the
-- same real vanilla API already used for this in server/BuildingObjects/
-- ISBuildUtil.lua) rather than the enum value directly, since these need
-- to round-trip through plain modData strings.
--
-- Deliberately combat/physical-conditioning skills free (Aiming, Axe,
-- Blunt, LongBlade, SmallBlade, SmallBlunt, Spear, Combat, Reloading,
-- Fitness, Strength, Sprinting, Nimble, Lightfoot, Sneak) -- these read as
-- "a class you could actually take", not a way to buy combat power in a
-- survival game.
PZLinuxTrainingCourses = PZLinuxTrainingCourses or {
    { id = "electricity", perk = "Electricity", nameKey = "IGUI_PZLinux_Training_Electricity" },
    { id = "mechanics", perk = "Mechanics", nameKey = "IGUI_PZLinux_Training_Mechanics" },
    { id = "cooking", perk = "Cooking", nameKey = "IGUI_PZLinux_Training_Cooking" },
    { id = "farming", perk = "Farming", nameKey = "IGUI_PZLinux_Training_Farming" },
    { id = "woodwork", perk = "Woodwork", nameKey = "IGUI_PZLinux_Training_Woodwork" },
    { id = "metalworking", perk = "MetalWelding", nameKey = "IGUI_PZLinux_Training_Metalworking" },
    { id = "tailoring", perk = "Tailoring", nameKey = "IGUI_PZLinux_Training_Tailoring" },
    { id = "firstaid", perk = "Doctor", nameKey = "IGUI_PZLinux_Training_FirstAid" },
    { id = "fishing", perk = "Fishing", nameKey = "IGUI_PZLinux_Training_Fishing" },
    { id = "trapping", perk = "Trapping", nameKey = "IGUI_PZLinux_Training_Trapping" },
    { id = "foraging", perk = "PlantScavenging", nameKey = "IGUI_PZLinux_Training_Foraging" },
    { id = "husbandry", perk = "Husbandry", nameKey = "IGUI_PZLinux_Training_Husbandry" },
    { id = "blacksmith", perk = "Blacksmith", nameKey = "IGUI_PZLinux_Training_Blacksmith" },
    { id = "masonry", perk = "Masonry", nameKey = "IGUI_PZLinux_Training_Masonry" },
    { id = "pottery", perk = "Pottery", nameKey = "IGUI_PZLinux_Training_Pottery" },
}

PZLinuxTrainingConfig = PZLinuxTrainingConfig or {
    offerCount = 3,
    offerDurationHours = 24 * 7,
    priceRoundingStep = 100,
    -- In-game-hour gap a single progress tick may ever count -- a
    -- generous sanity bound (not a tight anti-cheat clamp: the world
    -- clock is server-authoritative, a client can't fake or accelerate it
    -- beyond legitimate game-speed controls) against a stale baseline
    -- somehow surviving without a reset counting a huge, unearned jump.
    maxTickDeltaHours = 1,
}

function PZLinuxTrainingGetCourse(courseId)
    for _, course in ipairs(PZLinuxTrainingCourses) do
        if course.id == courseId then return course end
    end
    return nil
end

-- A "course offer" is a (skill, tier) pair -- e.g. "electricity_400" is
-- Electricity at the 400 XP / $20,000-$40,000 / 8h tier -- so completing
-- one tier of a skill doesn't use up the others; a player can come back later
-- for a bigger (or, if they just want a taste first, a smaller) dose of
-- the same skill.
function PZLinuxTrainingBuildOfferId(skillId, tierXp)
    return tostring(skillId) .. "_" .. tostring(tierXp)
end

-- Returns the course and tier definitions for an offer id, or nil, nil if
-- the id doesn't parse into a real (known skill, known tier) pair.
function PZLinuxTrainingResolveOffer(offerId)
    if type(offerId) ~= "string" then return nil, nil end
    local skillId, tierXpText = offerId:match("^(.+)_(%d+)$")
    if not skillId then return nil, nil end
    local tierXp = tonumber(tierXpText)

    local course = PZLinuxTrainingGetCourse(skillId)
    if not course then return nil, nil end

    for _, tier in ipairs(PZLinuxTrainingTiers) do
        if tier.xp == tierXp then return course, tier end
    end
    return nil, nil
end

-- Every (skill, tier) combination that exists in the catalog -- the full
-- pool PZLinuxTrainingEnsureWeeklyOffers draws its weekly 3 from.
function PZLinuxTrainingAllOfferIds()
    local ids = {}
    for _, course in ipairs(PZLinuxTrainingCourses) do
        for _, tier in ipairs(PZLinuxTrainingTiers) do
            table.insert(ids, PZLinuxTrainingBuildOfferId(course.id, tier.xp))
        end
    end
    return ids
end
