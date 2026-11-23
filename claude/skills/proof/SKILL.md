---
name: proof
description: Show that a change works, in a form a person can look at - a recording of the app driven at a person's speed, screenshots, or a request and its response - and build the proof page that sets that evidence against each acceptance criterion. Holds what any agent needs to prove frontend or backend behavior in any app. Fixes nothing, starts nothing.
---

# Proof

Input: the plan file. The proof directory is `proof/` in the pull request's branch directory, `~/.claude/tasks/<repo>/<branch>/proof/`, found from the worktree: `<repo>` is the `basename` of `git remote get-url origin` without `.git`, `<branch>` is `git branch --show-current`. Each pull request of a task has its own. Output: `index.html` in the proof directory, one self-contained file, with what it was built from beside it.

The page is for Camen, who has not read the code and will not read it here. It replaces "I checked it" with something he can watch, so nothing goes on it that you did not see happen. Its summary, context, captions and steps are written as `~/.claude/skills/assistant/writing.md` says.

1. Read the plan. Read how this app is run and got around: the app's own skill when the skill list has one; the project's CLAUDE.md and CLAUDE.local.md files load by themselves when you open a file in their directory with Read, so do not read them again. Read `checked.md` in the proof directory when there is one: the checks made while the task was built left there the paths they took and the data they created, so start from those. Local data only, never a deployed environment.
2. Pick the evidence for each criterion. One the plan marks `(test)` is shown by its test. For the rest, the first of these that applies:
   - A person would see it in the app: a walkthrough, under In a browser.
   - It is what a server answers: the request and the response, under From the backend.
   - Only a test can show it: the test's name and its output.
3. Start the app, unless it is already up, and put it in the state the evidence starts from. A seed step you had to work out goes in a script in the proof directory: it is also how Camen gets there.
4. Gather the evidence.
5. Write `proof.json` and build the page, under The page.
6. Leave the app running, since the page's Try it points at it, and stop anything else you started.
7. Return the page's path, then one line per criterion: its status and what shows it. Then anything you saw that looks broken and that no criterion covers, such as a column squeezed until it cannot be read. You are the only one who looks at the running app.

A later run replaces the page. Until its own page is built the old `index.html` stays where it is, since Camen may have it open. It gathers again only the evidence that the commits since the last page touch, and keeps the rest.

## In a browser

Record as few walkthroughs as show everything a person would see. One path through the app that passes five criteria is one recording, and each of those criteria points at it. A second walkthrough is for a path the first cannot reach.

A walkthrough is `<proof directory>/<walkthrough name>.cjs`, run with `node`:

```js
const { walkthrough } = require(`${process.env.HOME}/.claude/scripts/proof/walkthrough.cjs`)

walkthrough({ name: 'rename-project', directory: __dirname, baseUrl: 'http://127.0.0.1:3412' }, async (user) => {
  await user.step('Open the project\'s settings')
  await user.goTo('/projects/88/settings')
  await user.step('Rename the project and save')
  await user.click(user.page.getByRole('button', { name: 'Rename' }))
  await user.type(user.page.getByLabel('Name'), 'Spring launch')
  await user.press('Enter')
  await user.see('Renamed to Spring launch')
})
```

- `step(caption)` starts a step. The caption is what Camen reads beside the recording, so it says what a user is doing, not what the code does. Each step ends with a screenshot.
- Keep a caption to the behavior under test and its values, one line: "Set to $0: it saves as $0.00, not the recommended rate". No test residents' made-up names ("Waiver", "Custom") or setup detail: he found them noise (2026-11-18). Every recording carries its step captions burned into a bar above the picture, never below it, where the player's controls sit; a recording without them (older proofs) gets them from `~/.claude/scripts/annotate-video <walkthrough>.walkthrough.json`, which writes `<name>.annotated.mp4` beside it; the walkthrough helper does not burn them itself, so run it after every recording, and `page.cjs` embeds the annotated file when it exists (he asked that any video say at the top what is going on, 2026-11-18).
- `goTo`, `click`, `type`, `press` move a visible pointer and type key by key at a person's pace. `click` and `type` take a Playwright locator or a selector.
- `see(text)` waits for text to be on screen and holds on it. A criterion about something appearing ends in a `see`; if it never appears, the walkthrough fails and the recording shows where.
- `user.page` is the Playwright page, for waiting, reading, and putting data in place before the first step. Anything Camen should watch happen goes through `user`: a direct `page.click` happens in one frame.

Working the path out:

- Rehearse before recording. `PROOF_REHEARSE=1 node <walkthrough>.cjs` runs the same script with no pacing and no video, in seconds, and still writes each step's screenshot. Record, without the variable, once a rehearsal passes.
- Find controls by role and name, `getByRole('button', { name: 'Add New' })`, inside the dialog or region they sit in. Look at each page on the path once, dumping its roles and names with a throwaway script, then write the whole walkthrough in one Write from what is there, not control by control in edit-and-rerun: every rerun re-reads your whole conversation.
- Wait for the thing a user would wait for, a row or a heading, never a fixed time. A wait gives up after ten seconds; a slower page needs `user.page.setDefaultTimeout(<milliseconds>)` at the top.
- A state that lasts a moment, such as loading or a failed request, is held with `user.page.route` on the request it waits on, answered late or with an error. Never slow the network: a slowed dev server takes minutes for each load.
- Data the recording creates gets a name unique to the run, so a second run does not trip over the first.
- Under a minute each. Start where a user would start, not deep-linked past the part that matters.
- Read the run's contact sheet, `<walkthrough name>-sheet.png`, every step's screenshot captioned on one image, before calling a criterion shown, and open a single step's screenshot only where the sheet shows something wrong or too small to tell. A recording of a spinner, an error page, or the wrong account is not proof, and each shows at sheet size.

## From the backend

- Call the task's own server on its own port. Never a server someone else is using, never a deployed one.
- The evidence is the request line, the status, and the fields of the response the criterion is about. Cut the rest. No tokens, cookies, or keys.
- A criterion about what is stored is shown through the endpoint that reads it back. SQL only when no endpoint reaches it.
- A criterion that something is absent is shown by the response without it, with a line naming what was looked for.
- A test as evidence is its name and its output from a run made now. A result carried over from an earlier check says so.
- A generated PDF is shown as an image of its page: `sips -s format png -Z 2200 <file>.pdf --out <file>.png` renders page 1 (no ghostscript here), `magick <png> -crop WxH+X+Y +repage` cuts out the field.

## The page

`<proof directory>/proof.json`, then `node ~/.claude/scripts/proof/page.cjs <proof directory>`:

```json
{
  "title": "the task, as the plan titles it",
  "branch": "the branch",
  "summary": "Two sentences on what changed, as a user would see it.",
  "context": "For a review: what he needs to pick this up cold. Where in the app it lives, who uses it and when, what it did before, which pull request or ticket it follows.",
  "tryIt": {
    "url": "the page the change lives on, on the app you left running",
    "command": "what starts the app again if it has been stopped",
    "note": "who to sign in as, if it matters",
    "steps": [
      { "do": "Open Ada Park's Contacts tab and remove her Self contact", "url": "the page this step starts on", "expect": "the Remove button is disabled, with a tooltip saying why" },
      { "do": "Delete the Self contact through the API", "command": "the curl line or script to run, as he would paste it", "expect": "409 and the contact still listed" }
    ]
  },
  "criteria": [
    {
      "criterion": "the criterion, word for word from the plan",
      "status": "shown",
      "how": "One sentence on what was done to show it.",
      "evidence": [
        { "walkthrough": "rename-project" },
        { "image": "before.png", "caption": "what the image shows" },
        { "label": "GET /projects/88 as a member without edit rights", "text": "the request and response" }
      ]
    }
  ]
}
```

`tryIt.steps` is the list Camen works down to try the change himself, each with a box he ticks: three to eight things, the main path first, then the edges a reviewer would poke (the empty case, the other role, the undo). `do` names the real record and page from your own run, so he does not hunt for data; `url` for a step in the app, `command` for one from a terminal (it gets a Copy button), `expect` what he will see when it works. Only steps you ran yourself.

Every criterion in scope gets an entry, in the plan's order. The page shows each recording once, above the criteria, however many of them cite it.

For a stack proved on one page, put `"sections": [{ "title": "PR 1 (...)", "criteria": [...] }, ...]` in place of `criteria`: each section gets its heading, the recordings it first cites, and its criteria, numbered on across sections, so one section's media lifts into its own pull request.

- `shown`: the evidence on the page shows the criterion holding.
- `failed`: the evidence shows it not holding, which includes the thing it describes not being there. Leave the recording in; it is the bug report.
- `not shown`: you could not get the app into a state where it can be checked. `how` says what was in the way.

Never raise a status to make the page look finished. A gap Camen can see costs him a minute; a claim he later finds false costs him the page.

If a step here fails or is missing, fix it, then record the fix once: how to prove something in any app → this skill; how this app is run or got around → the app's own skill when it has one, else its CLAUDE.md if mine, else CLAUDE.local.md; how one screen is operated → your agent memory when you have one; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.
