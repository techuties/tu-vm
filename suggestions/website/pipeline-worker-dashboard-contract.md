---
title: Pipeline Worker Dashboard Contract
description: Constructional contract so the landing page shows the Tier 1 MinIO processor with the status route Nginx and the helper already expose.
last_updated: 2026-10-02
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Pipeline Worker Dashboard Contract

## Problem

`tika_minio_processor` is in `TIER1_SERVICES` in `tu-vm.sh` and in `TIER1_CONTAINERS` in `helper/uploader.py`. Announcements already treat a missing processor as a core service that is down.

The helper route and the Nginx proxy already exist:

```python
@app.route('/status/tika-processor', methods=['GET'])
def status_tika_processor():
    info = docker_inspect('tika_minio_processor')
```

```nginx
location /status/tika-processor {
    proxy_pass http://helper_index:9001/status/tika-processor;
}
```

The landing page never calls that URL. `nginx/html/index.html` puts Qdrant, MinIO, and Tika in the Tier 1 grid. The processor has no card. The `SERVICES` array probes `/status/` plus the card id:

```javascript
const SERVICES = [
  {id:'oweb',    ctrl:'open-webui'},
  {id:'minio',   ctrl:'minio'},
  {id:'qdrant',  ctrl:'qdrant'},
  {id:'tika',    ctrl:'tika'},
  {id:'affine',  ctrl:'affine'},
];
```

`refreshServices` fetches `/status/` + `id`. A card for the worker has to use id `tika-processor` so the browser hits the location Nginx already has. The control route is different: the helper map keys `tika_minio_processor` and `tika-minio-processor` to compose service `tika_minio_processor`.

`controlService` only remaps three names:

```javascript
const idMap = {'open-webui':'oweb','mcp-gateway':'mcp','langgraph-supervisor':'langgraph'};
const id = idMap[service] || service;
```

A Start button that posts `/control/tika_minio_processor/start` then looks for `btn-tika_minio_processor-start` and polls `/status/tika_minio_processor`. That path is not proxied. The button would spin even when `/status/tika-processor` is already `ok`.

The same grid is inconsistent about Stop:

| Tier 1 card | Stop button |
|---|---|
| PostgreSQL, Redis | No |
| Qdrant, MinIO, Tika | Yes |

Those three use `restart: unless-stopped`. A dashboard Stop is a Docker stop, and `unless-stopped` leaves the container stopped until the daemon starts again. Open WebUI RAG uses Qdrant (`QDRANT_URI`) and Tika (`TIKA_SERVER_URL`). The section title says the tier is always running. PostgreSQL and Redis already follow that by omitting Stop.

`/status/pdf-processing` only drives the toast while a file is in flight. An idle or crashed worker produces no card and no toast.

Checked on 2026-10-02 by reading `nginx/html/index.html`, `helper/uploader.py`, and `nginx/conf.d/default.conf`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `/status/tika-processor` in the helper and in Nginx | The probe the card should call |
| `TIER1_CONTAINERS['tika_minio_processor']` | Announcements already know this container |
| Helper `name_map` entries for the processor | Start/stop control already routed |
| Tier 1 grid in `index.html` | Where the card belongs |
| `SERVICES` and `idMap` | The two maps that must agree on id versus control name |
| Empty `btn-group` on PostgreSQL and Redis | The always-on pattern for Stop |

Out of scope:

- A new status service, metrics stack, or queue UI
- Changing how files are parsed (processor caps stay on Stages 41–42)
- Stage 43 untrusted-HTML rules for announcement text. Card copy stays a static string, same as the Tika card
- Rebuilding the marketing pipeline diagram

## Proposal

One card, the existing route, the existing control map.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Card | Tier 1 grid in `index.html` | Add a card like the Tika card. Badge id `badge-tika-processor`. Buttons `btn-tika-processor-start` and no Stop button |
| Probe list | `SERVICES` | `{id:'tika-processor', ctrl:'tika_minio_processor'}` |
| Button refresh | `idMap` in `controlService` | Map `tika_minio_processor` to `tika-processor` so Start resets the button that exists and polls `/status/tika-processor` |
| Stop | Qdrant, MinIO, and Tika cards | Remove the Stop button so they match PostgreSQL and Redis. Leave Start, so a container that is down can be brought back through the control route that already exists |
| Copy | Card description | Say it watches `WATCH_BUCKETS` (`tika-pipe` and `n8n-workflows` in Compose) and writes text back with Tika. Static text only |

### Rules

1. **Poll `/status/tika-processor`.** Do not add `/status/tika_minio_processor` or a second helper route.
2. **The card id and the control name are different.** `id` is the URL segment. `ctrl` is the helper map key. `idMap` must join them, the same way `open-webui` joins to `oweb`.
3. **Tier 1 cards do not offer Stop.** Qdrant, MinIO, Tika, and the processor stay in the always-on section. Start remains for recovery.
4. **Keep the PDF toast.** `/status/pdf-processing` stays the in-flight indicator. The card is the idle/down indicator.
5. **Do not invent a pipeline console.** No log tail, no bucket browser, no extra Flask endpoint.
6. **Announcements stay on `TIER1_CONTAINERS`.** The card should agree with that set. If the processor container is missing, the badge is offline and the announcement can still say the core service is down.

### Suggested contributor checklist

```text
1. Add a Tier 1 card with ids badge-tika-processor and btn-tika-processor-start
2. Append SERVICES with id tika-processor and ctrl tika_minio_processor
3. Map tika_minio_processor to tika-processor inside controlService
4. Remove Stop from the Qdrant, MinIO, and Tika cards
5. Load the landing page, stop the processor from the shell, and see the badge go offline
6. Start it from the card and see /status/tika-processor return ok without a new URL
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Liveness | Existing Nginx location and helper route | A processor-specific status app |
| Controls | Existing `/control/<service>/<action>` map | A new start API |
| Always-on Stop policy | The empty button group used by PostgreSQL and Redis | A confirm-modal framework |
| In-flight jobs | Existing `/status/pdf-processing` toast | Folding progress into a new database |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in `nginx/html/index.html` only. The helper and Nginx pieces are already there.
3. The Tier 1 grid must show the processor offline and then running, using `/status/tika-processor`, before this page is marked implemented.

## Acceptance criteria

- The landing page Tier 1 section includes the MinIO processor.
- The browser requests `/status/tika-processor` and no new status path.
- Start uses the existing control route and re-enables `btn-tika-processor-start`.
- Qdrant, MinIO, Tika, and the processor cards have no Stop button.
- PostgreSQL and Redis cards stay as they are.
- `/status/pdf-processing` still drives the toast.
