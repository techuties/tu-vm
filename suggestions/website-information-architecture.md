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

### Option A (primary): Docusaurus

Best when the priority is docs quality, versioning, search, and community contribution flow:

- Markdown-native authoring
- Versioned docs and sidebars
- Strong plugin ecosystem
- Low barrier for contributor pull requests

### Option B (secondary): Astro with Starlight

Best when broader marketing/content composition is expected:

- Fast and modern static site output
- Strong markdown pipeline
- Flexible custom page composition

### Selection rule

- Choose Docusaurus if docs, contribution guides, and proposal pages are the center of gravity.
- Choose Astro if a richer multi-purpose website is the top requirement.

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

## Success criteria

- New contributors can locate contribution workflow in two clicks or fewer.
- Operators can solve routine tasks without scanning the full README.
- Suggestions are discoverable and trackable from proposal to decision.
- Website content remains maintainable by distributed community contributors.
