# Scribe Helm Chart

## What
Deploys the Scribe real-time meeting transcription platform to Kubernetes.

## Why
Self-hosted deployment of the full Scribe stack: bot management, per-speaker transcription, real-time delivery via WebSocket, and a dashboard UI.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────────┐
│  Dashboard   │────>│  API Gateway  │────>│  Admin API          │
│  (Next.js)   │     │  (FastAPI)    │     │  (FastAPI)          │
└─────────────┘     └──────┬───────┘     └─────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼───────┐ ┌─────▼──────┐  ┌──────▼─────┐
   │ Meeting API   │ │ Agent API  │  │ Runtime API │
   │ (FastAPI)     │ │ (FastAPI)  │  │ (FastAPI)   │
   └──────┬───────┘ └────────────┘  └──────┬──────┘
          │                                │
   ┌──────▼───────┐                 ┌──────▼──────┐
   │  Bot Pods     │                │   Postgres   │
   │  (Playwright) │                │   Redis      │
   └──────────────┘                └─────────────┘
```

## Services

| Service | Description | Port |
|---------|-------------|------|
| api-gateway | HTTP + WebSocket API entry point | 8000 |
| admin-api | User/token CRUD, meeting management | 8001 |
| meeting-api | Meeting domain — bot lifecycle, transcription pipeline, recordings, webhooks | 8080 |
| runtime-api | Container lifecycle — Docker, K8s, process backends | 8090 |
| transcription-service | GPU inference (Whisper) — optional, can run externally | 8000 |
| dashboard | Next.js meeting dashboard | 3000 |
| postgres | Database (bundled, optional) | 5432 |
| redis | Stream + pub/sub (bundled, optional) | 6379 |

## Quick Start

```bash
helm install scribe ./deploy/helm/charts/scribe \
  --set secrets.adminApiToken=your-secret \
  --set database.host=your-pg-host \
  --set redisConfig.host=your-redis-host
```

## Bot Orchestration

The meeting-api delegates container lifecycle to Runtime API, which supports three orchestrator modes:

- **process** (default): Bots run as child processes. Simple, no extra permissions. Recommended for small deployments.
- **kubernetes**: Bots spawn as separate Pods. Requires RBAC. Best for scale.
- **docker**: Bots spawn as Docker containers. Requires Docker socket mount. Not recommended for K8s.

## Transcription Service

The transcription-service requires a GPU. Options:
- **External**: Run on a GPU machine outside K8s. Set `transcriptionService.enabled=false` and configure the URL in meeting-api.
- **In-cluster**: Set `transcriptionService.enabled=true` with a GPU node pool.

## Configuration

See `values.yaml` for all options. Key overrides for production:

```yaml
secrets:
  adminApiToken: "strong-random-token"
  transcriptionServiceToken: "match-transcription-service-API_TOKEN"

database:
  host: "your-postgres-host"

ingress:
  enabled: true
  host: "gateway.yourdomain.com"
  className: "nginx"
  tls:
    - secretName: scribe-tls
      hosts: ["gateway.yourdomain.com"]
```
