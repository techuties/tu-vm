---
title: Extension Pilot Contract
description: Constructional community contract for a first TU-VM extension package using Docker Compose fragments and existing tu-vm.sh surfaces.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# Extension Pilot Contract

## Problem

Community members want to add optional capabilities (extra automations, niche tools, experimental UIs) without waiting for core maintainers to absorb every idea into Tier 1. Historical suggestions proposed plugin marketplaces, privileged installers, and dashboard app stores. Those reinvent Compose and bypass MCP Gateway / nginx allowlist patterns.

[`../extensions-and-integration-framework.md`](../extensions-and-integration-framework.md) already sketches a package contract. What is missing is a **publishable website pilot**: one small, reviewable extension shape the community can copy.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Docker Compose Tier 2 services | Optional runtime units |
| `nginx/` reverse proxy patterns | Route exposure only when intentional |
| `tu-vm.sh start-service` / `stop-service` | Enablement without a new orchestrator |
| MCP Gateway allowlists | Tooling safety for assistant-connected servers |
| Stage 1 MCP catalog | Specialized contract for `mcp-tools/*` |
| Playbooks + doctor/smoke | Validation evidence |
| GitHub PR review | Intake and ownership |

Out of scope for the pilot:

- Runtime download of unreviewed archives
- Privileged containers by default
- A second identity/marketplace ratings system
- Replacing MCP catalog rules for MCP stdio tools

## Proposal

Pilot **one reference extension** that follows a minimal on-disk contract. Website docs describe the contract; implementation follows after the schema is reviewed.

### Directory convention

```text
extensions/
  <extension-id>/
    extension.yaml          # required metadata
    docker-compose.extension.yml  # optional service fragment
    README.md               # operator enable/disable notes
    scripts/
      validate.sh           # optional local checks
```

Keep extensions **disabled by default**. Core `docker-compose.yml` stays the system of record for Tier 1.

### `extension.yaml` required fields

| Field | Meaning |
|---|---|
| `id` | Stable slug (`compose` / folder name) |
| `title` / `summary` | Human description |
| `version` | Semver for the extension package |
| `compatible_tu_vm` | Version/commit range tested |
| `requires_services` | Existing services that must be healthy |
| `provides` | Capabilities (`ui-route`, `worker`, `mcp-tool`, …) |
| `network` | Egress/ingress expectations |
| `data_access` | Volumes/paths touched |
| `security_class` | `read-only`, `write-local`, `network-egress`, … |
| `enable` | Documented commands (usually `start-service` wrappers later) |
| `disable` | Documented stop/remove steps |
| `validation` | doctor/smoke/compose checks |
| `maintainer` | CODEOWNERS path or community handle |
| `status` | `pilot`, `community`, `deprecated` |

### Security baseline for pilots

1. No `privileged: true` unless a Decision Log exception exists.
2. Secrets via env var **names** documented in README—never committed values.
3. Default deny on new public routes; reuse nginx allowlist patterns for any control endpoints.
4. If the extension exposes MCP-facing tools, it must also satisfy the Stage 1 MCP catalog checklist.
5. Resource limits declared for any new containers (CPU/memory), consistent with Compose norms.

### Day-to-day operator flow (pilot)

```bash
# inspect
cat extensions/<id>/README.md

# validate fragment (proposed helper)
./scripts/validate-extension.sh <id>

# enable services the extension documents (today: existing tu-vm.sh)
./tu-vm.sh start-service <name>
./tu-vm.sh status
./tu-vm.sh doctor
```

Future thin wrappers (only after two successful pilots):

```text
./tu-vm.sh extension list
./tu-vm.sh extension show <id>
./tu-vm.sh extension enable <id> --plan
./tu-vm.sh extension disable <id>
```

These wrappers must orchestrate Compose/`tu-vm.sh`—not invent a parallel runtime.

### Suggested first pilot candidates (pick one)

| Candidate | Why it is a good pilot | Risk notes |
|---|---|---|
| Read-only status exporter fragment | Exercises metadata + validation without write tools | Must not weaken control-plane authz |
| Documented n8n workflow pack **as an extension of playbooks** | High day-to-day value; stays Tier 2 | Keep secrets out of exported workflows |
| Optional observability sidecar already discussed in monitoring docs | Clear enable/disable | Resource cost on laptops |

Prefer a pilot that **does not** require new public ports on `laptop-saver` hosts (see Stage 2 hardware matrix).

### Website catalog row

Publish an Extensions index (can start as a section here) with:

- id, summary, security_class, host class fit, status, maintainer, links to README + Decision entry

Community PRs update the catalog the same way as Stage 1 MCP catalog rows.

## Relation to other Stage pages

| Page | Boundary |
|---|---|
| Stage 1 MCP catalog (sibling when merged) | MCP stdio images and gateway allowlists |
| [`../website-community-roadmap.md`](../website-community-roadmap.md) | Knowledge packs / integration recipes—not Compose extensions |
| Stage 2 operator profiles (sibling when merged) | Which Tier 2 sets are running; extensions may declare profile affinity |
| [Quality gates](./community-quality-gates.md) | Evidence required on extension PRs |
| [Decision log](./decision-log.md) | Exceptions for elevated privileges |

## Rollout

1. Land this contract page and link it from the website index + extensions planning doc.
2. Add `extensions/README.md` pointing here (implementation PR, not required for this docs stage).
3. Accept one pilot PR with `extension.yaml` + compose fragment + validation notes.
4. Add warning-only `validate-extension.sh` in CI for `extensions/**`.
5. Only then consider `tu-vm.sh extension *` wrappers.

## Rollback

- Disable documented services; remove or ignore the compose fragment.
- Delete or deprecate the catalog row; set `status: deprecated`.
- Tier 1 remains unaffected if the pilot kept isolation rules.

## Success criteria

- A contributor can scaffold a pilot using only this page + existing Compose knowledge
- Reviewers evaluate risk from `extension.yaml` without reading ad-hoc chat history
- No pilot ships that bypasses allowlists, secret hygiene, or resource limits
- Duplicate “build a plugin marketplace” suggestions can be declined with a link here
