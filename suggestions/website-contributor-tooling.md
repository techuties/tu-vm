# Website Contributor Tooling Suggestions

This document proposes practical tooling to improve day-to-day operations for maintainers and community contributors.

## 1) Documentation workflow tooling

### Recommended baseline
- Markdown linting (`markdownlint`) for consistent docs quality.
- Link checking in CI (for example, `lychee`).
- Spellchecking focused on docs terms (`cspell` with project dictionary).
- Optional docs formatting (`prettier`) for predictable diffs.

Why:
- Reduces review effort.
- Prevents broken links and inconsistent style.
- Makes community PRs easier to accept quickly.

## 2) "Definition of done" for website/docs PRs

For every docs or website contribution:
- Build passes locally and in CI.
- No broken internal links.
- Security-sensitive guidance reviewed by a maintainer.
- Screenshots and commands are current.
- Changelog/reference updates included when behavior changed.

Publish this checklist on the contributor pages.

## 3) Automation suggestions using existing services

### Use n8n for community automation
- Auto-label incoming suggestions by keywords.
- Route security-sensitive suggestions to maintainer queue.
- Send digest summaries of open suggestions and stale PRs.
- Notify maintainers when docs for changed features are missing.

### Use helper API for status surfaces
- Add a public-safe endpoint for community metrics (optional).
- Keep sensitive control surfaces isolated behind token + allowlist.

## 4) Suggested CI jobs for website and docs

Minimum CI pipeline:
1. Markdown lint
2. Link check
3. Docs build
4. Optional accessibility smoke checks (Lighthouse/Pa11y)

Nice-to-have:
- Broken command detection by running shell snippets in a controlled test environment.
- Changed-page preview deployment.

## 5) Template library to avoid rework

Create and maintain reusable templates:
- Suggestion template
- RFC template
- New service integration template
- Troubleshooting article template
- Release notes template

This keeps community contributions structured and comparable.

## 6) Release communication tooling

Recommended:
- Generate release highlights from changelog sections.
- Publish "what changed / why it matters / operator action required".
- Tag docs pages with the version they apply to.

This avoids confusion for users running older VM versions.

## 7) Operational quality metrics

Track a short set of metrics:
- Median time to first maintainer response.
- Median time to merge docs PRs.
- Number of stale suggestions older than 30 days.
- Number of broken links found per week.
- Percentage of feature PRs with docs updates.

Use these metrics to improve process, not to gate contributors.

## 8) Suggested adoption sequence

Week 1:
- Add markdown lint + link checker + docs build checks.

Week 2:
- Add contribution templates and PR checklist.

Week 3:
- Add n8n triage automation and weekly maintainer digest.

Week 4:
- Add accessibility smoke tests and community metrics dashboard.
