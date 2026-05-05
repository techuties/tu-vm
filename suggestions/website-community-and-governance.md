# Website Community and Governance Suggestions

This document outlines how to create a community-based system around TU-VM without adding unnecessary complexity.

## 1) Community model: docs-first, workflow-enabled

The project already has strong technical capabilities (n8n, AFFiNE, helper API, MCP gateway).  
Use those capabilities to support community workflows rather than building custom systems from scratch.

Recommended model:
- Markdown-first contributions in Git.
- Lightweight role-based governance.
- Automated triage and contributor support through existing automation services.

## 2) Community roles

Define simple, practical roles:
- **Maintainers**: approve roadmap and releases.
- **Reviewers**: validate technical correctness and security impact.
- **Contributors**: submit docs, examples, and fixes.
- **Community stewards**: moderate discussions and organize feedback.

Keep role descriptions on the website to set expectations early.

## 3) Governance artifacts to publish on website

Minimum set:
1. Contributor Guide (how to contribute safely)
2. Code of Conduct (behavior standards and enforcement path)
3. Security Reporting Policy (private disclosure instructions)
4. Decision Log (major architecture and policy decisions)
5. Roadmap and RFC process (how ideas move to implementation)

These can be markdown pages in the website/docs app.

## 4) Suggestion intake process (non-fragmented)

To avoid duplicate ideas:
- Use one structured template for all suggestions:
  - Problem statement
  - Existing solutions evaluated
  - Proposed change
  - Risks and rollback plan
  - Effort estimate (S/M/L)
- Route suggestions through a single intake channel (for example, one issue label or one form).
- Link accepted suggestions to implementation tasks and changelog entries.

## 5) Community features that are high impact

### A) "Use-case cookbook" section
- Real examples (private AI chat, local RAG, workflow automation).
- Copy-paste safe defaults.
- Troubleshooting for common failures.

### B) "Service profiles" for daily operations
- Profile presets:
  - Battery saver
  - RAG mode
  - Automation mode
  - Full stack mode
- Each profile documents exactly which services should run.

### C) "Known good templates"
- n8n workflows
- Open WebUI tool/function snippets
- MinIO + Tika ingestion examples
- AFFiNE workspace templates

## 6) Trust and safety recommendations

- Keep moderation and reporting links visible in footer + community pages.
- Establish clear response times for moderation/security reports.
- Add "community health metrics" (response time, resolved suggestions, active contributors).
- Keep public transparency while protecting sensitive operational details.

## 7) Integration with existing stack

Leverage what already exists:
- **n8n**: automate suggestion triage, notifications, and status updates.
- **AFFiNE**: internal collaborative drafting before docs merge.
- **MCP gateway**: controlled integrations for internal tooling and assistants.
- **Helper API**: expose public-safe project metadata if needed.

Do not expose control endpoints or privileged APIs in public docs routes.

## 8) Milestones

Milestone 1 (foundation):
- Publish governance pages + contribution path.
- Launch community docs section with starter use-case cookbook.

Milestone 2 (engagement):
- Add recurring "community suggestion review" cycle.
- Publish monthly roadmap status and top community wins.

Milestone 3 (scale):
- Introduce formal RFC flow for larger changes.
- Track contributor onboarding and time-to-first-merged-contribution.
