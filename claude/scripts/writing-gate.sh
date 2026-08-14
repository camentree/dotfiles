#!/usr/bin/env bash

# The writing-audit gate. One script, three hook events, all reading stdin JSON:
#
#   PostToolUse(Write|Edit)  a notes page was written -> stamp "dirty"
#   PostToolUse(Skill)       writing-audit was invoked -> stamp "audited"
#   Stop                     dirty newer than audited -> refuse the stop
#
# State is one directory per session under ~/.claude/tmp/writing-gate/.
# `touch <state>/skip` lets a session end with an unfinished page on purpose.
# After 3 refusals the gate gives up and lets the stop through.

input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<<"$input")"
session="$(jq -r '.session_id // "unknown"' <<<"$input")"
state="$HOME/.claude/tmp/writing-gate/$session"
mkdir -p "$state"

case "$event" in
	PostToolUse)
		tool="$(jq -r '.tool_name // empty' <<<"$input")"
		case "$tool" in
			Write | Edit | MultiEdit)
				file_path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
				case "$file_path" in
					"$HOME/Documents/notes/"*) date +%s >"$state/dirty" ;;
				esac
				;;
			Skill)
				skill="$(jq -r '.tool_input.skill // empty' <<<"$input")"
				[ "$skill" = "writing-audit" ] && date +%s >"$state/audited"
				;;
		esac
		exit 0
		;;
	Stop)
		[ -f "$state/dirty" ] || exit 0
		[ -f "$state/skip" ] && exit 0

		dirty_at="$(cat "$state/dirty")"
		audited_at="$(cat "$state/audited" 2>/dev/null || echo 0)"
		[ "$audited_at" -ge "$dirty_at" ] && exit 0

		blocks="$(cat "$state/blocks" 2>/dev/null || echo 0)"
		if [ "$blocks" -ge 3 ]; then
			exit 0
		fi
		echo "$((blocks + 1))" >"$state/blocks"

		jq -n \
			--arg reason "A page under ~/Documents/notes/ was written this session and the writing audit has not run since. Invoke the writing-audit skill on it (it dispatches the cold-reader agent), then stop. If ending with an unaudited page is deliberate, run: touch $state/skip" \
			'{decision: "block", reason: $reason}'
		exit 0
		;;
esac

exit 0
