-- sendClientCommand("PZLinux", "FonctionA", { foo = 123 })

if isClient() then return end
local MODULE = "PZLinux"

local function fonctionA(player, args)
    -- logique serveur
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE then return end
    if command == "FonctionA" then fonctionA(player, args) return end
end

Events.OnClientCommand.Add(onClientCommand)