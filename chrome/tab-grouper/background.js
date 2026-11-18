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
      pinTitle(tab.id, tabTitle);
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

async function listGroups() {
  const groups = await chrome.tabGroups.query({});
  const tabs = await chrome.tabs.query({});
  return groups.map((group) => ({
    title: group.title,
    color: group.color,
    tabs: tabs.filter((tab) => tab.groupId === group.id).map((tab) => (tab.title || tab.url || "").slice(0, 60)),
  }));
}

async function handleRequest(port, { id, action, ...request }) {
  try {
    if (action === "list") {
      port.postMessage({ id, ok: true, result: await listGroups() });
    } else if (action === "group") {
      await applyGroup(request);
      port.postMessage({ id, ok: true });
    } else if (action === "reload") {
      port.postMessage({ id, ok: true });
      setTimeout(() => chrome.runtime.reload(), 100);
    } else {
      port.postMessage({ id, ok: false, error: `unknown action: ${action}` });
    }
  } catch (error) {
    port.postMessage({ id, ok: false, error: String(error) });
  }
}

let hostPort = null;

function connectHost() {
  if (hostPort) return;
  hostPort = chrome.runtime.connectNative("com.camen.tab_grouper");
  hostPort.onMessage.addListener((message) => handleRequest(hostPort, message));
  hostPort.onDisconnect.addListener(() => {
    hostPort = null;
    setTimeout(connectHost, 5000);
  });
}

chrome.runtime.onStartup.addListener(connectHost);
chrome.runtime.onInstalled.addListener(connectHost);
connectHost();

chrome.tabs.onUpdated.addListener(async (tabId, change) => {
  if (change.status !== "complete") return;
  const stored = await chrome.storage.session.get(String(tabId));
  const tabTitle = stored[String(tabId)];
  if (tabTitle) await pinTitle(tabId, tabTitle);
});

chrome.tabs.onRemoved.addListener((tabId) => {
  chrome.storage.session.remove(String(tabId));
});
