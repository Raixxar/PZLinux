[h1]PZLinux 1.0.20[/h1]

PZLinux 1.0.20 is a maintenance update for Project Zomboid Build 42.20.x. It
adds the new Poker AI table work, completes the Blackjack shoe UI, and hardens
betting money/session handling before production.

[h2]Online Betting[/h2]

[list]
[*] Added a full six-seat Texas Hold'em Poker table with persistent stacks,
buy-ins, cash-out, hand history and server-owned action resolution.
[*] Added registry-driven Poker AI personalities: ZombieBrain, Drunkard,
Survivor and Shark.
[*] Skill-aware Poker AIs still make their betting decisions from per-seat Monte
Carlo equity estimates, with cached simulations per board state.
[*] Poker lobby difficulty now scales from forgiving micro tables to brutal
elite tables through different AI mixes and skill settings.
[*] Blackjack now deals from a persistent per-table shoe and displays public
shoe depth, deck count and shuffle state in the UI.
[*] Multiplayer Blackjack now detects table shuffles through `shoeShuffleId`, so
another player's hand turning over the shoe is still visible.
[/list]

[h2]Production Hardening[/h2]

[list]
[*] Poker table opening now rolls back the buy-in if setup fails after debit.
[*] Poker can no longer overwrite an active table session or let AI
`createSeat()` mutate live stacks/session state.
[*] Invalid Poker AI decisions degrade to fold when chips are owed or check when
the action is free; AI exceptions are logged and recovered locally.
[*] Shark and Survivor raise sizing now converts desired total bet into the
additional amount still needed, preventing over-raises after blinds or prior
street bets.
[*] Poker reads ignore stale previous-street actions and no longer replace the
aggressor with later callers.
[*] Structured Poker and Blackjack server logs now include request IDs, session
or table context, actions, outcomes, money movement and enough state to
troubleshoot production reports without exposing hidden deck composition.
[/list]

[h2]Validation[/h2]

[list]
[*] Added regression coverage for Poker AI selection, Monte Carlo use, setup
isolation, invalid decisions, exception recovery, raise sizing and diagnostics.
[*] Added regression coverage for Blackjack shoe persistence, multiplayer
shuffle detection, translations and diagnostics.
[*] Full Lua test suite, static audit, release metadata checks and Poker
tournament smoke pass.
[*] Release metadata and Workshop version checks pass for 1.0.20.
[/list]

[h2]Previous 1.0.19 Highlights[/h2]

[list]
[*] Raised the mailbox post-delivery carrying limit to 80 while keeping
persistent parcels capped at 60.
[*] Preserved parcel IDs, order IDs and retry behavior for heavy mailbox
deliveries.
[/list]

[h2]Compatibility[/h2]

PZLinux 1.0.20 retains the B42_PZLinux mod ID and all existing player/world
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
