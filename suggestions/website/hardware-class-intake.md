---
title: Hardware-Class Intake Field
description: Optional GitHub Idea/suggestion form enhancement that ties community Issues to the Stage 2 hardware compatibility matrix without new trackers.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Hardware-Class Intake Field

## Problem

Performance and capacity Issues often omit host context. Stage 2 proposes a living hardware compatibility matrix page (`hardware-compatibility-matrix.md`, expected sibling under this folder) with stable `class_id` values (`laptop-saver`, `small-nuc`, `automation-workstation`, `homelab-server`). The suggestion Issue form does not yet ask for that class, so triage still begins with “what hardware is this?”

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`.github/ISSUE_TEMPLATE/suggestion.yml`](../../.github/ISSUE_TEMPLATE/suggestion.yml) | Sole Idea / suggestion intake |
| Stage 2 hardware matrix (sibling page when merged) | Canonical `class_id` vocabulary |
| [`../historical-suggestions.md`](../historical-suggestions.md) | Battery / idle Tier 2 / resource-history context |
| `./tu-vm.sh doctor --json` | Optional evidence attachment (redacted) |
| [`../../docs/playbooks/README.md`](../../docs/playbooks/README.md) | Recovery and DNS/Tailscale recipes |
| Stage 2 persona entry paths (sibling page when merged) | First-hour routing for operators |

Do **not** add a hardware wizard app, telemetry uploader, or mandatory fingerprinting. A single optional form field plus docs links is enough.

## Proposal

### 1) Issue form field

Add an optional dropdown (or short input) to the Idea / suggestion template:

| Input id | `class_id` |
|---|---|
| Label | Hardware class (from compatibility matrix) |
| Required | No (bugs may use a parallel optional field later) |
| Options | `unknown`, `laptop-saver`, `small-nuc`, `automation-workstation`, `homelab-server`, `other` |
| Description | Pick the closest class. See the hardware compatibility matrix. Use `unknown` if unsure. |

For Bug report templates, prefer the same optional field so capacity bugs share vocabulary.

### 2) Website guidance

On this page and the Stage 2 matrix page, show:

1. What each `class_id` means in one sentence.
2. Which evidence to attach (`doctor --json` summary, RAM/disk notes—**never** `.env`).
3. Which Stage 2 operator service profiles (`operator-service-profiles.md`, sibling when merged) usually fit that class.

### 3) Maintainer triage use

| `class_id` | Typical first questions |
|---|---|
| `laptop-saver` | Is Tier 2 stopped? Energy-saver profile applied? |
| `small-nuc` | Is only `ollama` enabled among heavy services? |
| `automation-workstation` | Are n8n/MCP/langgraph intentionally on? |
| `homelab-server` | Disk/backup paths and DNS bind expectations clear? |
| `unknown` / `other` | Ask for matrix class + doctor summary before deep debugging |

### 4) Playbook pointer

When `class_id` is `laptop-saver` and the report mentions DNS/Tailscale, point to playbook `playbook-pihole-tailscale` before expanding scope. When MCP/automation fails on workstation classes, point to `playbook-mcp-smoke`.

## Implementation sketch (small PR)

1. Update `.github/ISSUE_TEMPLATE/suggestion.yml` with `class_id` dropdown.
2. Optionally mirror on the bug template.
3. Link the field description to this page / matrix (GitHub-rendered blob URL or docs site URL after adoption).
4. Mention the field in CONTRIBUTING under suggestion quality tips.
5. No API changes; no dashboard changes.

## Rollout and rollback

- **Rollout:** form field is additive and optional—zero impact on existing Issues.
- **Rollback:** remove the field from the YAML template; matrix vocabulary remains useful in free-text.

## Success criteria

- ≥50% of new hardware/performance suggestions include a non-`unknown` `class_id` within two months of shipping the field
- Maintainers paste fewer “what are your RAM/services?” boilerplate comments
- No increase in secret leakage (doctor guidance remains redacted / allowlisted)
