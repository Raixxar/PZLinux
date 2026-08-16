# Changelog

## [1.0.13]

- Fixed a single-player startup crash reported on Build 42.20.2 when restoring
  an existing persistent character identity. The identity registry no longer
  calls Lua's unavailable `next()` primitive and now checks native bindings
  through a Kahlua-compatible iterator.
- Raised the mailbox delivery ceiling from 85% to 200% of the character's
  normal carrying capacity. Dark Web, Buy Goods and mail-reward parcels can now
  be collected while reasonably overloaded; a complete parcel that would cross
  the configurable ceiling remains queued without losing any contents.
- Added a translated mailbox warning in all 20 languages when parcels remain
  queued because the 200% ceiling was reached, plus a server result log showing
  delivered parcels, remaining orders and the active weight multiplier. The
  translation audit now validates 600 keys per locale.

## [1.0.12]

- Fixed a Build 42.20 server compatibility regression in persistent character
  identity lookup. The mod no longer probes the nonexistent reflected Java
  methods `IsoPlayer.getSqlId()` and `IsoPlayer.getSqlID()`; it reads the native
  `sqlId` field and keeps the descriptor ID as its portable fallback.
- Restored the complete server-authoritative command path for all 13 contracts.
  The identity exception could interrupt board access, preview, acceptance,
  synchronization, cancellation, deposits, world objectives and completion;
  Manhunt and Cargo made the failure especially visible because their nearby
  objectives could never reach the normal spawn path.
- Restored Request vehicle ordering, nearby server spawn and client visibility
  confirmation when the authoritative bank ledger is enabled. Vehicle delivery
  IDs, server-side duplicate detection, synchronized keys and retry behavior are
  unchanged and remain active in solo and multiplayer.
- Added release regressions that require the complete 13-contract catalog and
  prevent contract or vehicle paths from reintroducing invalid SQL accessor
  probes.
- Localized the interactive main computer menu across all 20 supported
  languages, including Simplified and Traditional Chinese. Network status,
  feature buttons, the welcome line and the connection warning no longer use
  hardcoded English; the period-appropriate boot sequence intentionally
  remains in English.
- Added a regression test that rejects hardcoded English feature labels in the
  main computer menu. The translation audit validates 599 keys per locale for
  this release.
- Aligned Dark Web Sell rows with Buy rows: item names now use the first line,
  price and available stock use a dedicated second line, and quantity plus the
  localized Sell button are anchored from the scroll panel's right edge. Stock
  therefore remains visible instead of being covered by the quantity field.

## [1.0.11]

- Added a server-bound persistent character identity, backed by Project
  Zomboid's native SQL character ID when available. Delivery queues and the new
  authoritative bank ledger are now indexed by character rather than username,
  so a replacement character on the same account cannot inherit pending orders
  or the deceased character's balance. Existing characters keep their balance
  and pre-v2 delivery queues through a one-time migration; pending deliveries
  are closed when their owner dies.
- Corrected the native B42.20 identity lookup to read `IsoPlayer.sqlId` with its
  actual casing. A living replacement now rotates any native binding already
  marked deceased, while server-side bank debits, credits and direct balance
  writes are rejected for the deceased character.
- Replaced the Dark Web and Buy Goods player-ModData delivery strings with
  a persistent server-side delivery ledger. Every purchase now receives a
  stable order ID, consecutive purchases append instead of replacing one
  another, and replaying the same request cannot debit or enqueue it twice.
  Existing pending string queues are migrated automatically for old saves;
  the player ModData fields remain compatibility counters only.
- Made mailbox parcels transactional at order level: a parcel is populated
  completely and checked against the post-delivery weight limit before it is
  synchronized. A failed item creation, synchronization failure or excessive
  weight removes the temporary parcel and leaves the entire order pending;
  retries never deliver a partial remainder. Materialized parcels carry their
  order ID so an interrupted delivery can be recovered without duplication.
- Migrated mail-mission gifts to the same persistent delivery ledger. Their
  exact randomized contents are fixed when the mission completes, multiple
  owed gifts remain separate, legacy reward counters migrate once, and every
  gift is delivered at most once in both solo and multiplayer.
- Added persistent receipt IDs to Dark Web and Sell Surplus payment packages.
  Replayed sale commands now reuse the original receipt, and a redeemed
  memento cannot credit the bank twice. Sell Surplus item removal now also
  uses the synchronized multiplayer inventory path.
- Tightened mailbox contract deposits: the server restores a valid active
  contract from tagged inventory objects when needed, rejects deposits with
  no canonical active contract, and removes exactly the requested quantity
  instead of every matching item in the player's inventory.
- Added a safety cap to mailbox delivery (Dark Web buy orders and Buy
  Goods orders alike): a mailbox visit now stops handing out more
  parcels once the player is getting too loaded down, leaving whatever's
  left safely queued for a later visit instead of dumping an entire
  backlog on them in one go. From player feedback: a backlog of pending
  orders piling up (e.g. after being unable to reach a mailbox for a
  while) could previously load a player down with an unbounded amount of
  weight in one go -- exactly the kind of "one bad decision away from
  getting one-shot by a horde" situation this mod should never create on
  its own. Originally stopped at 85% of the player's own real overweight
  threshold; this was raised to 200% in 1.0.13 after live MP testing showed
  that ordinary purchases were deferred too easily. It respects unlimited
  carry and fails open (delivers normally) if weight can't be read at
  all. The remaining orders are picked back up automatically next time
  the player visits any mailbox with room to spare.
- Brought Dark Web's Sell list up to par with its own Buy list, matching
  it visually and functionally: item names are now truncated so a long
  one can no longer run into the price/stock text next to it (previously
  unbounded, unlike Buy's rows), and every row (icon, name, price/stock,
  quantity box, SELL button) now shows a hover tooltip with the full
  item name and price/stock, exactly like Buy's rows already did. The
  quantity field and the player's own owned-count on the second line
  (added earlier this version) were already in place.
- Fixed the Dark Web Sell screen appearing completely blank when the main
  inventory contained no supported item, or when the server could not load
  offers. Both states now display a clear localized message, and Sell buttons
  plus the bank balance line use translated text.
- Added the 21 missing Sell Goods, Buy Goods availability and Dark Web Sell
  strings to all 20 language catalogs. The translation audit now also scans
  literal keys used by Lua, preventing a screen from silently falling back to
  English merely because its keys were absent from every catalog.

## [1.0.10]

- Fixed a player-reported bug in Training: a player with $100,000 in their
  bank account was told they didn't have enough money to buy an $80,000
  course. Root cause: onPayCourse showed the same hardcoded "not enough
  money" message for EVERY purchase failure other than
  "training_in_progress", regardless of the real reason -- most likely an
  "invalid_course" rejection (the offer clicked was no longer valid
  server-side, e.g. the week rolled over or it got consumed between
  refreshes) had nothing to do with the player's balance at all. Every
  real server error now maps to its own honest message instead of one
  wrong catch-all claim: not_enough_money still says exactly that,
  invalid_course clears the stale selection and resyncs the list from the
  server automatically (instead of leaving a phantom card the player
  could keep retrying forever), and any other/unexpected error falls back
  to a generic "purchase failed, try again" rather than blaming money.
- Fixed a player-reported performance bug in Training: clicking a course
  card sometimes appeared to do nothing, needing several clicks to
  register. Root cause: same underlying native-Translator behavior as the
  In Progress log-spam fix above, but far more frequent here -- rendering
  the offer list calls the game's own getText() on a "%s"-containing
  string once per card (up to 3 times) on every click (selecting a card,
  cancelling back to the list, a fresh refresh), and 3 real Java
  exceptions thrown, caught and logged back to back on the same thread
  was enough to cause a visible client hitch. Training's own
  placeholder-bearing keys (Detail, InProgress, Completed) now use
  "{1}"/"{2}"/"{3}" instead of "%s" -- the native lookup never sees a
  percent sign to trip over in the first place, while PZLinux's own
  substitution (still entirely in Lua, via a small new
  PZLinuxTrainingFormat helper) works exactly as before.
- Redesigned Training's offer list to match Buy Goods' clickable-row
  interaction instead of a name/detail label pair sitting next to its own
  small "Start" button: each of the 3 weekly offers is now a full
  clickable card with its name and price/duration stacked inside. From
  player feedback, clicking a card never spends money by itself anymore
  -- it only selects that one card and reveals a separate recap plus
  explicit Pay/Cancel buttons below it, so an accidental click can no
  longer charge the player; paying (or backing out with Cancel) is always
  a deliberate second step. A stale selection (the offer got bought
  elsewhere, or the week rolled over between refreshes) safely falls back
  to the list instead of trying to confirm a purchase that can no longer
  succeed.
- Fixed a player-reported bug: finishing every one of this week's 3
  Training offers made a brand new set appear immediately instead of
  waiting for the actual 7-day reroll. Root cause: the reroll check
  required the offer list to be non-empty as well as being the same
  week, so once all 3 were bought and completed (leaving an empty list --
  by design, see PZLinuxTrainingRemoveFromList) it looked exactly like a
  stale list that had never been rolled at all, and rerolled immediately.
  Now gated purely on the tracked week number, so an empty list within
  the current week is correctly treated as "nothing left until next
  week", not "never rolled yet".
- Changed the sound Training plays on completing a course from the plain
  string "levelup" (which resolves directly to a leftover legacy
  media/sound/levelup.ogg/.wav file, no longer used by vanilla gameplay --
  its own SoundBanks.lua alias is commented out) to "GainExperienceLevel",
  vanilla's own currently-used, properly-scripted sound for actually
  leveling up a skill. From player feedback: the old file's fuller fanfare
  mix included a vocal chant layer that didn't match the plain guitar
  sting vanilla itself uses for this moment.
- Fixed a player-reported log-spam bug in Training: the server log filled
  up with `Translator.reportMissingArgumentsFromPastAbuse ... Missing
  arguments for "IGUI_PZLinux_Training_InProgress"` warnings while a
  course was in progress. Root cause: the active-course label was rebuilt
  -- re-resolving and re-formatting its translation -- on every ~500ms
  tick response, even though the course name never actually changes
  between ticks (only the progress bar does). Since that translation
  string contains a raw "%s", every such lookup also made the game's own
  native Translator log this warning: it defensively tries to format the
  raw string itself before PZLinux's own gsub-based substitution ever
  runs (see PZLinuxGetText/PZLinuxFormatText's own comment on why this mod
  deliberately never passes real arguments to the native getText() call
  directly -- doing so once caused a worse, silent blank-value bug). At
  twice a second for a multi-hour course, that added up to a lot of
  avoidable noise in exactly the docker logs -f output this mod's own
  logging pass (see below) is meant to keep clean. Purely cosmetic --
  the label always displayed correctly regardless -- but now only
  rebuilt when the active course itself actually changes.
- Fixed a player-reported visual bug: the Training panel rendered as a
  plain floating dark box instead of appearing on the computer's own
  screen like every other PZLinux feature. Root cause: Training was built
  by reusing PZLinuxAdminBalance.lua's drag/close boilerplate for
  convenience -- a debug-only admin tool deliberately styled as an opaque
  panel with a red border so it never looks like part of the in-world
  computer -- and that styling came along for the ride by accident. Now
  drawn over the same oldCRT.png computer-screen bezel every real feature
  panel uses (Dark Web, Trading, Reputation, Check Condition, the boot
  menu itself, ...), with its own panel background made fully transparent
  so only the CRT texture shows as the frame, and its buttons restyled to
  match the shared green terminal look instead of solid red/green blocks.
- Fixed a player-reported compatibility issue: money from a "weightless
  money" mod (or any other mod reskinning/replacing vanilla cash) couldn't
  be deposited at an ATM, always rejected as if the player were carrying
  none at all. PZLinux never reads item weight anywhere, so a plain weight
  edit on the vanilla item was never the real problem -- the actual gap
  was that this mod only ever recognized its own Base.Money/
  Base.MoneyBundle items as cash, plus a partial fallback (any item whose
  vanilla "Type" tag is Money) that existed in the inventory-counting code
  but was missing from the ATM's own "gather money from bags before
  showing the deposit menu" step. Added a new sandbox option,
  PZLinux.CustomMoneyItems (free-text, comma-separated item IDs), letting
  a host explicitly register a third-party mod's currency item as valid
  $1 PZLinux cash -- the same supported extension pattern already used for
  PZLinux.CustomDarkWebItems. Every place this mod checks whether an item
  is spendable cash now goes through one shared function so the two never
  drift apart again. Also added a diagnostic server log line when a
  deposit is rejected for insufficient cash, printing what was actually
  detected vs. requested, to make this kind of report easier to root-cause
  from `docker logs -f` in the future.
- Added Training, a new PZLinux computer app -- moved up from the v1.1.0
  roadmap as a goodwill feature after a heavy bugfix cycle. Buy XP with
  money: 3 courses are rolled weekly (one at a time -- finish the current
  one before starting another), each a choice of skill x XP tier
  (100/200/400/800 XP, always priced at a flat $100 per XP, but duration
  doesn't scale 1:1 with XP -- doubling the XP each tier only costs +1
  in-game hour, so the bigger tiers are a genuinely better XP/hour deal,
  not just a bigger bill for the same rate). A daily reroll was tried
  first and walked back before release: with nothing ever permanently
  used up, 3 fresh options appearing every single in-game day was simply
  too generous over a long play session -- weekly keeps the same rules
  (see below) at a much more deliberate pace. Progress is gated by
  actually keeping the panel open and watching, the same reason vanilla
  reading a skill book takes real in-game time and stops the moment you
  stop reading -- durations (2-5 in-game hours) land in that same range on
  purpose, and speeding up game time (the normal >> controls) speeds
  through a course too, exactly like reading does. Progress is measured
  in in-game hours, computed server-side from the world clock itself
  (never trusting anything the client reports), and persists correctly
  across logging out and back in: re-opening the panel always resets the
  "am I currently watching" baseline to right now, so time spent away
  never counts, and time already banked is never lost either. XP is
  granted through the same addXp channel every other XP source in the
  game uses, so existing multipliers (Fast Learner, XP-boost moodles,
  etc.) apply automatically. Completing a specific (skill, tier) course
  removes only that exact offer from this week's remaining offers -- not
  tracked forever: it has a normal chance of coming back around on a
  future week's roll, the same way an already-bought Buy Goods category
  reappears the next day. Explicit by design: a player who only wants to
  spend $10,000 at a time on the small tier can, without a cheaper tier
  being a permanent one-shot that forces bigger spending later just to
  train the same skill again. Deliberately excludes every combat and
  physical-conditioning skill (Aiming, Axe, Blunt, Fitness, Sprinting,
  etc.) -- this reads as "a class you could actually take", not a way to
  buy combat power in a survival game.
- Added a quantity field to the Dark Web Sell list, matching the one Buy
  already has, instead of a single SELL click always selling every
  matching item the player owned. Defaults to "0" so a stray click can
  never sell anything by accident (a quantity of 0 is a no-op, both
  client and server-side). When selling fewer than everything owned,
  currently-EQUIPPED items (a worn bulletproof vest, say) are now only
  ever reached for once there aren't enough non-equipped matches left to
  cover the request -- from a player report: owning 3 (1 worn + 2 spare)
  and wanting to sell 2 used to risk the worn one going too, forcing a
  manual "unequip and stash it first" workaround every time. Also fixed,
  found while touching this code: sell prices re-rolled a fresh random
  value on every single offer-list rebuild, including right after selling
  a completely different item, which felt buggy since nothing about the
  market had actually changed -- now cached per item the same way Buy
  already caches its own prices, reset together on the same
  market-refresh boundary so Buy and Sell prices stay in sync with each
  other.
- Added server-side logging across every player-facing money/progress
  feature, for live monitoring via `docker logs -f` (or any server console)
  instead of only finding out about a bug from a player report after the
  fact: Trading (buy/sell), Poker (join/cash-out/table finished), Zombie
  Race (bet placed and settled), ATM (withdraw/deposit), Mail (mission
  completed, reward delivered), Sell Surplus (redeem), and Contracts
  (accept/cancel) all now print a one-line summary of the action, the
  player and the resulting balance -- on top of the Dark Web, Buy Goods,
  Blackjack, Admin and Vehicle-delivery logging this mod already had.
  Deliberate exception: Hacking's password is never logged, in any form --
  not the code itself, not a player's guess, not the correct/misplaced
  digit breakdown a guess produces, since that could be used to
  reconstruct the code across attempts just from watching the log. Only
  the non-sensitive lifecycle (a hack started, how many tries were used,
  whether an attempt was right or wrong, the amount transferred) is
  logged. Locked in by a dedicated test that scans every Hacking function
  for a print() call referencing the password/guess/digit-breakdown
  variables and fails the build if it ever finds one.
- Investigated a player report: credit cards not directly in the main
  inventory (e.g. sitting inside an equipped bag) made Hacking's Auto say
  "No Credit Card...", since PZLinuxHackingCountCards/RemoveCards only
  ever look at the character's own top-level inventory container, not
  nested bags -- a well-known Project Zomboid modding gotcha (the vanilla
  inventory panel shows everything a player is carrying merged across
  every equipped container, broader than a plain getInventory():getItems()
  check). A first pass made both functions recurse into nested containers,
  but that was deliberately reverted: this mod consistently only checks
  the player's direct, top-level inventory everywhere else (Dark Web's
  sell/buy matching, Contract deposit checks, etc.), and the call was to
  keep Hacking consistent with that rather than make it the one feature
  that reaches into bags -- cards need to be in the main inventory, same
  as everywhere else in this mod. Still fixed along the way: a card's
  name/type used to be recorded as "removed" even if the actual removal
  failed, which could have left a hack's recorded card list claiming more
  cards were taken than what actually left the player's inventory.
- Fixed a player-reported money exploit in Hacking's Auto mode: "when I
  close the computer after Auto + Transfer, my credit cards come back in
  my inventory, and I can redo Auto with them indefinitely." Root cause:
  the interrupted-session rollback that restores a player's cards after a
  genuine SERVER RESTART mid-hack (PZLinux.hackingSessions is memory-only,
  while the matching flag is persisted in modData -- a restart between
  "cards removed" and "hack resolved" would otherwise lose them forever
  with no trace) had no way to tell a real restart apart from any other
  reason those two independently-tracked flags might drift apart within
  the same running process -- restoring the cards either way, even after a
  fully successful, fully paid-out hack. Fixed without needing to pin down
  every possible way that drift could happen: every interrupted-session
  entry is now stamped with a value unique to the current server process,
  and the rollback only fires once that no longer matches -- i.e. only
  across an actual restart, the only way a memory-only table can
  legitimately forget an entry mid-process. Also fixed a real, confirmed
  asymmetry found while auditing this: a manual hack locked out after too
  many wrong password guesses cleared its persisted flag but left the dead
  session sitting in memory -- the mirror image of the bug above, closed
  the same way (both are now always cleared together, with no path left
  that clears only one of the two).
- Fixed a player-reported bug: a Dark Web purchase (money debited,
  confirmed) was never delivered at the mailbox -- no parcel, no "stolen"
  note, no error message either. Initial testing of the reported sequences
  (a single buy; buying twice before visiting the mailbox; a sell followed
  by a buy) found no logic bug against a simple, always-persistent fake
  modData table, which pointed a first fix at server commands failing
  silently instead (still shipped: every server command now runs through a
  safety net turning any uncaught error into a real, visible error message
  plus a server log line naming the command, instead of silence). The
  player's own server logs then caught the REAL root cause directly: two
  separate purchase log lines both showed the pending-order queue's length
  as 1 right after insertion -- the second purchase should have appended to
  the first (length 2), not reset it. The queue was an array of tables
  stored directly as a modData value; the previous v1.0.8 fix for a related
  symptom (re-assigning the modData key after every in-place table.insert/
  remove) was a good instinct but not enough, because the deeper problem is
  that this shape -- a nested value inside modData -- does not reliably
  survive between separate commands at all, the exact same failure mode
  already confirmed once before in this mod for reputation (see the
  backup-key fix at the top of ISPZLinuxVariablesTables.lua). Fixed by
  encoding both the Dark Web and Buy Goods pending-order queues as a single
  flat string instead of a nested array of tables -- the same simple,
  flat-value shape already proven reliable everywhere else in this mod --
  so a second purchase now reliably appends to the first regardless of
  whether anything else survives between the two commands.
- Following up on that report, audited every "Base.*" item id referenced
  anywhere in the mod against the currently installed Build 42 item/vehicle
  list and found 9 genuinely dead entries in the Dark Web catalog: Base.223
  Box/Base.223Clip (.223 was removed from the game in Build 42.14, replaced
  by 5.56 -- 556Box/556Clip already existed as their own correct entries,
  so these were removed rather than renamed onto a duplicate), Base.308Clip
  and the four "BulletsMold" entries (never had a current equivalent --
  .308 has no clip-fed variant, and no "mold" item exists in the current
  Reloading system), Base.IronSight (no current equivalent found), and
  Base.PigIronIngot (renamed to Base.IronIngot, the current basic-tier
  ingot). The same stale .223 Box id was also duplicated into the Dark Web
  price-balancing table and the "Need Ammo" mail-reward pool (both fixed to
  match), plus one more in the mail pool's live item-roll function where a
  stale id would have actively failed to hand the player their reward
  instead of just never being offered for sale. A stale Base.Stone (the
  current generic loose stone item is Base.Stone2) was also found and fixed
  in the Buy Goods (Requests) Materials category while at it. None of these
  explain the mailbox non-delivery report on their own -- a dead Dark Web
  catalog entry just never gets offered for sale in the first place, it
  doesn't get bought and then vanish -- but they were real, worth fixing
  regardless, and the mail-ammo one was a genuine (separate) silent-failure
  risk.
- Fixed a player-reported bug: repairing the in-world computer never
  granted Electricity XP, even though the repair itself visibly worked
  (electronics scrap consumed, condition improved). Root cause: this
  action runs client-side, like every other timed action in this mod, but
  the XP-granting function is a server-side-only native, nil on the
  client -- and this was the one place in the whole mod that called it
  without the "if it exists" guard already used at every other of its 46+
  call sites, so it threw an error right there every time, silently
  swallowing the XP grant (and the rest of the action's cleanup) without
  crashing the game or otherwise being visible to the player.
- Fixed a player-reported issue: an Auto Parts contract's request didn't
  always say whether a Standard/Sport/Resistant part was needed, leaving
  players guessing which item to actually bring back. Root cause: PZ's own
  vanilla item name is identical across all three quality tiers of a given
  part (e.g. Base.NormalSuspension1/2/3 all display as the same
  "Suspension - Regular"), and the dialogue text tried that ambiguous
  vanilla name first, only falling back to the mod's own curated,
  disambiguating name if the vanilla lookup failed -- which it essentially
  never does, so the curated name (which already existed) was never
  actually shown. Now the curated name is used whenever one is provided.
  Along the way: three Weapon request names (a B-F Pistol, an SN38
  Revolver, a Patrol Revolver) had gone stale, still referencing their
  B41-era nicknames instead of their current B42 vanilla names -- fixed to
  match. Every one of these part/item names (46 total, across the Auto
  Parts/Medical/Weapon request pools) is now a proper translation key
  instead of hardcoded English, translated into all 20 supported
  languages, since the physical contract note has always shown this exact
  text regardless of the player's language.

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
