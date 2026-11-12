// The list result goes in the tab title so the shell can read it through
// Chrome's AppleScript, which needs only Automation. Reading the tab strip
// through System Events needed Accessibility for the calling shell.
async function listGroups() {
  const groups = await chrome.tabGroups.query({});
  const tabs = await chrome.tabs.query({});
  const result = groups.map((group) => ({
    title: group.title,
    color: group.color,
    tabs: tabs.filter((tab) => tab.groupId === group.id).map((tab) => (tab.title || tab.url || "").slice(0, 60)),
  }));
  document.title = "groups:" + JSON.stringify(result);
}

if (new URLSearchParams(location.search).has("list")) listGroups();
