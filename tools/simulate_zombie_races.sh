#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if command -v lua5.1 >/dev/null 2>&1; then
    LUA_BIN="lua5.1"
elif command -v lua >/dev/null 2>&1; then
    LUA_BIN="lua"
else
    echo "Lua 5.1 is required. Install it with: sudo apt install lua5.1"
    exit 1
fi

RUNS="${PZ_RACE_RUNS:-1000}"
STAKE="${PZ_RACE_STAKE:-100}"
SEED="${PZ_RACE_SEED:-$(date +%s)}"
OUTPUT="${PZ_RACE_REPORT:-$REPO_ROOT/doc/RAPPORT_ZOMBIE_RACES.md}"

cd "$REPO_ROOT"
exec "$LUA_BIN" tools/simulate_zombie_races.lua \
    --runs "$RUNS" \
    --stake "$STAKE" \
    --seed "$SEED" \
    --output "$OUTPUT" \
    "$@"
