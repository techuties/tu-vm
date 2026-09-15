---
title: Helper Domain Env Wiring Contract
description: Constructional contract to pass existing DOMAIN into helper_index so dashboard status URLs match operator hostname instead of always defaulting to tu.lan.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Helper Domain Env Wiring Contract

## Problem

`helper/uploader.py` already builds community-facing service links from `DOMAIN`:

```text
domain = os.environ.get('DOMAIN', 'tu.lan')
# landing, oweb, n8n, affine, pihole, …
```

Compose `helper_index` only passes:

```text
HOST_IP=${HOST_IP}
CONTROL_TOKEN=${CONTROL_TOKEN:-}
```

Docker Compose does **not** inject the whole `.env` into the container. `DOMAIN` in the operator’s `.env` is used for Compose interpolation and for `tu-vm.sh` certificates, but the helper process always sees the Python default `tu.lan`.

The landing dashboard therefore advertises `https://oweb.tu.lan` even when the operator set `DOMAIN=lab.example`. That fights Stage 31 public-origin and Open WebUI `WEBUI_URL` work.

This is **not** a leftover MinIO credential in the helper (this run: no `MINIO_*` in `helper/`). Stage 27 helper contracts (image pin, `/health`, socket-proxy) stay as expected siblings — do not rewrite them.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `uploader.py` `/status` | Already DOMAIN-aware |
| `helper_index` environment | Missing `DOMAIN` |
| `HOST_IP` | Already wired the same way |
| Nginx HTML | Still has some hardcoded `oweb.tu.lan` strings (dashboard chrome) |
| Stage 5 control-plane contract (expected sibling) | Allowlist / helper safety |
| Stage 21 helper module split (expected sibling) | File layout, not env |
| Stage 31 public-origin + WEBUI_URL | App origins; helper should match |

Out of scope:

- A community API or second status schema
- Rewriting `/status/full` fixture shape beyond adding nothing new (URLs already exist)
- Baking DOMAIN into the helper image
- Stage 27 docker-socket-proxy (code, not this page)

## Proposal

Add to `helper_index`:

```text
- DOMAIN=${DOMAIN:-tu.lan}
```

Default matches today’s Python fallback. Optional: pass `HOST_IP` and `DOMAIN` as a tiny `x-helper-env` anchor if Stage 28 `x-*` DRY is already in the tree (expected sibling). Do not add `env_file: .env` on the helper (that would leak every secret into a container that already has a Docker socket).

Dashboard HTML hardcoded hosts are a **follow-up**: either leave chrome as tu.lan documentation or interpolate at serve time from `/status`. Do not invent a static-site build for `index.html` in this contract.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `helper_index.environment` | `DOMAIN=${DOMAIN:-tu.lan}` |
| Env schema | Already has `DOMAIN` | No new key |
| Tests | `/status/full` fixture | Unchanged if default stays tu.lan |
| HTML | `nginx/html/index.html` | Optional later; prefer live `/status` links |

### Rules

1. **Pass the existing key.** Do not rename to `TU_VM_DOMAIN` without a Stage 12 RFC.
2. **No full `env_file`.** The helper must not receive `POSTGRES_PASSWORD` et al. just to learn the hostname.
3. **Default tu.lan.** Behavior-identical for current clones.
4. **Do not add MinIO keys** to the helper “while you are there.”
5. **GitHub remains intake.** A theming/branding domain product is out of scope.

### Suggested contributor checklist

```text
1. Confirm helper/uploader.py reads DOMAIN
2. Confirm helper_index environment lacks DOMAIN
3. Add DOMAIN=${DOMAIN:-tu.lan} only
4. Recreate helper; curl /status shows custom domain when DOMAIN is set
5. Default unset → tu.lan (fixture still valid)
6. Do not add env_file: .env
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hostname | Existing `DOMAIN` | Helper-specific domain file |
| Status payload | Existing `/status` keys | A new `/status/urls` endpoint |
| Secrets | Explicit allowlisted env | `env_file: .env` |
| Dashboard chrome | Existing helper-driven links | Rebuilding index.html as a SPA |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line. Recreate `ai_helper_index`.
3. Optional: replace remaining hardcoded hosts in `index.html` with the status payload the page already fetches.

## Acceptance criteria

- [ ] `helper_index` receives `DOMAIN` with `tu.lan` default.
- [ ] `/status` `services.*` URLs follow `.env` `DOMAIN`.
- [ ] No `env_file: .env` on the helper.
- [ ] `/status/full` contract remains valid for the default domain.
- [ ] No MinIO credentials added to the helper.

## Rollback

Remove the env line. Helper returns to the in-code `tu.lan` default.

## Success metrics

- Custom-domain operators see matching links on the landing page after helper recreate.
- Contributors stop proposing a “URL config.json” bind-mount.
- Helper env stays a short allowlist (`HOST_IP`, `CONTROL_TOKEN`, `DOMAIN`).
