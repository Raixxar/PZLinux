[h1]PZLinux 1.0.13[/h1]

PZLinux 1.0.13 is a maintenance update for Project Zomboid Build 42.20.2.
It fixes a single-player startup crash and makes queued mailbox deliveries less
restrictive while preserving their transactional server-side safeguards.

[h2]Single-Player Identity Fix[/h2]

[list]
[*] Fixed a startup crash when an existing persistent character identity was
restored in single-player.
[*] Identity lookup no longer depends on Lua's unavailable next() primitive in
the affected Kahlua environment.
[*] Existing character identities, bank balances and pending deliveries remain
compatible. No save reset or manual migration is required.
[/list]

[h2]Mailbox Deliveries[/h2]

[list]
[*] Mailbox collection now allows temporary overload up to 200% of the
character's normal carrying capacity. The multiplier is configurable.
[*] Weight is checked after each complete parcel is built. A parcel that would
cross the limit is rolled back as a whole and remains queued for a later visit.
[*] Dark Web purchases, Buy Goods orders and mail rewards continue to use stable
server-side order IDs, preventing partial delivery and duplicate collection.
[*] Personal and street mailboxes now display a translated warning when parcels
remain queued because the player is carrying too much.
[*] Server logs now report delivered parcels, remaining orders and the active
weight multiplier to simplify multiplayer diagnostics.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.13 retains the B42_PZLinux mod ID and all existing player/world
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
