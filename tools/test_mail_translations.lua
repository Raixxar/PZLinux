-- Regression test for a real gameplay request: mail mission bodies (Ammo,
-- Medical, and the flavor ADS spam) were 100% hardcoded English prose,
-- never routed through the translation catalog like the rest of the mod.
-- This guards two things: (1) the Lua source now calls PZLinuxFormatText
-- with a stable key instead of string.format directly, and (2) every one
-- of the 20 language IG_UI.json files actually has all 26 keys, each with
-- exactly the placeholder count the call site passes -- since
-- PZLinuxFormatText fills %s occurrences strictly in call order, a missing
-- or extra %s in translated text silently misplaces or drops a value.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_mail_translations.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- Minimal strict JSON object-of-strings parser (same shape as every
-- IG_UI.json file): validates the file is well-formed and returns a table
-- of key -> decoded string value.
local function parseJsonObject(s)
    local i, n = 1, #s
    local function skipws() while i <= n and s:sub(i, i):match("%s") do i = i + 1 end end
    local function expect(c)
        if s:sub(i, i) ~= c then error("expected " .. c .. " at byte " .. i) end
        i = i + 1
    end
    local function parseString()
        expect("\"")
        local buf = {}
        while true do
            local c = s:sub(i, i)
            if c == "" then error("unterminated string at byte " .. i) end
            if c == "\"" then i = i + 1 break end
            if c == "\\" then
                local nx = s:sub(i + 1, i + 1)
                if nx == "n" then table.insert(buf, "\n")
                elseif nx == "t" then table.insert(buf, "\t")
                elseif nx == "\"" then table.insert(buf, "\"")
                elseif nx == "\\" then table.insert(buf, "\\")
                elseif nx == "/" then table.insert(buf, "/")
                elseif nx == "r" then table.insert(buf, "\r")
                else error("unsupported escape \\" .. nx .. " at byte " .. i) end
                i = i + 2
            else
                table.insert(buf, c)
                i = i + 1
            end
        end
        return table.concat(buf)
    end

    skipws(); expect("{"); skipws()
    local obj = {}
    if s:sub(i, i) == "}" then return obj end
    while true do
        skipws()
        local key = parseString()
        skipws(); expect(":"); skipws()
        obj[key] = parseString()
        skipws()
        local c = s:sub(i, i)
        if c == "," then i = i + 1
        else expect("}") break end
    end
    return obj
end

-- Placeholder counts must match the argument count each Lua call site
-- passes to PZLinuxFormatText, in this exact order.
local expectedPlaceholders = {
    MailAmmo_1 = 5, MailAmmo_2 = 5, MailAmmo_3 = 5,
    MailMedical_1 = 5, MailMedical_2 = 5, MailMedical_3 = 5,
    MailAds_1 = 2, MailAds_2 = 2, MailAds_3 = 1, MailAds_4 = 2, MailAds_5 = 2,
    MailAds_6 = 2, MailAds_7 = 1, MailAds_8 = 1, MailAds_9 = 2, MailAds_10 = 1,
    MailAds_11 = 1, MailAds_12 = 2, MailAds_13 = 1, MailAds_14 = 1, MailAds_15 = 2,
    MailAds_16 = 1, MailAds_17 = 1, MailAds_18 = 2, MailAds_19 = 1, MailAds_20 = 1,
}

local languages = {
    "CH", "CN", "CS", "DE", "EN", "ES", "FR", "HU", "IT", "JP",
    "KO", "NL", "NO", "PL", "PT", "PTBR", "RU", "TH", "TR", "UA",
}

for _, lang in ipairs(languages) do
    local path = luaRoot .. "/shared/Translate/" .. lang .. "/IG_UI.json"
    local content = readFile(path)
    local ok, obj = pcall(parseJsonObject, content)
    assert(ok, lang .. "/IG_UI.json is not valid JSON: " .. tostring(obj))

    for key, expectedCount in pairs(expectedPlaceholders) do
        local fullKey = "IGUI_PZLinux_" .. key
        local value = obj[fullKey]
        assert(value, lang .. " is missing " .. fullKey)
        local _, actualCount = value:gsub("%%s", "")
        assert(actualCount == expectedCount, string.format(
            "%s/%s has %d placeholder(s), expected %d -- PZLinuxFormatText " ..
            "fills %%s occurrences strictly in call order, so a wrong count " ..
            "silently misplaces or drops a value",
            lang, fullKey, actualCount, expectedCount))
    end
end

-- The Lua call sites must actually use the translation catalog now,
-- not build the message with a raw string.format.
for _, relativePath in ipairs({
    "/client/Context/World/Mails/PZLinuxMailAmmo.lua",
    "/client/Context/World/Mails/PZLinuxMailMedical.lua",
    "/client/Context/World/Mails/PZLinuxMailADS.lua",
}) do
    local source = readFile(luaRoot .. relativePath)
    assert(not source:find("string.format([[", 1, true),
        relativePath .. " must build mail bodies through PZLinuxFormatText, not a raw string.format literal")
    assert(source:find("PZLinuxFormatText(\"IGUI_PZLinux_Mail", 1, true),
        relativePath .. " must call PZLinuxFormatText with a stable translation key")
end

print("PZLinux mail translation tests OK")
