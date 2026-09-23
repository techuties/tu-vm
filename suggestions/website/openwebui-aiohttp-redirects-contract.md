---
title: Open WebUI Outbound Redirect Contract
description: Constructional contract to pin official AIOHTTP_CLIENT_ALLOW_REDIRECTS=false so Open WebUI does not follow outbound HTTP redirects.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Outbound Redirect Contract

## Problem

The pinned Open WebUI image sets `AIOHTTP_CLIENT_ALLOW_REDIRECTS` from the environment in `backend/open_webui/env.py`, default `False`. The comment in that revision says outbound HTTP requests do not follow `3xx` redirects when the flag is false. It is not a `ConfigVar`.

Current Open WebUI env reference says this default has held since v0.9.6 and names the call sites: RAG web loader, image loading and base64 conversion, OAuth pre-flight, code-interpreter login, and tool-server execution. Following redirects lets a public URL that passed an allowlist `302` to a loopback, RFC 1918, or cloud-metadata address. Compose does not pin the flag. TU-VM already sets `WEB_LOADER_ENGINE` to `safe_web`. That loader choice is not a substitute for the redirect flag.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Default `False`; startup read |
| Open WebUI env reference | Redirect following is an SSRF class; enable only with other controls |
| `WEB_LOADER_ENGINE` | Already `safe_web` unless overridden |
| GitHub Issues | Place to allow redirects for a named shortlink case |

Out of scope:

- A redirect firewall, egress proxy, or URL sandbox service
- Changing `WEB_LOADER_ENGINE` or Playwright / Browserless settings
- Rewriting Stage 37 code-interpreter or code-execution contracts
- Enabling redirects by default "so link shorteners work"

## Proposal

Pin the official default on the `open-webui` service:

```text
AIOHTTP_CLIENT_ALLOW_REDIRECTS: "false"
```

Do not invent `TU_VM_BLOCK_REDIRECTS`. Setting `true` needs an Issue that names the redirect case and the other control (egress limits or `WEB_FETCH_FILTER_LIST` covering internal ranges). The env reference says both are required together.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `false` |
| Env schema | `env.example` | Comment: do not follow 3xx |
| Docs | Open WebUI playbook | Shortlinks are an Issue, not a default |
| Loader | `WEB_LOADER_ENGINE` | Leave `safe_web` as it is |

### Rules

1. **Official flag.** The pinned image already defaults to false. The pin keeps a later `true` in review.
2. **Startup-only.** Recreate Open WebUI after a change.
3. **Loader and redirects are separate.** `safe_web` does not replace this key.
4. **No new egress product.** Use the official flag.
5. **GitHub remains intake.** A true value names the sites and the compensating control.

### Suggested contributor checklist

```text
1. Confirm the pinned image still defaults AIOHTTP_CLIENT_ALLOW_REDIRECTS to False
2. Set AIOHTTP_CLIENT_ALLOW_REDIRECTS=false on the open-webui service
3. Recreate Open WebUI
4. Confirm a web-loader URL that only answers with a 302 is not followed
5. Leave WEB_LOADER_ENGINE unchanged
6. Do not add a redirect proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Redirect policy | Official `AIOHTTP_CLIENT_ALLOW_REDIRECTS=false` | A URL firewall container |
| Page fetch | Existing `safe_web` loader | A new crawler |
| Exceptions | GitHub Issue plus `WEB_FETCH_FILTER_LIST` | A standing `true` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an Open WebUI recreate.
3. Allowing redirects is an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `AIOHTTP_CLIENT_ALLOW_REDIRECTS=false`.
- [ ] `WEB_LOADER_ENGINE` is not changed by this page.
- [ ] No redirect proxy or URL sandbox is added.

## Rollback

Remove the pin to restore the same official default of false. Setting `true` is a reviewed Issue.

## Success metrics

- Outbound Open WebUI HTTP calls do not follow 3xx responses.
- Web search still uses the existing loader.
