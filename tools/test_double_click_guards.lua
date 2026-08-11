-- Regression test for a proactive audit (no player report yet): several
-- money-moving buttons never disabled themselves during their server round
-- trip, unlike almost every other buy/sell/confirm button in the mod (Dark
-- Web, Sell Surplus, ATM, Race, Blackjack/Poker). A double-click (or a
-- mechanical mouse double-click defect) could fire the action twice for one
-- intended click. None of these lost money or created free items -- each
-- order/trade is independently validated and priced server-side -- but an
-- accidental double-charge is still a real, avoidable surprise, and every
-- other similar button in the mod already guards against it.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_double_click_guards.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- Trading: BUY and SOLD never disabled themselves at all.
local tradingSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxTrading.lua")
for _, handlerName in ipairs({ "onTradingSold", "onTradingBuy" }) do
    local handlerBlock = tradingSource:match("function tradingUI:" .. handlerName .. ".-\nend")
    assert(handlerBlock, "tradingUI:" .. handlerName .. " must exist")
    assert(handlerBlock:find("self.tradingSoldButton:setEnable(false)", 1, true),
        handlerName .. " must disable the SOLD button before sending its request")
    assert(handlerBlock:find("self.tradingBuyButton:setEnable(false)", 1, true),
        handlerName .. " must disable the BUY button before sending its request")
    assert(handlerBlock:find("self.tradingSoldButton:setEnable(true)", 1, true),
        handlerName .. " must re-enable the SOLD button once its response lands")
    assert(handlerBlock:find("self.tradingBuyButton:setEnable(true)", 1, true),
        handlerName .. " must re-enable the BUY button once its response lands")
end

-- Buy Goods: the confirm ("Yes") button never disabled itself either.
local requestSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxRequest.lua")
local onYesBlock = requestSource:match("function requestUI:onYesButton.-\nend")
assert(onYesBlock, "requestUI:onYesButton must exist")
assert(onYesBlock:find("button:setEnable(false)", 1, true),
    "onYesButton must disable itself before sending the order")
assert(onYesBlock:find("button:setEnable(true)", 1, true),
    "onYesButton must re-enable itself on every path that doesn't close the panel " ..
    "(not-enough-money, missing modData, a rejected order), or a legitimately declined " ..
    "order would leave the button permanently stuck disabled")

print("PZLinux double-click guard tests OK")
