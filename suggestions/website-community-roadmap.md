# Website Community Roadmap (Constructive Suggestions)

This roadmap proposes practical improvements to the TU-VM website/dashboard with a strong community-first focus.

## Historical baseline (already implemented)

The following capabilities already exist and should be reused instead of rebuilt:

- Service dashboard with Tier 1/Tier 2 control actions
- Health/status endpoints and live service probing
- Announcements panel and update management section
- Access-control UI (control token + allowlist)
- Pipeline explainers (LLM-to-n8n and document processing)

These suggestions extend that foundation rather than replacing it.

---

## Suggestion 1: Community Feedback Panel on the Website

### Goal
Create a structured place for operators and contributors to submit improvement ideas without leaving the dashboard context.

### Proposal
- Add a "Community Feedback" section to the website with:
  - Suggestion title
  - Problem statement
  - Expected benefit
  - Category (UI, security, docs, operations, integrations)
- Store submissions in a durable path (for example via helper API + PostgreSQL table or append-only file store).
- Expose a read-only "Top Suggestions" list ordered by votes/recent activity.

### Why this helps
- Reduces random ad-hoc requests across channels
- Makes recurring pain points visible
- Creates transparent prioritization

---

## Suggestion 2: Suggestion Voting + Status Workflow

### Goal
Turn ideas into a visible lifecycle so the community can track progress.

### Proposal
For each suggestion, display a status:

- `new`
- `triaged`
- `planned`
- `in-progress`
- `released`
- `declined` (with reason)

Add lightweight voting:
- One vote per authenticated operator identity (or device token in self-hosted mode)
- Optional weight for maintainers/admins

### Why this helps
- Avoids duplicate proposals
- Gives contributors clear signals on what is actively considered
- Builds trust through transparent decision logs

---

## Suggestion 3: "What Changed" Website Card Powered by Changelog

### Goal
Help users discover improvements already shipped (to prevent reinvention).

### Proposal
- Add a dashboard card that parses recent entries from `CHANGELOG.md` and shows:
  - latest version
  - top 3 highlights
  - links to operational commands for each change
- Include a "related suggestion" link when a release corresponds to prior community input.

### Why this helps
- Existing solutions become easier to find
- Operators learn features earlier
- New suggestions become better informed

---

## Suggestion 4: Community Playbooks and Runbook Snippets

### Goal
Make day-to-day operational work easier for all operators.

### Proposal
- Add a website area with quick action playbooks:
  - "Service down: fast recovery"
  - "Safe update flow"
  - "RAG troubleshooting"
  - "MCP/LangGraph chain smoke check"
- Each playbook should include copy-ready commands and expected output examples.

### Why this helps
- Reduces toil and repeated troubleshooting
- Lowers onboarding time for new community maintainers
- Standardizes incident handling

---

## Suggestion 5: Community Integrations Catalog (MCP/Tools)

### Goal
Create a reusable catalog of integrations instead of custom one-off setup guides.

### Proposal
- Add a curated "Integrations" view with standard metadata:
  - Name
  - Purpose
  - Required env vars
  - Security notes
  - Example workflows
  - Health-check command
- Start with core integrations already in repo: n8n, MinIO, AFFiNE, Qdrant, Tika.

### Why this helps
- Reuses proven patterns
- Improves consistency and safety
- Accelerates community contributions

---

## Suggestion 6: Accessibility + UX Hardening

### Goal
Improve usability for all community users.

### Proposal
- Add keyboard navigation for all interactive controls
- Improve ARIA labels for status badges, dropdowns, and control buttons
- Ensure color is not the only status indicator
- Add responsive refinements for smaller devices

### Why this helps
- Better inclusivity
- Fewer operator mistakes
- Better support for mobile/tablet management scenarios

---

## Suggested success metrics

- Suggestion-to-triage median time
- Duplicate suggestion rate (should trend down)
- Runbook usage count
- Mean time to recover common incidents
- Percentage of releases linked to community suggestions
