#!/usr/bin/env bash
set -uo pipefail

if [ "${1:-}" = "list" ]; then
  osascript -l JavaScript -e "
    const windows = Application('System Events').processes['Google Chrome'].windows
    const groups = []
    function read(element, key) { try { return String(element[key]() || '') } catch (error) { return '' } }
    function walk(element, depth) {
      if (depth > 14) return
      const role = read(element, 'role')
      if (role === 'AXWebArea') return
      if (role === 'AXTabGroup') groups.push(read(element, 'description'))
      let children = []
      try { children = element.uiElements() } catch (error) { return }
      for (const child of children) walk(child, depth + 1)
    }
    for (let index = 0; index < windows.length; index++) walk(windows[index], 0)
    groups.join('\n')"
  exit 0
fi

query=""
for pair in "$@"; do
  key="${pair%%=*}"
  value="${pair#*=}"
  query="${query}&${key}=$(jq -rn --arg value "$value" '$value | @uri')"
done

osascript -e "tell application \"Google Chrome\" to open location \"chrome-extension://jefoichdnlokggnejahekcndonjkdaap/group.html?${query#&}\""
