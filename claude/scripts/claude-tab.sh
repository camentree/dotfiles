#!/usr/bin/env bash
# Shows Claude Code's state as a coloured dot on the Ghostty tab.
#
#   record       SessionStart                       binds the session to its tab
#   working      UserPromptSubmit, ElicitationResult yellow
#   done         Stop                                green when focused, red when not
#   attention    Notification, StopFailure           red
#   clear        SessionEnd                          strips the dot
#
# Ghostty exposes no tty, so a session is bound to the tab selected at launch.
# Titles are set with `perform action set_tab_title`, which works on tabs the
# user has pinned with cmd+shift+i — escape sequences do not.

set -uo pipefail

MAP_FILE="${HOME}/.claude/session-tabs.json"
WORKING="🔸"
IDLE="🔹"
ATTENTION="♦️"

payload="$(cat)"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"

if [ -n "${CLAUDE_TAB_DEBUG:-}" ] || [ -f "${HOME}/.claude/tab-debug.on" ]; then
  printf '%s mode=%s event=%s type=%s session=%s\n' \
    "$(date +%T)" "${1:-}" \
    "$(printf '%s' "$payload" | jq -r '.hook_event_name // "?"')" \
    "$(printf '%s' "$payload" | jq -r '.notification_type // "-"')" \
    "${session_id:0:8}" >> "${HOME}/.claude/tab-debug.log"
fi

[ -z "$session_id" ] && exit 0

tab_id_for_session() {
  [ -f "$MAP_FILE" ] || return 0
  jq -r --arg session "$session_id" '.[$session].tabId // empty' "$MAP_FILE" 2>/dev/null
}

record_session() {
  local tab_info
  tab_info="$(osascript -e '
    tell application "Ghostty"
      repeat with win in windows
        repeat with tb in tabs of win
          if selected of tb then return (id of tb) & "|" & (name of tb)
        end repeat
      end repeat
      return ""
    end tell' 2>/dev/null)"
  [ -z "$tab_info" ] && return 0

  mkdir -p "$(dirname "$MAP_FILE")"
  [ -f "$MAP_FILE" ] || echo '{}' > "$MAP_FILE"

  local updated
  updated="$(jq --arg session "$session_id" \
                --arg id "${tab_info%%|*}" \
                --arg name "${tab_info#*|}" \
    '.[$session] = {tabId: $id, tabName: $name}' "$MAP_FILE" 2>/dev/null)"
  [ -n "$updated" ] && printf '%s' "$updated" > "$MAP_FILE"
}

tab_is_focused() {
  local tab_id="$1"
  [ "$(osascript -e "
    tell application \"Ghostty\"
      if not frontmost then return \"no\"
      repeat with win in windows
        repeat with tb in tabs of win
          if (id of tb) is \"${tab_id}\" and (selected of tb) then return \"yes\"
        end repeat
      end repeat
      return \"no\"
    end tell" 2>/dev/null)" = "yes" ]
}

tab_name() {
  osascript -e "
    tell application \"Ghostty\"
      repeat with win in windows
        repeat with tb in tabs of win
          if (id of tb) is \"${1}\" then return name of tb
        end repeat
      end repeat
      return \"\"
    end tell" 2>/dev/null
}

current_state() {
  [ -f "$MAP_FILE" ] || return 0
  jq -r --arg session "$session_id" '.[$session].state // empty' "$MAP_FILE" 2>/dev/null
}

remember_state() {
  local updated
  updated="$(jq --arg session "$session_id" --arg state "$1" \
    '.[$session].state = $state' "$MAP_FILE" 2>/dev/null)"
  [ -n "$updated" ] && printf '%s' "$updated" > "$MAP_FILE"
}

set_marker() {
  local tab_id="$1" marker="$2"
  local name base title
  [ "$(current_state)" = "$marker" ] && return 0
  name="$(tab_name "$tab_id")"
  [ -z "$name" ] && return 0

  base="$(printf '%s' "$name" | LC_ALL=C sed -E 's/^([^[:alnum:][:space:]]+[[:space:]]*)+//')"
  [ -z "$base" ] && base="$name"

  if [ -n "$marker" ]; then
    title="${marker} ${base}"
  else
    title="${base}"
  fi

  osascript -e "
    tell application \"Ghostty\"
      repeat with win in windows
        repeat with tb in tabs of win
          if (id of tb) is \"${tab_id}\" then
            perform action \"set_tab_title:${title}\" on (focused terminal of tb)
            return
          end if
        end repeat
      end repeat
    end tell" >/dev/null 2>&1

  remember_state "$marker"
}

forget_session() {
  [ -f "$MAP_FILE" ] || return 0
  local cleared
  cleared="$(jq --arg session "$session_id" 'del(.[$session])' "$MAP_FILE" 2>/dev/null)"
  [ -n "$cleared" ] && printf '%s' "$cleared" > "$MAP_FILE"
}

case "${1:-}" in
  record)
    record_session
    tab_id="$(tab_id_for_session)"
    [ -n "$tab_id" ] && set_marker "$tab_id" "$IDLE"
    ;;
  working)
    tab_id="$(tab_id_for_session)"
    [ -n "$tab_id" ] && set_marker "$tab_id" "$WORKING"
    ;;
  attention)
    tab_id="$(tab_id_for_session)"
    [ -n "$tab_id" ] && set_marker "$tab_id" "$ATTENTION"
    ;;
  done)
    tab_id="$(tab_id_for_session)"
    if [ -n "$tab_id" ]; then
      if tab_is_focused "$tab_id"; then
        set_marker "$tab_id" "$IDLE"
      else
        set_marker "$tab_id" "$ATTENTION"
      fi
    fi
    ;;
  clear)
    tab_id="$(tab_id_for_session)"
    [ -n "$tab_id" ] && set_marker "$tab_id" ""
    forget_session
    ;;
esac

exit 0
