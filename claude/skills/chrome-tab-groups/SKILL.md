---
name: chrome-tab-groups
description: Open pages in Camen's Chrome in a named tab group - creating a group, adding tabs to one, renaming or recolouring it, and listing what groups exist. Use whenever a session puts tabs in front of him in Chrome, or he asks for tabs grouped or a group named, in any words.
---

# Chrome tab groups

## Opening the tabs

With Claude in Chrome connected (the session was started with `claude --chrome`): `tabs_context_mcp {createIfEmpty: true}` makes the session's group with one empty tab; navigate it, and `tabs_create_mcp` for the rest, in one `browser_batch`. A session gets one group from the extension: later tabs go into it, never a second one. Closing a group's last tab removes the group, and the next `tabs_context_mcp` creates it again. Set a tab's `document.title` through `javascript_tool` to label it; a reload loses it.

Without Claude in Chrome: `bash ~/.claude/scripts/chrome-tab-group.sh open <urls>`, into the existing front window, never `open -a`, `-n` or `--new-window`: a new window hides his other review groups behind it (seen 2026-11-12), and every Chrome call steals his focus unless the script hands it back to the app he was in.

Claude in Chrome refuses `file://` urls ("Can't interact with browser-internal or unparseable URLs"), so serve a local page with `python3 -I -m http.server <port> --bind 127.0.0.1` from its folder, in the background, and open it on `127.0.0.1`.

## Naming the group

Claude in Chrome names its group "Claude (MCP)" and has no tool to rename it. The Tab Grouper extension (`chrome/tab-grouper` in dotfiles, loaded unpacked in his Chrome) does it, triggered from the shell once the tabs have loaded:

- **Name the group a tab is in, or group ungrouped tabs:** `bash ~/.claude/scripts/chrome-tab-group.sh match=<url part> "title=<name>"`. A matched tab already in a group renames that group in place, so Claude in Chrome keeps its tabs within reach. Matches in no group get a new group.
- **Add tabs to a named group:** `"group=<current name>" match=<url part>`.
- **Rename a group:** `"group=<current name>" "title=<new name>"`.
- **Colour:** `color=<grey|blue|red|yellow|green|pink|purple|cyan|orange>` on any of these.
- **Title a tab:** `match=<url part> "tabtitle=<title>"`. The title holds through reloads and the page's own title changes until the tab closes. Alone it only titles; with `group`/`title`/`color` it also groups.
- `match` repeats, and matches any tab whose url contains it. Group a review's tabs in one call with every `match` and the `title`, then title each tab: separate `title=` calls on ungrouped tabs make one same-named group per tab (seen 2026-11-12).

It acts silently, and does nothing when nothing matches. Check with `chrome-tab-group.sh list`, one line per group: "<name> (<colour>) - <n> tabs: <tab title>, …". The extension reports through its page's title, so the check needs no Accessibility grant. A group renamed this way keeps its name through later `tabs_context_mcp` calls (checked 2026-11-09).

Unless the caller says otherwise, name the group after this session's Ghostty tab as he sees it: `osascript -e 'tell application "System Events" to get name of every window of process "Ghostty"'` (the front tab's title per window). Not `~/.claude/tab-names/`, which holds only what `tabname` last wrote and misses a title he set in Ghostty himself.

After editing the extension's files, `chrome-tab-group.sh reload=1` reloads it.
