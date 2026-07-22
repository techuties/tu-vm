# Suggestion: Community Operations Toolkit

## Purpose

Turn the repository's existing issue, diagnostics, and playbook capabilities into
a clear community support path that can later be published on a static website.

GitHub Issues remain the system of record. The website is a discoverable,
read-only guide and index; it is not a second support queue.

## Historical baseline

The repository already provides:

- GitHub forms for bugs and suggestions;
- documented labels such as `triage`, `needs-info`, and `good first issue`;
- stale-item automation;
- `CONTRIBUTING.md`, `SECURITY.md`, and operator playbooks;
- `./tu-vm.sh doctor --json`, configuration checks, smoke tests, and helper
  contract checks; and
- Release Drafter and changelog linkage.

Do not recreate these as custom forms, a voting API, a support database, or a
second label taxonomy. The remaining problems are discoverability, consistently
safe diagnostic evidence, and keeping known resolutions connected to issues and
releases.

## Proposed website page set

The future docs framework should render these pages from one editable Markdown
source tree.

### `community/support/index.md`

The support landing page should route people by intent:

- operational problem: open the relevant playbook first;
- reproducible bug: search existing issues, gather safe evidence, then use the
  bug form;
- usage question: use the repository's configured discussion channel;
- feature idea: use the suggestion form;
- suspected vulnerability: use the private path in `SECURITY.md`.

The page should show the exact boundary between public and private reports and
must not copy security contact details that could drift from `SECURITY.md`.

### `community/support/gather-evidence.md`

This page should explain, in order:

1. how to record the TU-VM version or commit;
2. how to run `doctor --json`, `check-config`, and the relevant smoke check;
3. what must never be pasted into a public issue;
4. how to generate and inspect a support bundle after that tool ships; and
5. how to attach evidence while preserving reproducible steps in the issue body.

The detailed support-bundle contract is defined in
[Contributor Tooling Framework](./contributor-tooling-framework.md). Until it is
implemented, the page should recommend individual existing commands rather than
claiming the bundle is available.

### `community/support/known-issues.md`

Use a generated or tightly curated index, not copied troubleshooting prose. Each
entry should contain:

- a short symptom and affected release range;
- subsystem and status;
- a safe confirmation command;
- a link to the canonical playbook or issue;
- fixed-in release or workaround expiry; and
- last verified date.

Entries should disappear or move to an archive when their affected release is
no longer supported. The linked issue or playbook remains the detailed source.

### `community/support/triage-guide.md`

This maintainer-facing page should map the existing labels to actions:

| Signal | Action |
|---|---|
| Security-sensitive content | Remove public exposure where possible and route to `SECURITY.md`; do not quote the sensitive value. |
| Missing reproduction or version | Apply `needs-info` and request only the smallest missing evidence. |
| Known issue | Link the canonical issue/playbook and record the duplicate relationship. |
| Confirmed regression | Add subsystem and release labels, then link an implementation issue or pull request. |
| Documentation gap | Fix the canonical page and link the change back to the report. |
| Suitable first contribution | Add `good first issue` only when scope and acceptance checks are explicit. |

Avoid response-time promises until maintainers have measured capacity. Publish a
review cadence only when an owner rotation exists.

### `community/support/resolution-index.md`

Close the loop without creating a separate knowledge database. A resolution
entry should link:

- original issue;
- validating pull request or commit;
- changelog or release;
- affected and fixed versions; and
- canonical playbook or documentation.

Generate this view from repository-owned metadata where practical. If generation
is not reliable, keep the first version as a short curated index with a named
owner and review date.

## Content and automation model

### Single-source rules

- Commands are sourced from scripts or command inventories, not retyped across
  several pages.
- Security routing links to `SECURITY.md`.
- Issue status and discussion stay on GitHub.
- Operational steps link to `docs/playbooks/`.
- Release state links to `CHANGELOG.md` or GitHub Releases.
- Website pages never include submitted diagnostic archive contents.

### Safe automation

Start with pull-request-time validation:

- required metadata for known-issue entries;
- affected-version format and valid status values;
- relative-link checks;
- duplicate canonical issue URLs; and
- stale `last_verified` dates as warnings.

Do not scrape private reports, automatically publish issue bodies, or ingest
support bundle contents into the website build.

## Contributor path

Support work should be easy to turn into a first contribution:

1. a maintainer marks a confirmed documentation or playbook gap;
2. the issue names one canonical file and a reproducible acceptance check;
3. the contributor updates that source and links the issue;
4. CI validates links and repository checks; and
5. the resolution index links the shipped fix after release.

This keeps contribution work scoped and prevents support answers from being
copied into disconnected documents.

## Rollout

### Phase 1: connect existing assets

- Publish the support landing and evidence pages using current commands.
- Add stable links to existing playbooks, issue forms, and security policy.
- Document the current label-to-action map without introducing new labels.

### Phase 2: add privacy-safe evidence

- Implement and security-test the support bundle.
- Update the bug form and evidence page only after the command ships.
- Pilot known-issue metadata with a small set of recurring problems.

### Phase 3: generate indexes

- Generate known-issue and resolution views from validated metadata.
- Add search and filters in the selected static docs framework.
- Review metrics before adding triage automation.

Rollback is low risk: remove generated navigation and continue using GitHub
Issues, current playbooks, and existing diagnostics directly.

## Risks and mitigations

- **Stale website guidance:** validate links and dates; keep details in canonical
  scripts, policies, issues, and playbooks.
- **Accidental disclosure:** collect support data by allowlist, require local
  review, and never auto-publish.
- **Duplicate support queues:** make every website action route to the existing
  GitHub channel.
- **Maintainer burden:** start with routing pages and a small curated index;
  automate only measured repetition.
- **Metrics becoming surveillance:** use aggregate repository workflow data, not
  local product telemetry or bundle contents.

## Acceptance criteria

- A user reaches the correct public or private reporting channel in two links or
  fewer from the support landing page.
- Every shown command exists and is covered by a documentation/runtime check or
  a release review.
- Known-issue entries have affected versions, status, canonical link, and
  verification date.
- No page duplicates issue discussion, security contact data, or full playbook
  steps.
- The support path works with JavaScript disabled and remains keyboard
  navigable in the selected static framework.
- Removing the website layer does not remove issue history or operational
  guidance.

## Success measures

- Fewer `needs-info` cycles per reproducible bug.
- Fewer duplicate issues for indexed known problems.
- Shorter time from confirmed docs gap to merged correction.
- Higher first-time contributor completion rate on support-derived tasks.
- Zero confirmed public secret disclosures caused by the recommended evidence
  workflow.
