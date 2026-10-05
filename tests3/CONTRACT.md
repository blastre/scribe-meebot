# tests3 — command contract

The stable command interface for building, deploying and validating a Scribe
stack. Automation should bind to these signatures rather than to `lib/`
internals, which are free to change. Invoke from anywhere with
`make -C <repo> <verb> ARG=…`.

Every verb is a pure function of its arguments: deterministic, idempotent, and
holding no hidden state between runs. The caller decides the arguments and
interprets the result; the verb does the mechanics and reports honestly through
machine-readable output and an exit code.

---

## Verbs

| verb | args | does | output / exit |
|---|---|---|---|
| `build` | `ARTIFACT` (tag, optional) | build all images and push `:dev` — the only place bytes are created | pushed tag · `0` ok / non-zero build fail |
| `deploy` | `MODE`∈{lite,compose,helm} · `ENV`∈{local,throwaway} · `ARTIFACT` | stand the stack up (dispatch on MODE×ENV) | healthy stack · `0` ok / non-zero unhealthy |
| `validate` | `MODE` · `ENV` · `SCOPE`∈{full,`<scope.yaml>`} | run registry checks against the live stack | per-check report JSON under `.state/reports/<mode>/` · `0` green / non-zero red |
| `provision` | `MODE` | stand up fresh ephemeral infra (throwaway VMs / managed cluster) | infra handle · `0` ok |
| `teardown` | — | destroy ephemeral infra (mandatory after a throwaway cycle) | `0` (best-effort, zero residue) |
| `promote` | `FROM` · `TO` (e.g. `:dev`→`:latest`) | re-tag the artifact forward — **never rebuilds** | re-tagged · `0` ok |
| `publish-packages` | — | build and publish `packages/*` to npm (idempotent) | `0` ok |
| `helm-upgrade-safe` | `RELEASE_NAME` `NAMESPACE` `CHART_PATH` `VALUES_FILES` | pre-flight image-exists check, then atomic helm upgrade | `0` ok / non-zero (aborts before upgrade if any image is missing) |

## The MODE × ENV matrix

```
                 local                throwaway
lite       deploy/lite            tests3 vm-*-lite
compose    deploy/compose         tests3 vm-*-compose
helm       (not wired)            tests3 lke-*
```

- `local` dispatches to `deploy/lite` or `deploy/compose` directly.
- `throwaway` uses the `tests3` VM targets (`vm-provision-*`, `vm-redeploy-*`)
  and the managed-cluster targets (`lke-*`). Both provision, run, and tear down.

Throwaway targets need the relevant cloud CLI on your `PATH` and credentials in
the environment. They are opt-in and never run as part of the local suite.

## Deliberately not here

There is no stage machine and no marker file tracking "where you are" in a
release. This layer only exposes mechanics; deciding which verb to run when is
the caller's job. Durable state lives in the things that already hold it —
branches, PRs, and image tags — not in a file under `tests3/`.
