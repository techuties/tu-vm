# Community System Framework

## Objective

Build a repeatable community process that turns suggestions into high-quality outcomes without bottlenecks, ambiguity, or duplicate effort.

The system should be GitHub-native at first, Markdown-backed for historical memory, and website-rendered for discoverability.

## Principles

1. **Reuse before invention**: GitHub Issues, Discussions, PRs, labels, CODEOWNERS, release notes, and static Markdown already cover much of the workflow.
2. **Traceability over ceremony**: every accepted suggestion should be traceable from proposal to PR to changelog.
3. **Security remains a gate**: community growth must not weaken LAN-first defaults, control-token handling, backups, or network boundaries.
4. **Small tools first**: validation scripts and generated indexes should come before databases, voting systems, or custom moderation platforms.
5. **Human decisions stay visible**: automation can suggest status, labels, and duplicates, but maintainers record the final rationale.

## Core lifecycle

Use a lightweight lifecycle inspired by established open-source governance patterns:

1. **Idea**
   - Opened as a GitHub issue, Discussion, or draft Markdown suggestion.
   - Contains the problem, intended users, and expected benefit.
2. **Discovery**
   - Contributor checks `suggestions/` for historical overlap.
   - Automation lists related files and likely duplicates.
3. **Draft**
   - Proposal uses the required section contract.
   - Includes reuse scan, risks, rollout, rollback, and acceptance criteria.
4. **Review**
   - Community feedback validates user value.
   - Maintainers validate scope, security, operations, and architecture.
5. **Decision**
   - Outcome is one of `accepted`, `deferred`, `rejected`, `implemented`, or `superseded`.
   - Rationale is recorded in the issue or suggestion page.
6. **Implementation**
   - Work is split into linked issues/PRs.
   - PRs include validation evidence and changelog impact.
7. **Release and retrospective**
   - Delivered suggestions are referenced in release notes.
   - Larger efforts capture lessons learned and follow-up work.

## Status taxonomy

Use a small controlled vocabulary:

| Status | Meaning |
|---|---|
| `draft` | Idea is being shaped and may be incomplete. |
| `review` | Proposal is ready for maintainer/community review. |
| `accepted` | Maintainers agree with direction and scope. |
| `deferred` | Valid idea, but not ready to schedule or implement. |
| `rejected` | Not aligned, too risky, or not worth pursuing; rationale required. |
| `implemented` | Delivered and linked to PR/release evidence. |
| `superseded` | Replaced by another suggestion; replacement link required. |

Avoid creating many near-identical statuses. More statuses create reporting overhead without improving decisions.

## Suggestion document contract

Every active suggestion should include:

```yaml
title: Short descriptive title
status: draft
area: community
owner: unassigned
reviewers: []
last_reviewed: null
related:
  - historical-suggestions.md
```

Required sections:

- **Problem statement**: what pain exists today?
- **Historical overlap**: what prior files, issues, or roadmap items were checked?
- **Existing solutions scan**: which frameworks, GitHub features, scripts, or TU-VM components can be reused?
- **Proposed solution**: what exactly changes?
- **Trade-offs**: what do we gain and lose?
- **Security and operations impact**: what can break or become riskier?
- **Rollout and rollback**: how to ship safely and undo if needed?
- **Ownership**: who drives and who reviews?
- **Acceptance criteria**: what proves this is done?
- **Success metrics**: how value is measured after release?

## Governance roles

### Maintainers

- Final decision makers for acceptance and scope boundaries.
- Own security, reliability, and architecture consistency.
- Record decisions for accepted, rejected, or superseded proposals.

### Domain reviewers

- Review subsystem-specific changes.
- Suggested domains:
  - `cli`: `tu-vm.sh`
  - `compose`: `docker-compose.yml`
  - `nginx`: dashboard, proxying, access boundaries
  - `helper`: `helper/uploader.py` and status/control contracts
  - `docs`: website, README, playbooks, suggestions
  - `pipeline`: `tika-minio-processor/`
  - `security`: secrets, tokens, allowlists, public exposure

### Community reviewers

- Test clarity, usability, onboarding, and operator value.
- Find duplicate or related historical suggestions.
- Suggest lower-maintenance alternatives.

### Proposal champions

- Author and iterate the suggestion.
- Keep links, status, and acceptance criteria current.
- Coordinate implementation tasks after acceptance.

## Decision lanes

### Fast lane

Use for low-risk work:

- Documentation clarification.
- Broken link fix.
- Small dashboard copy changes.
- Non-behavioral refactors.
- Additional validation around existing behavior.

Fast-lane changes can proceed directly through PR review if validation is clear.

### Proposal lane

Use for changes that affect:

- Network exposure.
- Authentication or control paths.
- Backup, restore, data retention, or secrets.
- New services or major dependencies.
- Dashboard behavior that changes operator workflows.
- Website framework adoption or information architecture changes.

Proposal-lane work needs a suggestion page or issue with the full contract.

## Decision scorecard

Score each review-ready proposal:

| Criterion | Guidance |
|---|---|
| Community impact | Does this help users or contributors repeatedly? |
| Operational safety | Does it preserve secure defaults and recoverability? |
| Reuse score | Does it extend existing tools/frameworks instead of building new ones? |
| Maintenance burden | Is the long-term ownership realistic? |
| Implementation clarity | Are acceptance criteria and rollback paths concrete? |

Accepted proposals should show high community impact, strong reuse, clear ownership, and manageable operational risk.

## Workflows to implement

### 1) Intake workflow

Trigger: new suggestion file or issue labeled as a suggestion.

Actions:

- Validate required sections.
- Detect likely duplicates.
- Suggest area labels from changed paths or keywords.
- Confirm the idea links to related historical files.

### 2) Review workflow

Trigger: status set to `review`.

Actions:

- Assign domain reviewers.
- Check scorecard criteria.
- Request missing rollback/security/test notes.
- Record decision rationale when status changes.

### 3) Implementation workflow

Trigger: status set to `accepted`.

Actions:

- Create or link implementation issues.
- Require PRs to reference the suggestion.
- Track validation evidence.
- Add changelog or release-note references.

### 4) Archive workflow

Trigger: status set to `implemented`, `rejected`, or `superseded`.

Actions:

- Link final decision or release evidence.
- Remove from active indexes.
- Keep searchable historical context.

## Metrics

Track these to keep the process healthy:

- Duplicate suggestion rate.
- Suggestions without owner or related-history check.
- Review-ready suggestions missing acceptance criteria.
- Accepted suggestions shipped in a release.
- Median time in `review`.
- First-time contributor PRs with complete validation notes.

Use metrics for process improvement, not contributor scoring.

## Risk controls

- No accepted proposal without rollback or disable notes.
- No production-impacting change without a validation path.
- Security review required for network, auth, data, secret, and control-plane changes.
- New dependencies must have a clear maintenance owner and upgrade path.
- Automation findings should be advisory unless the rule is precise and documented.

## Practical first implementation steps

1. Normalize the canonical suggestion pages with status metadata.
2. Add a suggestion template that includes historical-overlap and reuse-scan sections.
3. Add a lightweight duplicate report over `suggestions/`.
4. Generate an index grouped by status and area.
5. Publish the index through the chosen website framework.
6. Add a release-note convention for delivered community suggestions.
