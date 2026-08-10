-- Regression test for a real player-requested feature: Blackjack used to
-- have no bet cap at all, letting a lucky streak compound a small bankroll
-- into an enormous one in just a few hands (one player reported going from
-- 15k to 10 million in about 10 minutes). Real casinos solve this with
-- fixed-stakes tables with posted limits, not by nerfing the payout odds
-- (which are the real 1:1 / 3:2 casino odds, verified separately) -- so
-- this mirrors the existing Poker lobby system (PZLinuxPokerConfig.lua)
-- instead: a handful of fixed-stakes tables, deliberately NOT scaled by
-- world-age price inflation, each capping how much a single hand can risk.

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_blackjack_tables.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

-- The config + lookup function can be exercised directly: PZLinuxConfig.lua
-- has no dependency on the game engine.
PZLinux = {}
dofile(luaRoot .. "/shared/PZLinux/PZLinuxConfig.lua")

assert(type(PZLinux.Config.Blackjack.tables) == "table" and #PZLinux.Config.Blackjack.tables >= 2,
    "Blackjack must offer more than one fixed-stakes table")

local previousMin = -1
for _, tableDef in ipairs(PZLinux.Config.Blackjack.tables) do
    assert(tableDef.id and tableDef.minBet and tableDef.maxBet, "every table needs an id, minBet and maxBet")
    assert(tableDef.minBet < tableDef.maxBet, "a table's minimum bet must be below its maximum")
    assert(tableDef.minBet > previousMin,
        "tables must be listed in ascending stakes order, so the UI lists them from lowest to highest")
    previousMin = tableDef.minBet
end

assert(PZLinuxBlackjackGetTable("micro"), "the micro table must be resolvable by id")
assert(PZLinuxBlackjackGetTable("does-not-exist") == nil,
    "an unknown table id must resolve to nil, not silently fall back to some default")

-- The server-side Start function must actually enforce the selected
-- table's range, not just accept whatever the client sends.
local variablesSource = readFile(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local startBlock = variablesSource:match("function PZLinuxBlackjackStart.-\nend")
assert(startBlock, "PZLinuxBlackjackStart must exist")
assert(startBlock:find("PZLinuxBlackjackGetTable(tableId)", 1, true),
    "PZLinuxBlackjackStart must look up the requested table")
assert(startBlock:find('error = "invalid_table"', 1, true),
    "starting a hand on an unknown table must be rejected")
assert(startBlock:find('error = "bet_out_of_range"', 1, true),
    "a bet outside the selected table's min/max must be rejected, or the whole point of fixed-stakes tables is moot")
assert(startBlock:find("amount < tableDef.minBet or amount > tableDef.maxBet", 1, true),
    "the range check must compare against the SELECTED table's own limits, not some other value")

-- The client must actually let the player pick a table and send it along
-- with the bet, not just decorate the UI without wiring it through.
local bettingSource = readFile(luaRoot .. "/client/Context/World/Features/PZLinuxBetting.lua")
assert(bettingSource:find("function PZLinuxBettingUI:onBlackjackSelectTable", 1, true),
    "the client must offer a way to pick a table")
local dealBlock = bettingSource:match("function PZLinuxBettingUI:onBlackjackDeal.-\nend")
assert(dealBlock, "PZLinuxBettingUI:onBlackjackDeal must exist")
assert(dealBlock:find("self.blackjackSelectedTableId", 1, true),
    "dealing a hand must send the currently selected table, not a hardcoded/default one")
assert(dealBlock:find("PZLinuxRequestBlackjackStart(self.player, self.blackjackSelectedTableId, amount", 1, true),
    "the selected table id must actually be passed to the start request")

print("PZLinux blackjack table tests OK")
