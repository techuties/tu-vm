# Suggestion 03: Developer Experience and Tooling

## Objective

Make contribution work easier, safer, and faster by adding practical day-to-day tools that fit the current stack:
- Docker Compose services
- `tu-vm.sh` control surface
- helper API + Nginx landing/dashboard
- existing changelog priorities around profiles, battery awareness, and operational visibility

---

## Existing strengths to leverage

The project already includes:
- One-command operational script (`tu-vm.sh`)
- Daily health/update checks and status files
- Dashboard controls and service state APIs
- Structured service naming in Compose and Nginx

This means we can add contributor tooling as thin wrappers and validators, not as a platform rewrite.

---

## Tooling proposal set

## A. `tu-vm.sh doctor` (single diagnostics command)

### Why
Contributors currently have multiple troubleshooting paths. A one-shot diagnostics command shortens issue triage.

### Behavior
`./tu-vm.sh doctor` should output a deterministic report:
- Compose validity check
- Required env var presence check (without printing secrets)
- Container status summary
- Nginx config test
- Key endpoint checks
- Disk/memory pressure warnings
- Suggested next commands based on findings

### Implementation notes
- Reuse logic from `status`, `health`, and daily check script.
- Output can be both human text and optional JSON:
  - `./tu-vm.sh doctor --json > doctor-report.json`

---

## B. `scripts/check-config.sh` (fast pre-flight validator)

### Why
Most configuration errors are predictable and should fail early.

### Scope
Check:
- `.env` exists and has non-empty required keys
- No obvious placeholder secrets remain
- Required files exist (`nginx/conf.d/default.conf`, cert placeholders, etc.)
- Domain/IP config consistency

### Usage
- Local: run before `./tu-vm.sh start`
- CI: run on pull requests to prevent broken merges

---

## C. `scripts/smoke-test.sh` (post-change verification)

### Why
A small standard smoke suite helps community contributors validate changes quickly.

### Suggested checks
- `docker compose config` passes
- `./tu-vm.sh start --tier1` succeeds
- `/status/full` endpoint returns expected keys
- Landing page loads and includes dashboard cards
- At least one control endpoint auth check behaves correctly (401 when no token)

### Optional mode
- `--full` includes Tier 2 services and additional integration checks

---

## D. `scripts/release-note-helper.sh` (changelog assistance)

### Why
Community release quality improves when contributors are prompted to record user-facing changes consistently.

### Behavior
- Collect latest commit subjects since tag
- Prompt contributor for:
  - type (`feat`, `fix`, `security`, `perf`, `docs`)
  - impact summary
  - migration notes (if any)
- Print a suggested changelog block ready to paste

This is not auto-writing files; it is a guided helper.

---

## E. Contributor local-stack profiles

### Why
Contributors often need different resource footprints.

### Proposal
Support profile presets aligned with historical roadmap:
- `dev-lite`: Tier 1 + selected Tier 2 stubs
- `dev-full`: all services
- `battery-save`: strict low-resource defaults

Expose via:
- `./tu-vm.sh profile dev-lite`
- `./tu-vm.sh profile battery-save`

This operationalizes the changelog's "Quick Action Profiles" idea and makes contributor environments reproducible.

---

## F. API contract check for helper endpoints

### Why
Dashboard and helper API evolve together; accidental contract drift creates regressions.

### Proposal
Define minimal endpoint contract tests for:
- `/status`
- `/updates`
- `/announcements`
- `/status/{service}`
- `/status/pdf-processing`

Checks focus on response shape and required fields, not exact values.

---

## G. Documentation lint gate

### Why
Community repositories need stable docs quality with low friction.

### Proposal
Add a light docs lint/check step:
- dead link scan (internal links)
- heading structure sanity
- required sections for major docs (install, security, troubleshooting)

Can run in CI and optionally pre-commit.

---

## Operational integration pattern

To avoid excessive complexity:
1. Add tools as scripts under `scripts/`.
2. Expose the most important ones via `tu-vm.sh` aliases.
3. Ensure every tool has:
   - help text
   - machine-readable mode where useful
   - non-zero exit on failure

---

## Priority order

1. `doctor` command
2. `check-config.sh`
3. `smoke-test.sh`
4. helper API contract checks
5. profile presets
6. release note helper
7. docs lint gate

This order gives immediate quality and triage benefits with minimal architectural disruption.

---

## Success metrics

- Faster issue triage time (fewer "cannot reproduce" loops)
- Higher first-time contributor success rate
- Fewer config-related runtime failures
- Fewer dashboard/helper API regression issues
- More complete and consistent changelog entries

---

## Risks and mitigations

- **Risk:** Script sprawl  
  **Mitigation:** Route user-facing commands through `tu-vm.sh` and keep scripts focused.

- **Risk:** Overly strict checks block practical development  
  **Mitigation:** Separate hard-fail checks from advisory warnings.

- **Risk:** Increased maintenance burden  
  **Mitigation:** Keep each tool small and reuse existing command logic wherever possible.

