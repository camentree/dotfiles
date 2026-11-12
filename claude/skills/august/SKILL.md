---
name: august
description: How to run and get around the August apps on this machine - starting the backend, the frontend and Experimental Tools for a branch, signing in as the right user, putting data in place, and finding your way through the UI from a script. Read it before using a running August app for a proof, a check, or a demo, and add what you had to work out.
---

# August

What any agent needs to run the August apps and move around in them. What is true of one screen or one feature does not belong here; that goes in your agent memory, or stays in the task.

Paths assume three repos: august-backend, august-frontend, Experimental-Tools. They move when the monorepo lands.

On this machine this skill wins over the frontend repo's checked-in `run-august-frontend`, which assumes a backend on port 9000 and a different sign-in.

## Running

Every app starts through its repo's `bin-local/dev`, never by hand. Each branch gets ports and a database of its own, named from the branch, so two tasks never share state. Start each as a background shell so it ends with the session, and poll for it: no script waits for its server.

| App | From | Command | Ready when |
| --- | --- | --- | --- |
| Backend | `<backend worktree>/loquat` | `bin-local/dev` | `curl -X GET localhost:<PLAY_HTTP_PORT>/ping` answers |
| External API | `<backend worktree>/loquat` | `bin-local/dev --api` | `/ping` on `INTEGRATIONS_API_PLAY_HTTP_PORT` answers |
| Frontend | `<frontend worktree>` | `bin-local/dev` | the app root answers on the branch's port |
| Experimental Tools | `<tools worktree>` | `bin-local/dev --tools=<branch>` | Vite prints its URL |

- Running a Tools import (not its preview) uploads the file to S3 and answers 500 "Something went wrong!" while the AWS SSO session is expired. Check `aws sts get-caller-identity --profile us-developer` before recording one; only Camen can run `aws sso login`, which opens a browser.
- Ports are never 9000 or 3000. The backend's are in the sandbox block of its worktree's `.env`; the frontend prints its own, and it is fixed per branch.
- The frontend and Tools scripts set up a backend of the same branch name. `--backend=<branch>` points either at another backend branch.
- The frontend's types come from the published models package. A task that changes a proto starts the frontend with `--backend-protos`.
- A frontend branch past "Upgrade to Yarn v4" is started through `nix develop -c`, with `GITHUB_PACKAGE_TOKEN` and `FONTAWESOME_PACKAGE_TOKEN` passed from `.npmrc`: `GITHUB_PACKAGE_TOKEN=$(grep 'npm.pkg.github.com/:_authToken' .npmrc | cut -d= -f2) FONTAWESOME_PACKAGE_TOKEN=$(grep 'npm.fontawesome.com/:_authToken' .npmrc | cut -d= -f2) nix develop -c bin-local/dev`. Its tests run the same way: `nix develop -c yarn test <paths>`.
- Mock sign-in needs `authMethod: 'none'` in the `local` block of the worktree's `src/shared/environment.ts`, left uncommitted; a new worktree has `'cookie'` and `bin-local/dev` only prints a reminder. Say so when handing over, so it is not committed.
- A feature flag is turned on for one community with `POST <backend>/featureFlags/<id>/featureFlagConfiguration` `{"enabled":true,"configurationTargetId":<facilityId>,"configurationTargetType":"Facility"}`; the id is in `GET /featureFlags`.
- A resident made through `POST .../facilities/<id>/people` needs `admissionsInformation.startDate`, and comes with its own Self contact.
- The backend's `bin-local/dev` runs a staged copy (`$TMPDIR/loquat-staged/<name>`) of the worktree as it was at start. To restart one held by another shell, kill the java pid `lsof -nP -iTCP:<PLAY_HTTP_PORT> -sTCP:LISTEN` names, then `bin-local/dev` again; `bin-local/dev stop` would also kill the warm sbt server.
- After a backend code change, stop the backend and start it again. `bin-local/dev stop` ends a branch's servers; `bin-local/dev rm` also drops its database.
- A step the scripts do not do yet is added to the script, not run by hand.

The full detail, with every trap, is in each repo's CLAUDE.local.md: the frontend's "Isolated environment" and "Running for the build loop", the backend's `loquat/CLAUDE.local.md` "Running", and Experimental-Tools' "Local Development".

## Signing in

- The frontend is reached at `http://127.0.0.1:<port>`, never `localhost` or the LAN address: sign-in fails silently on both.
- A fresh page signs in by itself as camen@augusthealth.com, a super user. `?mock_user=<email>` on any URL switches that tab to another user.
- `<backend worktree>/loquat/bin-local/users` lists the users with their roles. `bin-local/users set <email> '<groups json>'` changes a user's roles, and `add` creates one, for a task about permissions. `add` goes through Cognito and fails while the AWS SSO session is expired (the backend log says so at start); `set` on camen@ works without it, and set him back to `GROUP_TYPE_SUPER_USER` afterwards.
- A role changed with `users set` shows at the next page load, in the app and in the chip: the frontend reads the roles again for every page it serves.
- The backend's `bin-local/dev` takes a branch: `<main backend checkout>/loquat/bin-local/dev <branch>` creates the worktree with `wk`, a database from `seed`, and starts it; a first build takes about three minutes.
- When the frontend branch's own port is already held by another server of the same worktree, `bin-local/dev` prints "Already running" and exits without preparing the backend; `--port=<another>` runs a second one beside it.
- A page that reloads over and over has the wrong user for that database.
- A call straight to the backend carries `Authorization: Bearer <token>`. Mint one from `loquat/` with `../demo-data/bin/python ../demo-data/test_token.py -e <email>`; it is for that worktree's database only. A worktree has no `demo-data/bin/python`: use the main checkout's, `~/Projects/august-fullstack/august-backend/demo-data/bin/python -c "import jwt; print(jwt.encode({'cognito:username': '<username_uuid>'}, 'testKey', algorithm='HS256', headers={'kid': 'my_test_key'}))"`, with the uuid from `bin-local/users`. The external API takes the same token; the superuser needs no extra per-user flag for contact writes.
- A machine API user (`GROUP_TYPE_API_FULL_READ` and the other `GROUP_TYPE_API_*`) is a 400 "not supported by this endpoint" from `bin-local/users add`: add it as `GROUP_TYPE_FACILITY_STAFF`, then `bin-local/users set` it to the API group. `API_FULL_READ` on org 30 / facility 135 reads the external person and census endpoints.
- Experimental Tools signs in with a username and password, with MFA on a 409.

## Data

- Every branch database is a copy of the same seed: five orgs with their communities, residents, prospects, contacts, billing sources and medications. Use Oak River Villas, org 30 facility 135. Org 1 / facility 1 does not exist. No resident in the seed has a SELF contact.
- Data the seed lacks is created through the backend's API on the task's own port, with the client and builders in the backend's `demo-data`. SQL only for what the API cannot reach.
- A feature that seems missing may be behind a flag that is off for that community: check `GET <backend>/organizations/<orgId>/facilities/<facilityId>/enabledFeatureFlags`.
- A current resident POSTed to `/organizations/<orgId>/facilities/<facilityId>/people` needs `admissionsInformation.startDate`, or it is a 400 "A resident must have a move-in date"; creating one also creates its Self contact.
- A person `PATCH` takes `Content-Type: application/merge-patch+json` and answers 200 to a field Person does not have (such as `preferredName`), changing nothing: read the field back from the response before calling an update shown. `{"gender":"GENDER_FEMALE"}` is a real non-name change.
- Backend responses wrap the body in `{"data": ...}`.
- A state form (VA UAI, CA 601, ...) applies by the community's state: `PATCH /organizations/30/facilities/136` with `{"address": {...the existing address, "state": "VA"}}` (merge-patch), then `GET .../people/<id>/forms/<DATA_TYPE>.json` gives the filled fields and `.pdf` the form. Seed communities are all CA.
- A contact POSTed to `.../people/<id>/contacts` takes `name` and `relationship` (proto enum names, e.g. `["CONTACT_RELATIONSHIP_PERSONAL","CONTACT_RELATIONSHIP_SELF"]`) and no `category`: an unknown field is a 400 "Cannot find field".
- An outbound HL7 pharmacy message is captured locally in minutes: `POST .../facilities/<id>/pharmacyIntegration` a `PHARMACY_PARTNER_REDSAIL_QS1` facility with `supportedOutboundMessageTypes: ["HL7_MESSAGE_TYPE_ADT_A08"]` and `partnerSpecificConfiguration.redsailQs1.clientConfig` pointing at a local MLLP listener that ACKs (`~/.claude/tasks/self-contact-read-pharmacy.proof/mllp_listener.py`); any resident PATCH then sends an ADT A08 within a second.
- A SELF contact can be removed with `DELETE .../people/<id>/contacts/<contactId>`, for a resident without one.
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
