#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA_ROOT="$ROOT/Contents/mods/B42 PZLinux/42/media/lua"

LUAC_BIN=""
if command -v luac5.1 >/dev/null 2>&1; then
    LUAC_BIN="luac5.1"
elif command -v luac >/dev/null 2>&1; then
    LUAC_BIN="luac"
fi

if [ -z "$LUAC_BIN" ]; then
    echo "luac 5.1 is required: sudo apt install lua5.1"
    exit 127
fi

fail=0

while IFS= read -r -d '' file; do
    if ! "$LUAC_BIN" -p "$file" >/dev/null; then
        fail=1
    fi
done < <(find "$LUA_ROOT" -type f -name '*.lua' -print0)

if command -v luacheck >/dev/null 2>&1; then
    luacheck --config "$ROOT/tools/.luacheckrc" "$LUA_ROOT" || fail=1
else
    echo "luacheck not found; syntax check completed without lint."
fi

exit "$fail"
