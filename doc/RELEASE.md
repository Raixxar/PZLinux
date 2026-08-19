[h1]PZLinux 1.0.14[/h1]

PZLinux 1.0.14 is a focused maintenance update for Project Zomboid Build 42.20.2.
It fixes mailbox collection of heavy purchases while preserving the persistent,
transactional delivery queue introduced in previous releases.

[h2]Mailbox Deliveries[/h2]

[list]
[*] Mailbox collection now allows temporary overload up to an absolute carried
weight of 60, regardless of the character's Strength. The limit is configurable.
[*] Heavy purchases such as an Old Generator can therefore be collected by
low-Strength characters instead of remaining permanently queued.
[*] Weight is checked after each complete parcel is built. A parcel that would
cross the limit is rolled back as a whole and remains queued for a later visit.
[*] Dark Web purchases, Buy Goods orders and mail rewards continue to use stable
server-side order IDs, preventing partial delivery and duplicate collection.
[*] Server logs now report delivered parcels, remaining orders and the active
maximum weight to simplify multiplayer diagnostics.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.14 retains the B42_PZLinux mod ID and all existing player/world
ModData. It supports single-player, hosted multiplayer and dedicated servers on
Project Zomboid Build 42.20 and newer Build 42 versions. No additional mod
dependency is required.

[h2]Validation[/h2]

[list]
[*] 53 automated gameplay and persistence tests pass.
[*] All 66 Lua files parse successfully with no syntax errors.
[*] All 20 translation catalogs contain the same 600 keys and parameters.
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
