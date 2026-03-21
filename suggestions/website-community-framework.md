---
title: Community Website Suggestion Framework
status: proposed
priority: high
---

# Community Website Suggestion Framework

## Goal

Create a community-based website workflow where suggestions move from idea to shipped feature with clear ownership, feedback, and traceability.

## Core framework

## 1) Suggestion lifecycle (website-native)

Each suggestion should move through structured stages:

1. **Intake** - community submits suggestion using a standard template
2. **Validation** - duplicate check against historical suggestions
3. **Discussion** - comments, clarifications, and alternatives
4. **Prioritization** - score by impact, effort, and alignment
5. **Implementation** - linked to code changes and changelog updates
6. **Retrospective** - mark shipped/rejected and record learnings

## 2) Information architecture for website pages

Recommended content pages:

- `/suggestions` - searchable list of all suggestions
- `/suggestions/[id]` - detail page with status timeline
- `/suggestions/tags/[tag]` - grouped views (security, ux, performance, docs)
- `/suggestions/archive` - historical closed suggestions
- `/contribute/suggestions` - submission guide and template

## 3) Canonical suggestion schema

Use a consistent metadata block in each suggestion markdown file:

```yaml
id: SG-2026-001
title: Add community voting dashboard
status: proposed
owner: community
tags: [community, website, ux]
created_at: 2026-03-21
updated_at: 2026-03-21
related_files: [helper/uploader.py, nginx/index.html]
```

This enables static indexing and predictable rendering.

## 4) Prioritization model

Score every suggestion from 1-5 across:

- Community impact
- Implementation complexity
- Operational risk
- Reuse of existing components
- Security implications

Weighted score example:

`priority_score = impact*3 + reuse*2 - complexity - risk - security_penalty`

Higher scores move to implementation queue first.

## 5) Community governance model

Define roles:

- **Contributor**: proposes and comments
- **Maintainer**: validates, tags, prioritizes
- **Reviewer**: checks technical/security fit
- **Moderator**: handles conduct and discussion quality

Rules:

- no hidden decisions; every status change is documented
- rejected suggestions require rationale
- approved suggestions require implementation owner

## 6) Recommended technical implementation options

### Option A (low-friction, markdown-first)

- Static site generator (Docusaurus/Nextra)
- Markdown suggestions in repo (this folder)
- Build-time index generation
- GitHub Discussions for long-form threads

Best when you want low maintenance and high transparency.

### Option B (dynamic workflow)

- Next.js frontend
- Database-backed suggestions (PostgreSQL/Supabase)
- API-driven voting, moderation, and sorting
- Background jobs for digests and stale-item checks

Best when you need richer interaction and fine-grained analytics.

## 7) Accessibility and quality requirements

- keyboard navigable suggestion cards and filters
- color-independent status indicators (icon + text)
- descriptive ARIA labels for status timelines and vote controls
- semantic headings and readable contrast standards

## 8) Integration with current repository patterns

To avoid reinventing:

- expose suggestion status through helper API style endpoints
- reuse daily cron check style for stale suggestion alerts
- reuse announcement stream for newly approved/shipped suggestions

## Success criteria

- Suggestions are searchable and deduplicated.
- Every accepted suggestion has a traceable implementation link.
- Community can see why items were approved, delayed, or rejected.
- Operational load for maintainers stays low through automation.
