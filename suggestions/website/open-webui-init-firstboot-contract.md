---
title: Open WebUI Init / First-Boot Contract
description: Constructional contract for community contributions to scripts/init-openwebui.sh and first-boot Open WebUI patching—distinct from PDF loader switches and general Open WebUI config PRs.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Init / First-Boot Contract

## Problem

First boot of Open WebUI historically needed a TikaLoader-oriented patch so PDF ingestion behaves predictably. Contributors propose baking forks of Open WebUI, runtime `sed` in random entrypoints, or one-off host instructions that drift from Compose. Community work should extend the **existing init script lane** with clear idempotency and upgrade safety.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/init-openwebui.sh` | First-boot / repair patcher for Open WebUI loaders |
| Open WebUI Compose service | Target container and volume layout |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Broader Open WebUI config and tool wiring |
| Stage 13 `open-webui-audio-stt-contract.md` / `open-webui-websearch-contract.md` | Feature-specific day-2 lanes |
| Stage 14 `pdf-loader-switch-day2-contract.md` (expected sibling) | Runtime Tika vs PyMuPDF **toggle** (`switch-pdf-loader.sh`) |
| Stage 14 `seed-chat-context-contribution-contract.md` (expected sibling) | Assistant context bootstrap (different concern) |
| Stage 12 `compose-healthcheck-contribution-contract.md` (expected sibling) | Healthcheck honesty after init |

Out of scope:

- Maintaining a long-lived hard fork of Open WebUI as the default path
- Non-idempotent patches that break on image upgrades without detection
- Mixing loader **toggle** logic into init when `switch-pdf-loader.sh` already owns day-2 switches
- Patching unrelated Python files “while we are here” without an Issue

## Proposal

Publish an **init / first-boot contract** for community PRs that touch Open WebUI bootstrap patching.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Init script | `scripts/init-openwebui.sh` | Idempotent; detects already-applied markers; clear exit codes |
| Compose wiring | `docker-compose.yml` / entry hooks | Documents when init runs (first boot vs repair) |
| Verification | doctor / smoke / playbook | PDF or loader checks after init |
| Docs | README / playbooks | Distinguishes init vs `switch-pdf-loader` vs config-only PRs |

### Rules

1. **Idempotent by default.** Re-running init must be safe and print an already-applied result when nothing changed.
2. **Marker or checksum detection.** Patches need a stable marker string or equivalent so upgrades can detect drift.
3. **Init ≠ day-2 toggle.** Runtime engine switches stay in `switch-pdf-loader.sh` (Stage 14); init establishes first-boot correctness.
4. **Image upgrade honesty.** Docs must say what happens when upstream Open WebUI reshapes loader code (fail loud, Issue, or revised patch).
5. **No secrets.** Init must not embed tokens, model keys, or operator chat data.
6. **Minimal surface.** Prefer the smallest patch that restores Tika-first PDF behavior (or the currently documented default).
7. **GitHub remains intake.** “Vendor a full Open WebUI fork” stays an Issue; default is init-script repair.

### Suggested contributor checklist

```text
1. bash -n scripts/init-openwebui.sh
2. Run once → apply; run twice → already-applied
3. Confirm marker detection still matches upstream file paths
4. Note Open WebUI image digest in PR body
5. Do not combine with unrelated dashboard or n8n changes
6. Playbook mentions first-boot vs repair invocation
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| First-boot correctness | `init-openwebui.sh` | Manual docker exec folklore only |
| Day-2 loader toggle | `switch-pdf-loader.sh` | Duplicating toggle logic in init |
| Broader OWUI config | Stage 10 Open WebUI contract | Init script as a dumping ground |
| Upstream drift | Loud failure + Issue | Silent no-op that leaves broken PDFs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 10 Open WebUI and Stage 14 PDF loader pages when those merge.
3. Prefer **code** that improves detection/idempotency and playbook anchors over more prose.

## Acceptance criteria

- [ ] Idempotency and marker detection are required.
- [ ] Init vs day-2 loader toggle boundary is explicit.
- [ ] Upgrade-drift behavior is documented.
- [ ] No hard fork of Open WebUI is required.
- [ ] Secret-free patching is required.

## Rollback

Revert init script / Compose hook commits; operators can skip repair on already-healthy volumes. Docs-only publication needs no runtime rollback.

## Success metrics

- First-boot PDF path remains predictable across image bumps.
- Fewer duplicate “sed the container” Issues.
- Clear separation between init repair and day-2 loader switches.
