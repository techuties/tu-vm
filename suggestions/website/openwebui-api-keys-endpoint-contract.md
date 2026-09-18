---
title: Open WebUI API Keys Endpoint Contract
description: Constructional contract to enable official Open WebUI API keys with endpoint restrictions so n8n and MCP can call chat completions without a second API gateway.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI API Keys Endpoint Contract

## Problem

Community day-to-day work (n8n HTTP Request nodes, MCP tools, local scripts) needs a stable way to call Open WebUI's OpenAI-compatible API. The `open-webui` service does not set `ENABLE_API_KEYS` or `ENABLE_API_KEYS_ENDPOINT_RESTRICTIONS`. Operators then either share the browser session cookie, punch a second reverse-proxy path, or invent a TU-VM “chat gateway.”

Official Open WebUI already issues per-user API keys and can lock them to a path allowlist. That is the community integration framework; it is unused in Compose today.

This is distinct from:

- Stage 27 helper `CONTROL_TOKEN` / docker-socket-proxy (dashboard control plane, not chat completions)
- Stage 32 `browserless-token-required-contract.md` (Playwright TOKEN)
- Stage 32 `openwebui-signup-first-user-contract.md` (`ENABLE_SIGNUP`, not keys)
- Stage 33 `openwebui-community-sharing-contract.md` (public catalog, not API keys)
- Stage 34 `openwebui-cors-origin-contract.md` (browser Origin header, not bearer keys)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | `WEBUI_AUTH=true`; no API-key flags |
| Official Open WebUI hardening | `ENABLE_API_KEYS`, `ENABLE_API_KEYS_ENDPOINT_RESTRICTIONS`, `API_KEYS_ALLOWED_ENDPOINTS` |
| n8n / MCP gateway | Already the community automation plane; they should call oweb with a key |
| GitHub Issues | Intake for extra allowed endpoints |

Out of scope:

- A second OpenAI-compatible gateway or LiteLLM product
- Putting a shared API key in `env.example`
- Rewriting Stage 27 control-token or Stage 32 Browserless TOKEN
- Enabling keys without an endpoint allowlist

## Proposal

Set official keys so admins can mint tokens in the Open WebUI UI, and restrict what those tokens can hit:

```text
ENABLE_API_KEYS: "true"
ENABLE_API_KEYS_ENDPOINT_RESTRICTIONS: "true"
API_KEYS_ALLOWED_ENDPOINTS: /api/chat/completions,/api/v1/models
```

Do not publish a default token. Community workflows store the key in n8n credentials (see Stage 33 env-block: Code nodes must not read Compose env). Extra paths (`/api/v1/files`, retrieval) stay Issues until a playbook names them.

If the team wants keys off until the first admin exists, keep `ENABLE_API_KEYS=false` in Compose and document the three lines as the opt-in; do not invent a helper endpoint that mints keys.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official enable + restriction + path list |
| Env schema | `env.example` | Comment the three official keys; no token value |
| Docs | playbook + CONTRIBUTING | How to mint a key, store it in n8n credentials, rotate it |
| Intake | GitHub suggestion form | “Allow API key path X” with a caller (n8n/MCP) |

### Rules

1. **Official keys only.** Do not invent `TU_VM_OWEB_API_TOKEN`.
2. **Never commit a live key.** `env.example` stays comment-only.
3. **Restrict endpoints** whenever keys are enabled.
4. **Do not confuse with CONTROL_TOKEN.** Helper start/stop is a different secret.
5. **GitHub remains intake.** Path expansions are Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_API_KEYS
2. Set enable + endpoint restrictions + the two default paths
3. Recreate Open WebUI, mint a key as admin, call /api/v1/models
4. Confirm a key cannot call an unlisted admin path
5. Document n8n credential storage; do not add a gateway
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Programmatic chat | Official Open WebUI API keys | A second LiteLLM / gateway |
| Least privilege | Official endpoint restrictions | One shared cookie |
| Secret storage | n8n credentials + Stage 33 env-block | Putting the key in Compose env |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines + a playbook paragraph.
3. Mention key minting in release notes (admin UI, no default secret).

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_API_KEYS` (true, or documented false-with-opt-in).
- [ ] When true, endpoint restrictions are on and `API_KEYS_ALLOWED_ENDPOINTS` is non-empty.
- [ ] No API key is committed to the repo.
- [ ] Docs show mint + n8n credential storage.
- [ ] No second chat gateway is added.
- [ ] Stage 27 / 32 / 33 token and sharing pages are not rewritten.

## Rollback

Set `ENABLE_API_KEYS=false` or remove the keys (image default). Existing minted keys stop working. User data remains.

## Success metrics

- A community n8n workflow can call `/api/chat/completions` with a minted key.
- An unlisted path returns forbidden for that key.
- Integration PRs cite these official flags instead of a new gateway.
