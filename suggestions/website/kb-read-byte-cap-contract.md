---
title: Knowledge-Base Read Byte Cap Contract
description: Constructional contract so MCP knowledge-base reads stop at the same KB_MAX_OBJECT_BYTES ceiling that put already enforces.
last_updated: 2026-11-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Knowledge-Base Read Byte Cap Contract

## Problem

`KnowledgeBaseApi.max_object_bytes` is `KB_MAX_OBJECT_BYTES`, default `10485760` (10 MiB). `kb_put_object` uses it:

```python
if len(payload) > kb_api.max_object_bytes:
    raise HTTPException(status_code=413, detail="OBJECT_TOO_LARGE")
```

The read path does not. `_get_object_bytes_sync` does `resp.read()` and returns every byte. These callers use it with no length check:

| Caller | What it does with the bytes |
|---|---|
| `kb_get_object` | Returns UTF-8 text, or base64 when `asText` is false. `maxChars` trims text after the full download. |
| `kb_extract_text` | Sends the full object to Tika, then trims the extracted text to `KB_MAX_EXTRACT_CHARS`. |
| `kb_index_document` | Downloads the source object, then extracts it, before writing a small index JSON. |

Checked on 2026-11-06 by reading `mcp-gateway/app.py` and replaying the two decisions in Python 3.12. MinIO was not contacted.

| Payload | Put (`len > KB_MAX_OBJECT_BYTES`) | Get (`resp.read()`) |
|---|---|---|
| 10,485,760 bytes | stored | returned |
| 10,485,761 bytes | `413 OBJECT_TOO_LARGE` | 10,485,761 bytes returned |

`kb_get_object`, `kb_extract_text`, and `kb_index_document` do not mention `max_object_bytes`. `kb_put_object` does.

An object can already be larger than the cap: it was written when the cap was higher, or it was uploaded with `mc` or the processor bucket tools. The next get, extract, or index loads it into the gateway process. `kb_extract_text` then uploads that buffer to Tika. `asText: false` base64-expands it in the JSON response.

Stage 42 (open PR #68) owns the processor download cap. That page describes `KB_MAX_OBJECT_BYTES` as the ceiling for knowledge-base reads. The constant exists. Only put consults it. This page makes the read path match that description. It does not change the processor.

Stage 41 (open PR #67) owns the anonymous-read default. This page does not flip `KB_PUBLIC_READ_ENABLED`. While that default stays true, an anonymous `kb_get_object` on `kb-public` is one of the callers that needs the cap.

Checked in `mcp-gateway/app.py` (`_get_object_bytes_sync`, `get_object_bytes`, `_invoke_kb_tool`). No bucket was created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `KB_MAX_OBJECT_BYTES` | The ceiling put already enforces |
| `kb_put_object` | The `413 OBJECT_TOO_LARGE` response to copy |
| `KB_MAX_EXTRACT_CHARS` | Text trim after a download that already fit |
| `kb_get_object` `maxChars` | Response trim, after the download |
| Stage 41 `kb-public-read-default-contract.md` (open PR #67) | Who may call the read tools |
| Stage 42 `processor-object-byte-budget-contract.md` (open PR #68) | Processor `get_object` cap, separate process |

Out of scope:

- Changing `KB_PUBLIC_READ_ENABLED`
- The processor watcher byte cap
- A second object-storage service
- Deleting oversized objects

## Proposal

Stop a knowledge-base read when the object is larger than `KB_MAX_OBJECT_BYTES`. Keep put on the same constant.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Download | `_get_object_bytes_sync` | Read `Content-Length` or the stream up to `max_object_bytes + 1`. Over the cap, raise `413 OBJECT_TOO_LARGE` and close the response. |
| Get | `kb_get_object` | Keep `maxChars` as a response trim for objects that already fit. |
| Extract | `kb_extract_text` | Tika sees only a body that passed the cap. |
| Index | `kb_index_document` | The source download uses the same helper, so the index path is covered. |

### Rules

1. **One ceiling.** Put and every full-object read use `KB_MAX_OBJECT_BYTES`.
2. **Over the cap is 413.** The detail stays `OBJECT_TOO_LARGE`, the same string put returns.
3. **The object stays.** A too-large read does not delete the key.
4. **Text limits stay later.** `maxChars` and `KB_MAX_EXTRACT_CHARS` still trim text after a download that fit.
5. **Stage 41 still owns the anonymous default.** This page does not require a bearer token.
6. **Stage 42 still owns the processor.** This page does not edit `universal_processor.py`.

### Suggested contributor checklist

```text
1. Put a payload of KB_MAX_OBJECT_BYTES bytes and confirm it is stored
2. Put one extra byte and confirm 413 OBJECT_TOO_LARGE
3. Point kb_get_object at an object one byte over the cap and confirm 413 before a body is returned
4. Repeat for kb_extract_text and kb_index_document
5. Confirm a fitting object still returns text, and maxChars still trims the response
6. Confirm KB_PUBLIC_READ_ENABLED and the processor download loop are unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Size ceiling | `KB_MAX_OBJECT_BYTES` | A new limit service |
| Error | `413 OBJECT_TOO_LARGE` | A custom error catalog |
| Text trim | `maxChars` and `KB_MAX_EXTRACT_CHARS` | Trimming as a substitute for the byte cap |
| Intake | GitHub Issue | A storage ticket system |

### Acceptance check

- [ ] A payload of `KB_MAX_OBJECT_BYTES` bytes can be stored.
- [ ] One extra byte on put returns `413 OBJECT_TOO_LARGE`.
- [ ] `kb_get_object`, `kb_extract_text`, and `kb_index_document` return `413 OBJECT_TOO_LARGE` for an object one byte over the cap, and do not return the body.
- [ ] An object at the cap is still readable, and `maxChars` still trims text.
- [ ] `KB_PUBLIC_READ_ENABLED` is unchanged.
- [ ] `tika-minio-processor/universal_processor.py` is unchanged.
- [ ] MinIO was not contacted to prove this, and `.env` was not created.

### Rollback

Leave `_get_object_bytes_sync` as a full `resp.read()`. Put still rejects an oversized new upload. Get, extract, and index again load whatever is already in the bucket.
