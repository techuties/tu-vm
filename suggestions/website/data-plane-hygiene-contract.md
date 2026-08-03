---
title: Data-Plane Hygiene Contract
description: Constructional day-to-day hygiene contract for Postgres, Redis, and Qdrant that reuses existing backup, doctor, and playbook surfaces instead of introducing a DBA control plane.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Data-Plane Hygiene Contract

## Problem

Operators run Postgres, Redis, and Qdrant continuously, but community suggestions often invent managed-database dashboards, remote DBA SaaS, or destructive “cleanup wizards.” Day-to-day life needs a **lightweight hygiene contract** that keeps data planes healthy without reinventing operations tooling already covered by backup drills and observability.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `postgres`, `redis`, `qdrant` Compose services | Core data plane |
| `./tu-vm.sh backup` / restore flows | Durability lane |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Recurring restore proof |
| Stage 9 `offsite-backup-rclone-contract.md` (expected sibling) | Optional offsite copies |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Metrics/alerts |
| `./tu-vm.sh doctor` / `check-config` | Preflight signals |
| Stage 7 `local-resource-history.md` (expected sibling) | Host pressure context |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | DB password rotation lane |

Out of scope:

- Mandating a cloud DBA product
- Auto-deleting Qdrant collections or Postgres schemas without confirmation
- Exposing database ports on the public internet
- Replacing Redis with an alternate cache as a casual drive-by PR

## Proposal

Publish a **data-plane hygiene contract** focused on safe, repeatable operator habits and contribution rules.

### Hygiene checklist (day-to-day)

1. **Health first.** Confirm Compose healthchecks / helper status before invasive maintenance.
2. **Backup before mutate.** Any vacuum, reindex, collection drop, or major version bump follows Stage 6 drill habits.
3. **Credentials.** Rotation uses Stage 8 secret hygiene—never commit connection strings.
4. **Retention.** Document default retention for Redis (volatile) vs Postgres/Qdrant (persistent) so contributors do not “fix” the wrong store.
5. **Growth.** Disk pressure routes to Stage 10 disk-ops contract before deleting volumes.
6. **Version pins.** Postgres major upgrades are explicit migrations (Compose comments already warn about PG 15 data layout)—not silent tag floats.
7. **Community PRs.** Changes to init args, maxmemory, or Qdrant storage paths include rollback and compatibility notes.

### Contribution lanes

| Lane | Examples | Bar |
|---|---|---|
| Config tuning | `maxmemory`, shared_buffers, Qdrant env | Benchmarks or rationale + hardware class |
| Backup integration | Scripts wrapping existing backup | Restore evidence |
| Observability | Exporters/dashboards | Stage 6 rules |
| Destructive maintenance | Drop/rebuild collection | Explicit flag, backup proof, Decision Log if default behavior changes |

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Durability | Existing backup/restore | New backup microservice |
| Cache | Redis already in Compose | Parallel Memcached “for simplicity” |
| Vectors | Qdrant already in Compose | Second vector DB by default |
| Insights | Prometheus/Grafana lane | Scraping DB contents into the dashboard |
| Access | Internal Docker network | Publishing DB ports widely |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add playbook anchor `#playbook-data-plane-hygiene` with copy-paste health/backup checks.
3. Cross-link Stage 6 drills and Stage 8 secret rotation.
4. Require data-plane PRs to cite this contract in the PR template verification notes when relevant.

## Acceptance criteria

- [ ] Hygiene checklist covers health, backup, credentials, retention, growth, and pins.
- [ ] Destructive operations require explicit confirmation and backup evidence.
- [ ] Docs forbid exposing Postgres/Redis/Qdrant as public endpoints by default.
- [ ] Tuning guidance references Stage 2 hardware classes when resource limits change.
- [ ] No new DBA product is introduced as a prerequisite.

## Rollback

Restore from the latest successful backup/restore drill artifact; revert Compose env tuning. For Qdrant collection experiments, keep prior snapshots when available.

## Success metrics

- Fewer emergency “database wiped” incidents from undocumented cleanup scripts.
- Data-plane PRs include backup/rollback notes as a norm.
- Operators use playbooks instead of ad-hoc `docker exec` folklore shared only in chat.
