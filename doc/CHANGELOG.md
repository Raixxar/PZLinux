# Changelog

All notable changes to PZLinux are documented in this file. Pre-1.0 entries are
preserved as historical notes and may describe systems replaced by 1.0.0.

## [1.0.0] - Unreleased

### Added

- Added Blackjack with a real 52-card deck, dealer rules, server-side settlement
  and mood effects based on the size and outcome of a bet.
- Added six-seat Texas Hold'em Poker with configurable lobbies, AI opponents,
  persistent table stacks, side pots, all-in handling and hand evaluation.
- Added Poker hand names and a 300-sample equity estimate calculated without
  reading hidden opponent cards.
- Added finite, persistent ATM cash reserves initialized between $10,000 and
  $50,000.
- Added a shared weekly Contracts board and persistent world-contract registry.
- Added persistent objective ownership and `PZLinuxContractId` tags for shared
  and stealable multiplayer contract objectives.
- Added server idempotency by player, command and request ID to prevent duplicate
  payments or world mutations after clicks and network retries.
- Added restart rollback for temporary Blackjack, Hacking, Poker and Zombie Race
  sessions.
- Added shared, city-aware Build 42.20 location pools: 37 package destinations,
  22 cargo points, 16 manhunt points, 7 protection points and 36 vehicle points.
- Added 20 synchronized B42 JSON translation catalogs and automated key,
  placeholder and UTF-8 validation.
- Added local validation tools for Lua syntax, LuaCheck, assets, translations,
  locations, authority boundaries, Poker and server log monitoring.

### Multiplayer And Security

- Moved bank balances, ATM deposits and withdrawals to server-authoritative
  commands with explicit inventory replication.
- Moved Dark Web offer generation, purchases, sales, pending deliveries and
  mailbox redemption to server-authoritative flows.
- Moved Trading prices, wallets, purchases, sales and the 5% transaction fee to
  a shared server market.
- Moved contract preview, acceptance, cancellation, world objectives, deposits,
  completion, rewards and reputation changes to server-authoritative flows.
- Contract clients now send only the selected contract ID; locations, targets,
  item requests, quantities and rewards are generated from server allowlists.
- Moved Request orders, pricing, pending deliveries, mailbox parcels and vehicle
  spawning to server-authoritative flows.
- Moved Mail generation, mission acceptance, item consumption, rewards and
  reputation to server-authoritative flows.
- Moved Hacking card consumption, account generation, password attempts, locks
  and transfers to server-authoritative flows.
- Removed Hacking passwords from client responses and client state.
- Moved Blackjack, Poker and Zombie Race debit, state and settlement to
  server-authoritative sessions.
- Added distance, Z-level, object identity, objective-state and persistent-tag
  validation to sensitive mailbox and contract world commands.
- Removed client-side authority to delete contract corpses, zombies, cargo or
  delivered inventory items.
- Added explicit B42 container packets for cash, parcels, contract items, reward
  items and requested vehicle keys created or removed by the server.
- Centralized direct player resolution so multiplayer flows do not implicitly
  mutate player zero.

### Economy

- Rebalanced Dark Web prices for firearms, ammunition, explosives, generators,
  armor, strong melee weapons, books and rare magazines.
- Increased Request base prices and capped the Plant Scavenging discount at 15%.
- Reduced easy contract rewards while retaining stronger payouts for dangerous
  objectives.
- Added a configurable 5% Trading fee: purchases pay gross plus fee and sales
  receive gross minus fee.
- Added a configurable reputation range from -99 to 200. Contract cancellations
  apply a server-side penalty, completed contracts grant reputation and passive
  decay slowly returns positive or negative values toward neutral.
- Applied reputation surcharges and discounts to authoritative Dark Web and
  Request purchase prices.
- Centralized world-age scarcity for Dark Web and Request purchases: prices stay
  at x1 for the first three months, rise every three months and cap at x8 after
  two years. Contract rewards are deliberately excluded.
- Added configurable price-rounding tiers of $5, $10, $50, $100 and $500.
  Purchases round up, Dark Web resale rounds down and final contract rewards
  round to the nearest tier after mission modifiers.
- Capped the rare Mail cash bonus at $100-$300.

### Contracts And World Objectives

- Rebuilt all 12 contract mission definitions around one canonical mission and
  dialogue structure while preserving their informal IRC writing style.
- Extracted contract target names and automobile, medical and weapon request
  allowlists into dedicated shared data modules.
- Added canonical contract previews and notes generated from server state.
- Added live Kill Zombies progress to the synchronized inventory note.
- Fixed active Kill Zombies contracts disappearing after the first server-side
  kill update.
- Fixed accepted contracts becoming hidden when the weekly board renewed.
- Consumed accepted offers globally until the next weekly board generation,
  preventing repeated acceptance and payment of the same offer.
- Added contract synchronization on reconnect, computer close and relevant
  context-menu interactions.
- Made package retrieval depend on the player's real position inside a
  configurable five-tile objective zone rather than a clicked map object.
- Made contract delivery item removal server-authoritative and explicitly
  synchronized to the owning client.
- Made contract completion feedback idempotent so repeated context-menu opening
  cannot replay rewards, sounds or mood effects.
- Added a 5% reward modifier per absolute Z level for elevated and underground
  mission objectives.
- Removed the legacy `RetrievePackage.lua` implementation.

### Betting And Interface

- Replaced the Poker list with a compact oval table for the CRT interface.
- Reduced Poker to six total seats and hide eliminated opponents from the table.
- Kept authoritative AI difficulty active while removing it from client
  snapshots and visible UI.
- Displayed each seat's latest action, current stack, cumulative hand
  contribution and revealed showdown cards.
- Added a stable randomized visual seat for the player.
- Added translation-safe Poker action rows and end-of-hand controls.
- Fixed Poker hands stalling after the player folded.
- Distinguished player elimination from table victory when a Poker session ends.
- Automatically cash out the player's remaining Poker stack when leaving,
  minimizing or closing the betting interface.
- Rebuilt Blackjack on a face-to-face oval table with dealer and player cards,
  values, bet and outcome contained inside the CRT.
- Rendered hearts and diamonds in red while clubs and spades retain the terminal
  green color.
- Replaced Zombie Race progress text with moving runner icons and delayed payout
  until the animation reaches the finish.
- Removed the obsolete SFX toggle from computer interfaces.
- Reworked the ATM layout to show ATM cash and player balance without overlap.

### Localization And Text

- Migrated UI and Sandbox translations to B42 `IG_UI.json` and `Sandbox.json`
  catalogs.
- Added English and French catalogs plus Czech, German, Spanish, Hungarian,
  Italian, Japanese, Korean, Dutch, Norwegian, Polish, Portuguese, Brazilian
  Portuguese, Russian, Thai, Turkish, Ukrainian, Simplified Chinese and
  Traditional Chinese catalogs.
- Migrated Request messages, mission-location descriptions, contract controls
  and major betting labels away from hard-coded UI text.
- Replaced the Request conversation label with a fixed rich-text panel supporting
  wrapping, conditional scrolling and automatic scrolling to new messages.
- Centralized UTF-8-safe simulated typing and human reply delays across Contracts,
  Requests, Internet login and ATM authentication.

### Fixed

- Fixed hosted multiplayer ATM deposits not removing physical cash and
  withdrawals not creating synchronized cash.
- Fixed nested carried bags and exact bundle change during ATM deposits.
- Fixed Dark Web and Request mailbox deliveries being consumed without creating
  a synchronized parcel or vehicle key.
- Fixed Mail and Dark Web reward flows consuming mission items before confirming
  reward creation.
- Fixed contract dialogue tracebacks caused by stale or missing local reward
  snapshots.
- Fixed contract objective flags not reaching hosted multiplayer clients after
  acceptance.
- Fixed delivered contract packages remaining in the player's inventory.
- Fixed repeated contract-completion messages and sounds after right-clicking.
- Fixed Request vehicle price display differing from the authoritative debit.
- Fixed empty Dark Web parcels, zero-quantity purchases and hidden quantity
  controls after filtering.
- Fixed Hacking manual input, attempt counters, card restoration and password
  leakage.
- Fixed Trading and Wallet charts when every displayed value is identical.
- Fixed cargo cleanup and duplicate zombie-spawn event registration.
- Fixed timed actions and UI paths receiving a missing world object or resolving
  the wrong local player.

### Internal

- Split static configuration and domain data into modules for economy, Dark Web,
  Trading, requests, contracts, mission locations, mail, gambling and Poker.
- Kept existing public table and helper names where required for save, UI and
  server compatibility.
- Prefixed sensitive network commands and results with `PZLinux`.
- Added Project Zomboid-aware LuaCheck configuration and removed the unsafe
  undefined-global warning class from the migration backlog.
- Final release validation still requires an updated full-repository metrics run
  and the documented two-client dedicated-server campaign.

### Known Limitations

- Controller navigation is not yet implemented.
- Split-screen is not officially supported.
- Afrikaans, Catalan and Vietnamese translation catalogs are not yet included.
- Generated translations still benefit from native-speaker proofreading.

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
