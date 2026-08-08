---
title: CLI Subcommand Contribution Contract
description: Constructional contract for community contributions that extend tu-vm.sh with thin, discoverable subcommands wrapping existing scripts—without inventing a parallel control CLI.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# CLI Subcommand Contribution Contract

## Problem

Day-to-day operators live in `./tu-vm.sh`. Historical suggestions invent new CLIs (`tuctl`, Python click apps, dashboard-only controls) that drift from help text and cron wrappers. Contributors need a **reuse-first contract** for adding subcommands that stay discoverable, thin, and safe.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` | Canonical operator control surface + help |
| `scripts/*.sh` | Implementation home for non-trivial logic |
| Stage 5 `task-runner-wrapper.md` (expected sibling) | Optional `just`/`make` facade over the same scripts |
| Stage 4 `operator-profile-cli.md` (expected sibling) | Profile list/show/apply shape |
| Stage 8 `smart-startup-optimization.md` (expected sibling) | `--plan` style planner patterns |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Doctor/diagnose evidence expectations |
| Stage 13 day-2 contracts | PDF, whitelist, cleanup already surface via `tu-vm.sh` |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes that should name the same verbs |

Out of scope:

- Replacing `tu-vm.sh` with a mandatory compiled CLI rewrite
- Embedding large feature logic only inside the mega-script with no `scripts/` home
- Silent subcommands that never appear in `./tu-vm.sh help`
- Dashboard-only controls with no CLI equivalent for headless hosts

## Proposal

Publish a **CLI subcommand contribution contract** for community PRs that extend the control script.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Thin wrapper | `tu-vm.sh` case arm + help text | Forwards to `scripts/` with stable flags |
| Implementation | `scripts/<name>.sh` | `bash -n`, idempotent notes, dry-run/`--plan` when mutating |
| Docs | README / playbooks / CONTRIBUTING | Same verb names as help |
| Completion (optional later) | Docs-only examples first | No new shell plugin framework required |
| Task runner alias | Stage 5 Justfile/`make` | Must call the same script path |

### Rules

1. **One control plane verb.** Prefer `./tu-vm.sh <verb>` over a second top-level binary.
2. **Logic lives in `scripts/`** when more than a few lines; `tu-vm.sh` stays a dispatcher.
3. **Help is mandatory.** New verbs appear in `help` with a one-line purpose and safe examples.
4. **Mutating commands need a rehearsal.** Prefer `--plan` / `--check` / dry-run before apply (align with update-check and profile `--plan` patterns).
5. **Tier honesty.** Docs must say which services must be up and that Tier 2 stays optional.
6. **No secret printing.** Commands must not echo tokens, `.env` values, or allowlisted client IPs by default.
7. **Playbook parity.** If operators will run it weekly, add or update a `#playbook-*` anchor that uses the same verb.
8. **GitHub remains intake.** Proposals for whole new CLIs stay Issues; default answer is extend `tu-vm.sh`.

### Suggested contributor checklist

```text
1. Identify lane: wrapper vs script vs docs-only
2. bash -n tu-vm.sh scripts/<name>.sh
3. ./tu-vm.sh help | grep <verb>
4. Rehearsal flag works (or document why N/A)
5. smoke-test / doctor still green when relevant
6. Playbook or README mentions the same verb
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Operator UX | Existing `tu-vm.sh` help surface | Parallel `tu-*` binaries per feature |
| Implementation | `scripts/` + Compose | Host-global installs as the only path |
| Contributor shortcuts | Stage 5 task-runner wrappers | Divergent flag names per wrapper |
| Safety | `--plan`/`--check` + backups | Hidden destructive defaults |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link from CONTRIBUTING “Local checks” when docs polish lands.
3. Cross-link Stage 4 profile CLI, Stage 5 task-runner, Stage 8 smart-startup.
4. Prefer **code** that extracts oversized case-arms into `scripts/` over more suggestion prose.

## Acceptance criteria

- [ ] Dispatcher-vs-script split is explicit.
- [ ] Help-text and no-secret-print rules are stated.
- [ ] Mutating commands prefer a rehearsal flag.
- [ ] Playbook/README verb parity is required.
- [ ] No parallel control CLI is required for new features.

## Rollback

Revert `tu-vm.sh` / `scripts/` commits independently; operators keep calling previous verbs. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer PRs that introduce one-off CLIs.
- New verbs discoverable via `./tu-vm.sh help` without README archaeology.
- Decline in “build a Go rewrite of tu-vm.sh” suggestions as a prerequisite.
