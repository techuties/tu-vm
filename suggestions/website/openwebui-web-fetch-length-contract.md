---
title: Open WebUI Fetch URL Length Contract
description: Constructional contract to set official WEB_FETCH_MAX_CONTENT_LENGTH=50000 for the built-in fetch-url tool, which otherwise returns an unlimited page into the model context.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Fetch URL Length Contract

## Problem

The pinned Open WebUI image (revision `02dc3e689ceac915a870b373318b99c029ddf603`) defines `WEB_FETCH_MAX_CONTENT_LENGTH` as a `ConfigVar`. Unset, the value is `None`.

The admin tooltip in that revision says the field is the maximum characters to return from fetched URLs, and that empty means no limit. The image changelog records that this key replaced a hardcoded 50,000 character cap.

Enforcement in this revision is in `backend/open_webui/tools/builtin.py` `fetch_url`: when `max_length` is a positive integer and the extracted text is longer, the tool keeps that many characters and appends a truncation marker. `get_content_from_url` itself does not apply the cap. The retrieval URL-import path (`routers/retrieval.py`) calls `get_content_from_url` and does not read `WEB_FETCH_MAX_CONTENT_LENGTH`.

Compose does not set the key. The built-in fetch tool can therefore place an entire page into a chat on a container limited to 2G RAM.

This is not Stage 39 `RAG_FILE_MAX_SIZE` (chat file uploads, megabytes) and not Stage 9 Nginx `client_max_body_size`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `config.py` | Unset length is `None` |
| Pinned `tools/builtin.py` `fetch_url` | Truncates to the ConfigVar when it is a positive integer |
| Pinned admin Web Search screen | Documents the unit as characters; empty means no limit |
| Stage 13 web search contract (expected sibling) | Engine and Playwright wiring, not this cap |
| Stage 39 RAG upload limits (expected sibling) | File bytes and extensions |
| Stage 36 PersistentConfig (expected sibling) | Stored admin values override env |
| GitHub Issues | Place to raise the cap or to ask the retrieval import path to honor the same key |

Out of scope:

- A fetch proxy, readability service, or second truncator
- Editing Nginx body size
- Claiming the retrieval URL-import path truncates in this revision (it does not)
- `WEB_LOADER_CONCURRENT_REQUESTS` (image default 10; leave it)

## Proposal

Set the official key on the `open-webui` service:

```text
WEB_FETCH_MAX_CONTENT_LENGTH: "50000"
```

`50000` is characters, matching the admin tooltip and the cap this image removed. It is a starting laptop budget for the built-in tool, not a new upstream default.

The key is a `ConfigVar`. After the first successful start, the Admin → Web Search value wins over a later Compose edit unless Stage 36 PersistentConfig is implemented in **code**.

If URL import into the knowledge base should use the same number, that is a separate Issue against upstream behavior. Do not patch a private truncator into `get_content_from_url` on this page.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `WEB_FETCH_MAX_CONTENT_LENGTH: "50000"` |
| Env schema | `env.example` | Comment the unit (characters) and which path enforces it |
| Docs | Open WebUI playbook | Long pages belong in MinIO, not in one tool result |
| Persistence | Stage 36 | Implement in code so the pin survives Admin saves |

### Rules

1. **Official key only.** Do not invent `TU_VM_FETCH_MAX_CHARS`.
2. **Unit is characters** in this image, not bytes and not megabytes.
3. **Empty means unlimited** on the tool path. Do not "clear" the key to disable a cap.
4. **Do not claim every loader truncates.** This revision enforces the key in `fetch_url` only.
5. **GitHub remains intake** for a higher cap or for upstream retrieval to honor the key.

### Suggested contributor checklist

```text
1. Confirm fetch_url still truncates only when WEB_FETCH_MAX_CONTENT_LENGTH is a positive integer
2. Set the key to 50000 on the open-webui service
3. Recreate Open WebUI
4. Confirm a long page fetched by the built-in URL tool ends with the truncation marker
5. Leave Nginx client_max_body_size and Stage 39 RAG file keys unchanged
6. If Admin → Web Search already stored a length, apply Stage 36 in code or update the stored config on purpose
7. Do not add a fetch proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tool result size | Official `WEB_FETCH_MAX_CONTENT_LENGTH` | A truncating HTTP proxy |
| Chat file bytes | Stage 39 RAG file keys | Reusing this character cap as a byte limit |
| Bulk documents | Existing MinIO + Tika processor | Stuffing whole sites through the fetch tool |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. A different length, or enforcement on the retrieval import path, needs an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `WEB_FETCH_MAX_CONTENT_LENGTH=50000`.
- [ ] The page states that this revision enforces the cap in `fetch_url`, not in `get_content_from_url`.
- [ ] Nginx body size and Stage 39 upload keys are unchanged.
- [ ] No fetch proxy is added.

## Rollback

Remove the key to restore unlimited tool output (`None`). That rollback is a reviewed Issue on a 2G container, not a silent default.

## Success metrics

- Built-in fetch-url results stop at 50,000 characters plus the truncation marker.
- The Open WebUI memory limit stays 2G.
