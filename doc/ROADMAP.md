--- v1.1.0 ---
Mail quest chains: procedural multi-step mail missions built from the
    existing contract activities (retrieve an item, go to a location, kill
    a target). Each step's clue points to the next step's activity and
    location, both picked at random so every chain plays out differently.
    Chain length is rolled once per mission, between 2 and 6 steps, when
    the mission is generated.
Unique one-off mail quests, never chained: deliver a specific rare item
    (Big Spiffo bag, gas mask, etc). No detective/document-retrieval quests.
New manhunt variant: instead of the full elimination-and-proof flow, the
    target only needs to be found dead and a letter recovered from the
    corpse.
Quest: deliver water bottles to a specific point.
New contract: Radio station survival signal -- broadcasting it attracts
    every zombie in the area and spawns a horde.
New contract: Police station hack -- the player must bring a computer to
    the police station, plug it in, and solve an in-game puzzle/riddle to
    get in. Success pays the reward; failure sounds an alarm, spawns a
    horde on the spot, auto-cancels the contract and costs reputation.
    Likely the hardest contract in the mod.
New contract: deliver rand(2-5) full gas cans to a target.
Sandbox option: a daily (per-Zomboid-day) sell limit on the Dark Web,
    separate from the existing Requests/Sell Goods scarcity limits, to stop
    players from getting arbitrarily rich in one sitting. Host-configurable
    (0 = no limit, matching current behavior), same pattern as the existing
    PurchasePriceMultiplier/SalePriceMultiplier options in
    sandbox-options.txt: declare the option, read it where Dark Web sales
    are applied, add the Sandbox.json translation, verify in the world
    creation screen.
More sandbox options in general, so players/hosts can tune the mod to their
    own taste instead of relying on hardcoded defaults. Full audit of every
    hardcoded, host-meaningful value across PZLinuxConfig.lua,
    PZLinuxEconomy.lua, PZLinuxPokerConfig.lua and PZLinuxRaceEngine.lua,
    grouped by area -- nothing committed to yet, triage which ones are
    actually worth shipping (vs. leaving as internal defaults) once it's
    time to build this, same declare-option/read-it/translate/verify
    pattern as every sandbox option already shipped:
    - ATM: minCash/maxCash per machine, restockPerHour/restockCap.
    - Contracts: boardRefreshHours (board refresh rate), the reputation
      reward/penalty per contract (contractCompleteReward/
      contractCancelPenalty).
    - Reputation: minimum/maximum bounds, purchase surcharge/discount per
      point (how much reputation actually swings prices).
    - Market scarcity: scarcityPeriodHours/scarcityMaximumMultiplier (how
      wide Dark Web prices swing over time).
    - Buy Goods (Requests): the daily chance a category has no seller at
      all, and how many game-days that chance ramps up over.
    - Sell Surplus: daily demand chance, base price percent range, "great
      deal" chance/range.
    - Trading: the transaction fee rate (currently a flat 5%).
    - Blackjack/Poker: bet ranges per table / blinds per lobby -- likely a
      free-text option like CustomDarkWebItems rather than one option per
      number, given how many values that is.
    - Zombie Race: maximum player bet, takeoutRate (the house cut).
    - Hacking: money-per-card range, max password tries, password length.
Sandbox option: let the host set the Dark Web/Buy Goods package theft
    chance themselves, instead of the current hardcoded 10% roll shared by
    both delivery paths (see PZLinuxDarkWebApplyDeliverOrders/
    PZLinuxRequestsApplyDelivery, the ZombRand(1, 101) <= 10 check). Same
    pattern as the existing PurchasePriceMultiplier/StartingBalanceMin/Max
    options in sandbox-options.txt: declare a 0-100 option, read it from
    both delivery functions instead of the hardcoded 10, add the
    Sandbox.json translation. From player feedback: "Could we have that
    chance for the package to be lost as a sandbox variable please?"
Recovery interface: a new in-world computer app for reclaiming what a dead
    character left behind, for more casual/"journal-style" servers that let
    players respawn and recover progress instead of a strict permadeath
    economy. Builds on the "named recovery code" idea already raised for
    this (Raixxar's own suggestion, previously noted here) with a concrete
    two-option design:
    (a) Balance recovery via a hacking-style minigame: reuses the existing
    Hacking password-guessing mechanic (PZLinuxHacking.lua /
    PZLinuxHackingStartManual, today used to steal from a locked account) for
    the inverse case -- cracking the player's OWN dead account. Limited
    number of attempts to find the code; success returns the full balance,
    running out of attempts loses it forever (no retry, no cooldown -- a
    real stakes decision, worth confirming that's really intended before
    building it, since every other money-loss path in this mod is either
    fully preventable or capped, not permanent-and-final like this).
    Open question not yet resolved: in MP a player could have died more than
    once with balances left behind each time -- does recovery target only
    the most recent death, or does the player pick which one, and how is
    that surfaced in the UI?
    (b) Skill points recovery for a steep flat price (proposed: $50,000) --
    penalizing enough that death still matters, but not permanent. Must be
    additive-only per skill: for every perk, compare the dead character's
    recorded level against the new character's CURRENT level
    (playerObj:getPerkLevel(Perks.X), same read already used by
    PZLinuxEconomy.lua/ISPZLinuxRepareAction.lua) and only raise it, never
    lower it, so a new character who already leveled a skill higher than the
    old one never gets overwritten downward. Needs real verification before
    committing to an approach: the mod's existing XP grants (addXp(playerObj,
    Perks.X, amount)) add raw XP, not a level directly, and PZ's XP-per-level
    curve is non-linear -- restoring "up to level N" precisely likely means
    computing the exact XP delta from the game's own per-level thresholds
    rather than guessing a flat XP amount per level.
    Together, (a) and (b) also work as an expensive, entirely optional way to
    "reroll" a character on purpose (die, then buy back the balance and
    skills on the new one) rather than a dedicated separate feature -- worth
    keeping in mind for pricing so that path stays a real sink, not a cheap
    loophole.
    Either option still needs money (and skill levels) to become
    recoverable by something OTHER than the dying character's own modData --
    everything in this mod is currently scoped strictly to the character
    object, by design (confirmed while investigating an unrelated "does
    reusing a dead character's name recover their balance" question -- it
    doesn't, today, precisely because nothing is account-scoped). The
    recovery code itself needs to be the account-scoped key that survives
    the old character's death to make either option reachable at all.
    Needs to stay opt-in/host-configured, not default behavior, since it's a
    real philosophical fork away from Contracts being the only reliable
    income and death having real economic stakes -- exactly the "more
    casual" framing this was originally raised with. From player feedback:
    "It would be nice if we had the option to keep our money/stocks/etc on
    death, or keep a configurable percentage of them on death... And more
    casual servers like mine could set that to 0."
Formation (training courses) interface: a new in-world computer app to buy
    XP directly with money, playing the same role as VHS tapes/TV shows
    already do in vanilla PZ but as an instant, always-available purchase
    instead of a real-time-gated one -- worth being explicit about that
    difference when designing it, rather than silently reinventing VHS.
    Grounded in the mod's existing XP-grant precedent (addXp(playerObj,
    Perks.X, amount), Perks.Electricity/PlantScavenging already used this
    way in PZLinuxEconomy.lua/ISPZLinuxVariablesTables.lua). Example given:
    an Electricity course grants 200 XP for $20,000 -- a $100-per-XP anchor
    to seed pricing for the rest of the skill list once this gets built.
    Only 3 courses offered at a time, refreshed daily (per in-game day), so
    players can't just repeatedly buy the same skill -- the same shape as
    the existing daily-refresh mechanics already in the mod (contract board
    refresh via boardRefreshHours, Buy Goods' daily seller-availability
    roll), likely reusable as a pattern rather than new infrastructure.
    Open question not yet resolved: is the daily set of 3 the same for
    every player on the server (one shared roll, like Dark Web restock), or
    rolled separately per player? Matters for the next requirement:
    once a player completes a course, it must disappear from THEIR list
    permanently (never re-offered to them again, so a skill isn't trained
    twice) while staying available to every other player -- so completion
    has to be tracked per-player/per-character, even if the daily pool of
    which 3 are on offer ends up shared server-wide.
Trading overhaul: several new order types layered onto the current simple
    "buy X now / sell X now" market-order-only system
    (PZLinuxTradingApplyBuy/PZLinuxTradingApplySell -- immediate execution
    at the latest price, no concept of a pending/conditional order at all
    today). From player feedback, aimed at making Trading feel like real
    trading and teaching it to players who've never traded before, not
    just giving more options to people who already know the terms:
    - Short selling: bet on a price drop by selling borrowed shares now and
      buying them back later. A short's loss is theoretically unlimited if
      the price keeps rising, unlike a normal buy where the most you can
      ever lose is what you paid -- downside-risk decision made: the bank
      balance is allowed to go negative (debt) rather than being hard-
      capped/margin-called. Debt is tied into the EXISTING reputation
      system rather than building a separate one: while debt is
      outstanding, reputation drops (reusing the existing decay-toward-
      baseline machinery, just pointed downward instead of back to
      neutral), which automatically triggers the purchase surcharge
      PZLinux.Economy.reputationPurchaseMultiplier already applies below
      baseline -- no new pricing code needed, prices just get worse the
      deeper in debt the player stays. Settling the debt stops the drop
      and lets reputation recover normally over time, same as any other
      reputation hit today.
      Also raised: below -50 reputation (deep negative territory on the
      real -99 to 200 scale, baseline 1), zombie hordes start coming for
      the player. This is a broader consequence than just debt -- reputation
      is a single shared stat today (contract cancellations already lower
      it too), so this would apply to ANY path down to -50, not only
      unpaid debt; worth deciding whether that's intended before building
      it. Likely reuses the horde-spawn logic already built for Protect the
      Building/the Radio Station contract idea above, rather than a new
      spawn system.
    - Leverage: trade a bigger position than the cash actually put up,
      amplifying both gains and losses. Same debt-via-reputation handling
      as short selling above, and directly compounds it if the two combine.
    - Limit orders: buy/sell only executes once the price reaches a chosen
      level or better, instead of immediately at the current price.
    - Stop orders: the mirror of a limit order -- triggers a market order
      once the price crosses a chosen level, commonly used to enter on a
      breakout rather than to protect an existing position.
    - Stop-loss / take-profit: attached to an existing position, auto-sell
      if the price drops below (stop-loss) or rises above (take-profit) a
      chosen level, without the player needing to watch the market.
    Limit/stop/stop-loss/take-profit are all "pending order" types that
    don't execute immediately -- nothing like that exists today, so this
    needs a real background system checking every pending order against
    the price whenever it updates, executing (and notifying the player)
    the moment a condition is met, even while they're not looking at the
    Trading screen.
    Every new option needs an explanatory tooltip -- setTooltip already has
    a working, low-risk precedent in this mod (the Dark Web buy list's
    item tooltips, PZLinuxDarkWeb.lua) -- so a player who has never traded
    before can learn what each term means just by hovering over it, in
    keeping with the explicit goal of teaching real trading through play,
    not only adding options for players who already know the jargon.
Reputation-gated Dark Web offers: certain rare items only appear in the
    catalog once the player's reputation crosses the Preferred tier, giving
    another concrete reason to care about reputation beyond the price
    modifier.
Seasonal Dark Web events: a special limited-time offer tied to a specific
    real-world-style calendar date (Christmas, Halloween, etc), in the same
    spirit as the existing 1994-flavored details (AOL email domain, etc).
Season-linked scarcity: prices for season-relevant goods (fuel, generators)
    drift slightly with the in-game season instead of staying flat
    year-round.
New contract: "Clear the horde" -- kill a rolled number of zombies inside a
    target zone within a time limit for the reward. Reuses the horde-spawn
    logic already built for Protect the Building.
Quest: search for a courier who died, keep the package.

--- v1.2.0 ---
Animal missions: a deer chase, with checkpoints defined by coordinates. The
    deer moves at a set speed and the player must follow it by car only (no
    other means). It stops exhausted at the final checkpoint, where the
    player kills it and can harvest its hide.
Quest: deliver live chickens or rabbits.
Controller compatibility and proper split-screen support.
Rest of v1.2.0 TBD based on player feedback, plus more time to come up with
    additional animal mission ideas.
Reactive market events: an occasional Trading crash/boom triggered by a
    world event near the player (helicopter event, nearby gunfire) instead
    of a pure random walk, to make the market feel more alive.
New contract: "Escort delivery" -- carry a fragile/valuable package from A
    to B. Every rand(30-180) real-time minutes, a rand(2-19) group of
    zombies spawns a few tiles from the player and is drawn toward them,
    forcing them to keep fighting/staying alert for the whole route instead
    of a single fixed horde like Protect the Building.
New betting game: Roulette.
New betting game: classic slot machine.
New betting game: "Zombie Roulette" -- 5 zombies in a room, IDs 1-5 on the
    backend, shown with funny PMU-style contestant names on the front end
    instead of raw numbers/IDs. Round 1, the player bets on one of them and
    that pick is locked for the whole game (can never switch). Each round,
    a revolver "fires" at the group: roll rand(1, zombiesRemaining + 1),
    where a result 1..zombiesRemaining shoots that specific zombie (a
    "bang", it dies) and the extra top value is an empty chamber -- just a
    "click", nobody dies that round, pure suspense (e.g. rand(1,6) with 5
    zombies left, then rand(1,5) with 4 left, and so on). If the player's
    own zombie is the one shot, they lose immediately. Otherwise each round
    they can raise their bet or just continue. This repeats, one zombie
    eliminated per non-empty round, until a single zombie is left standing.
    If it's the player's pick, they win the pot.
Bill denominations: right now zombies only ever drop $1 (occasionally $2)
    bills, so physical cash farming means carrying a huge stack of single
    bills around just to reach a meaningful deposit. Add $5/$10/$20 bills
    at normal drop rates, with $50/$100 as rare finds -- fewer, higher-value
    bills for the same total amount, which also caps how much bag space a
    big cash haul eats up. From player feedback.

--- v1.3.0 (tentative, nothing committed) ---
Possibly boss encounters / tougher zombies -- still undecided, risk of
    drifting into pure RPG territory instead of staying Project Zomboid-like.
Shared server-side leaderboard (richest player, most contracts completed,
    etc), purely cosmetic and read-only, so no real MP/exploit risk. Only if
    the community actually asks for it.
Peer-to-peer player marketplace: a player lists an item for sale, the
    server takes custody of it (removed from their inventory) instead of
    holding it client-side; if another player buys it, the money goes
    straight to the seller. In solo (no other player to buy it), there's a
    once-per-hour chance the listing gets bought out by a simulated buyer
    instead, with the chance scaled down as the item's value goes up (e.g.
    25% above $1,000, 5% above $5,000, 1% beyond that) specifically to
    prevent using it to launder/transfer large sums, without needing to
    maintain a full per-item value list.

--- v1.4.0 (from player feedback, big architectural undertaking) ---
Modular "apps" API for other modders: expose a public, stable Lua API
    (e.g. PZLinux.RegisterApp(...)) other mods could call to add their own
    icon/app to the in-game computer, instead of only first-party features.
    Reasonably tractable, but needs real documentation and a commitment to
    not silently break the API between versions.
Fake "internet" system: modular, per-module content (websites,
    communication) and possibly communication between separate PZ servers.
    The cross-server communication part is the risky unknown here -- unsure
    whether PZ's Lua sandbox even allows outbound network calls at all, needs
    real investigation before committing to it.
DLC-style optional modules (Sims-like): let hosts/players enable only the
    modules they want instead of the whole mod at once, possibly through an
    in-world "floppy disk" item players find/craft to unlock a module,
    and/or a sandbox toggle per module for the host. Need to decide whether
    this is host-wide (sandbox) or per-player in-world progression (floppy
    disks) -- these imply very different implementations.

--- v2.0.0 (long-term vision, depends on the base game) ---
Once Project Zomboid's own NPC system ships, properly support it: NPC-aware
    contracts and quests built around whatever the devs actually deliver
    (NPC clients/targets/couriers instead of only zombies and world objects,
    NPC-run shops or contacts, etc). Scope depends entirely on what the base
    game's NPC feature ends up looking like, so nothing concrete can be
    planned yet -- revisit once it's out and stable.
