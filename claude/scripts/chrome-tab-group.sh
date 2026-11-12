#!/usr/bin/env bash
set -uo pipefail

page="chrome-extension://jefoichdnlokggnejahekcndonjkdaap/group.html"

# The extension writes the groups into its page's title, read here through
# Chrome's AppleScript. The old System Events walk of Chrome's window needed
# Accessibility for whatever shell ran this, including the find-reviews job.
if [ "${1:-}" = "list" ]; then
  result=$(osascript <<EOF
tell application "Google Chrome"
  open location "$page?list"
  repeat 50 times
    repeat with chromeWindow in windows
      repeat with chromeTab in tabs of chromeWindow
        if URL of chromeTab starts with "$page?list" and title of chromeTab starts with "groups:" then
          set groupsTitle to title of chromeTab
          close chromeTab
          return groupsTitle
        end if
      end repeat
    end repeat
    delay 0.1
  end repeat
end tell
EOF
  )
  if [ -z "$result" ]; then
    echo "no answer from the Tab Grouper extension; reload it in chrome://extensions" >&2
    exit 1
  fi
  jq -r '.[] | "\(.title) (\(.color)) - \(.tabs | length) tabs: \(.tabs | join(", "))"' <<<"${result#groups:}"
  exit 0
fi

query=""
for pair in "$@"; do
  key="${pair%%=*}"
  value="${pair#*=}"
  query="${query}&${key}=$(jq -rn --arg value "$value" '$value | @uri')"
done

osascript -e "tell application \"Google Chrome\" to open location \"$page?${query#&}\""
