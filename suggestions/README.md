# Suggestions Hub

This folder contains structured, implementation-ready suggestions for improving the TU-VM website and community workflow.

## Why this exists

Before adding new ideas, we checked existing project history (README, dashboard behavior, changelog) to avoid duplicating work.  
The suggestions here build on already shipped capabilities such as:

- Tiered service model (always-on + on-demand)
- Dashboard service controls and announcements
- Update-management and health-check workflows
- MCP Gateway + LangGraph governance path
- Document processing and RAG pipeline

## Suggestion documents

1. [website-community-roadmap.md](./website-community-roadmap.md)  
   Community-first website roadmap and feature proposals aligned with current architecture.

2. [website-framework-and-tooling.md](./website-framework-and-tooling.md)  
   Recommended frameworks and engineering tooling for maintainable website evolution.

3. [implementation-backlog.md](./implementation-backlog.md)  
   Prioritized implementation backlog with acceptance criteria and rollout guardrails.

## Suggested process for future community proposals

Use this lightweight lifecycle to keep suggestions constructive and actionable:

1. **Problem statement**  
   Describe the user pain and current workaround.
2. **Reuse check**  
   Confirm whether similar behavior already exists in dashboard/helper scripts/changelog.
3. **Proposal draft**  
   Include UX flow, data model changes, security considerations, and success metrics.
4. **Pilot**  
   Release behind a feature flag for a small operator group.
5. **Production**  
   Promote after validation and update docs/changelog.

This keeps the system community-driven while reducing reinvention and drift.
