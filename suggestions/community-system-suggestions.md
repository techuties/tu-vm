# Community System Suggestions

This document focuses on building a community-based system around the existing dashboard and helper API, with clear processes for contributors and maintainers.

## Design principles

- **Low-friction onboarding**: contributors should find one obvious path to help.
- **Visible impact**: community members should see how ideas become shipped changes.
- **Safety by default**: moderation and access control should be explicit.
- **Maintainability**: avoid systems that create heavy manual moderation burden.

## Suggestion 1: Suggestion lifecycle board

**Status:** `proposed`  
**Priority:** High  
**Objective:** Give the community a transparent, consistent pipeline for ideas.

### Proposal

Create a public lifecycle board with states:

1. New
2. Triaged
3. Accepted
4. In progress
5. Shipped
6. Deferred

This can be reflected via:
- GitHub issue labels and saved views.
- A generated JSON feed consumed by the dashboard's "Announcements" panel.

### Why this matters

- Reduces duplicate suggestions.
- Makes decision-making transparent.
- Builds trust by showing movement and outcomes.

### Implementation approach

1. Define labels in repository conventions (`suggestion:new`, `suggestion:accepted`, etc.).
2. Add a script to export labeled issues to JSON.
3. Add `/status/suggestions` endpoint in `helper/uploader.py`.
4. Render a compact "Community Suggestion Queue" panel in `nginx/html/index.html`.

### Success criteria

- Contributors can identify suggestion state within 30 seconds.
- Duplicate suggestions decrease over time.
- Maintainers close suggestion loops with clear state transitions.

---

## Suggestion 2: Community RFC template and decision log

**Status:** `proposed`  
**Priority:** High  
**Objective:** Standardize technical proposals and preserve rationale.

### Proposal

Introduce a lightweight RFC process for larger changes:

- Community member submits RFC issue using template sections:
  - Problem statement
  - Proposed approach
  - Alternatives considered
  - Rollout plan
  - Risks
  - Success metrics
- Maintainer decision is captured in a persistent decision log.

### Why this matters

- Avoids repeating prior technical debates.
- Helps newcomers understand why choices were made.
- Improves long-term architecture consistency.

### Implementation approach

1. Add GitHub issue template for RFCs.
2. Add a `suggestions/historical-suggestions.md` entry per accepted/rejected RFC.
3. Link decisions in release notes/changelog when shipped.

### Success criteria

- Major architecture changes include documented alternatives.
- Community questions about "why" can be answered with references.

---

## Suggestion 3: Contributor reputation signals (lightweight)

**Status:** `proposed`  
**Priority:** Medium  
**Objective:** Encourage healthy contribution behavior without gamification overhead.

### Proposal

Track and display lightweight contribution signals:
- Suggestions submitted
- Suggestions accepted
- Docs improvements merged
- Bug reports confirmed

Display top contributors in:
- Dashboard announcement module (rotating acknowledgment)
- Monthly changelog section

### Why this matters

- Increases motivation and retention.
- Rewards non-code contributions equally.

### Implementation approach

1. Use GitHub API query script to gather data.
2. Produce monthly JSON summary.
3. Render in dashboard "Community Highlights" section.

### Success criteria

- Increased repeat contribution rate.
- Balanced recognition across code and non-code contributions.

---

## Suggestion 4: Moderation and safety workflow

**Status:** `proposed`  
**Priority:** High  
**Objective:** Keep community interactions constructive and secure.

### Proposal

Define moderation policy and escalation:

- Contribution code of conduct references.
- Abuse/spam reporting path.
- Maintainer on-call rotation for moderation tasks.
- Auto-triage flags for potentially unsafe suggestions (e.g., asks to disable auth).

### Why this matters

- Prevents policy drift.
- Reduces burnout from ad-hoc moderation.
- Keeps security posture intact during community growth.

### Implementation approach

1. Add moderation rules in contributor docs.
2. Add issue form fields for risk/security impact.
3. Auto-label risky items for mandatory review.

### Success criteria

- Faster moderation response for flagged issues.
- Fewer unsafe suggestions reaching implementation without review.

---

## Suggestion 5: Monthly community review cadence

**Status:** `proposed`  
**Priority:** Medium  
**Objective:** Create predictable checkpoints for community alignment.

### Proposal

Run a recurring monthly review:

- What was shipped from community suggestions.
- What is blocked and why.
- Next top 3 suggestions targeted.

Publish summary via:
- Changelog snippet
- Dashboard announcements
- `suggestions/historical-suggestions.md` update

### Why this matters

- Strengthens feedback loop.
- Prevents suggestion backlog from becoming stale.

### Success criteria

- Monthly review completed consistently.
- Backlog health metrics visible and improving.

---

## Suggested phased rollout

### Phase A: Process foundation

- Suggestion lifecycle labels
- RFC template
- Moderation policy baseline

### Phase B: Dashboard visibility

- Suggestions status API endpoint
- Queue/Highlights UI blocks on landing page

### Phase C: Metrics and recognition

- Contribution signal generation
- Monthly review publishing workflow
