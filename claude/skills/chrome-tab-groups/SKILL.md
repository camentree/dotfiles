---
name: chrome-tab-groups
description: Open pages in Camen's Chrome in a named tab group - creating a group, adding tabs to one, renaming or recolouring it, and listing what groups exist. Use whenever a session puts tabs in front of him in Chrome, or he asks for tabs grouped or a group named, in any words.
---

# Chrome tab groups

## Opening the tabs

With Claude in Chrome connected (the session was started with `claude --chrome`): `tabs_context_mcp {createIfEmpty: true}` makes the session's group with one empty tab; navigate it, and `tabs_create_mcp` for the rest, in one `browser_batch`. A session gets one group from the extension: later tabs go into it, never a second one. Closing a group's last tab removes the group, and the next `tabs_context_mcp` creates it again. Set a tab's `document.title` through `javascript_tool` to label it; a reload loses it.

Without Claude in Chrome: `bash ~/.claude/scripts/chrome-tab-group.sh open <urls>`, into the existing front window, never `open -a`, `-n` or `--new-window`: a new window hides his other review groups behind it (seen 2026-11-12), and every Chrome call steals his focus unless the script hands it back to the app he was in. `open` drives Chrome through AppleScript, which lands in a chrome-devtools automation Chrome when one is running (`ps` shows `--enable-automation` / `--allow-pre-commit-input`), so its tabs never reach his groups: then pass the urls to `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --profile-directory=Default <urls> &`, which hands them to his running Chrome as tabs (seen 2026-11-15).

Claude in Chrome refuses `file://` urls ("Can't interact with browser-internal or unparseable URLs"), so serve a local page with `python3 -I -m http.server <port> --bind 127.0.0.1` from its folder, in the background, and open it on `127.0.0.1`.

## Naming the group

Claude in Chrome names its group "Claude (MCP)" and has no tool to rename it. The Tab Grouper extension (`chrome/tab-grouper` in dotfiles, loaded unpacked in his Chrome) does it, triggered from the shell once the tabs have loaded:

- **Name the group a tab is in, or group ungrouped tabs:** `bash ~/.claude/scripts/chrome-tab-group.sh match=<url part> "title=<name>"`. A matched tab already in a group renames that group in place, so Claude in Chrome keeps its tabs within reach. Matches in no group get a new group. `tabtitle=` applies to every match in the call, so set titles one tab per call after the grouping call.
- **Add tabs to a named group:** `"group=<current name>" match=<url part>`.
- **Rename a group:** `"group=<current name>" "title=<new name>"`.
- **Colour:** `color=<grey|blue|red|yellow|green|pink|purple|cyan|orange>` on any of these.
- **Title a tab:** `match=<url part> "tabtitle=<title>"`. The title holds through reloads and the page's own title changes until the tab closes. Alone it only titles; with `group`/`title`/`color` it also groups.
- A `match` that another review's tab also contains (a Linear ticket two pull requests share) renames that review's group: open a shared url with a query only this review uses (`?review=<feature>`) and match on that (seen 2026-11-13).
- `match` repeats, and matches any tab whose url contains it. Group a review's tabs in one call with every `match` and the `title`, then title each tab: separate `title=` calls on ungrouped tabs make one same-named group per tab (seen 2026-11-12).

It acts silently, and does nothing when nothing matches. Check with `chrome-tab-group.sh list`, one line per group: "<name> (<colour>) - <n> tabs: <tab title>, …". The script talks to the extension through its native messaging host (`chrome/tab-grouper/native-host.py`, listening on `~/.cache/tab-grouper.sock`), so no tab opens; with Chrome closed or the extension unloaded it says "no answer from the Tab Grouper extension" and exits 1. A group renamed this way keeps its name through later `tabs_context_mcp` calls (checked 2026-11-09).

Unless the caller says otherwise, name the group after this session's Ghostty tab as he sees it: `osascript -e 'tell application "System Events" to get name of every window of process "Ghostty"'` (the front tab's title per window). Not `~/.claude/tab-names/`, which holds only what `tabname` last wrote and misses a title he set in Ghostty himself.

After editing the extension's files, `chrome-tab-group.sh reload=1` reloads it.

## Safari

Safari's scripting dictionary has no tab groups, but UI scripting makes one (worked 2026-11-18, Safari 26.5): `click menu item "New Empty Tab Group" of menu "File" of menu bar 1` in System Events, then `set URL of current tab of front window` and `make new tab at end of tabs` for the rest. Typing the name and pressing Return leaves it "Untitled"; find the sidebar row (`rows of outline 1 of scroll area 1 of splitter group 1` of the window) whose `text field 1 of UI element 1 of UI element 1` value starts with "Untitled" (the row index varies; row 3 was a section header), `set focused` of it to true, set its `value`, then `perform action "AXConfirm"` (without focus the value doesn't stick). Never `make new document` or otherwise open a window for a group: tab groups are shared by every Safari window, and he does not want a new one each time (2026-11-24). Make the group in the window he already has (only with no window at all, make one), read `id of front window` in the same `osascript` call straight after the menu click, and address the window by that id from then on, not `front window`: another session's review grabbed the front window mid-script and a group lost its tabs (2026-11-18). His window switches to the new group, which is what he pressed review for; so make the group only when every page is ready and open all its tabs in that one call. One session at a time: `mkdir /tmp/safari-tab-group.lock` before, `rmdir` after, waiting while it exists. The window's name reads `<group> — <page title>` once it took. Closing tabs inside a `repeat with t in tabs` loop skips or errors as the list shrinks: close one match per `osascript` call (`close t` then `exit repeat`) and repeat the call. Making groups back to back, the rename can miss and leave a window named `Untitled — …` (the second of three did, 2026-11-23): check the window's name after each, and rename that window in a call of its own before making the next. A missed rename can also leave a garbled name (`e`, seen 2026-11-24), so list the sidebar's names first and rename the row that is neither `Untitled` nor an existing group (the new group's row is the only one whose `UI element 1 of UI element 1` holds a `text field`, the rest hold `static text`, and its value can read as missing, so find it by that, not by "Untitled": a `starts with` loop missed it and left `ks`, 2026-11-25); in AppleScript, `result` is reserved, so name the variable otherwise.

Only the group's creation needs Safari frontmost, and it tears his focus (2026-11-19), so keep it to one `osascript` call that hands focus back: first save `name of first process whose frontmost is true` (System Events) and the name of Safari's front window, then click the menu item, name the group and open its tabs, then `activate application "<saved app>"` and, when the saved app was Safari, `set index of window "<saved window>" to 1`. Every later step (adding tabs, setting a URL, `do JavaScript`, closing tabs) goes through Safari's dictionary to the group's window by name, never `activate` or System Events: those run in the background.
