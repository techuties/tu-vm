# Website Suggestion Dedupe Map

## Purpose

The `suggestions/` folder already contains many historical community, website, tooling, and roadmap proposals. This map helps contributors extend that history without creating another near-duplicate file.

Use this file before adding or reviewing website/community suggestions.

## How to use this map

1. Find the closest cluster below.
2. Read the canonical files first.
3. Update an existing canonical file when the new idea is an extension.
4. Add a new suggestion file only when the idea has a distinct implementation path, owner, risk profile, or acceptance criteria.
5. Link duplicates, replacements, and related work explicitly.

## Canonical clusters

### 1. Historical baseline and reuse rules

Canonical files:

- [`website-historical-baseline.md`](./website-historical-baseline.md)
- [`historical-suggestions-baseline.md`](./historical-suggestions-baseline.md)
- [`historical-patterns-from-project.md`](./historical-patterns-from-project.md)

Use these for:

- explaining what prior branches already proposed,
- identifying repository surfaces that should be reused,
- preventing new work from replacing `tu-vm.sh`, the helper API, the Nginx dashboard, or existing GitHub workflows without a strong reason.

Common duplicate shape:

- "Create a community suggestions process"
- "Add a website for suggestions"
- "Build tooling for contributor workflows"

Preferred action:

- Link to the baseline, then add only the new detail that is missing.

### 2. Website framework and publishing

Canonical files:

- [`website-markdown-publishing-system.md`](./website-markdown-publishing-system.md)
- [`website-and-docs-framework.md`](./website-and-docs-framework.md)
- [`website-platform-frameworks.md`](./website-platform-frameworks.md)
- [`website-information-architecture.md`](./website-information-architecture.md)

Use these for:

- Docusaurus/Astro/MkDocs/VitePress selection,
- markdown/frontmatter records,
- website page structure,
- generated indexes and status boards,
- docs-site migration boundaries.

Common duplicate shape:

- "Use Astro for a community site"
- "Use VitePress for docs"
- "Use Docusaurus for suggestions"
- "Build a custom suggestions app"

Preferred action:

- Treat Docusaurus as the default docs-site recommendation.
- Use Astro/Starlight only when custom product pages and interactive content become the main driver.
- Keep markdown in `suggestions/` as the source of truth regardless of framework.
- Avoid a custom suggestion database until GitHub-native intake is demonstrably insufficient.

### 3. Community governance and lifecycle

Canonical files:

- [`website-community-framework.md`](./website-community-framework.md)
- [`community-system-framework.md`](./community-system-framework.md)
- [`community-contribution-system.md`](./community-contribution-system.md)
- [`02-community-contribution-system.md`](./02-community-contribution-system.md)

Use these for:

- contributor roles,
- suggestion review statuses,
- issue/PR taxonomy,
- decision lanes,
- maintainership expectations,
- public transparency requirements.

Common duplicate shape:

- "Create a suggestion lifecycle"
- "Add contributor roles"
- "Add an RFC process"
- "Define triage labels"

Preferred action:

- Extend the existing lifecycle only when a new status, role, or decision lane is required.
- Keep status names aligned with GitHub labels and the website metadata contract.

### 4. Website community pages

Canonical files:

- [`website-community-pages.md`](./website-community-pages.md)
- [`website-community-platform.md`](./website-community-platform.md)
- [`website-community-features.md`](./website-community-features.md)
- [`website-community-roadmap.md`](./website-community-roadmap.md)

Use these for:

- public suggestions landing pages,
- how-to-submit pages,
- status boards,
- implemented suggestion showcases,
- decision logs,
- community feature ideas.

Common duplicate shape:

- "Add a suggestions page"
- "Add a status board"
- "Add implemented ideas page"
- "Show decisions publicly"

Preferred action:

- Keep the page set small: index, how-to-submit, status-board, decisions, implemented.
- Generate status views from metadata where possible.

### 5. Day-to-day maintainer tooling

Canonical files:

- [`website-tools-and-automation.md`](./website-tools-and-automation.md)
- [`website-tooling-and-operations.md`](./website-tooling-and-operations.md)
- [`website-tooling-framework.md`](./website-tooling-framework.md)
- [`developer-experience-tooling.md`](./developer-experience-tooling.md)
- [`03_developer-experience-and-tooling.md`](./03_developer-experience-and-tooling.md)
- [`implementation-backlog.md`](./implementation-backlog.md)

Use these for:

- markdown validation,
- link checks,
- duplicate detection,
- release-note helpers,
- dashboard/browser smoke tests,
- helper API contract checks,
- pre-push and CI workflows.

Common duplicate shape:

- "Add a doctor script"
- "Add smoke tests"
- "Add release helper"
- "Add markdown lint"
- "Add stale suggestion reminders"

Preferred action:

- Check `implementation-backlog.md` first because several tooling ideas are already implemented or superseded.
- Add new tooling suggestions only when they include specific command behavior, inputs, outputs, failure modes, and acceptance criteria.

### 6. Dashboard and helper API improvements

Canonical files:

- [`website-feature-suggestions.md`](./website-feature-suggestions.md)
- [`website-roadmap-and-acceptance.md`](./website-roadmap-and-acceptance.md)
- [`implementation-backlog.md`](./implementation-backlog.md)

Relevant repository files:

- [`../nginx/html/index.html`](../nginx/html/index.html)
- [`../helper/uploader.py`](../helper/uploader.py)
- [`../fixtures/status-full-contract.json`](../fixtures/status-full-contract.json)
- [`../scripts/validate_status_full_contract.py`](../scripts/validate_status_full_contract.py)

Use these for:

- dashboard cards and controls,
- `/status/full` contract changes,
- "What is new" content,
- service dependency hints,
- frontend modularization,
- browser smoke tests.

Common duplicate shape:

- "Improve the dashboard"
- "Add live release notes"
- "Add Playwright tests"
- "Split index.html into components"

Preferred action:

- Tie every dashboard suggestion to a helper API contract or static fallback.
- Keep LAN-first privacy defaults.
- Require validation evidence for behavior changes.

### 7. Feature roadmap from historical suggestions

Canonical files:

- [`04_feature-roadmap-from-historical-suggestions.md`](./04_feature-roadmap-from-historical-suggestions.md)
- [`website-roadmap-from-historical-suggestions.md`](./website-roadmap-from-historical-suggestions.md)
- [`website-implementation-roadmap.md`](./website-implementation-roadmap.md)
- [`04-implementation-roadmap.md`](./04-implementation-roadmap.md)

Use these for:

- Quick Action Profiles,
- battery-aware operation,
- idle auto-stop,
- resource history,
- smart startup,
- dependency assistance,
- mobile/accessibility improvements.

Common duplicate shape:

- "Add profiles"
- "Stop heavy services automatically"
- "Track resource history"
- "Improve startup"

Preferred action:

- Add implementation-grade specs only when they define contracts, controls, and validation steps.
- Keep operator safety and explicit controls central.

## New suggestion decision tree

Use this decision tree during review:

```text
Is the idea already implemented?
  yes -> link implementation and mark implemented/superseded
  no  -> continue

Does a canonical file already cover the same problem?
  yes -> update that file or add a related subsection
  no  -> continue

Does the idea need a separate rollout, owner, or validation path?
  yes -> create a new detailed suggestion file
  no  -> add it to the closest canonical file

Would the idea require a new service, database, identity layer, or external dependency?
  yes -> require security, privacy, rollback, and maintenance notes
  no  -> standard suggestion template is enough
```

## Required duplicate handling language

When closing or superseding a duplicate, use language like:

```text
This overlaps with <canonical suggestion>. The useful new detail is being merged there so the project keeps one source of truth. This record is marked superseded by <canonical suggestion>.
```

For partial overlap:

```text
This is related to <canonical suggestion>, but has a distinct implementation path because <reason>. It remains separate and links back to the canonical context.
```

## Suggested metadata links

For new markdown suggestion files, use these fields to keep relationships visible:

```yaml
related:
  - suggestions/website-historical-baseline.md
supersedes:
  - suggestions/old-duplicate.md
superseded_by: suggestions/new-canonical.md
```

## Review checklist

- The proposal links to at least one historical or canonical suggestion.
- The proposal explains why existing GitHub/templates/docs/scripts are not enough.
- The proposal avoids creating a new source of truth without justification.
- The proposal includes acceptance criteria and rollback notes.
- The proposal identifies security, privacy, and maintenance impact.
- The hub pages are updated only when the proposal is canonical or broadly reusable.

## Maintenance rule

Update this map whenever:

- a new canonical suggestion file is added,
- a duplicated cluster is merged,
- a framework decision changes,
- a proposal moves from suggested to implemented,
- a historical branch contributes a materially different idea.
