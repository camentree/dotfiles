# Environments

What each repo's `bin-local/dev` does, flag by flag, and how to run an app by hand. `august-app` covers the usual start; read this when you need a flag it does not pass, a second server, or to find out why a stack is not what you expected.

**When an isolated run needs something the scripts don't do yet (another service or container, a seed or migration step, an env var), add it to `bin-local/dev` rather than running it by hand.** The script is the definition of a working environment; a step that only lives in someone's terminal history is a step that breaks the next run.

## Frontend: `bin-local/dev`

Runs the frontend isolated to a branch, against a backend of its own. The backend is a separate process in another shell: `<backend worktree>/loquat/bin-local/dev`.

| Invocation | Frontend | Backend |
| --- | --- | --- |
| `bin-local/dev` | checkout you're in | branch of that checkout |
| `bin-local/dev --frontend=camen/mov-430` | `wk` worktree for `camen/mov-430` | `camen/mov-430` |
| `bin-local/dev --backend=camen/mov-415-backend-person` | checkout you're in | `camen/mov-415-backend-person` |
| `bin-local/dev --frontend=camen/mov-430 --backend=camen/mov-415-backend-person` | `wk` worktree for `camen/mov-430` | `camen/mov-415-backend-person` |

- Both flags take `--flag=value` or `--flag value`. Every worktree goes through `wk`, so a branch that doesn't exist is created from `origin/master` and one that does is reused. The backend branch defaults to the frontend branch, which is what keeps the database isolated per frontend branch.
- Ports are chosen for you: the backend takes a nine-port block from 10000 up, and the frontend a port in 3000-3899, both hashed from the branch name, so a branch's ports follow from its name and nothing else. Two worktrees run side by side without either naming a port. A worktree runs one dev server: `bin-local/dev` again while it is up prints the URLs and exits, and if another branch's server happens to hold the hashed port it says so and stops; `--port=<port>` then.
- It sets up the backend branch's database and port block (`loquat/bin-local/dev --no-start` there), prints the users to sign in as, installs, and then becomes the vite process in the foreground on that backend's port: ctrl-c stops it, and it dies with the shell that started it. Either order with the backend works once the database exists; whichever starts first does the shared setup. Then `curl -X GET http://localhost:<PLAY_HTTP_PORT>/ping` answers `{"data":{"I pong":"therefore I am"}}`.
- `@augusthealth/models` is the published package unless `--backend-protos` generates it from the backend branch; most feature work does not need that. When `node_modules/@augusthealth/models` is such a symlink, the reinstall uses `--check-files` on Yarn 1 only; Yarn 4 rejects that flag, so there it drops `node_modules/.yarn-state.yml` and runs `yarn install --immutable` instead.
- `--rm` stops that backend and drops its database and vhost.
- `--label=<text>` sets the chip's text; the frontend branch name is the default. The chip is a script `bin-local/vite.local.config.ts` injects into the served HTML, with the signed-in mock user's roles from the backend database's `user_account` and `user_groups`, e.g. `camen/mov-422-04-add-move-in · super user`. A key from another database reads "(not in this database)".
- `--user=<email>` changes who a fresh tab signs in as (default `camen@augusthealth.com`): the same injected script sets `mock_auth_username` before the app's modules run, so the "Mock Auth Username" prompt never shows.
- It serves on `--host 127.0.0.1`, so `127.0.0.1:<port>` answers; without it vite binds only `[::1]` and `127.0.0.1` refuses the connection. `--lan` serves `0.0.0.0` instead, for reading the UI from another device only.
- `bin-local/` is untracked, via `.git/info/exclude`, and `wk` links it into every worktree through `.worktreeinclude.local`.

By hand, against a backend already running: `BACKEND_PORT=<port> yarn start` for the main app on 3000, `yarn start:careapp` on 5173, `yarn start:emar` on 5174; without `BACKEND_PORT` the app calls 9000. Vite doesn't typecheck, so run `yarn tsc -w` beside it. Isolating a second worktree by hand (`bin/create-worktree` for the links, a changed Vite port, one backend serving both) is the old way and shares a database.

Traps:

- **Drive from `127.0.0.1`, never the LAN address or `localhost`.** `mockAuth.ts` signs its JWT with `crypto.subtle`, which exists only in a secure context. `http://192.168.50.96:3000` is not one, so `crypto.subtle` is `undefined`, no token is ever minted, and the app sits on the loading modal forever: blank body, zero requests to the backend, nothing in the console. It looks like a hung build, not an auth problem.
- **Two dev servers can share port 3000.** Vite without `--host` binds `[::1]` and with `--host 0.0.0.0` binds IPv4 `*`, so a second stack starts happily beside the first and `--strictPort` says nothing. macOS resolves `localhost` to `::1` first, so `http://localhost:3000` reaches whichever one is on IPv6: a different worktree, a different backend, a different database, with no sign anything is wrong. `127.0.0.1:3000` is unambiguous. Check with `lsof -iTCP:3000 -sTCP:LISTEN -n -P`.
- Logs are the terminal only. Browser errors go to Sentry, which is off locally.

## Backend: `loquat/bin-local/dev`

Runs from `loquat/`. One `db`, `rabbitmq`, and `pdf` container serve every worktree. Isolation is per name, not per container: each branch gets its own Postgres database, its own RabbitMQ vhost, and its own port block, all inside those shared containers. Gotenberg is stateless and shared as is. The scripts live in `loquat/bin-local/`, untracked and symlinked into every worktree.

`bin-local/dev {start|stop|rm|ps|seed} [branch]`; the verb defaults to `start`, the branch to the current one. A branch other than the current one acts on that branch's worktree from anywhere.

1. `bin-local/dev` starts the podman machine and the three containers if they are down, runs `seed` if that database is missing, clones `seed` into a database named after the current branch with slashes turned into dashes, creates vhost `/<name>` with the dead-letter policy, writes a block into this worktree's `.env`, prints `bin-local/users`, and then becomes the loquat sbt process in the foreground: ctrl-c stops it, and it dies with the shell that started it. Launch it with `run_in_background: true`. `--tunnel` also opens ngrok on `NGROK_DOMAIN` (from `.env` or the shell) to this worktree's port, for HelloSign callbacks; a watchdog kills ngrok when the server exits, and `stop` kills it too. The ngrok account, domain, and HelloSign app setup are on the "Ngrok Configuration" page in Notion.

    ```
    # sandbox begin
    DB_NAME=<name>
    DB_DATABASE=<name>
    RABBITMQ_VHOST=/<name>
    PLAY_HTTP_PORT=<base>
    SOAP_FRAMEWORK_LTC_PORT=<base+1>
    QS1_MLLP_PORT=<base+2>
    METRICS_PORT=<base+3>
    INTEGRATIONS_API_PLAY_HTTP_PORT=<base+4>
    API_INTEGRATIONS_METRICS_PORT=<base+5>
    TEST_SOAP_PORT=<base+6>
    TEST_MLLP_PORT=<base+7>
    TEST_METRICS_PORT=<base+8>
    # sandbox end
    ```

    `<base>` is hashed from the name into 10000-14990 and follows from the name alone, so the same worktree always gets the same block. Read it back from `.env` whenever you need a port. A worktree runs one of each app: `bin-local/dev` again while loquat is up prints its URL and exits, and if some other process holds the port it says which and stops.
2. The script does not wait for the server: poll `curl -X GET localhost:<PLAY_HTTP_PORT>/ping` until it answers. Logs are the shell's output. After a code change, ctrl-c and run again.
3. `bin-local/dev` runs `sbt stage` on the worktree's warm sbt server, copies the staged app to `$TMPDIR/loquat-staged/<name>/`, and runs the copy: starting the app is the compile, and once the stage finishes the sbt server is free for tests or anything else, and later compiles never touch the running app. `--dev` instead runs `sbt run` in dev mode in a JVM of its own (`SBT_NATIVE_CLIENT=false`), which recompiles on a request after a code change.
4. Done for the day: `bin-local/dev stop` kills the worktree's loquat, api-integrations, difit servers, and sbt server (the sbt server keeps the `.env` it loaded at startup and would otherwise reuse stale ports and database on the next `sbt` command). The database, vhost, and block stay, so the next `start` is a warm database and a cold compile. Done with the branch: `bin-local/dev rm` is `stop` plus dropping the database (with its users and roles) and vhost and removing the block. The `seed` template, the containers, and the worktree stay.

`bin-local/dev ps` lists every worktree with its database and whatever is up: `sbt:<pid>`, `loquat:<port>`, `api:<port>`, `difit:<ports>`, then databases with no worktree. Re-running `bin-local/dev` reuses the existing database; `rm` first for a fresh copy of the seed. `rm` on a name with no worktree, such as `seed`, just drops the database and vhost. `--no-start` sets the environment up without launching sbt.

`bin-local/dev start <branch>` (or `--backend=<branch>`) runs another branch instead of this checkout: `wk` puts that branch in a worktree, branched from `origin/master` when it is new, and the script re-execs there. That is how the frontend's `bin-local/dev` gets a backend of its own, so a change to the isolation flow needs to still work when it is called that way.

Applications:

- Internal API: `bin-local/dev`, or `sbt run` by hand. Port `PLAY_HTTP_PORT`; SOAP on `SOAP_FRAMEWORK_LTC_PORT`, MLLP on `QS1_MLLP_PORT`. Health: `/ping`, and `/ping/db` for the database.
- External API (api integrations): `bin-local/dev --api`, in a shell of its own, or `sbt "apiIntegrations/run <port>"` by hand. Port `INTEGRATIONS_API_PLAY_HTTP_PORT`. A bare `sbt apiIntegrations/run` ignores the variable and binds 9003. Health: `/ping` and `/ping/db`.
