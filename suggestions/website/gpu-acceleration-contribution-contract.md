---
title: GPU Acceleration Contribution Contract
description: Constructional contract for optional GPU enablement (primarily Ollama and related AI services) that reuses the Stage 2 hardware matrix and Compose override patterns instead of mandating GPU as Tier 1.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# GPU Acceleration Contribution Contract

## Problem

Contributors frequently propose “just enable GPU” changes that break CPU-only laptops, cloud agents, and digest-pinned Compose baselines. Historical suggestions also invent separate GPU orchestrators. TU-VM needs a **community contract** for optional acceleration that stays aligned with the hardware compatibility matrix and profile system.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ollama` Compose service | Primary local model runtime |
| Stage 2 `hardware-compatibility-matrix.md` (expected sibling) | Host/RAM/GPU class living artifact |
| Stage 2 `operator-service-profiles.md` / Stage 4 `operator-profile-cli.md` | When AI Mode should start heavy services |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local device/runtime overrides |
| Stage 9 `ollama-model-catalog-contribution.md` (expected sibling) | Model sizing guidance |
| Stage 7 `battery-power-operator-signals.md` (expected sibling) | Laptop energy tradeoffs |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image/runtime pins |

Out of scope:

- Making NVIDIA/AMD GPU mandatory for Tier 1
- Shipping host driver installers that mutate arbitrary kernels without warnings
- Cloud GPU SaaS as the default model path
- Mixing GPU enablement into unrelated services without a dependency note

## Proposal

Treat GPU support as an **optional acceleration lane** with explicit detection, docs, and rollback.

### Contribution lanes

| Lane | Where | Evidence required |
|---|---|---|
| Docs / matrix | Stage 2 hardware matrix | Class IDs, VRAM floors, CPU fallback |
| Compose override samples | `fixtures/compose-overrides/` (direction) | Device reservations, tested host OS notes |
| Service env | Ollama / related AI services | CPU-only default preserved |
| Profiles | AI Mode / Full Stack notes | GPU optional annotation |
| Models | Stage 9 catalog | VRAM-tagged recommendations |

### Rules

1. **CPU-only remains default.** Core compose path must start without GPU devices.
2. **Override, don’t fork.** Prefer documented Compose overrides over maintaining two full compose files forever.
3. **Matrix-linked.** Any GPU PR updates or references hardware class IDs.
4. **Failure is soft.** Missing GPU must yield clear logs/docs, not hard crash loops for Tier 1.
5. **Energy honesty.** Laptop classes document battery impact; link Stage 7 signals.
6. **Supply chain.** Custom CUDA images follow Stage 4 pin/CVE expectations.
7. **GitHub intake.** Hardware enablement debates stay on Issues with `class_id` once Stage 3 intake lands.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Model runtime | Ollama | Parallel GPU agent runtime |
| Host fit | Stage 2 matrix | Anecdotal “works on my 4090” as sole docs |
| Local customization | Compose overrides | Committing operator-specific device IDs to main compose |
| Scheduling | Profiles + Tier 2 on-demand | Always-on GPU services for all installs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-gpu-optional` with detect → override → verify → rollback.
3. Cross-link hardware matrix, profiles, and model catalog.
4. Keep cloud/agent docs stating GPU is unavailable/optional in DinD environments.

## Acceptance criteria

- [ ] Default install path remains CPU-functional.
- [ ] GPU enablement documented as override/optional lane.
- [ ] Hardware matrix linkage is required for GPU PRs.
- [ ] Soft-failure behavior is documented when devices are absent.
- [ ] Battery/energy caveats referenced for laptop classes.

## Rollback

Remove GPU override file/flags; return to CPU Ollama path; restart affected Tier 2 services. No Tier 1 rollback should be required.

## Success metrics

- Fewer broken PRs that assume `/dev/nvidia0` on all hosts.
- Hardware Issues include class IDs and VRAM notes.
- Operators can enable/disable GPU without rewriting core compose by hand each upgrade.
