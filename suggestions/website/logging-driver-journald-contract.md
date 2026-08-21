---
title: Logging Driver Journald Contract
description: Constructional contract for choosing json-file versus journald as the container log driver, without replacing max-size retention policy or inventing a log shipping stack.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Logging Driver Journald Contract

## Problem

CHANGELOG documents a Docker **daemon** default:

```json
"log-driver": "json-file",
"log-opts": { "max-size": "10m", "max-file": "3" }
```

`docker-compose.yml` has **no** per-service `logging:` block. Stage 11 covers **retention** (`max-size` / `max-file`) so disks do not fill. It does not name the **driver**. Community PRs that notice “logs vanish after prune” or “journalctl has no container logs” tend to propose Loki, ELK, or CloudWatch as a required pipeline.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| CHANGELOG Docker daemon snippet | Host-wide `json-file` + size caps |
| `docker-compose.yml` | No `logging:` override today |
| `nginx_logs` volume | Access/error files, not container stdout |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Optional Grafana/Prometheus |
| Stage 11 `container-log-retention-contract.md` (expected sibling) | Size/file count, not driver |
| Stage 13 `host-cleanup-and-prune-contract.md` (expected sibling) | Prune safety |

Out of scope:

- Requiring Loki / ELK / Vector as the default
- Changing Nginx access-log volume layout
- Using log shipping as a substitute for `max-size`
- Centralizing logs off the LAN by default

## Proposal

Keep `json-file` as the portable default (matches the documented daemon). Allow an **opt-in** Compose `logging.driver: journald` for hosts that already operate `journalctl` and want one place to read host + container logs—without a new observability product.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | Daemon `json-file` + Stage 11 caps | Works on Docker Desktop, rootless, and CI |
| Opt-in | Per-service or x-logging anchor in Compose | `driver: journald` + `tag: tu-vm/{{.Name}}` |
| Docs | Playbook + this page | When journald is unavailable (WSL/some rootless) |
| Retention | Stage 11 + `journald` vacuum | `SystemMaxUse` is a **host** setting, not Compose |
| Intake | GitHub Issues | Log-ship requests stay public |

### Rules

1. **Retention stays Stage 11.** Switching driver does not remove size caps. Journald hosts must document `SystemMaxUse` / `RuntimeMaxUse` or they will fill `/var/log`.
2. **Default remains json-file.** CI, smoke, and first-boot hosts must not require systemd.
3. **Reuse Docker logging, not a stack.** No Loki/Promtail as a prerequisite. Stage 6 exporters stay opt-in and separate.
4. **One driver per host story.** Do not mix json-file and journald on the same service “for redundancy.” Dual drivers double disk and confuse prune.
5. **Tag containers.** If journald is on, set a stable `tag` so `journalctl CONTAINER_NAME=ai_postgres` works. Do not invent a custom parser.
6. **Prune awareness.** `docker logs` on journald still works via the API, but operators who delete journals need the playbook warning (Stage 13).
7. **GitHub remains intake.** Requests for ELK stay Issues.

### Suggested contributor checklist

```text
1. Read Stage 11 retention contract and the CHANGELOG daemon snippet
2. Keep json-file as the documented default
3. If adding journald, use a Compose x-logging anchor, not a new service
4. Document host journal vacuum (SystemMaxUse)
5. Do not add Loki/ELK to Tier 1
6. Do not change nginx_logs volume behavior
7. Confirm smoke/CI still run without systemd journal
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Default logs | Docker `json-file` + max-size | A required log shipper |
| systemd hosts | Compose `journald` driver | A sidecar that tails json-file |
| Retention | Stage 11 + journald vacuum | Unlimited journals |
| Metrics/UI | Stage 6 opt-in Grafana | Treating logs as metrics |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: optional Compose `x-logging` anchor commented or profile-gated; default services stay on daemon json-file.
3. Optional: playbook `journalctl -u docker -t tu-vm/ai_nginx` example.

## Acceptance criteria

- [ ] json-file remains the portable default.
- [ ] journald, if added, is opt-in and reuse Docker’s driver.
- [ ] Stage 11 retention is not replaced.
- [ ] No log-shipping product is required.
- [ ] CI/smoke do not depend on systemd.

## Rollback

Remove Compose `logging:` blocks. Daemon json-file + max-size continue. Nginx file logs are unaffected.

## Success metrics

- Laptop/CI hosts keep working without journald.
- systemd operators can `journalctl` container output without Loki.
- Disk-fill incidents still cite Stage 11 / journal vacuum, not “we need ELK.”
