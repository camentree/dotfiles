#!/usr/bin/env bash

# Agent workflow: worktrees + tmux windows (one window per agent)
# Source this file: source ~/agent-windows.sh
# Then use: agent <branch> [subdir], agent-rm <branch>, agent-ls

AGENT_SESSION="agents"

agent() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repo"; return 1; }

  local branch="$1"
  local subdir="$2"  # optional subdirectory to cd into (e.g. "loquat")
  [ -z "$branch" ] && { echo "Usage: agent <branch-name> [subdir]"; return 1; }

  local repo_name=$(basename "$git_root")
  local agent_dir="$(dirname "$git_root")/${repo_name}-agents"
  local worktree_path="${agent_dir}/${branch}"
  local claude_dir="$worktree_path"
  [ -n "$subdir" ] && claude_dir="${worktree_path}/${subdir}"

  # Create worktree
  mkdir -p "$agent_dir"
  if [ -d "$worktree_path" ]; then
    echo "Worktree already exists: $worktree_path"
  else
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
      git worktree add "$worktree_path" "$branch" || return 1
    else
      git worktree add "$worktree_path" -b "$branch" || return 1
    fi
  fi

  # Create or add to tmux session as a new window
  if ! tmux has-session -t "$AGENT_SESSION" 2>/dev/null; then
    tmux new-session -d -s "$AGENT_SESSION" -n "$branch" -c "$claude_dir"
  else
    tmux new-window -t "$AGENT_SESSION" -n "$branch" -c "$claude_dir"
  fi

  # Launch claude in the single pane
  tmux send-keys -t "${AGENT_SESSION}:${branch}" 'claude' Enter

  echo "Agent ready: $branch"
  echo "  Worktree: $worktree_path"
  [ -n "$subdir" ] && echo "  Claude dir: $claude_dir"

  # Auto-attach if not already in tmux
  if [ -z "$TMUX" ]; then
    tmux attach -t "$AGENT_SESSION"
  fi
}

agent-rm() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repo"; return 1; }

  local branch="$1"
  [ -z "$branch" ] && { echo "Usage: agent-rm <branch-name>"; return 1; }

  local repo_name=$(basename "$git_root")
  local worktree_path="$(dirname "$git_root")/${repo_name}-agents/${branch}"

  # Kill the window named after this branch
  tmux kill-window -t "${AGENT_SESSION}:${branch}" 2>/dev/null

  # Remove worktree
  if [ -d "$worktree_path" ]; then
    git worktree remove "$worktree_path" --force 2>/dev/null
    echo "Removed: $branch"
  else
    echo "No worktree found for '$branch'"
  fi
}

agent-ls() {
  echo "=== Worktrees ==="
  git worktree list 2>/dev/null || echo "Not in a git repo"
  echo ""
  echo "=== Agent Windows ==="
  tmux list-windows -t "$AGENT_SESSION" -F '  #{window_name} (#{window_index}) #{pane_current_command}' 2>/dev/null || echo "No agent session"
}
