# Website Suggestion: Community Operations and Governance

## Problem

Without a transparent governance loop, community ideas can be lost, duplicated, or delayed without context.
This creates frustration and repeated requests for already-discussed topics.

## Proposed Solution

Introduce a lightweight community operations model that keeps proposal decisions visible and predictable.

## Reused Systems (no custom platform required)

- **GitHub Projects** for public roadmap states (`Now`, `Next`, `Later`)
- **GitHub Discussions** for proposal debate and feedback
- **Release notes + changelog links** for closure of accepted suggestions
- **Cron-driven suggestion review cadence** (weekly triage, monthly summary)

## Governance Model

### Decision Roles

- **Maintainers**: final technical decision and sequencing.
- **Community moderators**: keep proposals actionable and deduplicated.
- **Contributors**: submit, refine, and champion ideas.

### Decision Rules

Every suggestion should include:

1. user pain point
2. expected impact
3. alternatives considered
4. implementation complexity
5. maintenance owner

Suggestions without these should remain in `needs-details`.

## Operating Cadence

### Weekly (30-45 min)

- Triage new suggestions
- Merge duplicates into canonical threads
- Assign preliminary status (`reviewing`, `deferred`, `approved`)

### Monthly (60 min)

- Publish "community outcomes" summary:
  - accepted suggestions
  - shipped suggestions
  - deferred/rejected with rationale
- Refresh `Now/Next/Later` prioritization

### Quarterly

- Revisit governance health:
  - response time
  - contributor retention
  - implementation throughput

## Suggested Status Taxonomy

- `needs-details`
- `reviewing`
- `approved`
- `in-progress`
- `shipped`
- `deferred`
- `rejected`

Use status definitions consistently across issues, discussions, and roadmap board cards.

## Risks and Mitigations

- **Risk**: governance overhead grows too heavy  
  **Mitigation**: strict time-boxed meetings and templated updates.

- **Risk**: limited transparency in rejections  
  **Mitigation**: require a one-paragraph rationale for every rejected/deferred item.

- **Risk**: repeated duplicate proposals  
  **Mitigation**: maintain canonical index in `/suggestions/README.md` and link it in issue forms.

## Success Metrics

- Duplicate suggestion rate reduced by 35% in 3 months.
- 90% of new suggestions triaged within 7 days.
- Monthly community summary posted 100% on schedule.
- At least 2 community-originated suggestions shipped per quarter.
