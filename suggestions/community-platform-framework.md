---
title: Community Platform Framework
description: A practical framework for building a contribution-friendly, website-centered community system.
---

# Community Platform Framework

## Goal

Create a community-based system where users can share improvements, workflows, troubleshooting patterns, and reusable building blocks without creating governance or maintenance overhead.

## What to build

### 1) Documentation and community website layer

Recommended framework stack:

- **Docusaurus** (primary): versioned docs, search, plugin ecosystem, markdown-native workflows.
- **GitHub Discussions** (community Q&A and ideation): keeps conversation close to code.
- **Docs-as-code workflow**: suggestion pages, runbooks, recipes, and architecture notes stay in this repository.

Why this is constructive:

- Reuses existing markdown practices.
- Enables quick publishing from pull requests.
- Creates a visible, searchable source of truth for contributors.

### 2) Community content architecture

Suggested information structure:

1. **Getting Started**
   - First-run setup
   - Secure mode defaults
   - Tier 1 vs Tier 2 usage patterns
2. **Recipes**
   - Common workflow recipes (RAG setup, MinIO sync strategies, OCR-heavy processing)
   - Performance tuning recipes (battery mode, low-memory setup)
3. **Troubleshooting Playbooks**
   - Symptom -> diagnostics -> fix mapping
   - Links to `tu-vm.sh` commands and relevant logs
4. **Community Showcase**
   - Shared n8n workflows
   - Compose overlays
   - Dashboard customization examples
5. **Suggestion Registry**
   - Lifecycle: proposed -> accepted -> implemented -> archived

### 3) Contribution framework

Define a lightweight governance model:

- **RFC-lite template** for larger changes (problem, proposal, migration, rollback).
- **Suggestion template** for incremental improvements.
- **Implementation labels** (`good-first-issue`, `needs-testing`, `ops-impact`).
- **Monthly community triage** to review new suggestions and prioritize by impact.

## Reuse map (avoid reinventing)

Use existing platform components as the base:

- **Helper API** for status data and simple suggestion metadata endpoints.
- **Nginx landing page** as temporary entry point before full documentation site rollout.
- **Changelog + README** as the source for "already solved" areas and historical context.

## Suggested minimal rollout

### Phase A (quick wins)

1. Publish docs website skeleton and import current README/Quick Reference content.
2. Add contribution templates for suggestions and RFC-lite proposals.
3. Start a suggestion lifecycle board using labels and milestones.

### Phase B (community acceleration)

1. Add searchable "recipes" and troubleshooting playbooks.
2. Launch monthly "community improvements" release notes section.
3. Introduce maintainer rotation for triage to reduce bus factor.

### Phase C (ecosystem)

1. Add a curated workflow gallery (n8n and integration snippets).
2. Add compatibility matrix by hardware profile and deployment style.
3. Add extension registry for reusable automation modules.

## Success metrics

- Number of community-authored suggestions merged per month.
- Time from suggestion opened to first maintainer response.
- Share of docs traffic landing on recipes/troubleshooting pages.
- Number of reusable workflows adopted by multiple users.
