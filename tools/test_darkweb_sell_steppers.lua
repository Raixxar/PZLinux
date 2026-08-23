-- Player request: Dark Web quantity rows should be quick and consistent.
-- Buy and Sell rows now carry [-] [qty] [+] [++] [ACTION]: step down by
-- one (never below 0), step up by one (never above the row stock), or jump
-- straight to the full stock with [++].
--
-- The steppers are also the only place that repairs an out-of-range typed
-- value: setOnlyNumbers(true) blocks letters but not "9999", so every
-- stepper re-reads the box and clamps into [0, stock] before writing back.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_darkweb_sell_steppers.lua$") or "."
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

-- The client sources are a mix of CRLF and LF lines, so normalize before
-- doing any multi-line pattern matching against them.
local clientSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxDarkWeb.lua"):gsub("\r\n", "\n")

-- ---------------------------------------------------------------------
-- 1. Functional tests against the real clamp helpers, lifted out of the
-- client source so they run without the game's UI classes.
-- ---------------------------------------------------------------------

local helperSource = clientSource:match("(local function PZLinuxDarkWebSetQuantity.-\nend\n\nlocal function PZLinuxDarkWebStepQuantity.-\nend)")
PZLinuxTestAssert(helperSource, "the Sell stepper clamp helpers must exist in the Dark Web client source")
local loadHelpers = loadstring or load
local helperChunk = assert(loadHelpers(helperSource .. "\nreturn PZLinuxDarkWebSetQuantity, PZLinuxDarkWebStepQuantity"))
local setQuantity, stepQuantity = helperChunk()

local function fakeEntryBox(text)
    local box = { text = tostring(text) }
    function box:getText() return self.text end
    function box:setText(value) self.text = tostring(value) end
    return box
end

-- [-] stops at zero rather than going negative.
local box = fakeEntryBox("2")
PZLinuxTestAssert(stepQuantity(box, -1, 5) == 1, "[-] must step down by one")
PZLinuxTestAssert(stepQuantity(box, -1, 5) == 0, "[-] must reach zero")
PZLinuxTestAssert(stepQuantity(box, -1, 5) == 0, "[-] must stop at zero, never go negative")
PZLinuxTestAssert(box:getText() == "0", "[-] must write the clamped value back into the box")

-- [+] stops at the row's stock rather than exceeding what the player owns.
box = fakeEntryBox("1")
PZLinuxTestAssert(stepQuantity(box, 1, 3) == 2, "[+] must step up by one")
PZLinuxTestAssert(stepQuantity(box, 1, 3) == 3, "[+] must reach the full stock")
PZLinuxTestAssert(stepQuantity(box, 1, 3) == 3, "[+] must stop at the total count")

-- [++] jumps straight to the full stock.
box = fakeEntryBox("0")
PZLinuxTestAssert(setQuantity(box, 7, 7) == 7, "[++] must max the box out at the total count")
PZLinuxTestAssert(box:getText() == "7", "[++] must write the total count into the box")

-- A zero-stock row can only ever hold 0.
box = fakeEntryBox("4")
PZLinuxTestAssert(setQuantity(box, 4, 0) == 0, "a row with no stock must clamp to zero")
PZLinuxTestAssert(stepQuantity(box, 1, 0) == 0, "[+] on a zero-stock row must stay at zero")

-- The steppers double as the repair path for a hand-typed out-of-range
-- value: setOnlyNumbers(true) still allows "9999", and an empty or
-- garbage box must not be treated as nil.
box = fakeEntryBox("9999")
PZLinuxTestAssert(stepQuantity(box, 1, 6) == 6, "[+] must clamp a typed value above the stock back down")
box = fakeEntryBox("9999")
PZLinuxTestAssert(stepQuantity(box, -1, 6) == 6, "[-] must clamp a typed value above the stock back down")
box = fakeEntryBox("")
PZLinuxTestAssert(stepQuantity(box, 1, 6) == 1, "an empty box must be read as zero, not nil")
box = fakeEntryBox("abc")
PZLinuxTestAssert(stepQuantity(box, 1, 6) == 1, "a non-numeric box must be read as zero, not nil")

-- ---------------------------------------------------------------------
-- 2. Client source checks: the three Sell buttons exist, are wired to the
-- right deltas, and are laid out [-] [qty] [+] [++] [SELL].
-- ---------------------------------------------------------------------

local onSellBlock = clientSource:match("function darkWebUI:onSell%(%).-\nend")
PZLinuxTestAssert(onSellBlock, "darkWebUI:onSell must exist")

PZLinuxTestAssert(onSellBlock:find('ISButton:new(minusX, controlY, stepWidth, buttonHeight, "-"', 1, true),
    "each Sell row must carry a [-] button")
PZLinuxTestAssert(onSellBlock:find('ISButton:new(plusX, controlY, stepWidth, buttonHeight, "+"', 1, true),
    "each Sell row must carry a [+] button")
PZLinuxTestAssert(onSellBlock:find('ISButton:new(maxStepX, controlY, maxStepWidth, buttonHeight, "++"', 1, true),
    "each Sell row must carry a [++] button")

PZLinuxTestAssert(onSellBlock:find("PZLinuxDarkWebStepQuantity(sellQty, -1, itemStock)", 1, true),
    "[-] must step the row's own quantity box down by one, clamped to the row's stock")
PZLinuxTestAssert(onSellBlock:find("PZLinuxDarkWebStepQuantity(sellQty, 1, itemStock)", 1, true),
    "[+] must step the row's own quantity box up by one, clamped to the row's stock")
PZLinuxTestAssert(onSellBlock:find("PZLinuxDarkWebSetQuantity(sellQty, itemStock, itemStock)", 1, true),
    "[++] must set the row's own quantity box to the row's full stock")

-- Left-to-right order: [-] [qty] [+] [++] [SELL]. Each control is
-- anchored off the one to its right, so the whole cluster stays glued to
-- the SELL button no matter how the panel is sized.
PZLinuxTestAssert(onSellBlock:find("local maxStepX = buttonX - stepGap - maxStepWidth", 1, true),
    "[++] must sit immediately left of the SELL button")
PZLinuxTestAssert(onSellBlock:find("local plusX = maxStepX - stepGap - stepWidth", 1, true),
    "[+] must sit immediately left of [++]")
PZLinuxTestAssert(onSellBlock:find("local quantityX = plusX - stepGap - quantityWidth", 1, true),
    "the quantity box must sit immediately left of [+]")
PZLinuxTestAssert(onSellBlock:find("local minusX = quantityX - stepGap - stepWidth", 1, true),
    "[-] must sit immediately left of the quantity box")

-- The name column has to give up the space the new buttons take, or long
-- names would run underneath them (the same overlap test_darkweb_sell_ui
-- already guards against for the quantity box).
PZLinuxTestAssert(onSellBlock:find("local nameMaxWidth = math.max(40, minusX - labelNameX - 8)", 1, true),
    "the Sell name column must stop before the leftmost stepper, not before the quantity box")

for _, widget in ipairs({ "minusButton", "plusButton", "maxButton" }) do
    PZLinuxTestAssert(onSellBlock:find(widget .. ":initialise()", 1, true),
        "the Sell row's " .. widget .. " must be initialised, matching Buy's own row buttons")
    PZLinuxTestAssert(onSellBlock:find("self.scrollPanel:addChild(" .. widget .. ")", 1, true),
        "the Sell row's " .. widget .. " must be added to the scroll panel")
end

-- ---------------------------------------------------------------------
-- 3. Buy uses the same steppers, but its rows are pre-allocated once and
-- rebound to fresh offers on every render. The row's current stock is
-- stored on the quantity box so a reused row clamps against the offer it
-- is showing now, not an old one.
-- ---------------------------------------------------------------------

local initialiseBlock = clientSource:match("function darkWebUI:initialise%(%).-\nend")
PZLinuxTestAssert(initialiseBlock, "darkWebUI:initialise must exist")
local onBuyBlock = clientSource:match("function darkWebUI:onBuy%(%).-\nend")
PZLinuxTestAssert(onBuyBlock, "darkWebUI:onBuy must exist")

for _, listName in ipairs({ "transactionMinusBtns", "transactionPlusBtns", "transactionMaxBtns" }) do
    PZLinuxTestAssert(initialiseBlock:find("self." .. listName .. " = {}", 1, true),
        "Buy rows must pre-allocate " .. listName)
end

PZLinuxTestAssert(initialiseBlock:find('ISButton:new(minusX, (rowHeight - buttonHeight) / 2, stepWidth, buttonHeight, "-"', 1, true),
    "each Buy row must carry a [-] button")
PZLinuxTestAssert(initialiseBlock:find('ISButton:new(plusX, (rowHeight - buttonHeight) / 2, stepWidth, buttonHeight, "+"', 1, true),
    "each Buy row must carry a [+] button")
PZLinuxTestAssert(initialiseBlock:find('ISButton:new(maxStepX, (rowHeight - buttonHeight) / 2, maxStepWidth, buttonHeight, "++"', 1, true),
    "each Buy row must carry a [++] button")

PZLinuxTestAssert(initialiseBlock:find("PZLinuxDarkWebStepQuantity(transactionQty, -1, transactionQty.pzlinuxStock)", 1, true),
    "Buy [-] must clamp against the row's current stock")
PZLinuxTestAssert(initialiseBlock:find("PZLinuxDarkWebStepQuantity(transactionQty, 1, transactionQty.pzlinuxStock)", 1, true),
    "Buy [+] must clamp against the row's current stock")
PZLinuxTestAssert(initialiseBlock:find("PZLinuxDarkWebSetQuantity(transactionQty, transactionQty.pzlinuxStock, transactionQty.pzlinuxStock)", 1, true),
    "Buy [++] must set the row's current stock")

PZLinuxTestAssert(initialiseBlock:find("local maxStepX = buttonX - stepGap - maxStepWidth", 1, true),
    "Buy [++] must sit immediately left of the BUY button")
PZLinuxTestAssert(initialiseBlock:find("local plusX = maxStepX - stepGap - stepWidth", 1, true),
    "Buy [+] must sit immediately left of [++]")
PZLinuxTestAssert(initialiseBlock:find("local quantityX = plusX - stepGap - quantityWidth", 1, true),
    "the Buy quantity box must sit immediately left of [+]")
PZLinuxTestAssert(initialiseBlock:find("local minusX = quantityX - stepGap - stepWidth", 1, true),
    "Buy [-] must sit immediately left of the quantity box")
PZLinuxTestAssert(initialiseBlock:find("self.offerTextWidths[i] = math.max(40, minusX - labelNameX - 8)", 1, true),
    "the Buy name column must stop before the leftmost stepper")

PZLinuxTestAssert(onBuyBlock:find("self.transactionQtys[lineIndex].pzlinuxStock = tonumber(rowData.stock) or 0", 1, true),
    "a reused Buy row must refresh its stock before stepper clicks")
PZLinuxTestAssert(onBuyBlock:find("stepper:setEnable(hasStock)", 1, true),
    "Buy steppers must be disabled for sold-out rows, matching the BUY button")
PZLinuxTestAssert(onBuyBlock:find("stepper:setTooltip(offerTooltip)", 1, true),
    "Buy steppers must carry the row tooltip")

print("PZLinux Dark Web stepper tests OK")
