# Website Historical Baseline

## Purpose

This document captures historical suggestion patterns from prior `community-suggestions-*` branches and turns them into a single baseline for implementation.

It exists to prevent duplicate design work and to keep the new website/community framework aligned with what has already been proposed multiple times.

## Historical branches reviewed

- `origin/cursor/community-suggestions-documentation-f01e`
- `origin/cursor/community-suggestions-documentation-e8a5`
- `origin/cursor/community-suggestions-documentation-c719`
- `origin/cursor/community-suggestions-framework-6ed8`
- `origin/cursor/community-suggestions-framework-e483`
- `origin/cursor/community-suggestions-framework-d644`
- `origin/cursor/community-suggestions-framework-c211`
- Additional `community-suggestions-framework-*` and `community-suggestions-documentation-*` variants

## Repository history checked

The local git history for `suggestions/` shows repeated suggestion-system work, including:

- `Document community suggestion system`
- `docs: consolidate community website suggestions`
- `Add community website suggestions documentation set`
- `Add community suggestions hub and website framework docs`
- Multiple merges from `cursor/community-suggestions-framework-*`
- Multiple merges from `cursor/community-suggestions-documentation-*`

This means the project already has enough historical material to establish a website/community direction. New work should refine, deduplicate, and operationalize these documents instead of adding another parallel framework.

## Repeated themes across historical suggestions

### 1) Docs-first website structure
Almost every historical suggestion recommended a documentation-first website model with clear routes for:

- install and onboarding
- daily operations
- security and hardening
- contribution and governance
- archived and active suggestions

### 2) Community workflow formalization
Historical branches consistently suggested:

- lightweight contributor roles
- subsystem ownership
- issue/PR taxonomy
- a short RFC-style process for major changes

### 3) Day-to-day tooling for contributors
Frequently repeated tooling ideas:

- `doctor`-style diagnostics command
- pre-flight config checks
- smoke test scripts
- API contract checks for dashboard/helper endpoints
- changelog/release note helpers

### 4) Feature roadmap continuity
Most roadmap suggestions referenced existing project notes rather than introducing unrelated work, especially:

- quick profile switching
- battery-aware operations
- automatic stopping of idle heavy services
- resource history and visibility
- smart startup behavior

## Consolidated constructive suggestions

The useful common thread is a community website that explains, organizes, and measures work while leaving runtime control paths alone.

| Area | Reuse first | Add only where useful | Avoid |
|------|-------------|-----------------------|-------|
| Website framework | Markdown-first docs frameworks such as Docusaurus or Astro/Starlight | Suggestion indexes, roadmap pages, search, versioned docs | Hand-built routing, custom content parsers, or a dashboard rewrite |
| Suggestion intake | GitHub Issues, labels, templates, PR links, Discussions when enabled | Repository-backed suggestion pages generated from markdown/frontmatter | A separate voting database before GitHub-native flow is insufficient |
| Contributor tooling | Existing `tu-vm.sh`, `scripts/`, CI, pre-commit, Release Drafter, Dependabot | Small validation helpers for suggestion metadata and docs quality | Large custom bots with unclear ownership |
| Operations visibility | Existing Nginx landing page, helper status API, playbooks, changelog | Read-only community pages that link shipped ideas to releases | Public runtime-control endpoints or weakened allowlist/token requirements |
| Governance | Existing contributing guide, issue templates, PR checklist, CODEOWNERS placeholder | Lightweight ownership map and RFC-lite proposal template for major changes | Heavy process that slows safe fixes |

## Canonical suggestion flow

1. **Discover**: contributor checks this folder, open issues, changelog, and roadmap before proposing.
2. **Draft**: idea is written with problem, context, existing alternatives, proposed change, risk, rollback, and success criteria.
3. **Triage**: maintainers classify area, duplicate status, security/resource risk, and implementation size.
4. **Decision**: accepted, accepted-with-changes, deferred, or declined with rationale.
5. **Implementation**: linked issue/PR carries validation evidence and documentation updates.
6. **Close loop**: changelog/release entry links back to the original suggestion.

## What this means for current implementation

### Keep
- Existing operational center of gravity: `tu-vm.sh`
- Existing runtime surfaces: helper API + nginx landing/dashboard
- Existing docs assets: `README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`
- Existing GitHub-native community workflow: issue templates, PR template, labels, release drafter, stale workflow, Dependabot, docs-link checks

### Add
- A structured website information architecture
- Community governance and review framework
- Contributor tooling standards
- A phased roadmap tied to historical proposals already surfaced in changelog and prior branches
- Repository-backed suggestion metadata so future website pages can be generated consistently

### Avoid
- Replacing functioning systems wholesale
- Introducing governance bureaucracy that blocks practical contribution
- New defaults that weaken secure-by-default/LAN-first behavior
- Building bespoke community infrastructure before GitHub-native workflows and static docs are exhausted

## Baseline quality rules for all website suggestions

1. Every proposal must include implementation path and rollback notes.
2. Every proposal must identify security and resource impact.
3. Every proposal must reference existing components to be reused.
4. Every proposal must define measurable success signals.

## Cross-link

This baseline is operationalized in:

- `website-information-architecture.md`
- `website-community-framework.md`
- `website-contributor-tooling.md`
- `website-roadmap-from-historical-suggestions.md`
