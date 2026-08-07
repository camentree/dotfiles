# House style

How anything written for Camen to read should be built. Applies to every `explain` mode and to any other HTML page made for him.

## Collapsing

A fold is context priced by how likely Camen is to need it. Context he doesn't open costs him nothing, so folds are how a page carries more than he has to read.

The collapsed page is the complete fast read. **The failure is having to expand something in the happy path** — that means the summary didn't stand on its own. Fold count is not the metric; unnecessary expansion is.

**Summary and body do different jobs.** A summary gets shorter by assuming knowledge, and that's what makes it good. The body supplies that knowledge, minimally, for when he doesn't have it. So bodies are short. No body at all is fine when the summary needs no unpacking.

- Every summary carries its information alone, for a reader who has the assumed knowledge. "There is no database constraint backing any of it", not "Constraints".
- Never collapse behind a label that only names a topic.
- Word-cost discipline applies inside folds too. Expanding should not be punished with prose.

**A good summary is longer than a label, and that's correct.** "Feature flag gating" is short and useless; "the feature flag turns the whole surface into 404s" is longer and stands alone. Where standalone summaries and fewest-words disagree, standalone wins — the stated failure is unnecessary expansion, not word count.

**Price each piece by how likely he is to need it.** Very likely, it's uncollapsed prose. Low to medium, it's a fold. Vibes, not arithmetic — the decision is about probability of need, not importance or length.

Collapse two kinds of thing: concepts he may already know, and anything not needed for the task at hand.

## Density

Every word has a cost. Concretely:

| Cut | Because |
|---|---|
| "that id is the whole basis of this change" → "which we can use to discern duplicates" | Says it matters instead of what it does |
| "their gateway times out" | Mechanism that doesn't change the outcome |
| "So they send the identical batch again" → "So they retry" | Shortest phrasing wins |
| "201 vs 200 is the tell" → "201 vs 200" | Meaning unchanged without it |
| "A partner can use that to detect their own retries" | Shifts to an audience the reader isn't |
| "'Look, then create' has a gap." under a header saying that | First line restated the header |
| "The lookup key is three things together: …" | Restates the sentence above |

Also cut:
- Italics for emphasis
- Any sentence summarizing the one above
- Any first line that re-explains its header
- Framing about why you're including a section

Prefer a list to a paragraph. Prefer a header that lands the point to a header plus explanation.

Make consequences explicit — that isn't fluff. "Both create" → "both create, resulting in a duplicate".

Avoid black-and-white. "That reads like a bug and isn't" → "That reads like a bug but is defensible".

Where `artifact-design` and density disagree, density wins. Keep the treatment utilitarian.

## Worked examples

One concrete case, settled before writing anything else. Everything else hangs off it.

**Prefer the repo's own checked-in test fixtures** — real, non-production, and the example then matches the code's own assertions. Failing that, use ids from the ticket. Invent only what neither supplies, and never invent a resident's name when a fixture has one.

**Infrastructure has no domain data.** For a refactor, "real" means real identifiers from the repo — the actual class, the actual generated output, the actual annotation. Inventing there is worse than naming the real thing, because the real thing is the subject.

**For an enum- or flag-shaped subject**, the example is one setup with N outcomes in a table, not N narratives.

**When there are several independent surfaces**, pick the one where behavior is most visible and build the example there. The rest get a sentence up front and their full treatment in the mechanism section.

## Diagrams

Inline SVG. Conceptual boxes, no file paths or line numbers. Mark what's new or what's in scope.

No caption — if a diagram needs prose to say what it shows, fix the diagram. Put the description in `aria-label`.

`artifact-diagramming` asks for a `<figcaption>`. This overrides it; everything else in that skill still applies.

Good default, but skip it when the subject is a fact rather than a topology (a map lookup, a single added check). "Would a reader trace this with a finger?" If no, drop it.

## Vocabulary

At most three terms, and only ones the explanation hinges on. The known-knowledge list below marks the whole domain explain-worthy; taken literally that's a page of dotted underlines.

Inline expandable at first use. Never a glossary, never a parenthetical mid-sentence.

Two mechanics, both of which break the page visibly:

**`<details>` is not phrasing content**, so it's invalid inside *any* element that accepts only phrasing content — `<p>` and `<summary>` both. The browser closes the parent early, orphaning the rest of the sentence, and the text renders overlapping itself. Use `div.prose` for a paragraph containing one, and never put a term inside a fold summary — move it into the body.

**Don't put punctuation directly after a closing `</details>`.** The comma wraps alone onto the next line. Reword so a normal word follows the term.

Check the rendered structure, not just the markup. Both bugs look fine in source.

## Code

Syntax highlighted, narrow and tall. Break long expressions rather than scrolling sideways. Collapsed.

Include only where prose can't carry it. Unremarkable code isn't worth showing because he's learning the language — pick the snippet that carries the point.

## What Camen knows

Evolves — update as it changes.

**Explain:** Scala syntax and idioms, FP patterns (`traverse`, `partitionMap`, `Validated`, for-comprehensions, `AugustIO`), this codebase's conventions, the domain (billing, care, move-ins, integrations).

**Assume:** SQL and relational modeling, Python, TypeScript/React, HTTP and REST, general database concepts, git.

## Anti-goals

- Restating code as prose
- File paths and line numbers instead of explanation
- Exhaustive branch coverage when the shape is what's needed
- Any word that could be deleted without loss

## Output

`mkdir -p ~/Documents/notes/explain` first — nothing else creates it.

**Start from `page.html` in this directory.** Copy it, replace `TITLE`, the eyebrow, the standfirst, the `<!-- CONTENT -->` marker, and the footer. Don't rewrite the CSS or the script — that's how pages drift apart and how the `<details>`-in-`<p>` bug comes back.

The scaffold already carries: the token palette in all three theme states, the fold styles (`details.fold`, and `details.fold.section` for a whole section), inline vocabulary (`details.term`), `div.prose`, numbered sequences (`.timeline`), `table.data`, callouts (`.was`, `.risk`), the Scala syntax highlighter, and the comments layer.

Everything is one file, opened with `open`. Never markdown in the terminal, never a published artifact. Nothing may reference a network resource — `file://` blocks module imports and cross-origin fetches.

Load `artifact-design` for page design and `artifact-diagramming` for the SVG. Their artifact-frame specifics don't apply; the design guidance does.

**Class reference for the scaffold:**

| Need | Use |
|---|---|
| A paragraph containing an inline vocabulary term | `div.prose`, never `<p>` |
| A collapsible point | `details.fold` > `summary` + `div.inner` |
| A whole section collapsed | `details.fold.section` |
| A note beside a fold summary | `span.aside`, or `span.aside.warn` for a live risk |
| Old behavior at the step where it changed | `p.was` — pull-request mode only |
| A live risk called out | `p.risk` |
| Worked-example sequence | `ol.timeline` > `li` > `span.step` + `div.body` |
| Data table | `table.data`, wrapped in `div.scroller` |

## The comments layer

Every page carries it, free, from the scaffold: a `comment` button on each heading and fold summary, comments kept in `localStorage`, and a bar bottom-right with a count and a Copy button that puts labelled markdown on the clipboard.

Camen comments in the browser and pastes back. Never ask him to hand-edit the HTML, and never use inline `(? ...)` markers.

## Pages several skills write

A ticket page is created by `/explain` and then grown by `/plan-feature`, `/plan-pr`, and `/execute-pr`. All pages live in `~/Documents/notes/explain/`.

| Section | Owner |
|---|---|
| Source links, What's being asked, What happens today, How it works today, Constraints, Prior art | `/explain` |
| Files, PR slices, Decisions | `/plan-feature` |
| A slice's Plan | `/plan-pr` |
| A slice's Branch and PR | `/execute-pr` |
| Open questions | `/explain`, appended by the planning skills |

**Own your sections, carry the rest through untouched.** Regenerating means rebuilding from what's there plus what you're adding.

**Collapse shifts as work moves.** Price each section by how likely he is to need it *now*. Orienting: current behavior open, no slices yet. Planning: orientation collapses. Executing: finished slices collapse, the one in flight stays open.

**Summary for him, body for the machine.** File paths and signatures go in fold bodies where a future session can find them; the summary says the shape. A flat list of fifteen paths or eight test names is the wall of text he has complained about.
