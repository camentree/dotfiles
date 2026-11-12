async function findGroupByTitle(title) {
  const groups = await chrome.tabGroups.query({});
  return groups.find((group) => group.title === title);
}

async function applyGroup({ matches, group, title, color }) {
  const tabs = await chrome.tabs.query({});
  const matching = tabs.filter((tab) => {
    const url = tab.url || tab.pendingUrl || "";
    if (url.startsWith("chrome-extension://")) return false;
    return matches.some((match) => url.includes(match));
  });

  let groupId;
  if (group) {
    const existing = await findGroupByTitle(group);
    if (existing) groupId = existing.id;
  }
  if (groupId === undefined) {
    const alreadyGrouped = matching.find((tab) => tab.groupId !== chrome.tabGroups.TAB_GROUP_ID_NONE);
    if (alreadyGrouped) groupId = alreadyGrouped.groupId;
  }

  const toMove = matching.filter((tab) => tab.groupId !== groupId).map((tab) => tab.id);
  if (toMove.length > 0) {
    groupId = await chrome.tabs.group(groupId === undefined ? { tabIds: toMove } : { groupId, tabIds: toMove });
  }
  if (groupId === undefined) return;

  const update = {};
  if (title || group) update.title = title || group;
  if (color) update.color = color;
  if (Object.keys(update).length > 0) await chrome.tabGroups.update(groupId, update);
}

chrome.tabs.onUpdated.addListener(async (tabId, change, tab) => {
  if (change.status !== "complete") return;
  const url = tab.url || "";
  if (!url.startsWith(chrome.runtime.getURL("group.html"))) return;
  const parameters = new URL(url).searchParams;
  if (parameters.has("list")) return;
  await chrome.tabs.remove(tabId);
  if (parameters.has("reload")) {
    chrome.runtime.reload();
    return;
  }
  await applyGroup({
    matches: parameters.getAll("match").filter(Boolean),
    group: parameters.get("group") || "",
    title: parameters.get("title") || "",
    color: parameters.get("color") || "",
  });
});
