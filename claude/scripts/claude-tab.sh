#!/usr/bin/env bash
set -uo pipefail

IDLE_GLYPH="🔹"
WORKING_GLYPH="🔸"
NAME_DIR="${HOME}/.claude/tab-names"

find_terminal() {
  local pid=$$
  local depth=0
  local candidate
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ "$depth" -lt 12 ]; do
    candidate="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')"
    if [ -n "$candidate" ] && [ "$candidate" != "??" ]; then
      printf '%s' "$candidate"
      return 0
    fi
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
    depth=$((depth + 1))
  done
  return 1
}

mode="${1:-}"
payload="$(cat)"

if [ -n "${CLAUDE_TAB_TTY:-}" ]; then
  terminal="${CLAUDE_TAB_TTY#/dev/}"
else
  terminal="$(find_terminal)" || exit 0
fi
device="/dev/${terminal}"
if [ ! -w "$device" ]; then
  exit 0
fi

if [ "$mode" = "bell" ]; then
  printf '\a' > "$device"
  exit 0
fi

name_file="${NAME_DIR}/${terminal}"

if [ ! -s "$name_file" ]; then
  working_directory="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
  if [ -n "$working_directory" ]; then
    mkdir -p "$NAME_DIR"
    printf '%s\n' "${working_directory##*/}" > "$name_file"
  fi
fi

name="$(cat "$name_file" 2>/dev/null)"
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
