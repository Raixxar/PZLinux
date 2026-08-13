# Changelog

## [1.0.9]

- Added a "Manage player balances" tool to the existing PZLinux Admin
  context menu: a panel listing every currently connected player with
  their bank balance, letting an admin correct one directly by clicking
  their row, then setting a new balance. The target player is only ever
  settable by clicking a real row, never free-typed -- since this is
  scoped to online players only (below), every valid target is already a
  row in the list, so a separate editable username field would only add a
  typo risk (mistarget real money) for no actual capability gained.
  Deliberately scoped to online players only -- reaching an offline
  player's saved data would mean reading their save file directly, out of
  scope here. Directly useful after the Hacking/Poker money bugs fixed
  this release: previously the only admin money tool was "add funds to my
  own balance", with no way to inspect or fix another player's account.
  Every server-side function re-checks admin access itself, independent
  of the client menu being admin-gated. Also fixed a real, unrelated gap
  found while wiring this up: PZLinuxContractAdminForceMailResult was
  never recognized by the client's server-command dispatcher, so in real
  MP (not solo) the existing "Force a random mail mission" admin action
  would silently never report back to the client, even though the
  server-side mail really was created.
- Fixed a real, player-reported Hacking exploit plus a matching game
  crash: with multiple credit cards in inventory, clicking AUTO, then
  TRANSFER, then AUTO again *while the first transfer's countdown
  animation was still playing* (repeating that cycle) generated money
  without ever consuming more than the first hack's cards, and eventually
  crashed with a Lua error ("missing argument #1 to 'status'"). Root cause:
  the transfer countdown animation shared its coroutine/tick-handler
  fields with the unrelated boot-sequence animation, and every new
  transfer just overwrote those fields with a fresh coroutine/handler pair
  without ever unregistering the previous one from the game's tick event --
  reassigning the field doesn't unregister the old handler, which keeps
  running, orphaned, reading and clearing the very same fields the new one
  is using. Fixed with dedicated fields per animation (never shared again),
  a cleanup step that always tears down any previous animation by its own
  captured reference before starting a new one (on every transfer, and on
  closing the panel), stale buttons/labels now properly removed instead of
  merely hidden, and a server-side guard refusing to start a new hack while
  an existing one is unlocked and not yet transferred.
- Proactive audit for more money-related exploits after the v1.0.9 Hacking
  fix, across every coroutine/tick-driven animation, session-creation
  path (Race, Blackjack, Poker, Hacking) and reward-granting flow
  (Contracts, Mail, ATM refill) in the mod. One real bug found, in the
  opposite direction from the Hacking one: PZLinuxPokerCreateSession
  overwrote the player's active table unconditionally, with no check for
  one already in progress. A player seated with real winnings (built up
  over several hands) who re-triggered "join table" -- reachable simply by
  navigating back to the Betting menu and clicking POKER again, since the
  client's own lobby screen unconditionally forgets its local session
  tracking regardless of whether a real table is still active server-side
  -- would have that entire stack silently discarded: not refunded, not
  credited anywhere, just gone. Fixed with a guard that refuses to start a
  new table while one is still active, plus a restore-session path so the
  player lands back on their actual table (and stack) instead of getting
  stuck on a rejected join attempt. Also closed two lower-severity, non-
  exploitable hygiene gaps found along the way: every Poker control
  (buttons, labels) was only ever hidden, never actually removed from the
  UI tree (the same "stale accumulating widget" class fixed for Hacking/
  Trading previously, since ISButton/ISLabel don't have the :close()
  method the old cleanup code assumed they did), and the Contract
  completion button had no double-click guard, unlike every other money-
  moving button in the mod (the underlying payout function was already
  provably safe against a real double-payout on its own).

## [1.0.8]

- Added a sandbox option (PZLinux.CustomDarkWebItems, in the server's
  PZLinux settings page) letting a server admin add or re-price Dark Web
  items without editing any Lua file: free text, comma-separated
  "Base.ItemName:Price" pairs (e.g. "Base.Machete:1000,Base.MyItem:250").
  An item ID that already exists in the catalog has its price overridden
  instead of appearing as a duplicate entry; unknown item IDs and
  malformed entries are skipped safely. Applies everywhere the item
  catalog is used -- the daily buy offers, sell offers, and the in-game
  reference list -- with no default-behavior change if the option is left
  blank.
- Investigated a player report of reputation and bank balance both looking
  reset after restarting the game. Reputation lived in a nested modData
  table (md.pzlinux.player.reputation), unlike almost every other value in
  the mod, which uses flat top-level modData keys -- the pattern proven
  reliable across roughly 330 other usages. Both the reputation reader and
  the bank balance loader silently fell back to a default (neutral
  reputation; a random $500-$4000 balance) whenever their value read nil,
  with no way to tell "genuinely new character" from "the value was lost".
  Both now mirror their real value onto an independent flat backup key on
  every write, and recover from that backup before ever assuming a nil
  read means a fresh character -- belt and suspenders, so a save/reload
  round-trip glitch can no longer silently discard either value. Also
  closed the one place that read reputation through a raw getModData()
  call instead of the shared, now-repaired accessor.
- Fixed a related MP report: a player could repeatedly re-collect a Dark
  Web order they had already received at the mailbox, surviving log-outs
  and reconnects. The pending-order queues (Dark Web and Buy Goods alike)
  were only ever mutated in place with table.insert/table.remove -- the
  modData key itself was never re-assigned afterward, so a change could go
  unnoticed by sync/save and a reconnect could reload the pre-delivery
  state, delivering the same batch again. Every queue mutation now
  re-assigns its key right after (even to the same table), and the Dark
  Web delivery loop now transmits modData after every single batch
  removal instead of only once at the end, matching how the Buy Goods
  delivery loop already worked -- so a disconnect mid-delivery can't leave
  an already-collected batch still marked pending either.
- Addressed a player-reported exploit: a fresh character (no bank balance
  yet) always received a random $500-$4000 starting balance with no way to
  opt out, farmable for free money by repeatedly dying and creating a new
  character. The range is now sandbox-configurable (PZLinux.StartingBalanceMin/
  Max, in the server's PZLinux settings page) so an admin can set both to 0
  and remove the loop entirely, or tune the range; the defaults keep the
  exact $500-$4000 range this mod has always used. Also confirmed a
  separate hypothesis raised alongside this report -- that reusing a dead
  character's name might let a new character inherit their balance -- does
  not hold: the balance lives exclusively on modData, the same per-
  character storage PZ itself uses, never looked up by username or
  character name anywhere in this mod's code.

## [1.0.7]

- Proactive audit after the Blackjack race-condition fix below, looking for
  the same bug class elsewhere before a player hits it. Found and fixed two
  more:
  - Poker had the identical race: closing the betting panel right after
    Call/Raise/Fold/etc. could auto-cash-out before that action's own
    effect on the stack was applied, same fix as Blackjack (wait for any
    in-flight action to land first).
  - The Trading BUY/SOLD buttons and the Buy Goods order confirmation never
    disabled themselves during their server round trip, unlike every other
    buy/sell/confirm button in the mod -- a double-click could silently
    charge twice for one intended click. Neither lost money or created
    free items (each order/trade is independently validated and priced),
    but both now guard against it for consistency.
- Fixed a multiplayer-only Blackjack bug where a hand could resolve for a
  real win or loss and then have its bet silently refunded anyway, leaving
  the balance unchanged ("it's like free gambling"). The Close/Minimize/
  Leave buttons on the betting panel were never disabled while a Hit or
  Stand request was in flight, unlike Hit and Stand which disable each
  other -- so clicking Stand and then immediately leaving (very natural
  right after seeing you've lost) could send a forfeit-on-close request
  that raced the still-pending Stand response for the same hand. Since
  forfeiting refunds any hand it still finds open, it could cancel out a
  result that was already on its way. Closing the panel now waits for any
  in-flight Deal/Hit/Stand response to land before deciding whether there's
  still a hand to abandon.
- Added a small explanation when a Dark Web or Buy Goods order is stolen
  during delivery (the same pre-existing 10% theft roll shared by both
  systems). Previously the only feedback was a small HaloText bubble over
  the character's head, easy to miss entirely if the player looked away or
  was mid-fight, leading to reports that were actually just this chance
  roll going unnoticed. A stolen order now also drops a small torn note
  into the player's inventory, with one of twenty random flavor messages,
  translated into all 20 supported languages. The note is shared code, so
  Dark Web and Buy Goods can never drift out of sync on this again.

## [1.0.6]

- Fixed the computer's "Repair" option only ever appearing below 15%
  condition. A single repair attempt almost always pushes condition back
  above that threshold on its own, so the option immediately disappeared
  again, leaving the computer stuck well short of full health instead of
  being repairable back to 100% over as many attempts (and as much
  Electronic Scrap) as it takes. It now stays available any time condition
  is below a healthy 80% buffer.
- Added fixed-stakes Blackjack tables (Micro $10-$100, Low $50-$500, High
  $200-$1,000, Elite $1,000-$5,000), the same idea as the existing Poker
  lobbies: pick a table before dealing, and your bet is capped to that
  table's own posted limits. Without any cap, a lucky streak could
  compound a small bankroll into an enormous one in just a handful of
  hands. The payout odds themselves are untouched -- 1:1 for a normal win
  and 3:2 for a natural blackjack, the real casino odds -- since the fix
  for unlimited growth is a table limit, not worse odds. Stakes are
  deliberately fixed rather than scaled with world-age price inflation,
  like a real table's posted limits never move.
- Rebalanced the Poker lobby blinds/buy-ins down (Micro $100-$200, Low
  $500-$1,000, High $2,000-$4,000, Elite $5,000-$10,000) to match the same
  design goal as the new Blackjack tables: even the top lobby's maximum
  buy-in now stays below the single best-paying contract, so gambling
  stays a fun distraction rather than a way to out-earn actually playing.
  The old lobbies (up to $10,000/$5,000 blinds, $1,000,000 max buy-in)
  predated that goal by a wide margin.

## [1.0.5]

- Fixed a sold-out Dark Web offer disappearing from the buy list instead of
  staying shown disabled. Every offer after it in the list would silently
  shift up one row to fill the gap, but each row is a reused button and
  quantity box -- so a quantity already typed for one item could end up
  attached to a completely different item that slid into that same row,
  making it possible to buy (and receive) something other than what was
  on screen when you typed the quantity. Rows also now clear their typed
  quantity whenever they get rebound to a different offer, as an extra
  safeguard against the same kind of mix-up from any other cause (e.g.
  the search filter).
- Fixed closing or minimizing the betting panel mid-hand of Blackjack
  silently abandoning it: the bet already taken at Deal time was never
  settled or refunded, unlike Race and Poker which were already protected
  the same way. Walking away from a hand now refunds the bet (treated as
  a push) instead of the money just vanishing with the orphaned hand.
- Added a short cooldown between Blackjack Deal/Hit/Stand clicks to guard
  against a click landing twice almost simultaneously (a worn mouse's
  double-click defect, a fast real double-click, or a click racing the
  button's own disable-on-click before it takes effect), which could let
  a hand's outcome resolve faster than intended.
- Fixed a PZLinux window sometimes getting stuck glued to the mouse cursor
  after certain click sequences (e.g. clicking the bet amount field then a
  runner's name on the Zombie Races screen), with no way out except ESC.
  Every PZLinux panel drags itself manually and relies on its own title bar
  catching the mouse release to stop -- if a click landed on the wrong
  child widget that release could get missed, leaving the panel chasing
  the cursor forever. Releasing the mouse button anywhere now reliably
  lets go of any panel currently being dragged, on every PZLinux screen.

## [1.0.4]

- Fixed the computer's right-click menu sometimes not appearing at all when
  the Desktop Computer was placed on top of furniture (e.g. a counter),
  even standing right next to it. The game's own click detection can skip
  a computer stacked on furniture in favor of the furniture itself; the
  menu now also checks everything actually sitting on the same tile, not
  just what the game already picked out.
- Fixed the mailbox/ATM/computer context menu sometimes appearing on
  unrelated B42 objects (e.g. a newspaper dispenser instead of the actual
  mailbox), which then failed every action with a generic error. The menu
  matched sprite names with a substring search instead of an exact match,
  so a new object whose sprite name happened to start the same way (e.g.
  "street_decoration_01_90") was wrongly treated as a mailbox.

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
