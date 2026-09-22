---
title: Open WebUI Iframe CSP Contract
description: Constructional contract to set official IFRAME_CSP so Artifact and preview iframes cannot open outbound network connections.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Iframe CSP Contract

## Problem

Open WebUI renders LLM-generated and user-uploaded HTML inside `srcdoc` iframes for Artifacts, code and HTML previews, file previews, and citation modals. The iframe `sandbox` attribute is the baseline isolation. Official hardening documents `IFRAME_CSP` as an additional policy injected into every iframe document. The default is an empty string, which means sandbox-only.

On a shared community VM, a model can emit HTML that calls `fetch`, `XMLHttpRequest`, or `WebSocket` from the operator's browser. That is an exfiltration path for anything the page can read. Compose does not set `IFRAME_CSP` today.

This is distinct from:

- Stage 37 `openwebui-code-execution-contract.md` (in-chat run buttons)
- Stage 37 `openwebui-code-interpreter-contract.md` (model `execute_code`)
- Stage 34 `openwebui-cors-origin-contract.md` (API CORS, not artifact iframes)
- Nginx `X-Frame-Options: DENY` on the n8n vhost (parent-page framing, not `srcdoc` CSP)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | Example CSP that blocks iframe network calls |
| Official env reference | `IFRAME_CSP` string; empty default keeps sandbox-only |
| `open-webui` environment | Key unset |
| Iframe `sandbox` | Remains in the product; this contract adds CSP |

Out of scope:

- A custom artifact renderer or HTML sanitizer service
- Changing Nginx security headers on the dashboard or n8n vhost
- Disabling Artifacts entirely
- Rewriting the code-execution or CORS pages

## Proposal

Set the official example policy on the `open-webui` service:

```text
IFRAME_CSP: "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; connect-src 'none'"
```

Use that official string. It allows inline scripts inside the sandbox, which Artifacts need, and sets `connect-src 'none'` so generated HTML cannot open network connections. Do not invent `TU_VM_ARTIFACT_CSP`. Do not strip `'unsafe-inline'` in the same change; an overly strict policy breaks legitimate artifacts and should be a separate Issue with a screenshot of the broken preview.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official example CSP string |
| Env schema | `env.example` | Comment that artifact iframes cannot `fetch` |
| Docs | Open WebUI playbook | One line on expected artifact limits |
| Code | Recreate Open WebUI | Confirm a preview cannot reach the network |

### Rules

1. **Official key only.** `IFRAME_CSP`, using the hardening-guide example as the first value.
2. **Keep the sandbox.** CSP is defense in depth on top of the product iframe sandbox.
3. **Do not retune Nginx headers here.** Parent-page framing stays on the Nginx contracts.
4. **Do not disable Artifacts.** The goal is a network boundary inside the preview.
5. **Stricter policies need an Issue.** Include which artifact feature broke.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents IFRAME_CSP
2. Set the official example string on the open-webui service
3. Recreate Open WebUI and open an HTML artifact preview
4. Confirm inline artifact UI still renders
5. Confirm the preview does not complete a fetch or WebSocket
6. Do not add a sanitizer sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Artifact network limit | Official `IFRAME_CSP` | A custom HTML sandbox service |
| Inline artifact scripts | Official example (`unsafe-inline` / `unsafe-eval` inside sandbox) | A blank CSP that breaks previews |
| Parent framing | Existing Nginx headers | Mixing vhost headers into this env key |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and a container recreate.
3. Artifacts that need outbound network access are out of the default community profile.

## Acceptance criteria

- [ ] `open-webui` sets `IFRAME_CSP` to the official hardening example.
- [ ] No artifact renderer or sanitizer service is added.
- [ ] Nginx `X-Frame-Options` and CORS env are unchanged by this contract.

## Rollback

Unset `IFRAME_CSP` (official empty default) and recreate Open WebUI. Previews return to sandbox-only behavior.

## Success metrics

- Artifact and citation previews still render inline HTML.
- Those iframes do not complete outbound `fetch` or WebSocket calls.
