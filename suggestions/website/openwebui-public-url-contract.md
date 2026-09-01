---
title: Open WebUI Public URL Contract
description: Constructional contract for official WEBUI_URL so OAuth, emails, and generated links match the Nginx vhost instead of localhost:8080.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Public URL Contract

## Problem

Operators reach Open WebUI at `https://oweb.tu.lan` through the existing Nginx vhost. Compose already publishes a localhost debug port (`127.0.0.1:8080:8080`) and sets many unofficial-looking `WEBUI_*` keys, but it never sets official **`WEBUI_URL`**.

Open WebUI uses `WEBUI_URL` for the public origin: OIDC/OAuth redirect URIs, some email and webhook links, and “copy link” style URLs. Without it, the app can emit `http://127.0.0.1:8080` or an empty origin. That produces “add an OAuth rewrite proxy” and “put a second hostname in the container” suggestions.

The stack already has a single public hostname. The missing piece is the official env key.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Nginx vhost `oweb.tu.lan` | Public HTTPS origin |
| Compose `open-webui` `127.0.0.1:8080` | Debug bind only |
| `DOMAIN` / `tu.lan` in `env.example` | LAN DNS suffix |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Safe Open WebUI config changes |
| Stage 12 `host-port-binding-contract.md` (expected sibling) | Host port rules — do not reopen |
| Stage 15 `open-webui-init-firstboot-contract.md` (expected sibling) | First-boot patches |
| Stage 29 `openwebui-tika-service-dns-contract.md` (expected sibling) | Tika/MinIO URLs, not the public origin |

Out of scope:

- An OAuth / header-rewrite sidecar
- Changing the Nginx server_name
- Removing the localhost debug port in the same PR unless it is clearly unused
- Rewriting Stage 10 contribution rules or Stage 12 port policy

## Proposal

Set the official key from the same domain the stack already uses:

```yaml
WEBUI_URL: ${WEBUI_URL:-https://oweb.${DOMAIN:-tu.lan}}
```

Add `WEBUI_URL=` (or the explicit HTTPS URL) to `env.example` next to the other Open WebUI keys. Document that saved Admin settings can override env until changed (same honesty Open WebUI already has for web search).

Do not invent `PUBLIC_URL`, `BASE_URL`, or a helper endpoint that “fixes links.”

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `WEBUI_URL` |
| Env schema | `env.example` | Document the key and the `oweb.` prefix |
| Docs | README Open WebUI row | Public URL is Nginx, not `:8080` |
| Optional | `generate-secrets` | Do not generate this; it is not a secret |

### Rules

1. **Official key only.** `WEBUI_URL` is what Open WebUI documents.
2. **Nginx remains the edge.** Do not add a second public hostname in Compose.
3. **Debug port stays local.** `127.0.0.1:8080` is not the public URL.
4. **GitHub remains intake.** “SSO in front of Open WebUI” is a different RFC.

### Suggested contributor checklist

```text
1. Confirm current Open WebUI docs still list WEBUI_URL
2. Add the key to Compose and env.example
3. Default to https://oweb.$DOMAIN
4. Recreate open-webui and check Admin / OAuth redirect hints
5. Do not add a URL-rewrite proxy
6. Do not change Tika/MinIO URLs in the same PR (Stage 29)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Public origin | Official `WEBUI_URL` | Custom `PUBLIC_URL` / rewrite sidecar |
| TLS hostname | Existing Nginx vhost + Pi-hole `*.tu.lan` | A second certificate product |
| OAuth | Provider config + this URL | An oauth2-proxy container by default |
| Debug access | Existing localhost `:8080` | Publishing 8080 on `0.0.0.0` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose + `env.example` line. Recreate `open-webui`.
3. If operators already set the URL in the Admin UI, leave the DB value; env is the clone-path default.

## Acceptance criteria

- [ ] `WEBUI_URL` is set on the `open-webui` service.
- [ ] `env.example` documents it as `https://oweb.tu.lan` (or `https://oweb.${DOMAIN}`).
- [ ] No new proxy or hostname service is added.
- [ ] Localhost `:8080` is not advertised as the public URL in README.

## Rollback

Remove the env key. Open WebUI falls back to its previous inferred origin. Nginx routing is unchanged.

## Success metrics

- OAuth / “copy link” URLs use `https://oweb.tu.lan`.
- Fewer issues that treat `:8080` as the community-facing origin.
- Contributors stop proposing a link-rewrite microservice.
