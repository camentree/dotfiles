#!/usr/bin/env bash

file_path="$(jq -r '.tool_input.file_path // empty')"
[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

run() { command -v "$1" >/dev/null 2>&1 && "$@" >/dev/null 2>&1; }

case "$file_path" in
	*.py)
		run ruff check --select I --fix "$file_path"
		run ruff format "$file_path"
		;;
	*.lua)
		run stylua "$file_path"
		;;
	*.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.json | *.jsonc | *.css | *.scss | *.html | *.yaml | *.yml)
		run prettier --write "$file_path"
		;;
esac

exit 0
