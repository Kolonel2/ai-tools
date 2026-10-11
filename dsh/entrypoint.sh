#!/bin/bash
set -euo pipefail

: "${DSH_UI_USERNAME:?DSH_UI_USERNAME is required}"
: "${DSH_UI_USERPASS:?DSH_UI_USERPASS is required}"

DSH_UI_PASSHASH="$(caddy hash-password --plaintext "$DSH_UI_USERPASS")"
export DSH_UI_PASSHASH
unset DSH_UI_USERPASS

mkdir -p "$DSH_WORKSPACE" "$DSH_HOME"

dsh web --no-open --port 3081 &
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Exit (and let Cycle restart the container) as soon as either process dies
wait -n
exit 1
