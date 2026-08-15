-- Regression test for an explicit requirement: server logs added for live
-- monitoring (docker logs -f) must cover every feature EXCEPT the actual
-- Hacking password -- that must stay exclusively in-session, server-side,
-- never printed anywhere, in any form (not the password itself, not a
-- player's guess, not the correct/misplaced digit breakdown that could be
-- used to reconstruct it across attempts).
--
-- This test both confirms the privacy requirement (no sensitive value
-- ever appears in a print() call in the Hacking functions) and that
-- logging coverage genuinely exists (each function actually has a log
-- line, not just "no leaks because nothing is logged at all").

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_hacking_log_privacy.lua$") or "."
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

local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")

local function extract(pattern)
    local block = variablesSource:match(pattern)
    assert(block, "pattern not found: " .. pattern)
    return block
end

local functionsToCheck = {
    { name = "PZLinuxHackingStartManual", block = extract("function PZLinuxHackingStartManual.-\nend\n") },
    { name = "PZLinuxHackingAuto", block = extract("function PZLinuxHackingAuto.-\nend\n") },
    { name = "PZLinuxHackingGuess", block = extract("function PZLinuxHackingGuess.-\nend\n") },
    { name = "PZLinuxHackingTransfer", block = extract("function PZLinuxHackingTransfer.-\nend\n") },
    { name = "PZLinuxHackingBuildGuessFeedback", block = extract("function PZLinuxHackingBuildGuessFeedback.-\nend\n") },
}

-- ---------------------------------------------------------------------
-- 1. Coverage: START (manual/auto) and TRANSFER must each have a print()
-- call -- the money-moving lifecycle events an admin watching the logs
-- would want visibility into.
-- ---------------------------------------------------------------------

for _, entry in ipairs({ "PZLinuxHackingStartManual", "PZLinuxHackingAuto", "PZLinuxHackingGuess", "PZLinuxHackingTransfer" }) do
    local found = false
    for _, fn in ipairs(functionsToCheck) do
        if fn.name == entry then found = fn.block:find("print(", 1, true) ~= nil end
    end
    PZLinuxTestAssert(found, entry .. " must log its outcome for live server monitoring")
end

-- ---------------------------------------------------------------------
-- 2. Privacy: extract every print(...) call within each function and
-- confirm none of them reference the password, a guess, or the
-- correct/misplaced breakdown.
-- ---------------------------------------------------------------------

local forbiddenTokens = {
    "session.password", "%.password", "passwordStr", "guessDigits",
    "realDigits", "correctCount", "misplacedCount", "revealedPassword",
    "tostring(guess)",
}

for _, fn in ipairs(functionsToCheck) do
    for printCall in fn.block:gmatch("print%(.-%)%s*\n") do
        for _, token in ipairs(forbiddenTokens) do
            PZLinuxTestAssert(not printCall:find(token),
                fn.name .. " has a print() call that references " .. token ..
                " -- the hacking code must never be logged, directly or indirectly")
        end
    end
    -- Belt and suspenders: even outside a strictly-matched print(...) call
    -- (multi-line string.format arguments can defeat a naive single-call
    -- regex), the function body as a whole must never mention these.
    for _, token in ipairs(forbiddenTokens) do
        local mentionsToken = fn.block:find(token, 1, true) ~= nil
        local isDefinitionSite = fn.name == "PZLinuxHackingBuildGuessFeedback"
        if mentionsToken and not isDefinitionSite then
            error(fn.name .. " unexpectedly references " .. token .. " -- verify no log line was added referencing it", 0)
        end
    end
end

print("PZLinux hacking log privacy tests OK")
