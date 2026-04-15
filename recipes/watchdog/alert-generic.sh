#!/usr/bin/env bash
# Watchdog alert — generic template.
#
# Pick ONE of the examples below (or write your own) and uncomment. Called
# by watcher.sh on failure with these env vars set:
#   WATCHDOG_STATUS   ("FAIL")
#   WATCHDOG_RESULTS  (e.g. "tier1:pass tier2:pass tier3:FAIL(no-mcp-ping)")
#   WATCHDOG_ACTION   ("restart" | "no-action")
#   WATCHDOG_SERVICE  (service label)
#
# Keep tokens/secrets in environment variables, not in this file.

set -uo pipefail

STATUS="${WATCHDOG_STATUS:-UNKNOWN}"
RESULTS="${WATCHDOG_RESULTS:-}"
ACTION="${WATCHDOG_ACTION:-n/a}"
SERVICE="${WATCHDOG_SERVICE:-unknown}"
HOST="$(hostname 2>/dev/null || echo 'unknown-host')"

MESSAGE="ClawCode Watchdog [$STATUS] on ${HOST} / ${SERVICE} — checks: ${RESULTS} — action: ${ACTION}"

# ---------------- ntfy.sh (https://ntfy.sh) ----------------
# Requires env: NTFY_TOPIC (and optionally NTFY_SERVER, default https://ntfy.sh)
#
# : "${NTFY_TOPIC:?set NTFY_TOPIC}"
# curl -sf --max-time 10 -d "$MESSAGE" "${NTFY_SERVER:-https://ntfy.sh}/${NTFY_TOPIC}" >/dev/null

# ---------------- Pushover ----------------
# Requires env: PUSHOVER_TOKEN, PUSHOVER_USER
#
# : "${PUSHOVER_TOKEN:?}"; : "${PUSHOVER_USER:?}"
# curl -sf --max-time 10 https://api.pushover.net/1/messages.json \
#   --data-urlencode "token=${PUSHOVER_TOKEN}" \
#   --data-urlencode "user=${PUSHOVER_USER}" \
#   --data-urlencode "message=${MESSAGE}" >/dev/null

# ---------------- Slack incoming webhook ----------------
# Requires env: SLACK_WEBHOOK_URL
#
# : "${SLACK_WEBHOOK_URL:?}"
# curl -sf --max-time 10 -X POST -H 'Content-Type: application/json' \
#   --data "{\"text\":\"${MESSAGE}\"}" \
#   "$SLACK_WEBHOOK_URL" >/dev/null

# ---------------- Discord webhook ----------------
# Requires env: DISCORD_WEBHOOK_URL
#
# : "${DISCORD_WEBHOOK_URL:?}"
# curl -sf --max-time 10 -X POST -H 'Content-Type: application/json' \
#   --data "{\"content\":\"${MESSAGE}\"}" \
#   "$DISCORD_WEBHOOK_URL" >/dev/null

# ---------------- Zapier / generic webhook ----------------
# Requires env: ALERT_WEBHOOK_URL
#
# : "${ALERT_WEBHOOK_URL:?}"
# curl -sf --max-time 10 -X POST -H 'Content-Type: application/json' \
#   --data "{\"status\":\"${STATUS}\",\"service\":\"${SERVICE}\",\"results\":\"${RESULTS}\",\"action\":\"${ACTION}\",\"host\":\"${HOST}\"}" \
#   "$ALERT_WEBHOOK_URL" >/dev/null

# ---------------- Local mail ----------------
# Requires `mail` binary and env: ALERT_MAIL_TO
#
# : "${ALERT_MAIL_TO:?}"
# printf '%s\n' "$MESSAGE" | mail -s "ClawCode Watchdog [$STATUS] ${SERVICE}" "$ALERT_MAIL_TO"

# ---------------- Default: log only ----------------
# If nothing above is uncommented, we just echo to stdout. The watcher
# captures this into the watchdog log so there's at least a record.
echo "alert-generic: $MESSAGE"
echo "alert-generic: (no backend configured — uncomment a block in $0 to send somewhere)"
