# Website Suggestions - Community Features and Governance

## Objective
Create a community-based system where ideas are easy to submit, easy to evaluate, and easy to track from proposal to delivery.

## Core Community Features

## 1) Suggestion intake with quality prompts
Every new suggestion should require:
- problem statement
- expected user impact
- rough effort estimate (small/medium/large)
- affected area (dashboard, API, docs, tooling, security)
- success criteria

This reduces low-context requests and speeds triage.

### Reuse-first intake path

Start with GitHub-native workflow before adding custom submission infrastructure:

1. GitHub Issue template for idea/suggestion intake
2. Labels for `suggestion`, `triage`, `area:*`, `risk:*`, and `status:*`
3. Optional GitHub Discussions for early design threads
4. Markdown suggestion pages for accepted or high-value proposals
5. Website index generated from markdown/frontmatter and linked GitHub artifacts

Custom forms, authentication, and database-backed submissions should wait until issue/discussion volume creates a clear need.

## 2) Public triage board
Use clear states:
- `New`
- `Needs Clarification`
- `Accepted`
- `Planned`
- `In Progress`
- `Completed`
- `Declined` (with rationale)

Each suggestion should show:
- owner/maintainer
- next action
- target milestone (if available)

## 3) Voting and prioritization
- Allow lightweight upvotes.
- Add maintainer weighting factors:
  - community demand (votes)
  - platform risk
  - implementation complexity
  - security impact
  - operational cost
- Show a transparent priority score breakdown.

Recommended first implementation: use GitHub reactions and comment signals as demand input. A custom voting service should be considered only after maintainers need stronger anti-abuse controls, anonymous user handling, or weighted voting rules that GitHub cannot represent.

## 4) Decision transparency
Each suggestion should keep a decision log:
- why accepted or declined
- tradeoffs considered
- links to implementation artifacts (commits/releases/changelog entries)

## 5) Contributor pathways
- "Good first suggestions" label for low-risk tasks.
- "Needs design" for proposals requiring UX/architecture.
- "Needs maintainer input" for blocked items.
- Ready-to-implement checklists for accepted suggestions.

## Community website page set

The website should expose a small set of pages that answer the most common contributor questions:

1. **Community home**
   - current focus areas
   - links to Issues, Discussions, playbooks, and contribution guide
   - latest shipped community wins
2. **Suggestions board**
   - grouped by status and area
   - includes historical baseline and duplicate-merge notes
   - links to canonical GitHub issues/PRs
3. **Roadmap**
   - planned, in-progress, completed, deferred
   - explains why items were prioritized
   - links to release/changelog evidence
4. **Contributor starter path**
   - good first issues
   - local validation commands
   - PR checklist and risk classification examples
5. **Governance and decisions**
   - roles, ownership, RFC-lite path
   - accepted/declined rationale
   - security review expectations

## Suggested Review Cadence
- Weekly triage: classify all new items.
- Bi-weekly planning: move accepted items into planned milestones.
- Monthly retrospective: summarize completed community suggestions and impact.

## Suggested Moderation Rules
- No duplicate proposals: merge into canonical thread.
- Mark stale ideas after inactivity window (for example 30-45 days) with reopen option.
- Require respectful communication and actionable comments.
- Keep decline reasons explicit to maintain trust.

## Community KPI Dashboard (website page)
- New suggestions per week
- Triage lead time
- Acceptance rate
- Mean time from accepted to completed
- Reopened rate
- Top requested categories

Start with manually curated metrics from GitHub and changelog data. Automate collection later through GitHub Actions or a static data export once the metrics prove useful.

## Integration with Existing Project Assets
- Link implemented suggestions into `CHANGELOG.md`.
- Pull operational data from existing helper status endpoints where relevant.
- Keep community pages informational; runtime control stays behind secured endpoints.
- Surface playbook links from `docs/playbooks/` instead of duplicating operational recipes.
- Treat `tu-vm.sh` and existing scripts as the source of truth for executable workflows.

## Recommended First Iteration (MVP)
1. Static suggestion list + detail pages backed by markdown/frontmatter
2. Status workflow + decision log linked to GitHub issues/PRs
3. GitHub reaction/comment signals as lightweight demand input
4. Maintainer triage checklist and ownership map
5. Read-only roadmap page derived from suggestion statuses
