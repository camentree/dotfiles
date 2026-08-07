#!/usr/bin/env bash
set -uo pipefail

payload="$(cat)"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
[ -n "$session_id" ] && bash "${HOME}/.claude/ghostty-tab.sh" record "$session_id"
exit 0
