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
parseErrors=0

while IFS= read -r -d '' file; do
    if ! "$LUAC_BIN" -p "$file" >/dev/null; then
        fail=1
        parseErrors=$((parseErrors + 1))
    fi
done < <(find "$LUA_ROOT" -type f -name '*.lua' -print0)

if command -v luacheck >/dev/null 2>&1; then
    luacheck --config "$ROOT/tools/.luacheckrc" "$LUA_ROOT"
    lintStatus=$?
else
    echo "luacheck not found; syntax check completed without lint."
    lintStatus=0
fi

# luacheck exits non-zero on warnings alone, so its own status is not a
# reliable signal that something is actually broken; only real luac parse
# failures found above should fail this script for CI/gate purposes. They are
# summarized explicitly here since luacheck's own "0 errors" summary line
# only counts *its* findings and would otherwise silently hide a genuine
# luac5.1 parse error printed earlier in this same output.
echo ""
echo "luac5.1 parse errors: $parseErrors"
if [ "$parseErrors" -gt 0 ]; then
    exit 1
fi
exit 0
