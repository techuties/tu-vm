# Suggestion 03: Day-to-Day Tooling and Automation (Contributor Velocity)

## Goal

Make contributor and maintainer work easier by adding practical tooling that reduces repetitive manual steps, while preserving TU-VM's security and reliability posture.

## Current baseline strengths

- Strong operational scripts already exist under `scripts/`
- Good diagnostics and smoke checks are already documented
- Changelog and quick reference are maintained

This is a strong foundation; the recommendation is to standardize contributor tooling around it.

## Recommended tooling package

### 1) Standard task runner (`just` or `make`)

Create one entrypoint for frequent actions so contributors do not memorize many commands.

Example command groups:

- `just check` -> syntax checks and compose validation
- `just smoke` -> local smoke workflow
- `just docs-check` -> markdown lint/link checks (when docs site is introduced)
- `just suggestions-lint` -> quality checks for suggestion files (see below)

Benefit: lower onboarding friction and fewer command mistakes.

### 2) Pre-commit automation

Adopt lightweight pre-commit hooks for:

- trailing whitespace and EOF newline normalization,
- basic Markdown linting for consistency,
- shell script syntax checks (`bash -n`) for changed `.sh` files,
- optional Python syntax checks for changed Python files.

Benefit: catches quality issues early before CI and review.

### 3) Suggestion quality gates

Add a script that validates each file in `suggestions/` includes:

- goal/problem statement,
- recommendation section,
- implementation steps,
- risks/mitigations,
- status marker (`draft`, `review`, `accepted`).

Benefit: consistent proposal quality across community submissions.

### 4) Daily suggestion digest script

Create a small script that summarizes:

- newly added suggestion files,
- recently updated proposals,
- proposals pending review.

This can feed maintainers during standups/weekly planning and can later power dashboard or chat assistant summaries.

### 5) PR templates for suggestion-driven changes

Provide PR checklist prompts such as:

- "Which suggestion does this implement?"
- "Is this backward compatible?"
- "What operational validation was run?"

Benefit: traceability from proposal -> implementation.

## Suggested minimal implementation sequence

1. Add task runner with alias commands wrapping existing scripts.
2. Add lightweight pre-commit setup.
3. Add suggestion quality checker script.
4. Add suggestion digest script and optional cron integration.
5. Add/update PR templates and contribution guide references.

## Risks and mitigations

1. **Risk: perceived process overhead**
   - Mitigation: keep checks fast and scoped to changed files.
2. **Risk: contributor pushback on tooling installs**
   - Mitigation: provide one-line install bootstrap and fallback commands.
3. **Risk: false positives in linting**
   - Mitigation: start with minimal rules and tighten incrementally.

## Success indicators

- Lower reviewer time spent on formatting/syntax feedback.
- Faster first-time contributor merge cycle.
- Clear mapping from community proposal to shipped change.
