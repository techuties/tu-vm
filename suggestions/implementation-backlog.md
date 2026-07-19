# Implementation Backlog for Community-Based Website Suggestions

This backlog translates suggestions into implementation-ready work items with clear acceptance criteria.

## Completed / superseded (repository today)

These directions are satisfied without a custom suggestions stack:

- **Proposals & governance**: GitHub Issues (**Idea / suggestion** + **Bug report** templates), optional Discussions contact link when the repository feature is enabled, issue chooser security entry, [`CONTRIBUTING.md`](../CONTRIBUTING.md) (labels, `Fixes #` / Release publish notes), PR template with security/RFC checklist.
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

## P1-2: Canonical Markdown publishing and de-duplication

### Scope

Turn the existing suggestion archive into a maintainable website source without creating a separate suggestions application:

- Declare the canonical reading path in [`README.md`](./README.md).
- Apply the metadata/lifecycle contract in [`website-community-pages.md`](./website-community-pages.md).
- Add a validator for IDs, lifecycle states, required evidence, and local links.
- Generate navigation and a read-only status board from canonical metadata.
- Treat GitHub Issues as the proposal/discussion source of truth.

### Acceptance criteria

- Changed canonical pages pass the same validation locally and in CI.
- Historical duplicates remain discoverable but cannot appear as separate active proposals.
- Accepted and later entries link to an issue; implemented/shipped entries link to delivery evidence.
- The website requires no new database, auth system, or write API.

---

## P1-3: Community extension pilot

### Scope

Implement the smallest useful slice of [`extensions-and-integration-framework.md`](./extensions-and-integration-framework.md):

- versioned `extension.yaml` schema,
- one template and one reference extension,
- validation for compatibility, capabilities, privileged settings, routes, ports, networks, and secrets declarations,
- `./tu-vm.sh extension list` plus a dry-run validation command,
- read-only website compatibility catalog generated from extension metadata.

Enable/disable automation should follow only after the validator and pilot package prove the contract.

### Acceptance criteria

- A contributor can scaffold and validate an extension without editing core service definitions.
- Invalid compatibility ranges, route/port conflicts, privileged mode, and undeclared external networks produce actionable failures.
- The catalog distinguishes core-supported and community-maintained integrations.
- Pilot removal leaves the Tier 1 stack unchanged.

---

## P1-4: Live helper contract in CI

### Scope

Complement the static `/status/full` fixture with a minimal live helper test:

- run the smallest Compose or direct Flask test environment,
- execute [`scripts/helper-contract-check.sh`](../scripts/helper-contract-check.sh),
- validate status, announcements, and updates response shapes,
- assert control routes reject unauthenticated requests,
- preserve the fixture validator as the fast static check.

### Acceptance criteria

- CI runs the live job when `helper/uploader.py`, its contract script/fixture, or relevant Compose wiring changes; the workflow documents those path rules.
- Response drift between code and fixture fails with a field-level message.
- The job does not require the complete Tier 1 stack or privileged host operations.

---

## P1-5: Documentation-to-runtime drift validator

### Scope

Add one repository-local check that catches semantic drift which a Markdown link checker cannot detect:

- derive the Compose service inventory from rendered `docker compose config`,
- derive public helper routes from the Flask application,
- compare documented service names, status routes, and supported `tu-vm.sh` commands in canonical pages and playbooks,
- keep a small reviewed allowlist for intentional display names and historical examples,
- emit file, line, unknown value, and nearest valid values in both human-readable and JSON output.

Use format-aware parsers or application introspection instead of maintaining a second handwritten service/route registry. The default check must be static: it must not start containers, call the network, or require production secrets.

### Rollout

1. Report the existing mismatch baseline without failing.
2. Correct or explicitly allow each baseline mismatch.
3. Enforce changed canonical docs, playbooks, Compose service keys, helper routes, and CLI help.
4. Expand scope only when false positives remain low and a maintainer owns the allowlist.

### Acceptance criteria

- A removed or renamed Compose service, helper status route, or documented CLI command produces an actionable local failure.
- The same command runs in pre-push checks and CI with deterministic output.
- Intentional aliases include a reason and canonical target; broad wildcard exclusions are rejected.
- Historical files remain searchable without forcing obsolete examples into the active contract.

---

## P2-1: Frontend modularization

### Scope

Refactor monolithic `nginx/html/index.html` into maintainable assets:

- `assets/js/*`
- `assets/css/*`
- a declarative service-card registry for labels, status endpoints, tier, controls, and visibility
- shared design tokens for contrast, focus, spacing, status text, and reduced motion
- optional component abstraction only after repeated rendering behavior is visible

### Acceptance criteria

- Existing UX is behaviorally equivalent after refactor.
- Linting is active for extracted JS/CSS.
- Build/deploy path remains compatible with current Docker/Nginx setup.
- Adding a standard service card requires one validated registry entry instead of copied markup and request logic.
- Registry validation rejects duplicate IDs, unknown status endpoints, invalid control capabilities, and missing accessible labels.
- Status is communicated with text as well as color, keyboard focus remains visible, and reduced-motion behavior is preserved.

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

1. **P1-2** — stop suggestion duplication before publishing more website pages.
2. **P1-4**, **P1-5**, and image security scanning — strengthen contributor feedback and operator trust.
3. **P1-3** — pilot the community extension path on validated foundations.
4. **P2-1** then **P2-2** — introduce the validated card registry while modularizing, then grow browser coverage.
5. **P1-1** and **P2-3** — optional polish and controlled experiments.

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

1. **Canonical suggestion publishing** — metadata validation, generated index, and GitHub evidence links (**P1-2**).
2. **Trivy (or Grype) image CVE scans** — iterate Compose images with actionable severity thresholds, separate from today’s config-only scan.
3. **Documentation-to-runtime drift checks** — validate documented services, helper routes, and CLI commands against implementation inventories (**P1-5**).
4. **Live helper contract test** — minimal runtime check for status and control boundaries (**P1-4**).
5. **Community extension pilot** — schema, validator, template, reference package, and compatibility catalog (**P1-3**).
6. **Declarative dashboard modularization** — extract CSS/JS, add design tokens, and validate a service-card registry (**P2-1**).
7. **Playwright and axe smoke tests** — critical Tier 1 interactions against a headless Nginx fixture (**P2-2**).
8. **Playbook version notes** — short TU-VM major-version/command-behavior matrix in [`docs/playbooks/README.md`](../docs/playbooks/README.md).
9. **Tighten image security gates and export an SBOM** — fail on triaged HIGH/CRITICAL findings; attach CycloneDX/SPDX output to releases.
10. **Markdown style lint** — use a narrow rule set for `docs/`, canonical suggestions, and root policy files.
