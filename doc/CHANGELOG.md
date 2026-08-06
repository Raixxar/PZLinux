# Changelog

## [1.0.4]

- Fixed the computer's right-click menu sometimes not appearing at all when
  the Desktop Computer was placed on top of furniture (e.g. a counter),
  even standing right next to it. The game's own click detection can skip
  a computer stacked on furniture in favor of the furniture itself; the
  menu now also checks everything actually sitting on the same tile, not
  just what the game already picked out.

## [1.0.3]

- Fixed the mailbox/ATM/computer context menu sometimes appearing on
  unrelated B42 objects (e.g. a newspaper dispenser instead of the actual
  mailbox), which then failed every action with a generic error. The menu
  matched sprite names with a substring search instead of an exact match,
  so a new object whose sprite name happened to start the same way (e.g.
  "street_decoration_01_90") was wrongly treated as a mailbox.
- Translated the full body text of every mail mission (Ammo, Medical, and
  the flavor ADS spam mail) into all 20 supported languages. This text was
  100% hardcoded English before, unlike the rest of the mod.
- Fixed the delivery city always being missing from Ammo/Medical mail
  mission descriptions. Mail descriptions now also include the building or
  place name and a floor label (Ground Floor, Floor N above, Basement N
  below), so the delivery target is actually findable from the mail text
  alone. Contract locations (the seller's dialogue when offering a
  contract, and the accepted contract's note) now show the same floor
  label too.
- Changed mail mission gifts to be picked up at any mailbox instead of
  appearing directly in the player's inventory the instant the mission was
  completed -- the same "check a mailbox" flow already used for Dark Web
  and Request orders, instead of feeling like it materialized out of thin
  air. Several completed missions can each still have their own separate
  gift waiting.
- Added an admin-only "Force a random mail mission" debug option, same
  access rules as the existing contract/funds debug tools.
- Fixed completing an Ammo/Medical mail mission silently failing with a
  generic "Mail delivery rejected" even with the exact right item in hand,
  at a mailbox that visibly offered the deposit option. The context menu
  and the server-side completion check used two different distance
  metrics -- Chebyshev (max of dx/dy) for showing the option, Manhattan
  (dx+dy) for validating it -- so an off-axis position the player was shown
  as valid could still fail the stricter server check.
- Fixed Auto Parts, Medical and Weapon contracts (5, 9, 10) never showing a
  mailbox delivery option again after a multiplayer reconnect, even with
  the exact right item in hand. The requested item's type, name and count
  were only ever sent to the client at contract acceptance, never as part
  of the reconnect resynchronization -- the same class of bug already fixed
  for the ATM refill contract earlier, just not extended to these three.
- Fixed accepting a mail mission silently doing nothing (contracts still
  worked fine). The mail lookup used to check whether a mission could be
  accepted was never normalized to a number, so a mail ID that came back
  as a string after a ModData round-trip (save/reload, MP sync) made the
  lookup silently miss and the request never reached the server.

## [1.0.2]

- Fixed the "Check" button on the personal (white) mailbox overflowing well
  past the mail slot, toward the flag. It reused the same relative width as
  the street (blue) mailbox's button, but the two textures have very
  different proportions -- the personal mailbox's actual slot only spans
  roughly the left third of its texture, unlike the street mailbox's, which
  spans nearly the full width.
- Fixed clicking "CHECK CONDITION" locking a blank, unclosable computer
  panel on screen until restart. The computer's condition value could come
  back as a string instead of a number after a ModData round-trip
  (save/reload, MP sync), and comparing it directly against a number
  crashed mid-render, right after the panel was created but before it was
  populated or its close buttons were fully wired up. The condition is now
  normalized with tonumber both where it's stored and where it's compared.

## [1.0.1]

- Fixed Dark Web sell list rows overlapping after selling an item. The list
  was rebuilt from scratch on every refresh (including right after a sale)
  without removing the previous panel first, so each sale left one more
  full copy of the list stacked on top of the last.

## [1.0.0]

- Added hosted and dedicated multiplayer support, with server-side validation
  for Banking, ATMs, Dark Web, Trading, Contracts, Requests, Mail, Hacking
  and betting.
- Added a translated Network Reputation screen; completing contracts raises
  reputation, cancelling lowers it, and it drifts back to neutral over time.
- Applied reputation surcharges and discounts to Dark Web and Request prices.
- Added Blackjack with a real 52-card deck and server-side settlement.
- Added six-seat Texas Hold'em Poker with AI opponents, side pots and a
  hidden-card-free hand equity estimate.
- Replaced Zombie Race progress text with animated runners, a
  server-authoritative pari-mutuel pool and five scheduled daily departures,
  plus a weekly Sunday super jackpot race.
- Added finite, persistent ATM cash reserves ($10,000-$50,000) that restock
  over time, but only ever refund cash actually withdrawn from that specific
  machine, capped at $15,000 lifetime, so an untouched ATM never fills on
  its own. Deposits are capped at $50,000 and self-heal on load.
- Added a 13th contract type, Refill an ATM: withdraw a rolled cash amount
  ($1,000-$5,000) and deposit it at one fixed target machine per city for a
  reward, without the contract touching the bank at acceptance. The target
  machine starts near-empty and resets whenever a new contract instance
  targets it, giving cash-heavy players a reliable place to deposit.
- Added Sell Surplus (Sell Goods), the inverse of Requests: independent
  daily demand per item, a quote/accept/cancel flow and a chance to
  negotiate a better price.
- Reworked Requests seller rarity into a daily per-category roll that grows
  scarcer over survival time, and added a supplier-search delay to orders.
- Added a shared weekly Contracts board and persistent world-contract
  registry; accepted offers are consumed for everyone until the next board.
- Added a persistent server-wide Dark Web catalog refreshed every 24
  in-game hours, with finite stock and survival-time scarcity (prices rise
  every three months, capped at x8 after two years).
- Added shared, city-aware Build 42.20 location pools: 67 package
  destinations, 22 cargo points, 16 manhunt points, 45 protection points,
  36 vehicle points and 5 ATM refill points.
- Added configurable price-rounding tiers and a 5% Trading fee.
- Hacking now only accepts credit cards; ID cards no longer work.
- Added an admin-only debug menu for forcing a contract onto the board and
  adding bank funds for testing.
- Added 20 synchronized B42 translation catalogs and migrated all UI text,
  mission descriptions and contract dialogue into them.
- Fixed kill-zombie contracts remaining at zero in multiplayer.
- Fixed accepted contracts becoming hidden when the weekly board renewed.
- Fixed Manhunt, Cargo and Protect world objectives duplicating or failing
  to restore after reconnect.
- Fixed the Refill an ATM button never reappearing after a multiplayer
  reconnect.
- Fixed requested-vehicle delivery never completing in real multiplayer,
  and duplicate vehicle/zombie spawns from repeated failed searches.
- Fixed a native rich-text rendering bug that silently dropped the last
  word of a line whenever it was directly followed by a `<LINE>` tag,
  affecting the contract completion receipt, the Reputation screen and race
  results.
- Fixed the Reputation screen showing blank values on almost every line.
- Fixed a bogus "retrieve contract item" context-menu option near the
  Refill an ATM target, and reworked its ATM panel into a single button.
- Fixed "Capture a live zombie" always failing in solo.
- Fixed infinite-duration timed actions (computer, mailbox, ATM) leaving
  the character frozen after their panel closed.
- Fixed a Lua syntax bug that silently broke the entire Requests system.
- Fixed a crash depositing a Sell Goods package in a mailbox.
- Fixed Hacking manual input, attempt counters and password leakage.
- Renamed "SEND A REQUEST"/"SELL SURPLUS" to "BUY GOODS"/"SELL GOODS".
- Controller navigation and split-screen are not supported for 1.0.0.

## [0.1.12-rc1]

- Fixed the contract interface offering only a single contract type.

## [0.1.12]

- Added a chance to find money and a weapon inside contract briefcases.
- Reduced Dark Web resale prices.
- Added all skill magazines and books to the Dark Web.
- Reduced computer wear by half.
- Fixed Kill Zombies contracts not counting kills.
- Reduced the live-zombie capture reward.
- Removed the inventory note after requesting a vehicle.
- Added a randomized initial balance for new players.
- Increased Request prices to improve balance.
- Based Kill Zombies rewards on the number of required kills.
- Added a chance that no contact answers a Request and increased reply delays.
- Added a 10% chance for parcels to be stolen during mailbox retrieval.
- Added electronic equipment to the Dark Web.
- Added lower-yield multi-card automatic Hacking.
- Dropped compatibility with versions before Build 42.13 after Lua API changes.
- Added contracts to deliver a computer or a fridge.
- Added the first reputation system.
- Added the Mail interface, ammunition and medical delivery missions, spam and
  advertisements.
- Changed the email domain from Hotmail to AOL for the 1994 setting.
- Added desktop notifications for new mail.

## [0.1.11-rc6]

- Fixed Lua errors in the ATM password interface.
- Fixed computer repairs failing with electronic parts in the inventory.
- Limited computer repair actions to condition below 15% instead of 50%.

## [0.1.11-rc5]

- Adjusted simulated keyboard typing speed and reduced interface sound volume.
- Prevented zero-quantity Dark Web purchases from creating empty packages or XP.
- Fixed Lua errors triggered by zombie kills.
- Added requested automobile-part details to contract notes.
- Fixed automobile parts not being accepted for delivery.
- Balanced automobile-part rewards against part value.

## [0.1.11-rc4]

- Added a Sandbox multiplier for sale prices.
- Fixed completion menus for several contract types.
- Fixed Lua errors in Kill Zombies contracts.

## [0.1.11-rc3]

- Fixed stale contracts not being removed in a new game.
- Added a Sandbox multiplier for purchase prices.

## [0.1.11-rc2]

- Fixed mission information appearing before a contract was accepted.

## [0.1.11-rc1]

- Improved support for a second local player.
- Changed Zombie Race minimum odds to 2/1.
- Added Foraging XP to Dark Web purchases and sales.
- Added destination cities to relevant contracts.
- Added Electricity XP for computer repairs and successful Hacking.
- Added boredom, stress and happiness effects to Hacking, betting, Trading and
  contract completion.
- Began extracting editable data tables from feature files.

## [0.1.11]

- Replaced the contract log with a compact inventory paper note.
- Added more active-mission information to contract notes.
- Fixed computer messages overflowing the screen.
- Fixed mailbox Lua errors caused by uninitialized Requests.
- Added a map note for requested vehicles.
- Added contract-completion music and removed map annotations after cancellation
  or completion.
- Added generator power consumption for computers and ATMs.
- Added computer condition, electronic-part repairs and condition-specific boot
  sounds.
- Added bars and ingots to the Dark Web.
- Moved Dark Web purchase collection to mailboxes.
- Applied the Foraging discount to Request items.
- Added halo notifications for important actions.

## [0.1.10-rc2]

- Fixed map annotations in saves where the map had never been opened.
- Fixed stock-action prices before the Trading interface was opened.

## [0.1.10-rc1]

- Fixed map indicators in new games.
- Made contracts available during the first week.
- Fixed mailbox package error messages.

## [0.1.10]

- Added multiple package-retrieval destinations.
- Added a $5 contract bonus per zombie killed.
- Fixed Request pagination and live-zombie capture reset behavior.
- Mixed Request items for more varied delivery parcels.
- Added electronic, repair, material and seed Request categories.
- Added cargo, building protection, medical delivery and weapon delivery
  contracts.
- Added contract circles and summaries to the map.
- Fixed ID cards not being consumed after Hacking progression.
- Added credit-card Hacking.
- Added requested-vehicle map markers.
- Combined mailbox collection and deposit interactions.
- Added kill progress to the contract notebook.

## [0.1.9-rc1]

- Fixed zombie-blood contracts accepting an old target.
- Fixed timed actions remaining active after closing an interface.
- Fixed credit cards not being consumed.
- Fixed fish missing from Request deliveries.

## [0.1.9]

- Added Zombie Race betting.
- Added the live-zombie capture contract.
- Fixed minimizing a contract during dialogue returning to the wrong screen.
- Fixed Dark Web purchases and sales closing the PZLinux interface.
- Added all modern and standard parts to automobile-part contracts.
- Increased the PZLinux world-menu detection radius.
- Added vehicle Requests.
- Allowed PZLinux timed actions to follow game-speed acceleration.

## [0.1.8-rc2]

- Fixed a contract variable regression introduced in 0.1.8-rc1.

## [0.1.8-rc1]

- Added an SFX button to shorten interface message animations.

## [0.1.8]

- Migrated persistent values from `PZLinux.ini` to ModData.
- Preserved interface position while navigating between menus.
- Added cigarettes, cigars, knives and hats to Dark Web trading.
- Added hackable credit cards to the Dark Web.
- Removed the cap on company stock prices.
- Added manhunt, package retrieval, zombie blood and automobile-part contracts.
- Prevented remote use of computers, mailboxes and ATMs.
- Indexed purchase prices to world age.
- Added IRC Requests for canned goods, fish, books, fruit, meat and vegetables.
- Added IRC message notifications.
- Reduced Dark Web resale prices to account for Contracts and Requests.
- Fixed interfaces remaining open after the player moved away from a computer.

## [0.1.7-rc1]

- Fixed mailbox availability depending on mailbox direction.

## [0.1.7]

- Corrected Hacking interface text.
- Made interfaces movable.
- Fixed the Dark Web offer list during the first 24 world hours.
- Fixed sold items not being removed after consecutive Dark Web actions.
- Renamed the Dark Web `Sold` action to `Sell`.
- Linked interface sound volume to the game audio setting.
- Split Dark Web buying and selling into separate interfaces.
- Added suspicious sale packages and mailbox sale completion.
- Reduced the maximum visible Dark Web offer list from 100 to 50.
- Added Dark Web buy/sell help screens.
- Limited Mastermind to six attempts and ignored invalid non-four-digit inputs.

## [0.1.6]

- Fixed Trading token counts.
- Fixed ATM deposits for player names containing special characters.
- Began storing player money in ModData.
- Added weapon mods and magazines.
- Added ID-card Hacking.
- Improved 4K interface support.
- Added menu buttons for direct submenu navigation.
- Removed zero-quantity positions from the Trading wallet.

## [0.1.5]

- Linked connection speed to Electricity skill.
- Fixed Dark Web search and added Enter-key submission.
- Linked Dark Web prices to Foraging skill.
- Refreshed Dark Web offers every 24 world hours.
- Added Trading and its wallet interface.
- Renamed the mod to PZLinux and introduced the unified terminal menu.
- Required an active internet connection for online submenus.
- Added 24-hour internet sessions and computer uptime.
- Added computer boot sound and connection-status messages.
- Moved the CRT power button to the bottom-left corner.

## [0.1.4]

- Prevented Dark Web access from non-computer world objects.
- Fixed selling items that shared the same display name.

## [0.1.3]

- Added ATM deposits, withdrawals and persistent bank storage.
- Added ATM, buy, sell and error sounds.
- Added support for depositing cash carried in backpacks.
- Added connection extension and menu navigation controls.
- Linked ATM access from the Dark Web interface.
- Fixed menu scrolling alignment and computer startup logs.

## [0.1.2]

- Fixed selling items from nearby inventories.
- Added Money Bundles worth $100.
- Improved performance to reduce crashes and FPS issues.

## [0.1.1]

- Added a power-off button during computer initialization.
- Fixed incomplete interface cleanup after disconnecting.
- Replaced the disconnect button with the power-off button.
