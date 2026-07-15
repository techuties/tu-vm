# Website Suggestions - Day-to-Day Tooling for Community Operations

## Objective
Reduce maintainer overhead by automating repetitive tasks around suggestions, triage, releases, and communication.

## Tooling Recommendations

## 1) Suggestion templates and schema checks
- Enforce a structured suggestion template.
- Add CI validation for required sections (problem, impact, success criteria, effort).
- Reject malformed submissions early.
- Validate website markdown frontmatter before a suggestion can move past
  `draft`.
- Ensure `id`, `status`, `theme`, `owner`, and `updated_at` are present on
  durable suggestion pages.
- Fail duplicate suggestion IDs and invalid status values.

Recommended implementation:

- Start with a repository-local Python validator using a small allowed-status
  list and relative-link checks.
- Move to framework-native validation if the selected docs stack provides a
  mature plugin.
- Keep validation output actionable: file path, missing field, and suggested
  fix.

## 2) Auto-triage assistant
- Rule-based tagging on submission:
  - docs, UI, infra, security, performance, automation
- Duplicate detection using title/keyword similarity.
- Route high-risk suggestions (security/runtime controls) to maintainers first.
- Compare new issues against the canonical files linked from
  [`README.md`](./README.md), then scan older `/suggestions/` headings only
  when deeper historical context is needed.
- Suggest `superseded` or "extend existing suggestion" when overlap is high.
- Keep automated dedupe advisory until maintainers trust the false-positive
  rate.

Suggested signals:

- matching nouns in title and summary
- shared component names (`tu-vm.sh`, helper API, nginx dashboard, docs site)
- same lifecycle theme and impact level
- links to the same existing issue or PR

## 3) Prioritization helper
- Recurring job calculates priority scores from:
  - community signal (GitHub thumbs-up reactions or an explicit Project field)
  - age
  - severity/impact
  - estimated implementation size
- Output top-N queue for planning meetings.
- Include a reuse score so mature framework-based suggestions rank above
  custom rewrites with the same user impact.
- Publish the scoring formula beside the status board.

Suggested formula inputs:

| Input | Reason |
|-------|--------|
| Community impact | How many users or contributors benefit |
| Reuse score | Whether mature tools/frameworks handle the need |
| Operational risk | Lower risk should move faster |
| Maintenance cost | Ongoing burden after launch |
| Evidence quality | Clear reproduction, examples, or acceptance tests |

## 4) Changelog synchronizer
- When suggestion status changes to `shipped`, prompt maintainers to:
  - attach implementation reference (commit/tag)
  - add changelog entry
  - link back from suggestion page
- Normalize website status to `shipped`, while still mapping GitHub labels or
  project-board states such as `completed` when needed.
- Add missing release links to `implemented.md` during release preparation.

## 5) Notification automation
- Broadcast changes to community channels when:
  - suggestions accepted
  - status moved to in-progress
  - shipped and released
- Keep notification digest mode to prevent spam.
- Prefer digest summaries over one notification per metadata edit.
- Include rationale links for deferred and rejected ideas so contributors see
  that review happened.

## 6) Contributor productivity toolkit
- `make` or script shortcuts for:
  - local docs preview
  - markdown lint checks
  - suggestion schema validation
  - local API/dev server startup
- Include one-command bootstrap for new contributors.
- Add `suggestions:check` or equivalent task-runner target that runs markdown
  lint, relative-link validation, and schema checks together.
- Add `suggestions:new` helper only if it writes from the canonical template and
  refuses duplicate IDs.

## 7) Quality and accessibility checks for website pages
- Automated checks for:
  - broken links
  - heading hierarchy
  - color contrast failures
  - keyboard navigation basics
  - ARIA landmarks on key pages
- Keep suggestion tables narrow enough for mobile; use generated detail pages
  instead of overloading the status board.
- Prefer descriptive link text such as "Decision DEC-2026-003" instead of
  generic "read more".
- Ensure any generated charts or metrics summaries have accessible labels and
  text alternatives.

## 8) Website generation workflow

Recommended flow after a static-site framework is selected:

1. Read markdown suggestion pages and frontmatter.
2. Generate status, theme, owner, and recently updated indexes.
3. Render decision and implemented pages from the same metadata.
4. Run link, accessibility, and build checks in CI.
5. Publish static assets without adding runtime dependencies to TU-VM core
   services.

## 9) Maintainer dashboard ideas

Helpful dashboard widgets that reuse existing metadata:

- new suggestions waiting for triage
- accepted suggestions without linked implementation work
- in-progress suggestions missing validation evidence
- shipped suggestions missing changelog/release links
- deferred suggestions whose reopen conditions have changed

## Suggested Implementation Sequence
1. Template + schema validation
2. Auto-tagging and duplicate checks
3. Priority score generator
4. Changelog sync reminders
5. Notification digests
6. Generated website status indexes
7. Accessibility and link validation in the docs build

## Risks and Mitigations
- **Risk:** automation noise  
  **Mitigation:** start in suggestion mode (non-blocking), then enforce once stable.

- **Risk:** inaccurate duplicate detection  
  **Mitigation:** keep human override and merge suggestions manually.

- **Risk:** maintainer trust in scoring  
  **Mitigation:** make formula visible and editable in config.

## Definition of Done for Tooling Rollout
- New suggestions are consistently structured.
- Triage time decreases measurably.
- Shipped items reliably appear in changelog/release communication.
- Contributors can onboard and contribute with minimal manual guidance.
- Website suggestion pages can be generated or reviewed without custom manual
  bookkeeping.
- Duplicate proposals trend down because historical suggestions are searchable
  and canonical pages are clearly linked.
