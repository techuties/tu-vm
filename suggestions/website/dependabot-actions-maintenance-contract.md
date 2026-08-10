---
title: Dependabot Actions Maintenance Contract
description: Constructional contract for community contributions that keep GitHub Actions dependencies current via Dependabot without inventing a custom dependency-bot platform or weakening supply-chain gates.
last_updated: 2026-08-10
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Dependabot Actions Maintenance Contract

## Problem

Stale Actions pins create security and breakage risk. Historical suggestions invent custom dependency scrapers, force unpinned `@master` actions, or ignore updates until something breaks in CI. The repository already has `.github/dependabot.yml` for the `github-actions` ecosystem. Contributors need a **reuse-first day-to-day contract** distinct from container image CVE scanning (Trivy) and from application package ecosystems not yet adopted.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`.github/dependabot.yml`](../../.github/dependabot.yml) | Weekly GitHub Actions update PRs |
| `.github/workflows/*.yml` | Consumers of Actions versions |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVE / SBOM gates |
| Stage 15 `docs-link-ci-contribution-contract.md` (expected sibling) | Lychee action version hygiene adjacency |
| Stage 16 `ci-workflow-contribution-contract.md` (sibling) | Primary CI workflow ownership |
| Stage 16 `github-community-automation-contract.md` (sibling) | Stale/triage Actions adjacency |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor/CI expectations |

Out of scope:

- Building a custom Dependabot replacement
- Floating `uses: org/action@main` as the default posture
- Auto-merging Actions bumps without CI signal
- Expanding Dependabot into unrelated package ecosystems without an accepted Issue and lockfile strategy

## Proposal

Publish a **Dependabot Actions maintenance contract** for dependency-automation PRs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Dependabot config | `dependabot.yml` | Ecosystem, directory, schedule justified |
| Actions pins | workflow `uses:` lines | Version tags/SHAs; release notes skimmed |
| CI confidence | green `ci.yml` (+ relevant workflows) | Bumps validated by existing gates |
| Docs | CONTRIBUTING / security notes | Mentions weekly Actions updates when useful |

### Rules

1. **Reuse Dependabot.** Do not replace with a custom scraper for Actions pins.
2. **Keep ecosystems intentional.** Today’s default is `github-actions`; new ecosystems need an Issue + ownership.
3. **Prefer tagged/SHA pins.** Avoid `@main` / `@master` for security-sensitive workflows.
4. **CI is the merge gate.** Dependabot PRs should pass primary workflows before merge.
5. **Separate image CVEs.** Container digest/CVE work stays on Stage 4 / safe-update lanes.
6. **No secret exposure.** Update PRs must not require embedding registry credentials in workflow files.
7. **GitHub remains intake.** “Switch to Renovate-only” or multi-bot meshes need an accepted Issue.

### Suggested maintainer checklist

```text
1. Open/review Dependabot PR for Actions bump
2. Skim upstream action changelog for breaking inputs
3. Confirm ci.yml / docs-links / stale / trivy still green as applicable
4. Merge with a clear commit/PR title (action name + version)
5. If an action repeatedly breaks, pin SHA and document why
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Actions updates | Dependabot `github-actions` | Custom version scrapers |
| Image CVEs | Stage 4 Trivy + Stage 15 safe-update | Treating Dependabot as image scanner |
| Workflow logic | Stage 16 CI contract | Silent workflow rewrites inside bump PRs |
| Triage bots | Stage 16 community automation | Extra bot accounts for the same job |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep Dependabot schedule modest (weekly) unless volume demands grouping.
3. Prefer **merging validated bumps** over accumulating stale Action pins.

## Acceptance criteria

- [ ] Dependabot reuse rule is stated.
- [ ] Intentional ecosystem expansion rule is stated.
- [ ] Pin posture (tag/SHA, no `@main` default) is stated.
- [ ] CI-before-merge expectation is stated.
- [ ] Separation from image CVE lanes is stated.

## Rollback

Revert `dependabot.yml` or workflow pins independently. Docs-only publication needs no runtime rollback.

## Success metrics

- Actions dependencies stay current with low drama.
- Fewer CI breaks from abandoned action major versions.
- Clear boundary between Actions bumps and container supply-chain work.
