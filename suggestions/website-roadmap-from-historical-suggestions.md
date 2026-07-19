# Website Roadmap From Historical Suggestions

This roadmap converts recurring historical community-suggestion themes into a concrete implementation sequence for a community-based website and operations platform.

This page preserves product direction and dependencies from historical branches. [`implementation-backlog.md`](./implementation-backlog.md) is the source for current execution priority and shipped status.

It intentionally reuses existing assets:

- `README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`
- `tu-vm.sh` as the operational source of truth
- `helper/uploader.py` status and control surfaces
- `nginx/html/index.html` as the existing entrypoint
- `scripts/daily-checkup.sh` and monitoring configuration

---

## 1) Historical feature directions to carry forward

Recurring ideas found across prior suggestion branches:

1. Community docs and website structure around operations and onboarding
2. Formalized governance and contribution pathways
3. Practical contributor tooling for diagnostics, validation, and release hygiene
4. Phased evolution of profiles, battery awareness, idle optimization, and historical metrics

Roadmap design principle: sequence work so each phase creates reusable foundations for the next phase.

---

## 2) Current-state reconciliation

Historical phases must be checked against the repository before being proposed again:

| Historical direction | Current evidence | Status | Remaining work |
|---|---|---|---|
| Suggestion intake | [GitHub issue form](../.github/ISSUE_TEMPLATE/suggestion.yml) | Implemented | Keep one intake path; do not add a local queue/API. |
| Contribution and review | [`CONTRIBUTING.md`](../CONTRIBUTING.md), PR template, CODEOWNERS | Implemented / partial | Replace placeholder owners and keep labels aligned. |
| Triage and releases | stale workflow and Release Drafter | Implemented | Measure usefulness before adding more bots. |
| Contributor diagnostics | `doctor`, config/smoke/pre-push scripts | Implemented | Add live helper CI coverage and one thin task alias only if needed. |
| Community entrypoint | dashboard community strip and operator playbooks | Implemented | Publish curated Markdown navigation/status views. |
| Static docs framework | Markdown is rendered by GitHub; no dedicated docs build | Proposed | Apply the adoption gate in [`website-and-docs-framework.md`](./website-and-docs-framework.md). |
| Extension ecosystem | MCP tools exist; extension contract is documentation only | Proposed | Pilot schema, validator, reference extension, and catalog. |
| Profiles and resource optimization | Mentioned in historical docs/CHANGELOG | Proposed | Define data contracts and safe opt-in behavior after test foundations. |

---

## 3) Phase A: Curate the community website baseline

### Goal

Create a reliable community information layer where proposals and decisions are discoverable, linked, and maintainable.

### Deliverables

1. Curate the current canonical pages under `suggestions/`; after framework adoption, publish them from `docs/community/` (or the configured content root) with redirects:
   - Home
   - Install
   - Operate
   - Security
   - Community
   - Suggestions
2. Generate a suggestions index with:
   - historical baseline
   - active proposals
   - accepted/rejected items
3. Apply the metadata, body, risk, evidence, and lifecycle contract from [`website-community-pages.md`](./website-community-pages.md).
4. Mark overlapping historical files as historical or superseded instead of presenting all files as active.

### Dependencies

- Existing GitHub issue form, repository Markdown, and canonical-page ownership.

### Success signals

- New contributor can find contribution and suggestion workflow in two clicks or fewer.
- Existing operator docs are navigable by task rather than only by long-form README scanning.

---

## 4) Phase B: Community framework and governance activation

### Goal

Make it easy for contributors to understand how work is owned, reviewed, and accepted.

### Implemented foundation

- GitHub issue/PR templates and the `CONTRIBUTING.md` workflow.
- Security reporting policy.
- Stale/needs-info automation and Release Drafter.
- CODEOWNERS structure and documented label conventions.

### Remaining deliverables

1. Role and ownership model published:
   - maintainers
   - core contributors
   - contributors
   - users/testers
2. Subsystem ownership table:
   - CLI operations (`tu-vm.sh`)
   - helper API
   - nginx and network/security controls
   - monitoring and checkup scripts
   - document-processing pipeline
3. Replace placeholder CODEOWNERS identities with active maintainers
4. Align lifecycle labels or Project fields with the canonical website status model

### Dependencies

- Phase A community docs section.

### Success signals

- Fewer duplicate issues.
- Faster routing of work to relevant reviewers.
- More PRs submitted with clear validation and rollback notes.

---

## 5) Phase C: Contributor tooling for day-to-day operations

### Goal

Reduce friction for development, testing, and release preparation.

### Deliverables

Implemented foundations:

1. `doctor` diagnostics flow (entrypoint command and JSON output)
2. config validator and static/live smoke modes
3. pre-push wrapper and release-note helper
4. static helper response contract validation

Remaining deliverables:

1. minimal live helper contract job in CI,
2. image-level vulnerability scanning and an enforceable severity policy,
3. optional task alias that wraps existing scripts without replacing `tu-vm.sh`,
4. canonical suggestion metadata/link validator,
5. semantic drift check for documented Compose services, helper routes, and CLI commands.

### Dependencies

- Phase B review expectations, so tooling aligns with accepted quality standards.

### Success signals

- More issues resolved in first reproduction cycle.
- Fewer runtime failures from missing or inconsistent configuration.
- Higher consistency in release documentation quality.

---

## 6) Phase D: Validated community extensions

### Goal

Let contributors add optional integrations without repeatedly modifying core Compose, Nginx, helper, and dashboard code.

### Deliverables

1. Extension metadata schema and capability declaration
2. Validator for compatibility, security, routes, ports, networks, and secrets
3. Template plus one reference extension
4. Read-only website compatibility and support catalog
5. Dry-run list/validate CLI before enable/disable automation

### Dependencies

- Phase C validation conventions and explicit owner/security review.

### Success signals

- Reference extension can be added and removed without changing Tier 1 behavior.
- Reviewers see compatibility and risk in one machine-validated manifest.
- Community integrations have named ownership and support status.

---

## 7) Phase E: Profile-driven operations and startup behavior

### Goal

Operationalize historical profile and startup suggestions into predictable behavior for users and contributors.

### Deliverables

1. Profile presets:
   - Energy Save
   - Work Mode
   - AI Mode
   - Full Stack
2. Profile-aware status API surfaces and dashboard controls
3. Smart startup sequencing:
   - Tier 1 first
   - defer heavy services unless explicitly requested
4. Transparent startup summary indicating what started and why
5. Advisory service-dependency map:
   - define user-facing dependencies in reviewed profile metadata and validate service IDs against Compose,
   - distinguish required, recommended, and optional relationships,
   - show missing dependencies before an action and offer an explicit grouped start,
   - do not infer forced auto-start behavior from Compose `depends_on` alone.

### Dependencies

- Phase C tooling to validate behavior and reduce rollout regressions.

### Success signals

- Reduced startup resource spikes.
- Better user understanding of active services and profile state.
- Fewer failed starts caused by missing companion services without silently expanding the active profile.

---

## 8) Phase F: Battery awareness, idle optimization, and usage history

### Goal

Deliver evidence-based optimization loops that are useful for a laptop/home-lab environment.

### Deliverables

1. Battery telemetry object in status surfaces
2. Battery-aware recommendations and optional profile automation
3. Configurable auto-stop for selected inactive heavy services
4. Resource usage history storage and retrieval endpoints
5. Focused dashboard charts (CPU, memory, service activity timeline)

### Dependencies

- Phase E profiles and startup logic as control primitives.

### Success signals

- Lower idle resource cost for typical users.
- Better data-backed tuning discussions in community proposals.
- Clearer operational guidance for limited-resource contributors.

---

## 9) Cross-phase quality and security gates

Apply these gates to all phases:

1. Maintain secure-by-default and LAN-first assumptions.
2. Require explicit risk notes for network/security-affecting changes.
3. Keep proposal and docs pages synchronized with behavior changes.
4. Preserve backward-compatible defaults where possible.
5. Include rollback or disable paths for new automation behavior.
6. Keep GitHub as the proposal source of truth; publish read-only website views.
7. Require extension manifests and generated pages to pass repository-local checks.

---

## 10) Suggested implementation order

1. Phase A — canonical website Markdown and de-duplication
2. Phase B — finish ownership/label governance on the existing GitHub path
3. Phase C — live contracts, supply-chain checks, and local validation
4. Phase D — extension contract pilot and compatibility catalog
5. Phase E — profile and startup intelligence
6. Phase F — battery, idle, and history optimization

This order recognizes work that is already shipped, closes quality gaps, and then creates a safe extension path before adding more operational intelligence.
