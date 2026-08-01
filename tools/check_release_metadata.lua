local root = arg[1] or "."

local function PZLinuxReleaseRead(path)
    local file = assert(io.open(root .. "/" .. path, "rb"), "missing release file: " .. path)
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxReleaseAssert(condition, message)
    if not condition then error(message, 2) end
end

local readme = PZLinuxReleaseRead("README.md")
local workshop = PZLinuxReleaseRead("workshop.txt")
local overview = PZLinuxReleaseRead("doc/overview.md")
local modInfo = PZLinuxReleaseRead("Contents/mods/B42 PZLinux/42/mod.info")

for path, content in pairs({
    ["README.md"] = readme,
    ["workshop.txt"] = workshop,
    ["doc/overview.md"] = overview,
    ["42/mod.info"] = modInfo,
}) do
    PZLinuxReleaseAssert(not content:upper():find("BETA", 1, true), path .. " still contains BETA")
    PZLinuxReleaseAssert(not content:find("version=0%.1%."), path .. " still contains a 0.1.x version")
end

PZLinuxReleaseAssert(readme:find("%*%*Release:%*%* 1%.0%.0"), "README release is not 1.0.0")
PZLinuxReleaseAssert(overview:find("^version=1%.0%.0"), "overview release is not 1.0.0")
PZLinuxReleaseAssert(workshop:find("^version=1\n"), "workshop format version must remain 1")
PZLinuxReleaseAssert(workshop:find("\nvisibility=0\n?$"), "Workshop visibility must use public value 0")
PZLinuxReleaseAssert(modInfo:find("\nmodversion=1%.0%.0\n"), "mod.info has no 1.0.0 modversion")
PZLinuxReleaseAssert(modInfo:find("\nversionMin=42%.20\n"), "mod.info has no Build 42.20 minimum")
PZLinuxReleaseAssert(modInfo:find("\nid=B42_PZLinux\n"), "stable mod ID changed")

for _, term in ipairs({ "Poker", "Blackjack", "server", "controller", "split-screen" }) do
    PZLinuxReleaseAssert(workshop:lower():find(term:lower(), 1, true), "Workshop description is missing " .. term)
end

local commonInfo = io.open(root .. "/Contents/mods/B42 PZLinux/common/mod.info", "rb")
PZLinuxReleaseAssert(commonInfo == nil, "common/mod.info must not duplicate the versioned descriptor")
if commonInfo then commonInfo:close() end

print("PZLinux release metadata OK: v1.0.0, Build 42.20+, Workshop format 1")
