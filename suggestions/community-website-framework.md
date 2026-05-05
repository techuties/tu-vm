# Community Website Framework Suggestions

## Objective
Build a community-first website that can evolve with contributor input, without rebuilding solved pieces from scratch.

## Guiding Principles
1. Reuse proven frameworks and hosted services before building custom systems.
2. Keep contribution workflows simple for non-core maintainers.
3. Treat docs, suggestions, and decisions as versioned content in Git.
4. Design for transparency: roadmap, governance, and status should be public by default.

## Recommended Foundation

### Primary Option: Docusaurus + GitHub Discussions
- **Why**: Fast setup, markdown-native, versioned docs, plugin ecosystem, and easy contribution model.
- **Community fit**:
  - Suggestion pages authored as markdown.
  - Auto-generated sidebars and search.
  - Built-in blog/changelog support.
  - Strong docs-focused UX with low maintenance overhead.

### Alternative Option: Next.js + Nextra
- **Why**: More flexible website/app hybrid if interactive community dashboards are needed.
- **Tradeoff**: More engineering effort and maintenance than Docusaurus.

### When to choose Astro/Starlight
- Prefer if strict static output and high performance are top priorities.
- Works well for content-heavy sites, but ecosystem for docs/community workflows is smaller than Docusaurus.

## Suggested Information Architecture
1. **Home**
   - Mission
   - Current priorities
   - Entry points for contributors
2. **Suggestions**
   - Community suggestions (open, accepted, archived)
   - Search and tags (security, UX, infrastructure, automation)
3. **Roadmap**
   - Now / Next / Later buckets
   - Link to issues/discussions for each item
4. **Docs**
   - Setup and operations
   - Architecture decisions
   - Contributor handbook
5. **Community**
   - Governance
   - Code of conduct
   - Communication channels

## Suggestion Lifecycle (Do Not Reinvent)
Use a lightweight RFC-style flow:

1. **Propose** (markdown template)
2. **Discuss** (GitHub Discussion thread)
3. **Review** (label + maintainer triage)
4. **Decide** (accepted/rejected/deferred with reason)
5. **Track delivery** (issue/PR links)
6. **Archive** (final result and lessons learned)

This can be implemented with GitHub labels, discussions, and action workflows instead of custom backend logic.

## Suggested Directory Structure
```text
suggestions/
  community-website-framework.md
  community-operations-tooling.md
  contributor-experience-tooling.md
```

If a full docs site is added later:
```text
website/
  docs/
    suggestions/
      accepted/
      proposed/
      archived/
  blog/
  src/
```

## Governance Pattern
- **Maintainers**: final decision authority on technical feasibility.
- **Contributors**: propose and refine ideas with templates.
- **Community reviewers**: vote/comment and provide usage evidence.
- **Decision cadence**: regular triage (for example weekly/bi-weekly sync), decisions logged in markdown.

## Success Metrics
Track basic, practical outcomes:
- Time from suggestion opened to first maintainer response
- Time from accepted suggestion to implementation start
- Number of accepted suggestions shipped per cycle
- Percentage of suggestions with documented decision rationale
- Contributor return rate (repeat contributors)

## Implementation Notes
- Start with markdown + GitHub Discussions + labels.
- Add automation only where manual steps become repetitive.
- Keep the process visible and predictable to reduce contributor friction.
