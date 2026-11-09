---
name: abulafia
description: Get an answer from production data through Abulafia, the company's read-only data agent, when planning or investigating depends on what the data looks like. Never calls it unasked. Drafts the question, asks Camen whether to send it or hand it to him, and if he takes it writes the brief he opens an Abulafia session with.
---

# Abulafia

Abulafia is a separate agent that runs inside the company's AWS account. It reads a copy of the production database in Snowflake (about fifteen minutes behind), the backend and frontend source, and the engineering docs, and it writes its own SQL. This session runs outside that account, so only aggregates may come back.

Never call it on your own. Draft, ask, then do what Camen picks.

## Draft

Write the one question you would send. It has to stand alone, because a call is a fresh session that knows nothing about this one:

- Say what to count and how to split it: "how many residents have exactly one self contact, split by whether its phone matches the person record's phone after stripping formatting".
- Describe the data in the application's terms, with table and field names from `Tables.scala` or the protos when you know them. Don't write Postgres SQL: Snowflake's dialect and its JSON columns differ, and Abulafia looks the schema up itself.
- Batch related counts into one question.
- End it with: "Answer with counts only, plus the query you ran. No rows, names, phone numbers, emails, addresses, free text or clinical fields."

## Ask Camen

One AskUserQuestion. The dialog may be all he sees, so it carries the decision the answer feeds in a sentence and the drafted question in full. Two options:

- **Send it**: you run the drafted question once and report the number. Fast, but Abulafia answers exactly what was asked and nothing around it.
- **I'll take it to Abulafia**: he works it interactively, so it can be asked what he wants to know rather than the query you guessed would answer it. Slower, and the work that depends on it waits for him.

Put Send it first when the question is one well-defined count. Put I'll take it first when the shape of the data is unknown, the answer is likely to raise a follow-up, or the question is really "what should we do about X".

## If he says send it

1. `abulafia-session status` prints `{"expiresAt": ..., "secondsLeft": ...}`. Under 600 seconds left, go to Session expired and don't call.
2. `abulafia -p "<the drafted question>"`, 5 minute timeout. The answer is the last thing on stdout. `MCP: Failed to connect ...` lines are logins he hasn't done; they don't affect data questions.

His yes covers that one question. A follow-up is a new draft and a new ask.

## If he takes it

Write the brief he pastes into an Abulafia session, print it, and put it on the clipboard. It is the question he wants answered, not your query:

- **The decision.** What is being decided and what each answer would change, in product terms, two or three sentences.
- **What we know.** What the ticket and the code say today, and where each fact came from.
- **What we don't.** The open question in plain words, and why it can't be read off the code.
- **Where to look.** The tables, fields and proto messages you think are involved, marked as guesses.
- **Latitude.** "If a different cut of the data answers this better, say so and use it. Ask me when something is ambiguous instead of picking."
- **Handing back.** "When we are done, write a summary I can paste into another session: the counts and splits, the queries, and the caveats. No names, phone numbers, emails, addresses, free text or clinical fields."

Then carry on with the work that doesn't depend on the answer. When he pastes the summary back, use it as below.

## What may come back

Counts, ids, statuses, timestamps, table and column names, and the query. If an answer carries a name, a contact detail, free text or anything about a resident's health, don't repeat it in a reply, a file, a plan or a commit, and tell Camen it happened.

## Use the answer

Put the number and the query Abulafia cited where the decision is recorded, the plan's Decisions when there is a plan. A surprising number is a question about the query, not a fact: read the SQL it cited before building on it.

## Limits

- Data questions only. Log searches (CloudWatch bills by bytes scanned), Sentry triage and anything that writes are Camen's to start.
- One `SELECT` per query, at most 1,000 rows, nothing newer than about fifteen minutes.
- Every call costs model time and warehouse seconds.

## Session expired

The sign-in lasts about twelve hours and needs Camen: an MFA code today, a browser login once Abulafia moves to SSO. Don't retry. Ask him once to run `abulafia-session login <code>`, or whatever `abulafia doctor` names as the fix, and carry on with the work that doesn't depend on the answer.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.
