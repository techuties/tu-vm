---
title: Tika and MinIO Resource Limits Contract
description: Constructional contract for adding Compose deploy.resources to Tika and MinIO so they share the same energy budget as other Tier 1 services.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika and MinIO Resource Limits Contract

## Problem

`tika` and `minio` are **Tier 1** (always-on, `restart: unless-stopped`) but they are the only core services **without `deploy.resources`**. Neighbors already declare CPU and memory:

- postgres 512M / 0.5 CPU
- open-webui 2G / 1.0 CPU
- tika_minio_processor 512M / 0.5 CPU
- nginx 256M / 0.25 CPU

Tika already asks the JVM for **`-Xmx1536m`** via `JAVA_TOOL_OPTIONS`. Without a cgroup ceiling, a large OCR job can grow past that heap into host RAM and squeeze Pi-hole and Postgres — the same community-hostile failure Stage 18's budget is meant to prevent.

MinIO has no heap hint and no cgroup limit. Object listing and concurrent PUTs from Open WebUI plus the processor can expand until the laptop swaps.

Stage 18 covers **how to set a resource budget** for new services. Stage 10 covers **document pipeline contribution**. This page is the **missing limits on two existing Tier 1 images**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `deploy.resources` | Already used on postgres, redis, qdrant, ollama, open-webui, nginx, processor, MCP tools |
| Tika `JAVA_TOOL_OPTIONS` | `-Xms512m -Xmx1536m` today |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Budget rules for new keys |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Pipeline behavior |
| Stage 25 `compose-mem-swappiness-contract.md` (expected sibling) | Swap policy, not limits |

Out of scope:

- Moving Tika/MinIO back to Tier 2 (changelog 2.2.0 did; current compose put them back on Tier 1 — do not relitigate here)
- Changing Tika XML timeouts or MinIO bucket names
- Kubernetes `resources:` or Swarm-only deploy keys beyond what Compose already honors
- Raising Open WebUI or processor limits to "make room"

## Proposal

Add `deploy.resources` that respect the existing JVM heap and the laptop energy budget.

### Contribution lanes

| Lane | Where | Suggested ceiling |
|---|---|---|
| Tika | `tika.deploy.resources` | limit 2G / 1.0 CPU; reserve 512M / 0.25 (heap 1.5G + metaspace) |
| MinIO | `minio.deploy.resources` | limit 1G / 0.5 CPU; reserve 256M / 0.1 |
| JVM | `JAVA_TOOL_OPTIONS` | Keep `-Xmx1536m`; do not set `-Xmx` above the cgroup |
| Docs | this page + Stage 18 | New Tier 1 services must ship limits |

### Rules

1. **Every Tier 1 service declares limits.** Tika and MinIO are the remaining gap, not a special class.
2. **Heap must fit the cgroup.** `-Xmx` + metaspace + native < memory limit. 2G for a 1.5G heap is the minimum honest pair.
3. **Do not remove `JAVA_TOOL_OPTIONS`.** The cgroup is the backstop; the JVM flag is the working set.
4. **Do not invent a memory manager.** Compose limits plus the existing JVM flag are enough.
5. **Energy stays the default.** Do not "fix" OCR slowness by raising Tika to 8G in the community compose file. Operators who need more use a Stage 8 override.
6. **GitHub remains intake.** Requests for a cluster object store stay Issues.

### Suggested contributor checklist

```text
1. Add deploy.resources to tika (2G / 1.0, reserve 512M / 0.25)
2. Add deploy.resources to minio (1G / 0.5, reserve 256M / 0.1)
3. Confirm -Xmx1536m still fits under the 2G Tika limit
4. Do not change Tika XML or MinIO command
5. Confirm docker compose config still renders
6. Process one small PDF and one PUT to MinIO on a test stack
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| CPU/RAM ceiling | Compose `deploy.resources` | Unbounded Tier 1 images |
| JVM working set | Existing `JAVA_TOOL_OPTIONS` | A second heap manager |
| Local extra RAM | Stage 8 compose override | Raising the community default |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add the two `deploy.resources` blocks.
3. Watch Tika OOM logs once; if 2G is tight for documented OCR samples, raise once with evidence.

## Acceptance criteria

- [ ] `tika` and `minio` set `deploy.resources.limits` for memory and cpus.
- [ ] Tika's memory limit is ≥ 2G so `-Xmx1536m` fits.
- [ ] No new memory-manager container is added.
- [ ] `docker compose config` still renders.
- [ ] A small PDF extract and a MinIO health/PUT still succeed on a test stack.

## Rollback

Remove the two `deploy.resources` blocks. Images, volumes, and JVM flags are unchanged.

## Success metrics

- Host OOM tickets during OCR/upload drop.
- New Tier 1 services ship limits on the first PR.
- Pi-hole stays up while Tika processes a large PDF.
