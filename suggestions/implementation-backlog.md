# Implementation Backlog for Community-Based Website Suggestions

This backlog translates historical and current suggestions into implementation-ready work items with clear acceptance criteria.

The backlog is intentionally trimmed: completed GitHub-native and repository-native work remains documented for context, while new recommendations focus on the next useful community-system and website increments.

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

## P1-1: Suggestion metadata and structure validator

### Scope

Add a lightweight validation script for Markdown files in `suggestions/`.

The script should check:

- allowed status values,
- required frontmatter fields for active suggestions,
- required body sections,
- local link validity,
- related-history references for new active proposals.

### Acceptance criteria

- Validator can run locally without starting Docker services.
- Output is readable by humans and has an optional JSON mode.
- CI can run the strict, deterministic checks.
- Subjective findings are warnings, not failures.

---

## P1-2: Duplicate and historical-overlap report

### Scope

Add a deterministic report that compares new or changed suggestion files against existing `suggestions/` content.

Start with:

- title and heading extraction,
- keyword normalization,
- overlap scoring,
- top related files output.

### Acceptance criteria

- Report lists likely related suggestions with file paths.
- Contributors can use the output before creating new Markdown files.
- False positives are acceptable as advisory hints.
- No external service is required.

---

## P1-3: Generated suggestion index

### Scope

Generate a machine-readable index from suggestion metadata.

Suggested fields:

- title,
- status,
- area,
- owner,
- last reviewed date,
- source file,
- related files.

### Acceptance criteria

- Index generation is deterministic.
- Website/docs framework can consume the output.
- Generated data can group suggestions by status and area.
- Invalid metadata is caught by the validator before index generation.

---

## P1-4: Website framework skeleton

### Scope

Adopt one Markdown-first website framework using the guidance in [`website-and-docs-framework.md`](./website-and-docs-framework.md).

Initial sections:

- Home,
- Install,
- Operate,
- Security,
- Community,
- Suggestions,
- Release Notes.

### Acceptance criteria

- Existing root docs and playbooks are linked or imported without losing canonical source references.
- Suggestions index is visible from the website.
- Build command is documented.
- Broken local links fail the docs quality check.

---

## P1-5: Dynamic "What is new" content (optional polish)

### Scope

Static links to [latest release](https://github.com/techuties/tu-vm/releases/latest) and [`CHANGELOG.md`](../CHANGELOG.md) are on the landing page. **Optional next step:** fetch the latest GitHub Release title/body or parse the top of `CHANGELOG.md` and show **three** short bullets without leaving the LAN dashboard (requires a same-origin proxy, build-time injection, or cached JSON — avoid leaking operator traffic to third parties).

### Acceptance criteria

- At least three human-readable highlights visible on the dashboard when data exists.
- Graceful fallback to today’s static links when API data is unavailable.

---

## P2-1: Read-only community dashboard summary

### Scope

Add a small landing dashboard section that reads generated suggestion status data and links to website pages.

Suggested widgets:

- active suggestions by status,
- recently accepted suggestions,
- implemented suggestions in latest release,
- suggestions missing owner/review date.

### Acceptance criteria

- Widget is read-only and visually separate from service controls.
- Dashboard gracefully hides or degrades if suggestion data is unavailable.
- No third-party calls are made from the LAN dashboard.

---

## P2-2: Frontend modularization

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

## P2-3: Automated browser smoke tests

### Scope

Add Playwright checks for core flows.

### Acceptance criteria

- CI executes smoke tests on key website interactions.
- Failing tests block regressions on critical flows.
- Test docs describe local run procedure for community contributors.

---

## P2-4: Feature-flagged rollout strategy

### Scope

Roll out major dashboard or experimental UI behavior behind flags (example: optional panels, beta integrations).

### Acceptance criteria

- Flags can be toggled via config/env without code edits.
- Rollback path documented and tested.
- Observability includes basic visibility into flag-dependent code paths where relevant.

---

## Suggested implementation order

1. **P1-1**: suggestion metadata and structure validator.
2. **P1-2**: duplicate and historical-overlap report.
3. **P1-3**: generated suggestion index.
4. **P1-4**: website framework skeleton.
5. **P1-5**: dynamic "What is new" content, if operators want inline release highlights.
6. **P2-1** through **P2-4** as scale and polish items.

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Suggestion validator** - Validate metadata, required sections, local links, and allowed statuses (**P1-1**).
2. **Duplicate/historical-overlap report** - Warn when a new suggestion resembles existing files (**P1-2**).
3. **Generated suggestion index** - Produce JSON and website-friendly grouped indexes (**P1-3**).
4. **Markdown style lint** - Add markdownlint or equivalent on `docs/`, root policy files, and canonical suggestion pages.
5. **Website framework skeleton** - Adopt Docusaurus, MkDocs Material, or Astro Starlight for the community docs site (**P1-4**).
6. **Read-only dashboard community summary** - Surface suggestion counts and links after generated data is stable (**P2-1**).
7. **Trivy (or Grype) image CVE scans** - Iterate pinned Compose images with actionable severity thresholds.
8. **Incremental dashboard asset extraction** - Break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); introduce linting on extracted files (**P2-2**).
9. **Playwright smoke tests** - Tier-1 flows against `tu.lan` or a headless nginx fixture (**P2-3**).
10. **Feature-flag pattern for dashboard experiments** - Env-driven toggles before large UI changes (**P2-4**).
