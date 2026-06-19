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

## P1-1: Docusaurus docs website skeleton

### Scope

Create a static documentation website that renders the community/suggestion pages without replacing the existing Nginx landing dashboard.

Recommended initial navigation:

- Getting Started
- Suggestions
- Operations
- Community
- Reference

### Acceptance criteria

- Static build consumes Markdown from existing docs and `suggestions/` without duplicating content.
- Website navigation links to `README.md`, `CONTRIBUTING.md`, `docs/playbooks/`, `CHANGELOG.md`, and canonical suggestion pages.
- Generated site is deployable as static assets without adding a runtime service.
- Accessibility basics are documented: keyboard navigation, visible focus states, text labels for statuses, and meaningful link text.
- Rollback is simple: remove the generated static site link and keep the current dashboard links.

---

## P1-2: Suggestion metadata and index generator

### Scope

Define frontmatter for canonical suggestion pages and generate JSON/Markdown indexes by status and area.

Suggested fields:

- `title`
- `summary`
- `status`
- `area`
- `source_issue`
- `owner`
- `reviewers`
- `updated`

### Acceptance criteria

- Generator reports missing or invalid metadata for canonical proposal pages.
- Index output groups suggestions by status and area.
- Duplicate hints compare at least titles and summary keywords against existing suggestions.
- Generated output is deterministic so CI diffs are reviewable.
- Existing historical files can remain unfrontmattered until promoted.

---

## P1-3: Community status surface

### Scope

Expose a lightweight community status view on the website first, then optionally add a compact read-only widget to the existing landing dashboard.

Suggested metrics:

- Suggestions by status.
- Suggestions by area.
- Recently accepted or implemented proposals.
- Drafts needing maintainer review.

### Acceptance criteria

- Source data comes from generated Markdown metadata or GitHub issue labels, not a new custom tracker.
- No service control endpoint or credential path is touched.
- Dashboard widget, if added, is read-only and has graceful fallback when data is missing.
- Status labels are text-visible and accessible without relying on color alone.

---

## P1-4: Dynamic “What is new” content (optional polish)

### Scope

Static links to [latest release](https://github.com/techuties/tu-vm/releases/latest) and [`CHANGELOG.md`](../CHANGELOG.md) are on the landing page. **Optional next step:** fetch the latest GitHub Release title/body or parse the top of `CHANGELOG.md` and show **three** short bullets without leaving the LAN dashboard (requires a same-origin proxy, build-time injection, or cached JSON — avoid leaking operator traffic to third parties).

### Acceptance criteria

- At least three human-readable highlights visible on the dashboard when data exists.
- Graceful fallback to today’s static links when API data is unavailable.

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

1. **P1-1** — Docusaurus docs website skeleton, because it creates the website surface without runtime risk.
2. **P1-2** — suggestion metadata and generated indexes, because it prevents duplicated manual lists.
3. **P1-3** — community status surface, starting on the website before dashboard integration.
4. **Next high-value recommendations** — supply-chain depth, frontend modularization, browser smoke tests, richer dashboard content.
5. **P1-4** — only if operators want inline release bullets without clicking GitHub.
6. **P2-1**, **P2-2**, **P2-3**

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Docusaurus website skeleton** — Static community/docs site generated from existing Markdown (**P1-1**).
2. **Suggestion metadata/index generator** — Frontmatter validation, status indexes, and duplicate hints (**P1-2**).
3. **Community status surface** — Website-first proposal counts and recent decisions; dashboard widget only after generated data is reliable (**P1-3**).
4. **Trivy (or Grype) image CVE scans** — Iterate pinned Compose images with actionable severity thresholds (separate from today’s config-only scan).
5. **Incremental dashboard asset extraction** — Break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); introduce ESLint/stylelint on extracted files (**P2-1**).
6. **Playwright smoke tests** — Tier-1 flows against `tu.lan` or headless nginx fixture (**P2-2**).
7. **Compose profile for CI integration** — Minimal service set (or mocks) to curl `/status/full` against a live helper response shape, complementing the static fixture.
8. **Markdown style lint** — markdownlint on `docs/`, `suggestions/`, and root policy files with a narrow rule set.
9. **Feature-flag pattern for dashboard experiments** — Env-driven toggles before large UI changes (**P2-3**).
10. **n8n / AFFiNE maintainer workflows** — Lightweight triage reminders and decision-log support (behind Tier-2 services) per day-to-day-tooling docs, if the team adopts them.
