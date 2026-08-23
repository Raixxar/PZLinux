[h1]PZLinux 1.0.16[/h1]

PZLinux 1.0.16 is a maintenance update for Project Zomboid Build 42.20.2. It
fixes an all-in Poker freeze, tightens short-stack Poker actions and makes Dark
Web quantity controls consistent between Buy and Sell.

[h2]Poker[/h2]

[list]
[*] Fixed a turn-advance infinite loop that could freeze a Poker hand when the
player went all-in and the only remaining opponent was already all-in.
[*] All-in hands now correctly run out the board and resolve at showdown in
single-player, hosted multiplayer and dedicated multiplayer.
[*] Short stacks can still call or go all-in, but the normal Raise action is no
longer offered when the player cannot cover the minimum raise amount.
[/list]

[h2]Dark Web[/h2]

[list]
[*] Dark Web Sell rows now include quick quantity controls:
[-] [qty] [+] [++] [SELL].
[*] Dark Web Buy rows now use the same controls for a consistent interface:
[-] [qty] [+] [++] [BUY].
[*] Quantity steppers clamp typed values between zero and the available stock,
so a row cannot be stepped below 0 or above what can actually be bought or sold.
[*] The long item-name layout guard remains active: names are truncated before
the row controls and the full item name, price and stock remain available in
tooltips.
[/list]

[h2]Community[/h2]

[list]
[*] Thanks to the community contributor whose work helped shape this release.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.16 retains the B42_PZLinux mod ID and all existing player/world
ModData. It supports single-player, hosted multiplayer and dedicated servers on
Project Zomboid Build 42.20 and newer Build 42 versions. No additional mod
dependency is required.

[h2]Validation[/h2]

[list]
[*] Poker all-in, short-stack Raise and Dark Web quantity-stepper regressions
pass.
[*] All 66 Lua files parse successfully with no syntax errors.
[*] Release metadata and Workshop version checks pass for 1.0.16.
[/list]

[h2]Known Limitations[/h2]

[list]
[*] Keyboard and mouse are required. Full controller navigation and split-screen
support are not certified.
[*] A complete game or server restart is required after updating shared Lua
files; Reload Lua alone is not sufficient.
[/list]

[hr][/hr]

Full history: see CHANGELOG.md in the mod repository.
