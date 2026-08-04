dofile("Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxMissionLocations.lua")

local function count(list)
    local total = 0
    for _, location in ipairs(list or {}) do
        if location.enabled ~= false then
            total = total + 1
        end
    end
    return total
end

local function countByCity(pool)
    local total = 0
    for _, list in pairs((pool or {}).byCityId or {}) do
        total = total + count(list)
    end
    return total
end

local pools = PZLinux.MissionLocations.pools
local checks = {
    { name = "packages", total = countByCity(pools.packages) },
    { name = "cargo", total = countByCity(pools.cargo) },
    { name = "manhunt", total = countByCity(pools.manhunt) },
    { name = "protect", total = countByCity(pools.protect) },
    { name = "vehicles", total = countByCity(pools.vehicles) },
    { name = "mailDrops.ammo", total = countByCity(pools.mailDrops.ammo) },
    { name = "mailDrops.medical", total = countByCity(pools.mailDrops.medical) },
}

local hasWarning = false
print("PZLinux mission locations audit - " .. tostring(PZLinux.MissionLocations.mapBuild))
for _, check in ipairs(checks) do
    local status = check.total > 0 and "OK" or "EMPTY"
    if status == "EMPTY" then hasWarning = true end
    print(string.format("%-18s %s (%d)", check.name, status, check.total))
end

print("")
print("By city")
for cityId, cityName in ipairs(PZLinux.MissionLocations.cities or {}) do
    print(string.format("%02d %-15s packages=%d cargo=%d manhunt=%d protect=%d vehicles=%d ammo=%d medical=%d",
        cityId,
        cityName,
        count((pools.packages.byCityId or {})[cityId]),
        count((pools.cargo.byCityId or {})[cityId]),
        count((pools.manhunt.byCityId or {})[cityId]),
        count((pools.protect.byCityId or {})[cityId]),
        count((pools.vehicles.byCityId or {})[cityId]),
        count((pools.mailDrops.ammo.byCityId or {})[cityId]),
        count((pools.mailDrops.medical.byCityId or {})[cityId])))
end

if hasWarning then
    os.exit(1)
end
