#!/usr/bin/env bash
set -uo pipefail

DONE_GLYPH="🔹"
BLOCKED_GLYPH="♦️"
WORKING_GLYPH="🔸"
mode="${1:-}"

device="${OUTER_TTY:-/dev/tty}"
{ true > "$device"; } 2>/dev/null || exit 0

tab_key="$(basename "$device")"
name="$(cat "$HOME/.claude/tab-names/$tab_key" 2>/dev/null)"
if [ -z "$name" ]; then
  project_dir="${CLAUDE_PROJECT_DIR:-}"
  name="${project_dir##*/}"
fi
if [ -z "$name" ]; then
  exit 0
fi

bell=""
case "$mode" in
  done)    title="${DONE_GLYPH} ${name}"; bell=$'\a' ;;
  blocked) title="${BLOCKED_GLYPH} ${name}"; bell=$'\a' ;;
  working) title="${WORKING_GLYPH} ${name}" ;;
  clear)   title="${name}" ;;
  *)       exit 0 ;;
esac

printf '\033]2;%s\033\\%s' "$title" "$bell" > "$device"
exit 0
