# Website Community Framework

This proposal defines a practical framework for making the TU-VM website a community-centered system while reusing existing project assets.

## Objectives

1. Enable community members to contribute ideas and improvements with minimal friction.
2. Keep decisions transparent and traceable.
3. Ensure suggestions become actionable work items, not dead-end discussions.
4. Preserve TU-VM security and reliability standards while scaling participation.

## Information architecture (website)

Suggested top-level website/community sections:

1. **Home**
   - Mission, value proposition, and quick links to run TU-VM.
2. **Get Started**
   - Install paths (quickstart/manual), common first tasks, and safe defaults.
3. **Community**
   - Contribution paths, governance basics, and communication channels.
4. **Suggestions**
   - Public suggestion index with statuses and decision rationale.
5. **Roadmap**
   - Near-term and medium-term priorities tied to released versions.
6. **Trust & Operations**
   - Security model, quality gates, uptime/health posture, release practices.

## Community system model

Use a lightweight lifecycle for every suggestion:

1. **Proposed** - initial idea submitted
2. **Triaged** - validated for scope/fit
3. **Planned** - accepted with implementation direction
4. **In Progress** - active delivery work
5. **Shipped** - implemented and documented
6. **Declined** - not moving forward (with reason)

Each suggestion should include:

- Problem statement
- User/community impact
- Technical approach
- Dependencies and risks
- Security/reliability considerations
- Acceptance criteria

## Governance workflow

Define community roles with clear responsibilities:

- **Contributors**: submit suggestions, provide testing feedback, contribute docs/code.
- **Maintainers**: triage suggestions, align scope with architecture and security.
- **Reviewers**: validate implementation quality, rollout safety, and documentation completeness.

Decision rules:

- Require at least one maintainer + one reviewer sign-off for status changes to Planned.
- Require test/validation evidence for status change to Shipped.
- Require decline reason for any suggestion marked Declined.

## Reuse of current TU-VM components

The website/community framework should leverage existing building blocks:

- **Helper API + dashboard** for live service health and operational summaries.
- **n8n** for automating suggestion intake, reminders, and status sync.
- **MCP Gateway + LangGraph Supervisor** for controlled automation actions and auditable write paths.
- **CHANGELOG + scripts** as official evidence of shipped outcomes.

## Suggested UI components

1. **Suggestion Board**
   - Filter by status, area (security, UX, docs, automation), and release target.
2. **Decision Log**
   - Timeline view of accepted/declined decisions with rationale.
3. **Implementation Evidence Panel**
   - Links to commits, release notes, checks, and health/smoke outputs.
4. **Community Onboarding Widget**
   - “First contribution” steps mapped to docs/tasks.

## Success criteria

- Community members can discover, submit, and track suggestions without private context.
- Maintainers can process suggestions using a repeatable governance path.
- Shipped suggestions link to concrete implementation evidence.
- Website content remains aligned with actual platform behavior and release history.
