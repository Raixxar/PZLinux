local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_reputation_economy.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
    end
end

PZLinux = {}
PZLinuxDarkWebItemsTable = {}
rawset(_G, "Perks", { PlantScavenging = "PlantScavenging" })
rawset(_G, "SandboxVars", { PZLinux = { PurchasePriceMultiplier = 1, SalePriceMultiplier = 1 } })
rawset(_G, "ZombRand", function(minimum) return minimum end)
local worldAgeHours = 0
rawset(_G, "getGameTime", function()
    return { getWorldAgeHours = function() return worldAgeHours end }
end)

dofile(luaRoot .. "/shared/PZLinux/PZLinuxConfig.lua")
dofile(luaRoot .. "/shared/PZLinux/PZLinuxEconomy.lua")

local player = {
    reputation = 1,
    getPerkLevel = function() return 0 end,
    getModData = function(self)
        return { pzlinux = { player = { reputation = self.reputation } } }
    end,
}
PZLinuxGetPlayer = function(value) return value end
-- PZLinuxGetReputationPurchaseMultiplier goes through PZLinuxGetModData
-- (see PZLinux.getModData's backup-key recovery, added in v1.0.8) rather
-- than a raw getModData() read; stub it the same shape the real one
-- returns (md, pzlinux, playerObj) for this isolated test.
PZLinuxGetModData = function(value)
    local md = value:getModData()
    return md, md.pzlinux, value
end

PZLinuxTestAssertEqual(PZLinux.Economy.contractCancelPenalty(), 10, "contract cancellation penalty")
PZLinuxTestAssertEqual(PZLinux.Economy.contractCompleteReward(), 10, "contract completion reputation")
PZLinuxTestAssertEqual(PZLinux.Economy.applyReputationDelta(1, -10), -9, "neutral cancellation reputation")
PZLinuxTestAssertEqual(PZLinux.Economy.applyReputationDelta(-95, -10), -99, "minimum reputation clamp")
PZLinuxTestAssertEqual(PZLinux.Economy.applyReputationDelta(195, 10), 200, "maximum reputation clamp")
PZLinuxTestAssertEqual(PZLinux.Economy.decayReputation(11, 1), 10, "positive reputation decay")
PZLinuxTestAssertEqual(PZLinux.Economy.decayReputation(-9, 1), -8, "negative reputation recovery")
PZLinuxTestAssertEqual(PZLinux.Economy.decayReputation(0.5, 1), 1, "negative recovery must stop at neutral")
PZLinuxTestAssertEqual(PZLinux.Economy.decayReputation(1.5, 1), 1, "positive decay must stop at neutral")

PZLinuxTestAssertEqual(PZLinux.Economy.reputationPurchaseMultiplier(1), 1, "neutral price multiplier")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationPurchaseMultiplier(-9), 1.1, "one cancellation surcharge")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationPurchaseMultiplier(101), 0.75, "maximum reputation discount")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationPurchaseMultiplier(-99), 2, "maximum reputation surcharge")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationTier(-50), "blacklisted", "blacklisted reputation tier")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationTier(1), "neutral", "neutral reputation tier")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationTier(41), "reliable", "reliable reputation tier")
PZLinuxTestAssertEqual(PZLinux.Economy.reputationTier(101), "preferred", "preferred reputation tier")

PZLinuxTestAssertEqual(PZLinux.Economy.scarcityMultiplier(0), 1, "new world scarcity")
PZLinuxTestAssertEqual(PZLinux.Economy.scarcityMultiplier(2189), 1, "first quarter scarcity")
PZLinuxTestAssertEqual(PZLinux.Economy.scarcityMultiplier(2191), 2, "second quarter scarcity")
PZLinuxTestAssertEqual(PZLinux.Economy.scarcityMultiplier(17520), 8, "two-year scarcity")
PZLinuxTestAssertEqual(PZLinux.Economy.scarcityMultiplier(87600), 8, "long-world scarcity cap")

PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(47, "buy"), 50, "small purchase rounds up to five")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(47, "sell"), 45, "small resale rounds down to five")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(48, "nearest"), 50, "small reward rounds to nearest five")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(4567, "buy"), 4600, "medium purchase rounds up to fifty")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(4567, "sell"), 4550, "medium resale rounds down to fifty")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(4322, "nearest"), 4300, "medium reward rounds to nearest fifty")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(14132, "nearest"), 14100, "large reward rounds to nearest hundred")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(83247, "buy"), 83500, "premium purchase rounds up to five hundred")
PZLinuxTestAssertEqual(PZLinux.Economy.roundPrice(83247, "sell"), 83000, "premium resale rounds down to five hundred")

local itemData = { Price = 1000 }
player.reputation = 1
PZLinuxTestAssertEqual(PZLinuxDarkWebCalculateBuyPrice(player, itemData), 1000, "neutral Dark Web price")
player.reputation = -9
PZLinuxTestAssertEqual(PZLinuxDarkWebCalculateBuyPrice(player, itemData), 1100, "penalized Dark Web price")
player.reputation = 11
PZLinuxTestAssertEqual(PZLinuxDarkWebCalculateBuyPrice(player, itemData), 980, "rewarded Dark Web price")

local request = { price = 1000 }
player.reputation = 1
PZLinuxTestAssertEqual(PZLinuxRequestsCalculateUnitPrice(player, request), 990, "neutral Request price")
player.reputation = -9
PZLinuxTestAssertEqual(PZLinuxRequestsCalculateUnitPrice(player, request), 1100, "penalized Request price")
player.reputation = 11
PZLinuxTestAssertEqual(PZLinuxRequestsCalculateUnitPrice(player, request), 970, "rewarded Request price")

worldAgeHours = 17520
player.reputation = 1
PZLinuxTestAssertEqual(PZLinuxDarkWebCalculateBuyPrice(player, itemData), 8000, "two-year Dark Web scarcity price")
PZLinuxTestAssertEqual(PZLinuxRequestsCalculateUnitPrice(player, request), 7950, "two-year Request scarcity price")

local runtimeFile = assert(io.open(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua", "rb"))
local runtimeSource = runtimeFile:read("*a")
runtimeFile:close()
local formatterSource = runtimeSource:match("(function PZLinuxFormatText.-\nend)\n\nPZLinux%.callbacks")
assert(formatterSource and loadstring(formatterSource))()

-- Regression test for a real gameplay bug: an earlier version of this
-- formatter called the native getText(key, ...) with extra arguments,
-- assuming the native translator would substitute "%s" placeholders with
-- disposable markers so the real values could be gsub'd in afterward. In
-- real gameplay, several multi-argument reputation lines (Score, Status,
-- Purchase prices, Mail frequency, ...) rendered with their values silently
-- missing -- no error, no exception, just blank substitutions -- while the
-- very last line on the same screen (Next status) worked fine. getText must
-- therefore now only ever be called with the bare key (zero arguments); all
-- substitution happens here in Lua via gsub against whatever getText(key)
-- alone returns.
local nativeTemplates = {
    score = "Score : %s (de %s à %s)",
    status = "Statut : %s",
}
local getTextCallArgCounts = {}
getText = function(key, ...)
    table.insert(getTextCallArgCounts, select("#", ...))
    return nativeTemplates[key] or key
end
PZLinuxTestAssertEqual(PZLinuxFormatText("score", "Score: %s (%s/%s)", 31, -99, 200),
    "Score : 31 (de -99 à 200)", "translated reputation values must be substituted purely in Lua")
PZLinuxTestAssertEqual(PZLinuxFormatText("status", "Status: %s", "FIABLE"),
    "Statut : FIABLE", "a single translated value must also be substituted purely in Lua")
for _, argCount in ipairs(getTextCallArgCounts) do
    PZLinuxTestAssertEqual(argCount, 0,
        "getText must never be called with extra arguments -- that is exactly what silently dropped values in real gameplay")
end
local cancelBlock = runtimeSource:match("function PZLinuxContractsApplyCancel.-\nend")
assert(cancelBlock and cancelBlock:find('error = "no_active_contract"'), "forged cancellation without an active contract must be rejected")
assert(cancelBlock and cancelBlock:find("PZLinuxApplyReputationDelta%(playerObj, %-reputationPenalty%)"),
    "contract cancellation must apply its penalty on the server")
assert(cancelBlock and cancelBlock:find("reputation = reputation"), "the authoritative reputation must be returned to the client")
local snapshotBlock = runtimeSource:match("function PZLinuxReputationGetSnapshot.-\nend")
assert(snapshotBlock and snapshotBlock:find("reputationPurchaseMultiplier", 1, true),
    "the reputation screen must use the authoritative economy multiplier")
assert(snapshotBlock and not snapshotBlock:find("mailDelayMax", 1, true),
    "the reputation snapshot must not reveal the randomized mail delay")

local serverFile = assert(io.open(luaRoot .. "/server/PZLinuxServerCommands.lua", "rb"))
local serverSource = serverFile:read("*a")
serverFile:close()
assert(serverSource:find("PZLinuxReputationSnapshot = PZLinuxServerReputationSnapshot", 1, true),
    "the authoritative reputation snapshot command must be registered")

local reputationUiFile = assert(io.open(luaRoot .. "/client/Context/World/Features/PZLinuxReputation.lua", "rb"))
local reputationUiSource = reputationUiFile:read("*a")
reputationUiFile:close()
assert(reputationUiSource:find("PZLinuxRequestReputationSnapshot", 1, true),
    "the reputation UI must request its values from the server")
assert(reputationUiSource:find("PZLinuxFormatText%(key, fallback, %.%.%.%)"),
    "the reputation UI must use the shared placeholder-safe formatter")
assert(runtimeSource:find("function PZLinuxFormatText")
    and not runtimeSource:find("pcall%(getText, key, unpack"),
    "getText must never be called with extra arguments (that silently dropped values in real gameplay); " ..
    "all substitution must happen in Lua via gsub against a bare getText(key) lookup")
assert(reputationUiSource:find("PZLinuxReputationRoundedNumber%(snapshot%.reputation%)")
    and reputationUiSource:find("PZLinuxReputationRoundedNumber%(snapshot%.pointsToNext%)"),
    "the reputation UI must display whole reputation values without floating-point noise")
assert(not reputationUiSource:find("mailDelayMax", 1, true) and not reputationUiSource:find("nextat", 1, true),
    "the reputation UI must keep future mail timing hidden")

-- Regression test for a real gameplay bug: ISRichTextPanel:paginate()
-- (the native game class) tokenizes on spaces. A word glued directly to a
-- following <LINE> tag with no space in between gets swallowed by the
-- tag's token and is never rendered -- this silently dropped the very
-- value at the end of almost every reputation line (Score, Status,
-- Purchase prices, Mail frequency, Completion gain, Cancel penalty, Decay),
-- since each one ends with its substituted value immediately before the
-- next <LINE>. table.concat(lines, "<LINE>") must always be
-- table.concat(lines, " <LINE> ") instead -- exactly what the engine
-- itself inserts when converting "\n" -- or the last word of every line
-- but the final one silently disappears.
assert(reputationUiSource:find('table%.concat%(lines, " <LINE> "%)'),
    "reputation lines must be joined with spaced <LINE> tags, or ISRichTextPanel silently drops the last word of every line but the final one")
local contractsUiFile = assert(io.open(luaRoot .. "/client/Context/World/Features/PZLinuxContracts.lua", "rb"))
local contractsUiSource = contractsUiFile:read("*a")
contractsUiFile:close()
assert(contractsUiSource:find('table%.concat%(lines, " <LINE> "%)'),
    "the contract completion receipt lines must be joined with spaced <LINE> tags, for the same reason")

local contractPriceBlock = runtimeSource:match("function PZLinuxContractsBuildContract.-\nend")
assert(contractPriceBlock and not contractPriceBlock:find("scarcityMultiplier", 1, true),
    "world scarcity must not inflate contract rewards")
assert(contractPriceBlock and contractPriceBlock:find('roundPrice%(.-, "nearest"%)'),
    "contract board rewards must use the shared nearest-price rounding")

local economyFile = assert(io.open(luaRoot .. "/shared/PZLinux/PZLinuxEconomy.lua", "rb"))
local economySource = economyFile:read("*a")
economyFile:close()
local tradingBlock = economySource:match("function PZLinuxTradingCalculateTransaction.-\nend")
assert(tradingBlock and not tradingBlock:find("roundPrice", 1, true),
    "trading transactions and fees must keep exact amounts")

print("PZLinux reputation economy tests OK")
