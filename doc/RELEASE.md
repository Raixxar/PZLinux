[h1]PZLinux 1.0.11[/h1]

PZLinux 1.0.11 focuses on reliable deliveries and mailbox transactions in
single-player, hosted multiplayer and dedicated servers running Project
Zomboid Build 42.20 or newer.

[h2]Persistent Deliveries[/h2]

[list]
[*] Dark Web purchases, Buy Goods requests and mail-mission gifts now use a
persistent server-side delivery ledger.
[*] Every delivery receives a stable order ID. Consecutive purchases append to
the queue and replaying the same network request cannot debit or enqueue it
twice.
[*] Deliveries are bound to a persistent character identity instead of the
account username. A new character cannot collect orders left by a deceased
character on the same account.
[*] Existing pending deliveries from 1.0.10 are migrated automatically. No new
save or character is required.
[*] Every parcel is fully populated before synchronization. If an item cannot be
created or synchronized, the temporary parcel is removed and the complete order
remains pending for a later attempt.
[*] Materialized parcels retain their order ID so an interrupted transaction can
be recovered without duplicating its contents.
[/list]

[h2]Weight And Mailboxes[/h2]

[list]
[*] Mailbox collection stops before a delivery would push the player beyond 85%
of their current carrying threshold.
[*] Weight is checked again after each complete parcel is built. An overweight
parcel is rolled back as a whole; no partial remainder is lost or duplicated.
[*] Undelivered orders remain visible to the server and can be collected on a
later mailbox visit after freeing inventory capacity.
[*] Personal and street mailboxes now report when delivery was deferred because
the player is carrying too much.
[/list]

[h2]Sales And Contracts[/h2]

[list]
[*] Dark Web and Sell Surplus payment packages now carry persistent receipt IDs.
A replayed sale reuses its original receipt and the same memento cannot credit
the bank twice.
[*] Sell Surplus now removes sold inventory through the synchronized multiplayer
path.
[*] Contract deposits restore their canonical server record from persistent
contract tags when necessary and reject deposits with no valid active contract.
[*] Quantity contracts remove exactly the requested number of items. Additional
matching items remain in the player's inventory.
[/list]

[h2]Character Banking[/h2]

[list]
[*] Bank balances now have a server-authoritative ledger indexed by persistent
character identity, while player ModData remains the synchronized UI mirror.
[*] Existing characters retain their current balance automatically. A new
character on the same account receives a separate configured starting balance.
[*] The native Project Zomboid SQL character identity is used when available to
prevent a modified client from selecting another character's PZLinux identity.
[/list]

[h2]Interface[/h2]

[list]
[*] Long Dark Web Sell names are constrained to their column instead of
overlapping price and stock information.
[*] Dark Web Sell rows expose the complete item name, price and owned quantity in
their tooltip.
[*] Dark Web Sell now explains when no supported item is present in the main
inventory and reports offer-loading failures instead of showing an empty panel.
[*] Sell Goods and its availability/error messages are translated across all 20
supported language catalogs, including Simplified Chinese.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.11 retains the B42_PZLinux mod ID and existing player/world ModData.
It remains compatible with single-player, hosted multiplayer and dedicated
servers on Project Zomboid Build 42.20 and newer Build 42 versions. No additional
mod dependency is required.

[h2]Known Limitations[/h2]

[list]
[*] Keyboard and mouse are required. Full controller navigation and split-screen
support are not certified.
[*] A live dedicated-server restart test with several pending orders remains
recommended before publishing to a large public server.
[/list]

[hr][/hr]

Full history: see CHANGELOG.md in the mod repository.
