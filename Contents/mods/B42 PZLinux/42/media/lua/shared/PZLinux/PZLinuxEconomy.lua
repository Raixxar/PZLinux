PZLinux = PZLinux or {}
PZLinux.Economy = PZLinux.Economy or {}
PZLinux.Economy.TRADING_FEE_RATE = 0.05

function PZLinuxNormalizeMoney(amount)
    amount = tonumber(amount)
    if not amount then return 0 end
    return math.max(0, math.floor(amount))
end

function PZLinux.Economy.applyReputationDelta(currentReputation, amount)
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    local baseline = tonumber(config.baseline) or 1
    local minimum = tonumber(config.minimum) or -99
    local maximum = math.max(minimum, tonumber(config.maximum) or 200)
    currentReputation = tonumber(currentReputation) or baseline
    return math.max(minimum, math.min(maximum, currentReputation + (tonumber(amount) or 0)))
end

function PZLinux.Economy.decayReputation(currentReputation, amount)
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    local baseline = tonumber(config.baseline) or 1
    currentReputation = tonumber(currentReputation) or baseline
    amount = math.max(0, tonumber(amount) or 0.001)
    if currentReputation > baseline then
        return math.max(baseline, currentReputation - amount)
    end
    if currentReputation < baseline then
        return math.min(baseline, currentReputation + amount)
    end
    return baseline
end

function PZLinux.Economy.contractCancelPenalty()
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    return math.max(0, tonumber(config.contractCancelPenalty) or 10)
end

function PZLinux.Economy.contractCompleteReward()
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    return math.max(0, tonumber(config.contractCompleteReward) or 10)
end

function PZLinux.Economy.reputationTier(reputation)
    reputation = tonumber(reputation) or 1
    if reputation <= -50 then return "blacklisted", -49, "distrusted" end
    if reputation < 1 then return "distrusted", 1, "neutral" end
    if reputation == 1 then return "neutral", 2, "known" end
    if reputation < 41 then return "known", 41, "reliable" end
    if reputation < 101 then return "reliable", 101, "preferred" end
    return "preferred", nil, nil
end

function PZLinux.Economy.reputationPurchaseMultiplier(reputation)
    local config = PZLinux.Config and PZLinux.Config.Reputation or {}
    local baseline = tonumber(config.baseline) or 1
    reputation = tonumber(reputation) or baseline

    if reputation < baseline then
        local rate = math.max(0, tonumber(config.purchaseSurchargePerPoint) or 0.01)
        local maximum = math.max(0, tonumber(config.maximumPurchaseSurcharge) or 1.00)
        return 1 + math.min(maximum, (baseline - reputation) * rate)
    end

    local rate = math.max(0, tonumber(config.purchaseDiscountPerPoint) or 0.0025)
    local maximum = math.max(0, math.min(0.95, tonumber(config.maximumPurchaseDiscount) or 0.25))
    return 1 - math.min(maximum, (reputation - baseline) * rate)
end

function PZLinuxGetReputationPurchaseMultiplier(player)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj then return 1 end
    -- Goes through PZLinuxGetModData rather than a raw playerObj:getModData()
    -- read, so this benefits from the same nil-reputation backup recovery
    -- as every other reader (see PZLinux.getModData) instead of silently
    -- treating a lost value as reputation 1 on its own.
    local _, pzlinux = PZLinuxGetModData(playerObj)
    local reputation = pzlinux and pzlinux.player and pzlinux.player.reputation
    return PZLinux.Economy.reputationPurchaseMultiplier(reputation)
end

function PZLinux.Economy.mailDelayMax(reputation)
    local playerRep = math.min(tonumber(reputation) or 1, 200)
    return math.max(49, math.floor(30 * 24 + 1 - playerRep))
end

function PZLinux.Economy.scarcityMultiplier(worldAgeHours)
    local config = PZLinux.Config and PZLinux.Config.Economy or {}
    local periodHours = math.max(1, tonumber(config.scarcityPeriodHours) or 2190)
    local maximum = math.max(1, math.floor(tonumber(config.scarcityMaximumMultiplier) or 8))
    local ageHours = tonumber(worldAgeHours)
    if ageHours == nil then
        ageHours = getGameTime and getGameTime():getWorldAgeHours() or 0
    end
    return math.min(maximum, math.max(1, math.ceil(math.max(0, ageHours) / periodHours)))
end

function PZLinux.Economy.priceRoundingStep(amount)
    local config = PZLinux.Config and PZLinux.Config.Economy or {}
    local tiers = config.priceRoundingTiers or {
        { maximum = 99, step = 5 },
        { maximum = 999, step = 10 },
        { maximum = 9999, step = 50 },
        { maximum = 49999, step = 100 },
        { step = 500 },
    }
    amount = math.abs(tonumber(amount) or 0)

    for _, tier in ipairs(tiers) do
        local maximum = tonumber(tier.maximum)
        if not maximum or amount <= maximum then
            return math.max(1, math.floor(tonumber(tier.step) or 1))
        end
    end
    return 1
end

function PZLinux.Economy.roundPrice(amount, direction)
    amount = tonumber(amount) or 0
    if amount <= 0 then return 0 end

    local step = PZLinux.Economy.priceRoundingStep(amount)
    local units = amount / step
    local roundedUnits
    if direction == "buy" then
        roundedUnits = math.ceil(units)
    elseif direction == "sell" then
        roundedUnits = math.floor(units)
    else
        roundedUnits = math.floor(units + 0.5)
    end
    return math.max(1, math.floor(roundedUnits * step))
end

function PZLinuxDarkWebGetHourMultiplier()
    return PZLinux.Economy.scarcityMultiplier()
end

function PZLinuxDarkWebGetPurchaseMultiplier()
    if SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.PurchasePriceMultiplier then
        return SandboxVars.PZLinux.PurchasePriceMultiplier
    end
    return 1.0
end

function PZLinuxDarkWebGetSaleMultiplier()
    if SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.SalePriceMultiplier then
        return SandboxVars.PZLinux.SalePriceMultiplier
    end
    return 1.0
end

-- A player pointed out that a fresh character (no PZLinuxBank in modData
-- yet -- see PZLinuxLoadBankBalance) always receives a random starting
-- balance, with no way to opt out: dying and making a new character is
-- "free money" every time, farmable by repeated suicide. Exposing the
-- range as sandbox options lets a server admin set both to 0 for a hard
-- $0 start (or tune the range) without editing Lua; the defaults keep the
-- exact $500-$4000 range this mod has always used.
function PZLinuxGetStartingBalanceMin()
    if SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.StartingBalanceMin ~= nil then
        return math.max(0, math.floor(SandboxVars.PZLinux.StartingBalanceMin))
    end
    return 500
end

function PZLinuxGetStartingBalanceMax()
    if SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.StartingBalanceMax ~= nil then
        return math.max(0, math.floor(SandboxVars.PZLinux.StartingBalanceMax))
    end
    return 4000
end

function PZLinuxDarkWebCalculateBuyPrice(player, itemData)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not itemData or not itemData.Price then return nil end

    local perkLevel = playerObj:getPerkLevel(Perks.PlantScavenging)
    local buyMaxMultiplier = 3.0 - (2.0 * perkLevel / 10)
    local maxPrice = math.max(itemData.Price + 1, math.ceil(itemData.Price * buyMaxMultiplier))
    local price = math.ceil(ZombRand(itemData.Price, maxPrice) / 10) * 10
    price = price * PZLinuxDarkWebGetHourMultiplier() * PZLinuxDarkWebGetPurchaseMultiplier()
    price = price * PZLinuxGetReputationPurchaseMultiplier(playerObj)
    return PZLinux.Economy.roundPrice(price, "buy")
end

function PZLinuxDarkWebCalculateSellPrice(player, itemData)
    local playerObj = PZLinuxGetPlayer(player)
    if not playerObj or not itemData or not itemData.Price then return nil end

    local perkLevel = playerObj:getPerkLevel(Perks.PlantScavenging)
    local sellMinMultiplier = 0.25 + (0.025 * perkLevel)
    local sellMaxMultiplier = 0.50 + (0.025 * perkLevel)
    local minPrice = math.max(1, math.floor(itemData.Price * sellMinMultiplier))
    local maxPrice = math.max(minPrice + 1, math.ceil(itemData.Price * sellMaxMultiplier))
    local price = ZombRand(minPrice, maxPrice) * PZLinuxDarkWebGetSaleMultiplier()
    return PZLinux.Economy.roundPrice(price, "sell")
end

function PZLinuxRequestsCalculateUnitPrice(player, definition)
    if not definition then return 0 end

    local playerObj = PZLinuxGetPlayer(player)
    local skillLevel = 0
    if playerObj then
        skillLevel = playerObj:getPerkLevel(Perks.PlantScavenging) or 0
    end
    local worldAgeMultiplier = PZLinux.Economy.scarcityMultiplier()
    local sandboxMultiplier = 1.0
    if SandboxVars and SandboxVars.PZLinux and SandboxVars.PZLinux.PurchasePriceMultiplier then
        sandboxMultiplier = SandboxVars.PZLinux.PurchasePriceMultiplier
    end
    local discountPercent = math.min(15, math.max(0, skillLevel + 1))
    local basePrice = math.ceil((definition.price or 0) * worldAgeMultiplier * sandboxMultiplier)
    local requestPrice = math.ceil(basePrice * (1 - discountPercent / 100) * PZLinuxGetReputationPurchaseMultiplier(playerObj))
    return PZLinux.Economy.roundPrice(requestPrice, "buy")
end

function PZLinuxTradingNormalizePrice(price)
    price = tonumber(price) or 1
    return math.max(1, math.floor(price))
end

function PZLinuxTradingGetFeeRate()
    return math.max(0, math.min(1, tonumber(PZLinux.Economy.TRADING_FEE_RATE) or 0.05))
end

function PZLinuxTradingCalculateFee(grossAmount)
    grossAmount = PZLinuxNormalizeMoney(grossAmount)
    if grossAmount <= 0 then return 0 end
    return math.ceil(grossAmount * PZLinuxTradingGetFeeRate())
end

function PZLinuxTradingCalculateTransaction(grossAmount, transactionType)
    grossAmount = PZLinuxNormalizeMoney(grossAmount)
    local fee = PZLinuxTradingCalculateFee(grossAmount)
    local netAmount = grossAmount + fee
    if transactionType == "sell" then
        netAmount = math.max(0, grossAmount - fee)
    end

    return {
        grossAmount = grossAmount,
        fee = fee,
        netAmount = netAmount,
    }
end

function PZLinuxTradingGenerateNextPrice(lastPrice, _minPercent, maxPercent)
    lastPrice = PZLinuxTradingNormalizePrice(lastPrice)
    maxPercent = tonumber(maxPercent) or 25

    local direction = ZombRand(1, 4)
    if direction == 1 then
        local low = math.max(1, math.floor(lastPrice - lastPrice * maxPercent / 100))
        local high = math.max(low + 1, lastPrice + 2)
        return PZLinuxTradingNormalizePrice(ZombRand(low, high))
    elseif direction == 3 then
        local high = math.max(lastPrice + 1, math.ceil(lastPrice + lastPrice * maxPercent / 100))
        return PZLinuxTradingNormalizePrice(ZombRand(lastPrice, high))
    end

    return lastPrice
end

function PZLinux.Economy.contractCompanyNextPrice(lastPrice, direction)
    lastPrice = tonumber(lastPrice) or 1
    local delta = math.max(1, math.ceil(lastPrice * ZombRand(1, 10) / 100))
    local newPrice = lastPrice + delta
    if direction == "down" then
        newPrice = math.max(1, lastPrice - delta)
    end
    return newPrice
end

local function PZLinuxApplyDarkWebPriceBalance()
    local exactPrices = {
        -- Handguns
        ["Base.Revolver_Short"] = 1500,
        ["Base.Pistol"] = 1800,
        ["Base.Pistol2"] = 2400,
        ["Base.Revolver"] = 2500,
        ["Base.Pistol3"] = 3200,
        ["Base.Revolver_Long"] = 3500,

        -- Shotguns
        ["Base.DoubleBarrelShotgun"] = 4500,
        ["Base.Shotgun"] = 5000,
        ["Base.DoubleBarrelShotgunSawnoff"] = 6500,
        ["Base.ShotgunSawnoff"] = 7000,

        -- Rifles
        ["Base.VarmintRifle"] = 6500,
        ["Base.HuntingRifle"] = 8000,
        ["Base.AssaultRifle"] = 12000,
        ["Base.AssaultRifle2"] = 16000,

        -- Ammunition
        ["Base.Bullets9mmBox"] = 350,
        ["Base.Bullets38Box"] = 500,
        ["Base.Bullets44Box"] = 750,
        ["Base.223Box"] = 900,
        ["Base.308Box"] = 1000,
        ["Base.ShotgunShellsBox"] = 1200,
        ["Base.Bullets45Box"] = 1250,
        ["Base.556Box"] = 1500,
        ["Base.9mmClip"] = 900,
        ["Base.45Clip"] = 1000,
        ["Base.44Clip"] = 1100,
        ["Base.223Clip"] = 1400,
        ["Base.308Clip"] = 1600,
        ["Base.556Clip"] = 2200,
        ["Base.M14Clip"] = 2200,
        ["Base.223BulletsMold"] = 2000,
        ["Base.308BulletsMold"] = 2000,
        ["Base.9mmBulletsMold"] = 1800,
        ["Base.ShotgunShellsMold"] = 1800,

        -- Explosives and remotes
        ["Base.SmokeBomb"] = 500,
        ["Base.Molotov"] = 800,
        ["Base.Aerosolbomb"] = 2500,
        ["Base.FlameTrap"] = 2500,
        ["Base.PipeBomb"] = 3500,
        ["Base.AerosolbombTriggered"] = 4500,
        ["Base.AerosolbombRemote"] = 4500,
        ["Base.RemoteCraftedV1"] = 750,
        ["Base.RemoteCraftedV2"] = 1250,
        ["Base.RemoteCraftedV3"] = 2000,

        -- Base-critical equipment
        ["Base.PetrolCan"] = 3500,
        ["Base.Generator_Old"] = 5000,
        ["Base.Generator_Blue"] = 7500,
        ["Base.Generator"] = 9000,
        ["Base.Generator_Yellow"] = 12000,
        ["Base.Bag_ALICEpack_Army"] = 4500,

        -- Strong melee
        ["Base.Sledgehammer"] = 5000,
        ["Base.Axe"] = 1800,
        ["Base.WoodAxeForged"] = 2500,
        ["Base.PickAxeForged"] = 2500,
        ["Base.Machete"] = 3500,
        ["Base.Machete_Crude"] = 2800,
        ["Base.MacheteForged"] = 3800,
        ["Base.Sword"] = 6000,
        ["Base.Katana"] = 15000,

        -- Armor
        ["Base.Hat_RiotHelmet"] = 3000,
        ["Base.Hat_GasMask_nofilter"] = 3500,
        ["Base.Hat_GasMask"] = 5000,
        ["Base.Vest_BulletArmy"] = 9000,
        ["Base.Vest_BulletPolice"] = 9000,
        ["Base.Vest_BulletSWAT"] = 12000,
    }

    local bookLevelPrices = {
        [1] = 250,
        [2] = 500,
        [3] = 1000,
        [4] = 2000,
        [5] = 4000,
    }

    for _, offer in ipairs(PZLinuxDarkWebItemsTable) do
        local balancedPrice = offer.Price or 0
        for _, itemId in ipairs(offer.id or {}) do
            if exactPrices[itemId] then
                balancedPrice = math.max(balancedPrice, exactPrices[itemId])
            end

            local bookLevel = itemId:match("^Base%.Book.-([1-5])$")
            if bookLevel then
                balancedPrice = math.max(balancedPrice, bookLevelPrices[tonumber(bookLevel)])
            elseif itemId:match("^Base%.WeaponMag") then
                balancedPrice = math.max(balancedPrice, 5000)
            elseif itemId:match("^Base%.MechanicMag") then
                balancedPrice = math.max(balancedPrice, 3500)
            elseif itemId:match("^Base%.ArmorMag") then
                balancedPrice = math.max(balancedPrice, 3000)
            elseif itemId == "Base.ElectronicsMag4" then
                balancedPrice = math.max(balancedPrice, 5000)
            elseif itemId:match("^Base%.ElectronicsMag") then
                balancedPrice = math.max(balancedPrice, 2000)
            elseif itemId:match("^Base%.EngineerMagazine") then
                balancedPrice = math.max(balancedPrice, 3000)
            elseif itemId == "Base.KeyMag1" or itemId == "Base.HerbalistMag" then
                balancedPrice = math.max(balancedPrice, 2500)
            elseif itemId:match("Mag") then
                balancedPrice = math.max(balancedPrice, 1500)
            end
        end
        offer.Price = balancedPrice
    end
end

PZLinuxApplyDarkWebPriceBalance()
