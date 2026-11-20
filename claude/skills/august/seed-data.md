# Seed data

What every branch database starts with, how to add the state a task needs, and how the seed itself is rebuilt.

## What the seed holds

`seed` is a template database holding the common ground: five orgs with their communities (facility ids), which the groups json for `bin-local/users` scopes to:

| Org | Communities |
| --- | --- |
| 24 Org 24 | 70 Facility 70 |
| 30 August Communities | 135 Oak River Villas, 136 Devonshire Estate Homes, 137 eMAR Villa, 138 eMAR Only Villa |
| 31 Oakland Communities | 139 Jupiter Grove Homes, 140 Saturn Creek Villas |
| 32 August Communities | 141–144, same names as 30 |
| 33 Oakland Communities | 145–146, same names as 31 |

It also holds rooms, residents, prospects, contacts, billing sources, medications, the two superuser rows and four service accounts (see `users.md`). Oak River Villas, `/orgs/30/facilities/135/...`, has `linked_residents` on. Cloning the seed takes under a second, so every agent starts from the same data without running the seed scripts. Nothing added to your database touches the seed or any other agent.

## Data for one test

When the seed lacks the exact state you need, add it through the API against your own port. The backend's `demo-data` package already has a client and fake-data builders:

```python
# demo-data/scratch_scenario.py, run with `bin/python scratch_scenario.py http://localhost:<PLAY_HTTP_PORT> --email camen@augusthealth.com`
import demo_data
from cli import Cli

api = Cli().parse_args().api
org_id = api.list_orgs()[0]["id"]
facility_id = api.list_facilities(org_id)[0]["id"]
person = demo_data.fake_person(fill=True)
person["residentStatus"] = "RESIDENT_STATUS_CURRENT_RESIDENT"
person_id = api.create_person(org_id, facility_id, person)
api.create_billing_source(org_id, facility_id, person_id, demo_data.fake_billing_source())
```

`api.py` has a method per endpoint the seed uses; `demo_data.py` has a `fake_*` builder per resource. `push_demo_data.py --add-facility -f` adds one more populated community to the first org. Prefer the API over SQL: it runs the same validation as the frontend, and IDs stay consistent. Direct SQL is fine for state the API cannot reach, through `docker exec -it db psql -U postgres <name>`.

Data the UI can't create, from the frontend: Oak River Villas offers no immunization upload type, so make one from the signed-in page with `evaluate_script`, importing the app's own API module by its served path, e.g. `await import('/@fs/<worktree>/frontend/src/app/api/immunizations.ts')` then `createImmunization` and `attachImmunization`; the module shares the app's authed client. The served root is `src/`, so `/src/...` paths 404.

## Rebuilding the seed

`seed` is a snapshot, never built by the script. `bin-local/dev seed` drops it and clones `generations`; `bin-local/dev seed <branch>` stops that branch's servers and clones its database instead, which is how new evolutions get into the seed. The data comes from whatever the source holds: `generations` is populated once by hand. Run the server with no sandbox block in `.env` so it points at `generations`, then `cd demo-data && bin/python push_demo_data.py -b -f --email camen@augusthealth.com http://localhost:<PLAY_HTTP_PORT>` (`-f` without `-b` for the full random volume), and ctrl-c the server. The source is `generations` rather than an empty database because evolution 294 creates a cluster-wide Postgres role that already exists, so a database starting from zero can never get past it. The source must have no open connections during the clone; `seed` fails saying so rather than guessing which server holds them. Existing branch databases are copies, so re-seeding changes only what the next `start` gets.
