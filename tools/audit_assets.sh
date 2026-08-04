#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA_ROOT="$ROOT/Contents/mods/B42 PZLinux/42/media"
fail=0

if command -v identify >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
        identify -quiet "$file" >/dev/null || fail=1
    done < <(find "$MEDIA_ROOT" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0)
else
    echo "identify not found; install ImageMagick: sudo apt install imagemagick"
    fail=1
fi

if command -v ffprobe >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
        ffprobe -v error -show_format -show_streams "$file" >/dev/null || fail=1
    done < <(find "$MEDIA_ROOT" -type f \( -iname '*.ogg' -o -iname '*.wav' \) -print0)
else
    echo "ffprobe not found; install FFmpeg: sudo apt install ffmpeg"
    fail=1
fi

exit "$fail"
