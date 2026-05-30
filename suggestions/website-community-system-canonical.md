# Website Community System: Canonical Suggestions

## Purpose

This document is the canonical synthesis for website and community-system suggestions. It builds on the historical `suggestions/` folder instead of reauthoring the same ideas again.

Use this page first when planning website, governance, contributor tooling, or day-to-day workflow improvements. Then open the linked detailed files only when implementation needs more depth.

## Historical work to reuse

| Topic | Reuse first | Why it matters |
|---|---|---|
| Historical baseline | `website-historical-baseline.md` | Summarizes repeated ideas from prior `community-suggestions-*` branches. |
| Website structure | `website-information-architecture.md` | Defines the docs/community website navigation and content model. |
| Community governance | `website-community-framework.md` | Covers roles, decision lanes, ownership, and review standards. |
| Contributor tooling | `website-contributor-tooling.md` | Lists practical checks and tools for daily contribution work. |
| Roadmap | `website-roadmap-from-historical-suggestions.md` | Sequences prior feature ideas into implementation phases. |
| Current backlog | `implementation-backlog.md` | Separates shipped items from open recommendations. |
| Project patterns | `historical-patterns-from-project.md` | Keeps proposals aligned with TU-VM's actual architecture. |
| Integration model | `extensions-and-integration-framework.md` | Covers the distinct extension/plugin direction. |

## Framework recommendation

### Default today: repository-native markdown plus the existing landing page

The project already has a working public documentation surface:

- `README.md` for the complete technical narrative
- `QUICK_REFERENCE.md` for operator commands
- `CONTRIBUTING.md` for contribution and release workflow
- `docs/playbooks/` for operator recipes
- `nginx/html/index.html` for the dashboard and website entry point
- `helper/uploader.py` for status/control data surfaced to the website

Keep this as the default until the community needs versioned docs, full-text search, or a larger contributor documentation tree.

### Static docs framework when scale requires it

If the project outgrows repository-native markdown, use this decision rule:

| Framework | Choose when | Avoid when |
|---|---|---|
| Docusaurus | Documentation, versioning, search, sidebars, and proposal pages are the center of gravity. | The site needs highly custom marketing layouts before docs scale. |
| Astro + Starlight | The site must combine docs, community pages, release content, and richer landing pages. | The main need is a conventional docs portal with minimal customization. |
| VitePress | The team wants a very small Vue-friendly docs site. | Governance, roadmap, and versioned docs need a larger ecosystem. |
| MkDocs Material | Python-oriented docs workflows are preferred. | The community wants a broader JavaScript/static-site ecosystem. |

Do not build a custom CMS or bespoke suggestion tracker before GitHub Issues, markdown, generated indexes, and the existing dashboard have been exhausted.

## Canonical website sections

The website should expose these sections in one consistent navigation model:

1. **Home**
   - What TU-VM is
   - Quick install and operator entry points
   - Links to latest release and changelog
2. **Install**
   - Requirements
   - First-run checklist
   - Secure defaults
3. **Operate**
   - Service tiers
   - Daily controls
   - Playbooks and troubleshooting
4. **Security**
   - Access modes
   - Control-token and allowlist guidance
   - Vulnerability reporting
5. **Community**
   - Contribution workflow
   - Maintainer/reviewer expectations
   - Recognition and review cadence
6. **Suggestions**
   - Historical baseline
   - Active proposals
   - Accepted, superseded, rejected, and released decisions
   - Roadmap connection back to changelog entries

## Suggestion lifecycle

Use one lifecycle across GitHub Issues, markdown files, and website displays:

| Status | Meaning | Required next action |
|---|---|---|
| `draft` | Idea is captured but not ready for decision. | Clarify problem, scope, and reuse path. |
| `review` | Maintainers/community are evaluating fit. | Confirm risks, owner, and acceptance criteria. |
| `accepted` | Direction is approved. | Link implementation issue or PR. |
| `superseded` | Merged into a newer or broader proposal. | Link the replacement suggestion. |
| `rejected` | Decision is no. | Record rationale and revisit conditions. |
| `released` | Shipped and documented. | Link changelog or release notes. |

## Suggestion markdown contract

Future suggestion files should use a consistent structure so tooling can index them.

Recommended frontmatter:

```yaml
---
title: Short descriptive title
status: draft
area: website|community|tooling|security|operations|integration
priority: P0|P1|P2
related:
  - website-historical-baseline.md
  - implementation-backlog.md
---
```

Required sections:

1. **Problem**
   - What pain or opportunity is being addressed?
2. **Current state**
   - Which existing docs, scripts, services, or decisions already cover part of this?
3. **Suggestion**
   - What should change?
4. **Reuse plan**
   - Which existing TU-VM surfaces are reused first?
5. **Implementation path**
   - Concrete steps, preferably small and reversible.
6. **Risks and mitigations**
   - Security, operations, maintenance, and contributor-experience risks.
7. **Acceptance criteria**
   - Observable checks that prove the suggestion is complete.
8. **Related suggestions**
   - Links to historical or overlapping files so contributors do not duplicate work.

## Day-to-day tools that ease community work

Implement these as thin repository tools before introducing a larger platform:

1. **Suggestion index generator**
   - Reads frontmatter from `suggestions/*.md`.
   - Produces a static JSON index for the website.
   - Groups by status, area, priority, and related files.
2. **Duplicate hint report**
   - Compares new suggestion titles and related keywords against existing files.
   - Prints the top related suggestions during local checks or CI.
   - Marks low-confidence matches as hints, not failures.
3. **Markdown quality gate**
   - Checks heading hierarchy, internal links, and required sections.
   - Starts with warnings for legacy files and stricter checks for new files.
4. **Dashboard community widget**
   - Shows counts by lifecycle status.
   - Links to the suggestion index and contribution guide.
   - Uses generated static data first; helper API support can come later.
5. **Release linkage helper**
   - Encourages PRs and changelog entries to reference accepted suggestion IDs.
   - Lets community members trace idea -> decision -> implementation -> release.
6. **Optional semantic search**
   - Consider Qdrant-backed similarity only after simple title/tag matching is insufficient.

## Governance model

Use lightweight decision lanes:

- **Fast lane**: docs corrections, small UI copy, minor scripts, tests, and low-risk playbook updates.
- **Proposal lane**: new services, new framework dependencies, network/security changes, dashboard architecture changes, or any control-path behavior change.

Every proposal-lane item should include:

- security impact
- resource impact
- rollback path
- validation plan
- documentation impact

## Implementation sequence

### Phase 1: Canonicalize

- Treat this file and `README.md` in `suggestions/` as the entry point.
- Add frontmatter to new suggestion files.
- Keep older historical files as source material instead of deleting them.
- Add "related suggestions" links whenever a new file overlaps prior work.

### Phase 2: Publish on the website

- Generate a suggestions index from markdown metadata.
- Add a website page or dashboard section that links to active suggestions.
- Surface current backlog items from `implementation-backlog.md`.
- Keep the existing Nginx landing page as the first publishing target.

### Phase 3: Automate quality

- Add markdown and link checks for new suggestion files.
- Add duplicate hints based on titles, areas, and related files.
- Fail CI only on objective problems such as broken links or invalid frontmatter.

### Phase 4: Scale community operations

- Add contribution summaries to release notes.
- Publish periodic roadmap and retrospective summaries.
- Consider n8n or AFFiNE workflows only if GitHub-native review becomes a bottleneck.

## Success criteria

This community website system is working when:

- Contributors can find the active suggestion path in two clicks or fewer.
- New suggestions consistently link to related historical files.
- Maintainers can tell which ideas are draft, accepted, superseded, rejected, or released.
- The dashboard or website shows community status without manual page rewrites.
- Released work links back to the originating suggestion or issue.
- The project gains framework benefits without replacing working TU-VM surfaces.

## Guardrails

- Preserve secure-by-default and LAN-first behavior.
- Prefer GitHub Issues, markdown, generated JSON, and the existing dashboard before adding services.
- Avoid custom governance software unless community volume proves it is necessary.
- Do not require heavyweight tooling for small documentation or operational fixes.
- Keep proposal history even when ideas are superseded; link forward instead of erasing context.
