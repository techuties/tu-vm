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
3. **P2-1**, **P2-2**, **P2-3**

---

## Next high-value recommendations (10)

_Shipped from the prior round: playbook shortcuts + operator hub, static “What is new” links, pre-commit config, Dependabot, CODEOWNERS template, docs-links + Trivy config workflows, release-note-helper, `/status/full` fixture validator._

_Stage 4 website drafts (docs only): [`website/mcp-catalog-ci-contract.md`](./website/mcp-catalog-ci-contract.md), [`website/operator-profile-cli.md`](./website/operator-profile-cli.md), [`website/extension-pilot-scaffold.md`](./website/extension-pilot-scaffold.md), [`website/supply-chain-community-gates.md`](./website/supply-chain-community-gates.md), [`website/dashboard-modularization-smoke.md`](./website/dashboard-modularization-smoke.md), [`website/stage-merge-playbook.md`](./website/stage-merge-playbook.md)._

1. **MCP catalog YAML + CI** — Implement [`website/mcp-catalog-ci-contract.md`](./website/mcp-catalog-ci-contract.md) after Stage 1 catalog guidance merges.
2. **Trivy (or Grype) image CVE scans** — Follow [`website/supply-chain-community-gates.md`](./website/supply-chain-community-gates.md); iterate pinned Compose images with severity thresholds.
3. **Operator profile CLI** — `./tu-vm.sh profile list|show|apply --plan` per [`website/operator-profile-cli.md`](./website/operator-profile-cli.md) after Stage 2 profiles stabilize.
4. **Extension pilot scaffold** — Land `extensions/<id>/` + `validate-extension.sh` per [`website/extension-pilot-scaffold.md`](./website/extension-pilot-scaffold.md).
5. **Incremental dashboard asset extraction** — Break out CSS/JS from [`nginx/html/index.html`](../nginx/html/index.html); see [`website/dashboard-modularization-smoke.md`](./website/dashboard-modularization-smoke.md) (**P2-1**).
6. **Playwright smoke tests** — Tier-1 flows against fixture or `tu.lan` (**P2-2**, same Stage 4 page).
7. **Tighten Trivy gate** — Fail on CRITICAL/HIGH once Phase A noise is triaged (supply-chain page Phase B).
8. **Reconcile Stage 1–4 `suggestions/website/` hubs** — Follow [`website/stage-merge-playbook.md`](./website/stage-merge-playbook.md).
9. **Optional Issue-form `class_id`** — After Stage 2 matrix + Stage 3 hardware-class intake merge.
10. **SBOM export (optional)** — CycloneDX/SPDX on Release per supply-chain Phase C.
