local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_trading_fee.lua$") or "."

PZLinux = {}
PZLinuxDarkWebItemsTable = {}

dofile(repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxEconomy.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

assertEqual(PZLinuxTradingGetFeeRate(), 0.05, "default fee rate")
assertEqual(PZLinuxTradingCalculateFee(1000), 50, "five percent fee")
assertEqual(PZLinuxTradingCalculateFee(1), 1, "minimum rounded fee")
assertEqual(PZLinuxTradingCalculateFee(0), 0, "zero amount fee")

local buy = PZLinuxTradingCalculateTransaction(1000, "buy")
assertEqual(buy.grossAmount, 1000, "buy gross")
assertEqual(buy.fee, 50, "buy fee")
assertEqual(buy.netAmount, 1050, "buy debit")

local sell = PZLinuxTradingCalculateTransaction(1000, "sell")
assertEqual(sell.grossAmount, 1000, "sell gross")
assertEqual(sell.fee, 50, "sell fee")
assertEqual(sell.netAmount, 950, "sell credit")

local roundedSell = PZLinuxTradingCalculateTransaction(101, "sell")
assertEqual(roundedSell.fee, 6, "fee rounds up")
assertEqual(roundedSell.netAmount, 95, "rounded sell credit")

local runtimePath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua"
local runtimeFile = assert(io.open(runtimePath, "rb"))
local runtimeSource = runtimeFile:read("*a")
runtimeFile:close()

local clientPath = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua/client/Context/World/Features/PZLinuxTrading.lua"
local clientFile = assert(io.open(clientPath, "rb"))
local clientSource = clientFile:read("*a")
clientFile:close()

assert(runtimeSource:find('PZLinuxTradingCalculateTransaction%(price %* quantity, "buy"%)'), "buy must calculate its fee on the authoritative price")
assert(runtimeSource:find('PZLinuxApplyBankDebit%(playerObj, transaction%.netAmount, "trading%-buy", requestId%)'), "buy must debit the fee-inclusive amount")
assert(runtimeSource:find('PZLinuxTradingCalculateTransaction%(price %* quantity, "sell"%)'), "sell must calculate its fee on the authoritative price")
assert(runtimeSource:find('PZLinuxApplyBankCredit%(playerObj, transaction%.netAmount, "trading%-sell", requestId%)'), "sell must credit the fee-adjusted amount")
assert(not runtimeSource:find('PZLinuxSendClientCommand%("PZLinuxTradingBuy",[^\n]-fee'), "the client must not send a buy fee")
assert(not runtimeSource:find('PZLinuxSendClientCommand%("PZLinuxTradingSell",[^\n]-fee'), "the client must not send a sell fee")
assert(runtimeSource:find("function PZLinuxUpdateTradingPrices%(player%)"), "the shared runtime must own the update wrapper")
assert(runtimeSource:find("function PZLinuxTrading_initializePrices%(player%)"), "the shared runtime must own the initialization wrapper")
assert(runtimeSource:find("PZLinuxRequestTradingSnapshot%(player or PZLinuxGetPlayer%(%)"), "client wrappers must request the server snapshot")
assert(not clientSource:find("function PZLinuxUpdateTradingPrices", 1, true), "the client must not redefine the update wrapper")
assert(not clientSource:find("function PZLinuxTrading_initializePrices", 1, true), "the client must not redefine the initialization wrapper")

print("Trading fee tests: OK")
