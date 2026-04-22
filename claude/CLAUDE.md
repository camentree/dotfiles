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

## Code style

- **Readable over clever.** No single-letter variable names. Legibility beats performance micro-optimization by default.
- **Preserve existing comments.** Don't remove them when editing, even during restructuring.
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
