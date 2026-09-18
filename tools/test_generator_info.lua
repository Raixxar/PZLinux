-- The UI hook must preserve native fuel formatting for different capacities,
-- warnings and third-party additions, without mutating the generator.
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_generator_info.lua$") or "."
local data = {}
local player = { getModData = function() return data end }
PZLinuxGetPlayer = function() return player end
Events = setmetatable({}, { __index = function() return { Add = function() end } end })

local calls = 0
local expectedObject, expectedStats
local originalText
package.preload["ISUI/ISGeneratorInfoWindow"] = function()
    ISGeneratorInfoWindow = {
        getRichText = function(object, displayStats, sentinel)
            calls = calls + 1
            assert(object == expectedObject and displayStats == expectedStats)
            assert(sentinel == "forwarded", "extra arguments must reach the original renderer")
            return originalText
        end,
    }
end
dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/Features/PZLinuxUtils.lua")

local function render(active, stats, nativeText)
    expectedObject = { isActivated = function() return active end }
    expectedStats = stats
    originalText = nativeText
    local before = calls
    local result = ISGeneratorInfoWindow.getRichText(expectedObject, stats, "forwarded")
    assert(calls == before + 1, "native renderer must be called exactly once")
    assert(result:sub(1, #nativeText) == nativeText, "native information must remain intact")
    return result
end

data = { PZLinuxIsPowered = 1, ATMIsPowered = 1 }
-- Native output is deliberately opaque: PZLinux must not infer units or capacity.
for _, fuelText in ipairs({ "Fuel: 100% (10 L)", "Fuel: 100% (25 L)", "Fuel: 37.5%" }) do
    local native = fuelText .. " <LINE> Condition: 90% <LINE> Total: 0.12 L/h <LINE> <RED> Toxic / other mod"
    local result = render(true, true, native)
    assert(result:find("Desktop Computer (0.02 L/h)", 1, true))
    assert(result:find("ATM (0.01 L/h)", 1, true))
    assert(result:find("<RGB:1,1,1>", #native + 1, true), "reset warning color for added lines")
end
assert(render(false, true, "Off") == "Off")
assert(render(true, false, "Hidden stats / warning") == "Hidden stats / warning")
for _, flags in ipairs({ {}, { PZLinuxIsPowered = 0, ATMIsPowered = 0 } }) do
    data = flags
    assert(render(true, true, "Native only") == "Native only")
end
data = { PZLinuxIsPowered = 1 }
assert(not render(true, true, "Native"):find("ATM", 1, true))
data = { ATMIsPowered = 1 }
assert(not render(true, true, "Native"):find("Desktop Computer", 1, true))
player = nil
assert(render(true, true, "No local player") == "No local player")
print("PZLinux generator info tests OK")
