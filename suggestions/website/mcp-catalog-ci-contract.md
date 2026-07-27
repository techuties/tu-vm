---
title: MCP Catalog CI Contract
description: Constructional implementation contract for mcp-tools/catalog.yaml and CI validation that reuses the Stage 1 MCP catalog and existing gateway controls.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: mcp
impact: high
---

# MCP Catalog CI Contract

## Problem

Stage 1 proposed a human-readable MCP tools catalog and contribution checklist. The repository already ships four optional MCP tool images and a policy-heavy MCP Gateway. What is still missing is a **machine-readable catalog** that CI can validate so community additions cannot silently drift from Compose services, allowlists, or documented risk classes.

Without that contract, every new tool risks ad-hoc Compose edits and duplicate “integrations hub” reinvention.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Stage 1 `mcp-tools-catalog.md` (open PR) | Human contribution contract and row fields |
| `mcp-tools/*/Dockerfile` | Buildable stdio server images |
| `docker-compose.yml` MCP services | Runtime wiring and resource bounds |
| `mcp_gateway` + `MCP_ALLOWED_SERVERS` | Explicit enablement policy |
| `./tu-vm.sh chain-smoke` | Open WebUI → MCP → n8n evidence |
| GitHub Actions CI | Existing compose/smoke/docs gates |
| Static docs site (future) | Renders catalog rows from YAML |

Out of scope:

- Runtime download of unreviewed MCP servers
- Dashboard-hosted MCP installation UI
- A second marketplace or ratings system
- Bypassing gateway proof/approval paths

## Proposal

Add a single source of truth:

```text
mcp-tools/catalog.yaml
```

and a small validator that CI (and contributors) can run.

### Catalog schema (v1)

```yaml
version: 1
tools:
  - id: mcp_fetch
    title: Fetch
    summary: URL fetch helper for assistants
    source_path: mcp-tools/fetch
    compose_service: mcp_fetch   # must exist in docker-compose.yml when present
    transport: stdio
    capability_class: read-network
    default_enabled: false
    required_env: []             # names only
    gateway_allowlist_keys: []   # keys that must be documentable for enablement
    data_access:
      networks: [egress]
      paths: []
    security_notes: "Sanitize targets; treat content as untrusted."
    health_check: "compose health or documented probe"
    smoke: "chain-smoke subset or tool-specific"
    maintainer: "@techuties/tu-vm-maintainers"
    compatibility: "TU-VM mainline"
    status: core                 # core | community-pilot | deprecated
```

Required fields match the Stage 1 catalog row contract. Keep one file until independent versioning forces per-tool manifests.

### Seed entries (already in repository)

| ID | `source_path` | Capability class |
|---|---|---|
| `mcp_fetch` | `mcp-tools/fetch` | `read-network` |
| `mcp_filesystem` | `mcp-tools/filesystem` | `read-fs` |
| `mcp_memory` | `mcp-tools/memory` | `memory` |
| `mcp_playwright` | `mcp-tools/playwright` | `browser` |

Document these four **before** accepting community tools so the template is proven.

### Validator behavior (`scripts/validate-mcp-catalog.py` or `.sh`)

Checks (fail closed on schema errors):

1. YAML parses; `version` is supported.
2. Every `id` is unique and slug-safe.
3. Every `source_path` exists and contains a `Dockerfile`.
4. Every non-deprecated `compose_service` appears in `docker-compose.yml` (or is explicitly marked `compose_optional: true` with rationale).
5. `capability_class` is in an allowlist enum.
6. `required_env` contains names only (reject values that look like secrets).
7. `status` is one of `core`, `community-pilot`, `deprecated`.
8. Optional advisory: warn if a Compose MCP service exists without a catalog row (drift detection).

Exit codes:

- `0` — valid
- `1` — schema or consistency failure
- `2` — usage / IO error

### CI wiring

Add a job step to `.github/workflows/ci.yml` (or a focused workflow):

```text
python3 scripts/validate-mcp-catalog.py
```

Run on changes to:

- `mcp-tools/**`
- `docker-compose.yml`
- `scripts/validate-mcp-catalog.py`
- the workflow file itself

Keep the check fast and dependency-light (stdlib + PyYAML already used elsewhere, or a tiny pure-Python subset if preferred).

### Contributor day-to-day flow

1. Open an Idea / suggestion Issue only if the capability is new and not already covered.
2. Copy an existing `mcp-tools/<id>/` Dockerfile pattern.
3. Add a catalog row with honest `capability_class` and `security_notes`.
4. Run the validator locally before push.
5. Document enablement via gateway allowlists—never imply default-on for browser/write tools.
6. Prove with `./tu-vm.sh chain-smoke` (or a documented subset) when the stack is available.

### Website rendering later

After docs-framework adoption gates pass, generate the catalog table from `catalog.yaml` at build time. Until then, keep Stage 1 markdown as the human guide and this page as the implementation contract—**one editable YAML**, not two catalogs.

## Acceptance criteria

- [ ] `mcp-tools/catalog.yaml` seeds the four in-repo tools.
- [ ] Validator fails on missing Dockerfile, unknown compose service, or secret-looking env values.
- [ ] CI runs the validator on relevant path changes.
- [ ] CONTRIBUTING (or Stage 1 catalog page) links to this contract for MCP PRs.
- [ ] No runtime marketplace, installer UI, or gateway bypass is introduced.

## Rollout and rollback

1. Land YAML + validator as advisory (warn) for one release if noise is high.
2. Flip to fail-closed once seed rows are clean.
3. Rollback = revert workflow step; catalog file can remain as documentation.

## Success signals

- MCP PRs cite catalog rows and pass CI without maintainer re-explaining allowlists.
- Compose ↔ catalog drift is caught before merge.
- Community tool ideas reuse this contract instead of proposing a plugin store.
