[h1]PZLinux 1.0.19[/h1]

PZLinux 1.0.19 is a maintenance update for Project Zomboid Build 42.20.x. It
fixes heavy mailbox orders that could remain inaccessible even after the player
emptied their inventory.

[h2]Mailbox Deliveries[/h2]

[list]
[*] The absolute post-delivery carrying limit is now 80 instead of 60 for every
character, regardless of Strength.
[*] Individual persistent parcels remain capped at 60, so large purchases are
still split into manageable parts instead of being delivered as one unsafe load.
[*] Heavy vanilla orders such as 13 Base.IronIngot items can now be collected
with a sufficiently light inventory.
[*] A parcel that would exceed the limit remains queued for a later mailbox
visit. Existing order IDs, parcel IDs and completed parts are preserved, so
retries cannot duplicate or lose delivered contents.
[*] The same persistent delivery system is used in single-player, hosted
multiplayer and dedicated servers.
[/list]

[h2]Validation[/h2]

[list]
[*] Added regression coverage for the reported 13-ingot order, the 60-weight
parcel split and the new 80-weight post-delivery ceiling.
[*] Persistent delivery queue and Dark Web delivery regressions pass.
[*] Release metadata and Workshop version checks pass for 1.0.19.
[/list]

[h2]Previous 1.0.18 Highlights[/h2]

[list]
[*] Restored server-side Manhunt and Cargo objectives near active players.
[*] Reduced automatic Hacking payouts.
[*] Preserved the single-player bank identity recovery introduced in 1.0.17.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.19 retains the B42_PZLinux mod ID and all existing player/world
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
