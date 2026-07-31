#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA_DIR="${1:-$ROOT_DIR/Contents/mods/B42 PZLinux/42/media/lua}"

echo "# PZLinux namespace audit"
echo
echo "Lua root: $LUA_DIR"
echo

echo "## Unprefixed class/timed-action globals"
rg -n '^[A-Za-z_][A-Za-z0-9_]*\s*=\s*(ISPanel|ISBaseTimedAction):derive' "$LUA_DIR" \
  | awk -F: '
    {
      line = $0
      sub(/^.*\//, "", line)
      name = $3
      sub(/=.*/, "", name)
      gsub(/[ \t]/, "", name)
      if (name !~ /^PZLinux/) print
    }
  ' || true
echo

echo "## Unprefixed global function declarations"
rg -n '^function [A-Za-z_][A-Za-z0-9_]*\(' "$LUA_DIR" \
  | awk '
    {
      line = $0
      sub(/^.*function /, "", line)
      sub(/\(.*/, "", line)
      if (line !~ /^PZLinux/) print
    }
  ' || true
echo

echo "## Function declaration root counts"
rg -n '^function [A-Za-z_][A-Za-z0-9_:.]*\(' "$LUA_DIR" \
  | awk '
    {
      line = $0
      sub(/^.*function /, "", line)
      sub(/\(.*/, "", line)
      root = line
      sub(/[.:].*/, "", root)
      if (root !~ /^PZLinux/) print root
    }
  ' \
  | sort | uniq -c | sort -nr || true
echo

echo "## Event callbacks using unprefixed names"
rg -n 'Events\.[A-Za-z0-9_]+\.Add\([A-Za-z_][A-Za-z0-9_]*\)' "$LUA_DIR" \
  | awk '
    {
      line = $0
      cb = line
      sub(/^.*Add\(/, "", cb)
      sub(/\).*/, "", cb)
      if (cb !~ /^PZLinux/) print
    }
  ' || true
