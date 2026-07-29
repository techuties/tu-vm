---
title: n8n Workflow Catalog
description: Constructional community catalog and contribution contract for reusable n8n workflows that complements the MCP tools catalog without inventing a second automation platform.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# n8n Workflow Catalog

## Problem

TU-VM already ships n8n (and n8n-MCP) as Tier 2 automation, MinIO buckets for `n8n-workflows`, and `./tu-vm.sh chain-smoke` for Open WebUI → MCP → n8n evidence. Community suggestions repeatedly ask for “shared automations” or a custom workflow marketplace. Stage 1/4 cover **MCP tool** catalogs; they do not cover **n8n workflow JSON** contribution, review, or discovery.

Without a catalog contract, contributors paste opaque workflow exports into Issues, skip credential hygiene, or propose replacing n8n with yet another orchestrator.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` / `n8n_mcp` Compose services | Runtime automation (Tier 2) |
| MinIO `n8n-workflows` bucket + mounts | Input/output artifact storage |
| `./tu-vm.sh chain-smoke` | Cross-service execution evidence |
| `scripts/extract-n8n-node-types.sh` | Node-type refresh after updates |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Parallel pattern for MCP images |
| Stage 3/4 extension pilot contracts | Compose-backed optional packages |
| GitHub Issues / PR review | Intake and ownership |
| AFFiNE (optional Tier 2) | Human collaboration notes—not the workflow store |

Out of scope:

- Runtime download of unreviewed workflow packs from the public internet by default
- Storing live credentials, webhook secrets, or `.env` values inside exported JSON
- Building a custom workflow engine beside n8n
- Dashboard one-click “install any workflow” without review

## Proposal

Publish a **human + machine catalog** for community n8n recipes, mirroring the MCP catalog pattern but tuned to workflow exports.

### Layout (v1)

```text
community-workflows/
  catalog.yaml
  <workflow-id>/
    README.md           # purpose, triggers, credentials checklist
    workflow.json       # n8n export with credentials stripped
    fixtures/           # optional sample payloads (no secrets)
```

Optional later: an `extensions/<id>/` package may *reference* a workflow id instead of embedding JSON twice (extension pilot remains Compose-shaped).

### `catalog.yaml` row fields

| Field | Purpose |
|---|---|
| `id` | Stable slug |
| `title` / `summary` | Human discovery |
| `n8n_version_min` | Compatibility floor |
| `triggers` | cron / webhook / manual / chat |
| `credentials` | List of **types** required (e.g. `httpHeaderAuth`), never values |
| `tier2_deps` | Services that must be running (`n8n`, `minio`, …) |
| `risk_class` | `read` \| `write-internal` \| `egress` \| `control-plane` |
| `validation` | Commands maintainers ran (`chain-smoke`, manual path) |
| `owners` | GitHub team or individuals |

### Risk classes

| Class | Meaning | Review bar |
|---|---|---|
| `read` | Reads LAN services / MinIO only | Normal PR |
| `write-internal` | Mutates MinIO/docs/internal state | Maintainer + rollback notes |
| `egress` | Calls external URLs | Explicit allow rationale; prefer off by default |
| `control-plane` | Touches helper control or hosts | **Reject** or rewrite—use Stage 5 control-plane contract instead |

### Contribution checklist

1. Export from n8n → strip credentials → confirm JSON has empty/placeholder credential refs.
2. Document trigger, schedule impact, and failure modes in `README.md`.
3. Add/update `catalog.yaml` row.
4. Note Tier 2 deps and whether `chain-smoke` applies.
5. Open PR with `integrations` (or agreed) label; link Issue.

### CI (lightweight v1)

```text
scripts/validate-n8n-workflow-catalog.py
```

- Every directory has `workflow.json` + `README.md`
- JSON parses; fail if high-entropy secret-like strings match a small denylist (`API_KEY=`, `BEGIN RSA`, etc.)
- `risk_class` present; `control-plane` class fails CI (must not ship here)
- Catalog ids unique and paths resolve

### Website placement

- Community → Automate → n8n workflow catalog
- Cross-link Stage 1 MCP catalog: “stdio tools vs workflow recipes”
- Playbooks: how operators import a reviewed workflow into their LAN n8n

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Orchestration | Existing n8n Tier 2 | New in-house cron DSL |
| Packaging | Repo catalog + optional MinIO distribution | Unreviewed remote marketplaces |
| Secrets | n8n credential store on operator host | Secrets in git |
| Evidence | chain-smoke + README validation | Screenshot-only PRs for egress workflows |

## Rollout

1. Land this page; add empty `community-workflows/catalog.yaml` with schema comment.
2. Seed **one** reference workflow (e.g. daily checkup notifier that only hits local services) as the pilot.
3. Add validator + CI path filter on `community-workflows/**`.
4. After Stage 4 MCP CI lands, keep MCP and n8n catalogs separate—do not merge schemas.

## Acceptance criteria

- [ ] Catalog layout and risk classes documented.
- [ ] At least one credential-stripped pilot workflow (or explicit “pilot pending” stub with schema only).
- [ ] CI rejects obvious secrets and `control-plane` risk class.
- [ ] Docs state that GitHub PR review is mandatory before operators import.

## Rollback

Remove CI job; keep page as guidance. Delete pilot JSON if it confuses operators—catalog schema can remain.

## Success metrics

- Community automation ideas land as catalog PRs instead of “replace n8n” proposals.
- Zero credential leaks in workflow JSON detected in PR review or CI.
- Operators can discover Tier 2 deps before importing a recipe.
