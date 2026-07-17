# Website Day-to-Day Tooling for Community Operations

## Status

**Proposed.** Adopt in small slices after the Markdown contract in
[`website-community-pages.md`](./website-community-pages.md) is accepted.

## Objective

Reduce repeated maintainer work while keeping review decisions human,
explainable, and reversible.

TU-VM already has Issue Forms, pull request templates, pre-commit, Lychee,
Release Drafter, Dependabot, smoke checks, and a canonical operator CLI. The
tooling plan should extend those assets instead of adding a bot platform or a
second task runner.

## Tool selection principles

1. Prefer a maintained ecosystem tool for generic Markdown, YAML, links,
   accessibility, and dependency updates.
2. Write repository code only for TU-VM-specific metadata and index generation.
3. Run the same checks locally and in CI.
4. Make generation deterministic and review generated changes.
5. Start advisory automation as non-blocking; enforce it only after existing
   content has been normalized.
6. Never let automation accept, reject, or silently close an idea.

## Recommended toolchain

| Need | Reuse or adopt | Purpose |
|---|---|---|
| Suggestion intake | Existing GitHub Issue Form | Required fields and duplicate-search acknowledgment |
| Workflow | GitHub labels and Project views | Triage queue, ownership, and planning |
| Metadata validation | JSON Schema plus `check-jsonschema` | Enforce frontmatter types and lifecycle values |
| Markdown style | `markdownlint-cli2` or equivalent pre-commit hook | Consistent headings, lists, and code fences |
| Links | Existing Lychee config/workflow | Internal and external link health |
| Prose guidance | Vale, initially advisory | Project terms, plain language, and inclusive wording |
| Static site | MkDocs Material | Navigation, local search, and static build |
| Browser confidence | Playwright plus axe-core | Navigation, responsive layout, keyboard flow, and accessibility |
| Dependency updates | Existing Dependabot | Build-action and package updates |
| Release linkage | Existing Release Drafter and PR keywords | Connect implementation to Issues and releases |

Do not adopt all tools in one change. Metadata validation, links, and a clean
site build provide the first useful gate; prose and browser checks can follow.

## One contributor entrypoint

Extend the existing `tu-vm.sh` interface rather than requiring contributors to
learn `make`, `just`, package-manager scripts, and raw tool commands.

Suggested commands:

```text
./tu-vm.sh docs setup       # install pinned development dependencies
./tu-vm.sh docs serve       # local preview with file watching
./tu-vm.sh docs check       # metadata, Markdown, links, and static build
./tu-vm.sh docs build       # reproducible production output
./tu-vm.sh suggestions list --status triaged
./tu-vm.sh suggestions check [paths...]
./tu-vm.sh suggestions index --check
```

Each command should be non-interactive by default, return a meaningful exit
code, print actionable file-and-line errors, and support `--help`. The wrapper
may delegate to pinned tools; it should not reimplement them.

## Suggestion validation

The repository-specific validator should:

- parse YAML frontmatter safely without evaluating tags;
- validate against the accepted schema;
- reject duplicate IDs and unknown statuses/themes;
- require a source Issue for new records;
- verify `related` and `supersedes` IDs exist;
- detect supersession cycles;
- require decision rationale for terminal decision states;
- require implementation and release evidence for `implemented`;
- verify required body headings;
- ensure dates are valid and `last_reviewed` is not before `created`; and
- emit concise errors suitable for local use and CI annotations.

Support two modes:

- `check <changed paths>` for fast pre-commit feedback;
- `check --all` for repository-wide CI integrity.

Do not infer missing metadata or rewrite contributor files during validation.

## Deterministic website generation

A small TU-VM-specific generator may create:

- status board data and Markdown;
- decision and archive indexes;
- recently updated suggestions;
- related-suggestion backlinks; and
- a machine-readable public feed containing non-sensitive metadata.

Requirements:

- identical input produces byte-identical output;
- sort order is explicit and stable;
- generated files include a header that points to source records;
- `--check` fails when committed generated output is stale;
- private Issue data and environment details are never fetched or embedded;
- GitHub API failure falls back to repository metadata; and
- generation is unit-testable without network or Docker.

If the static-site framework can generate a view directly at build time, prefer
that over committing duplicate Markdown indexes.

## Triage assistance without automated judgment

### Safe automation

- Apply a `suggestion` label through the existing Issue Form.
- Suggest component labels from explicit form answers or file ownership.
- Alert on missing required information.
- Present possible duplicate links for maintainer review.
- Route security-sensitive content to the documented private reporting path.
- Remind owners when `last_reviewed` exceeds an agreed policy threshold.

### Unsafe automation to avoid

- Closing an Issue based only on text similarity.
- Computing an opaque priority score from reactions.
- Treating age as evidence of low value.
- Posting comments on every metadata change.
- Sending proposal text to external AI services without explicit consent.
- Publishing private Discussions, security reports, or contributor email data.

GitHub reactions and Project fields can inform prioritization, but maintainers
should record the final rationale in the suggestion.

## Review and release workflow

1. Contributor opens an Idea / suggestion Issue.
2. Triage identifies related records and adds ownership/theme labels.
3. A maintainer or contributor creates/updates one curated Markdown record.
4. CI validates schema, links, style, and site build.
5. A decision updates status and rationale in the same record.
6. Implementation PR uses `Fixes #` or `Refs #` and links the suggestion ID.
7. Release Drafter and `CHANGELOG.md` record shipped behavior.
8. The suggestion becomes `implemented` only after delivery and validation
   links are present.

## CI lanes

Keep feedback proportional to the change:

### Fast pull request lane

- changed-file metadata validation;
- Markdown style;
- internal links;
- static site build; and
- generated-index freshness.

### Full website lane

- repository-wide metadata and links;
- browser navigation and local search;
- axe accessibility scan;
- mobile viewport smoke check; and
- inspection for unexpected third-party requests.

Cache dependencies by lockfile, but never cache generated site output as the
source of truth.

## Operational reporting

Generate a quiet maintainer digest on demand or on the existing automation
cadence:

- new submissions awaiting triage;
- accepted items without implementation links;
- in-progress items without recent review;
- implemented items missing release evidence;
- deferred items whose re-open condition is now satisfied; and
- broken relationships or stale generated views.

Default to one summary artifact. Avoid per-item notifications unless a
maintainer subscribes.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Existing files fail a new schema | Normalize canonical records first; validate changed files before enforcing all files |
| Toolchain becomes hard to install | Pin dependencies and wrap them with `tu-vm.sh docs setup` |
| CI becomes slow | Separate changed-file and full-site lanes; cache by lockfile |
| Duplicate matcher produces false positives | Suggestions only; human makes merge/close decision |
| Generated indexes drift | Deterministic generator and `--check` mode |
| Hosted services leak browsing data | Local search and no third-party analytics by default |
| Automation hides community judgment | Record all decisions and overrides in human-readable Markdown |

## Acceptance criteria

- A new contributor can preview and check a page from one documented
  entrypoint.
- Local and CI checks use the same pinned versions and rules.
- Validation errors identify the file, field, expected value, and remediation.
- No status board or decision index requires manual synchronization.
- Automation never makes a terminal lifecycle decision.
- Website tests cover keyboard navigation, mobile layout, local search, and
  unexpected external requests.
- Maintainers can disable each automation independently without losing source
  records.

## Related suggestions

- [Website and documentation framework](./website-and-docs-framework.md)
- [Website community pages](./website-community-pages.md)
- [Website community governance](./website-community-governance.md)
- [Implementation backlog](./implementation-backlog.md)
