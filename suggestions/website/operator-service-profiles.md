---
title: Operator Service Profiles
description: Community contract for named TU-VM service profiles that make day-to-day Tier 1/Tier 2 operations predictable without a custom orchestrator.
last_updated: 2026-07-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Operator Service Profiles

## Problem

Historical suggestions and changelog notes repeatedly ask for Work / AI / Energy (battery) modes, idle auto-stop of heavy services, and clearer dependency startup. Operators today assemble ad-hoc mixes with `start` / `start-service` / `stop-service`. There is no **named, documented profile contract** the community can share, review, and later automate safely.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose Tier 1 vs on-demand Tier 2 | Natural profile building blocks |
| `./tu-vm.sh start`, `start-service`, `stop-service` | Manual profile application today |
| `./tu-vm.sh status`, `health`, `doctor` | Verify profile effect |
| Nginx + helper dashboard | Show what is running (do not become a profile editor SPA) |
| [`../historical-suggestions.md`](../historical-suggestions.md) | Quick action profiles, battery widget, idle stop |
| [Hardware matrix](./hardware-compatibility-matrix.md) | Which profiles fit which host class |

Do **not** invent a Kubernetes-like custom scheduler, a new daemon, or dashboard-only profile storage that drifts from Compose. Prefer declarative profile documents that eventually drive thin wrappers around existing `tu-vm.sh` commands.

## Proposal

Define a small set of **operator service profiles** as website markdown (community contract first). Implementation can follow once names and membership stabilize.

### Profile catalog (initial)

| Profile id | Intent | Services guidance | Typical host class |
|---|---|---|---|
| `energy-saver` | Battery / quiet laptop | Tier 1 only; stop ollama, n8n, affine*, browserless, mcp-* | `laptop-saver` |
| `ai-chat` | Private chat + RAG path | Tier 1 + `ollama` (+ keep processor/minio/tika for docs) | `small-nuc` |
| `automation` | Workflow engineering | Tier 1 + ollama + n8n + mcp_gateway (+ langgraph_supervisor when writing) | `automation-workstation` |
| `knowledge` | Notes + docs collaboration | Tier 1 + affine stack (and deps) as needed | `homelab-server` / workstation |
| `full-optional` | Everything opted in | Documented union of Tier 2; requires headroom | `homelab-server` |

Tier 1 core (today’s always-on guidance): postgres, redis, qdrant, tika, minio, tika_minio_processor, open-webui, pihole, nginx, helper_index.

Exact membership should be maintained as a table in this page until a machine-readable file is justified.

### Profile document contract

Each profile must specify:

1. **id** and human title  
2. **intent** (one sentence)  
3. **includes** / **excludes** service lists  
4. **depends_on** edges (example: Open WebUI chat quality may need Ollama)  
5. **apply** steps using current commands  
6. **verify** steps (`status`, endpoint checks, optional smoke)  
7. **rollback** (return to previous running set)  
8. **security notes** (never implies `public` access)  
9. **hardware class fit** link into the matrix  

### Day-to-day apply path (now, without new code)

Example: move a laptop into energy saver after an automation session:

```bash
./tu-vm.sh stop-service n8n
./tu-vm.sh stop-service ollama
./tu-vm.sh stop-service mcp_gateway
./tu-vm.sh stop-service langgraph_supervisor
./tu-vm.sh status
./tu-vm.sh doctor
```

Example: enable AI chat on a NUC:

```bash
./tu-vm.sh start-service ollama
./tu-vm.sh status
```

Document these recipes on the website first. A future `./tu-vm.sh profile apply energy-saver` should only orchestrate the same operations.

### Future CLI shape (only after the catalog stabilizes)

```text
./tu-vm.sh profile list
./tu-vm.sh profile show <id>
./tu-vm.sh profile apply <id> --plan
./tu-vm.sh profile apply <id>
```

Rules for that future command:

- `--plan` is default-safe and prints service diffs without changes when requested.
- Never read or print `.env` secrets.
- Never toggle `public` / allowlist posture as part of a resource profile.
- Idle auto-stop (historical suggestion) may **consume** profile membership later; it is a separate opt-in policy, not part of v1 docs.

## Frameworks and tools

| Need | Prefer | Avoid |
|---|---|---|
| Declaration | Markdown table → later YAML next to this page | Per-operator JSON in MinIO as source of truth |
| Execution | Wrapper around existing `tu-vm.sh` service commands | New orchestrator container |
| UX | Docs + optional dashboard status badges for “active profile” | In-dashboard profile marketplace |
| Automation | Optional n8n reminder to leave `full-optional` on laptops | Silent remote profile pushes |

## Community governance

- Profile id changes are breaking docs changes: require Issue + PR, update matrix links.
- Adding a service to a default profile needs resource justification and a hardware-class note.
- Removing a service from Tier 1 guidance is an RFC-level ops change, not a drive-by docs edit.
- Suggestions for new profiles must explain why an existing profile cannot be extended.

## Rollout

1. Publish this catalog page and link from persona paths + hardware matrix.  
2. Align wording with README Tier 1 / Tier 2 sections (no behavior change).  
3. Pilot one helper/dashboard read-only label (“profile: inferred from running set”) only after membership is stable.  
4. Implement `profile list/show/apply` behind explicit commands when `--plan` output matches manual recipes.  
5. Revisit idle auto-stop and battery widget proposals as consumers of this catalog.

## Rollback

- Docs-only stage: remove the page; operators keep using `start-service` / `stop-service`.  
- If CLI lands later: keep manual service commands as the supported escape hatch; feature-flag or remove the wrapper without Compose changes.

## Acceptance criteria

- At least four named profiles with includes/excludes and verify steps.  
- Apply instructions work with today’s `tu-vm.sh` surface.  
- Profiles never alter security posture (`secure` / `public` / `lock`).  
- Hardware matrix cross-links exist for each profile’s typical class.  
- No new always-on service is introduced by the docs stage.

## Success metrics

- Operators cite profile ids in Issues (“stayed on `ai-chat`, OOM after enabling affine”).  
- Reduction in contradictory advice about which Tier 2 services to run on laptops.  
- Faster implementation of historical quick-action profiles because names and membership already have community review.
