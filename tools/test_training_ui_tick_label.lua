-- Regression test for a player-reported log-spam bug: Training's active-
-- course label was rebuilt -- and its underlying translation key
-- re-looked-up -- on every ~500ms tick response while a course was in
-- progress, even though the course name never actually changes between
-- ticks (only the progress bar does). Since that translation string
-- contains a raw "%s" ("In progress: %s"), every such lookup also made
-- Project Zomboid's own native Translator log a
-- "Translator.reportMissingArgumentsFromPastAbuse" warning (it defensively
-- tries to format the raw string itself, before PZLinux's own gsub-based
-- substitution ever runs -- see PZLinuxGetText/PZLinuxFormatText in
-- ISPZLinuxVariablesTables.lua for why PZLinux deliberately never passes
-- real arguments to the native getText() call). At twice a second for a
-- multi-hour course, this was real noise in exactly the docker logs -f
-- output this mod's logging pass was meant to keep clean.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_training_ui_tick_label.lua$") or "."
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

local source = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxTraining.lua")
local applyStateBlock = source:match("function trainingUI:applyState.-\nend")
PZLinuxTestAssert(applyStateBlock, "trainingUI:applyState must exist")

-- PZLinuxTrainingFormat (the real "{1}"-style substitution helper, used
-- instead of native getText()+"%s" specifically to avoid triggering the
-- game's own Translator warning/exception on every lookup -- see its own
-- comment at the top of PZLinuxTraining.lua) is a plain module-local
-- function, not one of trainingUI's methods -- extract and register it
-- as a global too, since applyState calls it by bare name.
local formatBlock = source:match("local function PZLinuxTrainingFormat.-\nend\n"):gsub("^local function", "function", 1)
assert(loadstring(formatBlock))()

local getTextCalls = {}
PZLinuxGetText = function(key)
    getTextCalls[key] = (getTextCalls[key] or 0) + 1
    return "In progress: {1}"
end
PZLinuxTrainingResolveOffer = function(courseId)
    return { nameKey = "IGUI_Skill_" .. tostring(courseId) }
end
saveAtmBalance = function() end

local function newFakeLabel()
    return {
        setVisible = function() end,
        setName = function() end,
    }
end
local function newFakeProgressBar()
    return {
        setVisible = function() end,
        setProgress = function() end,
        setText = function() end,
    }
end
local function newFakeButton()
    return { setVisible = function() end }
end
local function newFakeOfferRows()
    return {
        { card = newFakeButton(), name = newFakeLabel(), detail = newFakeLabel() },
        { card = newFakeButton(), name = newFakeLabel(), detail = newFakeLabel() },
        { card = newFakeButton(), name = newFakeLabel(), detail = newFakeLabel() },
    }
end

local transformed = applyStateBlock:gsub("^function trainingUI:applyState%(state%)", "return function(self, state)", 1)
local applyState = assert(loadstring(transformed))()

local self = {
    activeLabel = newFakeLabel(),
    progressBar = newFakeProgressBar(),
    statusLabel = newFakeLabel(),
    offerRows = newFakeOfferRows(),
    confirmLabel = newFakeLabel(),
    payButton = newFakeButton(),
    cancelButton = newFakeButton(),
    player = "mock-player",
    startTickLoop = function() end,
    stopTickLoop = function() end,
    -- applyState's "no active course" branch delegates rendering to
    -- refreshOfferView (a separate method, exercised in full by
    -- test_training_ui_offer_selection.lua) -- a no-op stub is enough
    -- here since this test only cares about the InProgress-label
    -- dedup behavior in the ACTIVE-course branch above.
    refreshOfferView = function() end,
}

-- A course starting must resolve the In Progress label exactly once.
applyState(self, { active = { courseId = "Fishing_100", progress = 0.1 } })
PZLinuxTestAssert(getTextCalls["IGUI_PZLinux_Training_InProgress"] == 1,
    "starting a course must resolve the In Progress label once")

-- Repeated tick responses for the SAME course must never re-trigger the
-- translation lookup -- only the progress bar (not asserted here, already
-- covered by manual play-testing) should actually change.
applyState(self, { active = { courseId = "Fishing_100", progress = 0.3 } })
applyState(self, { active = { courseId = "Fishing_100", progress = 0.9 } })
PZLinuxTestAssert(getTextCalls["IGUI_PZLinux_Training_InProgress"] == 1,
    "repeated ticks for the same active course must not re-look-up the In Progress translation")

-- A genuinely different active course (panel reopened mid-course showing
-- a different one, or a new course started right after) must still
-- refresh the label.
applyState(self, { active = { courseId = "Electrical_200", progress = 0.0 } })
PZLinuxTestAssert(getTextCalls["IGUI_PZLinux_Training_InProgress"] == 2,
    "a genuinely different active course must still refresh the label")

-- Once no course is active, the tracked course id must be cleared, so
-- starting a course again later (even the same one) correctly refreshes
-- the label instead of being permanently skipped.
applyState(self, {})
applyState(self, { active = { courseId = "Electrical_200", progress = 0.0 } })
PZLinuxTestAssert(getTextCalls["IGUI_PZLinux_Training_InProgress"] == 3,
    "starting a course again after finishing/leaving must refresh the label, not be silently skipped forever")

print("PZLinux Training UI tick label tests OK")
