# When to push and when to post

Read by `/review` and `/address-comments` before any `git push` and before anything is posted on GitHub. Nothing leaves this machine until he says so, and the rows below are the only ways he says so. A difit comment counts as his word only in these forms; anything else in difit is a comment to answer in difit.

His markers are the first word of a line in a difit comment, not only its first line (he wrote `done with review` above `comment:`, 2026-11-25): `post:`, `accept:`, `changes:` (older: `reject:`), `comment:`; the text after the marker is what's posted. They reach you one at a time through the difit comment monitor armed on `[reviewing]` (the difit skill's Reading his comments; send comments was removed 2026-11-25): act on each as it lands.

## A teammate's pull request

Never push to their branch.

| He does | You do |
|---|---|
| `post: <text>` in a thread | Hold it. It is a new comment on that line, or a reply when the thread mirrors a GitHub thread. Posted only with a verdict. |
| `accept: <summary>`, `changes: <summary>` or `comment: <summary>` | Check the summary and every `post:` against the code and what was run. All right: post one review now (approve, request changes, or comment; his summary; every `post:` comment), then the replies. One wrong: post nothing, raise one `--question` with the revision. |
| Comments with no verdict | Answer his threads in difit. Post nothing. |
| "post it" typed in the conversation (or a `[publish]` that still arrives) | Post what is held, with the verdict he gave; with none, ask through `--question`. |

## His own pull request: fixes for review comments, one difit per commit

| He does | You do |
|---|---|
| "looks good", "looks good to me", "lgtm" or `accept:` in a commit's difit, in any thread or wording | That commit only. Push up to it (`git push origin <sha>:<branch>`) when every commit below it is approved too, else say in the thread which one it waits for. Then post the full-hash reply on every reviewer thread that commit addressed, plus each `post:` reply it lets out; no further go-ahead needed (he asked, 2026-11-25). No other commit is covered. |
| `post: <text>` in a thread | His words replace the drafted reply for that GitHub thread. Posted when that commit is pushed, not before. |
| `changes: <text>`, or any request for a change | Agree or say what you would do instead, then a commit of its own. That commit is not pushed until he approves it. |
| "looks good" or `accept:` on every commit's difit | Everything is approved: push it all and post every reply in `replies.json`. The card has no publish button (2026-11-24); a `[publish]` that still arrives means the same. |
| A question or a remark | Answer in the thread. Push nothing, post nothing. |

## His own branch with no pull request yet

| He does | You do |
|---|---|
| Comments in difit | Commit locally. Never push. |
| `accept:` in its difit | Verify, push, open the pull request with the description drafted on the card (`--description-file`); text after `accept:` is a change he wants made to that description first. The card has no publish button (2026-11-24); a `[publish]` with a description that still arrives means the same. |

## Never

- Push because the fixes are ready or the tests pass: ready means ready for his look.
- Post a verdict he did not give, or a reply he has not seen drafted.
- Force-push, amend, rebase, merge, or resolve a reviewer's thread.

## The commands, in exactly these forms

His permission rules match the literal form; another form is refused when the instruction came through difit.

```
gh api -X POST repos/<owner>/<repo>/pulls/<n>/reviews --input <scratchpad>/review.json
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments/<comment id>/replies -f body=<text>
git push origin <sha>:<branch>
```

Run each alone: no `cd … &&`, no variable prefix, `-X POST` never `--method`.

When a push or a post is refused by the permission check, do not try another form: raise it with `--question` ("Push refused: run it yourself or approve it in my terminal?"), so it reaches him on the page.

After anything goes out, `task-set.cjs --doing` says what did: "review posted", "pushed 2 of 5".
