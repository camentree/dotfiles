# The summary page

`summary.html` in the task directory, beside `proof/` and `review/`, so he gets up to speed from one page and watches the review move (asked for 2026-11-18). A review spanning a companion pull request has one page, in the main pull request's task directory. It always looks the same, and the review's session keeps it current through the whole review.

## The frame is fixed

At Set up, copy `~/.claude/skills/review/summary-skeleton.html` to `summary.html` and never change its `<style>`, its `<script>`, or the order of its parts: the title, the row of links, the progress bar, "What the PR does" (open), then the five steps. Only these change:

- the `<title>` and `<h1>`;
- the links in `<nav class="links">`: each pull request, the ticket, each difit while it runs, the proof page once it lands;
- each step's `data-status` (`todo`, `active`, `waiting` when it is on him, `done`) and `data-state`, a few words of where it stands. Code review and Behavior review are `done` once they have run, findings or not: their findings wait on him in difit, not on the page (he asked, 2026-11-19). The script builds the step's summary line and the progress bar from those two, so never write either by hand;
- the inside of each `<div class="body">`.

## The content is free

In whatever form the change calls for, built only from these:

- `<p>`, `<ul>`/`<ol>`, `<h3>` for a sub-heading, `<p class="note">` for a quiet aside;
- `<div class="finding">` for something wrong or questionable: a bold one-line lead, the story with real values, then a `note` with the fix and file:line;
- `<div class="held">` around what was checked and is fine;
- `<table>`;
- `<figure>` with an `<img>` or a `<video controls>` and a `<figcaption>`;
- `<pre class="command"><code>` for a curl or a command to run;
- a nested `<details><summary>…</summary><div class="body">…</div></details>` for anything secondary.

No other classes and no inline styles. `~/.claude/skills/review/summary-example.html` is a finished one (#8100 and #9661, editable care rate).

## What goes in each

- **What the PR does:** the change in very simple terms, a story with a resident and real amounts when the change has a user, then its pieces and the author's questions. Then whatever shows it best: the proof's recording (captions above the picture, as the proof skill says, a screenshot as poster), screenshots, or the curls to try.
- **Run the app:** what is running and where.
- **Code review:** each finding in plain words, the author's questions answered, what held behind a toggle; a companion pull request's findings and CI under their own `<h3>`.
- **Behavior review:** the verdict, what looks off, then behind toggles what the recording doesn't cover and how it was run.
- **Your review:** after he finishes, his verdict and what he raised, generalized into the idea that runs through it.
- **Comments posted:** each review's link and verdict, one line per comment, and the findings not posted.

## Keeping it current

Update it in the same turn as each event (the app answers, an agent reports, he comments, a comment is queued, a review is posted), then reload the tab in place (the difit skill's In Safari URL recipe) with `#step-<id>` to land on the section that changed. Agents return their part in plain words (`review/summary.md`, `proof/summary.md`, or in their report when the harness refuses the file), and the session turns it into the page.

## Length

No subtitle or last-updated line, which he called bloat. Inside a section lead with the verdict and what looks off, don't restate what the recording shows, and put the rest behind toggles: a full list plus every screenshot was too long (2026-11-18).

## Serving

`python3 -I -m http.server <port> --bind 127.0.0.1` from the task directory, in the background, so its relative links into `proof/` work; the first tab in the Safari tab group.
