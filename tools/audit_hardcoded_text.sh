#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUA_ROOT="$ROOT/Contents/mods/B42 PZLinux/42/media/lua"

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep is required: sudo apt install ripgrep"
    exit 127
fi

matches="$(rg -n '"[^"]{3,}"' "$LUA_ROOT" \
    | rg -v '/Translate/|ISPZLinuxVariablesTables.lua|getTexture\(|getText\(|PZLinuxGetText\(|getFullType\(|FindItem\(|AddItem\(|setActionAnim\(|SetVariable\(|PlayWorldSound\(' \
    || true)"

if [ -z "$matches" ]; then
    echo "No hardcoded text candidates found."
    exit 0
fi

count="$(printf '%s\n' "$matches" | wc -l)"
echo "$count hardcoded text candidates found."
printf '%s\n' "$matches" | sed -n '1,120p'
if [ "$count" -gt 120 ]; then
    echo "... truncated; inspect the full list by editing the limit in tools/audit_hardcoded_text.sh or running the rg command directly."
fi
