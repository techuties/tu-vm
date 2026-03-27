---
title: Community Governance Framework
slug: community-governance-framework
summary: A practical governance model for community-led roadmap, standards, and release decisions.
status: proposed
priority: high
---

# Community Governance Framework

## Why this suggestion exists

TU-VM already has strong technical foundations. The missing multiplier is a repeatable way for the community to:

- propose changes
- debate trade-offs
- make decisions transparently
- maintain quality as contributors scale

Without a governance framework, useful ideas can stall, duplicate, or conflict.

## Problem statement

Current documentation describes features and operations well, but there is no formal process for:

- who approves architectural changes
- how breaking changes are evaluated
- what "accepted quality" means for new contributions
- how community members can earn trust and higher responsibility

## Suggested framework

### 1) Working groups

Create focused groups with clear scope:

- **Platform WG**: core runtime, Docker Compose, networking, security controls
- **AI & Data WG**: Open WebUI, Ollama flows, Tika pipeline, Qdrant integrations
- **Ops & Reliability WG**: monitoring, backups, incident playbooks, release safety
- **Docs & Community WG**: onboarding, tutorials, issue triage, contributor support

Each WG has:

- 2 maintainers minimum
- explicit ownership list
- monthly public summary

### 2) Proposal lifecycle (light RFC)

Add a simple lifecycle for meaningful changes:

1. **Draft**: problem, context, alternatives, risks, migration plan
2. **Review**: async comments + WG review window
3. **Decision**: Accepted / Deferred / Rejected with rationale
4. **Implementation**: tracked tasks and owner
5. **Post-check**: verify goals and document outcomes

### 3) Decision policy

- Minor changes: maintainer approval
- Cross-component changes: at least 1 approval from each affected WG
- Security-sensitive changes: mandatory security checklist + rollback notes
- Breaking changes: migration guide required before merge

### 4) Trust ladder for contributors

Define transparent contributor progression:

- **Contributor** -> first accepted contributions
- **Regular** -> recurring quality contributions and review participation
- **Maintainer** -> ownership and approvals in scoped areas

Use contribution quality and consistency, not only volume.

## Deliverables

- `governance.md` (roles, decision rights, escalation model)
- `proposal-template.md` (standardized RFC format)
- `CODEOWNERS` alignment with working groups
- `decision-log` section (linked decisions and rationale)

## Implementation steps

1. Define WG scopes and initial maintainers.
2. Publish lightweight RFC template.
3. Require RFC for cross-component or breaking changes.
4. Add decision log references in changelog entries for major changes.
5. Reassess process after 2 release cycles.

## Success metrics

- Reduction in duplicate/overlapping proposals
- Faster decision turnaround for cross-cutting changes
- Higher review participation from non-core contributors
- Lower rollback rate for major features

## Risks and mitigations

- **Risk**: process becomes too heavy  
  **Mitigation**: keep RFC short and required only for meaningful changes

- **Risk**: maintainer bottlenecks  
  **Mitigation**: minimum of 2 maintainers per WG and clear backups

- **Risk**: unclear ownership boundaries  
  **Mitigation**: explicit scope map and periodic ownership review

## Dependencies

- Agreement from current maintainers
- Minimal documentation maintenance discipline

## Rollback plan

If the framework slows contributions, reduce approval gates to:

- one maintainer approval for non-breaking changes
- optional RFC for medium-scope changes

while keeping the decision log intact.
