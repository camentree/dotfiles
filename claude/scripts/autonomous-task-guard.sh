#!/usr/bin/env bash
budget_tokens="${CLAUDE_SESSION_BUDGET_TOKENS:-}"
[ -n "$budget_tokens" ] || exit 0

transcript_path=$(jq -r '.transcript_path' <&0)
subagent_dir="${transcript_path%.jsonl}/subagents"

total_tokens=$(cat "$transcript_path" "$subagent_dir"/*.jsonl 2>/dev/null \
  | jq -s '[.[] | .message.usage? // empty
      | (.input_tokens // 0) + (.output_tokens // 0) + (.cache_creation_input_tokens // 0)]
    | add // 0')

if [ "$total_tokens" -gt "$budget_tokens" ]; then
  echo "Session budget exceeded: ${total_tokens} tokens against ${budget_tokens}. Stop here. Say what is done, what is blocked, and what you would do next, then end the turn." >&2
  exit 2
fi
