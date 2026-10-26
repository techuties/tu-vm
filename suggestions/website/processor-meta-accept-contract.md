---
title: Processor Meta Accept Contract
description: Constructional contract so the document processor asks Tika /meta for JSON, and does not store that JSON in S3 user metadata until the encoded header fits.
last_updated: 2026-10-26
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Processor Meta Accept Contract

## Problem

The document processor reports "extracting metadata" and then stores no Tika metadata.

`tika-minio-processor/universal_processor.py` builds the text request with an explicit Accept header:

```text
headers = {"Content-Type": content_type, "Accept": "text/plain"}
PUT {TIKA_URL}/tika
```

The metadata request a few lines later does not:

```text
metadata_headers = {"Content-Type": content_type}
PUT {TIKA_URL}/meta
if metadata_response.status_code == 200:
    metadata = metadata_response.json()
```

`Content-Type` on that call is the uploaded file type, not the response type. On this host, `requests` 2.32.5 `default_headers()` sends `Accept: */*`. Preparing a `PUT` with only `Content-Type: application/pdf` keeps that Accept value.

Apache Tika 3.3.1 `MetadataResource` is `@Path("/meta")`. The `PUT` method is:

```text
@Produces({"text/csv", "application/json"})
```

`text/csv` is listed first. The Tika 3.3.1 server README shows the unadorned call as CSV:

```text
curl -T price.xls http://localhost:9998/meta
```

`curl` and `requests` both send `Accept: */*` when the caller does not set one. A CSV body makes `response.json()` raise. The processor catches `Exception`, logs a warning, and leaves `metadata` as `{}`.

`store_processed_content` only copies metadata when the dict is non-empty:

```text
if metadata:
    s3_metadata['extracted-metadata'] = quote(metadata_json, safe='')
```

An empty dict skips the header. The `.txt` object can still be written. The status line said metadata was extracted. The object has none.

The text path in this same file, and the older `tika_processor.py` comment ("without Accept header, Tika returns HTML"), already treat Accept as required. The `/meta` call is the one that skipped it.

Checked on 2026-10-26 by reading the processor, replaying `requests` header preparation, and reading Tika 3.3.1 `MetadataResource.java` plus the server README. No Tika container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `universal_processor.py` text `PUT /tika` | Already sends `Accept: text/plain` |
| `universal_processor.py` `PUT /meta` | The call that needs `Accept: application/json` |
| `tika_processor.py` comment | In-repo note that a missing Accept selects the wrong Tika body |
| `store_processed_content` | Writes `extracted-metadata` only when the dict is non-empty |
| Stage 54 metadata header (open PR #80) | Encoded user-metadata length. This page does not redo that table |
| Stage 58 OCR runtime (open PR #84) | `tika-config.xml` and the full image. Unchanged here |
| Stage 41 byte budget (open PR #67) | How many object bytes are read. Unchanged here |
| Open WebUI metadata flag (this stage) | The unread Compose key. Metadata stays in this processor |

Out of scope:

- A metadata database or a wrapper in front of Tika
- Changing the `/tika` text Accept header
- Editing `tika-config.xml` or OCR strategy headers
- A new S3 metadata schema
- Restating the Stage 54 percent-encoding length table

## Proposal

Ask `/meta` for the JSON media type it already produces. Keep the text object storable when that JSON is large.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Request | `PUT /meta` headers | Set `Accept: application/json` next to `Content-Type` |
| Parse | Same block | Keep `response.json()` only after that header. A non-JSON 200 stays a warning and an empty dict |
| Store | `store_processed_content` | Do not attach `extracted-metadata` unless the encoded value fits the limit Stage 54 already specifies |
| Order | One PR | Ship the Accept header together with that omit-or-cap. Accept alone turns today's empty dict into a body that can fail `put_object` |

Stage 54 owns the arithmetic (the cut runs before `quote()`, and the encoded value can pass 2048 bytes). This page does not replace that arithmetic. It says the Accept fix is unsafe to ship by itself, because a parsed dict reaches the header Stage 54 already shows can reject the upload. Until that cap lands, omit `extracted-metadata` and still store the text.

### Rules

1. **Send `Accept: application/json` on `/meta`.** `Accept: */*` is the CSV example in the Tika 3.3.1 README.
2. **Leave `Accept: text/plain` on `/tika`.** That call already matches the plain-text method.
3. **Do not fail the file when metadata is CSV or oversized.** Text storage is the pipeline result. Metadata is additional.
4. **Use Stage 54's header budget.** Do not invent a second byte limit in this page.
5. **Do not add a Tika proxy.** The processor already has the HTTP client.

### Suggested contributor checklist

```text
1. Confirm the /meta headers include Accept: application/json
2. Confirm the /tika text headers still include Accept: text/plain
3. Confirm a CSV or invalid JSON body logs a warning and leaves metadata empty
4. Confirm an oversized metadata dict does not fail put_object; the text object is still stored
5. Confirm tika-config.xml is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Metadata media type | Tika's existing `application/json` producer | A CSV parser in TU-VM |
| Text media type | The Accept header the text call already sets | A second Tika endpoint |
| Header size | Stage 54 encoded-length rule | A new object store |
| Failure mode | Store the text, warn on metadata | Retry forever because user metadata was too big |
| Intake | GitHub Issue | A forked Tika server |
