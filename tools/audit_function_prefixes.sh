#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA_ROOT="$ROOT/Contents/mods/B42 PZLinux/42/media/lua"

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep is required: sudo apt install ripgrep"
    exit 127
fi

matches="$(rg -n '^function [A-Za-z_][A-Za-z0-9_:.]*\(' "$LUA_ROOT" || true)"

if [ -z "$matches" ]; then
    echo "No function declarations found."
    exit 0
fi

unprefixed="$(echo "$matches" | awk '
{
    line=$0
    name=$0
    sub(/^.*function /, "", name)
    sub(/\(.*/, "", name)
    root=name
    sub(/[:.].*/, "", root)
    if (root !~ /^PZLinux/) {
        print line
    }
}')"

if [ -z "$unprefixed" ]; then
    echo "All global function declarations use the PZLinux prefix."
    exit 0
fi

count="$(printf '%s\n' "$unprefixed" | wc -l)"
echo "$count function declarations do not start with PZLinux."
printf '%s\n' "$unprefixed" | sed -n '1,120p'
if [ "$count" -gt 120 ]; then
    echo "... truncated; run bash tools/audit_function_prefixes.sh | sed -n '1,999p' after raising the script limit if needed."
fi
