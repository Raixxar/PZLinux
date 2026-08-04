#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA_ROOT="$ROOT/Contents/mods/B42 PZLinux/42/media/lua"

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep is required: sudo apt install ripgrep"
    exit 127
fi

fail=0

check_absent() {
    local pattern="$1"
    local label="$2"
    local matches

    matches="$(rg -n "$pattern" "$LUA_ROOT" || true)"
    if [ -n "$matches" ]; then
        echo "[FAIL] $label"
        echo "$matches"
        fail=1
    else
        echo "[ OK ] $label"
    fi
}

check_absent 'Pric2\s*=' "Dark web tables do not use Pric2"
check_absent 'PZLinuxMailLocation\s*\(' "Mail location helper is not duplicated globally"
check_absent 'contractsCompanyCodes\[7\]' "Contracts do not hard-code company index 7"
check_absent 'local checkSpawn\s*=' "Spawn checks do not use leaked checkSpawn state"
check_absent 'debug\s*=\s*true' "Release files do not force debug=true"

echo
echo "[INFO] Remaining direct getPlayer() calls outside central helper:"
get_player_matches="$(rg -n 'getPlayer\(' "$LUA_ROOT" | rg -v 'ISPZLinuxVariablesTables.lua|--' || true)"
if [ -n "$get_player_matches" ]; then
    get_player_count="$(printf '%s\n' "$get_player_matches" | wc -l)"
    echo "$get_player_count direct calls remain."
    printf '%s\n' "$get_player_matches" | sed -n '1,80p'
    if [ "$get_player_count" -gt 80 ]; then
        echo "... truncated; run rg -n 'getPlayer\\(' '$LUA_ROOT' for the full list."
    fi
else
    echo "none"
fi

echo
echo "[INFO] Duplicate global function names:"
dupes="$(rg -n '^function [A-Za-z0-9_]+\(' "$LUA_ROOT" \
    | sed -E 's/.*function ([A-Za-z0-9_]+)\(.*/\1/' \
    | sort \
    | uniq -d)"
if [ -n "$dupes" ]; then
    echo "$dupes"
else
    echo "none"
fi

exit "$fail"
