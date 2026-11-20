---
name: august
description: How to run and get around the August apps on this machine - starting the backend, the frontend and Experimental Tools for a branch, signing in as the right user, putting data in place, and finding your way through the UI from a script. Read it before using a running August app for a proof, a check, or a demo, and add what you had to work out.
---

# August

What any agent needs to run the August apps and move around in them. What is true of one screen or one feature does not belong here; that goes in your agent memory, or stays in the task.

Two repos: valinor (`augusthealth/valinor`, primary checkout `~/Projects/valinor`), which holds the backend in `backend/` and the frontend in `frontend/`, and Experimental-Tools. `<worktree>` below is a valinor worktree, `~/Projects/.valinor-worktrees/<branch>` from `wk <branch>`, so a branch's backend and frontend are one checkout.

`bin-local/` at the worktree root is Camen's, untracked: it lives in the primary checkout and `wk` links it into each worktree through the root `.worktreeinclude.local`. Run its scripts from anywhere inside the worktree they should act on.

On this machine this skill wins over the frontend's checked-in `run-august-frontend`, which assumes a backend on port 9000 and a different sign-in.

## Running

The apps start through `bin-local/dev`, never by hand. It runs the backend and the frontend of the worktree it is called from, always both: the backend staged in the background (log `backend/loquat/logs/dev-backend.log`), then vite in the foreground, and ending it stops both. Each branch gets ports and a database of its own, named from the branch, so two tasks never share state.

From a session, start them with `bash ~/Projects/dotfiles/claude/scripts/august-app start --worktree=<worktree>` as a background shell, so they end with the session, then `august-app wait` with the same options in the foreground. It runs `bin-local/dev` with the connection check, `AWS_PROFILE` and the system yarn, and prints the URLs, the user a fresh tab signs in as, a bearer token, and the stop command; `status` prints them again, `--user=<email>` for another user, and `--api`, `--dev`, `--tunnel` and `--lan` go through to `bin-local/dev`. Without `--worktree` it is the worktree you are in.

| App | From | Command | Ready when |
| --- | --- | --- | --- |
| Backend and frontend | `<worktree>` | `bin-local/dev` | `curl -X GET localhost:<PLAY_HTTP_PORT>/ping` answers, then the app root on the branch's port |
| Experimental Tools | `<tools worktree>` | `bin-local/dev --tools=<branch>` | Vite prints its URL |

- `--api` also starts the external API (api integrations) on `INTEGRATIONS_API_PLAY_HTTP_PORT`, `--dev` runs the backend in sbt dev mode, which recompiles on a request after a code change, and `--tunnel` opens ngrok on `NGROK_DOMAIN` for HelloSign callbacks.
- A worktree's ports and database name are in `.env.local` at its root, written by the first start and only read after that: change a port there, never with a flag. Each start copies the file into the sandbox block of `backend/.env`, so a variable put in `.env.local` overrides `backend/.env` for the backend and for `sbt`.
- Running a Tools import (not its preview) uploads the file to S3 and answers 500 "Something went wrong!" while the AWS SSO session is expired. Check `aws sts get-caller-identity --profile us-developer` before recording one, but do not trust a success there: it answered with the role while the Java SDK in the app and tests still failed with "The SSO session associated with this profile has expired" (the CLI's cached role credentials outlive the SSO token). Only Camen can run `aws sso login`, which opens a browser.
- The shared Postgres allows 200 connections. `bin-local/dev` now starts loquat with a pool of 5 (about 15 connections), but backends started before that hold about 40 each, and when the slots run out a start fails with "remaining connection slots are reserved" (a `TimeoutException` in `ensureStartupUsersExist`). Before starting one, check `docker exec db psql -U postgres -Atc "select count(*) from pg_stat_activity"` is under about 185; never stop someone else's backend to make room.
- Ports are never 9000 or 3000. They are in the worktree's `.env.local` (`PLAY_HTTP_PORT`, `INTEGRATIONS_API_PLAY_HTTP_PORT`, `FRONTEND_PORT`), and `august-app status` prints them.
- A frontend always runs against the backend of its own worktree. The Tools script sets up a backend of the same branch name; its `--backend=<branch>` points at another.
- Master is the primary checkout, `~/Projects/valinor`, on port 12930 with database `master`; start it there with a plain `bin-local/dev`. If it dies on "needs evolutions, including downs!", another branch applied a newer evolution to the `master` database (compare `select max(id) from play_evolutions` with `backend/loquat/conf/evolutions/default`): run a backend of the task's branch name instead, and never apply the downs, which would drop another session's column.
- The frontend's types are the checked-in sources in `backend/protos/typescript/src`, linked as `@augusthealth/models`: a task that changes a proto runs `./bin/proto-to-typescript` from the worktree root and commits what it writes, or CI's `Check Generated Models` fails.
- The machine's `yarn` is corepack's, so it runs the Yarn 4 that `packageManager` in `frontend/package.json` pins. No `nix develop` needed. The install reads `FONTAWESOME_PACKAGE_TOKEN` from `frontend/.env` and needs no GitHub token. If `yarn --version` says 1.22, a mise yarn pin from an old `.tool-versions` is ahead of corepack on `PATH`: start with `export PATH=/run/current-system/sw/bin:$PATH` in front, whose `yarn` follows the pin.
- Postgres truncates a branch database's name to 63 characters, so a long branch's database shows under the cut name in `psql -l`. Connecting with the full name still works.
- Mock sign-in needs `authMethod: 'none'` in the `local` block of the worktree's `frontend/src/shared/environment.ts`, left uncommitted; a new worktree has `'cookie'` and `bin-local/dev` sets it at each start. The `localauth` clean filter (`users.md`) keeps it out of commits: `git status` lists the file as modified, but `git diff` is empty and `git add` stages nothing. Jest reads that same `local` block, so with `'none'` component tests fail on "Not implemented: window.prompt": set it back to `'cookie'` while running `yarn test`.
- A feature flag is turned on for one community with `POST <backend>/featureFlags/<id>/featureFlagConfiguration` `{"enabled":true,"configurationTargetId":<facilityId>,"configurationTargetType":"Facility"}`, all three fields required; the id is in `GET /featureFlags`.
- A resident made through `POST .../facilities/<id>/people` needs `admissionsInformation.startDate`, and comes with its own Self contact.
- The backend runs as a staged copy (`$TMPDIR/loquat-staged/<name>`) of the worktree as it was at start. To restart only the backend, kill the java pid `lsof -nP -iTCP:<PLAY_HTTP_PORT> -sTCP:LISTEN` names, then `bin-local/dev` again, which stages and starts it and, finding the frontend up, holds the backend until it is ended; `bin-local/dev stop` would also kill the warm sbt server.
- A worktree whose `backend/.env` has no `AWS_PROFILE` line uses the default AWS profile, whose token is invalid: put `AWS_PROFILE=us-developer` in front of a hand-started `bin-local/dev` and `sbt "it-only ..."`, or KMS calls (the example import sheet's SSNs, uploads) fail.
- `august-app stop --worktree=<worktree>`, or `bin-local/dev stop` inside it, stops that worktree's backend, frontend, sbt server and difit servers, and nothing else.
- After a backend code change, stop and start again. `bin-local/dev stop` ends a worktree's servers; `bin-local/dev rm` also drops its database, and `wk rm` runs it.
- A step the scripts do not do yet is added to the script, not run by hand.

- When Camen asks to see something running, do the whole thing without asking: start the backend and frontend, sign in, open the page the change lives on and whatever modal or panel the change is in, so he finds it on screen, then give him the `http://127.0.0.1:<port>/...` URL, which signs in by itself in his browser too. The move-in modal is `/orgs/30/facilities/135/prospects` → "Add New".

More detail lives beside this file; read the one that fits when this page does not settle it (repository paths, not yet linked under `~/.claude`):

- `~/Projects/dotfiles/claude/skills/august/environments.md`: every verb and flag of `bin-local/dev`, the sandbox port block, the sbt stage, starting an app by hand, and the `localhost`/LAN/port-3000 traps. Read it for anything `august-app` does not do.
- `~/Projects/dotfiles/claude/skills/august/users.md`: how backend auth and frontend mock auth work, the `bin-local/users` commands and groups json, minting a token, and the reload loop. Read it for a task about permissions or a sign-in that fails.
- `~/Projects/dotfiles/claude/skills/august/seed-data.md`: the seed's orgs and communities, the `demo-data` scratch script for adding state, and rebuilding the seed. Read it before creating data.
- `~/Projects/dotfiles/claude/skills/august/browser.md`: chrome-devtools and CDP traps, `bin-local/dev-browser`, the PDF editor, `Listbox`. Read it before driving the frontend from chrome-devtools.
- `~/Projects/dotfiles/claude/skills/august/database.md`: the shared Postgres under podman, connection limits, out-of-memory kills, and recovery. Read it on a database or queue error.

Experimental-Tools' own CLAUDE.local.md "Local Development" has its detail.

## Signing in

- The frontend is reached at `http://127.0.0.1:<port>`, never `localhost` or the LAN address: sign-in fails silently on both.
- A fresh page signs in by itself as camen@augusthealth.com, a super user. `?mock_user=<email>` on any URL switches that tab to another user.
- `<worktree>/bin-local/users` lists the users with their roles. `bin-local/users set <email> '<groups json>'` changes a user's roles, and `add` creates one, for a task about permissions. `add` goes through Cognito and fails while the AWS SSO session is expired (the backend log says so at start); `set` on camen@ works without it, and set him back to `GROUP_TYPE_SUPER_USER` afterwards.
- A role changed with `users set` shows at the next page load, in the app and in the chip: the frontend reads the roles again for every page it serves.
- A branch with no worktree: `wk <branch>` from `~/Projects/valinor` (run as `zsh -ic "wk '<branch>'"`, whose last line is the path), then `bin-local/dev` there, which gives it a database from `seed`; a first build takes about three minutes with the primary checkout's build output to copy, far longer without.
- A frontend started with `bin-local/dev --lan` cannot be driven by a scripted browser: on `127.0.0.1` its API calls go to the LAN address and fail ("Internet problems"), and on the LAN address the app never boots (page error "Crypto is not available", loader forever, with `'none'` and with `'cookie'`). Keep the `--lan` one for Camen and record against a second server of the same worktree, `FRONTEND_PORT=<another> bin-local/dev`, on `127.0.0.1` with `authMethod: 'none'`.
- The LAN address changes when the machine changes network: read `ipconfig getifaddr en0` again before handing over a LAN URL, and restart a `--lan` frontend started under the old address.
- After a merge that changes `yarn.lock`, restart the frontend dev server: one left running across the reinstall stops answering page loads.
- When the frontend branch's own port is already held by another server of the same worktree, `bin-local/dev` prints "Already running" and starts no second frontend; `FRONTEND_PORT=<another>` in front of the command runs one beside it.
- A page that reloads over and over has the wrong user for that database.
- A call straight to the backend carries `Authorization: Bearer <token>`, for that worktree's database only: `august-app status --worktree=<worktree> --user=<email>` prints one for any active user, good for eight hours. The external API takes the same token; the superuser needs no extra per-user flag for contact writes.
- A machine API user (`GROUP_TYPE_API_FULL_READ` and the other `GROUP_TYPE_API_*`) is a 400 "not supported by this endpoint" from `bin-local/users add`: add it as `GROUP_TYPE_FACILITY_STAFF`, then `bin-local/users set` it to the API group. `API_FULL_READ` on org 30 / facility 135 reads the external person and census endpoints.
- Experimental Tools signs in with a username and password, with MFA on a 409.

## Data

- Every branch database is a copy of the same seed: five orgs with their communities, residents, prospects, contacts, billing sources and medications. Use Oak River Villas, org 30 facility 135. Org 1 / facility 1 does not exist. No resident in the seed has a SELF contact.
- Data the seed lacks is created through the backend's API on the task's own port, with the client and builders in the backend's `demo-data`. SQL only for what the API cannot reach, through `docker exec -it db psql -U postgres <database>`; `bin/psql` reaches `generations`, which no branch uses.
- A feature that seems missing may be behind a flag that is off for that community: check `GET <backend>/organizations/<orgId>/facilities/<facilityId>/enabledFeatureFlags`.
- A current resident POSTed to `/organizations/<orgId>/facilities/<facilityId>/people` needs `admissionsInformation.startDate`, or it is a 400 "A resident must have a move-in date"; creating one also creates its Self contact with the resident's telecoms. The body: `{"name":[{"given":["Ann"],"family":"Lee"}],"residentStatus":"RESIDENT_STATUS_CURRENT_RESIDENT","admissionsInformation":{"startDate":{"year":2025,"month":1,"day":1}},"telecom":[...]}` (`family` is a string, not a list).
- A person `PATCH` takes `Content-Type: application/merge-patch+json` and answers 200 to a field Person does not have (such as `preferredName`), changing nothing: read the field back from the response before calling an update shown. `{"gender":"GENDER_FEMALE"}` is a real non-name change.
- Backend responses wrap the body in `{"data": ...}`.
- A job is queued with `POST /queueJob` and the payload's oneof name in camelCase, e.g. `{"demoteExtraSelfContacts":{"dryRun":true}}` (answers `queued`); it runs within a second in the dev server, and its log lines are JSON in the worktree's `backend/loquat/logs/application.log`, with `"august.job"` naming the job. A whole-database job also touches other sessions' data on that branch database, and the log can interleave another session's run of the same job: keep a line only by its `dryRun` and `orgId`.
- People and contacts are read from the `proto_value` bytea column, not `json_value`: an SQL edit to the JSON changes nothing a GET returns. To store a telecom the API refuses (a blank value, an invalid email), append the encoded entry to the proto, which adds one more element to the repeated field: `update people set proto_value = proto_value || '\x<hex>'::bytea where id = <id>`, with `<hex>` from `python3 -I ~/.claude/skills/august/telecom_hex.py 14 'EMAIL=not an email' 'FAX=   '` (field 14 for a person, 8 for a contact).
- A person's last update (`people_last_updates`) is read with `GET .../facilities/<fid>/peopleStats?residentStatus=RESIDENT_STATUS_CURRENT_RESIDENT`, as `lastUpdate` per entry; audit events with `GET /organizations/<orgId>/auditEvents?startDate=<YYYY-MM-DD>&endDate=<same>&resourceType=CONTACT&limit=500`, whose `auditScope.applicationUrl` ends in `/residents/<personId>`.
- No seed resident has a recommended care rate: the inherited level-of-care settings carry no `billingItemId`. Give facility 135 its own with `POST /orgFacilitySettings` `{"orgId":"30","facilityId":"135","settingsType":"SETTINGS_TYPE_LEVEL_OF_CARE_SETTINGS","settings":{"levelOfCareSettingsList":{"careLevelsByAdmissionType":[...]}}}`, copied from `GET /orgFacilitySettings/inherited/SETTINGS_TYPE_LEVEL_OF_CARE_SETTINGS?orgId=30&facilityId=135` with `"billingItemId":"5"`..`"8"` on the four assisted living levels (AL - Care Level 1-4, $500-$1,500). Then create the resident with `"levelOfCare":{"value":<n>}`, `admissionsInformation.admissionType` `ADMISSION_TYPE_ASSISTED_LIVING` and `negotiatedRate` in cents; `GET .../people/<id>/recommendedCareRate` reads it back.
- Two residents are linked with `POST .../facilities/<fid>/personLinks` `{"primaryPersonId":<id>,"secondaryPersonId":<id>,"relationship":"CONTACT_RELATIONSHIP_SPS"}` once `linked_residents` is on for the facility.
- An org is made inactive only by SQL: `update organizations set is_active = false where id = <id>`; all five seed orgs are active. Set it back after.
- A state form (VA UAI, CA 601, ...) applies by the community's state: `PATCH /organizations/30/facilities/136` with `{"address": {...the existing address, "state": "VA"}}` (merge-patch), then `GET .../people/<id>/forms/<DATA_TYPE>.json` gives the filled fields and `.pdf` the form. Seed communities are all CA.
- A contact POSTed to `.../people/<id>/contacts` takes `name` and `relationship` (proto enum names, e.g. `["CONTACT_RELATIONSHIP_PERSONAL","CONTACT_RELATIONSHIP_SELF"]`) and no `category`: an unknown field is a 400 "Cannot find field".
- An outbound HL7 pharmacy message is captured locally in minutes: `POST .../facilities/<id>/pharmacyIntegration` a `PHARMACY_PARTNER_REDSAIL_QS1` facility with `supportedOutboundMessageTypes: ["HL7_MESSAGE_TYPE_ADT_A08"]` and `partnerSpecificConfiguration.redsailQs1.clientConfig` pointing at a local MLLP listener that ACKs (`python3 ~/.claude/skills/august/mllp_listener.py <port> <output file>`, which appends each message to the file); any resident PATCH then sends an ADT A08 within a second.
- A contact is made the responsible person with `PUT .../people/<pid>/contacts/responsibleParty/<contactId>` (no body; works with AWS SSO expired); adding the RP relationship through the contact PATCH is a 400. The contacts GET has no `isResponsibleParty` field: read RP as `CONTACT_RELATIONSHIP_RESPONSIBLE_PERSON` in `relationship`. A payer is a contact PATCH adding `CONTACT_RELATIONSHIP_FINANCIAL_PAYMENT_OF_CARE`.
- A resident's SELF contact cannot be deleted through the API (400) on branches with the one-Self constraint. For a resident without one, edit SELF off it with a contact PATCH `{"relationship":["CONTACT_RELATIONSHIP_PERSONAL","CONTACT_RELATIONSHIP_CHILD"]}`: `PERSONAL` alone, or with `FRIEND`, is a 400 "Requires a relationship that matches the category Personal".
- Branches with the `contacts_one_self_per_person` unique constraint on `(person_id, is_self)` cannot hold two SELF contacts, even by SQL; it is deferred, so test a copy with `set constraints all immediate` inside a rolled-back transaction. On older branches, a second one is made by copying the row: `insert into contacts (org_id, facility_id, person_id, json_value, proto_value) select org_id, facility_id, person_id, json_value, proto_value from contacts where id = <selfId> returning id`, then shaped through the contact PATCH.
- Helper scripts with `local path=...` break when sourced in zsh (`path` is zsh's PATH array, so `curl` disappears): run them with `bash`.
- The sandbox block in `backend/.env` is rewritten from `.env.local` at each start: read and change ports in `.env.local`, not in the block.
- People's names take letters only. For a row unique to a run, build a suffix from letters, not digits.

## Getting around the frontend

- A community's pages live under `/orgs/<orgId>/facilities/<facilityId>/`, and a person's under that at `/residents/<id>/` or `/prospects/<id>/`.
- Vite compiles each route on first load, so a first visit to a page can take longer than ten seconds. Allow thirty.
- A list is ready when `table tbody tr` has a first row. A sortable column sorts by the `button` inside its `columnheader`.
- A dropdown opens from the button that follows its combobox (`xpath=following-sibling::button[1]`): click it, type to filter, click the `option`.
- A dialog's fields are found inside the dialog, by role and name. In a long dialog the sticky footer covers fields near the bottom, so click the element, not a coordinate.
- Every served page carries a chip in the bottom right corner naming the branch and the signed-in user's roles. A recording showing the wrong chip is of the wrong stack.

## Getting around Experimental Tools

- Every tool is a route with query parameters, so a state is reached by URL: `/task-explorer?orgId=&fId=&pId=&taskId=`, `/org-facility-settings?orgId=&fId=`, `/task-definer?dataType=&customType=`, `/template-search?templateId=`.
- Recurring Charge Import writes real billing data when dry run is unchecked. Leave it on.

If something here is wrong or missing, fix it as you find it: one line per fact, written as an instruction, with the command or selector that worked. Correct a line that turned out wrong and delete one that no longer holds. What is true of only one screen goes in your agent memory, not here.
