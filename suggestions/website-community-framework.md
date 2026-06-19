# Website Suggestion: Community Framework and Governance

## Objective

Create a clear, lightweight, community-centered operating model for website and platform contributions that preserves quality, security, and predictable releases.

This framework is intentionally aligned with existing project characteristics:
- Script-first operations (`tu-vm.sh`)
- Existing status/control API surfaces (`helper/uploader.py`)
- Security-focused deployment posture (secure/public/lock modes)
- Existing docs and changelog practices (`README.md`, `CHANGELOG.md`)

## Foundations to keep (do not reinvent)

Historical suggestions repeatedly emphasized preserving these strengths:

1. Secure-by-default behavior
2. Operational simplicity through one main control surface
3. Transparent change communication through changelog and docs
4. Resource-aware design for laptop and home-lab environments

This proposal keeps all four as baseline guardrails.

## Recommended community system

Use a **GitHub-native, RFC-lite process**:

- GitHub Issues are the intake queue.
- GitHub Discussions, when enabled, are for early exploration.
- Markdown proposal pages in `suggestions/` are the durable design record.
- Pull requests implement accepted work and link back to the issue/proposal.
- Release notes and `CHANGELOG.md` close the loop when work ships.

This gives the community a transparent process without adding a separate proposal database, login system, or moderation surface.

## Community operating model

### Roles

Use lightweight role categories. They can be informal at first:

- **Maintainers**
  - Final merge and release authority
  - Security and architecture gatekeepers
- **Core contributors**
  - Frequent reviewers with subsystem familiarity
  - Own selected operational or docs areas
- **Contributors**
  - Submit issues, docs, code, and tests
- **Users/testers**
  - Validate releases and provide reproducible reports

### Subsystem ownership

Define an ownership map for faster review routing:

- `tu-vm.sh` (CLI workflows and operational UX)
- `helper/uploader.py` (status/control API contract)
- `nginx/` (access boundaries and landing/dashboard behavior)
- `scripts/` and `monitoring/` (diagnostics and observability)
- `tika-minio-processor/` (document pipeline reliability)
- Website/docs suggestion pages (`suggestions/` and docs site once added)

Each subsystem should have one primary owner and one backup reviewer.

### Suggested ownership table

| Area | Primary routing | Stronger review required when |
|------|-----------------|-------------------------------|
| `tu-vm.sh` | Operations maintainer | Start/stop, backup, restore, install, or security mode behavior changes |
| `helper/uploader.py` | API/status maintainer | `/control/*`, auth, status payload contract, or filesystem access changes |
| `nginx/` | Security/network maintainer | Public exposure, TLS, proxy, rate-limit, or allowlist behavior changes |
| `docker-compose.yml` | Platform maintainer | New services, volumes, ports, resource limits, or health dependencies change |
| `scripts/` | Tooling maintainer | CI, smoke, config, release, or pre-push workflow behavior changes |
| `docs/` and `suggestions/` | Docs/community maintainer | Governance, security guidance, or canonical proposal status changes |

## Decision lanes

### Fast lane (minor changes)
- Docs clarifications
- Non-breaking script refactors
- UI text and small UX improvements
- Small test additions

### Proposal lane (major changes)
- New services or major dependencies
- Security model or network exposure changes
- API contract breaking changes
- Behavioral changes in backup/restore or control flows
- Large website architecture migration decisions

Major changes should include a short proposal following a common template.

## Proposal template (RFC-lite)

Use this shape for significant changes:

1. Problem statement
2. Current behavior and constraints
3. Proposed change
4. Security impact
5. Resource impact (CPU, memory, disk)
6. Migration and rollback strategy
7. Test and verification plan
8. Documentation impact

This stays short and practical while improving alignment.

## Suggestion lifecycle

Use one status taxonomy everywhere: issues, labels, proposal frontmatter, generated website pages, and release notes.

| Status | Meaning | Exit condition |
|--------|---------|----------------|
| `idea` | Initial community request or rough concept | Duplicate check completed and scope clarified |
| `draft` | Proposal is being structured | Required sections are complete |
| `review` | Maintainers/community are evaluating | Decision recorded with rationale |
| `accepted` | Ready for implementation | Linked issue/PR plan exists |
| `implemented` | Shipped or merged into the documented release path | Release note or changelog reference exists |
| `deferred` | Valuable but not current priority | Revisit condition is written down |
| `rejected` | Not aligned or superseded | Rationale and alternatives are recorded |

### Duplicate and historical-suggestion check

Before a proposal moves from `idea` to `draft`, reviewers should check:

1. Open GitHub Issues with similar labels or keywords.
2. Existing Markdown files in `suggestions/`.
3. Historical roadmap items in `CHANGELOG.md`.
4. Existing implementation or shipped infrastructure listed in `implementation-backlog.md`.

If overlap exists, update the existing proposal, mark the new issue as related, or explicitly document why a separate proposal is justified.

## Contribution workflow standards

### Issue taxonomy

Use standard labels for triage consistency:
- `kind:bug`
- `kind:feature`
- `kind:docs`
- `kind:security`
- `kind:performance`
- `kind:community`
- `priority:high|medium|low`
- `area:<subsystem>`
- `status:idea|draft|review|accepted|implemented|deferred|rejected`
- `risk:low|medium|high`

### Pull request expectations

Minimum PR checklist:
- Linked issue/proposal
- Risk level stated (`low|medium|high`)
- Reproducible validation steps
- Changelog impact noted
- Rollback note for medium/high-risk changes

### Review rigor

Require stronger review depth for changes touching:
- Access controls and authentication paths
- Network boundary behavior
- Backup/restore logic
- Control endpoints under `/control/*`
- Any defaults that affect secure posture
- New services, persistent volumes, or background automation

## Definition of done

A change is done when:
1. Behavior is documented or intentionally unchanged
2. Verification steps are reproducible by other contributors
3. Security implications are acknowledged
4. Core operator flows keep working (`start`, `stop`, `status`, `secure`)
5. Community-originated work links back to the source issue/proposal
6. Accepted suggestions have a rollback or disablement note

## Release and communication framework

### Channels
- **Canary/dev**: frequent integration for active contributors
- **Stable**: curated releases with stronger validation

### Release note standard

Each release entry should include:
- User-visible changes
- Operator-impacting changes
- Security notes
- Migration notes
- Known limitations
- Community suggestions delivered, with issue/PR links where available

`CHANGELOG.md` remains canonical.

### Community decision log

For accepted, deferred, or rejected proposals, record:

- Date of decision.
- Decision owner or reviewer group.
- Short rationale.
- Related issue/PR links.
- Follow-up condition, if deferred.

This can live in the proposal Markdown until the volume justifies a generated decision-log page.

## Community health loops

To keep the ecosystem active:

1. Periodic pain-point roundup (docs, setup, operations)
2. A backlog of beginner-friendly tasks
3. Subsystem watchlist for stale ownership areas
4. Contributor recognition in release notes
5. Monthly review of duplicate proposals and unanswered issues
6. Maintainer retrospective on where automation created noise or saved time

## Security guardrails for community changes

Never merge changes that silently weaken defaults. For networking and control-path changes, require:
- Explicit threat notes
- Safe fallback behavior
- Clear rollback instructions
- Elevated reviewer attention

Suggested security escalation triggers:

- New externally reachable endpoint or widened bind address.
- Secret, token, credential, or backup behavior changes.
- New MCP/tool integration or workflow automation that can perform writes.
- Proposal changes that alter public/private mode expectations.
- Any suggestion that asks to collect telemetry or community analytics.

## Practical first implementation steps

1. Add this framework summary to main project docs navigation.
2. Establish the `status:*`, `area:*`, and `risk:*` labels used by the lifecycle.
3. Publish the subsystem ownership table with real maintainers or placeholders.
4. Add proposal frontmatter and required sections to canonical suggestion pages.
5. Generate a simple suggestion index by status from Markdown metadata.
6. Tie release checklist updates to `CHANGELOG.md` and Release Drafter notes.

## Success signals

- Lower duplicate issue rates
- Faster triage for regressions
- Higher first-pass PR quality
- More predictable release outcomes
- Higher percentage of accepted suggestions linked to implementation PRs
- Clearer contributor understanding of why proposals are accepted, deferred, or rejected
