#!/usr/bin/env bash
set -uo pipefail

socket="$HOME/.cache/tab-grouper.sock"

if [ "${1:-}" = "open" ]; then
  previous_app=$(osascript -e 'tell application "System Events" to get bundle identifier of first process whose frontmost is true' 2>/dev/null)
  restore_focus() {
    [ -n "$previous_app" ] && [ "$previous_app" != "com.google.Chrome" ] && osascript -e "tell application id \"$previous_app\" to activate" 2>/dev/null
  }
  trap restore_focus EXIT
  shift
  for url in "$@"; do
    osascript - "$url" <<'EOF'
on run arguments
  tell application "Google Chrome"
    if (count of windows) is 0 then make new window
    make new tab at end of tabs of front window with properties {URL:item 1 of arguments}
  end tell
end run
EOF
  done
  exit 0
fi

send() {
  local response
  response=$(printf '%s\n' "$1" | nc -U -w 10 "$socket" 2>/dev/null)
  if [ -z "$response" ]; then
    echo "no answer from the Tab Grouper extension: Chrome must be running with it loaded; reload it in chrome://extensions" >&2
    exit 1
  fi
  if [ "$(jq -r '.ok' <<<"$response")" != "true" ]; then
    jq -r '.error' <<<"$response" >&2
    exit 1
  fi
  printf '%s' "$response"
}

if [ "${1:-}" = "list" ]; then
  response=$(send '{"action":"list"}') || exit 1
  jq -r '.result[] | "\(.title) (\(.color)) - \(.tabs | length) tabs: \(.tabs | join(", "))"' <<<"$response"
  exit 0
fi

if [ "${1:-}" = "reload=1" ]; then
  send '{"action":"reload"}' >/dev/null
  exit 0
fi

request='{"action":"group","matches":[],"group":"","title":"","color":"","tabTitle":""}'
for pair in "$@"; do
  key="${pair%%=*}"
  value="${pair#*=}"
  case "$key" in
    match) request=$(jq -c --arg value "$value" 'if $value == "" then . else .matches += [$value] end' <<<"$request") ;;
    group | title | color) request=$(jq -c --arg key "$key" --arg value "$value" '.[$key] = $value' <<<"$request") ;;
    tabtitle) request=$(jq -c --arg value "$value" '.tabTitle = $value' <<<"$request") ;;
  esac
done

send "$request" >/dev/null
