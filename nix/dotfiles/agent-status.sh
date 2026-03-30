#!/usr/bin/env bash

# agent-status.sh
# Colors tmux window tabs based on Claude Code state.
# Called from status-right in tmux.conf — runs every status-interval (2s).
# Outputs nothing; works via side-effects (set-window-option).
#
# Colors: green=idle, red=needs input, yellow=working
# Sets both window-status-style and window-status-current-style so
# the color applies regardless of which window is active.

SESSION="agents"

tmux has-session -t "$SESSION" 2>/dev/null || exit 0

# Catppuccin colors
thm_bg="#1e1e28"
thm_red="#e38c8f"
thm_green="#b1e3ad"
thm_yellow="#ebddaa"

tmux list-windows -t "$SESSION" -F '#{window_index}' | while read -r win_idx; do
  # Check if pane 1 is running claude
  pane_cmd=$(tmux display-message -t "${SESSION}:${win_idx}" -p '#{pane_current_command}' 2>/dev/null)

  is_claude=false
  case "$pane_cmd" in
    claude|node) is_claude=true ;;
    [0-9]*)      is_claude=true ;;
  esac

  if ! $is_claude; then
    bg="$thm_green"
  else
    # Get last non-empty line from claude pane
    last_line=$(tmux capture-pane -t "${SESSION}:${win_idx}" -p -S -50 2>/dev/null | grep -v '^$' | tail -1)

    case "$last_line" in
      *"Esc to cancel"*)  bg="$thm_red" ;;
      *"esc to interrupt"*) bg="$thm_yellow" ;;
      *)                    bg="$thm_green" ;;
    esac
  fi

  style="fg=${thm_bg},bg=${bg}"
  tmux set-window-option -t "${SESSION}:${win_idx}" window-status-style "$style" 2>/dev/null
  tmux set-window-option -t "${SESSION}:${win_idx}" window-status-current-style "$style" 2>/dev/null
done
