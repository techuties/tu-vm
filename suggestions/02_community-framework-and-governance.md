# Suggestion 02: Community Framework and Governance Model

## Objective

Create a sustainable community model that keeps TechUties VM open to contributions while maintaining security, quality, and roadmap coherence.

This framework is designed to fit the current repo and architecture:
- one primary operational script (`tu-vm.sh`)
- multiple service components (`nginx`, `helper`, `monitoring`, `tika-minio-processor`)
- practical docs (`README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`)

---

## What should not change

To avoid reinventing successful patterns, retain these foundations:

1. **LAN-first security posture as default**
   - Keep secure defaults and explicit opt-in for broader exposure.

2. **Script-first operations model**
   - Continue making `tu-vm.sh` the source of truth for common workflows.

3. **Operational transparency**
   - Keep changelog updates and status surfaces visible to users.

4. **Energy/resource awareness**
   - Continue evaluating features through laptop/home-lab constraints.

---

## Community operating model

## 1) Roles

Define lightweight role categories (can be informal at first):

- **Maintainers**
  - Merge and release authority
  - Security and architecture gatekeeping
- **Core contributors**
  - Frequent contributors with review privileges
  - Own selected subsystems
- **Contributors**
  - Submit issues, docs, code, testing feedback
- **Users/testers**
  - Validate releases and share operational reports

No heavy bureaucracy is required. The point is to clarify expectations.

## 2) Ownership by subsystem

Use a component ownership table (can live in README section for now):

- `tu-vm.sh` (operations and CLI UX)
- `helper/uploader.py` (control/status API)
- `nginx/` (networking, security boundaries, landing page)
- `monitoring/` + `scripts/daily-checkup.sh` (observability)
- `tika-minio-processor/` (document pipeline)

Each subsystem should have at least one primary and one backup reviewer.

## 3) Decision types

Split decisions into two lanes:

- **Fast lane (minor)**
  - docs improvements
  - non-breaking script quality changes
  - UI text and small UX improvements
- **Proposal lane (major)**
  - new services
  - network/security model changes
  - data model/storage behavior changes
  - breaking CLI or API changes

Major changes should go through a short written proposal.

---

## Proposal workflow (community RFC-lite)

Adopt a small template for non-trivial changes:

- Problem statement
- Why now
- Existing behavior and constraints
- Proposed change
- Security impact
- Resource impact (CPU/memory/disk)
- Migration/rollback
- Test plan

Keep proposals practical and short. The purpose is alignment, not ceremony.

---

## Contribution workflow framework

## 1) Issue taxonomy

Use clear labels:
- `kind:bug`
- `kind:feature`
- `kind:docs`
- `kind:security`
- `kind:performance`
- `kind:community`
- `priority:high|medium|low`
- `area:<subsystem>`

This helps route work and prevent duplicate efforts.

## 2) Pull request expectations

Minimum checklist:
- linked issue or proposal
- risk level stated (`low`, `medium`, `high`)
- test/verification steps provided
- changelog impact noted
- rollback notes for risky changes

## 3) Review standards

Require at least one reviewer for low risk and two for medium/high risk changes touching:
- security controls
- network exposure
- backup/restore
- data processing paths

---

## Quality and reliability framework

## 1) Definition of done (DoD)

A change is considered done when:
- behavior is documented (or intentionally unchanged)
- verification steps are reproducible
- security implications are acknowledged
- no regressions in core script flow (`start/stop/status/secure`)

## 2) Testing strategy tiers

- **Tier A**: lint/static checks, config syntax checks
- **Tier B**: smoke test commands (`status`, key endpoint probes)
- **Tier C**: scenario tests (service control, PDF pipeline, restore path)

Do not block all contributions on full end-to-end tests initially; phase it in.

---

## Release framework

## 1) Release channels

- **Canary/dev**: frequent updates for active contributors
- **Stable**: curated, validated set for general users

## 2) Release notes standard

Each release should include:
- user-visible changes
- operator-impacting changes
- security notes
- migration notes
- known limitations

`CHANGELOG.md` already exists and can be kept as the canonical record.

---

## Community health loops

To keep this community-based system alive long-term:

1. **Monthly "pain points" thread**
   - Gather top contributor friction points.

2. **"Good first ops issue" backlog**
   - Targeted tasks in docs, scripts, and tests for onboarding.

3. **Subsystem watchlist**
   - Flag stale areas where no one reviewed code recently.

4. **Recognition loop**
   - Highlight contributors in release notes or landing page section.

---

## Security guardrails for community contributions

Given this project exposes networked services, establish strict defaults:

- Never merge changes that weaken secure-by-default behavior unintentionally.
- For any networking change, include explicit threat and fallback notes.
- For control endpoints (`/control/*`, allowlist routes), require higher review rigor.
- Avoid adding public internet assumptions into default paths.

---

## Practical first implementation steps

1. Add a "Community Framework" section to root README.
2. Define issue/PR labels and enforce PR checklist.
3. Add subsystem ownership table.
4. Introduce proposal template for major changes.
5. Add release note checklist tied to `CHANGELOG.md`.

---

## Success signals

- More external PRs reaching merge quality with fewer iterations.
- Lower duplicate issue rate.
- Faster triage for bug reports.
- Better predictability of release quality and rollback behavior.
