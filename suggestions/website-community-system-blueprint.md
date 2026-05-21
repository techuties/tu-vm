---
title: Website Community System Blueprint
description: Canonical, detailed suggestions for a community-based website and day-to-day contributor system.
status: proposed
updated: 2026-05-21
---

# Website Community System Blueprint

## Purpose

This blueprint consolidates the repeated historical suggestions in this folder into a single, implementation-oriented direction for the TU-VM website and community system.

The goal is to make community participation easier without rebuilding services that mature open-source tools already provide.

## Historical suggestions reviewed

This proposal builds from the existing suggestions history instead of starting over:

- `website-historical-baseline.md`
- `historical-suggestions.md`
- `website-information-architecture.md`
- `website-and-docs-framework.md`
- `website-framework-and-architecture.md`
- `website-community-framework.md`
- `community-system-framework.md`
- `community-operating-framework.md`
- `website-contributor-tooling.md`
- `tooling-and-day2-operations.md`
- `implementation-backlog.md`

Recurring themes across those files:

1. Keep the current Nginx dashboard and helper API as the operational control surface.
2. Add a docs-first website layer for onboarding, proposals, roadmap, and governance.
3. Use GitHub Issues, PRs, labels, Release Drafter, and existing scripts before introducing custom workflow services.
4. Make suggestions discoverable, de-duplicated, and traceable from proposal to release.
5. Preserve local-first privacy, LAN-first security posture, and rollback paths for operational changes.

## Recommendation summary

Adopt a **docs-first community website** backed by Markdown and GitHub workflows first. Add dynamic community features only after the static process is useful and maintainable.

### Recommended framework path

1. **Start with MkDocs Material or VitePress for the community docs site.**
   - Both support Markdown-first authoring, search, navigation, and static hosting.
   - MkDocs Material fits the current Python-heavy repository and avoids adding a large frontend toolchain early.
   - VitePress fits if maintainers prefer a Vue/Node ecosystem and want richer interactive docs components.

2. **Avoid a custom suggestions application at first.**
   - GitHub Issues already provide identity, discussion, labels, search, notifications, and moderation controls.
   - Markdown files in `suggestions/` are enough for curated decisions, accepted proposals, and historical records.

3. **Add a separate community web app only when static docs are insufficient.**
   - A future `/community` app can use Next.js or another mature framework if the project needs authenticated voting, richer roadmap filtering, or public profile pages.
   - Keep that route separate from operational dashboard controls.

## Website information architecture

Use a simple top-level structure:

```text
/
  Home
  Install
  Operate
  Security
  Community
  Suggestions
  Roadmap
```

### Home

Purpose:

- Explain what TU-VM does.
- Link to install, operations, security, and contribution paths.
- Keep the existing Nginx dashboard focused on runtime operations.

Suggested content:

- Short platform overview.
- Service map.
- "Start here" paths for operators, contributors, and reviewers.
- Links to GitHub Issues, Discussions if enabled, releases, and security policy.

### Install

Purpose:

- Turn setup knowledge from `README.md`, `QUICK_REFERENCE.md`, and playbooks into task-focused pages.

Suggested pages:

- Requirements
- First startup
- Secure/public/lock modes
- Configuration reference
- Troubleshooting bootstrap failures

### Operate

Purpose:

- Make day-to-day administration easier for non-expert users.

Suggested pages:

- Service tiers
- Start/stop/status workflows
- Backup and restore
- Updates and rollback
- Diagnostics with `./tu-vm.sh doctor`
- Smoke testing and helper contract checks

### Security

Purpose:

- Preserve the private-AI and LAN-first posture while expanding community contribution.

Suggested pages:

- Threat model basics
- Access modes and Nginx boundaries
- Secret handling
- Vulnerability reporting
- Review rules for network, auth, data, and control endpoint changes

### Community

Purpose:

- Explain how people participate and how maintainers make decisions.

Suggested pages:

- Contribution overview
- Labels and triage
- RFC-lite process
- Maintainer and reviewer responsibilities
- Subsystem ownership
- Release and changelog workflow

### Suggestions

Purpose:

- Provide one discoverable path from idea to accepted work.

Suggested pages:

- Active suggestions
- Accepted suggestions
- Implemented suggestions
- Deferred or rejected suggestions
- Historical baseline
- Proposal template

### Roadmap

Purpose:

- Show where community ideas are headed without promising custom timelines.

Suggested pages:

- Now: accepted work ready for implementation
- Next: scoped proposals with dependencies
- Later: valuable ideas blocked by complexity, risk, or missing ownership
- Shipped: completed suggestions linked to releases

## Suggestion lifecycle

Use one lifecycle across GitHub Issues and Markdown records:

| State | Meaning | Primary record |
|---|---|---|
| `idea` | New suggestion submitted for discovery | GitHub Issue |
| `triage` | Maintainers check scope, duplicates, and security impact | GitHub Issue labels |
| `draft` | Author expands problem, alternatives, rollout, rollback, and validation | Issue or Markdown proposal |
| `review` | Maintainers and community review trade-offs | Issue/PR discussion |
| `accepted` | Decision is made and implementation can begin | Markdown record + linked issue |
| `in-progress` | Implementation PRs are active | GitHub Issue/PR |
| `implemented` | Released or merged with verification notes | Release notes + suggestion record |
| `deferred` | Valid idea, not ready due to dependencies or risk | Markdown record |
| `rejected` | Not aligned or superseded, with rationale | Markdown record |

## Suggestion page template

Every curated suggestion page should include:

```markdown
---
title: Short suggestion title
status: idea|triage|draft|review|accepted|in-progress|implemented|deferred|rejected
area: docs|dashboard|cli|helper-api|security|automation|community
owner: unassigned
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Short suggestion title

## Problem

What pain exists today?

## Existing work to reuse

Which existing files, scripts, services, frameworks, or prior suggestions should be reused?

## Proposal

What should change?

## Implementation outline

Small, reviewable steps.

## Security and privacy impact

Network exposure, auth, secrets, data handling, and rollback notes.

## Validation

Commands, manual checks, fixtures, or CI jobs that prove the change.

## Decision log

Accepted, deferred, rejected, or superseded rationale.
```

## Day-to-day tooling suggestions

### 1. Generated suggestion index

Add a small script that reads frontmatter from `suggestions/*.md` and generates:

- suggestion title
- status
- area
- owner
- last update
- linked implementation issue or PR

Output targets:

- `suggestions/index.md`
- optional JSON file for dashboard rendering

Why this helps:

- Contributors can browse by status without reading every file.
- Maintainers can spot stale accepted work.
- The website can show suggestion state without a database.

### 2. Duplicate suggestion detector

Add a local script that compares new suggestion titles and problem statements with existing records.

Useful signals:

- overlapping keywords
- same affected subsystem
- similar problem statement
- references to the same historical feature direction

Why this helps:

- Reduces repeated proposal churn.
- Encourages contributors to improve the canonical suggestion instead of creating parallel threads.

### 3. Suggestion quality lint

Add a lightweight check for:

- required frontmatter keys
- valid status values
- required body sections
- links that resolve inside the repository
- security and rollback notes for operational changes

Fit with existing tooling:

- Expose through `scripts/`.
- Add an optional `./tu-vm.sh` alias if it becomes common.
- Include in `scripts/pre-push-check.sh` after the rule set is stable.

### 4. Community digest

Extend daily or release-oriented reports with:

- new suggestions
- accepted suggestions without linked implementation
- stale review items
- recently shipped suggestions
- duplicate candidates

Fit with existing tooling:

- Reuse `scripts/daily-checkup.sh` style output.
- Optionally write a static JSON digest for the landing page.

### 5. Dashboard community panel

Add a read-only panel to the existing dashboard after the Markdown/GitHub process is stable.

Recommended content:

- latest shipped community item
- top accepted suggestions
- links to contribute, report a bug, and review security policy
- current release highlights

Guardrails:

- No unauthenticated control actions.
- No direct browser calls that leak private operator context.
- Cache or build static content where possible.

## Community governance suggestions

### Labels

Use a small shared label set:

- `suggestion`
- `triage`
- `accepted`
- `deferred`
- `rejected`
- `implemented`
- `needs-info`
- `area:docs`
- `area:dashboard`
- `area:cli`
- `area:helper-api`
- `area:security`
- `area:automation`

### Roles

Keep roles lightweight:

- **Maintainers** make final decisions and protect security posture.
- **Reviewers** provide subsystem-specific feedback.
- **Proposal champions** keep a suggestion moving through the lifecycle.
- **Operators/testers** validate real setup and day-to-day workflows.

### Decision rules

Accept suggestions that:

- improve operator or contributor experience,
- reuse existing components or mature frameworks,
- include validation and rollback,
- preserve privacy and LAN-first defaults,
- have clear ownership or a small implementation path.

Defer suggestions that:

- need a larger dependency decision,
- require new public services,
- cannot be validated safely yet,
- duplicate an existing accepted direction.

Reject suggestions that:

- weaken secure defaults,
- require mandatory external telemetry,
- replace working platform surfaces without clear migration value,
- introduce high maintenance burden for low community benefit.

## Implementation order

### Phase 1: Curate and standardize

- Declare this file as the canonical current blueprint.
- Add a suggestion page template or frontmatter convention.
- Update the hub/index pages to point contributors at the canonical path.
- Keep older suggestion files as historical context.

### Phase 2: Static website foundation

- Select MkDocs Material or VitePress.
- Create navigation for Install, Operate, Security, Community, Suggestions, and Roadmap.
- Migrate high-value pages from `README.md`, `docs/playbooks/`, and `suggestions/`.
- Add search and link checking.

### Phase 3: Automation for maintainers

- Add suggestion linting.
- Add duplicate detection.
- Generate suggestion indexes from frontmatter.
- Add community digest output.

### Phase 4: Dashboard visibility

- Add a read-only community panel to `nginx/html/index.html`.
- Pull from generated static JSON or helper-cached content.
- Link to issues, releases, roadmap, and security reporting.

### Phase 5: Dynamic community features only if needed

- Evaluate whether GitHub Issues and static website pages are insufficient.
- If needed, add `/community` as a separate app route.
- Keep operational controls separate from public community interactions.

## Success measures

- New contributors can find the suggestion process from the website home page.
- Duplicate suggestions are redirected to a canonical page.
- Accepted suggestions link to issues, PRs, validation notes, and releases.
- Maintainers can review community state without manually scanning every file.
- Operators retain the same secure default runtime behavior.

## Non-goals

- Replacing the existing dashboard before parity is proven.
- Building a custom voting or identity system before GitHub-native workflows are exhausted.
- Moving operational control endpoints into a public community surface.
- Requiring any SaaS dependency for local operation.

## Immediate next recommendations

1. Treat this blueprint as the current canonical suggestion set.
2. Keep `implementation-backlog.md` as the active implementation queue.
3. Add frontmatter to future suggestion pages.
4. Build the website from Markdown before introducing a custom app.
5. Automate indexing and duplicate checks once the frontmatter convention is stable.
