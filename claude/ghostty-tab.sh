#!/usr/bin/env bash
# Maps Claude Code sessions to Ghostty tabs so notifications can name and focus
# the right conversation. Ghostty exposes no tty, so a session is bound to
# whichever tab was selected when it started.

set -uo pipefail

MAP_FILE="${HOME}/.claude/session-tabs.json"

selected_tab() {
  osascript -e '
    tell application "Ghostty"
      repeat with win in windows
        repeat with tb in tabs of win
          if selected of tb then return (id of tb) & "|" & (name of tb)
        end repeat
      end repeat
      return ""
    end tell' 2>/dev/null
}

record_session() {
  local session_id="$1"
  local tab_info
  tab_info="$(selected_tab)"
  [ -z "$tab_info" ] && return 0

  local tab_id="${tab_info%%|*}"
  local tab_name="${tab_info#*|}"

  mkdir -p "$(dirname "$MAP_FILE")"
  [ -f "$MAP_FILE" ] || echo '{}' > "$MAP_FILE"

  local updated
  updated="$(jq --arg session "$session_id" --arg id "$tab_id" --arg name "$tab_name" \
    '.[$session] = {tabId: $id, tabName: $name}' "$MAP_FILE" 2>/dev/null)"
  [ -n "$updated" ] && printf '%s' "$updated" > "$MAP_FILE"
}

lookup_name() {
  local session_id="$1"
  [ -f "$MAP_FILE" ] || return 0
  jq -r --arg session "$session_id" '.[$session].tabName // empty' "$MAP_FILE" 2>/dev/null
}

focus_tab() {
  local session_id="$1"
  [ -f "$MAP_FILE" ] || return 0
  local tab_id
  tab_id="$(jq -r --arg session "$session_id" '.[$session].tabId // empty' "$MAP_FILE" 2>/dev/null)"
  [ -z "$tab_id" ] && return 0

  osascript -e "
    tell application \"Ghostty\"
      activate
      repeat with win in windows
        repeat with tb in tabs of win
          if (id of tb) is \"${tab_id}\" then
            activate window win
            select tab tb
            return
          end if
        end repeat
      end repeat
    end tell" 2>/dev/null
}

case "${1:-}" in
  record) record_session "${2:-}" ;;
  name)   lookup_name "${2:-}" ;;
  focus)  focus_tab "${2:-}" ;;
  *)      echo "usage: ghostty-tab.sh {record|name|focus} <session-id>" >&2; exit 1 ;;
esac
