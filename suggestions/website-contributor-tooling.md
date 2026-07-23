# Website Contributor Tooling and Preview Workflow

**Status:** Proposed

## Summary

Give contributors one predictable path from a local change to review-ready evidence:

1. identify the repository areas changed,
2. recommend the smallest trustworthy check set,
3. build a private website/docs preview when relevant, and
4. publish a concise result summary for reviewers.

This proposal extends the current scripts and GitHub workflow. It does not add a second issue tracker, suggestion database, authentication system, or executable plugin host.

## Historical overlap reviewed

This proposal consolidates and narrows ideas already present in:

- [`day-to-day-tooling.md`](./day-to-day-tooling.md), which records the shipped validation baseline;
- [`website-day-to-day-tooling.md`](./website-day-to-day-tooling.md), which mentions local docs preview;
- [`04-implementation-roadmap.md`](./04-implementation-roadmap.md), which calls for changed-doc preview guidance; and
- [`implementation-backlog.md`](./implementation-backlog.md), which prioritizes docs quality, live contract checks, and browser smoke coverage.

The focus here is the missing connection between those capabilities. New commands should orchestrate existing checks rather than reimplement them.

## Current repository baseline

The project already has most low-level building blocks:

- `./tu-vm.sh doctor` for host and configuration diagnostics;
- [`scripts/check-config.sh`](../scripts/check-config.sh) for configuration policy;
- [`scripts/smoke-test.sh`](../scripts/smoke-test.sh) for static and optional live checks;
- [`scripts/helper-contract-check.sh`](../scripts/helper-contract-check.sh) for helper API behavior;
- [`scripts/pre-push-check.sh`](../scripts/pre-push-check.sh) as the broad local wrapper;
- [`scripts/validate_status_full_contract.py`](../scripts/validate_status_full_contract.py) for the canonical status fixture;
- [CI](../.github/workflows/ci.yml), docs link checking, optional pre-commit, and Release Drafter; and
- GitHub Issue and pull request templates described in [`CONTRIBUTING.md`](../CONTRIBUTING.md).

The remaining friction is discoverability and scope. A contributor must currently know which scripts apply, whether Docker or live services are required, and how to present the results.

## Suggestion 1: Change-aware contributor check planner

### Problem

Running every check for every edit is slow, while guessing a narrow command can miss cross-component contracts. Documentation-only contributors should not need a live stack, but helper, Nginx, and Compose changes need stronger evidence.

### Proposed interface

Add a non-interactive mode under the existing control surface:

```text
./tu-vm.sh contribute-check --base origin/dev
./tu-vm.sh contribute-check --base origin/dev --plan
./tu-vm.sh contribute-check --base origin/dev --format json
```

`--plan` prints the selected checks and reasons without executing them. Human-readable output is the default; JSON supports CI and future website summaries. A direct script may implement the logic, but `tu-vm.sh` remains the discoverable entry point.

### Initial impact map

| Changed path | Recommended evidence |
|---|---|
| Root Markdown, `docs/**`, `suggestions/**` | Markdown structure, relative links, scoped external link check |
| `docker-compose.yml`, `env.example` | Compose render, `check-config --ci`, smoke test |
| `tu-vm.sh`, `scripts/*.sh` | `bash -n`, targeted command help/smoke, static smoke test |
| `helper/**` | Python compile, helper contract check, `/status/full` fixture validation |
| `nginx/**` | Nginx/static smoke checks; browser smoke when available |
| `.github/**` | YAML parse plus workflow-specific validation |
| Cross-cutting or unknown files | Existing full `pre-push-check.sh` |

The map should be declarative data consumed by both local tooling and CI. It must not become a second source of truth for service dependencies or API schemas.

### Guardrails

- Use Git's changed-file list only; do not inspect untracked files outside the repository.
- Fail closed to the full safe check set for an unknown path.
- Never read or print `.env` values.
- Explain every selected and skipped check.
- Return stable exit codes: `0` passed, `1` validation failed, `2` invocation/setup error.
- Provide `--no-live` by default; live probes require an explicit flag.
- Keep the planner advisory until its path mapping has been compared with CI results on representative changes.

### Acceptance criteria

- Documentation-only changes receive a useful plan without requiring Docker services.
- Compose, helper, and Nginx changes cannot silently omit their existing contract checks.
- The JSON result includes changed areas, selected checks, status, duration, and remediation text, but no environment values or command output that may contain secrets.
- Running the recommended full mode remains behaviorally equivalent to the current pre-push wrapper.

## Suggestion 2: Reproducible website and documentation preview

### Problem

Markdown review in a source diff does not reveal broken navigation, inaccessible heading structure, mobile layout issues, or framework-specific rendering. Public third-party preview deployments can also leak private repository content or operational details.

### Proposed workflow

Adopt preview tooling only when the static documentation framework described in [`website-and-docs-framework.md`](./website-and-docs-framework.md) passes its adoption gates.

The selected framework should expose:

```text
./tu-vm.sh docs-preview
./tu-vm.sh docs-build
```

The commands are aliases for the framework's standard development and production build commands. Contributors should still be able to use the upstream package commands directly.

For pull requests:

1. build the static site from the pull request commit;
2. run link, heading, accessibility, and small-screen smoke checks against that build;
3. package the static output as a short-lived GitHub Actions artifact;
4. add paths changed, check status, and artifact name to the job summary; and
5. do not publish a public preview URL by default.

Forked pull requests receive read-only permissions and no repository secrets. If maintainers later enable hosted previews, deployment must require an explicit trusted-branch gate and automatic expiry.

### Preview content boundaries

- Build only version-controlled public documentation.
- Exclude `.env`, generated support bundles, backups, logs, and runtime state.
- Replace live dashboard controls with documented screenshots or inert fixtures; a docs preview must never point at an operator control endpoint.
- Mark generated pages and stale content clearly.
- Use one editable Markdown source. Do not copy `suggestions/` into a second hand-maintained website tree.

### Acceptance criteria

- A contributor can preview the site with one documented command.
- CI proves that a production build succeeds before a docs change is merged.
- Preview artifacts contain no secret-like values according to an allowlist-based content check.
- Reviewers can identify changed rendered pages from the job summary.
- The preview remains optional until a static docs framework is adopted; the current Nginx operational dashboard is unaffected.

## Suggestion 3: GitHub-native contributor hub

### Problem

Contributor guidance exists, but users must move among the root README, contribution guide, issue chooser, playbooks, and release history. Building a custom task board would duplicate GitHub and require synchronization.

### Proposed website projection

Publish a static contributor hub that links to authoritative repository surfaces:

- **Report or suggest:** GitHub Issue forms; security reports route to [`SECURITY.md`](../SECURITY.md).
- **Find work:** saved GitHub Issue queries for `good first issue`, `needs-info`, `documentation`, and subsystem labels.
- **Prepare a change:** persona-specific checklists for docs, Compose, helper, Nginx, and shell changes.
- **Validate:** commands selected by `contribute-check --plan`.
- **Follow delivery:** linked pull requests, Releases, and `CHANGELOG.md`.
- **Get operational context:** stable anchors in [`docs/playbooks/`](../docs/playbooks/README.md).

The first version is hand-curated Markdown with stable links. A later generator may read public GitHub metadata at build time, but the generated output stays read-only and degrades to static links when GitHub is unavailable.

### Content ownership

Extend the ownership map only after real GitHub handles replace the placeholder in [`CODEOWNERS`](../CODEOWNERS). Each contributor page should identify:

- the authoritative source file;
- the owning subsystem or reviewer role;
- the validation command;
- a `lastReviewed` value once frontmatter is adopted; and
- the issue link for corrections.

Do not publish personal schedules, response-time promises, contributor rankings, or inferred activity profiles.

### Acceptance criteria

- A first-time contributor reaches an issue form or a starter-task query in two navigational choices or fewer.
- Every task view links back to GitHub as the system of record.
- Closing or relabeling an issue cannot leave an authoritative duplicate in a local database.
- The hub remains useful when GitHub API calls fail.

## Suggestion 4: Accessibility and localization readiness

### Problem

The historical corpus repeatedly requests accessible controls, but content contribution standards are underspecified. Translation should not begin until ownership exists, yet avoidable authoring choices can make later localization expensive.

### Proposed authoring baseline

Apply these checks to the canonical website pages before expanding to historical files:

- one page title and a valid heading hierarchy;
- descriptive links instead of generic "click here" text;
- alt text for informative images and empty alt text for decorative images;
- keyboard-reachable navigation and visible focus;
- status communicated with text or icons as well as color;
- no essential text embedded only in screenshots;
- plain language, defined acronyms, and a small project glossary;
- sentence-level content that does not depend on fixed visual position; and
- code samples separated from prose so translators never alter commands.

### Translation adoption gate

Enable a second locale only when:

1. at least two community contributors can review that locale;
2. install, security, and recovery pages have named technical reviewers;
3. the selected static framework supports locale-specific navigation and fallback;
4. untranslated or stale pages show the source language and review date; and
5. CI can detect missing internal links and duplicated page identifiers per locale.

Use the framework's native internationalization model or a proven translation platform only after this gate. Do not build a custom translation editor.

### Acceptance criteria

- Canonical contributor pages pass automated accessibility checks and a keyboard smoke test.
- Glossary terms and command names remain consistent.
- Mobile pages do not clip code, tables, navigation, or action links at the supported viewport.
- A future locale can be added without changing operational routes or duplicating source-language ownership.

## Suggestion 5: Review evidence summary

### Problem

Reviewers often reconstruct validation context from comments and logs. A concise, consistent summary reduces repetitive questions without hiding raw evidence.

### Proposed output

Both local and CI runs should produce the same conceptual fields:

```json
{
  "revision": "<commit>",
  "areas": ["docs", "nginx"],
  "checks": [
    {"name": "relative-links", "status": "passed"},
    {"name": "browser-smoke", "status": "not-configured"}
  ],
  "live_services_used": false
}
```

CI renders this as a readable job summary. The pull request template continues to hold human context: operator impact, security implications, rollout, and rollback. Automated output must not edit pull request descriptions or post repetitive comments.

### Acceptance criteria

- A reviewer can distinguish passed, failed, skipped, and not-configured checks.
- Every skip includes a reason and the command needed for stronger validation.
- The summary links to logs inside the same CI run.
- JSON output is versioned before external tools depend on it.

## Delivery sequence

### Stage 1: Document and validate the impact map

- Compare the proposed path map with current CI and pre-push behavior.
- Add machine-readable plan output behind an explicitly experimental flag.
- Collect false-skip and unnecessary-check examples from pull requests.

### Stage 2: Make the planner the local entry point

- Expose stable human and JSON output through `tu-vm.sh`.
- Document setup errors and non-live defaults.
- Add the planner to the contributor hub.

### Stage 3: Add static website previews

- Proceed only after a documentation framework is selected.
- Build private CI artifacts and changed-page summaries.
- Add narrow accessibility and responsive smoke checks.

### Stage 4: Publish read-only community projections

- Add saved issue queries, ownership information, and release traceability.
- Add localization only after the reviewer and CI adoption gate is met.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The path map skips a necessary check | Unknown and cross-cutting paths fall back to the full suite; compare advisory plans with CI before enforcement |
| Planner logic duplicates CI | Store one declarative impact map and keep check implementations in existing scripts |
| Public previews expose private content | Default to short-lived GitHub artifacts with read-only permissions and no secrets |
| Generated community pages become stale | GitHub remains authoritative; static links remain as the failure mode |
| Tooling becomes a prerequisite for simple docs edits | Keep direct commands documented and provide a Docker-free docs path |
| Translation creates unsafe stale instructions | Require locale reviewers, visible review dates, and source-language fallback |
| Metrics create contributor surveillance | Measure aggregate workflow outcomes only; do not rank or profile people |

## Rollback

Each layer is independently removable:

- disable the planner and continue using `scripts/pre-push-check.sh`;
- remove preview jobs without changing source Markdown;
- serve the contributor hub as plain repository Markdown; and
- disable a locale while retaining source-language pages.

No stage changes the helper API, Nginx control routes, Docker Compose service model, or GitHub Issue system of record.

## Success signals

- Fewer review rounds caused by missing validation evidence.
- Lower rate of CI failures that a local recommended check would have caught.
- More first-time contributions that use the correct template and validation path.
- Shorter time spent by maintainers explaining which check to run.
- No secret exposure or public preview incident.
- Accessibility defects are found before website publication.
