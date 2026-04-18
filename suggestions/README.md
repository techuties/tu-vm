# Suggestions Hub

This folder contains structured, implementation-ready suggestions focused on building a community-driven website and contribution system for TU-VM.

## Why this exists

The project already has strong technical foundations (Nginx landing page, helper API, Open WebUI, MCP Gateway, LangGraph Supervisor). These suggestions are designed to **extend what exists** instead of replacing it.

## Current state check

- No prior `/suggestions/` history was present when this folder was initialized.
- Existing project docs were reviewed to avoid duplicated ideas and to align with current architecture.

## Suggestion files

1. `website-community-framework.md`
   - Recommended website architecture and content framework.
   - How to integrate community contribution flows without re-platforming.

2. `website-tools-and-automation.md`
   - Tooling that reduces day-to-day maintenance overhead.
   - Lightweight automation for triage, docs quality, and release visibility.

3. `website-community-governance.md`
   - Suggestion lifecycle (intake to accepted/rejected).
   - Roles, moderation, quality bars, and decision rules.

4. `website-implementation-roadmap.md`
   - Phased implementation plan with concrete deliverables.
   - KPIs, risk controls, and operational checkpoints.

## How to use this folder

- Start with `website-implementation-roadmap.md` for execution order.
- Use `website-community-framework.md` to shape information architecture.
- Apply `website-tools-and-automation.md` to remove operational friction.
- Govern changes via `website-community-governance.md`.

## Contribution format for future suggestions

When adding future files here, keep a consistent template:

1. Problem statement
2. Proposed solution
3. Reuse of existing TU-VM capabilities
4. Implementation details
5. Risks and mitigations
6. Success metrics

