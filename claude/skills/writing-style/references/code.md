# Code

All code, everywhere. He is the author; you are drafting for him. The floor carries the compressed version; this is the full standard, and `style-pass` reviews against it.

- **Readable over clever.** Legibility beats performance micro-optimization by default.
- **Never write comments.** Not one. There is no exception — not for a hidden constraint, not for an upstream bug, not for surprising ordering, not "just this once because it's genuinely non-obvious." If you catch yourself reasoning that this particular comment is the rare justified one, that is the rule firing correctly: delete it. Well-named identifiers already explain *what*; the code already shows *how*; anything else he will ask about. If code needs explaining, restructure it or name things better instead. Say the explanation in chat, not in the file.
- **Preserve existing comments.** Don't remove his when editing, even during restructuring. That is *not* a license to add your own.
- **No section-divider comments.** No `# ── Tool definitions ──` block headers. If a file needs visual separators to navigate, split the file.
- **Never use single-letter variable names.** Not for loop indices, not for lambda parameters, not for comprehension variables, not for caught exceptions, not for a "throwaway" one-liner. `index` not `i`, `row` not `r`, `error` not `e`, `neighbor_count` not `k`, `message` not `m`. The only permitted single character is `_` for a value you are deliberately discarding (`first, _ = pair`). No exceptions for brevity, convention, or math notation — if the surrounding code or a library's own examples use single letters, still spell yours out.
- **No abbreviations in variable names.** `markdown_client` not `md`, `postgres_connection` not `conn`. If a name feels too long, something else is wrong (too many parameters, misnamed scope, missing class) — don't shorten to compensate.
- **No added layers.** Fewer abstractions, fewer helpers, fewer indirections. Three similar lines beat a base class. Don't generalize before there's a second case.
- **No `*,` keyword-only marker in function signatures.** Force keyword-style at the call site instead, by always passing kwargs.
- **Use keyword arguments when calling functions.** `foo(content=content, markdown_client=client)` not `foo(content, client)`. Positional is fine for one or two obvious args; past that, name them.
- **Type-hint every parameter,** including external clients. Untyped parameters force readers to grep for callers.
- **Custom colors, not pre-made themes.** Hex notation (`#86c9c0`), not color names or ANSI numbers. Consistent across Ghostty, Starship, and nvim.

Where a project's own documented standards conflict — a repo that requires comments, a team naming convention — the project wins; these carry what is personal.
