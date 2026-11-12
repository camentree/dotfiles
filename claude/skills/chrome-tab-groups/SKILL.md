---
name: chrome-tab-groups
description: Open pages in Camen's Chrome in a named tab group - creating a group, adding tabs to one, renaming or recolouring it, and listing what groups exist. Use whenever a session puts tabs in front of him in Chrome, or he asks for tabs grouped or a group named, in any words.
---

# Chrome tab groups

## Opening the tabs

With Claude in Chrome connected (the session was started with `claude --chrome`): `tabs_context_mcp {createIfEmpty: true}` makes the session's group with one empty tab; navigate it, and `tabs_create_mcp` for the rest, in one `browser_batch`. A session gets one group from the extension: later tabs go into it, never a second one. Closing a group's last tab removes the group, and the next `tabs_context_mcp` creates it again. Set a tab's `document.title` through `javascript_tool` to label it; a reload loses it.

Without Claude in Chrome: `open -na "Google Chrome" --args --new-window <urls>`.

Claude in Chrome refuses `file://` urls ("Can't interact with browser-internal or unparseable URLs"), so serve a local page with `python3 -I -m http.server <port> --bind 127.0.0.1` from its folder, in the background, and open it on `127.0.0.1`.

## Naming the group

Claude in Chrome names its group "Claude (MCP)" and has no tool to rename it. The Tab Grouper extension (`chrome/tab-grouper` in dotfiles, loaded unpacked in his Chrome) does it, triggered from the shell once the tabs have loaded:

- **Name the group a tab is in, or group ungrouped tabs:** `bash ~/.claude/scripts/chrome-tab-group.sh match=<url part> "title=<name>"`. A matched tab already in a group renames that group in place, so Claude in Chrome keeps its tabs within reach. Matches in no group get a new group.
- **Add tabs to a named group:** `"group=<current name>" match=<url part>`.
- **Rename a group:** `"group=<current name>" "title=<new name>"`.
- **Colour:** `color=<grey|blue|red|yellow|green|pink|purple|cyan|orange>` on any of these.
- `match` repeats, and matches any tab whose url contains it.

It acts silently, and does nothing when nothing matches. Check with `chrome-tab-group.sh list`, one line per group: "<name> (<colour>) - <n> tabs: <tab title>, …". The extension reports through its page's title, so the check needs no Accessibility grant. A group renamed this way keeps its name through later `tabs_context_mcp` calls (checked 2026-11-09).

Unless the caller says otherwise, name the group after this session's Ghostty tab as he sees it: `osascript -e 'tell application "System Events" to get name of every window of process "Ghostty"'` (the front tab's title per window). Not `~/.claude/tab-names/`, which holds only what `tabname` last wrote and misses a title he set in Ghostty himself.

After editing the extension's files, `chrome-tab-group.sh reload=1` reloads it.
