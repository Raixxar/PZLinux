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
bash tools/watch_console.sh
```

`watch_console.sh` follows the usual Linux Project Zomboid console log:

```bash
~/.local/share/ProjectZomboid/console.txt
```

You can override it when needed:

```bash
PZ_LOG=/path/to/console.txt bash tools/watch_console.sh
```

## Fast release loop

1. Run `bash tools/run_static_audit.sh`.
2. Run `bash tools/audit_function_prefixes.sh`.
3. Run `bash tools/audit_hardcoded_text.sh`.
4. Run `bash tools/check_lua_syntax.sh`.
5. Run `bash tools/audit_assets.sh`.
6. Start a new B42.20.x save, reproduce one feature, and keep `bash tools/watch_console.sh` open in a VSCode terminal.
