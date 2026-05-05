# Website Roadmap From Historical Suggestions

This roadmap converts recurring historical community-suggestion themes into a concrete implementation sequence for a community-based website and operations platform.

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

## 2) Phase A: Launch the community suggestions website baseline

## Goal

Create a reliable community information layer where proposals and decisions are discoverable, linked, and maintainable.

## Deliverables

1. Build a docs/site section with top-level navigation:
   - Home
   - Install
   - Operate
   - Security
   - Community
   - Suggestions
2. Add a suggestions index with:
   - historical baseline
   - active proposals
   - accepted/rejected items
3. Add standardized proposal page template:
   - problem, current state, proposal, implementation, risk, metrics, ownership

## Dependencies

- None beyond existing markdown docs and site shell.

## Success signals

- New contributor can find contribution and suggestion workflow in two clicks or fewer.
- Existing operator docs become searchable by task rather than only by long-form README scanning.

---

## 3) Phase B: Community framework and governance activation

## Goal

Make it easy for contributors to understand how work is owned, reviewed, and accepted.

## Deliverables

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
3. Lightweight proposal workflow for major changes
4. Pull request quality checklist and risk classification guidance

## Dependencies

- Phase A community docs section.

## Success signals

- Fewer duplicate issues.
- Faster routing of work to relevant reviewers.
- More PRs submitted with clear validation and rollback notes.

---

## 4) Phase C: Contributor tooling for day-to-day operations

## Goal

Reduce friction for development, testing, and release preparation.

## Deliverables

1. `doctor` diagnostics flow (entrypoint command and report output)
2. fast config validator script
3. standard smoke test script (core + optional full mode)
4. helper API contract checks for key endpoints
5. changelog/release-note helper flow

## Dependencies

- Phase B review expectations, so tooling aligns with accepted quality standards.

## Success signals

- More issues resolved in first reproduction cycle.
- Fewer runtime failures from missing or inconsistent configuration.
- Higher consistency in release documentation quality.

---

## 5) Phase D: Profile-driven operations and startup behavior

## Goal

Operationalize historical profile and startup suggestions into predictable behavior for users and contributors.

## Deliverables

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

## Dependencies

- Phase C tooling to validate behavior and reduce rollout regressions.

## Success signals

- Reduced startup resource spikes.
- Better user understanding of active services and profile state.

---

## 6) Phase E: Battery awareness, idle optimization, and usage history

## Goal

Deliver evidence-based optimization loops that are useful for a laptop/home-lab environment.

## Deliverables

1. Battery telemetry object in status surfaces
2. Battery-aware recommendations and optional profile automation
3. Configurable auto-stop for selected inactive heavy services
4. Resource usage history storage and retrieval endpoints
5. Focused dashboard charts (CPU, memory, service activity timeline)

## Dependencies

- Phase D profiles and startup logic as control primitives.

## Success signals

- Lower idle resource cost for typical users.
- Better data-backed tuning discussions in community proposals.
- Clearer operational guidance for limited-resource contributors.

---

## 7) Cross-phase quality and security gates

Apply these gates to all phases:

1. Maintain secure-by-default and LAN-first assumptions.
2. Require explicit risk notes for network/security-affecting changes.
3. Keep proposal and docs pages synchronized with behavior changes.
4. Preserve backward-compatible defaults where possible.
5. Include rollback or disable paths for new automation behavior.

---

## 8) Suggested implementation order

1. Phase A - website baseline
2. Phase B - governance activation
3. Phase C - contributor tooling
4. Phase D - profile and startup intelligence
5. Phase E - battery/idle/history optimization

This order minimizes reinvention by first establishing shared documentation and decision patterns, then incrementally adding operations intelligence.
