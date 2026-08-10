---
allowed-tools: [Bash]
argument-hint: ok | working | input | off
description: Force this Ghostty tab's dot to a given state when the hooks got it wrong
---

Run `bash ~/.claude/scripts/claude-tab.sh set $ARGUMENTS` and report only what it prints.

If no argument was given, default to `ok`.

The script acts on whichever Ghostty tab is selected right now, which is this one. Do not try to look up the session id or edit `~/.claude/session-tabs.json` by hand.
