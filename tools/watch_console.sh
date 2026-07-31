#!/usr/bin/env bash
set -u

LOG_FILE="${PZ_LOG:-$HOME/.local/share/ProjectZomboid/console.txt}"

if [ ! -f "$LOG_FILE" ]; then
    echo "Project Zomboid console log not found: $LOG_FILE"
    echo "Set PZ_LOG=/path/to/console.txt if your install uses another location."
    exit 1
fi

if command -v rg >/dev/null 2>&1; then
    tail -F "$LOG_FILE" | rg --line-buffered -i 'pzlinux|lua|error|exception|stack trace|stacktrace'
else
    tail -F "$LOG_FILE"
fi
