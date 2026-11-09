async function groupMatching({ title, color, match }) {
  const tabs = await chrome.tabs.query({});
  const matching = tabs.filter(
    (tab) =>
      (tab.url || tab.pendingUrl || "").includes(match) &&
      !(tab.url || "").startsWith("chrome-extension://"),
  );
  if (matching.length === 0) return;
  const groupId = await chrome.tabs.group({ tabIds: matching.map((tab) => tab.id) });
  await chrome.tabGroups.update(groupId, { title, color });
}

chrome.tabs.onUpdated.addListener(async (tabId, change, tab) => {
  if (change.status !== "complete") return;
  const url = tab.url || "";
  if (!url.startsWith(chrome.runtime.getURL("group.html"))) return;
  const parameters = new URL(url).searchParams;
  const match = parameters.get("match") || "";
  if (match) {
    await groupMatching({
      title: parameters.get("title") || "",
      color: parameters.get("color") || "grey",
      match,
    });
  }
  await chrome.tabs.remove(tabId);
});
