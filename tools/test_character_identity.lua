local scriptPath = debug.getinfo(1, "S").source:sub(2)
local repoRoot = scriptPath:match("^(.*)/tools/test_character_identity.lua$") or "."
local luaRoot = repoRoot .. "/Contents/mods/B42 PZLinux/42/media/lua"

local function PZLinuxTestRead(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function PZLinuxTestAssert(condition, message)
    if not condition then error(message, 2) end
end

local identitySource = PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxIdentity.lua")
local avoidsReflectedSqlAccessors = not identitySource:find(":getSqlId%(")
    and not identitySource:find(":getSqlID%(")
PZLinuxTestAssert(avoidsReflectedSqlAccessors,
    "identity lookup must not invoke missing reflected SQL accessors through pcall")

local globalModData = {}
ModData = {
    getOrCreate = function(key)
        globalModData[key] = globalModData[key] or {}
        return globalModData[key]
    end,
}
getGameTime = function() return { getWorldAgeHours = function() return 42 end } end
isClient = function() return false end
isServer = function() return true end
ZombRand = function(minimum) return minimum end

local function PZLinuxTestPlayer(username, modData, sqlId, descriptorId)
    local player = {
        modData = modData or {},
        sqlId = sqlId,
        dead = false,
        getUsername = function() return username end,
        getModData = function(self) return self.modData end,
        isDead = function(self) return self.dead end,
        transmitModData = function(self) self.transmissions = (self.transmissions or 0) + 1 end,
    }
    if descriptorId then
        player.getDescriptor = function()
            return { getID = function() return descriptorId end }
        end
    end
    return player
end

PZLinux = {}
PZLinuxGetPlayer = function(value) return value end
PZLinuxGetPlayerKey = function(value) return value:getUsername() end
PZLinuxTransmitPlayerModData = function(player) player:transmitModData() end
PZLinuxNormalizeMoney = function(value) return math.max(0, math.floor(tonumber(value) or 0)) end
PZLinuxGetStartingBalanceMin = function() return 500 end
PZLinuxGetStartingBalanceMax = function() return 500 end

assert(loadstring(identitySource))()
assert(loadstring(PZLinuxTestRead(luaRoot .. "/shared/PZLinux/PZLinuxDeliveryQueue.lua")))()

local shared = PZLinuxTestRead(luaRoot .. "/shared/ISPZLinuxVariablesTables.lua")
local bankStart = assert(shared:find("local PZLINUX_BANK_DATA", 1, true))
local bankEnd = assert(shared:find("function PZLinuxGetInterruptedSessions", bankStart, true))
assert(loadstring(shared:sub(bankStart, bankEnd - 1)))()

local characterAData = {}
local characterBData = {}
local characterA = PZLinuxTestPlayer("SharedAccount", characterAData, 101)
local characterB = PZLinuxTestPlayer("SharedAccount", characterBData, 102)

local characterAId = PZLinuxGetCharacterId(characterA, true)
local characterBId = PZLinuxGetCharacterId(characterB, true)
PZLinuxTestAssert(PZLinuxGetCharacterNativeKey(characterA) == "SharedAccount:sql:101",
    "B42.20's sqlId field must be used as the primary native character key")
PZLinuxTestAssert(characterAId ~= characterBId,
    "two characters on the same account must receive different persistent IDs")
PZLinuxTestAssert(PZLinuxGetCharacterKey(characterA, true) ~= PZLinuxGetCharacterKey(characterB, true),
    "the persistent character key must not be indexed by username alone")

local reconnectA = PZLinuxTestPlayer("SharedAccount", characterAData, 101)
PZLinuxTestAssert(PZLinuxGetCharacterId(reconnectA, true) == characterAId,
    "reconnecting the same character must preserve its identity")

local transitionData = {}
local descriptorOnly = PZLinuxTestPlayer("TransitionAccount", transitionData, nil, 501)
local transitionId = PZLinuxGetCharacterId(descriptorOnly, true)
local sqlAssignedLater = PZLinuxTestPlayer("TransitionAccount", transitionData, 201, 501)
PZLinuxTestAssert(PZLinuxGetCharacterId(sqlAssignedLater, true) == transitionId,
    "receiving a SQL ID after creation must not replace the existing descriptor-bound identity")

PZLinuxDeliveryEnqueue(characterA, "darkweb", { { name = "Base.Axe", quantity = 1 } }, "a-order")
PZLinuxDeliveryEnqueue(characterB, "darkweb", { { name = "Base.Hammer", quantity = 1 } }, "b-order")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(characterA, "darkweb") == 1,
    "the first character must see its own order")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(characterB, "darkweb") == 1,
    "the second character must see only its own order")

PZLinuxSetBankBalance(characterA, 9000)
PZLinuxSetBankBalance(characterB, 750)
characterAData.PZLinuxBank = 999999
characterAData.PZLinuxBankBackup = 999999
PZLinuxTestAssert(PZLinuxLoadBankBalance(reconnectA) == 9000,
    "the server ledger must override a modified client-side balance mirror")
PZLinuxTestAssert(PZLinuxLoadBankBalance(characterB) == 750,
    "a second character on the same account must keep a separate balance")

characterAData.PZLinuxCharacterId = characterBId
PZLinuxTestAssert(PZLinuxGetCharacterId(reconnectA, true) == characterAId,
    "the native SQL character binding must override a modified ModData identity")

local lost = PZLinuxDeliveryCloseCharacter(characterA, "character_death")
characterA.dead = true
PZLinuxBankMarkCharacterDead(characterA)
PZLinuxMarkCharacterDead(characterA)
PZLinuxTestAssert(lost == 1 and PZLinuxDeliveryPendingCount(characterA, "darkweb") == 0,
    "a dead character's pending orders must be closed instead of inherited")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(characterB, "darkweb") == 1,
    "closing one character must not alter another character on the same account")

local characterC = PZLinuxTestPlayer("SharedAccount", {
    PZLinuxCharacterId = characterAId,
}, 103)
PZLinuxTestAssert(PZLinuxGetCharacterId(characterC, true) ~= characterAId,
    "the server-native character binding must reject a forged deceased character ID")
PZLinuxTestAssert(PZLinuxLoadBankBalance(characterC) == 500,
    "a replacement character must receive a fresh configured starting balance")
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(characterC, "darkweb") == 0,
    "a replacement character must not inherit pending deliveries")

local reusedNativeCharacter = PZLinuxTestPlayer("SharedAccount", {}, 101)
local reusedNativeCharacterId = PZLinuxGetCharacterId(reusedNativeCharacter, true)
PZLinuxTestAssert(reusedNativeCharacterId ~= characterAId,
    "a living replacement must rotate an identity whose native key is marked deceased")
PZLinuxTestAssert(PZLinuxLoadBankBalance(reusedNativeCharacter) == 500,
    "a reused native key must not revive the deceased character's bank account")

local deadDebit = PZLinuxApplyBankDebit(characterA, 100, "death-test", "dead-debit")
local deadCredit = PZLinuxApplyBankCredit(characterA, 100, "death-test", "dead-credit")
PZLinuxTestAssert(not deadDebit.ok and deadDebit.error == "character_deceased",
    "the authoritative bank must reject debits after character death")
PZLinuxTestAssert(not deadCredit.ok and deadCredit.error == "character_deceased",
    "the authoritative bank must reject credits after character death")
PZLinuxTestAssert(PZLinuxLoadBankBalance(characterA) == 9000,
    "rejected post-death transactions must leave the deceased account unchanged")

local legacyData = { PZLinuxBank = 3333, PZLinuxBankBackup = 3333 }
local legacyCharacter = PZLinuxTestPlayer("LegacyAccount", legacyData, 104)
PZLinuxTestAssert(PZLinuxLoadBankBalance(legacyCharacter) == 3333,
    "an existing pre-identity character must retain its bank balance during migration")
PZLinuxTestAssert(legacyData.PZLinuxBankCharacterId == legacyData.PZLinuxCharacterId,
    "the migrated bank balance must be stamped with its new character ID")

local legacyQueueLedger = PZLinuxDeliveryGetLedger()
legacyQueueLedger.players.LegacyQueueAccount = {
    orders = {
        {
            id = "legacy-order",
            source = "darkweb",
            status = "pending",
            requestId = "legacy-request",
            items = { { name = "Base.Nails", quantity = 1 } },
        },
    },
    migrations = {},
}
local legacyQueueCharacter = PZLinuxTestPlayer("LegacyQueueAccount", {}, 105)
PZLinuxTestAssert(PZLinuxDeliveryPendingCount(legacyQueueCharacter, "darkweb") == 1,
    "a pre-v2 username delivery record must migrate once to the existing character")
PZLinuxTestAssert(legacyQueueLedger.players.LegacyQueueAccount == nil,
    "the migrated username-only delivery bucket must be removed")

print("PZLinux character identity, bank and delivery isolation tests OK")
