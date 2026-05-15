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

## Suggestion archive and anti-duplication workflow

The existing `suggestions/` directory is already a large historical archive. The community system should make that archive useful rather than adding more parallel documents with the same recommendation.

### Intake rule

Before a new website/community suggestion is accepted for discussion, the submitter or triage maintainer should check:

1. `suggestions/README.md` and `suggestions/index.md`
2. `suggestions/historical-suggestions-baseline.md`
3. `suggestions/implementation-backlog.md`
4. active GitHub Issues labeled `suggestion` or `enhancement`
5. recently shipped items in `CHANGELOG.md`

### Canonicalization rule

When overlap exists:

- **Duplicate**: link to the canonical suggestion and close or mark as duplicate.
- **Partial overlap**: merge useful details into the canonical file and note the source.
- **Superseded idea**: keep the old file for history, but add a clear pointer to the newer recommendation.
- **Implemented idea**: move the action item into `implementation-backlog.md` under completed/superseded with the relevant file or PR reference.

This protects the community from re-litigating the same framework choices and gives new contributors a reliable starting point.

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

## Website/community feature framework

The community-facing website should focus on discoverability and workflow clarity, not replace GitHub as the issue tracker.

### Core pages

1. **Start here**
   - install path
   - service model
   - "where to ask for help" links
2. **Contribute**
   - issue templates
   - PR expectations
   - local checks and review standards
3. **Suggestions**
   - historical archive
   - active proposal index
   - duplicate/superseded mapping
4. **Roadmap**
   - accepted next work
   - shipped community requests
   - deferred ideas with rationale
5. **Operations**
   - day-to-day commands
   - troubleshooting playbooks
   - status endpoint contract references

### Community interaction surfaces

- Use GitHub Issues for formal suggestions.
- Use Discussions for early design exploration when enabled.
- Use Markdown proposal pages for durable decisions and implementation guidance.
- Use release notes and `CHANGELOG.md` to close the loop after accepted ideas ship.

### Moderation and safety boundaries

- Keep control/admin operations private and token-gated.
- Do not expose operator telemetry publicly by default.
- Require explicit maintainer approval for suggestions that change networking, authentication, backup/restore, or service startup behavior.
- Prefer static website content for community pages so public information can be reviewed before publication.

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
2. Establish issue labels and a PR checklist.
3. Publish subsystem ownership table.
4. Add a proposal template for major changes.
5. Tie release checklist updates to `CHANGELOG.md`.

## Success signals

- Lower duplicate issue rates
- Faster triage for regressions
- Higher first-pass PR quality
- More predictable release outcomes
