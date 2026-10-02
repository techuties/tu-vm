---
title: Tika Pipeline Readiness Contract
description: Constructional contract so Open WebUI and the MinIO processor wait until Apache Tika is listening, using a probe the pinned image can run.
last_updated: 2026-10-02
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Tika Pipeline Readiness Contract

## Problem

Tika is Tier 1. Open WebUI is configured for it:

```yaml
CONTENT_EXTRACTION_ENGINE: "tika"
TIKA_SERVER_URL: "http://ai_tika:9998"
```

The `tika` service mounts `tika-config/tika-config.xml` and starts the server with `--config`. It has **no** `healthcheck` block. The processor comment is leftover from Tier 2:

```yaml
tika_minio_processor:
  depends_on:
    tika:
      condition: service_started
    minio:
      condition: service_started
  # Healthcheck disabled for on-demand service (Tier 2)
```

`open-webui` uses the same `service_started` condition for `tika` and for `minio`. Compose marks `service_started` when the container process has started. The Tika process is a JVM. Port 9998 opens later. The processor and Open WebUI are free to call Tika during that gap. The watcher retries every `CHECK_INTERVAL` (10 seconds), so it can recover, but the first extracts fail and the dashboard has no readiness signal.

`check_service_health` treats a missing healthcheck as `none` and then as success whenever the container is running. `wait_for_services` can report Tika ready while the JVM is still starting.

The pinned image does not contain `curl`, so copying the Qdrant or MinIO check would fail the same way:

`apache/tika@sha256:90b7fa1dc018434075fce9e1d9b88b1e3d0ea6979d0cf86e116c79a8073ae973`

linux/amd64 config created 2026-05-27. The only `apt-get install` in that history is:

```text
openjdk-21-jre-headless ca-certificates
```

`CHANGELOG.md` still says Tier 1 Tika uses a 180 second health interval. The Compose service does not. The Compose file is the contract.

Stage 19 (open PR #45, `tika-xml-config-contribution-contract.md`) owns the XML timeouts. This page does not change `tika-config.xml`.

Checked on 2026-10-02 from `docker-compose.yml` and the registry image history. The daemon was not running here, so this is not a live port probe.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika` service | Where the healthcheck belongs |
| `open-webui.depends_on.tika` | Should wait for healthy, not merely started |
| `tika_minio_processor.depends_on` | Same for Tika and for MinIO, which already has a healthcheck |
| MinIO `healthcheck` | Upstream `curl` check. The processor should honor it with `service_healthy` |
| JRE inside the pinned Tika image | The runtime the image history proves is installed |
| Helper `/status/tika` | TCP connect to `ai_tika:9998`. Same readiness idea, already shipped |
| Stage 19 XML page | Timeouts inside the server. Leave the file alone |

Out of scope:

- A custom Tika image that installs `curl` or `wget`
- Editing `tika-config.xml` or OCR timeouts
- Processor byte caps, archive expansion, or object-list pagination (Stages 41–42)
- Moving Tika back to Tier 2

## Proposal

Add a Compose healthcheck the pinned image can execute. Point the two dependents at `service_healthy`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Probe | `tika.healthcheck` | A command that exits 0 only when something accepts TCP 9998. Do not call `curl` |
| Binary check | Contributor machine, pinned digest | `docker run --rm --entrypoint sh <digest> -c 'command -v bash; command -v curl; command -v java'` and pick a binary that prints a path. `java` is installed. `curl` is not. Use `bash -c 'echo >/dev/tcp/127.0.0.1/9998'` only if `bash` is on `PATH` |
| Boot window | Same healthcheck | `start_period` long enough for a cold JVM (on the order of the 60–120 seconds Open WebUI already needs, not 5 seconds). Steady `interval` can match the other Tier 1 services |
| Dependents | `open-webui` and `tika_minio_processor` | `condition: service_healthy` for `tika`. For the processor, also `service_healthy` on `minio` |
| Comment | processor service | Delete the Tier 2 healthcheck comment. The service is Tier 1 |

### Rules

1. **Prove the probe inside the pinned image** before merging. A healthcheck that exits 127 leaves Tika `unhealthy` forever and blocks Open WebUI once `depends_on` is `service_healthy`.
2. **Do not install packages into a child image.** The pin exists so the server bits stay upstream.
3. **`service_started` is the wrong condition for a JVM.** Switch it after the probe works, not before.
4. **Honor MinIO's existing healthcheck** from the processor. MinIO already has `start_period: 20s` and a live route. The processor does not need a new MinIO probe.
5. **Leave `tika-config.xml` on the Stage 19 page.** Readiness is whether the port accepts connections, not how long a parse may run.
6. **Keep `/status/tika` as the dashboard signal.** It already opens port 9998. This page makes Compose agree with that check.

### Suggested contributor checklist

```text
1. Run command -v inside the pinned apache/tika digest and record bash, curl, and java
2. Add a healthcheck that uses a binary from that list and touches port 9998
3. Recreate ai_tika and show Status healthy only after the port accepts connections
4. Set open-webui and tika_minio_processor depends_on tika to service_healthy
5. Set the processor's minio dependency to service_healthy
6. Remove the Tier 2 healthcheck comment
7. Do not edit tika-config.xml and do not add a Dockerfile in front of apache/tika
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Readiness | Compose `healthcheck` + `service_healthy` | `sleep` in the processor before the first poll |
| Probe | A binary already in the pinned image | `curl` copied from the MinIO or Qdrant snippets |
| Dashboard | Existing `/status/tika` TCP check | A new Tika status route |
| Config file | Stage 19 XML contract | A second XML suggestion |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in the `tika`, `open-webui`, and `tika_minio_processor` services of `docker-compose.yml`.
3. A cold start must show `ai_tika` healthy before Open WebUI is started, on the pinned digest, before this page is marked implemented.

## Acceptance criteria

- `ai_tika` has a healthcheck whose command exists in the pinned image.
- The healthcheck is `healthy` only after port 9998 accepts connections.
- Open WebUI and the processor wait on `service_healthy`.
- The processor also waits until MinIO is `healthy`.
- `tika-config.xml` is unchanged.
- No new image is published.
