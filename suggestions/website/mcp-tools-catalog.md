---
title: Community MCP Tools Catalog
description: Contribution contract and website catalog for optional TU-VM MCP tool images.
last_updated: 2026-07-24
owner: maintainers
status: proposed
theme: mcp
impact: high
---

# Community MCP Tools Catalog

## Summary

Create a **community-curated catalog and contribution contract** for optional MCP tool images under [`mcp-tools/`](../../mcp-tools/), gated by the existing [`mcp-gateway`](../../mcp-gateway/) security controls.

This is a constructional suggestion: it reuses Compose, Dockerfiles, gateway allowlists, proof/dedupe stores, and `./tu-vm.sh chain-smoke` instead of inventing a plugin marketplace, dynamic installer, or shadow MCP host.

## Problem

TU-VM already ships optional MCP stdio servers (`mcp_playwright`, `mcp_filesystem`, `mcp_fetch`, `mcp_memory`) and a policy-heavy MCP Gateway (allowlists, write approval, kill switch, proof signing). Community members who want to add or document tools currently face:

- No single catalog of purpose, risk class, required env vars, and health checks
- No shared review checklist for network, filesystem, or browser-capable tools
- Risk of ad-hoc Compose edits that bypass `MCP_ALLOWED_SERVERS` and approval controls
- Duplicate “add an integrations hub” suggestions that ignore the gateway already in-tree

## Existing assets to reuse (do not reinvent)

| Asset | Role |
|---|---|
| `mcp-tools/*/Dockerfile` | Buildable stdio server images |
| `docker-compose.yml` MCP services | Runtime wiring and resource bounds |
| `mcp_gateway` + `MCP_ALLOWED_SERVERS` | Explicit enablement policy |
| `MCP_WRITE_APPROVAL_*`, `MCP_EXECUTION_KILL_SWITCH` | Write-path safety |
| `./tu-vm.sh chain-smoke` | Open WebUI → MCP → n8n evidence |
| GitHub Issues / PRs | Intake, review, attribution |
| Static docs website (future) | Read-only catalog rendering |

Out of scope for this suggestion:

- Runtime download of unreviewed MCP servers
- Dashboard-hosted MCP installation UI
- A second identity or marketplace ratings system
- Bypassing gateway proof/approval paths for “convenience”

## Proposed website experience

Publish an **MCP Tools** section with three pages (can start as this single catalog page):

1. **Catalog index** — one row per tool (core + community)
2. **Contribute a tool** — metadata contract + security review checklist
3. **Operator enablement** — which `tu-vm.sh` / Compose steps apply, and how to disable quickly

### Catalog row fields

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Stable slug, matches Compose service naming intent |
| `title` | yes | Human name |
| `summary` | yes | One or two sentences |
| `source_path` | yes | e.g. `mcp-tools/fetch` |
| `transport` | yes | `stdio` via supergateway/HTTP bridge, etc. |
| `capability_class` | yes | `read-network`, `read-fs`, `browser`, `memory`, `write-*` |
| `default_enabled` | yes | Usually `false` for optional tools |
| `required_env` | yes | Names only—never values |
| `gateway_allowlist_keys` | yes | Keys that must appear in `MCP_ALLOWED_SERVERS` or related flags |
| `data_access` | yes | Paths/networks touched |
| `security_notes` | yes | Prompt-injection, exfil, and privilege risks |
| `health_check` | yes | Command or compose health reference |
| `smoke` | yes | How to prove it works (`chain-smoke` subset or tool-specific) |
| `maintainer` | yes | CODEOWNERS path or named team |
| `compatibility` | yes | Tested TU-VM / upstream versions |
| `status` | yes | `core`, `community-pilot`, `deprecated` |

### Seed catalog (already in repository)

| ID | Purpose | Capability class | Notes |
|---|---|---|---|
| `mcp_fetch` | URL fetch helper for assistants | `read-network` | Network egress; sanitize targets |
| `mcp_filesystem` | Constrained filesystem tools | `read-fs` / potential write | Mount allowlists required |
| `mcp_memory` | Persistent memory helper | `memory` | Treat stored text as untrusted |
| `mcp_playwright` | Browser automation | `browser` | Highest misuse risk; keep optional |

Document these four **before** accepting new community tools so the template is proven.

## Contribution contract

### Package layout

```text
mcp-tools/<id>/
  Dockerfile
  README.md          # purpose, mounts, ports, threat notes
  # optional: compose fragment only if maintainers adopt extension pilot
```

Metadata for the website catalog may start as a single YAML/JSON index (for example `mcp-tools/catalog.yaml`) consumed by the docs build. Split into per-tool manifests only when independent versioning requires it.

### Review checklist (required for merge)

- [ ] Dockerfile pins base images or documents digest policy
- [ ] No secrets baked into the image; env vars documented by name only
- [ ] Filesystem mounts are read-only by default unless write is justified
- [ ] Network egress is explained; SSRF and internal-host risks called out
- [ ] Gateway allowlist / feature flags updated deliberately (not “allow all”)
- [ ] Write operations respect `MCP_WRITE_APPROVAL_*` when applicable
- [ ] Kill-switch behavior verified (`MCP_EXECUTION_KILL_SWITCH`)
- [ ] `compose config` renders; image builds locally or in CI
- [ ] Smoke path documented; `chain-smoke` still passes when tool is disabled
- [ ] License and upstream attribution recorded
- [ ] Rollback: how to remove the service without breaking Tier 1

### Security posture for community tools

Treat every community MCP tool as **untrusted code with LLM-reachable capabilities**:

1. Default **off** in secure deployments
2. Explicit operator enablement via Compose profiles or documented `docker compose up` targets
3. No privileged containers unless a dedicated security review accepts them
4. Catalog must show capability class icons/text (color alone is insufficient)
5. Prompt-injection guidance: tool outputs are data, not instructions
6. Prefer gateway-mediated calls over direct exposure of tool ports on LAN

This aligns with the platform’s existing proof store, dedupe store, and approval patterns rather than inventing a parallel policy engine.

## Day-to-day operator workflow

```text
# Discover
# (website catalog + README table)

# Enable deliberately (example shape; exact flags follow compose docs)
sudo docker compose up -d mcp_fetch
# ensure MCP_ALLOWED_SERVERS / related flags include the tool’s key

# Evidence
./tu-vm.sh chain-smoke

# Disable quickly
sudo docker compose stop mcp_fetch
# or re-enable MCP_EXECUTION_KILL_SWITCH=true during an incident
```

Website copy should link to live command help instead of freezing flags that drift.

## Implementation plan

### Phase A — Catalog truthfulness

1. Add `mcp-tools/catalog.yaml` (or equivalent) describing the four existing tools
2. Publish this website page as the human-readable catalog
3. Link from Community hub + playbook “MCP and automation smoke”

### Phase B — Contribution path

1. Add `mcp-tools/README.md` contribution section pointing at this contract
2. Extend CODEOWNERS for `mcp-tools/` and `mcp-gateway/`
3. Add CI job: validate catalog schema + `docker compose config` for MCP services

### Phase C — Community pilot

1. Accept one external/community tool that is read-only and low egress
2. Require the full checklist; keep default-off
3. Retrospect: trim fields that added noise without review value

### Phase D — Optional automation

1. n8n reminder when catalog `compatibility` is older than N releases
2. Docs build generates the catalog table from YAML (single source)
3. Only then consider `./tu-vm.sh mcp list` as a thin wrapper over Compose labels

## Relationship to other suggestions

| Suggestion | Relationship |
|---|---|
| [`../extensions-and-integration-framework.md`](../extensions-and-integration-framework.md) | Broader package contract; MCP catalog is the first concrete pilot surface |
| [`../website-community-roadmap.md`](../website-community-roadmap.md) | Integrations catalog theme; this page specializes MCP tools |
| Knowledge packs in `helper/chat-context/` | Context files ≠ executable tools; keep catalogs separate |
| Dashboard modularization | Do **not** host MCP installers on the control plane |

## Success metrics

- Time for a reviewer to accept/reject a new MCP tool drops (checklist completeness)
- Zero merges that widen `MCP_ALLOWED_SERVERS` without catalog + security notes
- Operators can name capability class and disable path for each enabled tool
- Duplicate “build an MCP marketplace” suggestions decline because the contract is visible

## Acceptance criteria

- All four in-repo MCP tools appear in the catalog with required fields
- Contribution checklist is linked from CONTRIBUTING or `mcp-tools` docs
- CI validates catalog schema once the file exists
- Disabling or omitting optional MCP tools never breaks Tier 1 health
- Website remains read-only; enablement stays on Compose / `tu-vm.sh`

## Rollback

1. Remove or deprecate catalog entries
2. Revert Compose/service additions for pilot tools
3. Keep gateway defaults restrictive
4. Website page can remain as historical guidance without runtime coupling
