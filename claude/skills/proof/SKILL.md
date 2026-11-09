---
name: proof
description: Show that a change works, in a form a person can look at - a recording of the app driven at a person's speed, screenshots, or a request and its response - and build the proof page that sets that evidence against each acceptance criterion. Holds what any agent needs to prove frontend or backend behavior in any app. Fixes nothing, starts nothing.
---

# Proof

Input: the plan file. `<name>` is the plan file's name without `.md`, and the proof directory is `<name>.proof/` beside the plan. Output: `~/.claude/tasks/<name>.proof/index.html`, one self-contained file, with what it was built from beside it.

The page is for Camen, who has not read the code and will not read it here. It replaces "I checked it" with something he can watch, so nothing goes on it that you did not see happen.

1. Read the plan. Read how this app is run and got around: the app's own skill when the skill list has one, and the project's CLAUDE.md and CLAUDE.local.md files. Read `checked.md` in the proof directory when there is one: the checks made while the task was built left there the paths they took and the data they created, so start from those. Local data only, never a deployed environment.
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
- `goTo`, `click`, `type`, `press` move a visible pointer and type key by key at a person's pace. `click` and `type` take a Playwright locator or a selector.
- `see(text)` waits for text to be on screen and holds on it. A criterion about something appearing ends in a `see`; if it never appears, the walkthrough fails and the recording shows where.
- `user.page` is the Playwright page, for waiting, reading, and putting data in place before the first step. Anything Camen should watch happen goes through `user`: a direct `page.click` happens in one frame.

Working the path out:

- Rehearse before recording. `PROOF_REHEARSE=1 node <walkthrough>.cjs` runs the same script with no pacing and no video, in seconds, and still writes each step's screenshot. Record, without the variable, once a rehearsal passes.
- Find controls by role and name, `getByRole('button', { name: 'Add New' })`, inside the dialog or region they sit in. When a control will not be found, dump the roles and names on the page once with a throwaway script, then write the walkthrough from what is there.
- Wait for the thing a user would wait for, a row or a heading, never a fixed time. A wait gives up after ten seconds; a slower page needs `user.page.setDefaultTimeout(<milliseconds>)` at the top.
- A state that lasts a moment, such as loading or a failed request, is held with `user.page.route` on the request it waits on, answered late or with an error. Never slow the network: a slowed dev server takes minutes for each load.
- Data the recording creates gets a name unique to the run, so a second run does not trip over the first.
- Under a minute each. Start where a user would start, not deep-linked past the part that matters.
- Read every step's screenshot before calling a criterion shown. A recording of a spinner, an error page, or the wrong account is not proof.

## From the backend

- Call the task's own server on its own port. Never a server someone else is using, never a deployed one.
- The evidence is the request line, the status, and the fields of the response the criterion is about. Cut the rest. No tokens, cookies, or keys.
- A criterion about what is stored is shown through the endpoint that reads it back. SQL only when no endpoint reaches it.
- A criterion that something is absent is shown by the response without it, with a line naming what was looked for.
- A test as evidence is its name and its output from a run made now. A result carried over from an earlier check says so.

## The page

`<proof directory>/proof.json`, then `node ~/.claude/scripts/proof/page.cjs <proof directory>`:

```json
{
  "title": "the task, as the plan titles it",
  "branch": "the branch",
  "summary": "Two sentences on what changed, as a user would see it.",
  "tryIt": { "url": "the page the change lives on, on the app you left running", "command": "what starts the app again if it has been stopped", "note": "who to sign in as, if it matters" },
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

Every criterion in scope gets an entry, in the plan's order. The page shows each recording once, above the criteria, however many of them cite it.

- `shown`: the evidence on the page shows the criterion holding.
- `failed`: the evidence shows it not holding, which includes the thing it describes not being there. Leave the recording in; it is the bug report.
- `not shown`: you could not get the app into a state where it can be checked. `how` says what was in the way.

Never raise a status to make the page look finished. A gap Camen can see costs him a minute; a claim he later finds false costs him the page.

If a step here fails or is missing, fix it, then record the fix once: how to prove something in any app → this skill; how this app is run or got around → the app's own skill when it has one, else its CLAUDE.md if mine, else CLAUDE.local.md; how one screen is operated → your agent memory when you have one; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.
