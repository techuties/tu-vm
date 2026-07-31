---
title: Service Dependency Map
description: Constructional contract for declaring Tier 2 service dependencies and safe start ordering by reusing Docker Compose and tu-vm.sh instead of a new orchestration framework.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Service Dependency Map

## Problem

CHANGELOG potential improvements include **service dependencies** (for example start Ollama when Open WebUI needs it). Historical suggestions propose custom dependency engines. Day-to-day operators need a small, declared map that Compose and `tu-vm.sh` can honor—without Kubernetes operators or a second control plane.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` | Service definitions, `depends_on`, profiles |
| Tier 1 / Tier 2 startup model | Manual dependency knowledge today |
| `./tu-vm.sh` service start helpers | Operator entrypoint |
| Stage 2 operator service profiles | Bundles of services for modes |
| Stage 4 operator profile CLI | Plan/apply named profiles |
| Stage 7 idle auto-stop policy | Stop side must respect dependency awareness |
| Helper status surfaces | Show missing dependency reasons |

Out of scope:

- Full mesh service discovery product
- Cross-host scheduling
- Automatically starting services with insecure public exposure
- Replacing Compose `depends_on` with an incompatible DSL

## Proposal

Publish a **service dependency map** as data the CLI and docs share.

### Map file (v1)

```text
config/service-dependencies.yaml
```

Illustrative content:

```yaml
version: 1
services:
  open-webui:
    requires:
      - ollama          # soft/runtime dependency when local models expected
    suggests:
      - qdrant
  tika_minio_processor:
    requires:
      - tika
      - minio
  # Tier 1 core services omit optional edges or list only hard peers
```

### Semantics

| Edge | Meaning | CLI behavior |
|---|---|---|
| `requires` | Needed for useful operation | `start X` offers to start missing requires (prompt or `--with-deps`) |
| `suggests` | Common companion | Printed in `--plan`, not auto-started unless profile says so |
| `conflicts` (optional) | Mutual exclusion | Warn in plan output |

### Rules

1. **Compose remains source of truth for containers.** The map is an operator UX layer, not a competing orchestrator.
2. **Never auto-start across security boundaries** (for example services that open WAN ports) without explicit confirmation.
3. **Profiles can alias maps.** “AI Mode” profile applies a known subgraph.
4. **Idle auto-stop consults the map.** Stopping a required dependency of a still-running dependent should warn or stop dependents per policy (document choice in implementation).
5. **Validate in CI.** Schema check that names exist in Compose (or documented aliases).

### Day-to-day commands

```bash
./tu-vm.sh deps show open-webui
./tu-vm.sh start open-webui --with-deps --plan
./tu-vm.sh start open-webui --with-deps
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Runtime | Docker Compose | Custom scheduler framework |
| UX | `tu-vm.sh` + profiles | Per-service shell scripts that diverge |
| Validation | YAML schema + Compose name check | Hidden magic in dashboard JS only |
| Docs | Playbook + this website page | Undocumented tribal knowledge |

## Rollout

1. Land this page with initial edges taken from README Tier guidance.
2. Add `config/service-dependencies.yaml` + validator script.
3. Wire `--with-deps` / `--plan` into `tu-vm.sh` start paths.
4. Surface missing-dependency hints in helper status messages.
5. Keep website table generated or curated from the YAML (single source).

## Acceptance criteria

- [ ] Map names reconcile with Compose services (CI-checked).
- [ ] Default start behavior without `--with-deps` stays backward compatible.
- [ ] Security-sensitive starts still require explicit operator intent.
- [ ] Idle-stop interaction is documented.
- [ ] Profiles can reuse the same map rather than duplicating adjacency lists.

## Rollback

Ignore the map file; `tu-vm.sh start` behaves as today. Remove `--with-deps` flag if needed.

## Success metrics

- Fewer “Open WebUI up but models fail” support threads caused by forgotten Ollama.
- Profile apply/plan output references the same dependency edges.
- Contributors extend YAML instead of inventing new orchestrators.
