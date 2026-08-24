---
title: Compose Non-Root User Contract
description: Constructional contract for Compose user: on stateless first-party services, without a new identity platform or breaking docker.sock helper ops.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: security
impact: high
---

# Compose Non-Root User Contract

## Problem

Most first-party and several vendor services run as root inside the container:

- `tika_minio_processor` — Alpine Python, no `USER`, writes only `/tmp`
- `helper_index` — root plus **docker.sock** (needs a mapped docker GID, not a blind `user: "1000"`)
- MCP tool images (`mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, `mcp-memory`) — local builds, no `USER`
- `tika` — official image often root unless configured

Stage 18 already requires **cap_drop / no-new-privileges / docker.sock review**. Stage 23 covers **read-only rootfs for Nginx**. Neither page says **which numeric `user:` is allowed on which service**. Root remains the silent default for community Compose PRs.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `user:` | Numeric UID:GID without image rebuild |
| Official Postgres / Redis / Nginx / MinIO / Pi-hole | Already drop to a service user in entrypoint |
| Helper docker.sock mount | Requires membership of the **host docker GID** |
| Processor `/tmp` share with helper | Must stay writable by both UIDs or stay world-writable tmpfs |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | caps / no-new-privileges |
| Stage 23 `read-only-rootfs-proxy-contract.md` (expected sibling) | Nginx `read_only` + tmpfs |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Host sudoers, not container UID |

Out of scope:

- LDAP, Keycloak, or a cluster identity product
- Running helper **without** docker.sock (that is a larger control-plane split)
- Changing volume ownership of `postgres_data` / `minio_data` (vendor users already own those)
- Kubernetes `runAsNonRoot` / Pod Security

## Proposal

Declare `user:` on **stateless first-party** services that do not need docker.sock. Treat helper as a documented exception: keep root **or** map `user: "<uid>:<docker_gid>"` only after `tu-vm.sh doctor` prints the host docker GID.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Easy non-root | `tika_minio_processor`, `mcp-fetch`, `mcp-memory` | `user: "65534:65534"` (nobody) if `/tmp` or `/data` is writable |
| Filesystem tool | `mcp-filesystem` | Same nobody **or** a dedicated UID that owns `mcp_shared` |
| Playwright | `mcp-playwright` / `browserless` | Vendor Chromium user if present; do not force nobody if chrome-sandbox breaks |
| Helper exception | `helper_index` | Document docker GID; do not apply a random `1000` |
| Vendor datastores | postgres, minio, qdrant, redis | Leave image entrypoint users; do not override unless a volume-permission bug is proven |

### Rules

1. **Numeric UID:GID only.** Names like `user: nobody` fail if the image has no passwd entry. Prefer `65534:65534` or a documented project UID.
2. **Helper is not a copy-paste target.** `user: "1000:1000"` plus docker.sock is a silent break. Doctor must show the GID recipe.
3. **Do not chown vendor data volumes** to satisfy a cosmetic `user:` on Postgres/MinIO.
4. **tmp share stays explicit.** If processor drops to nobody, `/tmp` notifications must remain writable (mode or tmpfs).
5. **Hardening stack is layered.** `user:` does not replace Stage 18 cap_drop or Stage 23 read_only.
6. **GitHub remains intake.** Requests for a cluster IAM layer stay Issues.

### Suggested contributor checklist

```text
1. Classify each service: vendor-entrypoint-user / first-party-stateless / docker.sock
2. Add user: "65534:65534" only on first-party-stateless after a write-path check
3. Leave helper on root unless doctor documents a docker GID map
4. Do not chown postgres_data / minio_data / qdrant_data
5. Confirm processor can still write /tmp status for the dashboard
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Container identity | Compose `user:` + image USER | LDAP/Keycloak for UID |
| docker.sock | Documented GID map / keep root | Blind `user: 1000` |
| Filesystem sandbox | nobody + `mcp_shared` ownership | Host home mounts as root |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: processor + mcp-fetch + mcp-memory first (smallest write surface).
3. Document the helper exception in `tu-vm.sh doctor` and this page.

## Acceptance criteria

- [ ] At least the processor and one MCP tool run with a numeric non-root `user:`.
- [ ] Helper either stays root or uses a doctor-documented docker GID.
- [ ] No vendor data volume is chowned as part of this work.
- [ ] Dashboard `/tmp` notifications still appear after processor UID change.
- [ ] `docker compose config` still renders.

## Rollback

Remove `user:` keys. If a volume was chowned in error, restore the vendor UID (that is why the rule forbids chown).

## Success metrics

- `docker top` on processor shows UID 65534 (or the documented UID).
- Community Compose PRs that add a Python sidecar include `user:`.
- Helper control-plane commands still work after any UID experiment.
