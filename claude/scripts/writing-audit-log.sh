#!/usr/bin/env bash

# The writing-audit trail: one row per artifact the audit rewrote.
#
#   timestamp \t session \t repo \t kind \t edits \t why
#
# Kinds are a closed set so the log stays aggregatable: page, question, pr,
# commit, code. A clean audit writes nothing.
#
# As a PreToolUse(Skill) hook it announces the run without recording anything.
# The skill calls `writing-audit-log.sh record <kind> <edits> <why>` per artifact,
# and `show` renders the history for a human.

log_file="$HOME/.claude/logs/writing-audit.log"
mkdir -p "$(dirname "$log_file")"

if [ "$1" = "show" ]; then
	[ -s "$log_file" ] || { echo "No writing audits have rewritten anything yet."; exit 0; }
	awk \
		-v limit="${2:-20}" \
		-v width="$(tput cols 2>/dev/null || echo 100)" \
		-v teal=$'\033[38;2;134;201;192m' \
		-v grey=$'\033[38;2;138;138;138m' \
		-v off=$'\033[0m' '
		BEGIN { FS = "\t"; indent = "              " }

		function wrap(text, available,    words, total, index_, line, out) {
			total = split(text, words, " ")
			for (index_ = 1; index_ <= total; index_++) {
				if (line == "") line = words[index_]
				else if (length(line) + 1 + length(words[index_]) <= available) line = line " " words[index_]
				else { out = out line "\n" indent; line = words[index_] }
			}
			return out line
		}

		{
			session = $2
			if (!(session in seen)) { seen[session] = 1; order[++audits] = session; started[session] = $1; repo[session] = $3 }
			findings[session] = findings[session] $4 "\t" $5 "\t" $6 "\n"
		}

		END {
			available = width - length(indent) - 1
			if (available < 30) available = 30
			for (position = (audits > limit ? audits - limit + 1 : 1); position <= audits; position++) {
				session = order[position]
				printf "\n%s%s%s   %s%s%s   %s%s%s\n", grey, started[session], off, teal, repo[session], off, grey, substr(session, 1, 8), off
				total = split(findings[session], rows, "\n")
				for (index_ = 1; index_ < total; index_++) {
					split(rows[index_], parts, "\t")
					printf "   %-8s %s×%s%s  %s\n", parts[1], grey, parts[2], off, wrap(parts[3], available)
				}
			}
			print ""
		}
	' "$log_file"
	exit 0
fi

if [ "$1" = "record" ]; then
	kind="$2"
	case "$kind" in
		page | question | pr | commit | code) ;;
		*)
			echo "unknown kind: $kind (expected page, question, pr, commit, code)" >&2
			exit 1
			;;
	esac
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
		"$(date '+%Y-%m-%d %H:%M')" \
		"${CLAUDE_CODE_SESSION_ID:-unknown}" \
		"$(basename "$PWD")" \
		"$kind" \
		"${3:?edits count required}" \
		"${4:?reason required}" >>"$log_file"
	exit 0
fi

[ "$(jq -r '.tool_input.skill // empty')" = "writing-audit" ] || exit 0

rewrite_count=0
[ -f "$log_file" ] && rewrite_count="$(wc -l <"$log_file" | tr -d ' ')"

jq -n \
	--arg message "writing-audit running — ${rewrite_count} rewrites logged before this one" \
	'{hookSpecificOutput: {hookEventName: "PreToolUse", systemMessage: $message}}'
