# User-Level Instructions

## About me

- Software developer. Primarily Python these days; relearning Scala; strong SQL background.
- Also works in TypeScript/React.
- Strong VSCode background; still building muscle memory in neovim.
- Cares about clean shell aesthetics and consistent visual identity across tools (Ghostty, Starship, nvim).
- Anxious with too much going on at once — values minimalism and clean, legible surfaces.

## How to write and how to code

The `writing-for-humans` output style. Always on, no invocation. Per-surface detail is in the `writing-style` skill's references.

## Permissions

I'm learning permission management. If you're asking for a permission and I hit "accept all," and the rule seems generically safe/reasonable (not just for this one task), ask whether I'd like to add it to my global permissions.

## About this machine

This machine is managed declaratively by Nix (nix-darwin + home-manager). Source of truth lives at `~/Projects/dotfiles/`.

- **Most files in `$HOME` are symlinks** into `/nix/store/` — effectively read-only. Don't edit them in place. Edit the source in `~/Projects/dotfiles/` and rebuild.
- **Packages, macOS defaults, dotfiles** — all live in `~/Projects/dotfiles/`. See that repo's README for the layout.
- **To apply config changes**, run `nix-rebuild <machine-name>` (e.g. `nix-rebuild mac-arm-work`). It's a shell function that runs `darwin-rebuild switch --flake ~/Projects/dotfiles#<machine-name>`.
- **To inspect / revert**, `nix-ls` lists generations; `sudo darwin-rebuild switch --rollback` reverts.
- **Machine names** live in `~/Projects/dotfiles/flake.nix` under `darwinConfigurations`.

If asked to change a setting (git config, a package, a macOS default, a keybinding, etc.), edit the dotfiles repo — don't run imperative commands like `brew install` or `defaults write` that will get overwritten on the next rebuild.

## Shell conventions

- **Research** — prefer `WebFetch` / `WebSearch` directly over spawning a research agent that runs its own curl/python.
- Always use explicit HTTP method flags with curl (`curl -X GET`, `curl -X POST`) so permission rules can distinguish read-only from mutating requests.
- Prefer `WebFetch` over `curl | jq` / `curl | python` pipelines for read-only HTTP GETs — it parses JSON/HTML and avoids extra permission prompts.
- When you produce content whose main purpose is for me to paste elsewhere — an email, a Slack/message draft, a commit message, a standalone snippet — also pipe a clean copy to `pbcopy` and tell me it's on the clipboard. Skip this for ordinary explanatory output; it's for the "here's the thing, go paste it" cases.
- **Any command you want me to run goes on the clipboard too.** Same `pbcopy` treatment, every time, without being asked. If there are several, copy the one I'm most likely to run next and say which.

## Secrets

Secrets live in 1Password, reached through the `op` CLI. This comes up rarely — assume a command needs no credentials unless it fails for lack of one, or I've said it does. Don't wrap things in `op run` speculatively.

- `op run --env-file=<file> -- <command>` resolves `op://` references into the command's environment and redacts the values from its output. Reach for this instead of asking me to paste a secret.
- Never `op read` or `op item get` a secret — that prints it into the transcript, where it persists.
- `op://Vault/Item/field` references are pointers, not secrets. Safe to commit; safe to put in a tracked `.env` or in `home/zshenv`. The values they point at never touch disk.

## CloudWatch Logs Insights

CloudWatch Logs Insights bills on **bytes scanned across the time range**, not on rows matched — a tighter `filter` does *not* reduce cost, only a shorter time range does. The prod app log group (`/aws/eks/prod/application`, us-west-2) is huge: a single 7-day query scanned ~1.7 TB and cost ~$8.50.

- **Always scope queries to a small time range — under 30 minutes.** Widen only when a narrow window comes up empty, and only one step at a time.
- **Don't fan out queries.** Run as few as possible; each one costs real money. Prefer one well-targeted query over several exploratory ones.
- Before running, ask whether I'd rather run it myself in the console — for anything beyond a quick narrow check, hand me the query string to paste into the UI instead of running it via the CLI.
- Completed query results are retained ~7 days and re-fetchable by `queryId` for free (`aws logs get-query-results`) — reuse a prior result instead of re-running.

## Claude session management

- `claude-move-session <session-id> [target-path]` (in `home/zshrc`) — relocates a session's `.jsonl` and aux dir into the project key for `target-path` (default `$PWD`). Use it when a session's original cwd no longer exists (deleted worktree, moved directory) so it shows up in `claude --resume` from a stable location.
- `wkrm` calls this automatically before removing a worktree, parking any worktree sessions in the main repo's project key — so worktree conversations survive deletion.
- Background: Claude Code stores sessions under `~/.claude/projects/<encoded-cwd>/` (path with `/` → `-`). `--resume` filters by current cwd; there's no flag to disable that filter, so physical relocation is the workaround.
