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

## Suggestion lifecycle

Use one public lifecycle for issues, suggestion Markdown, roadmap entries, and release notes:

| State | Meaning | Required evidence |
| --- | --- | --- |
| `proposed` | Idea has enough detail for triage. | Problem, affected users, expected outcome. |
| `triaged` | Maintainers confirmed category, duplicate status, and risk level. | Labels, area, and duplicate check. |
| `accepted` | Maintainers agree the project should pursue it. | Decision note, owner or next step, validation expectation. |
| `in-progress` | Implementation or documentation work is active. | Linked issue/PR and scope. |
| `implemented` | Work shipped or docs were published. | Commit, release note, changelog, or merged PR link. |
| `deferred` | Useful idea, but not a current priority. | Rationale and revisit trigger. |
| `superseded` | Covered by another suggestion or existing implementation. | Link to replacement or shipped evidence. |

The website should display these states consistently. Avoid separate status vocabularies for the dashboard, docs site, and GitHub labels.

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

## Website community surfaces

The community system should be visible on the website through a few durable pages:

### Suggestions index

Purpose:
- list active suggestions by status,
- link to historical baseline and implementation backlog,
- explain how to submit a new idea without duplicating prior work.

Minimum fields:
- title,
- status,
- area,
- risk level,
- owner or next reviewer,
- last meaningful update,
- linked evidence.

### Decision log

Purpose:
- preserve why accepted, rejected, deferred, or superseded decisions were made,
- make old tradeoffs searchable for new contributors,
- reduce repeated architecture debates.

Reuse path:
- start with Markdown entries linked from suggestion pages,
- later generate a static index from front matter if volume grows.

### Community health snapshot

Purpose:
- show maintainers and contributors whether the suggestion system is moving,
- keep stale backlogs visible,
- recognize non-code contribution.

Suggested metrics:
- open suggestions by status,
- duplicate/superseded count,
- implemented suggestions per release,
- oldest untriaged suggestion,
- contributor acknowledgments.

Keep metrics local and repository/GitHub-derived. Do not add third-party analytics to the self-hosted dashboard by default.

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

## Duplicate check standard

Before accepting a new suggestion, reviewers should check:

1. The canonical bundle in [`README.md`](./README.md).
2. Historical themes in [`website-historical-baseline.md`](./website-historical-baseline.md).
3. Current priorities in [`implementation-backlog.md`](./implementation-backlog.md).
4. Open GitHub Issues using the `suggestion` label.
5. Recently merged PRs and `CHANGELOG.md` entries.

If a suggestion overlaps prior work, mark it `superseded` or merge it into the nearest active proposal instead of creating a parallel roadmap item.

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

## Definition of done

A change is done when:
1. Behavior is documented or intentionally unchanged
2. Verification steps are reproducible by other contributors
3. Security implications are acknowledged
4. Core operator flows keep working (`start`, `stop`, `status`, `secure`)

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

`CHANGELOG.md` remains canonical.

## Community health loops

To keep the ecosystem active:

1. Periodic pain-point roundup (docs, setup, operations)
2. A backlog of beginner-friendly tasks
3. Subsystem watchlist for stale ownership areas
4. Contributor recognition in release notes

## Security guardrails for community changes

Never merge changes that silently weaken defaults. For networking and control-path changes, require:
- Explicit threat notes
- Safe fallback behavior
- Clear rollback instructions
- Elevated reviewer attention

## Practical first implementation steps

1. Add this framework summary to main project docs navigation.
2. Normalize issue labels and suggestion statuses against the lifecycle table above.
3. Publish subsystem ownership table.
4. Add or update a proposal template for major changes.
5. Tie release checklist updates to `CHANGELOG.md`.
6. Publish the suggestions index and decision log in the selected static docs framework.

## Success signals

- Lower duplicate issue rates
- Faster triage for regressions
- Higher first-pass PR quality
- More predictable release outcomes
