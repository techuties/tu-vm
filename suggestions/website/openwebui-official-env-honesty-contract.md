---
title: Open WebUI Official Env Honesty Contract
description: Constructional contract to keep only env keys Open WebUI actually reads, so generate-secrets and .env stay aligned with the official image.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Official Env Honesty Contract

## Problem

The `open-webui` service and `generate-secrets` maintain several `WEBUI_*` keys that look official but are not documented by Open WebUI (verify against the current image docs before deleting):

| Key in this repo | Compose / scripts today | Likely status |
|---|---|---|
| `WEBUI_SECRET_KEY` | Compose + `generate-secrets` | Official session/secret key |
| `WEBUI_JWT_SECRET_KEY` | Compose + `generate-secrets` | Often an alias or unused; confirm |
| `WEBUI_AUTH` | Compose `"true"` | Official |
| `WEBUI_AUTH_SECRET` | Compose + `generate-secrets` | Not in upstream env lists — decorative |
| `WEBUI_RATE_LIMIT` / `WEBUI_RATE_LIMIT_WINDOW` | Hardcoded in Compose | Not in upstream env lists — decorative |
| `WEBUI_URL` | **Missing** | Official — see the sibling public-URL contract |
| `TIKA_METADATA_EXTRACTION` | Compose `"true"` | Confirm; may be ignored |
| `PDF_EXTRACT_IMAGES` | Compose `"false"` | Confirm against current loader settings |

`generate-secrets` rotates `WEBUI_AUTH_SECRET` and prints it as if operators needed it. That produces “rate-limit sidecar” and “second JWT service” suggestions, and it wastes rotation attention on keys the process never reads.

This is the same honesty pattern as Stage 24 (`NGINX_WORKER_*`, `HEALTH_CHECK_*`) and Stage 30 (n8n login keys): **wire or delete**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI env docs | Source of truth for key names |
| `open-webui` environment block | Current mix of real and decorative keys |
| `generate-secrets` | Writes JWT + AUTH_SECRET defaults |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | How to change Open WebUI safely |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | Adding keys |
| Stage 24 `nginx-worker-env-wiring-contract.md` (expected sibling) | Wire-or-delete pattern |
| Sibling `openwebui-public-url-contract.md` | Adds the missing official `WEBUI_URL` |

Out of scope:

- A custom rate-limiter in front of `oweb.tu.lan` (Nginx already has zones; Stage 19/20)
- Inventing `WEBUI_*` keys that only this repo understands
- Rewriting Stage 10 contribution rules
- Changing Tika/MinIO URLs (Stage 29)

## Proposal

1. Open the current Open WebUI environment-variable list for the **pinned digest**.
2. Keep keys the image reads. Delete or stop generating keys it ignores.
3. If `WEBUI_JWT_SECRET_KEY` is an alias of `WEBUI_SECRET_KEY`, keep one and document the other as deprecated-in-repo.
4. Rate limits belong in Nginx (`limit_req`) or Open WebUI Admin settings — not invented Compose keys.
5. Land `WEBUI_URL` in the sibling contract, not as another invented name.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` | Delete unused keys after a cited upstream check |
| Scripts | `generate-secrets` | Stop writing unused secrets |
| Env schema | `env.example` | Match the surviving official set |
| Docs | README | One table: key → purpose → official? |

### Rules

1. **Upstream list wins.** A key is not official because this repo set it.
2. **Do not invent rate-limit env** when Nginx and Admin UI already exist.
3. **One secret is enough** if JWT and session keys are the same upstream concept.
4. **Cite the docs revision** in the PR (link + date) so the next digest bump can re-check.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Open upstream env docs for the pinned Open WebUI digest
2. Table every WEBUI_* / RAG_* / TIKA_* key in Compose
3. Delete or comment unused keys; keep a citation in the PR
4. Stop generate-secrets from writing unused names
5. Recreate open-webui; login and RAG still work
6. Do not add a rate-limit or JWT microservice
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Session secret | Official `WEBUI_SECRET_KEY` | A second JWT container |
| HTTP rate limit | Existing Nginx zones | Invented `WEBUI_RATE_LIMIT` |
| Auth toggle | Official `WEBUI_AUTH` | A helper “auth product” |
| Public URL | Sibling `WEBUI_URL` contract | `BASE_URL` aliases |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** after a docs citation: delete unused keys in one PR.
3. Existing `.env` leftover keys are harmless; stop generating new ones.

## Acceptance criteria

- [ ] Each remaining `WEBUI_*` key is cited as official or clearly marked local-only with a reason.
- [ ] `generate-secrets` does not rotate unused names.
- [ ] No new proxy or rate-limit container is added.
- [ ] `WEBUI_URL` is handled by the sibling page, not duplicated here as a rewrite.

## Rollback

Restore the previous environment block. Open WebUI ignores unknown keys, so deletion is low risk.

## Success metrics

- `generate-secrets` output matches keys the image reads.
- Fewer PRs that add `WEBUI_*` names copied from this repo’s folklore.
- Stage 24-style unused-key hygiene applies to the AI UI, not only Nginx.
