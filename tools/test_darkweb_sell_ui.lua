-- Regression test for a player-requested UI parity fix: Dark Web's Sell
-- list didn't look or behave like its own Buy list -- no tooltip on
-- hover, no limit on how long an item name could run before overlapping
-- the price/quantity/button next to it. From player feedback: "il
-- faudrait un tooltip, une limite pour que le nom ne dépasse pas dans le
-- bouton... et sur la 2eme ligne comme pour les achats il faut voir le
-- stock du joueur, pour qu'il puisse set le bon chiffre directement."
-- The quantity field and stock line were already in place (see
-- test_darkweb_sell_quantity.lua); this covers what wasn't: tooltip
-- coverage and name truncation.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_sell_ui.lua$") or "."
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

local clientSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxDarkWeb.lua")
local onSellBlock = clientSource:match("function darkWebUI:onSell%(%).-\nend")
PZLinuxTestAssert(onSellBlock, "darkWebUI:onSell must exist")

-- Name truncation: the item name must go through the same
-- PZLinuxDarkWebFitText helper Buy already uses, not the raw,
-- unbounded item.name.
PZLinuxTestAssert(onSellBlock:find("PZLinuxDarkWebFitText(item.name, nameMaxWidth)", 1, true),
    "the Sell item name must be truncated with PZLinuxDarkWebFitText, matching Buy's own rows")
PZLinuxTestAssert(not onSellBlock:find("ISLabel:new(self.width * 0.059, yOffset, 20, item.name,", 1, true),
    "the raw, untruncated item.name must no longer be handed straight to the name label")

-- Tooltip coverage: icon, name, price, quantity box and the Sell button
-- must all carry the same hover tooltip, matching Buy's row-wide
-- tooltip treatment (icon/label/price/qty/background all tooltipped).
for _, widget in ipairs({ "itemIcon", "itemSellLabel", "priceLabel", "sellQty", "sellButton" }) do
    PZLinuxTestAssert(onSellBlock:find(widget .. ".setTooltip", 1, true) or onSellBlock:find(widget .. ":setTooltip", 1, true),
        "the Sell row's " .. widget .. " must carry a tooltip, matching Buy's rows")
end

-- The tooltip text itself must be the full, untruncated name (so a name
-- cut short by nameMaxWidth is still fully readable on hover) plus the
-- price/stock line, mirroring Buy's own offerTooltip pattern.
PZLinuxTestAssert(onSellBlock:find("local sellTooltip = item.name .. \"\\n\" .. priceText", 1, true),
    "the Sell tooltip must combine the full item name and the price/stock line")
PZLinuxTestAssert(onSellBlock:find("nameMaxWidth = math.max(40, quantityX - labelNameX - 8)", 1, true),
    "the Sell text column must stop before the quantity field")
PZLinuxTestAssert(onSellBlock:find("yOffset + labelNameY + 15", 1, true),
    "the Sell price and stock must use a dedicated second line below the item name")
PZLinuxTestAssert(onSellBlock:find("buttonX = self.scrollPanel.width - buttonWidth - 23", 1, true),
    "the Sell controls must be anchored to the visible scroll-panel width")

PZLinuxTestAssert(onSellBlock:find("IGUI_PZLinux_DarkWeb_NoSellableItems", 1, true),
    "an empty Sell inventory must display an explicit localized message")
PZLinuxTestAssert(onSellBlock:find("IGUI_PZLinux_DarkWeb_SellUnavailable", 1, true),
    "a failed Sell offer request must display an explicit localized error")

print("PZLinux Dark Web Sell UI tests OK")
