#!/bin/bash
set -euo pipefail

: "${DSH_UI_USERNAME:?DSH_UI_USERNAME is required}"
: "${DSH_UI_USERPASS:?DSH_UI_USERPASS is required}"
DSH_PUBLIC_HOST="${DSH_PUBLIC_HOST:-dsh.agents.sera4.ai}"

DSH_UI_PASSHASH="$(caddy hash-password --plaintext "$DSH_UI_USERPASS")"
export DSH_UI_PASSHASH
unset DSH_UI_USERPASS

mkdir -p "$DSH_WORKSPACE" "$DSH_HOME" /run/dsh
rm -f /run/dsh/cookie /run/dsh/dsh.log

# The NFS-backed /workspace creates every file as mode 777, but dsh refuses to
# start unless its credentials file is owner-only.
[ -f "$DSH_HOME/.credentials.yaml" ] && chmod 600 "$DSH_HOME/.credentials.yaml"

# dsh only trusts loopback hosts unless told otherwise, and prints a one-time
# login URL (token) on every start.
dsh web --no-open --port 3081 --trusted-host "$DSH_PUBLIC_HOST" 2>&1 | tee /run/dsh/dsh.log &

TOKEN=""
for _ in $(seq 1 60); do
  TOKEN="$(grep -ao 'token=[A-Za-z0-9_-]*' /run/dsh/dsh.log 2>/dev/null | head -n1 | cut -d= -f2 || true)"
  [ -n "$TOKEN" ] && break
  sleep 1
done
[ -n "$TOKEN" ] || { echo "entrypoint: dsh did not print a login token" >&2; exit 1; }

# Exchange the token for dsh's session cookie, as the public host name
COOKIE=""
for _ in $(seq 1 15); do
  COOKIE="$(curl -si -H "Host: $DSH_PUBLIC_HOST" "http://127.0.0.1:3081/?token=$TOKEN" \
    | tr -d '\r' | grep -i '^set-cookie:' | head -n1 | sed 's/^[^:]*: *//; s/;.*//' || true)"
  [ -n "$COOKIE" ] && break
  sleep 1
done
[ -n "$COOKIE" ] || { echo "entrypoint: could not obtain dsh session cookie" >&2; exit 1; }
printf '%s' "$COOKIE" > /run/dsh/cookie
chmod 600 /run/dsh/cookie

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Exit (and let Cycle restart the container) as soon as either process dies
wait -n
exit 1
