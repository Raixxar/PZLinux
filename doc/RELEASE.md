[h1]PZLinux 1.0.15[/h1]

PZLinux 1.0.15 is a maintenance and balance update for Project Zomboid Build
42.20.2. It fixes multiplayer Training persistence and mailbox collection of
heavy purchases while preserving existing saves.

[h2]Training[/h2]

[list]
[*] Weekly Training offers are now stored in a persistent server-authoritative
ledger per character. Reopening the application or reconnecting cannot reroll
the list or make a displayed course fail during payment.
[*] Each set of three courses remains fixed for a full 168 in-game hours after
generation. Completed courses disappear one by one and do not refill before the
stored deadline.
[*] Course prices are randomized and frozen with their offer: $5,000-$15,000
for 100 XP, $10,000-$25,000 for 200 XP, $20,000-$40,000 for 400 XP and
$30,000-$80,000 for 800 XP before world-age scarcity. The server applies the
same scarcity multiplier used by online item markets, then rounds the final
weekly quote to the nearest $100.
[*] New course durations are doubled to 4, 6, 8 and 10 in-game hours. Existing
active courses retain their saved duration and progress.
[/list]

[h2]Mailbox Deliveries[/h2]

[list]
[*] Mailbox collection now allows temporary overload up to an absolute carried
weight of 60, regardless of the character's Strength. The limit is configurable.
[*] Heavy purchases such as an Old Generator can therefore be collected by
low-Strength characters instead of remaining permanently queued.
[*] Orders heavier than 60 are automatically split into persistent parcel
parts under the same order ID. Each part has its own delivery status, so
collecting one part and returning later resumes with only what remains.
[*] Weight is checked after each complete parcel is built. A parcel that would
cross the limit is rolled back as a whole and remains queued for a later visit.
[*] Dark Web purchases, Buy Goods orders and mail rewards use stable server-side
order and parcel-part IDs, preventing partial parcel creation and duplicate
collection.
[*] Pending orders created by earlier versions are planned automatically on
their next mailbox interaction; no save reset or manual migration is required.
[*] Server logs now report delivered parcels, remaining orders and the active
maximum weight to simplify multiplayer diagnostics.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.15 retains the B42_PZLinux mod ID and all existing player/world
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
