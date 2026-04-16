# Community Suggestions Framework (Website-Focused)

This folder captures structured suggestions for evolving TU-VM with a community-driven system while reusing existing platform building blocks.

## Why this exists

The project already has strong foundations:

- Landing page + helper API (`nginx/html/index.html`, `helper/uploader.py`)
- Workflow automation and guardrails (`mcp-gateway/`, `langgraph-supervisor/`)
- Collaboration space (`AFFiNE`)
- Operational scripts and daily checks (`scripts/`)

To avoid re-inventing the wheel, proposals in this folder are designed to extend those assets instead of introducing unrelated stacks.

## Historical signal used

Suggestions in this folder explicitly build on:

- Existing architecture and Tier 1/Tier 2 model in `README.md`
- Existing dashboard/service-control capabilities
- Existing suggestion-like roadmap entries in `CHANGELOG.md` ("Future Enhancements")
- Existing workflow diagnosis suggestion patterns in `mcp-gateway/app.py`

## Document map

1. `website-community-framework.md`
   - Core framework for a community suggestion portal integrated into current website/dashboard.
2. `community-workflow-and-governance.md`
   - End-to-end intake, triage, voting, and decision governance model.
3. `tooling-and-day2-operations.md`
   - Tools and automations to reduce day-to-day operational friction for maintainers and contributors.
4. `implementation-roadmap.md`
   - Phased execution plan with acceptance criteria and rollout gates.

## Working rules for future additions

- Prefer extending existing services before adding new containers.
- Keep suggestion metadata machine-readable (YAML front matter + status fields).
- Use reversible rollout (feature flags, read-only first, then writes).
- Every accepted suggestion should map to:
  - owner,
  - measurable success metric,
  - rollback path.
