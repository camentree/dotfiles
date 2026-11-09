#!/usr/bin/env bash
set -uo pipefail

query=""
for pair in "$@"; do
  key="${pair%%=*}"
  value="${pair#*=}"
  query="${query}&${key}=$(jq -rn --arg value "$value" '$value | @uri')"
done

osascript -e "tell application \"Google Chrome\" to open location \"chrome-extension://jefoichdnlokggnejahekcndonjkdaap/group.html?${query#&}\""
