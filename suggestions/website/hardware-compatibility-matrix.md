---
title: Hardware Compatibility Matrix
description: Living community artifact for TU-VM host, RAM, GPU, storage, and network fit without reinventing custom hardware detectors.
last_updated: 2026-07-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Hardware Compatibility Matrix

## Problem

Operators and contributors open Issues that say “TU-VM is slow,” “Ollama will not start,” or “docs say 8GB but chat dies,” without a shared vocabulary for host fit. Historical suggestions repeatedly asked for battery awareness, idle Tier 2 stop, and resource history, but there is still no **publishable matrix** that maps hardware classes to safe service sets.

## Existing scan (reuse first)

| Asset | Reuse as |
|---|---|
| [`README.md`](../../README.md) system requirements | Minimum / recommended baseline |
| `./tu-vm.sh doctor` / `doctor --json` | Host evidence without inventing a new probe tool |
| `./tu-vm.sh start-service` / `stop-service` | Selective Tier 2 enablement |
| Compose Tier 1 vs Tier 2 split | Profile input for resource classes |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Recovery and MCP smoke recipes |
| [`../historical-suggestions.md`](../historical-suggestions.md) | Battery, idle stop, resource history backlog |

Do **not** invent a proprietary hardware agent, cloud telemetry sink, or vendor certification program. Prefer a Markdown matrix (later YAML-backed) that humans and CI can review, plus commands operators already have.

## Proposal

Publish a living **Hardware Compatibility Matrix** as website markdown, kept in this folder, that:

1. Defines host classes (laptop saver, small NUC, workstation, homelab server).
2. Maps each class to recommended Tier 1 / Tier 2 services.
3. Lists known constraints (RAM, disk, GPU optional, DNS port 53, TLS).
4. Points to the exact validation commands for filing Issues or PRs.
5. Accepts community updates via the GitHub suggestion/PR path with evidence.

### Host classes (initial)

| Class | Typical hardware | Default posture | Recommended services |
|---|---|---|---|
| `laptop-saver` | 8–16 GB RAM, SSD, on battery often | Tier 1 only; Tier 2 off by default | postgres, redis, qdrant, tika, minio, tika_minio_processor, open-webui, pihole, nginx, helper_index |
| `small-nuc` | 16–32 GB RAM, SSD, always-on LAN | Tier 1 + selective AI | Tier 1 + `ollama` when local models needed |
| `automation-workstation` | 32 GB+ RAM, SSD/NVMe | Tier 1 + automation path | Tier 1 + ollama + n8n + mcp_gateway (+ langgraph_supervisor when writing workflows) |
| `homelab-server` | 32 GB+ RAM, multi-disk optional | Full optional stack with care | Above + affine stack, browserless, selected `mcp-*` tools |

These are **community guidance**, not hard product SKUs. Defaults must keep LAN-first security and never auto-enable public exposure.

### Resource dimensions to document

| Dimension | What the matrix should say | Evidence command |
|---|---|---|
| RAM | Minimum for Tier 1; headroom before enabling Ollama/n8n/AFFiNE | `./tu-vm.sh doctor --json` |
| Disk | Free space for images, models, MinIO, backups | `doctor` / host `df` summarized by operator |
| CPU | Concurrent Tier 2 cost; prefer stop unused services | `./tu-vm.sh status` |
| GPU | Optional for Ollama acceleration; CPU-only remains supported | Operator note + model size |
| Network | Ports 80/443/53; Pi-hole DNS bind; Tailscale notes | Playbook `playbook-pihole-tailscale` |
| Power | Battery-friendly defaults: no always-on heavy Tier 2 | Link to [operator service profiles](./operator-service-profiles.md) |

### Suggested matrix row schema (Markdown first)

Keep rows in a table until automation needs YAML:

| field | meaning |
|---|---|
| `class_id` | Stable id (`laptop-saver`, …) |
| `ram_gb_min` / `ram_gb_recommended` | Planning numbers |
| `storage_gb_free_min` | Before pulling models/backups |
| `tier1` | Always-on core guidance |
| `tier2_default` | Services safe to enable by default for the class |
| `tier2_avoid` | Services that need explicit headroom |
| `validation` | Commands to attach to Issues |
| `last_verified` | Date + TU-VM tag/commit |
| `notes` | Battery, GPU, DNS caveats |

Optional later upgrade: `suggestions/website/data/hardware-matrix.yaml` consumed by the static site and a small validator script. Do not split into YAML until at least one CI consumer exists.

## Community contribution workflow

1. Operator hits a limit (OOM, disk full, Pi-hole port conflict, model pull failure).
2. They gather safe evidence with `./tu-vm.sh doctor --json` and `./tu-vm.sh status` — never paste `.env` secrets.
3. They open a GitHub Issue (bug or suggestion) referencing the matrix `class_id`.
4. Accepted corrections update this page (and YAML later) via PR with `last_verified`.

Website role: **catalog + guidance**. GitHub remains system of record for discussion.

## Frameworks and tools to prefer

| Need | Prefer | Why |
|---|---|---|
| Host inventory | Existing `doctor` JSON | Already maintained; no new daemon |
| Docs publishing | Static docs framework after gates | Matrix is static content |
| Optional automation | n8n Tier 2 digest of matrix changes | Reuses stack; not required for v1 |
| Resource history | Future helper snapshots from historical backlog | Separate proposal; matrix stays declarative |

## Rollout

1. Publish this page and link it from [`index.md`](./index.md) and persona paths.
2. Add a short pointer in [`docs/playbooks/README.md`](../../docs/playbooks/README.md) (“choose a host class before enabling Tier 2”).
3. Ask Issue templates (later, optional) for optional `class_id` + `doctor` summary.
4. Only after repeated updates: extract YAML + warning-only CI schema check.

## Rollback

Remove or archive the page; operators fall back to README requirements and playbooks. No runtime dependency should be introduced in Stage 2.

## Acceptance criteria

- Four host classes documented with Tier 1 / Tier 2 guidance.
- Every class lists validation commands that already exist in the repo.
- Page states clearly that GPU is optional and LAN-first security is unchanged.
- Community update path is GitHub PR/Issue only.
- No new telemetry service, hardware agent, or dashboard auth is required.

## Success metrics

- Hardware-related Issues reference a `class_id` or matrix row.
- Fewer duplicate “what should I run on 8GB?” discussions.
- Profile and idle-stop work (historical backlog) can cite this matrix as input.
