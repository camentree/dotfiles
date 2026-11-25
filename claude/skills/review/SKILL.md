---
name: review
description: Review a branch or pull request with Camen in difit - his own or a teammate's. Use whenever he asks to review, or for help reviewing, a branch or pull request, in any words ("review <url>", "help me review", "difit"), and with --prepare from the work page or /manage. Prepares everything slow first - the app compiled, the walkthrough, findings run against the app, a proof page, a summary page - and opens nothing he sees until he asks. On his own branch his comments become commits, never rewritten; on a teammate's the comments he marks go to GitHub as one review when he publishes. Updates itself from his feedback.
---

# Review

Read the `difit` skill first (starting a server, posting and keeping threads, shutting down) and `~/.claude/skills/assistant/writing.md` (how every thread, comment and explanation is written). This skill holds what goes in the threads and how to answer.

Input: a pull request number or URL, or nothing for the current branch; `--prepare` to stop once everything is ready.

Every subagent on a review runs on `opus` or `fable`, never `sonnet`: pass `model` on each Agent call, since a scout defaults to sonnet (he said, 2026-11-25).

Everything about the pull request lives in its task directory, `~/.claude/tasks/<repo>/<branch>/` (the README's "The task directory"): `plan.md` on his branch when there is one, `proof/`, `review/` for the collateral (repro scripts, their output, findings), `task.json`, and difit's `difit.json` and `comments.json`. A teammate's gets one too, under its head branch. Create it if missing.

**Whose it is** decides two things, and nothing else in the review differs. The pull request's author is `camentree`, or there is no pull request and it is the current branch: it is **his**. Anyone else: it is a **teammate's**.

| | His | A teammate's |
|---|---|---|
| A change request in a thread | a commit of its own, replied `done in <sha>` | no code change, commit nothing: the code is someone else's |
| GitHub | nothing posted | his marked comments, as one review, on his verdict comment in difit |

**The flow.** Nobody watches the terminal: he works from the work page (`~/.claude/skills/assistant/data.md`), and the page's buttons arrive here as messages. Prepare, then end the turn. `[open review]` or `[reviewing]`: Open. Each comment the difit monitor reports: Answer him. `[paused]`: Pause. `[publish]`: Publish. Without `--prepare` (he ran it himself), Prepare and Open run in one go.

**Reporting.** This session is the only writer of the task's `task.json`, through `node ~/.claude/scripts/task-set.cjs` from the worktree, as data.md says: `--doing` at least every 10 minutes while working, and subagents report to this session, not to the file.

**Deciding.** Easily reversible, or not reversible but what the change should do is clear: decide, and record it with `--decision`. What a user should be able to do or see is unclear: ask through `task-set.cjs --question` (writing.md's form), carry on with what does not depend on it, end the turn; the answer arrives as `[answer]`. Pushing and posting under his name happen only on the signals in `~/.claude/skills/review/push-and-post.md`: read it before either, every time, since it is where the rule changes (agents working from an older reading pushed and posted at the wrong moments, 2026-11-24). Merging never. Never AskUserQuestion or a "Needs you" line: nobody is at the terminal.

## Set up

1. Check `aws sts get-caller-identity --profile us-developer`. When the SSO session has expired, at the start, not the end (uploads, `bin-local/users add`, and Tools imports fail without it): run `aws sso login --profile us-developer` yourself in the background and, as it opens the sign-in page, `osascript -e 'display notification "Sign-in page opened by the review of <pr>" with title "AWS sign-in"'` so he knows what the page is; he only approves it in the browser (he asked, 2026-11-24, over a `--question` telling him to run it; no clickable notifier is installed).
2. With a pull request: `gh pr view <n> --json title,author,headRefName,baseRefName,body,files,headRefOid,statusCheckRollup,url`. Read the description closely: its claims are what the review checks. A Linear ticket id in the branch name or title gives the `(linear)` tab.
3. Name the terminal tab: a teammate's, `tabname '<author> - <feature>'`, the author abbreviated the way he abbreviates people (the People list in his notes; someone not on it, their GitHub login, which is the list's pattern); his, as his CLAUDE.md says.
4. `task-set.cjs --title "<what changes for a user>" --kind mine|teammate --pull <url> --state working --doing "preparing the review"`, so the page shows an agent has it.
5. Work in the branch's own worktree. A session the work page started already runs in it, made by `wk`: `git fetch origin <branch> <base branch>` and use it (2026-11-23, the first page-started review). His: the one `git worktree list` shows it in, when there is one. Otherwise, and always for a teammate's: `git fetch origin <branch> <base branch>`, then `wk <branch>`. Never in the worktree the session started in when that is another branch: it is usually his own work, uncommitted. An August pull request is in `augusthealth/valinor`, checkout `~/Projects/valinor`. One whose description starts `Migrated from <url>` was moved from august-backend or august-frontend by `bin/migrate-pr`, and its earlier reviews and threads are on that old pull request: read them there. Given an old-repository URL, find the valinor pull request that names it (`gh pr list -R augusthealth/valinor --search "<url> in:body"`) and review that; when there is none yet, review the diff only, with no app, and say so in the explanation.
   - `wk` links the shared untracked files (`bin-local`, `CLAUDE.local.md`, `local.sbt`, ...). If it prints `no matches found` from `wk-share-files`, run `wk-share-files <main checkout> <worktree>` again from a fresh `zsh -ic`.
   - A `.env` that comes out as a dangling link (the main checkout has none): replace it with a copy of another worktree's `.env`. `bin-local/dev` rewrites its sandbox block.
6. `<base>` is the commit whose diff to `HEAD` is exactly what he has not seen yet, chosen from the code, not from a fixed branch name:
   - First review: `git merge-base HEAD origin/<base branch>`. The base branch is the pull request's `baseRefName`; with none, `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`). A stacked branch diffed against the default branch shows its parent's changes as its own.
   - Prepared already, with no new commits since `comments.json`'s threads: skip Prepare, since the walkthrough, the code review and the proof are done (he asked on 2026-11-19 whether a rerun redoes everything).
   - Already reviewed, new commits since: the last commit he reviewed, so the diff is only the new work. `difit.json` or `task.json`'s `review.difit.base` carries the last base, and `comments.json` his earlier threads.
   - The pull request's base branch changes mid-review (restacked, or the base merged in): restart difit on `git merge-base HEAD origin/<new base branch>` right away, re-posting the open threads, with a thread saying which files belong to which pull request, or the server shows the base's commits as this change (seen 2026-11-13: a 6k-line diff after a restack). The same after you `git merge origin/<base branch>` into the branch yourself, in the same turn as the push (seen 2026-11-15: a 9k-line diff after merging master).

## Prepare

All started in one turn, none waiting on another:

1. **The app**, from this session with the Bash tool's `run_in_background`, never from an agent: an agent's background servers die when it finishes. `august-app start` from the worktree, as the august skill says: it runs `bin-local/dev`, which starts the backend and the frontend both (ports from `august-app status`; `--api` when the change is in the external API); it stages the branch through the worktree's warm sbt server, so this is the compile. Nothing to run (a script, a skill): compile only when there is something to compile.
2. **The walkthrough**, as The threads say. It needs only the diff, the description and the plan, so write it while the app compiles.
3. **Tests, a teammate's only.** None when CI passed on `headRefOid`: CI ran them. Otherwise the specs the branch adds or edits, once the app's stage has finished (they share the worktree's sbt server), as the repo's notes say. His branch: none, they ran before the handover.
4. **The code review**, a background `worker` agent (Code review agent, below).
5. **The proof**, a background `driver` agent with `Run /proof`, only when the task directory has no `proof/index.html`: his work was proven before the handover, so a proof page there is never rebuilt. A teammate's takes the description's claims as the criteria. The prompt asks for `context` and `tryIt.steps` as the proof skill describes them: working out what a pull request is and what to try costs him most of a review (2026-11-18). A page that is already there with no `tryIt.steps`: add `context` and the steps to its `proof.json` from the plan and the page's own evidence, then rerun `page.cjs`, re-recording nothing.
6. **The summary page**, under Summary page.

A companion pull request (the other half split out, or an Experimental-Tools change, named in the description) is part of the review: its own worktree and app beside this one, so the proof shows the change in use, and its own difit threads with a code review agent; no walkthrough or behavior check on it unless he asks (2026-11-18). When its worktree carries an uncommitted local change (the frontend's `authMethod: 'none'`), its difit runs on `HEAD <base>`, a fixed pair, so the change stays out of the diff.

An agent stopped by a usage limit keeps its work: resume it with SendMessage, not a fresh agent.

When every agent has reported:

- Write the threads into `comments.json` as the difit skill's Prepared threads says: the walkthrough, every finding from `review/findings.json`, and on the first walkthrough thread the proof page's path.
- Record what the page shows, writing each as writing.md says: `--explanation`, one `--finding` per finding (`--reproduced` when it was run), one `--proof` per recording or key screenshot from `proof/`, and `--review-file` with `{ "difit": { "base": "<base>", "comments": "comments.json" }, "tabs": [...] }`, the tabs in the order Open opens them.
- One `--material "<kind>|<label>|<url>"` per tab in Open's order (kinds `context` for the summary, `difit` for the wrapper url `http://localhost:4990/review.html?id=<card id>&port=<port>`, `pr`, `proof`, `linear`, `other` for the app or plan), after a `--material-clear` at the start of the review: the page's Review button opens exactly these in one Safari group, with no agent, and a card with materials is Queued for him (2026-11-25).
- A teammate's: `--ready review --state ready --doing "review ready"`. His: leave `--ready work` as `/manage` set it, `--state ready --doing "review ready"`.
- With `--prepare`, stop the app (`august-app stop --worktree=<worktree>`) and end the turn. Without it, go straight on to Open.

Several pull requests at once: one background session per pull request, each owning its whole review; the work page starts them (`POST /api/agent` with `kind: "review"`). The podman VM has 4 GiB and a test run's Testcontainers take about 500 MB, so at most two teammates' test runs at a time.

## Code review agent

`subagent_type: worker`, in the background. The prompt names the worktree, the task directory, `<base>`, the pull request (or the plan's criteria on his branch), the app's port and the user to call it as, and gives it Checking a finding, Collateral and writing.md. It reads the change against the description's claims, or the plan's criteria, and reports a finding only once it has run it, waiting on `curl -X GET localhost:<port>/ping` when it needs the app. It starts and stops nothing: no difit, no app, no `task-set.cjs`. It writes each finding's transcript to `review/<finding>.md` and all its threads, as the JSON body for `/api/comment-imports`, to `review/findings.json`, and returns one line per finding. When CI failed on the head commit, it reads the failing jobs' logs first and says why each failed (the pull request's code, a package not yet published, infra, a job cancelled by another's failure) before anything else. The harness refuses an agent's report files such as `summary.md`, so the prompt asks for that text in the final report too, and this session saves it.

## Checking a finding

Before writing a finding, run the code. A finding no one ran is a guess, and he will ask.

- For each place the code and a claim might disagree, build the smallest state that tells them apart and run it: the requests in a script under `review/`, so he can rerun it. Before the bug, after the change, and against the claim.
- Check a suspicion from more than one side before calling it a bug: the case that works, the case that doesn't, and what master does.
- A suspicion only a test reaches: the smallest spec case that shows it, run as the repo's notes say.

## Collateral

Every finding carries what shows it. For the backend that is, from `review/`:

- the request line and body that set the state up, and the one that shows the bug,
- the fields of each response that matter (cut the rest, no tokens),
- the state left behind, read back through the endpoint that returns it, SQL only where no endpoint reaches it.

In the finding's thread, the short form: the steps as plain sentences with the actual dates or values, then expected against what came back. The full transcript goes in `review/<finding>.md`, with the script's path. For a frontend change, record it as `/proof`'s In a browser says.

## Summary page

Every review gets `summary.html` in the task directory, copied at Prepare from `~/.claude/skills/review/summary-skeleton.html` and kept current in the same turn as each event, so he gets up to speed from one page (2026-11-18). How to fill and serve it: `~/.claude/skills/review/summary-page.md` and `summary-example.html`, a filled-in page, both read before touching yours. "What the PR does" shows the change, not just tells it: the proof's recordings (captioned at the top, the proof skill's `annotate-video` when they aren't) and the before/after screenshots inline, never only a link to the proof page (he asked, 2026-11-18); copy them into the task directory's own `media/`, since a stack's shared proof folder can be moved by a sibling review.

## Open

On `[open review]`, or straight after Prepare when he ran it himself. Everything he needs to try the change is running and open, so he never starts anything himself:

- The app again, as Prepare's step 1. A frontend change gets a tab on the page where the change shows, at `http://127.0.0.1:<port>`, never `localhost` (the API calls go to 127.0.0.1, so a localhost origin fails every one with CORS and shows "Internet problems", 2026-11-24), signed in as the user who sees it: `?mock_user=<email>` when that is not camen@, with the role set through `bin-local/users set` first. Not the community's front page: the person's tab, the modal's page, the record the findings used. A backend change: the repro script's path is in the first walkthrough thread.
- difit, as the difit skill's Start says, on `review.difit.base`, with `comments.json` restored. On his branch with `--include-untracked`: untracked files are part of the change.
- The review's Safari tab group, as the difit skill's In Safari says, never Chrome (2026-11-18): `review.tabs` in order (the summary page first, then each difit, the pull request and its companion, the app, the proof page, the Linear ticket, the plan). His own work opens this same full set, a built task and fixes to review comments alike, never difit alone: a page it lacks (no `summary.html`, no proof page, the app not up) is made or started first, since he reads his own change the way he reads a teammate's (he asked, 2026-11-24). The urls also go in the first walkthrough thread. `[open review]` is him pressing review, so always open the group and let it take his window, even unattended and even when the review is already running (difit up, state `reviewing`): a second `[open review]` means he sees no tabs. Never end the turn with only a url (he asked, 2026-11-25, after a round that reported only a link).
- `[reviewing]` is him pressing review on the work page, which already opened the card's materials in the Safari group it names: set `--state reviewing` first, start what is not up (the app, each difit server), add each new url with `--material`, and open only those new tabs into that same group, never the whole set again (#93 sat `ready` with nothing running, 2026-11-25). Then update `summary.html`'s steps in the same turn: "Run the app" done with its urls, "Your review" in progress, since that page is the first tab he reads (#93's still said "starting" with the app up, 2026-11-25). Then arm the difit comment monitor as the difit skill's Reading his comments says, since there is no send comments button to wait for (2026-11-25); the `[reviewing]` message itself lists these steps and the monitor's command.
- `[paused]` is him pressing to queue: stop the comment monitor, save each difit server's threads and stop the servers as the difit skill says, stop the app (`august-app stop --worktree=<worktree>`), keep the materials, and `--state ready --doing "paused, review again to resume"`; the next `[reviewing]` starts it all again (he asked, 2026-11-25).
- `task-set.cjs --state reviewing --doing "reviewing in difit"`, no `(difit LAN)` entry (everything is localhost only, 2026-11-25): `--doing` is five words at most, no urls (it tops the closed card, 2026-11-24). End the turn.

## Slices and fixed pairs

Reviewing one slice of the branch (e.g. "just the modal"): the scope is every change since the fork point that the slice needs (its files plus the code they call), not the latest commit. difit has no path filter and ignores a diff piped on stdin in `--background` mode, silently showing `HEAD~1..HEAD` instead. Build a review-only commit instead — the fork point's tree with the slice's paths taken from `HEAD` — and diff that against the fork point, under `<slice>`:

```
GIT_INDEX_FILE=<tmp>/review.index git read-tree <base>
git ls-tree -r HEAD -- <paths> | GIT_INDEX_FILE=<tmp>/review.index git update-index --index-info
git update-ref refs/review/<branch>/<slice> "$(git commit-tree "$(GIT_INDEX_FILE=<tmp>/review.index git write-tree)" -p <base> -m review)"
npx --yes difit refs/review/<branch>/<slice> <base> --port <port> --keep-alive --no-open --clean --host 0.0.0.0
```

Run it under `bash -c` (zsh does not word-split an unquoted `$paths`), and save `paths` and `target` in `<slice>.difit.json` in the task directory. It is a fixed pair (see the difit skill). List what the slice leaves out in the first thread. A slice started mid-review carries over the other servers' threads on its paths: `/api/comments` restore won't take them (different target), so re-post each thread's messages through `/api/comment-imports`, the first as `thread` and the rest as `reply`, each keeping its `author`. "Non-test files only" is `git diff --name-only <base> HEAD | grep -v -E '\.test\.tsx?$|^test/|^src/mocks/'`.

**Fixes for PR review comments.** On his branch, when the commits under review answer a reviewer's comments (`/address-comments --unattended` opens its fixes this way), give each commit its own server, so each fix reads against the comment that asked for it. Only comments still unaddressed: a thread he has already replied to was reviewed in an earlier round. Comments answered by a reply alone (no commit) get one server on the pull request's own diff, a thread each on the line the comment sits on, with the drafted reply, since otherwise there is nothing to open (2026-11-24). One tab is one reviewer comment: when he asks for something different on a comment, amend that comment's unpushed commit (or, for a reply-only comment, make its commit) and restart the same port on the new sha with the thread carried over, never a new tab beside it (he asked, 2026-11-24).

- Map comments to commits: `gh api --paginate repos/{owner}/{repo}/pulls/<n>/comments`; keep the reviewer threads with no reply from him, and match each to the commits made for it since. One commit can answer several comments, and one comment can need several commits. An uncommitted change that answers a comment gets a server too, `difit . HEAD`.
- One server per commit: `npx --yes difit <sha> <sha>^ --port <port> --keep-alive --no-open --clean --host 0.0.0.0`, consecutive free ports, state in `pr-<NN>-<slug>.difit.json` and `pr-<NN>-<slug>.comments.json`, fixed pairs as the difit skill says. Prepared, `review.difit` is the list of them, each with its `target`.
- One thread per server, on the commit's first added line in its main file (`"side":"old","line":1` for a deleted file): the link `https://github.com/<owner>/<repo>/pull/<n>#discussion_r<id>`, the comment verbatim as a blockquote, then what it asks in plain words as a short story with a resident (he couldn't follow a quoted reviewer comment alone, 2026-11-24), then what the commit did, anything in the comment it leaves unanswered, the drafted reply, and his own replies on the thread quoted. Then `Proof:` and a link straight to that commit's section of the proof page (`…/proof/index.html#<sha>`, the page having one section per commit with its recording or screenshots, or the test run for a change with nothing to see), since he asked how to see the proof for one fix (2026-11-24).
- A tab per server, named for what its commit does, three to five words in a user's terms ("room list keeps vacant first", not the sha or the card's title): pass it as `&name=<url-encoded>` on the wrapper url and as the entry's `label` in `review.difit`, so six tabs of one card can be told apart (he asked, 2026-11-24). Comments no commit answers, and those a commit answers only in part, go in `--explanation`.

## The threads

Walkthrough threads start with `(walkthrough)`, findings with `(finding)`. A request to look at a few uncommitted fixes skips the walkthrough and the findings.

Walkthrough, in this order:

- **What it does.** One thread on the first changed line of the main file: a teammate's pull request and number, or on his branch the criteria it serves; the change in a few sentences, the pieces it is made of.
- **Context.** Wherever a reader would otherwise have to ask: how the code it calls works, a decision from the plan and the alternative rejected, a precedent it follows, why a test changed.
- **Critical path.** The change most likely to break something else, and why.
- **How to verify.** On the test file: the commands run and their counts, or that CI passed on the head commit, or on his branch that the proof page holds the evidence. The command and its expected output on the line it proves.

Findings:

- Lead with the behavior in plain words and the domain's own nouns: "the bed assignment's start date stays on the move-in date", not "the bed doesn't move", and never "the date" without saying which. Then the concrete steps with real values. Code identifiers and the fix come last.
- A teammate's: a draft of a comment he could post, phrased as a question or a suggestion to a peer, not a verdict. His: the fix you'd make, which he accepts in a reply.
- State only what was run. A guess about how common a case is, or what production data holds, is said as a guess or left out.
- Anchor a finding on the line where the behavior happens (the call that throws, the branch that drops), never on a neighbouring line about another case: a corrupt-PDF finding on the `InvalidPasswordException` line read as a password finding.
- One finding per behavior. Two bugs with one fix are still two threads, with the fix in each.

## Answer him

On each comment the difit monitor reports (or a leftover `[comments sent]`: every thread whose last message is not Claude's): reply in its thread at once with one line on what you will do, act, then reply again with the result, so no comment of his hangs unanswered (he asked, 2026-11-25; the monitor replaced the send comments button the same day). A reply from him is working the issue out with you, not a request for new wording:

- "What happens" asks for the outcome a user sees, in a sentence; give the code path only when he asks for it.
- Answer the question plainly, in the same thread. Don't append a reworded comment.
- "I don't understand": tell it as a story, with a person and dates, before any code.
- When he restates it, check every part against what was run: the order of steps, which date is which, which side is earlier. Say "yes" only to what holds, and correct the rest by name.
- Disagreement with a decision: reply with the options and a recommendation. No code change until he answers.
- Resolved threads disappear from the server; that is him, not loss.

His branch:

- A change request, or a yes to a finding's fix: say in the thread whether you agree before touching code — "agree, doing it: <the change in a line>", or what you'd do instead and why. Then a commit of its own. Reply `done in <sha>` plus one line on what changed. Then run the tests that cover it.
- Never amend, fixup, rebase, reset, or force-push: a `done in <sha>` must stay a commit he can open, here and on GitHub. When the base branch has moved and the branch needs it (conflicts, or a merged stack parent padding the pull request's diff), `git merge origin/<base branch>`, resolve and commit without asking (he said not to ask, 2026-11-19).
- What a difit comment of his lets you push or post is the table in `push-and-post.md` beside this skill and nothing wider: his "looks good" or `accept:` on one server covers that server's commit and no other (he said, 2026-11-24).

A teammate's:

- A message he starts with `(post)` or `post:` is a comment to post, in his words, held until his verdict: a new comment on that line when it opens a difit thread, a reply when its thread mirrors a GitHub thread (posted after the review with `gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments/<comment id>/replies -f body=<text>`, exactly that form). Check each against what was run and note anything it gets wrong, including the code's own names: he wrote "negotiated care rate" where the code compares the recommended care rate (the negotiated rate is rent), 2026-11-18. When he says to update it ("update the post to say …"), reply `Text to post:` and his text with only that change; the latest one in a thread wins. A thread he asks me to start on a line is a draft in my words, opened with `Text to post:`.
- His verdict and the review's summary come in one difit comment whose first line is the marker: `accept:` is `APPROVE`, `changes:` (or the older `reject:`) is `REQUEST_CHANGES`, `comment:` is `COMMENT`, and the text after it is the summary, posted with every `post:` comment (his convention, 2026-11-24). Check the summary as you check a `post:`. A paste of difit's thread dump in place of `[comments sent]` is the same signal: read the server, not the paste. The verdict comment is how he publishes: a teammate's review card has no publish button (2026-11-24). Once the summary and every `post:` are factually right against the code and what was run, go straight to Publish with them. When one is not, post nothing yet and raise it to him with `--question`: which comment, what it says against what the code does (file and line, the run), and options he can tick, the first your revised text in full (`Post it revised: "<text>"`), then `Post it as written`, then `Drop it`; one question holding every comment that is off, and Publish on his answer.

Keep the threads alive through fixes as the difit skill says: fixes that delete lines drop the threads above them.

## Publish

On `[publish]`, or a teammate's verdict that checked out.

Run the command below exactly in this form, alone, flags in this order (`-X POST`, never `--method`, no `cd … &&` or variable prefix): a permission rule matches the literal form, and any other form is refused when the instruction came through difit or a relay.

A teammate's: post one review holding his summary (the text after his verdict marker) as `body`, the verdict as `event` (`COMMENT`, `APPROVE`, `REQUEST_CHANGES`; never one he didn't give: with none, ask through `--question`), and each thread's latest `(post)` text, verbatim without the marker, on the line its thread sits on:

```
gh api -X POST repos/<owner>/<repo>/pulls/<n>/reviews --input <scratchpad>/review.json
```

with `{"commit_id": "<headRefOid>", "event": "<his verdict>", "body": "<his summary>", "comments": [{"path": "<repo-relative path>", "line": <n>, "side": "RIGHT", "body": "..."}]}`. Check `headRefOid` still matches the worktree's `HEAD` first; if the author pushed since, ask before posting. Run every `gh pr` call with `-R <owner>/<repo>`: from the companion's worktree, `gh pr view 8100` read the frontend's #8100 and showed a false "pushed since" (2026-11-18). Before posting, read each final text once more for a fact a reply flagged that he never fixed: fix it and record a `--decision` saying so. A companion pull request gets its own review with its own verdict; when one review's body links the other's ("same comment as …"), post the linked one first and put its URL in. Fill the summary page's Your review and Comments posted, set `--doing "review posted"` and record the review's link as a `--decision`, then Close without waiting: once posted there is nothing left (2026-11-18).

His branch: `/verify <plan> --pre-push` by a `worker` (its findings, if any, go to a `fixes` build and verify runs again; when a pass fixes less than the one before, stop and ask through `--question`). Then `/pr` with the description he sent, which opens it ready for review. When the pull request already exists, only push: its description is his (he rejected a `/pr` rewrite on 2026-11-13 with "just push"). Then Close.

## Close

- A role changed for him to try it: set camen@ back to `GROUP_TYPE_SUPER_USER` with `bin-local/users set`.
- Shut difit down as its skill says, stop the app (`august-app stop --worktree=<worktree>`, which stops that worktree's backend and frontend only; leave servers whose start time doesn't match yours, since a sibling review may be using them, 2026-11-18), and close the Safari tab group's tabs.
- A worktree made for the review: keep it and its database (`wk rm <branch>` removes both).
- `task-set.cjs --ready none --state done --doing "<what was posted or pushed>"`.

Then, on his branch, turn what he asked for into rules, so the next branch does not earn the same comment. Go through his comments in `comments.json` once. Leave out what was about this change only. For each one that would apply to other work in this repo and is not already in its notes, draft one line, the rule and a one-line why, for the `## Code style checks` section of the repo's CLAUDE.md if it is his, else its CLAUDE.local.md: builders read that section before they write, and `/verify` grades against it. A rule that holds in every repo goes to his own CLAUDE.md. One that a linter or a test could enforce: propose that in place of a line. Record them as one `--decision` ("Proposed rules", each line and where it goes, alternative "write none"), and write only the ones a later `[note]` picks. With nothing to propose, record nothing.

## Updating this skill

Whenever he corrects how the review went — in a thread, a `[note]`, or the terminal, about wording, order, evidence, or setup — change this skill right then: one line, edited into the section it belongs to, the rule and its why in a clause, and record it as a `--decision`. He reviews skill edits as uncommitted changes in the dotfiles repo, so write them, don't propose them. A correction about running difit goes in the difit skill; how something is written goes in `~/.claude/skills/assistant/writing.md`; a fact about the repo goes in its CLAUDE.md if his, else CLAUDE.local.md; how he wants you to work goes in his CLAUDE.md.
