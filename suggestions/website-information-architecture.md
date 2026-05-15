# Website Information Architecture Suggestion

## Objective

Build a clear, community-first website and documentation structure that helps:

- New users install and run the platform quickly
- Operators complete common day-to-day tasks reliably
- Contributors discover where and how to contribute
- Community members submit and track constructive suggestions

This should extend current project assets, not replace functional components.

## Existing project assets to reuse

The repository already contains working building blocks:

- `README.md` for complete technical narrative
- `QUICK_REFERENCE.md` for command-level guidance
- `CHANGELOG.md` for release history and future direction
- `nginx/html/index.html` as the existing web surface
- `helper/uploader.py` for status/control/announcement endpoints
- `tu-vm.sh` as the canonical operations interface

Recommendation: preserve this architecture and layer a docs/community website framework around it.

## Recommended website framework options

Historical suggestion files propose Docusaurus, Astro/Starlight, VitePress, and MkDocs Material. They are all better than a custom documentation engine. The project should choose the smallest framework that satisfies the community workflow rather than creating bespoke navigation, search, or versioning.

### Option A (primary): Docusaurus

Best when the priority is docs quality, versioning, search, and community contribution flow:

- Markdown-native authoring
- Versioned docs and sidebars
- Strong plugin ecosystem
- Low barrier for contributor pull requests
- Native fit for proposal/RFC pages, docs sidebars, and "edit this page" links

### Option B (secondary): Astro with Starlight

Best when broader marketing/content composition is expected:

- Fast and modern static site output
- Strong markdown pipeline
- Flexible custom page composition
- Cleaner path if the project wants landing pages, showcases, or component-rich community pages

### Option C (lightweight fallback): VitePress or MkDocs Material

Use one of these only if the team wants a smaller docs-only toolchain:

- **VitePress** if the contributor base prefers a lightweight JavaScript/Vite stack.
- **MkDocs Material** if the contributor base prefers Python tooling and mature docs search/navigation.

### Selection rule

- Choose Docusaurus if docs, contribution guides, and proposal pages are the center of gravity.
- Choose Astro if a richer multi-purpose website is the top requirement.
- Choose VitePress/MkDocs only when their ecosystem and maintainer familiarity are a better local fit.
- Avoid building custom docs routing, search, sidebar generation, or proposal indexing unless the chosen framework cannot support a requirement.

## Markdown source-of-truth model

Keep source content simple and reviewable:

| Content type | Source location | Website behavior |
|--------------|-----------------|------------------|
| Install and operations docs | `README.md`, `QUICK_REFERENCE.md`, `docs/playbooks/` | Imported or linked as task-oriented docs pages |
| Community workflow | `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/` | Published as contributor guide pages |
| Historical suggestions | `suggestions/*.md` | Indexed as proposal archive with status metadata |
| Release history | `CHANGELOG.md`, GitHub Releases | Shown as release notes / "what changed" pages |
| Security policy | `SECURITY.md` | Published as security and disclosure guidance |

For future proposal pages, add small front matter where useful:

```yaml
---
status: proposed
area: website
related:
  - suggestions/website-community-framework.md
  - suggestions/implementation-backlog.md
---
```

This makes the eventual website indexable without making contributors learn a database or custom CMS.

## Proposed navigation model

1. **Home**
   - Project overview
   - Why this platform exists
   - "Get started fast" links

2. **Install**
   - Prerequisites
   - Setup flow
   - First-run secure configuration checklist

3. **Operate**
   - Service control patterns
   - Monitoring and health checks
   - Backup/restore and troubleshooting playbooks

4. **Security**
   - Access modes (secure/public/locked)
   - Control token and allowlist handling
   - Production hardening and threat boundaries

5. **Community**
   - How to contribute
   - Role model and review expectations
   - Contribution standards and quality checks

6. **Suggestions**
   - Historical suggestions baseline
   - Active proposals
   - Accepted/rejected decisions and rationale
   - Duplicate/superseded links so repeated ideas point to canonical proposals

## Suggested docs taxonomy

- `docs/getting-started/*`
- `docs/operations/*`
- `docs/security/*`
- `docs/community/*`
- `docs/suggestions/*`
- `docs/architecture/*`

Each suggestion document should be linked from a single index page so users can browse proposal history consistently.

## Suggested page template for proposal-style content

Use this repeatable structure to keep suggestion quality high:

1. Problem statement
2. Current state
3. Proposed change
4. Implementation steps
5. Risk and mitigation notes
6. Success metrics
7. Ownership and review path

## Accessibility and UX standards

Apply these standards for all website pages and interactive controls:

- Ensure keyboard navigation and visible focus states
- Use high-contrast colors and avoid color-only status communication
- Add ARIA labels for controls and status elements
- Keep mobile responsiveness as a default requirement
- Avoid dense page layouts that reduce readability

## Implementation approach

1. Introduce docs framework in a dedicated website/docs folder.
2. Import and normalize existing core docs with minimal rewriting.
3. Add a dedicated suggestions section sourced from this folder.
4. Add cross-links from existing landing page and docs root.
5. Add documentation quality checks (broken links, heading structure).
6. Add an "edit this page" link and issue-template link to every community-facing page.
7. Publish a generated suggestion index grouped by status, area, and superseded-by relation.

## Success criteria

- New contributors can locate contribution workflow in two clicks or fewer.
- Operators can solve routine tasks without scanning the full README.
- Suggestions are discoverable and trackable from proposal to decision.
- Website content remains maintainable by distributed community contributors.
