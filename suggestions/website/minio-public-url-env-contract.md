---
title: MinIO Public URL Env Contract
description: Constructional contract to interpolate MINIO_SERVER_URL and MINIO_BROWSER_REDIRECT_URL from .env instead of hardcoding the tu.lan console URLs in Compose.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# MinIO Public URL Env Contract

## Problem

`env.example` already documents the official MinIO console URL keys:

```text
MINIO_SERVER_URL=https://api.minio.tu.lan
MINIO_BROWSER_REDIRECT_URL=https://minio.tu.lan
```

Compose ignores those keys and hardcodes the same strings:

```yaml
MINIO_SERVER_URL: "https://api.minio.tu.lan"
MINIO_BROWSER_REDIRECT_URL: "https://minio.tu.lan"
```

`MINIO_CONSOLE_ADDRESS` is also listed in `env.example` (`:9001`) while Compose sets it twice (environment **and** `command: server /data --console-address ":9001"`).

Operators who change `DOMAIN` or the MinIO vhost names edit `.env`, recreate MinIO, and still see console redirects to `*.tu.lan`. That produces “add a MinIO URL rewrite sidecar” suggestions. Stage 30 already interpolates **`MINIO_ROOT_USER`**. This page is the leftover **public URL** pair, not a second identity store.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official MinIO `MINIO_SERVER_URL` | API URL the console advertises |
| Official `MINIO_BROWSER_REDIRECT_URL` | Browser redirect after login |
| Nginx vhosts `api.minio.tu.lan` / `minio.tu.lan` | Actual public HTTPS |
| `env.example` MinIO block | Keys already named correctly |
| Stage 23 `minio-object-versioning-ilm-contract.md` (expected sibling) | Versioning / ILM — do not rewrite |
| Stage 24 `minio-sse-kms-contract.md` (expected sibling) | Encryption — do not rewrite |
| Stage 30 `minio-root-user-env-contract.md` (expected sibling) | Root user interpolation — do not rewrite |

Out of scope:

- Changing Nginx vhost names
- A console-rewrite proxy
- Replacing `mc` with another client
- Hardcoding `MINIO_ROOT_USER` again (Stage 30)

## Proposal

Interpolate the keys that `env.example` already has:

```yaml
MINIO_SERVER_URL: ${MINIO_SERVER_URL:-https://api.minio.${DOMAIN:-tu.lan}}
MINIO_BROWSER_REDIRECT_URL: ${MINIO_BROWSER_REDIRECT_URL:-https://minio.${DOMAIN:-tu.lan}}
MINIO_CONSOLE_ADDRESS: ${MINIO_CONSOLE_ADDRESS:-:9001}
```

Keep the `command:` `--console-address` in sync with `MINIO_CONSOLE_ADDRESS` (or drop the duplicate flag if the env key is enough for the pinned image — cite MinIO docs in the PR).

Do not add `MINIO_PUBLIC_URL` or a helper that rewrites `Location` headers.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `minio` environment | Interpolate the three official keys |
| Env schema | `env.example` | Already present; add `DOMAIN` substitution comment |
| Docs | README MinIO URLs | Point at `.env`, not Compose literals |
| Nginx | unchanged | Vhosts stay the source of TLS names |

### Rules

1. **Official MinIO keys.** No invented public-URL aliases.
2. **`.env` is the clone-path override.** Compose supplies domain-aware defaults only.
3. **Stage 30 identity stays separate.** Root user interpolation is not this PR.
4. **Internal clients keep `http://minio:9000`.** Public URLs are for the console/browser, not the processor.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Grep MINIO_SERVER_URL and MINIO_BROWSER_REDIRECT_URL
2. Replace hardcoded strings with ${...} interpolation
3. Confirm processor / KB still use service DNS, not these HTTPS URLs
4. Recreate minio; console redirect matches .env
5. Do not add a rewrite sidecar
6. Do not reopen Stage 30 MINIO_ROOT_USER
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Console public URL | Official MinIO env keys | A rewrite proxy |
| TLS names | Existing Nginx vhosts | A second certificate for MinIO |
| Domain change | `DOMAIN` + `.env` | Editing Compose per site |
| Identity | Stage 30 `${MINIO_ROOT_USER}` | Hardcoded `admin` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: interpolate three keys. Recreate `minio`.
3. Operators with a custom domain set the two HTTPS URLs in `.env` once.

## Acceptance criteria

- [ ] Compose no longer hardcodes `https://api.minio.tu.lan` / `https://minio.tu.lan`.
- [ ] `env.example` keys are the values Compose interpolates.
- [ ] Processor and KB still talk to `minio:9000` (or the Stage 30 service-DNS default), not the public HTTPS URL.
- [ ] No rewrite sidecar is added.

## Rollback

Restore the string literals. Existing `minio_data` is unchanged.

## Success metrics

- Custom `DOMAIN` operators get a matching console redirect without a Compose fork.
- Contributors stop proposing a MinIO URL microservice.
- Stage 30 identity work and this URL work stay in separate, reviewable PRs.
