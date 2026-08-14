#!/usr/bin/env bash

# PostToolUse(Write|Edit) warning when an edit adds comment lines to work code.
# Warn-only: the no-comments rule is judgment (config repos accept comments),
# so this surfaces the lines and lets the model decide. Python/Scala/TS only.

input="$(cat)"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"

case "$file_path" in
	*.py | *.sql) comment_pattern='^[[:space:]]*(#|--)' ;;
	*.scala | *.sc | *.ts | *.tsx | *.js | *.jsx) comment_pattern='^[[:space:]]*(//|/\*|\*)' ;;
	*) exit 0 ;;
esac

added_lines="$(jq -r 'if .tool_input.content != null then .tool_input.content
	elif .tool_input.edits != null then [.tool_input.edits[].new_string] | join("\n")
	else .tool_input.new_string // "" end' <<<"$input")"
previous_lines="$(jq -r 'if .tool_input.edits != null then [.tool_input.edits[].old_string] | join("\n")
	else .tool_input.old_string // "" end' <<<"$input")"

new_comments="$(comm -23 \
	<(grep -E "$comment_pattern" <<<"$added_lines" | grep -v '^#!' | sort -u) \
	<(grep -E "$comment_pattern" <<<"$previous_lines" | sort -u))"

[ -n "$new_comments" ] || exit 0

jq -n \
	--arg file "$file_path" \
	--arg comments "$new_comments" \
	'{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("This edit to \($file) added comment lines:\n\($comments)\nThe no-comments rule (writing-style references/code.md) likely applies — remove them and say the explanation in chat instead. Leave them only where the repo itself calls for comments.")}}'
