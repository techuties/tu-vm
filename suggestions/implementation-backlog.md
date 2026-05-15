# Implementation Backlog for Community-Based Website Suggestions

This backlog translates suggestions into implementation-ready work items with clear acceptance criteria.

## Completed / superseded (repository today)

These directions are satisfied without a custom suggestions stack:

- **Proposals & governance**: GitHub Issues (**Idea / suggestion** + **Bug report** templates), Discussions link, issue chooser security entry, [`CONTRIBUTING.md`](../CONTRIBUTING.md) (labels, `Fixes #` / Release publish notes), PR template with security/RFC checklist.
- **Security reporting**: [`SECURITY.md`](../SECURITY.md) (private reporting path + fallback).
- **Release ↔ issue linkage**: [Release Drafter](../.github/release-drafter.yml) + [workflow](../.github/workflows/release-drafter.yml) on `main`; draft releases grouped by PR labels (`skip-changelog` supported).
- **Triage hygiene**: [Stale automation](../.github/workflows/stale.yml) (`needs-info` cadence + idle issues/PRs); documented labels (`stale`, `pinned`, etc.).
- **Contributor diagnostics**: `./tu-vm.sh doctor`, `check-config`, `smoke-test`, `helper-contract-check`; [`scripts/pre-push-check.sh`](../scripts/pre-push-check.sh).
- **CI**: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (`compose` render, `bash -n`, `check-config --ci`, smoke test, `/status/full` fixture validator; strict env gate on pull requests).
- **Docs & supply-chain hygiene (light)**: [docs link workflow](../.github/workflows/docs-links.yml), [Trivy config scan](../.github/workflows/trivy.yml) for `docker-compose.yml`, [Dependabot Actions](../.github/dependabot.yml).
- **CODEOWNERS template**: [`CODEOWNERS`](../CODEOWNERS) (replace placeholder team) + branch-protection notes in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
- **Pre-commit (optional)**: [`.pre-commit-config.yaml`](../.pre-commit-config.yaml).
- **Release note helper**: [`scripts/release-note-helper.sh`](../scripts/release-note-helper.sh) and `./tu-vm.sh release-notes`.
- **Starter playbooks**: [`docs/playbooks/README.md`](../docs/playbooks/README.md) with stable anchor IDs for dashboard deep-links.
- **Landing dashboard**: Community strip **and** operator hub (per-playbook shortcuts + “What is new” → Releases / CHANGELOG) in [`nginx/html/index.html`](../nginx/html/index.html).
- **`/status/full` contract**: canonical shape in [`fixtures/status-full-contract.json`](../fixtures/status-full-contract.json), checked by [`scripts/validate_status_full_contract.py`](../scripts/validate_status_full_contract.py).

---

## Priority model

- **P0**: High impact, low complexity, immediate quality gain
- **P1**: Core community workflows
- **P2**: Scale and polish

---

## P1-1: Dynamic “What is new” content (optional polish)

### Scope

Static links to [latest release](https://github.com/techuties/tu-vm/releases/latest) and [`CHANGELOG.md`](../CHANGELOG.md) are on the landing page. **Optional next step:** fetch the latest GitHub Release title/body or parse the top of `CHANGELOG.md` and show **three** short bullets without leaving the LAN dashboard (requires a same-origin proxy, build-time injection, or cached JSON — avoid leaking operator traffic to third parties).

### Acceptance criteria

- At least three human-readable highlights visible on the dashboard when data exists.
- Graceful fallback to today’s static links when API data is unavailable.

---

## P1-2: Static website/community framework selection

### Scope

Choose and scaffold one static website framework for community docs and suggestion pages. Historical suggestions mention Docusaurus, Astro/Starlight, VitePress, and MkDocs Material; the selection should be based on contributor workflow rather than novelty.

Recommended decision:

- **Docusaurus** if docs, proposal pages, versioning, and GitHub-style contributor flow are primary.
- **Astro/Starlight** if a broader content website with custom landing pages is primary.
- **VitePress/MkDocs Material** only if maintainer familiarity makes them clearly easier to sustain.

### Acceptance criteria

- Framework choice is documented in `suggestions/website-information-architecture.md`.
- Website source keeps Markdown as the main authoring format.
- Existing `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `docs/playbooks/`, and `suggestions/` content are linked or imported without copy/paste drift.
- Generated site can be served by existing Nginx without replacing the operational dashboard.
- Local preview command is documented for contributors.

---

## P1-3: Suggestion archive metadata and index

### Scope

Make the existing `suggestions/` archive navigable by status, area, and relationship to historical proposals.

### Acceptance criteria

- New or touched proposal files may include front matter fields: `status`, `area`, `related`, `supersedes`, `superseded_by`.
- A canonical index groups suggestions by active, accepted, implemented, deferred, rejected, duplicate, and superseded.
- Duplicate suggestions link to a canonical page instead of repeating the same framework or tooling recommendation.
- Historical files remain readable; cleanup is incremental and does not require rewriting every old suggestion at once.

---

## P1-4: Community triage and daily-workflow tooling

### Scope

Add small tools that make recurring maintainer work easier without introducing a custom community platform database.

### Acceptance criteria

- A docs/suggestion quality check reports broken links, missing headings, and missing proposal metadata for changed files.
- A triage report identifies stale accepted suggestions, duplicate candidates, and implemented items missing changelog references.
- Any tool has non-interactive usage, actionable errors, and predictable exit codes so contributors and CI can use it reliably.
- The tools integrate with existing script conventions and can be exposed through `tu-vm.sh` only when they become stable.

---

## P2-1: Frontend modularization

### Scope

Refactor monolithic `nginx/html/index.html` into maintainable assets:

- `assets/js/*`
- `assets/css/*`
- optional component abstraction

### Acceptance criteria

- Existing UX is behaviorally equivalent after refactor.
- Linting is active for extracted JS/CSS.
- Build/deploy path remains compatible with current Docker/Nginx setup.

---

## P2-2: Automated browser smoke tests

### Scope

Add Playwright checks for core flows.

### Acceptance criteria

- CI executes smoke tests on key website interactions.
- Failing tests block regressions on critical flows.
- Test docs describe local run procedure for community contributors.

---

## P2-3: Feature-flagged rollout strategy

### Scope

Roll out major dashboard or experimental UI behavior behind flags (example: optional panels, beta integrations).

### Acceptance criteria

- Flags can be toggled via config/env without code edits.
- Rollback path documented and tested.
- Observability includes basic visibility into flag-dependent code paths where relevant.

---

## Suggested implementation order

1. **P1-2** — select/scaffold the static website framework and define the contributor preview flow.
2. **P1-3** — add suggestion archive metadata and a generated/canonical index.
3. **P1-4** — add lightweight quality and triage tooling for community maintainers.
4. **Next high-value recommendations** — supply-chain depth, frontend modularization, browser smoke tests, richer dashboard content.
5. **P1-1** — only if operators want inline release bullets without clicking GitHub.
6. **P2-1**, **P2-2**, **P2-3**

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Trivy (or Grype) image CVE scans** — Iterate pinned Compose images with actionable severity thresholds (separate from today’s config-only scan).
2. **Incremental dashboard asset extraction** — Break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); introduce ESLint/stylelint on extracted files (**P2-1**).
3. **Playwright smoke tests** — Tier-1 flows against `tu.lan` or headless nginx fixture (**P2-2**).
4. **Compose profile for CI integration** — Minimal service set (or mocks) to curl `/status/full` against a live helper response shape, complementing the static fixture.
5. **Playbook version notes** — Short matrix in [`docs/playbooks/README.md`](../docs/playbooks/README.md): TU-VM major tag / compose behaviours that change commands.
6. **Tighten Trivy gate** — Switch from `exit-code: 0` to failing on HIGH/CRITICAL once noise is triaged.
7. **Markdown style lint** — markdownlint on `docs/` + root policy files with a narrow rule set.
8. **SBOM export (optional)** — CycloneDX/SPDX artifact on release for regulated operators.
9. **Feature-flag pattern for dashboard experiments** — Env-driven toggles before large UI changes (**P2-3**).
10. **n8n / AFFiNE maintainer workflows** — Lightweight triage reminders (behind Tier-2 services) per day-to-day-tooling docs, if the team adopts them.
