---
title: n8n Postgres Service DNS Contract
description: Constructional contract for pointing n8n at the postgres Compose service name instead of the static 172.20.0.10 IPAM address, reusing Docker DNS rather than a second resolver product.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Postgres Service DNS Contract

## Problem

n8n is the only first-party client that bypasses Compose DNS for Postgres:

```yaml
      DB_POSTGRESDB_HOST: 172.20.0.10
      DB_POSTGRESDB_PORT: 5432
```

Everyone else uses the service name (`postgres`, `affine_postgres`). Open WebUI already does:

```yaml
DATABASE_URL: postgresql://…@postgres:5432/…
```

Stage 18 treats `172.20.0.10` as an allocated address that **can move** if the registry is rebuilt. A hardcoded client makes that move a silent outage. Stage 21 already prefers service names for **Nginx upstreams**. n8n’s env is the leftover application client.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose service name `postgres` + `172.20.0.11` DNS | In-network name resolution |
| Open WebUI `DATABASE_URL` host `postgres` | Pattern to copy |
| `n8n` static IP `172.20.0.15` | Keep for IPAM; do not use as a client target |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Who owns `172.20.0.10` |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling) | Service names at the edge |
| `N8N_INTERNAL_URL: http://ai_n8n:5678` | Container **name** is already used elsewhere — prefer **service** name for Compose |

Out of scope:

- Removing static `ipv4_address` from services (Stage 18)
- Nginx resolver changes (Stage 21)
- Switching n8n off Postgres
- PgBouncer (Stage 23)

## Proposal

Set `DB_POSTGRESDB_HOST` to the Compose service name `postgres`. Keep user, password, database, and schema keys as they are.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `n8n` | `DB_POSTGRESDB_HOST` | `postgres` |
| Docs | this page + Stage 18 | Application clients must not embed IPAM |
| `env.example` | only if a host override exists | Do not add `N8N_POSTGRES_IP` |

### Rules

1. **Service name, not container name.** Use `postgres`, not `ai_postgres`, so Compose DNS (not `/etc/hosts` hacks) is the source of truth.
2. **Do not add a second host alias** unless a measured DNS failure appears.
3. **Do not “fix” this by documenting the IP.** The IP belongs in Stage 18’s registry only.
4. **Keep schema `n8n`.** This is a hostname change, not a database move.
5. **GitHub remains intake.** Requests for “external managed Postgres” stay Issues (Stage 23 pooling).

### Suggested contributor checklist

```text
1. Replace DB_POSTGRESDB_HOST 172.20.0.10 with postgres
2. Leave DB_POSTGRESDB_* user/password/schema unchanged
3. Confirm docker compose config still renders
4. Start n8n and confirm the editor reaches the existing n8n schema
5. grep compose for other hardcoded 172.20.0.10 clients (should be none)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| In-stack hostname | Compose service DNS | Hardcoded IPAM clients |
| Edge hostnames | Stage 21 Nginx resolver | Copying `172.20.0.10` into nginx |
| Address changes | Stage 18 registry + DNS | Hunting env keys for dotted quads |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one-line Compose change; no data migration.
3. If a rare DNS miss appears, add an explicit `networks` alias on `postgres`, do not revert to the IP.

## Acceptance criteria

- [ ] `n8n` `DB_POSTGRESDB_HOST` is `postgres`.
- [ ] No other application env embeds `172.20.0.10` as a client target.
- [ ] `ipv4_address` on `postgres` remains (IPAM unchanged).
- [ ] `docker compose config` still renders with current interpolation.
- [ ] Existing n8n workflows still load (same DB/schema).

## Rollback

Restore `DB_POSTGRESDB_HOST: 172.20.0.10`. Data is unchanged.

## Success metrics

- Stage 18 IPAM edits do not require an n8n hotfix.
- Community PRs that add a new DB client use the service name.
- Grep for `172.20.0.10` in env blocks stays limited to the `postgres` service itself.
