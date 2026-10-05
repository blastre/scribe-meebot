# Scribe Helm Charts

## Why

Docker Compose gets you running locally but doesn't scale, self-heal, or manage secrets properly. For production Kubernetes deployments, you need proper resource limits, RBAC for bot pod spawning, health probes, ingress routing, and secrets management. These Helm charts package all of that — two charts covering the full multi-service topology and the simpler single-pod Lite deployment.

## What

Helm charts for deploying Scribe on Kubernetes. Includes the Scribe Dashboard.

## How

- `scribe`: Full, multi-service deployment matching the upstream Docker Compose topology, with optional Scribe Dashboard deployment.
- `scribe-lite`: Single-container deployment intended for simpler setups, with optional Scribe Dashboard deployment.

### Prerequisites

- Kubernetes cluster (v1.22+ recommended)
- Helm v3
- Container images published to DockerHub (`scribe/` namespace)

### Image tags

Charts default to `scribe/*:latest`. For production, pin to a specific immutable tag:

```bash
helm install scribe ./deploy/helm/charts/scribe \
  --set apiGateway.image.tag=260330-1415 \
  --set adminApi.image.tag=260330-1415 \
  --set meetingApi.image.tag=260330-1415
```

Mutable tags (`:staging`, `:latest`) are pointers managed by `make promote-staging` / `make promote-latest` in the compose Makefile. They always point to a known immutable `YYMMDD-HHMM` build.

(`values-staging.yaml` was deprecated and removed in v0.10.5 — `values.yaml` + your operator-side overlay is the canonical pattern; `values-test.yaml` is the test-infrastructure config and remains.)

### Quickstart

Install the full chart from this repo:

```bash
helm install scribe ./deploy/helm/charts/scribe \
  --set secrets.adminApiToken=CHANGE_ME \
  --set secrets.transcriptionServiceToken=CHANGE_ME \
  --set database.host=postgres \
  --set redisConfig.url=redis://redis:6379
```

Install the lite chart:

```bash
helm install scribe-lite ./deploy/helm/charts/scribe-lite \
  --set scribe.databaseUrl=postgres://USER:PASS@HOST:5432/scribe \
  --set scribe.adminApiToken=CHANGE_ME \
  --set scribe.transcriptionServiceToken=CHANGE_ME
```

### Configuration

### scribe

Key values in `charts/scribe/values.yaml`:

- `secrets.adminApiToken`, `secrets.transcriptionServiceToken`: Required for auth and service communication.
- `database.host`, `database.user`, `database.name`: Used by admin-api, meeting-api.
- `redisConfig.url` (or `redisConfig.host`/`port`): Required if `redis.enabled=false`.
- `meetingApi.recordingEnabled`: `"true"` (required) — enables audio recording in bot containers.
- `runtimeApi.orchestrator`: `process` (default), `kubernetes` (K8s pods with RBAC), or `docker`.
- `runtimeApi.browserImage`: Bot container image (defaults to meetingApi image).
- `secrets.internalApiSecret`: Shared secret for gateway↔admin-api internal calls.
- `secrets.scribeApiKey`: Pre-provisioned API key for dashboard proxy (optional).
- `whisperLive.profile`: `cpu` or `gpu` (use with GPU resources and node selectors).
- `ingress.*`: Optional ingress for `api-gateway`.

Bundled dev dependencies:

- `postgres.enabled=true` and `redis.enabled=true` create in-cluster Postgres/Redis for development.

### scribe-lite

Key values in `charts/scribe-lite/values.yaml`:

- `scribe.databaseUrl`, `scribe.adminApiToken`, `scribe.transcriptionServiceToken`: Required unless `scribe.existingSecret` is set.
- `scribe.orchestrator`: Defaults to `process` (no Docker socket required).
- `dashboard.enabled`: Deploys a separate dashboard container.
- `ingress.*`: Optional ingress for the lite API and dashboard.

### Notes

- All images are on DockerHub under `scribe/`. No GHCR setup required.
- For production, pin image tags to specific `YYMMDD-HHMM` builds rather than using `:latest`.

## Development Notes

### Verification checklist

After deploying, verify:

1. `helm template` renders without errors
2. `helm install --dry-run` succeeds
3. All pods reach Running state (no CrashLoopBackOff)
4. All services have endpoints
5. Ingress routes correctly
6. Secrets are created
7. PVCs are bound
8. Bot RBAC works (can spawn pods, if using kubernetes orchestrator)
9. Inter-service connectivity (api-gateway can reach admin-api, meeting-api, etc.)
10. Health endpoints respond on each service

## Definition of Done


| #   | Item                            | Weight | Status   | Evidence                                          | Last checked |
| --- | ------------------------------- | ------ | -------- | ------------------------------------------------- | ------------ |
| 1   | scribe chart installs on K8s      | 20     | PASS     | 60/60 smoke checks pass on LKE (589344)           | 2026-04-08   |
| 2   | scribe-lite chart installs on K8s | 10     | SKIP     | Not tested                                        | —            |
| 3   | Images pulled from registry     | 8      | PASS     | All 10 pods running with :dev tags                | 2026-04-08   |
| 4   | Images built + pushed work      | 8      | PASS     | global.imageTag=0.10.0-260408-1826, all 7 pods running | 2026-04-09   |
| 5   | DB load from dump               | 10     | PASS     | 1761 users, 9587 meetings, 507K transcriptions via pg-loader pod | 2026-04-08   |
| 6   | Values documented               | 10     | PASS     | RBAC, orchestrator, recording, secrets documented | 2026-04-08   |
| 7   | Image tags match chart defaults | 7      | PASS     | values-test.yaml uses :dev consistently           | 2026-04-08   |
| 8   | Secrets management documented   | 10     | PASS     | internalApiSecret, scribeApiKey, adminApiToken      | 2026-04-08   |
| 9   | Health probes configured        | 7      | PASS     | K8S_DEPLOYMENTS_READY + K8S_NO_CRASHLOOP checks   | 2026-04-08   |
| 10  | Smoke checks pass               | 10     | PASS     | 60/60: docs 4, static 14, env 7, health 14, contracts 21 | 2026-04-08   |


## Confidence

Score: 90/100  
Last validated: 2026-04-09  
Tests: 60 smoke + dashboard + containers + webhooks + browser-session + auth-meeting  
Ceiling: scribe-lite chart SKIP

