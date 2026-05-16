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

## P1-0: Canonical suggestion records for website publishing

### Scope

Normalize the current `suggestions/` folder into a website-ready source of truth:

- identify canonical suggestion files for website, governance, tooling, and roadmap topics,
- add consistent frontmatter or required sections for status, owner, area, risk, and updated date,
- document which historical files are duplicates, superseded, or merged,
- generate or maintain a simple index by status and area.

### Acceptance criteria

- A contributor can identify the current canonical suggestion for a topic without reading every historical file.
- New suggestion files are only added when no suitable canonical page exists.
- The website/docs framework can build a suggestions index without manual status copying.

---

## P1-1: Dedicated community docs website pilot

### Scope

Create a static website pilot that exposes existing Markdown without changing the runtime dashboard:

- pick Docusaurus or MkDocs Material using the selection rules in `website-and-docs-framework.md`,
- publish sections for Install, Operate, Security, Community, Suggestions, and Playbooks,
- link the site from `README.md` and the landing dashboard,
- keep generated output compatible with Nginx static hosting.

### Acceptance criteria

- Existing Markdown remains editable through normal pull requests.
- The suggestions index is browsable by status and area.
- No new Tier 1 service dependency is required.

---

## P1-2: Dynamic “What is new” content (optional polish)

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

1. **P1-0** — make the existing suggestions folder canonical and website-ready.
2. **P1-1** — pilot a static community/docs website from repository Markdown.
3. **Next high-value recommendations** — supply-chain depth, frontend modularization, browser smoke tests, richer dashboard content.
4. **P1-2** — only if operators want inline release bullets without clicking GitHub.
5. **P2-1**, **P2-2**, **P2-3**

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Canonical suggestion metadata** — Normalize active suggestion files with status, owner, area, risk, and duplicate/superseded links (**P1-0**).
2. **Static community docs website pilot** — Render repository Markdown and suggestions through Docusaurus or MkDocs Material (**P1-1**).
3. **Trivy (or Grype) image CVE scans** — Iterate pinned Compose images with actionable severity thresholds (separate from today’s config-only scan).
4. **Incremental dashboard asset extraction** — Break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); introduce ESLint/stylelint on extracted files (**P2-1**).
5. **Playwright smoke tests** — Tier-1 flows against `tu.lan` or headless nginx fixture (**P2-2**).
6. **Compose profile for CI integration** — Minimal service set (or mocks) to curl `/status/full` against a live helper response shape, complementing the static fixture.
7. **Playbook version notes** — Short matrix in [`docs/playbooks/README.md`](../docs/playbooks/README.md): TU-VM major tag / compose behaviours that change commands.
8. **Tighten Trivy gate** — Switch from `exit-code: 0` to failing on HIGH/CRITICAL once noise is triaged.
9. **Markdown style lint** — markdownlint on `docs/` + root policy files with a narrow rule set.
10. **Feature-flag pattern for dashboard experiments** — Env-driven toggles before large UI changes (**P2-3**).
