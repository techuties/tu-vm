# Website Community Framework Suggestion

## Objective

Build a community-first website framework that turns TU-VM from a project page into a **participation platform**: clear knowledge flow, transparent decision-making, and shared ownership.

## Problem

Most technical projects fail community growth because:

- documentation is scattered,
- contribution paths are unclear,
- decisions happen in private channels,
- users cannot easily turn feedback into shipped improvements.

## Proposed framework

### 1) Structured content architecture

Create predictable website sections with a single purpose each:

- **Get Started**: install, run, first success in under 20 minutes.
- **How-To Guides**: task-focused flows (backup, secure mode, PDF pipeline, monitoring).
- **Reference**: command and configuration details (source of truth).
- **Community**: contribution guide, roadmap, office hours, governance.
- **Showcase**: real community use-cases and templates.

Design rule: each page must answer one primary user intent.

### 2) Community governance layer on the website

Publish transparent processes directly on the website:

- proposal lifecycle (draft -> review -> approved -> implemented),
- decision records for major architectural choices,
- ownership map for subsystems (who reviews what),
- monthly change log summaries aimed at contributors, not only users.

This reduces repeated debate and improves contributor trust.

### 3) Feedback ingestion framework

Standardize how website feedback enters the engineering loop:

- idea form with tags (docs, platform, security, workflows, UX),
- triage rubric (impact, complexity, urgency),
- public status board labels (planned, in progress, blocked, done),
- “why accepted / why deferred” rationale snippets.

### 4) Community knowledge loops

Add recurring loops that convert usage into reusable value:

- “What broke this week?” postmortem snippets (short and practical),
- monthly “top contributor insights,”
- reusable automation recipes submitted by the community,
- migration notes between releases.

## Technical implementation suggestions

- Use a docs-as-code model (Markdown + pull request review).
- Add page metadata fields for ownership and freshness:
  - `owner`,
  - `last_reviewed`,
  - `next_review_due`,
  - `stability` (experimental/stable/deprecated).
- Add a content linter in CI:
  - broken links,
  - missing metadata,
  - stale pages beyond review date.

## Rollout phases

### Phase A: Foundation

- Launch the content architecture and ownership metadata.
- Publish contribution paths and governance basics.

### Phase B: Community operations

- Add feedback ingestion and triage board links.
- Publish lightweight decision records and monthly updates.

### Phase C: Scale and optimize

- Add community showcases and automation recipe library.
- Measure participation and refine templates.

## Success metrics

- reduced repeat support questions for core setup flows,
- higher number of first-time contributors completing one accepted PR,
- lower cycle time from suggestion submission to triage decision,
- increased percentage of docs pages reviewed on schedule.

## Risks and mitigations

- **Risk**: governance overhead slows shipping.  
  **Mitigation**: lightweight templates and time-boxed review rules.
- **Risk**: stale community pages reduce trust.  
  **Mitigation**: enforce review-due checks in CI and assign explicit owners.
