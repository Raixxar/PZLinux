local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_hacking_authority.lua$") or "."

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source
end

local sharedPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua"
local clientPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/Features/PZLinuxHacking.lua"
local serverPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/server/PZLinuxServerCommands.lua"

local sharedSource = readFile(sharedPath)
local clientSource = readFile(clientPath)
local serverSource = readFile(serverPath)

local startPosition = assert(sharedSource:find("function PZLinuxHackingStartManual", 1, true), "manual Hacking start function not found")
local autoPosition = assert(sharedSource:find("function PZLinuxHackingAuto", startPosition, true), "automatic Hacking function not found")
local startFunction = sharedSource:sub(startPosition, autoPosition - 1)
assert(startFunction:find("password = password", 1, true), "the server session must retain its password")
assert(startFunction:find("passwordLength = #password", 1, true), "the public response must expose only the password length")

local responsePosition = assert(startFunction:find("\n    return {\n        ok = true", 1, true), "manual Hacking response not found")
local responseBlock = startFunction:sub(responsePosition)
assert(not responseBlock:find("password =", 1, true), "manual Hacking response must not contain a password")
assert(not clientSource:find("result%.password%f[^%w_]"), "the client must not read a server password")
assert(not clientSource:find("serverPassword", 1, true), "the client must not store a server password")
assert(serverSource:find("PZLinuxHackingGuess%(player, args and args%.guess, args and args%.requestId%)"), "guesses must be evaluated by the server")

print("Hacking authority tests: OK")
