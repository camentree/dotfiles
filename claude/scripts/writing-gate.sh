#!/usr/bin/env bash

# The writing-audit gate. One script, three hook events, all reading stdin JSON:
#
#   PostToolUse(Write|Edit)  prose was written -> add its size to the tally
#   PostToolUse(Skill)       writing-audit was invoked -> stamp "audited"
#   Stop                     enough prose, none audited since -> refuse the stop
#
# Gates on kind and size only, never location: prose means .html or .md files,
# and the gate arms once a session has written 4000+ characters of it.
# State is one directory per session under ~/.claude/tmp/writing-gate/.
# `touch <state>/skip` lets a session end unaudited on purpose.
# After 3 refusals the gate gives up and lets the stop through.

threshold=4000

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
					*.html | *.md) ;;
					*) exit 0 ;;
				esac
				added="$(jq -r 'if .tool_input.content != null then .tool_input.content
					elif .tool_input.edits != null then [.tool_input.edits[].new_string] | join("")
					else .tool_input.new_string // "" end | length' <<<"$input")"
				total="$(cat "$state/prose_chars" 2>/dev/null || echo 0)"
				echo "$((total + added))" >"$state/prose_chars"
				date +%s >"$state/dirty"
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

		total="$(cat "$state/prose_chars" 2>/dev/null || echo 0)"
		[ "$total" -ge "$threshold" ] || exit 0

		dirty_at="$(cat "$state/dirty")"
		audited_at="$(cat "$state/audited" 2>/dev/null || echo 0)"
		[ "$audited_at" -ge "$dirty_at" ] && exit 0

		blocks="$(cat "$state/blocks" 2>/dev/null || echo 0)"
		if [ "$blocks" -ge 3 ]; then
			exit 0
		fi
		echo "$((blocks + 1))" >"$state/blocks"

		jq -n \
			--arg reason "This session wrote ${total} characters of prose (HTML or markdown) and the writing audit has not run since. Invoke the writing-audit skill on what was written (it dispatches the cold-reader agent), then stop. If ending unaudited is deliberate, run: touch $state/skip" \
			'{decision: "block", reason: $reason}'
		exit 0
		;;
esac

exit 0
