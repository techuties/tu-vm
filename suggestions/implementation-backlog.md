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

## P1-2: Static community docs website decision

### Scope

Select and document the static website framework used to publish the canonical suggestion bundle:

- VitePress for the lightweight docs-first path.
- Docusaurus if versioned docs and a larger plugin ecosystem are required.
- Astro with Starlight if the website grows into broader marketing/content pages.

The first implementation should publish the existing Markdown set rather than rewriting content:

- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`website-information-architecture.md`](./website-information-architecture.md)
- [`website-community-framework.md`](./website-community-framework.md)
- [`website-contributor-tooling.md`](./website-contributor-tooling.md)
- [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md)

### Acceptance criteria

- Framework choice is documented with the selection rule from [`website-information-architecture.md`](./website-information-architecture.md).
- Local preview command is documented for contributors.
- Suggestions index, history, governance, tooling, and roadmap pages are reachable from one website navigation section.
- Existing Markdown remains readable on GitHub without requiring the site build.
- Broken-link and heading checks cover the published pages.

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

1. **Next high-value recommendations** — supply-chain depth, frontend modularization, browser smoke tests, richer dashboard content.
2. **P1-1** — only if operators want inline release bullets without clicking GitHub.
3. **P1-2** — before migrating or rewriting website/community content.
4. **P2-1**, **P2-2**, **P2-3**

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Static community docs website decision** — choose VitePress/Docusaurus/Astro with Starlight and publish the canonical suggestion bundle (**P1-2**).
2. **Trivy (or Grype) image CVE scans** — iterate pinned Compose images with actionable severity thresholds (separate from today’s config-only scan).
3. **Incremental dashboard asset extraction** — break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); introduce ESLint/stylelint on extracted files (**P2-1**).
4. **Playwright smoke tests** — Tier-1 flows against `tu.lan` or headless nginx fixture (**P2-2**).
5. **Compose profile for CI integration** — minimal service set (or mocks) to curl `/status/full` against a live helper response shape, complementing the static fixture.
6. **Playbook version notes** — short matrix in [`docs/playbooks/README.md`](../docs/playbooks/README.md): TU-VM major tag / compose behaviours that change commands.
7. **Tighten Trivy gate** — switch from `exit-code: 0` to failing on HIGH/CRITICAL once noise is triaged.
8. **Markdown style lint** — markdownlint on `docs/` + root policy files with a narrow rule set.
9. **SBOM export (optional)** — CycloneDX/SPDX artifact on release for regulated operators.
10. **Feature-flag pattern for dashboard experiments** — env-driven toggles before large UI changes (**P2-3**).
