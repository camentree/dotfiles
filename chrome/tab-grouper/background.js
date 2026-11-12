async function findGroupByTitle(title) {
  const groups = await chrome.tabGroups.query({});
  return groups.find((group) => group.title === title);
}

async function pinTitle(tabId, tabTitle) {
  await chrome.scripting
    .executeScript({
      target: { tabId },
      args: [tabTitle],
      func: (pinnedTitle) => {
        document.title = pinnedTitle;
        if (window.tabGrouperObserver) window.tabGrouperObserver.disconnect();
        window.tabGrouperObserver = new MutationObserver(() => {
          if (document.title !== pinnedTitle) document.title = pinnedTitle;
        });
        window.tabGrouperObserver.observe(document.documentElement, { subtree: true, childList: true, characterData: true });
      },
    })
    .catch(() => {});
}

async function applyGroup({ matches, group, title, color, tabTitle }) {
  const tabs = await chrome.tabs.query({});
  const matching = tabs.filter((tab) => {
    const url = tab.url || tab.pendingUrl || "";
    if (url.startsWith("chrome-extension://")) return false;
    return matches.some((match) => url.includes(match));
  });

  if (tabTitle) {
    for (const tab of matching) {
      await chrome.storage.session.set({ [String(tab.id)]: tabTitle });
      await pinTitle(tab.id, tabTitle);
    }
    if (!group && !title && !color) return;
  }

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
    tabTitle: parameters.get("tabtitle") || "",
  });
});

chrome.tabs.onUpdated.addListener(async (tabId, change) => {
  if (change.status !== "complete") return;
  const stored = await chrome.storage.session.get(String(tabId));
  const tabTitle = stored[String(tabId)];
  if (tabTitle) await pinTitle(tabId, tabTitle);
});

chrome.tabs.onRemoved.addListener((tabId) => {
  chrome.storage.session.remove(String(tabId));
});
