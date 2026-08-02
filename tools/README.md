# PZLinux tools

Small local helpers for release validation and in-game debugging.

## Install on Debian

```bash
sudo apt update
sudo apt install -y lua5.1 liblua5.1-0-dev luarocks luacheck imagemagick ffmpeg ripgrep
```

If `luacheck` is not available from your Debian repository:

```bash
sudo apt install -y build-essential
sudo luarocks --lua-version=5.1 install luacheck
```

## Commands

```bash
bash tools/run_static_audit.sh
bash tools/audit_function_prefixes.sh
bash tools/audit_hardcoded_text.sh
bash tools/check_lua_syntax.sh
bash tools/audit_assets.sh
lua5.1 tools/audit_locations.lua
lua5.1 tools/check_translations.lua
lua5.1 tools/check_release_metadata.lua
lua5.1 tools/test_contract_authority.lua
lua5.1 tools/test_contract_world_authority.lua
lua5.1 tools/test_darkweb_delivery.lua
lua5.1 tools/test_hacking_authority.lua
lua5.1 tools/test_mailbox_proximity.lua
lua5.1 tools/test_atm_inventory.lua
lua5.1 tools/test_request_delivery.lua
lua5.1 tools/test_inventory_authority.lua
lua5.1 tools/test_reputation_economy.lua
lua5.1 tools/test_trading_fee.lua
lua5.1 tools/test_poker_engine.lua
lua5.1 tools/test_race_settlement.lua
lua5.1 tools/test_typing.lua
bash tools/simulate_zombie_races.sh
bash tools/watch_console.sh
```

## Zombie Race balance simulation

The simulator uses the same shared card, race and payout engine as the server. Its
default strategy always bets on the lowest displayed odds and resolves equal
favorites randomly:

```bash
bash tools/simulate_zombie_races.sh
```

The quick run uses 1,000 races. Generate the release report with a reproducible
100,000-race sample:

```bash
bash tools/simulate_zombie_races.sh --runs 100000 --seed 42020
```

The Markdown report is written to `doc/RAPPORT_ZOMBIE_RACES.md`. Defaults can be
changed with `PZ_RACE_RUNS`, `PZ_RACE_STAKE`, `PZ_RACE_SEED` and
`PZ_RACE_REPORT`; run `lua5.1 tools/simulate_zombie_races.lua --help` for every
option.

## Live game logs

Project Zomboid writes its Windows client log to:

```text
%USERPROFILE%\Zomboid\console.txt
```

To follow it directly from a Windows PowerShell terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\watch_console.ps1
```

Use `-All` to display every line or specify another save directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\watch_console.ps1 `
  -LogFile "D:\Zomboid\console.txt" -All
```

### Development container on a Windows host

The Debian container cannot read the host log unless the Windows directory is
mounted into it. Add this mount to `.devcontainer/devcontainer.json`:

```json
{
  "mounts": [
    "source=${localEnv:USERPROFILE}/Zomboid,target=/pz-logs,type=bind,readonly"
  ]
}
```

Rebuild the container, start Project Zomboid on Windows, then run:

```bash
bash tools/watch_console.sh
```

The script detects `/pz-logs/console.txt` automatically. The equivalent Docker
Compose volume is:

```yaml
services:
  pzlinux-dev:
    volumes:
      - "${PZ_WINDOWS_LOG_DIR}:/pz-logs:ro"
```

Set `PZ_WINDOWS_LOG_DIR=C:/Users/<name>/Zomboid` in the Compose `.env` file.

On a native Linux install, `watch_console.sh` also detects the usual locations:

```bash
~/.local/share/ProjectZomboid/console.txt
~/Zomboid/console.txt
```

The path can always be passed explicitly or through `PZ_LOG`:

```bash
PZ_LOG=/pz-logs/console.txt bash tools/watch_console.sh
bash tools/watch_console.sh /another/path/console.txt
```

Display every line or customize the filter when debugging a specific command:

```bash
PZ_LOG_ALL=1 bash tools/watch_console.sh
PZ_LOG_FILTER='PZLinuxContract|rejected|traceback' bash tools/watch_console.sh
```

## Fast release loop

1. Run `bash tools/run_static_audit.sh`.
2. Run `bash tools/audit_function_prefixes.sh`.
3. Run `bash tools/audit_hardcoded_text.sh`.
4. Run `bash tools/check_lua_syntax.sh`.
5. Run `bash tools/audit_assets.sh`.
6. Run `lua5.1 tools/audit_locations.lua`, `lua5.1 tools/check_translations.lua`, `lua5.1 tools/check_release_metadata.lua`, then every `tools/test_*.lua` test.
7. Start a new B42.20.x save, reproduce one feature, and keep
   `watch_console.ps1` on Windows or `watch_console.sh` with `/pz-logs` mounted
   open in a VSCode terminal.
