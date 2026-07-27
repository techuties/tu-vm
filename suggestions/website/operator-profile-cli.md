---
title: Operator Profile CLI Contract
description: Constructional contract for a thin tu-vm.sh profile CLI that applies Stage 2 operator service profiles without inventing a custom orchestrator.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Operator Profile CLI Contract

## Problem

Stage 2 defines named operator service profiles (`energy-saver`, `ai-chat`, `automation`, `knowledge`, `full-optional`) as a community contract. Operators still assemble ad-hoc `start-service` / `stop-service` sequences. Historical changelog items (Work/AI/Energy modes, idle auto-stop) keep resurfacing as “new frameworks” instead of thin wrappers over existing Compose tiers and `tu-vm.sh`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Stage 2 `operator-service-profiles.md` | Named profile membership and verify/rollback recipes |
| Stage 2 hardware matrix | Which profiles fit which host class |
| `./tu-vm.sh start`, `start-service`, `stop-service` | Actual enablement path today |
| `./tu-vm.sh status`, `health`, `doctor` | Verification |
| Compose Tier 1 vs Tier 2 | Natural profile building blocks |
| Nginx + helper dashboard | Show running set; not a profile editor SPA |

Out of scope for v1:

- Kubernetes-like custom scheduler or new daemon
- Dashboard-only profile storage that drifts from Compose
- Toggling `public` / allowlist posture as part of a resource profile
- Idle auto-stop policy (may **consume** profile membership later; separate opt-in)

## Proposal

After the Stage 2 catalog stabilizes, add a thin CLI:

```text
./tu-vm.sh profile list
./tu-vm.sh profile show <id>
./tu-vm.sh profile apply <id> --plan
./tu-vm.sh profile apply <id>
```

### Source of truth

Prefer a small machine-readable file once the markdown catalog is stable:

```text
profiles/catalog.yaml
```

Until then, keep membership tables in Stage 2 markdown and treat this page as the CLI contract only. **Do not** maintain conflicting membership lists in three places.

### Profile record (CLI-facing)

| Field | Meaning |
|---|---|
| `id` | Stable slug |
| `title` / `intent` | Human summary |
| `includes` | Services that should be running |
| `excludes` | Services that should be stopped when applying |
| `depends_on` | Soft edges for planning output |
| `hardware_fit` | Links/ids into the hardware matrix |
| `verify` | Commands or checks after apply |
| `security_notes` | Never implies public exposure |

### Command semantics

#### `profile list`

Print id, title, and one-line intent. Stable tabular or plain text; optional `--json` for scripting (no secrets).

#### `profile show <id>`

Print includes/excludes, depends_on, hardware fit, and verify steps. Exit non-zero on unknown id.

#### `profile apply <id> --plan`

Default-safe planning mode:

1. Resolve desired include/exclude sets.
2. Compare against current running containers (reuse existing status plumbing).
3. Print a diff: `would start`, `would stop`, `already ok`.
4. Make **no** changes.
5. Never read or print `.env` secret values.

#### `profile apply <id>`

1. Require explicit confirmation unless `--yes` is passed (match existing `tu-vm.sh` conventions).
2. Stop exclude-list services that are running (via existing stop helpers).
3. Start include-list services that are not running (via existing start helpers).
4. Run documented verify steps (`status`, optional `doctor`).
5. On partial failure, print which steps completed and how to roll back (previous running set is not automatically snapshot-persisted in v1—document manual rollback).

### Initial profile mapping (illustrative)

| Profile | Includes (beyond Tier 1) | Excludes (typical) |
|---|---|---|
| `energy-saver` | (Tier 1 only) | ollama, n8n, affine*, browserless, mcp-* |
| `ai-chat` | ollama | heavy automation extras unless already needed |
| `automation` | ollama, n8n, mcp_gateway (+ langgraph when writing) | unrelated niche stacks |
| `knowledge` | affine stack as documented | browser automation unless required |
| `full-optional` | documented Tier 2 union | none (requires headroom) |

Exact membership must track Stage 2; this table is illustrative only until that page merges.

### Day-to-day community usage

```bash
./tu-vm.sh profile list
./tu-vm.sh profile show energy-saver
./tu-vm.sh profile apply energy-saver --plan
./tu-vm.sh profile apply energy-saver --yes
./tu-vm.sh doctor
```

Website docs should show `--plan` first so contributors learn safe rehearsal.

### Frameworks and tools (reuse)

| Need | Prefer | Avoid |
|---|---|---|
| Orchestration | Existing Compose + `tu-vm.sh` helpers | New process manager |
| Config format | YAML next to profiles docs | Hidden SQLite profile DB |
| UX | CLI + dashboard status readback | SPA profile editor |
| Historical “modes” | Map Work/AI/Energy names onto these ids | Parallel mode systems |

## Acceptance criteria

- [ ] `list` / `show` / `apply --plan` work without mutating runtime.
- [ ] `apply` only calls existing start/stop paths.
- [ ] No secret material in plan/apply output.
- [ ] Access posture (secure/public/lock) is never changed by profiles.
- [ ] Docs link Stage 2 catalog as membership authority (or single YAML once adopted).
- [ ] Help text appears in `./tu-vm.sh help`.

## Rollout and rollback

1. Ship `list` + `show` + `apply --plan` first.
2. Enable mutating `apply` after one release of plan-only rehearsal.
3. Rollback = remove subcommands; operators keep using `start-service` / `stop-service`.

## Success signals

- Laptop operators switch to `energy-saver` without memorizing stop lists.
- Suggestion Issues for “Work/AI/Energy modes” close as implemented-by-profile rather than new frameworks.
- Profile apply failures are diagnosable with `doctor` / `status` alone.
