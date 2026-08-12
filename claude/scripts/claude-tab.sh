#!/usr/bin/env bash
set -uo pipefail

IDLE_GLYPH="🔹"
WORKING_GLYPH="🔸"
mode="${1:-}"
payload="$(cat)"

device="${CLAUDE_TAB_TTY:-}"
if [ ! -w "$device" ]; then
  echo "claude-tab: CLAUDE_TAB_TTY is not a writable terminal (got '${device}') — start Claude through the 'claude' shell function in home/zshrc." >&2
  exit 1
fi

if [ "$mode" = "bell" ]; then
  printf '\a' > "$device"
  exit 0
fi

name="${CLAUDE_TAB_NAME:-}"
if [ -z "$name" ]; then
  working_directory="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
  name="${working_directory##*/}"
fi
if [ -z "$name" ]; then
  exit 0
fi

case "$mode" in
  idle)    title="${IDLE_GLYPH} ${name}" ;;
  working) title="${WORKING_GLYPH} ${name}" ;;
  clear)   title="${name}" ;;
  *)       exit 0 ;;
esac

printf '\033]2;%s\033\\' "$title" > "$device"
exit 0
