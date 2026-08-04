#!/usr/bin/env bash
set -u

PZ_LOG_FILTER="${PZ_LOG_FILTER:-pzlinux|lua|error|exception|stack trace|stacktrace|callstack|traceback|rejected|rollback|refund}"

PZLinuxPrintUsage() {
    cat <<'EOF'
Usage: bash tools/watch_console.sh [path/to/console.txt]

The path can also be supplied through PZ_LOG. In a development container, mount
the Windows Zomboid directory read-only at /pz-logs.

Environment:
  PZ_LOG=/path/to/console.txt  Explicit log path
  PZ_LOG_ALL=1                Print every line instead of filtering
  PZ_LOG_FILTER='regex'       Override the default case-insensitive filter
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    PZLinuxPrintUsage
    exit 0
fi

LOG_FILE="${1:-${PZ_LOG:-}}"

if [ -z "$LOG_FILE" ]; then
    for candidate in \
        "/pz-logs/console.txt" \
        "$HOME/.local/share/ProjectZomboid/console.txt" \
        "$HOME/Zomboid/console.txt"
    do
        if [ -f "$candidate" ]; then
            LOG_FILE="$candidate"
            break
        fi
    done
fi

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    echo "Project Zomboid console log not found: ${LOG_FILE:-no path detected}"
    echo "Pass the path, set PZ_LOG, or mount the Windows Zomboid directory at /pz-logs."
    echo "Run with --help for examples."
    exit 1
fi

echo "Following Project Zomboid log: $LOG_FILE"

if [ "${PZ_LOG_ALL:-0}" = "1" ]; then
    tail -n 0 -F "$LOG_FILE"
elif command -v rg >/dev/null 2>&1; then
    tail -n 0 -F "$LOG_FILE" | rg --line-buffered --color=always -i "$PZ_LOG_FILTER"
else
    tail -n 0 -F "$LOG_FILE" | grep --line-buffered -Ei "$PZ_LOG_FILTER"
fi
