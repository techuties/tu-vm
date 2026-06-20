# Website Suggestions - Day-to-Day Tooling for Community Operations

## Objective
Reduce maintainer overhead by automating repetitive tasks around suggestions, triage, releases, and communication. Tooling should start as small scripts or CI checks, then graduate to services only when usage proves the maintenance cost is worth it.

## Tooling Recommendations

## 1) Suggestion templates and schema checks
- Enforce a structured suggestion template.
- Add CI validation for required sections (problem, impact, success criteria, effort).
- Reject malformed submissions early.
- Require historical-overlap notes so contributors show what existing suggestions they checked.
- Validate frontmatter fields if suggestions become website-rendered markdown.

Suggested reusable tools:
- GitHub Issue Forms for structured intake.
- A small Python frontmatter validator for markdown in `/suggestions/`.
- markdownlint with a narrow, documented rule set.

## 2) Auto-triage assistant
- Rule-based tagging on submission:
  - docs, UI, infra, security, performance, automation
- Duplicate detection using title/keyword similarity.
- Route high-risk suggestions (security/runtime controls) to maintainers first.
- Keep the first version advisory: comment with "possible related suggestions" instead of blocking.
- Promote to required review only after false positives are understood.

Suggested implementation:
- Generate a local keyword index from titles, headings, and tags.
- Compare new suggestions against the index and return the top related files.
- Store merge/supersede decisions in the suggestion status log.

## 3) Prioritization helper
- Daily/weekly job calculates priority scores from:
  - vote count
  - age
  - severity/impact
  - estimated implementation size
- Output top-N queue for planning meetings.
- Display the formula beside results so contributors can understand trade-offs.
- Keep maintainer override visible with rationale.

Suggested scoring fields:
- operator impact
- community leverage
- security or reliability benefit
- implementation complexity
- maintenance burden
- reuse of existing frameworks/tools

## 4) Changelog synchronizer
- When suggestion status changes to `Completed`, prompt maintainers to:
  - attach implementation reference (commit/tag)
  - add changelog entry
  - link back from suggestion page
- Flag shipped suggestions with no release note.
- Create a release-digest section for "Community suggestions delivered."

## 5) Notification automation
- Broadcast changes to community channels when:
  - suggestions accepted
  - status moved to in-progress
  - completed and released
- Keep notification digest mode to prevent spam.
- Prefer digest summaries over per-event notifications unless a maintainer explicitly opts in.
- Include links to decisions and validation evidence, not just status names.

## 6) Contributor productivity toolkit
- `make` or script shortcuts for:
  - local docs preview
  - markdown lint checks
  - suggestion schema validation
  - local API/dev server startup
- Include one-command bootstrap for new contributors.
- Add `tu-vm.sh` aliases only when they fit the existing operator CLI model.
- Keep docs-only validation runnable without starting Docker.

Useful commands to standardize:
- `scripts/check-suggestions.sh`: validates frontmatter, links, and duplicate hints.
- `scripts/generate-suggestion-index.py`: emits markdown or JSON status indexes.
- `scripts/release-note-helper.sh`: includes shipped suggestion IDs in release notes.
- `scripts/docs-preview.sh`: starts the chosen static-site framework locally.

## 7) Quality and accessibility checks for website pages
- Automated checks for:
  - broken links
  - heading hierarchy
  - color contrast failures
  - keyboard navigation basics
  - ARIA landmarks on key pages
- For generated dashboards, ensure every card view has an equivalent list/table view.
- Keep visual status badges backed by readable text labels.

Suggested reusable tools:
- markdownlint for markdown structure.
- lychee or equivalent for links.
- Playwright for rendered website smoke tests.
- axe-core checks through Playwright once pages are rendered in CI.

## 8) Maintainer operations dashboard

Create a small generated dashboard for recurring community work:

- New suggestions needing first triage.
- Accepted suggestions missing owner or implementation issue.
- In-progress suggestions without recent update.
- Shipped suggestions missing changelog links.
- Deferred suggestions with re-open conditions.

Start by generating markdown or JSON artifacts from `/suggestions/`; do not add a database until the manual process breaks down.

## 9) Community digest helper

Generate a digest that maintainers can publish with minimal editing:

- New ideas received.
- Accepted ideas and rationale.
- Shipped community improvements.
- Items needing testers.
- Duplicates merged into canonical suggestions.

The digest should always link to source suggestions and decisions so contributors can audit the summary.

## Suggested Implementation Sequence
1. Template + schema validation
2. Auto-tagging and duplicate checks
3. Priority score generator
4. Changelog sync reminders
5. Notification digests
6. Generated maintainer dashboard
7. Rendered website accessibility checks

## Risks and Mitigations
- **Risk:** automation noise  
  **Mitigation:** start in suggestion mode (non-blocking), then enforce once stable.

- **Risk:** inaccurate duplicate detection  
  **Mitigation:** keep human override and merge suggestions manually.

- **Risk:** maintainer trust in scoring  
  **Mitigation:** make formula visible and editable in config.

- **Risk:** tool sprawl
  **Mitigation:** prefer scripts that reuse GitHub, markdown, existing CI, and `tu-vm.sh` patterns before adding long-running services.

- **Risk:** community submissions accidentally affect runtime services
  **Mitigation:** keep suggestion intake separate from `/control/*`, require moderation, and forbid direct writes into trusted runtime paths.

## Definition of Done for Tooling Rollout
- New suggestions are consistently structured.
- Triage time decreases measurably.
- Completed items reliably appear in changelog/release communication.
- Contributors can onboard and contribute with minimal manual guidance.
- Historical suggestions are searchable enough that duplicate ideas can be merged rather than re-created.
- Website suggestion pages pass link, structure, and accessibility checks before publication.
