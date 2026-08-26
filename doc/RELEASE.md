[h1]PZLinux 1.0.18[/h1]

PZLinux 1.0.18 is a maintenance update for Project Zomboid Build 42.20.x. It
fixes a single-player banking identity reload issue that could make the bank
balance reroll to a fresh starting amount after restarting the save.

[h2]Banking[/h2]

[list]
[*] Single-player saves now recover the existing PZLinux character identity from
the global save ledger when the player ModData mirror or native character ID is
not available during reload.
[*] Reloading a solo save after deposits, purchases or other bank transactions
no longer creates a new bank record and rerolls the configured starting balance.
[*] The solo recovery key is local-only and is not used in hosted or dedicated
multiplayer, where usernames alone still cannot claim another player's account.
[*] Dead survivors remain isolated: after death, a replacement character with the
same solo name receives a fresh account instead of inheriting the deceased one.
[/list]

[h2]Validation[/h2]

[list]
[*] Added regression coverage for solo reloads with missing player ModData, solo
death/replacement rotation and MP isolation when no native character key exists.
[*] Character identity, bank backup and starting-balance configuration
regressions pass.
[*] Release metadata and Workshop version checks pass for 1.0.18.
[/list]

[h2]Previous 1.0.16 Highlights[/h2]

[list]
[*] Fixed a Poker all-in freeze and short-stack Raise visibility.
[*] Added consistent Dark Web Buy/Sell quantity steppers.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.18 retains the B42_PZLinux mod ID and all existing player/world
ModData. It supports single-player, hosted multiplayer and dedicated servers on
Project Zomboid Build 42.20 and newer Build 42 versions. No additional mod
dependency is required.

[h2]Known Limitations[/h2]

[list]
[*] Keyboard and mouse are required. Full controller navigation and split-screen
support are not certified.
[*] A complete game or server restart is required after updating shared Lua
files; Reload Lua alone is not sufficient.
[/list]

[hr][/hr]

Full history: see CHANGELOG.md in the mod repository.
