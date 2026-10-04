---
title: Tika Client and Server Timeout Contract
description: Constructional contract so the MinIO processor's Tika client budget stays inside the task timeout already set in tika-config.xml.
last_updated: 2026-10-04
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Tika Client and Server Timeout Contract

## Problem

Apache Tika and the MinIO processor disagree about how long one extract may run.

The server cap is mounted from `tika-config/tika-config.xml`:

```xml
<taskTimeoutMillis>900000</taskTimeoutMillis>
<timeout>900000</timeout>
```

`900000` ms is 900 seconds, 15 minutes. The Compose comment on the `tika` service says the same thing.

The processor budget is set on `tika_minio_processor` and read in `UniversalProcessor`:

| Setting | Compose value | Client effect |
|---|---|---|
| `TIKA_TIMEOUT_NO_OCR_SECONDS` | `600` | Starting wait for a non-OCR stage |
| `TIKA_TIMEOUT_OCR_SECONDS` | `1800` | Starting wait for an OCR stage |
| `TIKA_TIMEOUT_MAX_SECONDS` | `3600` | Cap on the adaptive wait |
| `TIKA_TIMEOUT_PER_MB_OCR_SECONDS` | `4.0` | Added per megabyte on OCR |

`adaptive_timeout` returns `max(base, min(base + size_mb * per_mb, max))`. For a 1 MB PDF with OCR that is `max(1800, min(1804, 3600))`, so **1800 seconds**. The OCR stage then does both of the following:

- `requests.put(..., timeout=1800)`
- `X-Tika-Timeout-Millis: 1800000` when `use_ocr` is true

The server task cap is `900000` ms. The client asks for twice that, and then blocks for twice that, on a 1 MB file. A larger file climbs toward 3600 seconds. A non-OCR file starts at 600 seconds, which is under the cap, and crosses it once `600 + 1.5 * size_mb` exceeds 900 (above 200 MB).

The practical failure is a processor that still says it is processing after Tika has ended the task. `PROCESSOR_MAX_RETRIES` is `2`, so the OCR stage can repeat that wait. The dashboard status file stays on the in-progress record for the whole client timeout.

Stage 19 owns how contributors edit the XML, and it already requires `taskTimeoutMillis` and the OCR `timeout` to stay equal. They are equal today. Stage 48 owns the readiness probe and explicitly leaves the XML file alone. Neither page states that the processor's Compose numbers are larger than `900000` ms.

Checked by reading `tika-config/tika-config.xml`, the `tika_minio_processor` environment in `docker-compose.yml`, and `_process_with_tika` in `tika-minio-processor/universal_processor.py`. No file was sent to Tika.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika-config/tika-config.xml` | Server task cap, 900 seconds |
| Processor timeout env vars | Client budget, OCR base 1800 seconds, max 3600 |
| `X-Tika-Timeout-Millis` | Header set only on OCR requests, from the client budget |
| `requests` `timeout=` | How long the processor blocks |
| Stage 19 XML contribution page (expected sibling) | Paired XML timeouts and the 15-minute baseline |
| Stage 48 pipeline readiness (expected sibling) | Healthcheck and `depends_on`. Not this budget |
| Stage 41–42 processor caps (expected siblings) | Byte size, archive expansion, pagination. Not the clock |

Out of scope:

- A second extractor or a custom Tika image
- Raising the server cap above the documented 15-minute baseline in this change
- Editing parser or mime configuration
- The Stage 48 curl-less healthcheck

## Proposal

Treat `taskTimeoutMillis` as the single budget. The processor may wait less. It must not wait more, and it must not send a header above that cap.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| OCR base | `TIKA_TIMEOUT_OCR_SECONDS` | Set it to at most `900` |
| Hard cap | `TIKA_TIMEOUT_MAX_SECONDS` | Set it to at most `900` |
| Non-OCR path | Adaptive formula | The computed wait, including the per-megabyte term, must be clamped to 900 even when the base is 600 |
| Header | `X-Tika-Timeout-Millis` | Send `min(request_timeout, 900) * 1000`, never a value above `900000` |
| XML | Unchanged in this PR | Leave both XML values at `900000` so the Stage 19 pair stays intact |
| Comment | Compose comment on `tika` | Keep "15 minutes" only if the processor cap matches it |

### Rules

1. **The server cap wins.** A longer client timeout cannot finish a task Tika has already stopped.
2. **Do not raise the XML to match 1800.** That holds the JVM for longer on a laptop. Stage 19 already calls out that energy cost. Align the client downward.
3. **Keep the XML pair equal.** If a later Issue accepts a longer server cap, change `taskTimeoutMillis` and the OCR `timeout` together, then set the processor max to that same number of seconds.
4. **Clamp every stage.** OCR is the case that fails on a 1 MB file. The max must still clamp non-OCR so a large file cannot wait an hour.
5. **Retries stay.** `PROCESSOR_MAX_RETRIES` is a separate knob. Do not remove retries in this PR. Do make each attempt respect the cap.
6. **No new extractor.** The fix is three numbers and one `min()`.

### Suggested contributor checklist

```text
1. Read taskTimeoutMillis and the processor TIKA_TIMEOUT_* values
2. Set OCR base and the max to 900 seconds or less
3. Clamp adaptive_timeout and X-Tika-Timeout-Millis to that cap
4. Leave tika-config.xml at 900000 / 900000
5. Process a small PDF and confirm the logged timeout is <= 900
6. Do not add an extractor image
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Server deadline | Existing `taskTimeoutMillis` | A sidecar watchdog |
| Client deadline | The processor env vars that already exist | A new config file |
| Pairing rule | Stage 19 XML pair | Editing only one of the two XML numbers |
| Readiness | Stage 48 probe | Mixing the healthcheck into this PR |

## Acceptance criteria

- `TIKA_TIMEOUT_OCR_SECONDS` and `TIKA_TIMEOUT_MAX_SECONDS` are less than or equal to 900.
- `adaptive_timeout` never returns a value above 900.
- `X-Tika-Timeout-Millis` is never greater than `900000`.
- `tika-config.xml` still has `900000` for both the task and the OCR timeout.
- No new image or extractor service is added.

## Verification notes

Arithmetic checked against the tree on 2026-10-04: `900000 / 1000 = 900` seconds on the server; a 1 MB OCR stage resolves to `1800` seconds in the client. The header is `request_timeout * 1000`, so that stage sends `1800000`.

## Rollback

Restore the Compose timeout values and the unclamped header. The XML file is not part of the rollback.
