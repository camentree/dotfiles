#!/usr/bin/env bash
set -uo pipefail

IDLE_GLYPH="🔹"
WORKING_GLYPH="🔸"
mode="${1:-}"

device="${OUTER_TTY:-/dev/tty}"
{ true > "$device"; } 2>/dev/null || exit 0

if [ "$mode" = "bell" ]; then
  printf '\a' > "$device"
  exit 0
fi

tab_key="$(basename "$device")"
name="$(cat "$HOME/.claude/tab-names/$tab_key" 2>/dev/null)"
if [ -z "$name" ]; then
  project_dir="${CLAUDE_PROJECT_DIR:-}"
  name="${project_dir##*/}"
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
