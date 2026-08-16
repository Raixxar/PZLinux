local root = arg[1] or "."
local menuPath = root .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/ISContextLinuxMenu.lua"

local file = assert(io.open(menuPath, "rb"))
local source = file:read("*a")
file:close()

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local requiredKeys = {
    "Welcome", "NotConnected", "Connected", "Connect", "DarkWeb",
    "Trading", "Wallet", "HackCard", "Contracts", "BuyGoods",
    "OnlineBetting", "Mail", "CheckCondition", "Training", "ConnectFirst",
}
for _, suffix in ipairs(requiredKeys) do
    PZLinuxTestAssert(source:find('"IGUI_PZLinux_Main_' .. suffix .. '"', 1, true),
        "main computer UI does not use translation key " .. suffix)
end

for _, hardcoded in ipairs({
    '"NOT CONNECTED"', '"CONNECTED"', '"DARK WEB"', '"TRADING"',
    '"WALLET"', '"HACK A CREDIT CARD"', '"CONTRACTS"', '"BUY GOODS"',
    '"ONLINE BETTING"', '"MAIL"', '"CHECK CONDITION"', '"TRAINING"',
}) do
    PZLinuxTestAssert(not source:find(hardcoded, 1, true),
        "main computer UI still contains hardcoded label " .. hardcoded)
end

PZLinuxTestAssert(not source:find("You need to connect first", 1, true),
    "main computer UI still contains a hardcoded connection warning")

print("PZLinux main computer UI translation tests OK")
