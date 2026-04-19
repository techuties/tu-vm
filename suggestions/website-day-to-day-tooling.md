# Website Day-to-Day Tooling Suggestions

This proposal focuses on reducing manual overhead for maintainers and contributors who work on the TU-VM website/dashboard.

It uses the existing project style: shell-first operations, pragmatic validation, and incremental hardening.

## Goals

- Make common website changes safer and faster.
- Catch regressions before merge.
- Keep onboarding simple for community contributors.
- Align with current repository workflow (`tu-vm.sh`, existing scripts, changelog discipline).

## 1) Add a minimal frontend quality gate

Current website code in `nginx/html/index.html` is a single-page HTML/CSS/JS bundle.

### Suggestion

Add lightweight checks without introducing heavy framework migration:

- HTML lint (structure issues, duplicate IDs, accessibility basics)
- JavaScript lint (no accidental globals, syntax/style consistency)
- Link and route sanity check for dashboard paths

### Practical implementation

- Add script: `scripts/check-dashboard.sh`
- Run checks:
  - HTML parsing/lint step
  - `node --check` or ESLint on extracted JS block
  - basic URL path checks for `/status/*`, `/control/*`, `/whitelist/*`

### Why this matters

- Prevents accidental breakage of control/status flows.
- Keeps “single file dashboard” approach maintainable without full rewrite.

## 2) Add snapshot-style smoke test for key UI states

The platform already has backend smoke scripts; add one for frontend rendering behavior.

### Suggestion

Add a Playwright-based smoke profile that validates:

- Dashboard loads and shows service cards.
- Status badges update from placeholder values.
- Announcements dropdown opens/closes.
- Access control panel token input renders.

### Practical implementation

- New script: `scripts/dashboard-smoke.sh`
- Use a small Playwright test file stored under `scripts/tests/`
- Run headless against `https://127.0.0.1` with host header override

### Reuse opportunities

- Reuse patterns from existing smoke checks (`scripts/langgraph-e2e-smoke.sh`).
- Reuse browserless service path if desired for consistency.

## 3) Introduce website component extraction (without framework lock-in)

Avoid immediate migration to React/Vue while still reducing complexity.

### Suggestion

Split `nginx/html/index.html` into generated parts:

- `nginx/html/src/styles.css`
- `nginx/html/src/template.html`
- `nginx/html/src/dashboard.js`

Then generate `index.html` via a simple build script.

### Practical implementation

- Script: `scripts/build-dashboard.sh`
- Output target remains `nginx/html/index.html` for runtime compatibility
- Add `scripts/check-dashboard.sh` to ensure generated file is up-to-date

### Benefit

- Easier review and community contribution.
- Keeps deploy/runtime unchanged (still static file via Nginx).

## 4) Make contribution workflow explicit for website changes

### Suggestion

Create a lightweight contribution checklist embedded in existing docs:

- changed endpoints listed?
- accessibility quick check done?
- mobile viewport checked?
- smoke scripts passed?
- changelog updated if user-facing behavior changed?

### Practical implementation

- Add a short “Website contribution checklist” section to `README.md`
- Optional: add pull request template checkbox section for website changes

## 5) Automate changelog entry generation for dashboard changes

There is already `scripts/changelog-refresh.sh`.

### Suggestion

Tag dashboard commits with `dashboard:` prefix and surface them automatically in the “Unreleased” block.

### Practical implementation

- Extend existing changelog refresh script to group entries by area:
  - dashboard
  - control/api
  - docs
  - ops

### Benefit

- Community can quickly understand web-facing changes and rationale.

## 6) Provide seed issue labels and triage rules for community suggestions

### Suggestion

Adopt labels for suggestion lifecycle:

- `suggestion:website`
- `suggestion:tooling`
- `suggestion:community`
- `status:needs-repro`
- `status:accepted`
- `status:planned`

### Benefit

- Improves contributor feedback loop.
- Makes roadmap transparent without heavy project tooling.

## 7) Add “local dev mode” helper for dashboard iteration

### Suggestion

Provide one command to iterate on the website quickly:

- validate syntax
- rebuild generated `index.html` (if split structure adopted)
- optionally reload nginx container

### Practical implementation

- `./tu-vm.sh dashboard-dev` (or script under `scripts/`)
- Keep this optional and non-invasive

## Suggested adoption order

1. Add `check-dashboard.sh` gate.
2. Add dashboard smoke test.
3. Split source files + build script.
4. Add contribution checklist and commit/changelog conventions.
5. Add local dev helper command.

This sequence delivers immediate risk reduction first, then maintainability improvements.
