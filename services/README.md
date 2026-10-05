# Services

Scribe is split into services rather than a monolith. Each owns one concern and
they talk over REST and Redis. This map exists because no single service tells
you how the whole system fits together.

## System diagram

```
                        ┌──────────────┐
                        │  Dashboard   │   Next.js admin UI
                        │  (Next.js)   │
                        └──────┬───────┘
                               │
                        ┌──────▼───────┐
                        │ API Gateway  │   public edge: auth, rate limit, proxy
                        └──────┬───────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────▼─────┐   ┌──────▼──────┐  ┌──────▼────────┐
       │ Admin API  │   │ Meeting API │  │   Calendar    │
       │  users,    │   │ join, stop, │  │   OAuth +     │
       │  tokens    │   │ status, wh  │  │   event sync  │
       └────────────┘   └──────┬──────┘  └──────┬────────┘
                               │                │
                 ══════════════╪════════════════╪════════
                     domain    │                │
                     ──────────┼────────────────┘
                     infra     │
                        ┌──────▼───────┐
                        │ Runtime API  │   scheduler: auto-join + timeouts
                        └──────┬───────┘
                               │ spawns
                        ┌──────▼───────┐
                        │  scribe-bot  │   ephemeral Chromium container,
                        │  (per call)  │   one per meeting
                        └──────┬───────┘
                               │ audio
                        ┌──────▼─────────────┐
                        │ Transcription svc  │  batch + realtime
                        └────────────────────┘

   Backing stores:  Postgres (record)  ·  Redis (bus)  ·  MinIO (recordings)
                    Cloudflare D1 (read mirror of finalized transcripts)
```

## Service map

| Service | Port | Role |
| --- | --- | --- |
| [api-gateway](api-gateway/) | 8056→8000 | Public edge. Auth, rate limiting, proxying. Hosts `/public/*`, `/bots`, `/calendar/*` |
| [meeting-api](meeting-api/) | 8080 | Bot lifecycle, launches bot containers, receives callbacks, orchestrates batch transcription, webhooks, D1 mirror |
| [admin-api](admin-api/) | 8057→8001 | User and API-token CRUD; resolves an API key to `{user_id, scopes, max_concurrent}` |
| [runtime-api](runtime-api/) | 8090 | Scheduler: calendar auto-join jobs and bot timeout jobs |
| [calendar-service](calendar-service/) | 8050 | Google Calendar OAuth and event sync, schedules auto-joins |
| [scribe-bot](scribe-bot/) | ephemeral | Per-meeting Chromium bot. Joins, records audio, samples the active speaker |
| [transcription-service](transcription-service/) | 8000 | Wrapper over the transcription provider. Batch and realtime modes |
| [dashboard](dashboard/) | 3001→3000 | Next.js admin UI |

Infrastructure containers: **postgres** (5458→5432), **redis** (6379), and
**minio** (9000/9001). See [redis.md](redis.md) for how the bus is used.

## Request flow

The main path, from API call to stored transcript:

1. A client calls `POST /public/join` on the **API Gateway** with an API key.
2. The gateway resolves the key via **Admin API** and forwards to **Meeting API**.
3. **Meeting API** creates the meeting record and launches a **scribe-bot**
   container for it.
4. The bot joins the meeting, records audio in chunks to **MinIO**, and streams
   speaker-activity events over **Redis**.
5. On meeting end, **Meeting API** sends the assembled audio to the
   **Transcription Service** as one batch, then merges the result with the
   speaker timeline.
6. The finished transcript is written to **Postgres** and mirrored to
   **Cloudflare D1**, where the customer-facing frontend reads it.

Calendar auto-join runs alongside this: **calendar-service** syncs events and
**runtime-api** fires a join at the scheduled time through the same path.

## Conventions

- Service-to-service calls carry `INTERNAL_API_SECRET`; only the gateway is
  meant to be reachable from outside.
- Every meeting and transcript is owned by an `owner_email`, which is what
  scopes all reads.
- Each service directory has its own README with local detail.
