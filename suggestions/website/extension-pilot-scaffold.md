---
title: Extension Pilot Scaffold
description: Constructional scaffold for the first community extension package and validate-extension.sh, implementing the Stage 3 extension pilot contract.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# Extension Pilot Scaffold

## Problem

Stage 3 defines an extension pilot contract (`extension.yaml`, optional Compose fragment, security baseline). The community still lacks a **copyable on-disk scaffold** and a validator script, so “plugin marketplace” suggestions keep reappearing and ad-hoc Compose forks accumulate.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Stage 3 `extension-pilot-contract.md` | Package shape and security baseline |
| Stage 1 MCP catalog / Stage 4 MCP CI | Specialized path for `mcp-tools/*` |
| Docker Compose Tier 2 | Optional runtime units |
| `tu-vm.sh start-service` / `stop-service` | Enablement without a new orchestrator |
| `scripts/check-config.sh`, smoke, doctor | Validation evidence |
| nginx allowlist patterns | Control-plane exposure rules |
| GitHub PR review | Intake and ownership |

Out of scope:

- Runtime download of unreviewed archives
- Privileged containers by default
- Marketplace ratings / second identity system
- Replacing MCP catalog rules for MCP stdio tools

## Proposal

Land one reference pilot under:

```text
extensions/
  README.md
  example-health-note/
    extension.yaml
    docker-compose.extension.yml   # optional; may be omitted for docs-only pilots
    README.md
    scripts/
      validate.sh                  # optional thin wrapper
```

and a repo-level validator:

```text
scripts/validate-extension.sh <extension-id|--all>
```

### Reference pilot choice

Prefer a **low-risk, docs-or-helper oriented** pilot that demonstrates the contract without adding privileged services. Examples that fit TU-VM:

1. **Docs-only community note pack** — `extension.yaml` + README that points operators at playbooks (no Compose fragment). Proves metadata validation alone.
2. **Optional read-only helper sidecar** — only if maintainers want a Compose fragment example; must be non-privileged, default-off, and allowlist-aware.

Start with (1) unless a maintainer-sponsored service fragment is ready. The website should show both layouts.

### Minimal `extension.yaml` for the scaffold

```yaml
id: example-health-note
title: Example Health Note Pack
summary: Reference pilot that documents doctor/smoke evidence for community triage.
version: 0.1.0
compatible_tu_vm: ">=mainline"
requires_services: [helper_index, nginx]
provides: [docs]
network:
  ingress: none
  egress: none
data_access:
  volumes: []
  paths: []
security_class: read-only
enable:
  - "No runtime enablement; read extensions/example-health-note/README.md"
disable:
  - "Remove or ignore the extension directory; nothing to stop"
validation:
  - "./scripts/validate-extension.sh example-health-note"
  - "./tu-vm.sh doctor"
maintainer: "@techuties/tu-vm-maintainers"
status: pilot
```

### `scripts/validate-extension.sh` checks

1. Directory `extensions/<id>/` exists.
2. `extension.yaml` parses and required fields are present (align with Stage 3 table).
3. `id` matches directory name.
4. `security_class` is in an allowlist; reject undocumented `privileged` hints in YAML.
5. If `docker-compose.extension.yml` exists:
   - `docker compose -f docker-compose.yml -f extensions/<id>/docker-compose.extension.yml config` succeeds (or documented compose invocation).
   - Fail if the fragment sets `privileged: true` without a Decision Log exception marker.
6. README exists with enable/disable and secret-name documentation rules.
7. Exit non-zero on failure; support `--all` to walk `extensions/*/`.

### CI posture

- Run validator when `extensions/**` changes.
- Start as non-blocking warn if needed; flip to required once the example pilot is green.
- Do **not** auto-start extension services in CI.

### Contributor day-to-day flow

1. Copy `extensions/example-health-note/` to `extensions/<new-id>/`.
2. Fill metadata honestly (`security_class`, network, data access).
3. Run `./scripts/validate-extension.sh <new-id>`.
4. Open a PR; link the Stage 3 contract and any Decision Log exception.
5. If the extension is MCP-facing, also satisfy the MCP catalog CI contract.

### Relationship to MCP tools

| Kind | Path | Contract |
|---|---|---|
| MCP stdio tool images | `mcp-tools/<id>/` | Stage 1 catalog + Stage 4 CI |
| Broader optional packs | `extensions/<id>/` | Stage 3 contract + this scaffold |

Do not duplicate MCP tools as extensions unless the extension wraps non-MCP runtime pieces.

## Acceptance criteria

- [ ] `extensions/README.md` explains default-off and security baseline.
- [ ] One reference pilot validates with `scripts/validate-extension.sh`.
- [ ] CI invokes the validator on `extensions/**` changes.
- [ ] No privileged defaults; no remote archive installers.
- [ ] Website pages link Stage 3 contract (shape) ↔ Stage 4 scaffold (files).

## Rollout and rollback

1. Docs-only pilot + validator first.
2. Optional Compose fragment example second.
3. Rollback = remove scaffold; contract pages remain as guidance.

## Success signals

- New integration Ideas cite `extensions/<id>/` instead of “plugin marketplace”.
- Reviewers check validator output instead of reinventing security questions.
- Core `docker-compose.yml` stays the Tier 1 system of record.
