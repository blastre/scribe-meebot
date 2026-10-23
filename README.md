<p align="center">
  <img src="assets/logodark.svg" alt="Scribe" width="64"/>
</p>

<h1 align="center">Scribe</h1>

<p align="center"><strong>A self-hosted meeting bot that joins, records, and transcribes.</strong></p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue?style=flat-square" alt="License"/></a>
  <img src="https://img.shields.io/badge/python-3.11+-3776AB?style=flat-square" alt="Python"/>
  <img src="https://img.shields.io/badge/node-20+-339933?style=flat-square" alt="Node"/>
</p>

---

Scribe sends a headless Chromium bot into a meeting, records the whole session
with a who-spoke-when timeline, and produces a speaker-labelled transcript.

It is built for a **single-tenant-per-deployment or multi-tenant SaaS** shape:
every meeting and transcript is owned by a user (`owner_email`), with per-user
concurrency caps. Google Meet is the production path; Microsoft Teams and Zoom
adapters are present in the bot but are not the supported deployment target.

Transcription runs **in one batch after the meeting ends**, not live. That is a
deliberate trade: batch diarization over a complete recording is materially more
accurate than streaming, and the bot does not need a GPU because transcription
is a cloud API call.

## How it works

```
  Google Meet
      │  bot joins as a participant
      ▼
  scribe-bot ──────► audio chunks ──────► MinIO (S3)
 (Chromium/Playwright)   + speaker timeline
      │
      ▼
  meeting-api ──► batch transcription ──► Postgres (system of record)
   (lifecycle)       (Deepgram/Groq)            │
                                                ▼
                                        Cloudflare D1 (read mirror)
                                                │
                                                ▼
                                       your frontend reads here
```

Postgres is the system of record. Finalized transcripts are mirrored into
Cloudflare D1 so an edge frontend can read them without reaching back into the
backend network — see [`deploy/cloudflare-d1`](./deploy/cloudflare-d1).

## Services

| Service                   | Role                                                                 |
| ------------------------- | -------------------------------------------------------------------- |
| **api-gateway**           | Public edge. Auth, rate limiting, proxying. Hosts `/public/*`         |
| **meeting-api**           | Bot lifecycle, launches bot containers, orchestrates transcription, webhooks, D1 mirror |
| **admin-api**             | User and API-token CRUD; resolves an API key to scopes and limits     |
| **runtime-api**           | Scheduler for calendar auto-join and bot timeout jobs                 |
| **calendar-service**      | Google Calendar OAuth and event sync, schedules auto-joins            |
| **scribe-bot**            | Per-meeting Chromium bot. Joins, records audio, samples active speaker |
| **transcription-service** | Wrapper over the transcription provider. Batch and realtime modes     |
| **dashboard**             | Next.js admin UI                                                      |

Backed by Postgres (system of record), Redis (bus, bot status, rate limiting)
and MinIO (S3-compatible recording storage).

## Quickstart

Requires Docker and a transcription provider API key.

```bash
git clone https://github.com/blastre/scribe-meetbot.git
cd scribe-meetbot
cp deploy/env-example .env     # then fill in the values below
```

Set at minimum, in `.env`:

| Variable             | What it is                                   |
| -------------------- | -------------------------------------------- |
| `DEEPGRAM_API_KEY`   | Transcription provider key                   |
| `ADMIN_API_TOKEN`    | Bootstrap token for the admin API            |
| `INTERNAL_API_SECRET`| Shared secret for service-to-service calls   |

Then bring it up:

```bash
make lite     # single container, everything bundled — quickest way to evaluate
make all      # full stack, one container per service — development & production
```

`make help` lists every target. Once up:

```bash
# send a bot into a meeting
curl -X POST http://localhost:8056/public/join \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","meeting_url":"https://meet.google.com/xxx-xxxx-xxx"}'
```

## Deployment

| Target                              | Use                                          |
| ----------------------------------- | -------------------------------------------- |
| [`deploy/lite`](./deploy/lite)      | Single container, all services               |
| [`deploy/compose`](./deploy/compose)| Docker Compose, one container per service    |
| [`deploy/helm`](./deploy/helm)      | Kubernetes                                   |
| [`deploy/cloudflare-d1`](./deploy/cloudflare-d1) | The D1 read-mirror schema and sync |

A single EC2-class box running Compose is enough for this workload — there is no
GPU requirement and no Kubernetes requirement at small scale.

## Documentation

Full docs live in [`docs/`](./docs):
[getting started](./docs/getting-started.mdx) ·
[concepts](./docs/concepts.mdx) ·
[authentication](./docs/authentication.mdx) ·
[webhooks](./docs/webhooks.mdx) ·
[speaker identification](./docs/speaker-identification.mdx) ·
[recording storage](./docs/recording-storage.mdx) ·
[deployment](./docs/deployment.mdx) ·
[troubleshooting](./docs/troubleshooting.mdx)

Architecture and per-service detail: [`PRODUCT_OVERVIEW.md`](./PRODUCT_OVERVIEW.md)
and the README in each `services/*` directory.

## Architecture Diagram (GitDiagram)

[![Architecture diagram of blastre/scribe-meebot](https://gitdiagram.com/blastre/scribe-meebot/diagram.png)](https://gitdiagram.com/blastre/scribe-meebot?utm_source=readme&utm_medium=picture)

## Development

```bash
make build     # build images
make test      # run the test suite
make smoke     # end-to-end smoke test
make down      # tear down
```

Tests live in [`tests3/`](./tests3). Contributions: see
[CONTRIBUTING.md](./CONTRIBUTING.md). Security policy: [SECURITY.md](./SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
