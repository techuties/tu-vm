# Website Suggestion: Community Platform Foundation

## Problem

Project information is strong, but community discovery and participation are fragmented.
New users can run the platform, yet there is no structured "community hub" experience for:

- finding trusted setup guides,
- sharing integrations and templates,
- voting on feature priorities,
- discovering known best practices.

## Proposed Solution

Build a community-first website layer that combines docs, roadmap visibility, and contribution entry points.

### Recommended Architecture (reuse-first)

Avoid custom CMS work. Use a proven stack:

- **Docusaurus** (documentation and versioned content)
- **GitHub Discussions** (community Q&A and idea threads)
- **OpenAPI + Swagger UI** (public helper/control API docs where safe)
- **Plausible or Umami** (privacy-friendly analytics)

### Why this avoids re-inventing the wheel

- Docusaurus gives versioned docs, search, and structured navigation out of the box.
- GitHub Discussions already provides moderation, reactions, and threading.
- Swagger/OpenAPI eliminates hand-maintained endpoint documentation drift.

## Information Architecture

Proposed top-level site sections:

1. **Get Started**
   - installation paths (VM or direct host)
   - secure defaults checklist
2. **Use Cases**
   - private AI chat
   - document automation
   - home-lab operations
3. **Community Hub**
   - "show and tell" integrations
   - proposal voting links
   - community playbooks
4. **Roadmap**
   - now/next/later board
   - release highlights and migration notes
5. **Contribute**
   - code contribution guide
   - docs contribution guide
   - support and triage etiquette

## Implementation Phases

### Phase 1 (1-2 weeks): Foundation

- Deploy Docusaurus with core navigation and current README content split into topic pages.
- Link GitHub Discussions and define categories (`Ideas`, `Help`, `Showcase`, `Announcements`).
- Add docs versioning aligned with release tags.

### Phase 2 (2-3 weeks): Community Signals

- Add "Community Highlights" page powered by curated discussion links.
- Add public roadmap page with issue/discussion references.
- Introduce proposal labels and voting guidance.

### Phase 3 (1-2 weeks): Quality and Growth

- Add feedback widgets on docs pages ("was this useful?").
- Add contributor onboarding path with estimated effort levels.
- Add monthly summary page with accepted and shipped ideas.

## Risks and Mitigations

- **Risk**: stale pages and abandoned discussions  
  **Mitigation**: define rotation ownership (weekly doc owner, monthly community curator).

- **Risk**: fragmented decision-making  
  **Mitigation**: every accepted idea must map to a tracked issue and target release.

- **Risk**: noisy low-quality ideas  
  **Mitigation**: use suggestion template and minimum context requirements.

## Success Metrics

- 30% increase in monthly documentation contributors within 90 days.
- 25% reduction in repeated support questions through better discoverability.
- At least 5 community-originated proposals reviewed each month.
- Median "time to first community response" under 24 hours.
