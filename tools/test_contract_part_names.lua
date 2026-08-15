-- Regression test for a player-reported issue: an Auto Parts contract's
-- request text didn't say whether a Standard/Sport/Resistant part was
-- needed. Confirmed root cause: PZ's own vanilla item name is IDENTICAL
-- across all three quality tiers of a given part (e.g. Base.NormalSuspension1
-- /2/3 all display as "Suspension - Regular" -- see
-- media/lua/shared/Translate/EN/ItemName.json), so PZLinuxContractsLocalizedItemName
-- trying the vanilla name FIRST and only falling back to the mod's own
-- curated, disambiguating name if that failed (it essentially never does)
-- meant the curated name was never actually used. Also found along the
-- way: three Weapon request names (Pistol3/Revolver_Short/Revolver) were
-- stale B41-era nicknames no longer matching these items' current B42
-- vanilla names. And since the mod's curated names are shown in the
-- physical contract note regardless of this dialogue-side fix, they now
-- go through a translation key (PZLinuxGetText) instead of being
-- hardcoded English, in all 20 supported languages.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_contract_part_names.lua$") or "."
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
-- 1. PZLinuxContractsLocalizedItemName: functional test of the priority
-- flip, using a real (ambiguous) vanilla item name as the "vanilla result"
-- and a distinct curated fallback.
-- ---------------------------------------------------------------------

local contractsSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxContracts.lua")
local localizedNameBlock = contractsSource:match("local function PZLinuxContractsLocalizedItemName.-\nend")
PZLinuxTestAssert(localizedNameBlock, "PZLinuxContractsLocalizedItemName must exist")

rawget(_G, "getItemNameFromFullType")
getItemNameFromFullType = function(_itemType) return "Suspension - Regular" end
getScriptManager = function()
    return { FindItem = function(_, _itemType) return { getDisplayName = function() return "Suspension - Regular" end } end }
end
assert(loadstring((localizedNameBlock:gsub("^local function", "function", 1))))()

PZLinuxTestAssert(
    PZLinuxContractsLocalizedItemName("Base.NormalSuspension2", "Standard suspension: Sport") == "Standard suspension: Sport",
    "a curated fallback name must win over PZ's own (possibly ambiguous) vanilla item name when provided")
PZLinuxTestAssert(
    PZLinuxContractsLocalizedItemName("Base.NormalSuspension2", "") == "Suspension - Regular",
    "with no curated fallback, the vanilla item name must still be used as before")
PZLinuxTestAssert(
    PZLinuxContractsLocalizedItemName("Base.NormalSuspension2", nil) == "Suspension - Regular",
    "a nil fallback must behave the same as an empty one")

print("PZLinux contract part name resolution tests OK")

-- ---------------------------------------------------------------------
-- 2. Data tables: every entry uses a translation key now, none left as a
-- hardcoded "name" string; the three stale weapon names are fixed.
-- ---------------------------------------------------------------------

local requestDataSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxContractRequestData.lua")
PZLinuxTestAssert(not requestDataSource:find('%f[%w]name%s*=%s*"'),
    "no contract request entry should still have a hardcoded name field -- every one must use nameKey")

for _, entry in ipairs({
    { key = "IGUI_PZLinux_ContractPart_Pistol3", oldStale = "D-E Pistol" },
    { key = "IGUI_PZLinux_ContractPart_RevolverShort", oldStale = "M36 Revolver" },
    { key = "IGUI_PZLinux_ContractPart_Revolver", oldStale = "M625 Revolver" },
}) do
    PZLinuxTestAssert(requestDataSource:find(entry.key, 1, true),
        "the request data table must reference " .. entry.key)
end

-- ---------------------------------------------------------------------
-- 3. PZLinuxContractsBuildMission resolves each request's name through
-- PZLinuxGetText (so it's actually translated), for all three contract
-- types that use this system.
-- ---------------------------------------------------------------------

local missionSource = readFile(luaRoot .. "/shared/PZLinux/PZLinuxContractMission.lua")
local _, resolvedCount = missionSource:gsub("mission%.infoName = PZLinuxGetText%(request%.nameKey%)", "")
PZLinuxTestAssert(resolvedCount == 3,
    "all three item-request contract types (Auto Parts, Medical, Weapon) must resolve " ..
    "mission.infoName through PZLinuxGetText(request.nameKey), found " .. resolvedCount)

-- ---------------------------------------------------------------------
-- 4. Every nameKey referenced by the three data tables must have both an
-- English fallback (PZLinux.TextFallbacks) and a translation in all 20
-- supported languages.
-- ---------------------------------------------------------------------

local nameKeys = {}
for key in requestDataSource:gmatch('nameKey%s*=%s*"([^"]+)"') do
    table.insert(nameKeys, key)
end
PZLinuxTestAssert(#nameKeys == 46, "expected 46 contract part name keys across the three request pools, found " .. #nameKeys)

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local fallbackBlock = variablesSource:match("PZLinux%.TextFallbacks = PZLinux%.TextFallbacks or %{.-\n%}")
PZLinuxTestAssert(fallbackBlock, "the shared text fallback table must exist")
for _, key in ipairs(nameKeys) do
    PZLinuxTestAssert(fallbackBlock:find(key, 1, true),
        "PZLinux.TextFallbacks must define an English fallback for " .. key)
end

local languages = { "CH", "CN", "CS", "DE", "EN", "ES", "FR", "HU", "IT", "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RU", "TH", "TR", "UA" }
for _, lang in ipairs(languages) do
    local path = luaRoot .. "/shared/Translate/" .. lang .. "/IG_UI.json"
    local content = readFile(path)
    for _, key in ipairs(nameKeys) do
        PZLinuxTestAssert(content:find('"' .. key .. '"', 1, true),
            lang .. "/IG_UI.json must define " .. key)
    end
end

print("PZLinux contract part name translation tests OK")
