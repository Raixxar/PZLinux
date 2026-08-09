local luaRoot = "Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local worldHour = 23
local globalData = {}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
    transmit = function() end,
}
function getGameTime()
    return { getWorldAgeHours = function() return worldHour end }
end
function isServer() return true end

local randomCounter = 0
function ZombRand(minimum, maximumExclusive)
    if maximumExclusive then return minimum end
    randomCounter = randomCounter + 1
    return (randomCounter - 1) % minimum
end

PZLinux = {}
PZLinuxDarkWebMarketConfig = {
    refreshHours = 24,
    minimumOffers = 5,
    maximumOffers = 5,
    stockTiers = {
        { maximumPrice = 499, minimumStock = 10, maximumStock = 15 },
        { maximumPrice = 999, minimumStock = 8, maximumStock = 10 },
        { maximumPrice = 2499, minimumStock = 6, maximumStock = 8 },
        { maximumPrice = 4999, minimumStock = 4, maximumStock = 6 },
        { maximumPrice = 9999, minimumStock = 2, maximumStock = 4 },
        { minimumStock = 1, maximumStock = 2 },
    },
}
PZLinuxDarkWebItemsTable = {
    { id = { "Base.Cheap" }, Price = 100 },
    { id = { "Base.Common" }, Price = 700 },
    { id = { "Base.Uncommon" }, Price = 1500 },
    { id = { "Base.Rare" }, Price = 3500 },
    { id = { "Base.VeryRare" }, Price = 7500 },
    { id = { "Base.Legendary" }, Price = 12000 },
}

local function PZLinuxTestPlayer(name)
    local player = { name = name, modData = { PZLinuxBank = 1000000 } }
    function player:getModData() return self.modData end
    return player
end

function PZLinuxGetPlayer(player) return player end
function PZLinuxGetPlayerKey(player) return player.name end
function PZLinuxNormalizeMoney(amount) return math.max(0, math.floor(tonumber(amount) or 0)) end
function PZLinuxLoadBankBalance(player) return player.modData.PZLinuxBank end
function PZLinuxApplyBankDebit(player, amount)
    amount = PZLinuxNormalizeMoney(amount)
    local previous = player.modData.PZLinuxBank
    if amount <= 0 or previous < amount then return { ok = false, balance = previous } end
    player.modData.PZLinuxBank = previous - amount
    return { ok = true, previousBalance = previous, balance = player.modData.PZLinuxBank }
end
function PZLinuxTransmitPlayerModData() end
function PZLinuxDarkWebCalculateBuyPrice(_, itemData) return itemData.Price end
function PZLinuxDarkWebGetHourMultiplier() return 1 end
function PZLinuxDarkWebGetPurchaseMultiplier() return 1 end
function getScriptManager()
    return { FindItem = function(_, itemId) return itemId and true or nil end }
end

dofile(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua")

local playerOne = PZLinuxTestPlayer("market-one")
local playerTwo = PZLinuxTestPlayer("market-two")
local firstSnapshot = PZLinuxDarkWebGetBuyOffers(playerOne, "offers-one")
local secondSnapshot = PZLinuxDarkWebGetBuyOffers(playerTwo, "offers-two")
PZLinuxTestAssert(firstSnapshot.ok and #firstSnapshot.offers == 5,
    "the global market must expose its configured number of unique offers")
PZLinuxTestAssert(firstSnapshot.offers[1].offerId == secondSnapshot.offers[1].offerId
    and firstSnapshot.offers[1].stock == secondSnapshot.offers[1].stock,
    "all multiplayer clients must receive the same offer and stock")

local minimumStock, maximumStock = PZLinuxDarkWebGetStockRange(12000)
PZLinuxTestAssert(minimumStock == 1 and maximumStock == 2,
    "$10,000+ items must be limited to one or two copies")
minimumStock, maximumStock = PZLinuxDarkWebGetStockRange(100)
PZLinuxTestAssert(minimumStock == 10 and maximumStock == 15,
    "sub-$500 items must receive the common stock tier")

local contestedOffer = firstSnapshot.offers[1]
local purchase = PZLinuxDarkWebApplyBuy(
    playerOne,
    contestedOffer.index,
    contestedOffer.stock,
    "buy-last-stock"
)
PZLinuxTestAssert(purchase.ok and purchase.stock == 0,
    "buying the remaining stock must atomically exhaust the global offer")
local stalePurchase = PZLinuxDarkWebApplyBuy(playerTwo, contestedOffer.index, 1, "buy-stale-stock")
PZLinuxTestAssert(not stalePurchase.ok and stalePurchase.error == "not_enough_stock"
    and stalePurchase.stock == 0,
    "a second client must not buy stock already consumed by another player")

local darkWebUiFile = assert(io.open(
    luaRoot .. "/client/Context/World/Features/PZLinuxDarkWeb.lua",
    "rb"
))
local darkWebUi = darkWebUiFile:read("*a")
darkWebUiFile:close()
-- Regression test for a real gameplay bug: a sold-out offer used to be
-- filtered out of the buy list entirely, which silently shifted every
-- offer after it up by one visual row. Each row is a reused button and
-- quantity box whose bound offer index gets reassigned on every
-- re-render, so that shift could leave a player's already-typed quantity
-- sitting in a row that now points at a completely different item --
-- clicking BUY there purchases whatever slid into that slot, not what
-- was on screen a moment ago.
local filterMatchBlock = darkWebUi:match("function darkWebUI:FilterMatch.-\nend")
PZLinuxTestAssert(filterMatchBlock, "darkWebUI:FilterMatch must exist")
PZLinuxTestAssert(not filterMatchBlock:find('rowData%.stock.-<= 0'),
    "sold-out offers must stay in the list (shown disabled) instead of being filtered out, " ..
    "or row positions can silently shift underneath the player")
PZLinuxTestAssert(darkWebUi:find("transactionQtys[lineIndex]:setText(\"0\")", 1, true),
    "a row must clear its typed quantity whenever it gets rebound to a different offer, " ..
    "as defense in depth against any other cause of row positions shifting (e.g. search filtering)")
PZLinuxTestAssert(darkWebUi:find('IGUI_PZLinux_DarkWeb_Stock'),
    "the Dark Web UI must display the available quantity")
PZLinuxTestAssert(darkWebUi:find("PZLinuxDarkWebFitText")
    and darkWebUi:find("offerTextWidths"),
    "Dark Web item names and details must be constrained to their responsive text column")
PZLinuxTestAssert(darkWebUi:find("labelNameY %+ 15")
    and darkWebUi:find("quantityX %- labelNameX"),
    "Dark Web price and stock must use a separate line before the quantity column")
PZLinuxTestAssert(darkWebUi:find("setTooltip%(offerTooltip%)"),
    "truncated Dark Web offers must expose their complete name, price and stock in a tooltip")
PZLinuxTestAssert(darkWebUi:find('tonumber%(item%.count%) or 0'),
    "Dark Web sell offers must display the total inventory quantity")

-- Regression test for a real gameplay bug: the sell list is rebuilt from
-- scratch (a brand new ISPanel) every time onSell() runs, including right
-- after selling an item to refresh stock/prices. Without removing the
-- previous scrollPanel first, each sale stacked one more full copy of the
-- list on top of the last, leaving overlapping, unreadable rows the more
-- items were sold in a row.
PZLinuxTestAssert(darkWebUi:find("if self%.scrollPanel then")
    and darkWebUi:find("self:removeChild%(self%.scrollPanel%)"),
    "onSell must remove any previous sell list panel before rebuilding it, or repeated sales stack overlapping rows")

local darkWebSharedFile = assert(io.open(luaRoot .. "/shared/PZLinux/PZLinuxDarkWeb.lua", "rb"))
local darkWebShared = darkWebSharedFile:read("*a")
darkWebSharedFile:close()
PZLinuxTestAssert(darkWebShared:find("if count > 0 and firstItemId"),
    "Dark Web sell offers with no available inventory must remain hidden")

worldHour = 24
local refreshed = PZLinuxDarkWebGetBuyOffers(playerOne, "offers-refresh")
PZLinuxTestAssert(refreshed.ok and refreshed.offers[1].offerId ~= contestedOffer.offerId,
    "the shared stock must replenish at the configured 24-hour boundary")

print("PZLinux Dark Web market tests OK")
