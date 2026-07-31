#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: tools/nearest_street.sh <x> <y> [streets-json]" >&2
    exit 2
fi

x="$1"
y="$2"
streets_json="${3:-/tmp/pz_streets_42_20.json}"

if [ ! -f "$streets_json" ]; then
    echo "Missing streets JSON: $streets_json" >&2
    echo "Download it with:" >&2
    echo "curl -L -sS -o /tmp/pz_streets_42_20.json https://map.projectzomboid.com/maps/42.20.0/streets/marks.json" >&2
    exit 1
fi

jq -r '.[] | select(.points and (.points|length)>1) | [.name, (.points|map([.x,.y])|@json)] | @tsv' "$streets_json" \
    | perl -MJSON::PP -F'\t' -lane '
        BEGIN { $px = shift @ARGV; $py = shift @ARGV; }
        $name = $F[0];
        $pts = decode_json($F[1]);
        $best = 1e18;
        $bx = 0;
        $by = 0;
        for ($i = 0; $i < @$pts - 1; $i++) {
            ($ax, $ay) = @{$pts->[$i]};
            ($cx, $cy) = @{$pts->[$i + 1]};
            $vx = $cx - $ax;
            $vy = $cy - $ay;
            $wx = $px - $ax;
            $wy = $py - $ay;
            $den = $vx * $vx + $vy * $vy;
            $t = $den ? ($wx * $vx + $wy * $vy) / $den : 0;
            $t = 0 if $t < 0;
            $t = 1 if $t > 1;
            $qx = $ax + $t * $vx;
            $qy = $ay + $t * $vy;
            $d = sqrt(($px - $qx) ** 2 + ($py - $qy) ** 2);
            if ($d < $best) {
                $best = $d;
                $bx = $qx;
                $by = $qy;
            }
        }
        printf "%.2f\t%s\tnearest=(%.1f,%.1f)\n", $best, $name, $bx, $by;
    ' "$x" "$y" \
    | sort -n \
    | awk 'NR <= 10 { print }'
