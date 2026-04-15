#!/usr/bin/env bash
# Watchdog alert — Telegram Bot API.
#
# Called by watcher.sh when a check fails. Reads context from environment
# variables set by the watcher:
#   WATCHDOG_STATUS    ("FAIL")
#   WATCHDOG_RESULTS   (tier results string)
#   WATCHDOG_ACTION    ("restart" or "no-action")
#   WATCHDOG_SERVICE   (service label)
#
# Token and chat ID must be provided via environment (never hardcoded):
#   TELEGRAM_BOT_TOKEN
#   TELEGRAM_CHAT_ID
#
# If the bot's token lives in ~/.claude/channels/telegram/.env (the convention
# used by the Telegram channel plugin), this script auto-sources it.

set -uo pipefail

# Auto-source the plugin's env file if present — typical install keeps
# TELEGRAM_BOT_TOKEN there.
PLUGIN_ENV="$HOME/.claude/channels/telegram/.env"
if [[ -r "$PLUGIN_ENV" && -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  # shellcheck disable=SC1090
  set -a; . "$PLUGIN_ENV"; set +a
fi

TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT="${TELEGRAM_CHAT_ID:-}"

if [[ -z "$TOKEN" ]]; then
  echo "alert-telegram: TELEGRAM_BOT_TOKEN not set — skipping alert" >&2
  exit 0  # non-fatal: watchdog already did its primary job
fi
if [[ -z "$CHAT" ]]; then
  echo "alert-telegram: TELEGRAM_CHAT_ID not set — skipping alert" >&2
  exit 0
fi

STATUS="${WATCHDOG_STATUS:-UNKNOWN}"
RESULTS="${WATCHDOG_RESULTS:-}"
ACTION="${WATCHDOG_ACTION:-n/a}"
SERVICE="${WATCHDOG_SERVICE:-unknown-service}"

HOST="$(hostname 2>/dev/null || echo 'unknown-host')"
MESSAGE=$(cat <<EOF
⚠️ ClawCode Watchdog — ${STATUS}

host:    ${HOST}
service: ${SERVICE}
checks:  ${RESULTS}
action:  ${ACTION}
EOF
)

curl -sf --max-time 10 \
  -X POST \
  "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT}" \
  --data-urlencode "text=${MESSAGE}" \
  --data-urlencode "parse_mode=HTML" \
  >/dev/null || echo "alert-telegram: failed to send" >&2
