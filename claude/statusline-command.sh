#!/usr/bin/env bash
# Claude Code status line — matches Starship/Ghostty palette
# Colors: #86c9c0 (teal), #8a8a8a (muted gray)
#
# Line 1: [model]  branch | ctx%
# Line 2: 5h N% (resets at h:mm AM), 7d N% (resets at Mon DD)

input=$(cat)

model=$(jq -r '.model.display_name'                     <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd'            <<<"$input")
ctx_pct=$(jq -r '.context_window.used_percentage // empty'        <<<"$input")
fivehr_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
fivehr_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty'     <<<"$input")
sevenday_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
sevenday_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty'     <<<"$input")

# ANSI 24-bit color helpers
teal='\033[38;2;134;201;192m'
gray='\033[38;2;138;138;138m'
reset='\033[0m'

# Nerd Font GitHub icon (nf-fa-github, U+F09B)
github_icon=$''

# Git branch (non-blocking — skip any index lock)
branch=""
if git -C "$cwd" rev-parse --git-dir --no-optional-locks &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

fmt_pct() { [ -n "$1" ] && printf "%.0f%%" "$1"; }

# Line 1: [model]  branch | ctx%
line1="${gray}[${model}]${reset}"
[ -n "$branch" ]  && line1="${line1} ${teal}${github_icon} ${branch}${reset}"
ctx_str=$(fmt_pct "$ctx_pct")
[ -n "$ctx_str" ] && line1="${line1} ${gray}| ${ctx_str}${reset}"

# Line 2: 5h and 7d rate-limit usage + reset times (Pro/Max only)
line2=""
if [ -n "$fivehr_pct" ]; then
  reset_t=$(date -r "$fivehr_reset" "+%-I:%M %p" 2>/dev/null)
  line2="${gray}5h: $(fmt_pct "$fivehr_pct") (${reset_t})${reset}"
fi
if [ -n "$sevenday_pct" ]; then
  reset_t=$(date -r "$sevenday_reset" "+%b %d" 2>/dev/null)
  seg="${gray}7d: $(fmt_pct "$sevenday_pct") (${reset_t})${reset}"
  if [ -n "$line2" ]; then
    line2="${line2} ${gray}| ${reset}${seg}"
  else
    line2="$seg"
  fi
fi

printf "%b\n" "$line1"
[ -n "$line2" ] && printf "%b\n" "$line2"
exit 0
