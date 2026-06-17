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

TU-VM should use a mature static documentation framework and keep content in Markdown. The important decision is not "which framework is fashionable"; it is which framework gives contributors navigation, search, and reviewable pages without turning the project into a custom web application.

### Option A (primary): VitePress

Best when the first goal is a lightweight docs/community website:

- Markdown-native authoring with simple front matter.
- Fast static output that can be served by the existing Nginx model.
- Low operational complexity and a small contributor learning curve.
- Enough theming/navigation for install, operations, security, community, and suggestion pages.

### Option B: Docusaurus

Best when the project needs heavier docs platform features:

- Mature versioned docs.
- Rich plugin ecosystem.
- Strong sidebar, search, blog, and announcement patterns.
- Familiar contribution model for larger open-source communities.

### Option C: Astro with Starlight

Best when the website must combine docs with broader marketing or custom content sections:

- Fast static output.
- Excellent content collections.
- Flexible page composition beyond docs.
- Good fit if a public-facing landing site grows beyond the operator dashboard.

### Selection rule

| Need | Recommended choice |
| --- | --- |
| Simple docs/community site served statically | VitePress |
| Versioned docs, large plugin ecosystem, release docs at scale | Docusaurus |
| Rich marketing/content site plus docs | Astro with Starlight |
| Dashboard controls and live service state | Keep using `nginx/html/index.html` plus helper API |

Do not rebuild sidebar navigation, search, table-of-contents behavior, or docs routing by hand unless a framework gap is proven.

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

## Suggested docs taxonomy

- `docs/getting-started/*`
- `docs/operations/*`
- `docs/security/*`
- `docs/community/*`
- `docs/suggestions/*`
- `docs/architecture/*`

Each suggestion document should be linked from a single index page so users can browse proposal history consistently.

## Website-ready community page set

The first website pass should publish a small, focused set of pages sourced from repository Markdown:

| Page | Purpose | Source candidate |
| --- | --- | --- |
| `/community/` | Explain how the community works and where to participate. | `CONTRIBUTING.md` plus `website-community-framework.md` |
| `/community/suggestions/` | Index active, accepted, implemented, deferred, and superseded suggestions. | `suggestions/README.md` and `implementation-backlog.md` |
| `/community/suggestions/history/` | Show historical themes so contributors avoid duplicates. | `website-historical-baseline.md` |
| `/community/tools/` | Explain local checks, release-note helper, and maintainer tools. | `website-contributor-tooling.md` |
| `/roadmap/` | Present phased delivery from historical suggestions. | `website-roadmap-from-historical-suggestions.md` |

Keep the initial page set small. Add more pages only when an existing page becomes too broad to review safely.

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

1. Choose the static docs framework using the selection rule above.
2. Introduce the docs framework in a dedicated website/docs folder.
3. Import and normalize existing core docs with minimal rewriting.
4. Add a dedicated suggestions section sourced from this folder.
5. Add cross-links from the existing landing page and docs root.
6. Add documentation quality checks for broken links, heading structure, and required suggestion sections.
7. Keep the runtime dashboard controls in the existing Nginx/helper API flow unless a separate proposal justifies moving them.

## Success criteria

- New contributors can locate contribution workflow in two clicks or fewer.
- Operators can solve routine tasks without scanning the full README.
- Suggestions are discoverable and trackable from proposal to decision.
- Website content remains maintainable by distributed community contributors.
