# Update v.1.0.0
- Added a first B42.20.0 stable hardening pass for the 1.0.0 release.
- Fixed ATM, mailbox and street mailbox timed actions receiving a missing world object.
- Fixed timed actions and several UI paths using the wrong player object in local split-screen or MP contexts.
- Added shared PZLinux player/modData helpers to reduce nil modData errors.
- Fixed contract completion reputation update when the active contract reaches the completed state.
- Fixed cargo cleanup state handling.
- Removed forced mail debug timing and duplicate zombie spawn event registration.
- Fixed dark web data issues caused by missing `Price` fields and invalid item ids.
- Fixed dark web purchases creating empty mailbox parcels or awarding XP without a real purchase.
- Fixed dark web quantity inputs staying hidden after search/filter refresh.
- Fixed hacking manual input visibility, password debug logging, auto-hack single-card reward and attempt counter handling.
- Fixed request UI debiting the displayed discounted total instead of the raw item price.
- Fixed contract company price updates using the wrong hard-coded company index.
- Fixed trading and wallet chart edge cases when all values are identical.
- Added centralized mission location scaffolding in `ISPZLinuxVariablesTables.lua`.
- Added finite ATM cash reserves stored on the ATM object. Each ATM starts with $10k-$50k on first use, displays its available cash and refuses withdrawals above its local reserve.
- Added the first dedicated UI translation file and migrated ATM labels/messages to `IGUI_PZLinux_*` keys.
- Added MP/economy, price balance and variables/translations/prefixes audit documents for the 1.0.0 migration.
- Added local validation tools under `tools/` for static audit, Lua syntax/LuaCheck, PNG/OGG metadata checks and Project Zomboid console tailing.
- Added local tools to list unprefixed global functions and hardcoded UI text candidates.
- Added shared bank helpers and server commands for bank sync/debit, used by the new betting flow in MP while preserving local solo behavior.
- Made ATM deposits and withdrawals server-authoritative in MP through prefixed `PZLinuxAtm*` commands: the server syncs the ATM state on open, validates the player balance, physical cash and ATM reserve, then applies inventory/bank/object mutations atomically before syncing the result back to the client.
- Reworked online betting into a hub with Zombie Race and Blackjack.
- Added Blackjack with a real 52-card deck, no duplicate cards, dealer draw rules, debit on deal and server-side payout resolution in MP.
- Moved Zombie Race card generation, winner selection, debit and payout through PZLinux server commands in MP.
- Added betting mood effects: boredom reduction while playing, stress from risky stakes and happiness/stress relief on meaningful wins.
- Centralized ATM bank balance load/save through the shared PZLinux bank helpers.
- Rebalanced the Dark Web economy with higher minimum prices for firearms, ammunition, explosives, books, rare magazines, generators, armor and strong melee weapons.
- Increased Request base prices and capped the PlantScavenging request discount at 15%.
- Reduced easy contract rewards while keeping dangerous high-tier contracts profitable.
- Reduced Luacheck noise from 933 to 569 warnings, removing the W121/W113 risk class through safer helper naming and a Project Zomboid aware lint configuration.
- Centralized direct `getPlayer()` usage behind the shared PZLinux player helpers; client UI/contract flows now use the player passed by PZ (`player` or `self.player`) instead of implicitly resolving player 0.
- Reduced Luacheck noise to 328 warnings / 0 errors after the getPlayer MP compatibility pass.
- Made Dark Web buy/sell flows server-authoritative in MP while preserving the solo fallback: the server now generates and validates buy offers, debits purchases, records pending deliveries, scans/removes sold inventory items, creates suspicious sale packages, delivers purchased parcels through mailboxes and credits completed sales.
- Secured mailbox interactions against remote commands: Dark Web deliveries and sale redemption, Request deliveries and contract deposits now require a real supported mailbox within two tiles of the server-side player position and on the same Z level.
- Added `PZLinuxWorldInteractions.lua` for canonical mailbox references and server validation, plus `tools/test_mailbox_proximity.lua` covering missing, forged, distant and wrong-Z interactions.
- Reduced Luacheck noise to 317 warnings / 0 errors after the Dark Web server-authoritative pass.
- Made Trading server-authoritative in MP while preserving the solo fallback: the server initializes and ticks shared market prices, clients request a snapshot, and buy/sell orders are validated with server-side price, bank balance and wallet quantity before mutation.
- Added a server-authoritative 5% Trading fee per transaction: purchases debit the gross value plus the fee, sales credit the gross value minus the fee, and the UI displays the charged fee and final amount.
- Updated the Wallet UI to use the same Trading snapshot so portfolio values are based on the server market state.
- Reduced Luacheck noise to 315 warnings / 0 errors after the Trading server-authoritative pass.
- Added a server-backed Contracts board shared through `PZLinuxContractsBoard`, so clients receive the same weekly contract list in MP.
- Moved contract accept, cancel, mailbox deposit and final payout/reputation through prefixed server commands while preserving solo fallback behavior.
- Removed client-side contract payment, local company price mutation and local mailbox item-removal authority from the main contract flow.
- Reduced Luacheck noise to 307 warnings / 0 errors after the Contracts server-authoritative pass.
- Moved contract world events through `PZLinuxContractWorldEvent`: zombie kill progress, manhunt zombie spawn, cargo object spawn/removal, protect horde spawn, contract pickup/cargo/cut/blood/capture/protect timed-action outcomes now ask the server in MP while preserving solo fallback behavior.
- Added server-side reputation helpers and server-side reputation decay for online MP players; contract completion reputation is now applied through the same shared helper.
- Stopped MP clients from granting mail reputation locally; mail rewards still need a dedicated server-authoritative pass.
- Reduced Luacheck noise to 280 warnings / 0 errors after the Contracts spawns/reputation server-authoritative pass.
- Added a global Contracts world registry in `PZLinuxContractsWorld`: accepted contracts now receive a persistent `PZLinuxContractId`, track owner/deliveredBy/completedBy/status, and transmit their state through global ModData.
- Tagged spawned cargo objects, manhunt/protect zombies when possible, and generated contract delivery items with `PZLinuxContractId`/objective metadata.
- Made tagged delivery items claimable by any player at mailbox deposit, allowing stolen contract objectives to be completed by the player who actually delivers them.
- Made tagged cargo objects expose the cargo context action to other players through the global contract record.
- Made Request orders server-authoritative in MP while preserving solo fallback: the server validates requested items/vehicles, validates vehicle delivery locations, applies survival-time and SandboxVars pricing, debits the bank, stores pending deliveries and spawns requested vehicles.
- Moved Request mailbox delivery and requested vehicle spawn out of direct client mutation and through prefixed `PZLinuxRequest*` server commands.
- Fixed requested vehicle price delta display so expensive vehicles no longer appear cheaper than the server-side debit.
- Reduced Luacheck status remains 280 warnings / 0 errors after the Request server-authoritative pass.
- Made Mails server-authoritative in MP while preserving solo fallback: mail generation, accept, delete, delivery validation, requested item removal, reward gift creation and reputation reward now pass through prefixed `PZLinuxMail*` commands/helpers.
- Mail missions now initialize item, quantity and location through shared mail helpers so the displayed email, map marker and server validation use the same data.
- Removed direct client authority from mail completion rewards; the timed action now asks the server and only plays local feedback after confirmation.
- Reduced Luacheck status to 279 warnings / 0 errors after the Mail server-authoritative pass.
- Made Hacking server-authoritative in MP while preserving solo fallback: card consumption, hacked account generation, password attempts, account lock and bank transfer now pass through prefixed `PZLinuxHacking*` commands/helpers.
- Removed the Hacking password from server responses and client state. Manual sessions now expose only the four-digit code length, while guesses, partial feedback, locking and unlock state remain evaluated by the server-held session.
- Added `tools/test_hacking_authority.lua` to prevent the password or a client-side `serverPassword` field from being reintroduced.
- Removed direct client authority from hacking rewards/transfers; the client now only displays the terminal UI and applies local feedback after server confirmation.
- Reduced Luacheck status to 263 warnings / 0 errors after the Hacking server-authoritative pass.
- Split the first editable/static data blocks out of `ISPZLinuxVariablesTables.lua` into dedicated shared modules under `shared/PZLinux/`: config, mission locations, gambling data, request definitions, contract definitions and mail definitions.
- Kept the MP-compatible runtime helpers in place while preparing the next extraction pass for Dark Web, Trading and economy formulas.
- Moved the Dark Web item/price catalog into `shared/PZLinux/PZLinuxDarkWebData.lua` while keeping the existing `PZLinuxDarkWebItemsTable` API for compatibility.
- Moved Dark Web runtime and MP/solo callback wrappers into `shared/PZLinux/PZLinuxDarkWeb.lua` while keeping the existing global helper API for UI/server compatibility.
- Moved the Trading company catalog into `shared/PZLinux/PZLinuxTradingData.lua` while keeping the existing `PZLinuxTradingCompanyNameTable` API for compatibility.
- Moved economy formulas into `shared/PZLinux/PZLinuxEconomy.lua`: money normalization, Dark Web prices, Request prices, Trading price movement, reputation delta and mail delay calculation.
- Renamed the remaining unprefixed bank, Blackjack and race network commands/results to `PZLinuxBank*`, `PZLinuxBlackjack*` and `PZLinuxRace*`.
- Capped the rare mail reward cash bonus from a possible `$1-$1999` roll to `$100-$300`.
- Removed the W212 Luacheck category by marking intentionally unused Project Zomboid callback arguments with `_` names; full Luacheck is now 128 warnings / 0 errors.
- Added generic server idempotency by player, command and `requestId`; duplicate network retries now return the cached result instead of replaying economic/world mutations.
- Added restart rollback for temporary sessions: interrupted Blackjack sessions refund the stored bet, and interrupted Hacking sessions restore consumed cards when the player next reaches the server.
- Added Texas Hold'em Poker to Online Betting: configurable lobbies, isolated solo/MP sessions per player, server-authoritative buy-in/actions/cashout, masked AI cards before showdown, AI opponents, side pots, hand evaluation tests and restart rollback of the current player stack.
- Added `PZLinuxPokerStart`, `PZLinuxPokerAction` and `PZLinuxPokerCashOut` network commands with `PZLinuxPokerState` responses.
- Added Poker configuration under `PZLinux.Poker.Config` for blinds, buy-in limits, AI stacks, opponent count, AI difficulty weights, bluff rates, decision delay and economic limits.
- Improved Betting readability: added fallback labels when Project Zomboid translations are not loaded, made Blackjack/Poker cards human-readable, cleaned race runner names and compacted the Poker table UI.
- Added French UI translations in `shared/Translate/FR/IG_UI.json` with the same keys as the English reference file.
- Poker now automatically cashes out the remaining temporary stack before closing, minimizing or returning from the betting interface, preventing accidental fund loss when leaving the UI.
- Reduced Poker default table size to 5 seats total (player + 4 AI) and tightened the table action/history layout to better fit the CRT interface.
- Moved the Poker action history into a dedicated right-hand column so player cards and table events no longer overlap.
- Rebuilt the Build 42.20 mission-location catalog with shared pools for 37 package locations, 22 cargo locations, 16 manhunt locations, 7 protection locations and 36 vehicle spawn locations.
- Reused the 37 validated package destinations for ammunition and medical mail drops.
- Added city-aware mission pools for Irvington, Ekron, Brandenburg, Echo Creek, Riverside, Fallas Lake, Rosewood, March Ridge, Muldraugh, West Point, Valley Station, Louisville and Coalfield.
- Added a 5% contract reward modifier per absolute Z level for more dangerous underground or elevated objectives.
- Added `tools/audit_locations.lua` to validate mission IDs, coordinates, enabled entries and per-city pool coverage.
- Removed the legacy `RetrievePackage.lua` contract implementation and migrated package retrieval to the shared contract dialogue/location flow.
- Extracted contract target names and automobile, medical and weapon request tables into `PZLinuxContractRequestData.lua`.
- Moved contract company codes and contract definitions into `PZLinuxContractsData.lua` and shared dialogue behavior into `PZLinuxContractDialogue.lua`.
- Refactored the remaining contract conversations onto a common coroutine/dialogue skeleton while preserving their informal IRC writing style.
- Refactored Request data into `PZLinuxRequestsData.lua` and removed duplicated inline request tables from the UI.
- Replaced the Request conversation label with a fixed `ISRichTextPanel` supporting automatic wrapping, conditional scrolling and automatic scrolling to the newest message.
- Moved Request interface messages and mission-location descriptions to `IGUI_PZLinux_*` translation keys with English fallbacks.
- Added 18 additional translation catalogs: Czech, German, Spanish, Hungarian, Italian, Japanese, Korean, Dutch, Norwegian, Polish, European Portuguese, Brazilian Portuguese, Russian, Thai, Turkish, Ukrainian, Simplified Chinese and Traditional Chinese.
- Added `tools/check_translations.lua`; all 20 catalogs currently contain the same 284 unique keys, valid UTF-8 and matching dynamic placeholders.
- Migrated all UI and Sandbox translation catalogs from the legacy `.txt` format to the locale-independent `IG_UI.json`/`Sandbox.json` format required by B42.20.
- Connected the Contracts balance and Yes/No controls to the translated UI catalog instead of hard-coded English labels.
- Added `tools/generate_translations.pl` to regenerate selected language catalogs while protecting placeholders and proper location names.
- Updated the release audit with current MP authority gaps, location coverage, localization status and the remaining 1.0.0 test checklist.
- Made contract acceptance fully server-authoritative: clients request a canonical `PZLinuxContractPreview`, then send only `contractId` when accepting.
- The server now selects contract locations, Z levels, targets, requested items, quantities and rewards from its own board and shared allowlists, then creates the canonical contract note and world record.
- Prevented modified clients from increasing rewards through forged Z levels or changing contract objectives through `location`, `info`, `quantity`, `note` or reward fields.
- Added `tools/test_contract_authority.lua` to validate canonical mission generation and prevent sensitive client fields from being reintroduced into `PZLinuxContractsApplyAccept`.
- Hardened every contract world-event command against forged clients: the server now resolves real objects, corpses and zombies, checks player distance/Z, canonical mission position, persistent contract tags and the expected world-record state before mutating anything.
- Moved Kill Zombies, Protect and Blood kill accounting to the server `OnZombieDead` event using the server-side attacker and objective tags; forged `zombieKilled` and `clearCargo` client events are rejected.
- Removed client-side zombie/corpse deletion from Capture and Manhunt timed actions. Cargo, captured zombies and target corpses are now removed only by the server after successful validation.
- Removed automatic client `contractId` injection from contract world events. Cargo and Manhunt ownership are derived from the selected entity's persistent `PZLinuxContractId`, preserving stealable MP objectives without trusting the sender.
- Removed the client reconnect reset that changed an already spawned Manhunt target back to its pre-spawn state.
- Added `tools/test_contract_world_authority.lua` to prevent client kill counting, forged contract coordinates/IDs and client-side entity removal from being reintroduced.
- Fixed Dark Web mailbox deliveries on hosted/dedicated servers: completed parcels are now explicitly synchronized to the owning client's inventory with the B42 container packet.
- Dark Web pending orders are no longer consumed when the parcel or purchased contents cannot be created, and mailbox UIs now display the server rejection reason.
- Added `tools/test_darkweb_delivery.lua` covering parcel contents, MP inventory synchronization and retry-safe pending orders.
- Fixed a Contracts dialogue traceback when a Lua reload or stale client cache cleared the local reward table: dialogues now retain the canonical server preview reward and never overwrite valid ModData with `nil`.
- Applied the same reward snapshot/fallback handling to all inline and externalized contract conversations.
- Fixed hosted/dedicated MP contract acceptance not synchronizing objective flags to the client, which could draw a package marker without exposing the retrieval context action.
- Package retrieval can now recover its actionable state from the persistent world-contract record, and server-created contract cases, corpse bags and blood jars are explicitly synchronized to the client inventory.
- Package retrieval no longer depends on right-clicking an arbitrary map object near the marker: the option is exposed from the player's real position inside the five-tile objective zone, which is independently validated by the server.
- Added `PZLinuxContractSync`: reconnecting clients request their canonical active contract, objective flags and location from the server, and closing the PZLinux computer performs the same synchronization automatically before leaving the terminal.
- Contract context menus now perform a silent server resynchronization while an objective is active, throttled to one request per player every ten seconds; mailbox deposit results also apply their next-stage state immediately.
- Removed the Electricity-skill modifier from simulated player typing in Contracts, Request, Internet login and ATM screens; every player now uses the same short delay configured by `PZLinux.Config.UI.typingDelay`.
- Current release validation passes Lua 5.1 syntax on 55 files, assets, all mission-location pools, all 20 translation catalogs, contract authority/world-event authority and the standalone Poker engine tests; Luacheck remains at 113 warnings / 0 errors.

# Update v.0.1.12-rc1
- Fixes an issue where the contract interface was offering only a single contract type.

# Update v.0.1.12
- In contracts where you need to find a briefcase, you now have a chance to find money and a weapon inside.
- Reduced resale prices for all items on the dark web.
- Added all skill magazines to the dark web.
- Added all skill books to the dark web.
- Reduced computer wear by half, meaning it will need to be repaired less often.
- Fixed a bug where the contract requiring zombie kills was not counting kills toward contract completion.
- Reduced the reward for the contract requiring a live zombie capture.
- Removed the note from the inventory when the player requests a car.
- Add Random sold for new player.
- Increased prices for requests to adjust the mod’s balance.
- The reward for the contract requiring zombie kills is now based on the number of zombies to eliminate. A higher kill requirement will now grant more money.
- Added a chance that no one connects to the room for the player’s requests.
- Increased the waiting time for player requests.
- Your parcels now have a 10% chance of being stolen when you try to retrieve them from the mailbox.
- You can now find electronic equipment on the dark web.
- It is now possible to hack multiple cards at the same time using the auto function. However, this feature provides lower rewards.
- Due to major changes in the Lua API, the mod is no longer compatible with versions prior to B42.13.
- New contract: To complete it, you must send a computer.
- New contract: To complete it, you must send a fridge.
- Added a reputation system to the game. The more contracts you successfully complete, the higher your reputation, unlocking various advantages.
- Added a mail interface: other survivors can now contact you for special missions.
- Added missions requiring ammunition delivery in mail UI
- Added missions requiring medical supply delivery in mail UI
- Changed the email domain from Hotmail to AOL, which is more consistent with the 1994 time period.
- Added ads and spam emails.
- Added a notification for new emails on the PZLinux desktop.

# Update v.0.1.11-rc6
- Fix the LUA errors in the ATM interface when the password is entered.
- Fix an issue where the computer couldn't be repaired even if you had the electronic parts in your inventory.
- Computer repair now only appears below 15%, whereas it was at 50% before.

# Update v.0.1.11-rc5
- Change of the formula for the player's typing speed on the computer keyboard; it is now more realistic.
- Change of the mod sound volume; the sounds are slightly decreased.
- Fixed an issue where players could receive an empty package when purchasing a quantity of 0 in the DW.
- Fixed an issue where players could increase their skill without making any purchases.
- Fixed LUA errors when the player kills a zombie.
- Information about car parts to be sent is now in the contract note.
- Fixed an issue where car parts couldn't be sent to complete the contract.
- Adjusted the reward for the car parts contract; the values are now more realistic with the parts' worth.

# Update v.0.1.11-rc4
- Added a sandbox option as a multiplier for sale prices.
- Fixes an issue where the quest completion menu does not display correctly for certain contracts.
- Fixes LUA errors for the quest requiring zombie kills.

# Update v.0.1.11-rc3
- Fixes an issue where the contract could not be properly removed in a new game.
- Added a sandbox option to the mod to adjust the multiplier on item prices.

# Update v.0.1.11-rc2
- Resolve an issue where you might have information from an unaccepted contract.

# Update v.0.1.11-rc1
- Fix an issue where the second player couldn't properly use the mod.
- Changes to online betting: the odds are never 1/1, which offers no return on a win. The minimum odds are now 2/1.
- Buying or selling items increases your 'Foraging' level.
- Contracts now display the destination city when necessary.
- Fixing the computer increases your electricity level.
- Succeeding in hacking increases your electricity level.
- Hacking a credit card now reduces your boredom.
- Successfully hacking for profit boosts your joy and lowers your stress.
- Betting reduces your boredom.
- Losing an online bet, depending on the wager amount, decreases your joy and increases your stress, while winning boosts your joy and lowers your stress.
- Selling stocks based on their value increases your happiness and reduces your stress.
- Successfully completing a contract reduces your boredom and stress while increasing your happiness.
- Some of the tables are now separated into a separate file, allowing you to modify them as you wish.

# Update v.0.1.11
- The contract log is now on a piece of paper to take up less space in the player's inventory.
- Added more information about the ongoing mission in the contract note.
- Fixed an issue where the message could overflow off the computer screen.
- Fix the LUA error on mailbox that could occur if a request was not initialized correctly.
- Requesting a car now adds a note to your inventory for easily locating this vehicle.
- Adding music when you successfully complete a contract.
- Annotations on the map are now removed if you cancel or complete a contract.
- The computer now consumes energy for the generators.
- The ATM now consumes energy for the generators.
- You can view this energy consumption in the generator info sheet.
- Computers now have a condition like generators and require electronic parts for repairs.
- Added a menu to track the computer's status.
- Introduced two different startup sounds based on its condition. A computer in poor condition will have its disk click at startup.
- Bars and ingots are now available for DW.
- Items purchased on the dark web must now be collected from a mailbox.
- Items in the request interface are now affected by your 'Foraging' skill. A skill reduces the price of items.
- Added multiple halo alert messages to assist the player.

# Update v.0.1.10-rc2
- Fix a bug where the annotation does not appear correctly if the player has never opened their map.
- Fix a bug where the price was not updated correctly for stock actions if the player has never opened the trading interface.

# Update v.0.1.10-rc1
- Fixed a bug where the indicator on the map didn't appear correctly in new games.
- Contracts are now available in the first week for new saves.
- Fix the error message for mailboxes when sending a package.

# Update v.0.1.10
- Added multiple spawns for the quest to retrieve a package.
- In a mission, each zombie killed = $5 bonus.
- Fix a bug where the pagination did not disappear properly after selecting a query.
- Fix a bug where the capture quest was not correctly reset upon completion.
- Items in the requests are now mixed to create a diverse selection in the delivery box.
- Adding electronic components to the requests.
- Adding repairing components to the requests.
- Adding materials components to the requests.
- Adding seeds components to the requests.
- New contract: prepare a cargo to be airlifted by helicopter (lvl:4)
- New contract: Protect a building (lvl:5)
- New contract: Find and send medical equipment (lvl:2)
- New contract: Find and send weapons (lvl:3)
- Contracts now add a circle and a summary directly on the map.
- Fixed a bug where the ID card was not properly consumed after pressing 'Next'.
- It is now possible to hack credit cards like ID cards.
- When you request a car, it now appears on your map for you to pick up.
- Mailboxes now allow for taking and depositing with a single click.
- Zombies killed are now added to the contract notebook to track your mission status.

# Update v.0.1.9-rc1
- Fix an issue where the quest to collect zombie blood did not require killing a new target.
- Fix an issue where TimedAction wasn't properly closed after an interface closure.
- Fix for a glitch where the credit card was not properly consumed.
- Fix an issue where the fish were not delivered after a purchase.

# Update v.0.1.9
- Create zombie races for online betting.
- Add a contract to capture a live zombie for the race.
- Reducing the contract interface during message animation now correctly links back to the contract list.
- Fixing a bug or buying and selling an item closes the PZLinux interface.
- Added all modern and normal pieces to the auto part quest rotation.
- Increase the detection menu radius for the PZLinux menu.
- It is now possible to purchase vehicles.
- PZLinux actions can now be accelerated over time.

# Update v.0.1.8-rc2
- Correct a variable error in contracts due to the v0.1.8-rc1 update. Sorry!

# Update v.0.1.8-rc1
- Added an SFX button to shorten the duration of mod animation messages.

# Update v.0.1.8
- All values are now integrated into ModData. the PZLinux.ini file is no longer used.
- Fix an issue where the interface position resets to default with each submenu change.
- Add cigarettes and cigars to the list of items that can be bought and sold.
- Add several knives and hats to purchase and sale on Dark Web. Thank you CdrCanteets for your help.
- Add credit cards on the Dark Web. These cards can then be hacked to obtain more money.
- Fix an issue where stock prices for companies were capped.
- Added bounty contracts for hunting down targets and eliminating them.
- Added contracts for object retrieval.
- Added contracts for zombie blood analysis.
- Added contract to send sports car parts.
- Fix an issue where the computer could be launched remotely
- Fixed an issue where mailboxes could be opened remotely.
- Fixed an issue where the ATM could be opened remotely.
- The value of purchases is now indexed to the world's time. The longer survival lasts, the more expensive prices become.
- You can now make requests on IRC to purchase canned goods, fish, books, fruits, meats, and vegetables.
- Added a notification sound for new messages on IRC
- Price balancing on the dark web. With contracts and requests features, selling prices are adjusted downward to balance the mod.
- Fix an issue where the interface closes correctly if the player moves away from the computer.

# Update v.0.1.7-rc1
- Fix the issue where the mailbox interface was not available based on the mailbox direction.

# Update v0.1.7
- Correct a spelling mistake on the hacking interface regarding the word 'transfer'.
- All interfaces are now movable to make handling in your inventory easier.
- Fixed a bug where the dark web couldn't generate an object list for the first 24h.
- Fix a bug where the item was not properly removed after a sale on the dark web while performing another action.
- Changing the 'Sold' button to 'Sell' on the dark web interface for better understanding.
- The sound volume of the different interfaces is now adjusted according to the overall game volume level.
- Added a new interface for selling items.
- Added two new interfaces for dropping off your packages.
- Buying and selling are now two separate interfaces.
- Selling items now generates a suspicious package.
- To finalize your sale, you must drop your package in a mailbox.
- Reduction of items available for purchase to a maximum of 50. The previous limit was 100 before the update.
- Added a help interface that shows the list of items available for sale and purchase.
- The limit in the mastermind menu is now correctly set to 6 attempts.
- Entering a code other than 4 digits no longer counts as a try.

# Update v0.1.6
- Fixed a bug where the token count was not displaying correctly in the trading interface.
- Fixed a bug where money deposited in the ATM is not accounted for players with special characters in their names.
- Integration of modData for player money, meaning the debug file will soon be removed.
- Added modes and magazines for your weapons.
- Added a hacking interface. This allows hacking bank accounts using ID cards found on zombies.
- Fix the interface to support 4K resolutions.
- Added buttons to navigate through the different submenus of the mod. You no longer need to type commands to enter the submenus.
- Clean up the wallet when the quantity of your stocks reaches 0 for better clarity in this interface.

# Update v0.1.5
- The connection speed on the internet is now linked to your electrical skills. A higher level allows for a faster connection.
- Fix the search issue that hasn't been working properly since the last update.
- The value of prices is now linked to your search skill. A higher skill results in lower purchase prices and higher selling prices.
- You can now press enter in the search field to initiate your search.
- Article updates on the dark web are now done every 24 hours, game time. You can find new articles every day in the game.
- Add a trading interface, allows for trading in Project Zomboid.
- A wallet interface has also been added to track your assets.
- Code cleanup that should resolve button overlap issues.
- For clarity, the mode name will switch to a new name: PZLinux.
- You must now use this mod with the PZLinux menu.
- You must now be connected to the internet to navigate through the different submenus.
- You are now connected for 24 hours, game time, before being automatically disconnected.
- The computer also stays on for 24 hours before shutting down automatically.
- Add a sound when the computer starts.
- Add a message if you are not connected to invite you to do so before using the submenus.
- The power button is now located at the bottom left of the CRT.

# Update v0.1.4
- Resolve the issue where the dark web could be accessed on non-computer devices.
- Fix the problem preventing items with the same name in the interface from being sold.

# Update v0.1.3
- Add ATM for storing money
- Add Sound for ATM
- Add Deposit option
- Add Withdraw option
- Add Ability to move money from backpack
- Add Sound for buy/sell action
- Add Sound for buy/sell error
- Add Button to stay connected
- Add Button 3 to scroll in the menu
- Add Link ATM to the dark web
- Fix Scroll menu not centered
- Fixed bug in logs when the computer starts

# Update v0.1.2
- Fix a bug that prevents selling in nearby inventories.
- Add the option to pay with Money Bundles, each worth 100 Money.
- Improve performance to prevent crashes or FPS issues.

# Update v0.1.1
- Added a "Power OFF" button to shut down the computer before initialization finishes.
- Fixed the bug where the interface wouldn't completely disappear upon disconnection.
- The Power OFF button now replaces the disconnection button.
