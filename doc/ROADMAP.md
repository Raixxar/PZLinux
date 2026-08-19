# PZLinux Roadmap

This roadmap collects possible directions after the 1.0.x release cycle. Target
versions express the current direction, not a promise that every listed feature
will ship in that release. Player feedback, technical feasibility and
multiplayer safety may change the order.

## At A Glance

| Target | Main focus | Status |
| --- | --- | --- |
| [v1.1.0](#v110) | Missions, economy controls and progression | Candidate scope |
| [v1.2.0](#v120) | Animals, accessibility and betting | Early planning |
| [v1.3.0](#v130) | Public multiplayer hardening and server features | Planned |
| [v1.4.0](#v140) | Extensibility and modular apps | Architectural research |
| [v2.0.0](#v200) | Native NPC integration | Depends on Project Zomboid |

## v1.1.0

### Contracts And Mail Missions

- [ ] **Procedural mail quest chains**

  Build multi-step mail missions from existing activities such as retrieving an
  item, visiting a location or killing a target. Each clue points to the next
  randomized activity and location. The chain length is rolled once when the
  mission is generated, from two to six steps.

- [ ] **Unique one-off mail quests**

  Add standalone requests for a specific rare item, such as a Big Spiffo bag or
  gas mask. These missions are never inserted into procedural chains. Detective
  and document-retrieval quests are excluded from this category.

- [ ] **Simplified manhunt variant**

  The target is already dead. The player must locate the corpse and recover a
  letter instead of completing the full elimination-and-proof flow.

- [ ] **Water delivery**

  Deliver water bottles to a designated location.

- [ ] **Fuel delivery**

  Deliver a randomized quantity of two to five full gas cans to a target.

- [ ] **Radio station survival signal**

  Broadcast a survival signal from a radio station. Activating the transmitter
  attracts nearby zombies and spawns a horde.

- [ ] **Police station hack**

  Bring a computer to a police station, connect it and solve an in-game puzzle
  or riddle. Success pays the contract reward. Failure sounds an alarm, spawns a
  horde, cancels the contract and reduces reputation. This is intended to be one
  of the hardest contracts in the mod.

- [ ] **Clear the horde**

  Kill a randomized number of zombies inside a target zone before a time limit.
  Reuse the horde-spawn logic from Protect the Building.

- [ ] **Dead courier**

  Search for a courier who died and keep the package they were carrying.

### Sandbox Configuration

- [ ] **Dark Web daily sell limit**

  Add a host-configurable per-day sell limit, separate from the existing Buy
  Goods and Sell Surplus scarcity limits. A value of `0` disables the limit and
  preserves the current behavior.

- [ ] **Package theft chance**

  Replace the hardcoded 10% loss chance shared by Dark Web and Buy Goods
  deliveries with a sandbox option from 0 to 100%. This requires declarations in
  `sandbox-options.txt`, runtime reads in both delivery paths and translated
  `Sandbox.json` labels.

- [ ] **Audit other host-meaningful values**

  Review hardcoded values in `PZLinuxConfig.lua`, `PZLinuxEconomy.lua`,
  `PZLinuxPokerConfig.lua` and `PZLinuxRaceEngine.lua`. Only expose settings that
  are genuinely useful to server hosts.

| Area | Candidate options |
| --- | --- |
| ATM | Minimum cash, maximum cash, hourly restock and restock cap |
| Contracts | Board refresh interval and reputation reward or penalty |
| Reputation | Minimum, maximum and purchase modifier per point |
| Market scarcity | Period length and maximum multiplier |
| Buy Goods | Daily no-seller chance and scarcity ramp duration |
| Sell Surplus | Demand chance, base-price range and great-deal chance |
| Trading | Transaction fee, currently 5% |
| Blackjack and Poker | Table bet ranges and lobby blinds |
| Zombie Race | Maximum player bet and house takeout rate |
| Hacking | Money per card, maximum attempts and password length |

For Poker and Blackjack, a compact free-text format may be preferable to one
sandbox option per numeric value, following the `CustomDarkWebItems` pattern.

### Localization Completion

- [ ] **Migrate remaining legacy UI text into the translation catalogs**

  The 20 catalogs have identical keys, but several older interfaces still write
  English directly in Lua and therefore bypass them. Prioritize the main PZLinux
  menu, Hacking, Trading, Dark Web help and mailbox notifications. Keep the
  computer boot sequence in English intentionally for the period-authentic
  terminal presentation.

- [ ] **Community proofreading pass**

  Review terminology and natural phrasing with native speakers after the final
  hardcoded strings have been extracted, with Simplified Chinese as the first
  requested pass. Structural checks now reject missing keys and placeholder
  mismatches, but cannot judge translation quality.

### Economy And Long-Term Progression

- [ ] **Bank maintenance fee and progressive wealth tax**

  Add two optional balance sinks for long-running servers. They apply only to the
  bank balance and never remove physical cash from player inventories.

  - Maintenance fee: proposed default of 2%, charged every seven in-game days.
    A rate or interval of `0` disables it.
  - Wealth tax: an additional configurable rate applied only to the portion of a
    balance above a threshold, proposed at `$100,000`.
  - Prefer a marginal formula over a hard threshold that taxes the entire
    balance as soon as it is crossed.

  <details>
  <summary>Implementation and design notes</summary>

  The existing `Events.EveryTenMinutes` server loop already handles recurring
  per-player maintenance for reputation and race scheduling. ATM restocking also
  provides a reusable elapsed-world-time pattern. Store a per-player
  `lastFeeApplied` timestamp and debit through `PZLinuxLoadBankBalance` and
  `PZLinuxSetBankBalance`.

  The remaining design decision is whether offline time counts. The recommended
  approach is lazy elapsed-time calculation when the player next logs in or is
  processed by the server loop. Add transaction logs and a read-only UI summary
  showing the current rates, threshold and time until the next fee.

  </details>

- [ ] **Recovery interface for dead characters**

  Add an optional computer application for casual or journal-style servers where
  players may recover selected progress from a dead character using an
  account-scoped recovery code.

  - Balance recovery: use a hacking-style password minigame. Success restores
    the balance; exhausting all attempts loses it permanently.
  - Skill recovery: restore previous skill levels for a proposed flat `$50,000`
    fee. Recovery must only raise a skill and never lower the new character's
    current level.
  - Keep the system disabled by default because it changes the economic meaning
    of permadeath.

  <details>
  <summary>Open questions and technical constraints</summary>

  Decide whether balance recovery targets only the latest death or allows the
  player to select among multiple dead characters.

  Project Zomboid's XP curve is non-linear. Exact skill restoration should use
  the game's level thresholds rather than granting a guessed flat amount of XP.
  The recovery data cannot remain only in the dead character's ModData; it needs
  an account-scoped server record that survives character death.

  Balance and skill recovery together also permit an intentional character
  reroll. Pricing must keep that route expensive enough to remain a meaningful
  economic sink.

  </details>

### Trading Overhaul

- [ ] **Short selling**

  Let players sell borrowed shares and buy them back later. Losses may push the
  bank balance into debt. Outstanding debt reduces the existing reputation score,
  which already increases purchase prices below the neutral baseline.

- [ ] **Leverage**

  Permit positions larger than the cash committed, amplifying gains and losses.
  Use the same debt and reputation consequences as short selling.

- [ ] **Limit orders**

  Execute a buy or sell only when the market reaches the selected price or a
  better one.

- [ ] **Stop orders**

  Trigger a market order when the price crosses a selected threshold.

- [ ] **Stop-loss and take-profit orders**

  Automatically close an existing position after reaching its configured loss or
  profit threshold.

<details>
<summary>Trading implementation and UX notes</summary>

Pending orders require a new server-side background process. It must evaluate
orders whenever prices update and notify players even when the Trading screen is
closed.

Every advanced order type needs a translated tooltip so players unfamiliar with
trading can learn the terminology in the interface.

A broader reputation consequence is still undecided: below `-50`, zombie hordes
could begin hunting the player. Because reputation is shared by all systems, this
would affect players with heavy contract-cancellation penalties as well as debt.
Confirm that behavior before implementation. Existing horde logic should be
reused if the idea is retained.

</details>

### Reputation And Market Events

- [ ] **Reputation-gated Dark Web offers**

  Reveal selected rare items only after the player reaches the Preferred
  reputation tier.

- [ ] **Seasonal Dark Web events**

  Offer limited items on calendar dates such as Christmas or Halloween, while
  retaining the mod's 1994 flavor.

- [ ] **Season-linked scarcity**

  Slightly adjust fuel and generator prices according to the in-game season.

## v1.2.0

### Animal Missions

- [ ] **Deer chase**

  Define a route from coordinate checkpoints. The deer moves at a fixed speed and
  the player follows it by car. It stops exhausted at the final checkpoint, where
  it can be killed and harvested for hide.

- [ ] **Live animal delivery**

  Deliver live chickens or rabbits.

- [ ] **Additional animal missions**

  Leave room for player feedback and further Project Zomboid-compatible ideas.

### Accessibility

- [ ] **Contextual hover help and translated tooltips**

  Add concise mouseover explanations to ambiguous controls and values throughout
  the CRT applications. Prioritize Trading (`H1`, `D1`, charts, wallet value,
  quantity, fees and buy/sell actions), then Dark Web stock and prices,
  reputation effects, betting terminology and compact icon buttons. Tooltips
  must wrap, remain inside the CRT bounds and exist in every translation catalog.
  Keyboard/controller focus should expose the same help once controller
  navigation is implemented; hover text must not become the only way to obtain
  essential information.

- [ ] **Controller compatibility**
- [ ] **Proper split-screen support**

### World And Market Events

- [ ] **Reactive market events**

  Trigger occasional Trading booms or crashes from nearby world events, such as
  the helicopter event or gunfire, instead of relying only on a random walk.

- [ ] **Escort delivery**

  Carry a fragile or valuable package from point A to point B. Every 30 to 180
  real-time minutes, spawn a group of 2 to 19 zombies near the player and draw it
  toward them. This creates recurring pressure along the route instead of one
  fixed horde.

### Betting Games

- [ ] **Roulette**
- [ ] **Classic slot machine**
- [ ] **Zombie Roulette**

  Five backend zombies receive humorous race-style contestant names. The player
  chooses one zombie for the whole game. Each round rolls from `1` to
  `zombiesRemaining + 1`: a zombie result eliminates that contestant, while the
  extra result represents an empty chamber. The player may increase the bet or
  continue after each surviving round. The last zombie standing wins the pot.

### Physical Cash

- [ ] **Additional bill denominations**

  Add normal drops for `$5`, `$10` and `$20` bills, with `$50` and `$100` as rare
  finds. This reduces inventory clutter from large stacks of `$1` bills without
  necessarily increasing total cash generation.

## v1.3.0

> The public-server security work is planned. The gameplay ideas remain
> tentative and may move depending on player feedback.

### Public Multiplayer Hardening

The 1.0.x line targets solo games and private cooperative servers whose players
trust one another. Normal clients cannot trigger most of the cases below through
the regular UI. A modified client on a public or competitive server could,
however, forge PZLinux commands or alter mirrored player `ModData`. Version
1.3.0 will therefore move the remaining sensitive state to canonical server
registries before PZLinux is advertised as resistant to hostile clients.

- [ ] **Create a canonical per-character server state**

  Add `PZLinuxCharacterStateV1`, keyed by the persistent character identity.
  Store reputation, Trading holdings, mail progression, Training, Requests,
  Sell Surplus and interrupted sessions in this registry. Player `ModData`
  becomes a UI mirror and a controlled legacy-import source only.

- [ ] **Secure legacy migrations**

  Accept old balances, delivery queues and rewards only through explicit
  allowlists, quantity limits and one-time migration markers. Prevent a new
  character from inheriting unverified state from an older character using the
  same username.

- [ ] **Make contracts fully authoritative**

  Use `PZLinuxContractsWorld` as the only source for ownership, objective
  transitions, deposits, cancellation penalties and rewards. Clients send only
  an action and an opaque contract ID.

- [ ] **Make sales and receipts fully authoritative**

  Validate receipt owner, source, amount, status and transaction ID against a
  server ledger before crediting Dark Web or Sell Surplus proceeds. Ensure each
  receipt can be redeemed exactly once, including after a crash or reconnect.

- [ ] **Move remaining economy and progression state server-side**

  Migrate Trading portfolios, daily Sell Surplus demand, reputation, mail
  rewards, Training snapshots, Request vehicle orders and interrupted-game
  refunds out of player-controlled state.

- [ ] **Harden ATM transactions**

  Validate player-to-ATM proximity on the server and make deposits, withdrawals
  and refills atomic. Failed inventory, balance or ATM updates must roll back the
  whole transaction.

- [ ] **Finish character lifecycle isolation**

  Key contracts, race tickets, betting sessions, request idempotency and other
  persistent domains by character identity rather than username. Close every
  domain when the character dies without affecting a replacement character.

- [ ] **Require idempotency and rate limiting**

  Require a valid `requestId` for every mutation, reject replays and malformed
  IDs, and rate-limit sensitive commands per character and domain.

- [ ] **Add hostile-client and fault-injection tests**

  Test forged player `ModData`, false receipts, invalid contract transitions,
  remote ATM calls, duplicate requests and simulated failures between debit,
  stock update, queue insertion, item removal and payment.

- [ ] **Run a dedicated-server security recipe**

  Validate the migration with two Windows clients across reconnects, full server
  restarts, character death, simultaneous stock purchases and interrupted
  transactions before describing public multiplayer as cheat-resistant.

- [ ] **Boss encounters or tougher zombies**

  Explore carefully. This risks shifting the mod toward a pure RPG experience
  instead of Project Zomboid's tone.

- [ ] **Shared server leaderboard**

  Add read-only rankings such as richest player or most contracts completed.
  Keep it cosmetic and only pursue it if the community requests it.

- [ ] **Peer-to-peer marketplace**

  Allow players to list items for sale. The server takes custody of the item and
  transfers payment to the seller after purchase. In solo, a simulated buyer may
  purchase a listing once per hour, with lower chances for expensive items.

  Proposed solo probabilities:

  | Item value | Hourly purchase chance |
  | --- | ---: |
  | Above `$1,000` | 25% |
  | Above `$5,000` | 5% |
  | Highest-value listings | 1% |

  The decreasing probability is intended to prevent the marketplace from
  becoming an easy large-sum laundering mechanism.

## v1.4.0

> Ideas from player feedback that require significant architectural work.

- [ ] **Modular applications API**

  Expose a stable public API such as `PZLinux.RegisterApp(...)` so other mods can
  add applications to the in-game computer. This requires documentation and a
  compatibility policy for future versions.

- [ ] **Fake internet system**

  Support modular website and communication content. Communication between
  separate Project Zomboid servers remains an unresolved technical question and
  requires investigation into the Lua sandbox's networking capabilities.

- [ ] **Optional DLC-style modules**

  Let hosts or players enable only selected PZLinux modules. Possible unlock
  mechanisms include sandbox toggles or in-world floppy disks. Decide first
  whether configuration is server-wide or individual player progression, since
  these require different implementations.

## v2.0.0

> Long-term direction dependent on Project Zomboid's native NPC system.

- [ ] **NPC-aware contracts and services**

  Once the base game's NPC system is available and stable, revisit contracts,
  couriers, clients, targets, shops and contacts using the APIs and behaviors the
  game actually provides. No concrete scope should be committed before then.
