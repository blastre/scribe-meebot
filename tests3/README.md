# tests3 — validation suite

End-to-end validation for a running Scribe deployment. These are not unit tests:
each one exercises a real stack (lite, compose, or Helm) and asserts on observed
behaviour. Per-service unit tests live next to their service, under
`services/*/tests/`.

Run everything from the repo root via `make`, or directly with
`make -C tests3 <target>`.

## Quick start

```bash
make -C tests3 health          # is the stack up and reachable?
make -C tests3 smoke           # fast end-to-end sanity pass
make -C tests3 validate-compose  # full suite against a compose deployment
make -C tests3 help            # list every target
```

## Layout

| Path | What it holds |
| --- | --- |
| `registry.yaml` | The check registry — every check, what it proves, and the symptom it catches |
| `tests/` | Executable scenarios (46 shell + 1 Python), one concern each |
| `synthetic/` | 12 scenarios driven against a stubbed rig, no real meeting needed |
| `lib/` | Shared helpers: assertions, VM and cluster provisioning, DB loading |
| `checks/` | Check dispatch and supporting scripts |
| `testdata/` | Fixtures |
| `releases/` | Per-release scope files |
| `CONTRACT.md` | The verb interface this suite exposes to callers |

## The registry

`registry.yaml` is the source of truth for what is checked. Each entry records
why the check exists, so a failure is readable without digging into the script:

```yaml
ADMIN_API_DB_EXISTS:
  proves:   "The scribe database exists and is reachable from admin-api"
  symptom:  "/login returns 500; admin-api crashes with InvalidCatalogNameError"
  type:     script
  modes:    [lite, compose, helm]
  max_duration_sec: 30
```

`proves` is the contract the check defends. `symptom` is what you would actually
see in production when it regresses. `modes` limits a check to the deployment
shapes where it is meaningful.

## Tiers

Targets are grouped so you can run only what a change affects:

| Tier | Target | Covers |
| --- | --- | --- |
| Health | `health` | Services up, ports reachable, DB present |
| Contracts | `contracts` | API shapes and auth behaviour |
| Smoke | `smoke` | A short end-to-end path |
| Meeting | `meeting`, `bot`, `transcribe`, `finalize` | Bot lifecycle and the transcription pipeline |
| Dashboard | `dashboard`, `dashboard-auth`, `dashboard-proxy` | UI and proxy behaviour |
| Full | `validate-lite`, `validate-compose`, `validate-helm`, `validate-all` | Everything for a deployment shape |

`make -C tests3 what-changed` suggests the affected targets for your working
diff; `collect` and `score` summarize a run.

## Remote targets

Helpers exist for validating against a throwaway VM or a managed cluster rather
than localhost — `vm-compose`, `vm-lite`, `vm-destroy`, and the `lke-*` targets.
They provision, run a scope, and tear down. These need the relevant cloud CLI on
your `PATH` and credentials in the environment; they are opt-in and never run as
part of the local suite.

## Writing a check

1. Add the entry to `registry.yaml` with `proves` and `symptom` filled in.
2. Add the script under `tests/`, exiting non-zero on failure.
3. Wire it into the right tier in the `Makefile`.
4. Keep it idempotent — it must be safe to run repeatedly against one stack.
