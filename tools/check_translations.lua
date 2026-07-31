local translateRoot = arg[1] or "Contents/mods/B42 PZLinux/42/media/lua/shared/Translate"
local locales = { "EN", "FR", "CS", "DE", "ES", "HU", "IT", "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RU", "TH", "TR", "UA", "CN", "CH" }

local function PZLinuxTranslationRead(path)
    local file, err = io.open(path, "rb")
    if not file then return nil, err end
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTranslationIsUtf8(value)
    local index = 1
    while index <= #value do
        local byte = value:byte(index)
        local count
        if byte <= 0x7F then count = 0
        elseif byte >= 0xC2 and byte <= 0xDF then count = 1
        elseif byte >= 0xE0 and byte <= 0xEF then count = 2
        elseif byte >= 0xF0 and byte <= 0xF4 then count = 3
        else return false end
        for offset = 1, count do
            local continuation = value:byte(index + offset)
            if not continuation or continuation < 0x80 or continuation > 0xBF then return false end
        end
        index = index + count + 1
    end
    return true
end

local function PZLinuxTranslationSignature(value)
    local signature = {}
    for placeholder in value:gmatch("%%[A-Za-z]") do table.insert(signature, placeholder) end
    for placeholder in value:gmatch("<[%w_]+>") do table.insert(signature, placeholder) end
    table.sort(signature)
    return table.concat(signature, "|")
end

local function PZLinuxTranslationParse(locale)
    local path = translateRoot .. "/" .. locale .. "/IG_UI_" .. locale .. ".txt"
    local content, err = PZLinuxTranslationRead(path)
    if not content then return nil, { path .. ": " .. tostring(err) } end

    local errors = {}
    if not PZLinuxTranslationIsUtf8(content) then table.insert(errors, path .. ": invalid UTF-8") end
    if not content:match("^IG_UI_" .. locale .. "%s*=%s*{") then
        table.insert(errors, path .. ": expected table IG_UI_" .. locale)
    end

    local entries = {}
    for lineNumber, line in ipairs((function()
        local lines = {}
        for current in (content .. "\n"):gmatch("(.-)\n") do table.insert(lines, current) end
        return lines
    end)()) do
        local key, literal = line:match("^%s*(IGUI_[%w_]+)%s*=%s*(\".*\")%s*,%s*$")
        if key then
            if entries[key] then
                table.insert(errors, path .. ":" .. lineNumber .. ": duplicate key " .. key)
            else
                local chunk, loadError = loadstring("return " .. literal)
                if not chunk then
                    table.insert(errors, path .. ":" .. lineNumber .. ": " .. tostring(loadError))
                else
                    local ok, value = pcall(chunk)
                    if ok and type(value) == "string" then entries[key] = value
                    else table.insert(errors, path .. ":" .. lineNumber .. ": invalid string for " .. key) end
                end
            end
        end
    end
    return entries, errors
end

local catalogs = {}
local allErrors = {}
for _, locale in ipairs(locales) do
    local entries, errors = PZLinuxTranslationParse(locale)
    catalogs[locale] = entries or {}
    for _, err in ipairs(errors or {}) do table.insert(allErrors, err) end
end

local english = catalogs.EN
for _, locale in ipairs(locales) do
    if locale ~= "EN" then
        for key, englishValue in pairs(english) do
            local translated = catalogs[locale][key]
            if translated == nil then
                table.insert(allErrors, locale .. ": missing key " .. key)
            elseif PZLinuxTranslationSignature(translated) ~= PZLinuxTranslationSignature(englishValue) then
                table.insert(allErrors, locale .. ": placeholder mismatch for " .. key)
            end
        end
        for key in pairs(catalogs[locale]) do
            if english[key] == nil then table.insert(allErrors, locale .. ": extra key " .. key) end
        end
    end
end

if #allErrors > 0 then
    for _, err in ipairs(allErrors) do io.stderr:write(err .. "\n") end
    io.stderr:write("Translation audit failed with " .. #allErrors .. " error(s).\n")
    os.exit(1)
end

print("Translation audit OK: " .. #locales .. " locales, " .. tostring((function()
    local count = 0
    for _ in pairs(english) do count = count + 1 end
    return count
end)()) .. " keys each.")
