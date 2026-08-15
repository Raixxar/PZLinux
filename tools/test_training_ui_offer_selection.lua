-- Regression test for a player-requested UI redesign: Training's offer
-- list now looks like Buy Goods' clickable rows (a card per course, name
-- and price/duration stacked inside) instead of a name+detail label pair
-- next to its own small "Start" button. Clicking a card never spends
-- money by itself -- it only selects it and reveals a separate Pay/Cancel
-- confirmation step below, so a stray click on a card can never charge
-- the player by accident (from player feedback: "faudrait un bouton
-- valider ou annuler avant de payer pour éviter les miss click").

local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_training_ui_offer_selection.lua$") or "."
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

local function extractMethod(name, params)
    local block = source:match("function trainingUI:" .. name .. ".-\nend")
    assert(block, "trainingUI:" .. name .. " must exist")
    local newParams = (params == "") and "self" or ("self, " .. params)
    local transformed = block:gsub("^function trainingUI:" .. name .. "%(" .. params .. "%)",
        "return function(" .. newParams .. ")", 1)
    return assert(loadstring(transformed))()
end

local refreshOfferView = extractMethod("refreshOfferView", "")
local onSelectCourse = extractMethod("onSelectCourse", "button")
local onCancelSelection = extractMethod("onCancelSelection", "_button")

PZLinuxGetText = function(key)
    if key == "IGUI_PZLinux_Training_Detail" then
        return "+%s XP - $%s - about %s in-game hours"
    end
    return key
end

local function newFakeCard()
    local card = { internal = nil, borderColor = nil, backgroundColor = nil, visibleCalls = 0, visible = nil }
    card.setVisible = function(_self, v) card.visible = v; card.visibleCalls = card.visibleCalls + 1 end
    return card
end
local function newFakeLabel()
    local label = { text = nil, visible = nil }
    label.setName = function(_self, text) label.text = text end
    label.setVisible = function(_self, v) label.visible = v end
    return label
end
local function newFakeButton()
    local button = { visible = nil }
    button.setVisible = function(_self, v) button.visible = v end
    return button
end

local function newSelf()
    return {
        currentOffers = {
            { id = "electricity_100", nameKey = "Electricity", xp = 100, price = 10000, durationHours = 2 },
            { id = "cooking_200", nameKey = "Cooking", xp = 200, price = 20000, durationHours = 3 },
            { id = "fishing_400", nameKey = "Fishing", xp = 400, price = 40000, durationHours = 4 },
        },
        offerRows = {
            { card = newFakeCard(), name = newFakeLabel(), detail = newFakeLabel() },
            { card = newFakeCard(), name = newFakeLabel(), detail = newFakeLabel() },
            { card = newFakeCard(), name = newFakeLabel(), detail = newFakeLabel() },
        },
        statusLabel = newFakeLabel(),
        confirmLabel = newFakeLabel(),
        payButton = newFakeButton(),
        cancelButton = newFakeButton(),
        -- onSelectCourse/onCancelSelection call self:refreshOfferView()
        -- internally -- wire the real extracted implementation onto the
        -- mock so that self-call resolves, exactly like the real object.
        refreshOfferView = refreshOfferView,
    }
end

-- 1. Initial list view: all 3 cards visible, confirm/pay/cancel hidden.
local s1 = newSelf()
refreshOfferView(s1)
for i, row in ipairs(s1.offerRows) do
    PZLinuxTestAssert(row.card.visible == true, "card " .. i .. " must be visible in the list view")
    PZLinuxTestAssert(row.card.internal == s1.currentOffers[i].id, "card " .. i .. " must be wired to the right offer id")
end
PZLinuxTestAssert(s1.confirmLabel.visible ~= true, "the confirm recap must be hidden until a card is selected")
PZLinuxTestAssert(s1.payButton.visible ~= true, "Pay must be hidden until a card is selected")
PZLinuxTestAssert(s1.cancelButton.visible ~= true, "Cancel must be hidden until a card is selected")

-- 2. Selecting a card must not spend money -- it only narrows the view
-- down to that one card and reveals the confirm step.
local s2 = newSelf()
refreshOfferView(s2)
local pickedRow = s2.offerRows[2]
onSelectCourse(s2, { internal = pickedRow.card.internal })
PZLinuxTestAssert(s2.selectedOfferId == "cooking_200", "selecting a card must record its offer id, nothing else")
PZLinuxTestAssert(s2.offerRows[1].card.visible == false, "unselected cards must be hidden once one is picked")
PZLinuxTestAssert(s2.offerRows[2].card.visible == true, "the selected card must stay visible")
PZLinuxTestAssert(s2.offerRows[3].card.visible == false, "unselected cards must be hidden once one is picked")
PZLinuxTestAssert(s2.confirmLabel.visible == true, "the confirm recap must appear once a card is selected")
PZLinuxTestAssert(s2.payButton.visible == true, "Pay must appear once a card is selected")
PZLinuxTestAssert(s2.cancelButton.visible == true, "Cancel must appear once a card is selected")
PZLinuxTestAssert(tostring(s2.confirmLabel.text):find("200", 1, true) ~= nil,
    "the confirm recap must describe the actually-selected offer, not a different one")

-- 3. Cancelling a selection must not spend money either -- it must return
-- cleanly to the list view.
onCancelSelection(s2, {})
PZLinuxTestAssert(s2.selectedOfferId == nil, "cancelling must clear the selection")
for i, row in ipairs(s2.offerRows) do
    PZLinuxTestAssert(row.card.visible == true, "cancelling must bring back card " .. i .. " in the list view")
end
PZLinuxTestAssert(s2.confirmLabel.visible == false, "cancelling must hide the confirm recap again")
PZLinuxTestAssert(s2.payButton.visible == false, "cancelling must hide Pay again")
PZLinuxTestAssert(s2.cancelButton.visible == false, "cancelling must hide Cancel again")

-- 4. A stale selection (the offer got bought elsewhere, or the week
-- rolled over between refreshes) must safely fall back to the list view
-- instead of confirming a purchase that can no longer succeed.
local s3 = newSelf()
s3.selectedOfferId = "not_a_real_offer_anymore"
refreshOfferView(s3)
PZLinuxTestAssert(s3.selectedOfferId == nil, "a stale/no-longer-offered selection must be cleared")
PZLinuxTestAssert(s3.confirmLabel.visible ~= true, "a stale selection must never show the confirm step")
for i, row in ipairs(s3.offerRows) do
    PZLinuxTestAssert(row.card.visible == true, "a stale selection must fall back to showing card " .. i .. " again")
end

print("PZLinux Training UI offer selection tests OK")
