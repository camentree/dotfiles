#!/usr/bin/env bash
# macOS notifications for Claude Code, titled with the Ghostty tab the session
# belongs to. Clicking focuses that tab where terminal-notifier is available.
#
#   notify.sh input   Notification hook  — session is blocking on you
#   notify.sh start   UserPromptSubmit   — stamps the turn's start time
#   notify.sh stop    Stop hook          — announces turns longer than a minute

set -uo pipefail

TIMER_FILE="${HOME}/.claude/session-timers.json"
LONG_TURN_SECONDS=60

payload="$(cat)"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"

send() {
  local body="$1"
  local tab_name
  tab_name="$(bash "${HOME}/.claude/ghostty-tab.sh" name "$session_id")"
  [ -z "$tab_name" ] && tab_name="$(basename "${cwd:-claude}")"

  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier \
      -title "$tab_name" \
      -message "$body" \
      -group "claude-${session_id}" \
      -sound Ping \
      -execute "bash ${HOME}/.claude/ghostty-tab.sh focus ${session_id}" >/dev/null 2>&1
  else
    osascript -e "display notification \"${body}\" with title \"${tab_name//\"/\\\"}\" sound name \"Ping\"" >/dev/null 2>&1
  fi
}

stamp_start() {
  [ -z "$session_id" ] && return 0
  mkdir -p "$(dirname "$TIMER_FILE")"
  [ -f "$TIMER_FILE" ] || echo '{}' > "$TIMER_FILE"
  local updated
  updated="$(jq --arg session "$session_id" --argjson now "$(date +%s)" \
    '.[$session] = $now' "$TIMER_FILE" 2>/dev/null)"
  [ -n "$updated" ] && printf '%s' "$updated" > "$TIMER_FILE"
}

announce_if_long() {
  [ -f "$TIMER_FILE" ] || return 0
  local started
  started="$(jq -r --arg session "$session_id" '.[$session] // empty' "$TIMER_FILE" 2>/dev/null)"
  [ -z "$started" ] && return 0

  local elapsed=$(( $(date +%s) - started ))
  local cleared
  cleared="$(jq --arg session "$session_id" 'del(.[$session])' "$TIMER_FILE" 2>/dev/null)"
  [ -n "$cleared" ] && printf '%s' "$cleared" > "$TIMER_FILE"

  [ "$elapsed" -ge "$LONG_TURN_SECONDS" ] && send "responded"
  return 0
}

case "${1:-input}" in
  input) send "needs input" ;;
  start) stamp_start ;;
  stop)  announce_if_long ;;
esac

exit 0
