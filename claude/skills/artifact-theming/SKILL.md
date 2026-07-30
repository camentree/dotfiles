---
name: artifact-theming
description: Theme and verify published Claude artifacts. Use when writing an artifact with custom colors or dark mode, and whenever a published artifact renders wrong — mixed light/dark, unreadable text on coloured cards, an unexpected cream background, or mojibake. The artifact frame injects its own body background and text colour that silently beat page-level rules, and file:// previews cannot reproduce any of it.
---

# Artifact theming

A published artifact is not a standalone page. It is wrapped in a frame that injects its own
stylesheet, and that stylesheet fights yours in one specific, non-obvious way.

## What the frame injects

Verified by fetching a live artifact URL:

```html
<meta charset=utf8>
<style>
  :root { color-scheme: light }
  body  { margin:0; padding:0; font:14px -apple-system,...;
          background:#faf9f5; color:#141413 }
  img   { max-width:100% }
</style>
```

The frame runtime also sets `data-theme` on `documentElement` and an inline `style.colorScheme`
when the viewer has an explicit theme.

## The failure mode

`body { color: #141413 }` is a **closer ancestor than `html`**. So a page that does this:

```css
html { background: var(--ground); color: var(--ink); }   /* loses */
```

has its text colour overridden for every descendant, while its *component* backgrounds still come
from its own tokens. If those tokens resolve dark (via `prefers-color-scheme`) you get dark cards
with the frame's dark text on them — unreadable — sitting on the frame's cream `#faf9f5` ground.
Half your theme, half theirs.

The symptom looks like a broken media query. It isn't. Token resolution is fine; the text colour
never came from your tokens at all.

## Rules

**Own `color` and `background` below `html`.** This is the essential fix, independent of whether
the page is single- or dual-theme:

```css
html, body { background: var(--ground) !important; color: var(--ink) !important; }
.shell     { background: var(--ground); color: var(--ink); }  /* outermost content wrapper */
```

The wrapper rule matters as much as the `!important` one: inheritance resolves from the nearest
ancestor that sets a value, so a wrapper that restates `color` makes every descendant immune to
whatever `body` says.

**Default to one committed palette.** Declare `color-scheme: dark` (or `light`), define tokens once,
and ship no `@media (prefers-color-scheme)` and no `[data-theme]` blocks. This removes the variable
that produced the mix. Only build dual-theme when the user asks for it.

**If dual-theme is required**, drive it from `:root[data-theme="dark"]` / `:root[data-theme="light"]`
— the frame does set that attribute — and still apply the body/wrapper rule above. Verify all four
combinations (OS preference each way × explicit toggle each way), and check that **every** token is
redefined in **every** block. A block missing two or three tokens yields a partial theme that only
shows up on the components using them.

## Verifying

**`file://` cannot reproduce any of this.** There is no frame, no injected stylesheet, and mermaid
does not render. A local screenshot proves nothing about the published page. Do not report an
artifact as verified on the strength of one.

To actually check a published artifact, `WebFetch` its URL. That returns the full served HTML
including the injected frame CSS, which is how the rules above were established. Useful greps once
fetched: `color-scheme`, `prefers-color-scheme`, `data-theme`, `body{`.

Cheap static checks worth running on the source before publishing:

- count of theme-conditional blocks (should be 0 for a single-theme page)
- any custom property defined more than once outside its intended theme blocks
- any hex from the *other* palette still present after collapsing to one theme

## Encoding

The frame does send `<meta charset=utf8>`, so UTF-8 is safe in the viewer. It is **not** safe in a
`file://` preview or any other consumer that gets no charset — those fall back to windows-1252 and
render `—` as `â€”`, `·` as `Â·`, `→` as `â†’`.

Writing punctuation as named entities (`&mdash;` `&middot;` `&rarr;` `&hellip;` `&ldquo;`) keeps the
file pure ASCII and correct under any decoding, at no cost. Worth doing by default. Verify by
encoding the finished file with a strict `ascii` codec — it raises if anything slipped through.

## Mermaid

Mermaid renders in the frame but not over `file://`, so it cannot be checked locally at all.

It bakes a fixed palette into the SVG it emits, so it will not follow page tokens on its own.
Repaint it:

```css
.diagram svg .node rect      { fill: var(--surface-sunk) !important; stroke: var(--primary) !important; }
.diagram svg text            { fill: var(--ink) !important; }
.diagram svg .edgePath path  { stroke: var(--ink-faint) !important; }
.diagram svg marker path     { fill: var(--ink-faint) !important; }
```

Set a matching fallback palette in the diagram's own `%%{init: {'theme':'base','themeVariables':{…}}}%%`
block so it stays legible if a selector misses — mermaid's class names shift between versions.

When a diagram is simple (a hub and some spokes, a short pipeline), hand-building it in HTML/CSS is
often better than mermaid: it uses the page's tokens directly, needs no overrides, and can be
verified locally.
