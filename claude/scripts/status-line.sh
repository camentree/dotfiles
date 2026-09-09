#!/usr/bin/env bash
input=$(cat)

model=$(jq -r '.model.display_name | sub(" *\\(.*\\)$"; "")' <<<"$input")
effort=$(jq -r '.effort.level // empty'                 <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd'            <<<"$input")
ctx_pct=$(jq -r '.context_window.used_percentage // empty'        <<<"$input")
fivehr_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
fivehr_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty'     <<<"$input")
sevenday_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
sevenday_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty'     <<<"$input")

teal='\033[38;2;134;201;192m'
gray='\033[38;2;138;138;138m'
reset='\033[0m'

github_icon=$''

branch=""
if git -C "$cwd" rev-parse --git-dir --no-optional-locks &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

fmt_pct() { [ -n "$1" ] && printf "%.0f%%" "$1"; }

# Line 1: branch
line1=""
[ -n "$branch" ] && line1="${teal}${github_icon} ${branch}${reset}"

# Line 2: model (effort) | ctx%
[ -n "$effort" ] && model="${model} (${effort})"
line2="${gray}${model}${reset}"
ctx_str=$(fmt_pct "$ctx_pct")
[ -n "$ctx_str" ] && line2="${line2} ${gray}| ${ctx_str}${reset}"

# Line 3: 5h and 7d rate-limit usage + reset times
line3=""
if [ -n "$fivehr_pct" ]; then
  reset_t=$(date -r "$fivehr_reset" "+%-I:%M %p" 2>/dev/null)
  line3="${gray}5h: $(fmt_pct "$fivehr_pct") (${reset_t})${reset}"
fi
if [ -n "$sevenday_pct" ]; then
  reset_t=$(date -r "$sevenday_reset" "+%b %d" 2>/dev/null)
  seg="${gray}7d: $(fmt_pct "$sevenday_pct") (${reset_t})${reset}"
  if [ -n "$line3" ]; then
    line3="${line3} ${gray}| ${reset}${seg}"
  else
    line3="$seg"
  fi
fi

[ -n "$line1" ] && printf "%b\n" "$line1"
printf "%b\n" "$line2"
[ -n "$line3" ] && printf "%b\n" "$line3"
exit 0
