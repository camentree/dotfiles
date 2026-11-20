# Users and sign-in

How the backend authenticates a request, how the frontend signs in under mock auth, and how to give a user the role a task needs.

## Backend

Two ways to authenticate locally, picked by `AUTH_PROVIDER` in the backend's `.env`:

- **With permission checks — prefer this.** `AUTH_PROVIDER=com.august.controllers.auth.JWTOrCookieAuthProvider`, the default. A request carries a bearer JWT signed with the test key (`kid` `my_test_key`, HS256, secret `testKey`) whose `cognito:username` is the user's username_uuid (the `user_account.username` column), or a session cookie from a real login. The backend loads that row and every endpoint checks its permission against the row's roles (`user_groups`), so the UI shows what that role really sees and a missing permission is a real 403. The username_uuid is not the email: a token carrying an email matches no row and every request is a 401.
- **Without permission checks.** `AUTH_PROVIDER=com.august.controllers.auth.ConfigAuthProvider` makes every request the superuser from `auth.provider.configauth.user`, whatever bearer it carries, no row needed. It sits commented out below the active line in `.env`, and the last line for a key wins, so uncommenting it silently turns checks off. Only for when auth itself is in the way; it proves nothing about permissions.

Every startup runs `RootUserCreation`, which makes two superuser rows if missing: `camen@augusthealth.com` (from `EMAIL` in `.env`) and `it+superuser@augusthealth.com`. They are in the seed, so every branch database has them, alongside four service accounts with no email. Rows, groups, and permissions live in your database only; Cognito holds just the identity, and the AWS SDK finds the credentials in `~/.aws`, so creating or editing users needs nothing in `.env`. A username_uuid belongs to one database.

## `bin-local/users`

`<worktree>/bin-local/users`, run from anywhere inside the worktree. It reads this worktree's database and port from the sandbox block of `backend/.env`, which each start copies from `.env.local`. `bin-local/dev` prints its table at each start.

| Command | Does | Needs the server |
| --- | --- | --- |
| `bin-local/users` | active users: id, email, username_uuid, roles with their org and facility scope | no |
| `bin-local/users show <email>` | one user's roles with every permission each grants | yes |
| `bin-local/users set <email> '<groups json>'` | replaces the user's roles, acting as it+superuser | yes |
| `bin-local/users add <orgId> <email> '<groups json>' [given] [family]` | creates a user in the org with those roles | yes |

Groups json is `[{"groupType":"GROUP_TYPE_FACILITY_STAFF","personMatcher":{"organizationId":"30","facilityId":"135"}}]`; an empty `personMatcher` is global. `bin-local/users --help` has the shape too. Role names are the `GroupType` enum in `modules/protos/src/main/protobuf/com/august/protos/permission.proto`; what each grants is `groupPermissionsMap` in `GroupPermissionRepository.scala`, or `bin-local/users show` on a user holding it. Roles are read per request, so a change applies without a restart.

**After starting, pick the user before driving the app.** Read the `bin-local/users` table and choose by the task: a superuser (`camen@` or `it+superuser@`) for general work, a user holding the role under test when the task is about permissions. To test as a restricted role, `set` roles on `camen@augusthealth.com` and keep `it+superuser@augusthealth.com` as the admin: the script edits as it+superuser, so demoting camen never locks it out. Verified: as `FACILITY_STAFF` camen gets 403 on `GET /internal/users`, and 200 again once `set` back to `[{"groupType":"GROUP_TYPE_SUPER_USER","personMatcher":{}}]`. `add` goes through Cognito's shared dev pool, so reuse addresses such as `camen+staff@augusthealth.com` rather than inventing one per run; an address already in the pool is reused (get-or-create), so `add` works in every fresh database. Use `set` on camen when the task only needs someone restricted, `add` when it needs a separate user, or both a superuser and a restricted one at once. `bin-local/dev rm` then `bin-local/dev` restores the seed's users.

Under the hood `set` is `GET /users/<id>`, swap `groups`, `PUT /users/<id>`, and `add` is `POST /organizations/<orgId>/users` with `name`, `email`, and `groups`.

## Tokens

`august-app status --worktree=<worktree> --user=<email>` prints one. Or mint a token for any user row with `../demo-data/bin/python ../demo-data/test_token.py -e camen@augusthealth.com`, run from `loquat/` or `demo-data/`: it reads `../.env` relative to the working directory to find `DB_DATABASE`, which the block sets alongside `DB_NAME`, so the token targets your database. Send it as `Authorization: Bearer`.

## Frontend

`authMethod` in `src/shared/environment.ts` picks how the frontend authenticates:

- `'none'`, for driving the app locally. Set in the `local` block (`august-app` does it) and restart; never commit it. No login form. Every request carries a mock bearer JWT, minted in the browser by `src/shared/api/mockAuth.ts`, for the username_uuid in `sessionStorage` key `mock_auth_username`. If the key is unset the page prompts "Mock Auth Username". The key is per tab.
- `'cookie'`, the `local` block's value on master and every deployed environment. The login form posts to `/userSessions` and the backend sets a session cookie; needs a real Cognito identity with a password.

A git clean filter keeps `'none'` out of every commit: `.git/info/attributes` maps `frontend/src/shared/environment.ts` to `filter=localauth`, whose clean step rewrites `authMethod: 'none'` back to `'cookie'` inside the `local` block only. It is local config, not in the repo, so a fresh clone needs it again: `git config --local filter.localauth.clean "sed \"/^  local: {/,/^  },/ s/authMethod: 'none'/authMethod: 'cookie'/\""`, `git config --local filter.localauth.smudge cat`, then the attributes line.

Under `bin-local/dev` a tab signs in by itself, and `?mock_user=<email or username_uuid>` on any route switches that tab's user and drops the parameter; that is also how to drive Chrome as another user, no prompt involved. Served any other way, a fresh tab shows the "Mock Auth Username" `window.prompt`, which blocks the extension; there, open `/robots.txt` on the same origin, run `sessionStorage.setItem("mock_auth_username", "<username_uuid>")`, then go to the app route.

**The page reloading over and over means the mock user is wrong.** Every API call answers 401, the 401 handler in `src/shared/api/apiClient.ts` logs out and redirects, and the next call 401s again. The backend log shows `No associated session` per request. Causes, most likely first: `mock_auth_username` holds an email or a username_uuid from another database (a tab left open from another branch's stack on the same port keeps its old key and loops against the new backend); the user is inactive; the backend is on a database that lacks the user. Fix the key from the `bin-local/users` table and reload.
