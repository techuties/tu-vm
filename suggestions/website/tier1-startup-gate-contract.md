---
title: Tier 1 Startup Gate Contract
description: Constructional contract so a Docker health status of starting does not skip MinIO bucket setup, Pi-hole DNS sync, and cron installation.
last_updated: 2026-10-02
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Tier 1 Startup Gate Contract

## Problem

`start_services` in `tu-vm.sh` brings Tier 1 up, then calls `wait_for_services`. The success branch is the only place that syncs Pi-hole DNS, creates MinIO buckets, mounts storage, and installs cron:

```bash
if wait_for_services "${TIER1_SERVICES[@]}"; then
    sync_pihole_dns_records
    setup_minio_buckets
    mount_minio_storage
    ensure_sync_cron_job
    ensure_daily_checkup_cron_job
    ensure_weekly_update_cron_job
    show_access_info
else
    warn "Some services may not be fully ready yet."
fi
```

`wait_for_services` allows 10 attempts and sleeps 2 seconds between them. That is about 20 seconds per service.

`check_service_health` already shells out to `docker inspect`. It returns success for `healthy` and for `none`. It returns failure for `starting` and for `unhealthy`.

Docker keeps a container at `starting` until the first healthcheck succeeds. The first probe is scheduled one `interval` after the container starts, unless `start_interval` is set. These Tier 1 services set `interval: 180s`:

| Service | Healthcheck command in `docker-compose.yml` | Interval |
|---|---|---|
| `postgres` | `pg_isready` | 180s |
| `redis` | `redis-cli ... ping` | 180s |
| `open-webui` | `curl` to `/health/db` | 180s, plus `start_period: 180s` |
| `pihole` | `dig` | 180s |
| `nginx` | `nginx -t` | 180s |

`open-webui` depends on Redis with `condition: service_started`, so `docker compose up -d` does not wait for Redis to become healthy. The waiter then runs. Redis is still `starting` for the whole 20 second budget. One failure fails the whole list, and the `else` branch runs.

`AGENTS.md` already says Open WebUI takes about 60–120 seconds on first boot. The Open WebUI healthcheck cannot succeed inside a 20 second window even when the process is fine.

Two different failures share this gate:

- A slow first probe (`starting`) on Redis, Open WebUI, Pi-hole, Nginx, or PostgreSQL when that container was just created.
- A probe that can never succeed. The Qdrant page in this stage covers that case. Once `ai_qdrant` is `unhealthy`, every later `./tu-vm.sh start` takes this `else` branch, including boots where every other service is healthy.

The practical miss on a cold start or any recreate:

- `*.tu.lan` names are not refreshed in Pi-hole
- `setup_minio_buckets` does not run, so `tika-pipe` and the other first-boot buckets are absent
- the daily checkup cron and the weekly update cron are not installed
- the script does not print the access URLs

Checked on 2026-10-02 by reading `tu-vm.sh` and `docker-compose.yml` on `dev`. The Docker daemon was not running here. The 20 second budget is the loop. The 180 second delay is the Compose `interval` plus Docker's rule that status stays `starting` until a probe succeeds.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `check_service_health` | Already reads `.State.Health.Status` |
| `wait_for_services` | The loop whose budget is too small for `starting` |
| `start_services` success branch | The only caller of bucket setup and the cron installers |
| Compose `healthcheck.interval` | Steady-state probe spacing already chosen for Tier 1 |
| Compose `start_period` on Open WebUI, Qdrant, and MinIO | The boot window those services already declare |
| `setup_minio_buckets` | Its own MinIO retry loop (30 attempts, 2 seconds). It does not need Open WebUI to be healthy |

Out of scope:

- A new process supervisor or systemd unit (Stage 46 owns the user-unit install notes)
- Image digest compare and the update-status file (Stage 44)
- Rewriting `scripts/daily-checkup.sh` (Stage 47 owns that script's container identity)
- Changing MinIO `mc` transport (Stage 46)
- Replacing Compose healthchecks with a side-car prober

## Proposal

Keep one waiter and one Compose healthcheck per service. Separate "still booting" from "failed".

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Steady interval | `docker-compose.yml` services that already use 180s | Keep 180s after the boot window so the energy-saving interval stays |
| Boot probes | Same healthchecks | Set `start_interval` (Compose healthcheck field) short, on the order of 5s, and keep `start_period` at least as long as the service actually takes. Open WebUI's existing `start_period: 180s` is the right boot window |
| Waiter | `wait_for_services` | Treat `starting` as not ready yet. Keep polling until `start_period` plus one interval has elapsed, then fail. A flat 20 second cap is smaller than every 180s interval in the table above |
| Failed probe | `check_service_health` | `unhealthy` is still failure. Do not treat it as `starting` |
| Post-start work | `start_services` | Run `setup_minio_buckets` when MinIO accepts connections. That function already returns without doing work if `ai_minio` is stopped. Do not also require Open WebUI, Pi-hole, and Nginx to be `healthy` |
| Cron and DNS | Same function | Install cron and sync Pi-hole when those containers are running. A peer still in `starting` can be logged. It should not erase the install |

### Rules

1. **`starting` means boot, not outage.** The status string is Docker's, from the inspect call this function already uses.
2. **The steady interval can stay long.** `start_interval` exists so the first successful probe is not delayed by the 180 second energy interval. Confirm `docker compose version` on the operator host understands `start_interval`. If it does not, document that and use a shorter `interval` only for the services whose `depends_on` condition is `service_healthy` (`postgres` today).
3. **One unhealthy container must be visible.** Log the service name and the status string. Keep going with the tasks that do not need that service.
4. **MinIO bucket setup keys off MinIO.** `setup_minio_buckets` already waits on `mc ls`. It should run on the success path of that wait, including when Qdrant is the service that is `unhealthy`.
5. **Do not add a second health agent.** No new container, no HTTP polling sidecar, no extra status file for this gate.
6. **Leave the Qdrant probe text to the Qdrant page.** This page only consumes the resulting status (`starting`, `healthy`, `unhealthy`, `none`).

### Suggested contributor checklist

```text
1. Confirm start_interval is accepted by the Compose version this repo documents
2. Give 180s-interval services a short start_interval and an honest start_period
3. Teach wait_for_services to keep waiting while status is starting, and to name the service when it gives up
4. Call setup_minio_buckets when MinIO is up, even if another Tier 1 service is still starting
5. Still install daily-checkup and weekly-update cron in that case
6. A healthy stack plus an unhealthy Qdrant prints the Qdrant failure and still creates buckets
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Status | `docker inspect` `.State.Health.Status` already in `check_service_health` | A new health HTTP service |
| Boot vs steady state | Compose `start_interval` and `start_period` | Shrinking the 180s interval with no boot window |
| Bucket creation | `setup_minio_buckets` | A second bucket-bootstrap container |
| Cron | `ensure_daily_checkup_cron_job` and `ensure_weekly_update_cron_job` | A hand-written crontab that bypasses those functions |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in `tu-vm.sh` and the Tier 1 `healthcheck` blocks. Ship the Qdrant probe fix in the same release or the gate will still fail after Qdrant turns `unhealthy`.
3. A cold `./tu-vm.sh start` must reach `setup_minio_buckets` before this page is marked implemented.

## Acceptance criteria

- Redis still in `starting` at 20 seconds does not skip cron installation.
- `setup_minio_buckets` runs when `ai_minio` is running and another Tier 1 service is `unhealthy`.
- The operator message names the service that failed and its health status.
- Steady-state probe spacing for PostgreSQL, Redis, Open WebUI, Pi-hole, and Nginx stays on the order of 180 seconds after the boot window.
- No new container and no new status file.
