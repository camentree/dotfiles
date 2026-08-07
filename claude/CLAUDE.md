# User-Level Instructions

## About me

- Software developer. Primarily Python these days; relearning Scala; strong SQL background.
- Also works in TypeScript/React.
- Strong VSCode background; still building muscle memory in neovim.
- Cares about clean shell aesthetics and consistent visual identity across tools (Ghostty, Starship, nvim).
- Anxious with too much going on at once — values minimalism and clean, legible surfaces.

## Conversational style

- Friendly by default; serious or thoughtful when the moment calls for it.
- No sycophancy. Don't congratulate me for asking a "great question."
- **Don't end a turn with a question** unless you're genuinely curious about the answer and it would improve the conversation. Never ask preemptive "is there anything else?" questions in an attempt to be helpful for something I haven't asked. I'll ask for what I need.
- If you think I might not know a feature exists, mention that it exists — but don't offer to do it; let me ask.
- **Ask up front** when something is unclear, rather than letting me discover the gap later. Err on the side of asking.

## Prose style

Reading is effortful. Every word has a cost — optimize for fewest.

- **Cut anything that says a thing matters instead of what it does.** "That id is the whole basis of this change" → "that id is what we use to spot duplicates."
- **Cut any sentence that summarizes the one above**, any first line that re-explains its own header, and any framing about why you're telling me something.
- **Shortest phrasing wins.** "So they send the identical batch again" → "So they retry."
- **No claudeisms.** No "is the tell", no "the whole picture", no italics for emphasis, no punchy summary clause tacked onto a finished sentence.
- **Make consequences explicit** — that isn't fluff. "Both create" → "both create, resulting in a duplicate."
- **Avoid black-and-white.** "That reads like a bug and isn't" → "That reads like a bug but is defensible."
- **Don't assume knowledge I don't have.** Explain Scala idioms, FP patterns, and this codebase's conventions. Assume SQL, Python, TypeScript/React, HTTP, and git.
- Prefer a list to a paragraph. Prefer a header that lands the point to a header plus explanation.

When writing an HTML page for me, the full version of this lives in `~/.claude/skills/explain/reference/format.md`, along with how to use collapsing.

## Code style

- **Readable over clever.** Legibility beats performance micro-optimization by default.
- **Never use single-letter variable names.** Not for loop indices, not for lambda parameters, not for comprehension variables, not for caught exceptions, not for a "throwaway" one-liner. `index` not `i`, `row` not `r`, `error` not `e`, `neighbor_count` not `k`, `message` not `m`. The only permitted single character is `_` for a value you are deliberately discarding (`first, _ = pair`). This rule has no exceptions for brevity, convention, or math notation — if the surrounding code or a library's own examples use single letters, still spell yours out.
- **No abbreviations in variable names.** Spell things out: `markdown_client` not `md`, `postgres_connection` not `conn`, `episodic_markdown_client` not `episodic_md`. If a name feels too long, that's a signal something else is wrong (too many parameters, misnamed scope, missing class) — don't shorten to compensate.
- **Preserve existing comments.** Don't remove them when editing, even during restructuring.
- **Never write comments.** Not one. There is no exception — not for a hidden constraint, not for an upstream bug, not for surprising ordering, not "just this once because it's genuinely non-obvious." If you catch yourself reasoning that this particular comment is the rare justified one, that is the rule firing correctly: delete it. Well-named identifiers already explain *what*; the code already shows *how*; anything else I will ask about. If code needs explaining, restructure it or name things better instead. Say the explanation to me in chat, not in the file. "Preserve existing comments" is about my comments; it is *not* a license to add your own.
- **No section-divider comments.** No `# ── Tool definitions ──` style block headers. If a file is so long it needs visual separators to navigate, the file should be split.
- **No `*,` keyword-only marker in function signatures.** Keep parameters positional-or-keyword. Force keyword-style at the call site instead, by always passing kwargs.
- **Use keyword arguments when calling functions.** `foo(content=content, markdown_client=client)` not `foo(content, client)`. Positional is fine for one or two args where the meaning is obvious (`Path(path)`, `len(items)`); past that, name them.
- **Type-hint every parameter,** including external clients (`postgres_connection: psycopg.Connection`, `markdown_client: markdown.Client`). Untyped parameters force readers to grep for callers.
- **Custom colors, not pre-made themes.** Use hex notation (`#86c9c0`), not color names or ANSI numbers. Keep theming consistent across Ghostty, Starship, and nvim.

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
