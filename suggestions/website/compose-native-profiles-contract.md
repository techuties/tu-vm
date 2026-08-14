---
title: Native Compose Profiles Contract
description: Constructional contract for aligning Docker Compose profiles: with tu-vm.sh Tier arrays so community start modes stay one source of truth instead of a second orchestrator.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Native Compose Profiles Contract

## Problem

Operators start services through `tu-vm.sh` arrays (`TIER1_SERVICES`, `TIER2_SERVICES`) and flags such as `start --portable` / `--server` and `quickstart`. `docker-compose.yml` has **no** native `profiles:` keys. A contributor who runs `docker compose up -d` therefore starts a different set than `./tu-vm.sh start`.

CHANGELOG 2.2 also drifted from current code: it says Qdrant, Tika, and `tika_minio_processor` moved to Tier 2, while `tu-vm.sh` and `AGENTS.md` list them as Tier 1. Community PRs that add `profiles: [tier2]` from the changelog will mis-classify those services.

Stage 2 operator profiles and Stage 5 CI live-profile describe *named sets*. Stage 18 quickstart describes *beginner defaults*. This page is the **sync contract** between Compose `profiles:` and the shell arrays.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `TIER1_SERVICES` / `TIER2_SERVICES` in `tu-vm.sh` | Canonical start sets today |
| `quickstart_beginner()` | Portable vs `--server` |
| `docker compose up -d "${TIER1_SERVICES[@]}"` | Actual start implementation |
| `docker compose up -d --no-start "${TIER2_SERVICES[@]}"` | Create-but-do-not-run Tier 2 |
| CHANGELOG 2.2 vs `AGENTS.md` | Documented drift to reconcile |
| Stage 2 `operator-service-profiles.md` (expected sibling) | Named Work/AI/Energy sets |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Minimal CI profile for `/status/full` |
| Stage 8 `smart-startup-optimization.md` (expected sibling) | Planner over existing tiers |
| Stage 18 `beginner-quickstart-contribution-contract.md` (expected sibling) | Portable remains default |

Out of scope:

- Kubernetes / Swarm as a prerequisite
- Replacing `tu-vm.sh` with raw Compose for operators
- Silent `profiles:` that change default `docker compose up` without a migration
- Treating CHANGELOG 2.2 as source of truth over current arrays

## Proposal

If native `profiles:` are adopted, they must **mirror** `tu-vm.sh` arrays and be generated or CI-checked against them.

### Recommended profile names

| Profile | Maps to | Default `compose up` |
|---|---|---|
| (none / default) | Tier 1 only, matching `TIER1_SERVICES` | Safe laptop path |
| `tier2` | Current `TIER2_SERVICES` | Opt-in |
| `observability` | Stage 19 exporters | Opt-in, off by default |
| `ci` | Stage 5 live helper subset | CI only |

Do not invent `work` / `ai` / `energy` Compose profiles until Stage 2 operator profiles exist as code.

### Rules

1. **One source of truth.** Either generate `profiles:` from the shell arrays or fail CI when they diverge.
2. **Reconcile CHANGELOG 2.2.** A profiles PR must state the current Tier 1 list (postgres, redis, qdrant, tika, minio, tika_minio_processor, open-webui, pihole, nginx, helper_index) and update changelog notes if history is wrong.
3. **Default Compose up stays Tier 1.** Services with `profiles: [tier2]` must not start on an unprofiled `up -d`.
4. **`tu-vm.sh` remains the operator CLI.** Profiles are for Compose-native and CI users, not a second UX.
5. **`--no-start` behavior.** Today Tier 2 containers may be created stopped. Preserve that or document the break.
6. **AFFiNE deps.** `affine_postgres`, `affine_redis`, and `affine_migration` must share AFFiNE’s profile even if they are not in `TIER2_SERVICES` by name.
7. **GitHub remains intake.** Requests for a GUI orchestrator stay Issues.

### Suggested contributor checklist

```text
1. Diff TIER1_SERVICES / TIER2_SERVICES against AGENTS.md
2. Do not copy CHANGELOG 2.2 tier lists without verifying compose + script
3. If adding profiles:, attach every Tier 2 service (and AFFiNE deps)
4. Add CI that parses both arrays and profiles: keys
5. Keep unprofiled docker compose up -d equivalent to tu-vm.sh start
6. Update README start examples in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Start sets | Existing bash arrays + optional Compose profiles | A third YAML “manifest” |
| CI subset | Stage 5 live profile | Booting Ollama in CI |
| Named operator modes | Stage 2 / Stage 8 after arrays exist | Premature `profiles: [energy]` |
| Beginner path | Stage 18 quickstart portable default | `compose up` starting AFFiNE + Ollama |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: a small checker that compares `TIER1_SERVICES` / `TIER2_SERVICES` to Compose `profiles:` (or documents why profiles are still absent).
3. Fix changelog/docs drift in the same wave as any profiles: adoption.

## Acceptance criteria

- [ ] Current Tier 1 list is stated from `tu-vm.sh`, not CHANGELOG 2.2 alone.
- [ ] Default Compose up remains Tier 1 if profiles are added.
- [ ] Divergence between arrays and `profiles:` is a CI defect.
- [ ] AFFiNE dependency services share AFFiNE’s profile.
- [ ] `tu-vm.sh` stays the supported operator entry point.

## Rollback

Remove `profiles:` keys; arrays continue to work. A checker can be deleted without changing start behavior.

## Success metrics

- `docker compose up -d` and `./tu-vm.sh start` start the same Tier 1 set.
- No community PR re-tiers Tika/Qdrant from changelog memory alone.
- CI fails on array/profile drift.
