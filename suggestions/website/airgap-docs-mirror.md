---
title: Air-Gapped Docs Mirror
description: Constructional contract for publishing an offline or LAN-only static documentation pack so community operators can use TU-VM docs without public CDN dependency.
last_updated: 2026-07-29
owner: maintainers
status: proposed
theme: docs
impact: medium
---

# Air-Gapped Docs Mirror

## Problem

TU-VM is LAN-first and often runs in privacy-sensitive or disconnected environments. Documentation today spans GitHub-rendered Markdown, root README surfaces, and (future) a static community site. Historical suggestions assume contributors can always reach `github.com` or third-party CDNs for fonts and docs. That fights the product posture and creates day-to-day friction for air-gapped operators.

We do not need a bespoke offline docs product—we need a **mirror/export contract** that reuses the eventual static site build and existing Markdown sources.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Root `README.md`, `QUICK_REFERENCE.md`, `docs/playbooks/` | Primary operator docs |
| `suggestions/website/` | Publishable community pages (this tree) |
| Stage 3 `docs-framework-adoption.md` (expected sibling) | Starlight/Docusaurus/MkDocs gates |
| Stage 6 website frontmatter CI | Schema for exportable pages |
| Nginx landing page | Already serves local HTML assets |
| MinIO (optional) | Internal artifact distribution on LAN |
| Lychee docs-links workflow | Link hygiene for connected CI |

Out of scope:

- Guaranteeing every upstream container image is air-gap mirrored (separate supply-chain concern)
- Shipping proprietary font CDNs into the LAN pack
- Building a full wiki engine on the helper API
- Dual-editing GitHub docs and an unrelated Confluence space

## Proposal

Define an **docs mirror pack** produced from the same Markdown that powers the community website.

### Pack outputs

| Artifact | Format | Consumer |
|---|---|---|
| `tu-vm-docs-<version>.tar.gz` | Static HTML + local assets | Air-gapped operator workstation |
| Optional MinIO object | Same tarball | LAN distribution via existing MinIO |
| Optional nginx alias | `/docs/` from extracted pack | Browse on `tu.lan` without GitHub |

### Build rules (reuse static site)

1. Prefer the adopted static docs framework (Stage 3) in **offline-friendly mode**: self-hosted assets, no required external font/CDN calls.
2. Until that framework lands, ship a **minimal pack**: Pandoc or `mdbook`/`mkdocs` one-shot build over `docs/playbooks/` + `suggestions/website/` + selected root docs—documented as interim.
3. Pin tool versions in the workflow that builds the pack.
4. Publish the tarball on GitHub Releases (connected build) and document how operators copy it inward (USB/MinIO).

### Content allowlist (v1)

- `docs/playbooks/**`
- `suggestions/website/**` (publishable community pages)
- `README.md`, `QUICK_REFERENCE.md`, `SECURITY.md`, `CONTRIBUTING.md`
- Exclude operator `.env`, backups, and large binary fixtures

### CI job shape

- Workflow `docs-mirror` on tags / manual dispatch (not every PR).
- Build → tar → upload Release asset or Actions artifact.
- Fail if the HTML references absolute `https://fonts.` / known CDN hosts (simple grep gate).

### Website placement

- Community → Reliability → Air-gapped docs mirror
- Install/Operate nav: “Using docs offline”

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Site generator | Chosen static framework offline mode | Custom PHP docs server |
| LAN serve | Existing Nginx | Second reverse-proxy stack |
| Distribution | Releases + MinIO | Mandatory always-online portal |
| Link checking | Connected CI Lychee | Requiring Lychee inside the air gap |

## Rollout

1. Land this contract page with allowlist and CDN banlist principles.
2. After Stage 3 docs-framework gates pass, implement the Release workflow.
3. Document copy-in procedures in playbooks (USB and MinIO paths).
4. Optionally add dashboard link to local `/docs/` when the pack is present.

## Acceptance criteria

- [ ] Pack allowlist and offline asset rules are documented.
- [ ] Build is tag/manual, not a PR-time burden.
- [ ] CDN/font externalization is treated as a build failure once automation exists.
- [ ] Operators have a documented path to browse docs without GitHub.

## Rollback

Stop publishing tarballs; GitHub Markdown remains available for connected users. Remove `/docs/` nginx alias if unused.

## Success metrics

- Air-gapped operators report successful install/operate using the pack.
- Community website pages are included without a second editable tree.
- Docs PRs do not need a full mirror rebuild on every push.
