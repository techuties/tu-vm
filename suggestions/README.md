---
title: Community Suggestions Hub
status: active
owner: community
---

# Community Suggestions Hub

This folder is the single source of truth for **constructive, implementation-ready suggestions**.

## Why this exists

- Prevent duplicate ideas and repeated design debates.
- Keep a historical trail of suggestions, decisions, and outcomes.
- Make it easy for contributors to propose improvements without deep repo knowledge.

## File index

1. [historical-patterns-from-project.md](historical-patterns-from-project.md)
   - What is already built and should be reused first.
2. [website-community-framework.md](website-community-framework.md)
   - Recommended architecture for a community-based website suggestion system.
3. [tooling-day-to-day-operations.md](tooling-day-to-day-operations.md)
   - Practical automation and tools for daily contributor workflows.
4. [implementation-roadmap.md](implementation-roadmap.md)
   - Phased execution path with clear technical checkpoints.

## Suggestion status model

Use one of these statuses in future suggestion documents:

- `proposed` - idea is drafted but not reviewed
- `reviewing` - gathering feedback, validating feasibility
- `approved` - accepted and ready to implement
- `in-progress` - implementation underway
- `shipped` - deployed and documented
- `rejected` - not moving forward (keep reason in file)

## Contribution format (for new suggestion files)

Every suggestion should include:

1. Problem statement
2. Proposed approach
3. Reuse check (what already exists in this repository)
4. Technical impact (files/services changed)
5. Risks and mitigations
6. Success criteria

This structure keeps suggestions practical and implementation-friendly.
