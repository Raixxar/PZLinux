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
    own taste instead of relying on hardcoded defaults.
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
