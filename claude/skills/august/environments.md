# Environments

What `bin-local/dev` does, verb by verb and flag by flag, and how to run an app by hand. `august-app` covers the usual start; read this when you need a flag it does not pass, a second server, or to find out why a stack is not what you expected.

**When an isolated run needs something the script doesn't do yet (another service or container, a seed or migration step, an env var), add it to `bin-local/dev` rather than running it by hand.** The script is the definition of a working environment; a step that only lives in someone's terminal history is a step that breaks the next run.

## `bin-local/dev`

One script at the root of a valinor worktree. It acts on the worktree it is called from (`git rev-parse --show-toplevel`), whichever copy of the script is run, and `start` always runs both the backend and the frontend of that worktree. `bin-local/` is untracked, via `.git/info/exclude`, and `wk` links it into every worktree through the root `.worktreeinclude.local` (`wk` reads that file and `.worktreeinclude` at the repo root only, so both list paths from the root).

`bin-local/dev [start] [--api] [--dev] [--tunnel] [--lan] [--user=<email>] [--label=<text>]`, and `bin-local/dev stop | rm | ps | seed [branch]`.

**`.env.local`, at the worktree root, holds the worktree's settings.** The first start writes the database name and every port there; later starts read them back and only add a key that is missing, so a port or the database is changed by editing that file, and the change survives restarts. It is untracked and never linked between worktrees. Each start copies it into the sandbox block of `backend/.env`, which the backend and `sbt` read, so any variable put in `.env.local` overrides `backend/.env`; everything else, secrets included, still comes from `backend/.env` and `frontend/.env`. Optional keys: `DEV_USER`, `DEV_LABEL`, `NGROK_DOMAIN`. A worktree that changes branch keeps its `DB_NAME` and ports: delete the lines to have them hashed again.

One `db`, `rabbitmq`, and `pdf` container serve every worktree. Isolation is per name, not per container: each branch gets its own Postgres database, its own RabbitMQ vhost, and its own port block, all inside those shared containers. Gotenberg is stateless and shared as is.

1. `start` starts the podman machine and the three containers if they are down, runs `seed` if that database is missing, clones `seed` into the database `DB_NAME` names (the branch with slashes turned into dashes), creates vhost `/<name>` with the dead-letter policy, writes `.env.local` where keys are missing, copies it into a block in the worktree's `backend/.env` (a linked `.env` is first replaced by a copy), and prints `bin-local/users`. `.env.local` on a first start:

    ```
    DB_NAME=<name>
    PLAY_HTTP_PORT=<base>
    SOAP_FRAMEWORK_LTC_PORT=<base+1>
    QS1_MLLP_PORT=<base+2>
    METRICS_PORT=<base+3>
    INTEGRATIONS_API_PLAY_HTTP_PORT=<base+4>
    API_INTEGRATIONS_METRICS_PORT=<base+5>
    TEST_SOAP_PORT=<base+6>
    TEST_MLLP_PORT=<base+7>
    TEST_METRICS_PORT=<base+8>
    FRONTEND_PORT=<3000-3899>
    ```

    `<base>` is hashed from the branch name into 10000-14990 and the frontend port into 3000-3899, so a new worktree of the same branch gets the same ports. The block in `backend/.env` is these lines between `# sandbox begin` and `# sandbox end`, with `DB_DATABASE` and `RABBITMQ_VHOST` added. Read a port from `.env.local` whenever you need one.
2. The backend: `sbt stage` on the worktree's warm sbt server (log `backend/loquat/logs/sbt-stage-backend.log`), the staged app copied to `$TMPDIR/loquat-staged/<name>/loquat`, and the copy run in the background with a database pool of 5, its output in `backend/loquat/logs/dev-backend.log`. Starting the app is the compile, and once the stage finishes the sbt server is free for tests or anything else, and later compiles never touch the running app. The script waits for `/ping`, which answers `{"data":{"I pong":"therefore I am"}}`. A backend of this worktree that is already up is reused, and left running when the script ends; if some other process holds the port it says which and stops.
3. The frontend: sets `authMethod: 'none'` in the `local` block of `frontend/src/shared/environment.ts`, runs `yarn install --immutable`, copies `bin-local/vite.local.config.ts` into `frontend/node_modules/.bin-local/` (its imports have to resolve from the frontend's `node_modules`), and runs vite in the foreground on `--host 127.0.0.1` against that backend's port. Ctrl-c, or ending the shell that started it, stops vite and the backend this run started.
4. Done for the day: `stop` kills the worktree's backend, frontend, difit servers, and sbt server (the sbt server keeps the `.env` it loaded at startup and would otherwise reuse stale ports and database on the next `sbt` command). The database, vhost, and block stay, so the next `start` is a warm database and a cold compile. Done with the branch: `rm` is `stop` plus dropping the database (with its users and roles) and vhost and removing the block; `wk rm` runs it before removing the worktree. The `seed` template, the containers, and the worktree stay.

- `start` again while the frontend is up prints "Already running", starts whatever else is down (the backend, `--api`, `--tunnel`) and holds it; if another process holds `FRONTEND_PORT` it says so and stops. `FRONTEND_PORT=<port>` in front of the command, the one setting the shell can override, runs a second frontend beside the first against the same backend.
- `--api` also stages and starts the external API (api integrations) on `INTEGRATIONS_API_PLAY_HTTP_PORT`, log `backend/loquat/logs/dev-api.log`, health `/ping` and `/ping/db`. By hand it is `sbt "apiIntegrations/run <port>"`; a bare `sbt apiIntegrations/run` ignores the variable and binds 9003.
- `--dev` runs the backend, and the external API with `--api`, as `sbt run` in dev mode in a JVM of its own (`SBT_NATIVE_CLIENT=false`), which recompiles on a request after a code change, instead of the staged copy.
- `--tunnel` opens ngrok on `NGROK_DOMAIN` (`.env.local`, then `backend/.env`, then the shell) to the backend's port, for HelloSign callbacks, log `backend/loquat/logs/ngrok.log`; it ends with the run, and `stop` kills it too. The ngrok account, domain, and HelloSign app setup are on the "Ngrok Configuration" page in Notion.
- A database whose evolutions need downs (the backend log says "needs evolutions, including downs!") is fixed, when the data is yours to change, by one start with `JAVA_OPTS=-Dplay.evolutions.db.default.autoApplyDowns=true` in front; otherwise `rm` and start again for a fresh copy of the seed.
- `--label=<text>` sets the chip's text; the branch name is the default. The chip is a script `vite.local.config.ts` injects into the served HTML, with the signed-in mock user's roles from the backend database's `user_account` and `user_groups`, e.g. `camen/mov-422-04-add-move-in · super user`. A key from another database reads "(not in this database)".
- `--user=<email>` changes who a fresh tab signs in as (default `AUGUST_DEFAULT_USER`): the same injected script sets `mock_auth_username` before the app's modules run, so the "Mock Auth Username" prompt never shows.
- `--lan` serves `0.0.0.0` and points API calls at the machine's LAN address, for reading the UI from another device only.
- `ps` lists every worktree with its database and whatever is up: `sbt:<pid>`, `loquat:<port>`, `api:<port>`, `frontend:<port>`, `tunnel`, `difit:<ports>`, then databases with no worktree.
- `seed` drops the `seed` template and clones `generations`; `seed <branch>` stops that branch's servers and clones its database instead.

By hand, against a backend already running, from `frontend/`: `BACKEND_PORT=<port> yarn start` for the main app on 3000, `yarn start:careapp` on 5173, `yarn start:emar` on 5174; without `BACKEND_PORT` the app calls 9000. Vite doesn't typecheck, so run `yarn tsc -w` beside it. The backend by hand is `sbt run` from `backend/loquat`: port `PLAY_HTTP_PORT`, SOAP on `SOAP_FRAMEWORK_LTC_PORT`, MLLP on `QS1_MLLP_PORT`, health `/ping` and `/ping/db`.

Traps:

- **Drive from `127.0.0.1`, never the LAN address or `localhost`.** `mockAuth.ts` signs its JWT with `crypto.subtle`, which exists only in a secure context. `http://192.168.50.96:3000` is not one, so `crypto.subtle` is `undefined`, no token is ever minted, and the app sits on the loading modal forever: blank body, zero requests to the backend, nothing in the console. It looks like a hung build, not an auth problem.
- **Two dev servers can share port 3000.** Vite without `--host` binds `[::1]` and with `--host 0.0.0.0` binds IPv4 `*`, so a second stack starts happily beside the first and `--strictPort` says nothing. macOS resolves `localhost` to `::1` first, so `http://localhost:3000` reaches whichever one is on IPv6: a different worktree, a different backend, a different database, with no sign anything is wrong. `127.0.0.1:3000` is unambiguous. Check with `lsof -iTCP:3000 -sTCP:LISTEN -n -P`.
- Frontend logs are the terminal only. Browser errors go to Sentry, which is off locally.
- The `db` container's data volume is `pvlocal/pgdata-14` under `~/Projects/august-fullstack/august-backend`, where it was created: that folder has to stay on disk until the database is moved (`database.md`).
