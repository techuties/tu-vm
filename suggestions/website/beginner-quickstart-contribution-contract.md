---
title: Beginner Quickstart Contribution Contract
description: Constructional contract for community changes to ./tu-vm.sh quickstart—keep portable-first onboarding and existing setup/firewall helpers instead of a second installer product.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: community
impact: high
---

# Beginner Quickstart Contribution Contract

## Problem

`./tu-vm.sh quickstart` is the documented beginner path: prepare secrets/DNS/SSL, start **portable** (Tier 1) by default, optionally `--server`, optionally skip firewall with `--no-secure`, then print next steps (`https://tu.lan`, `dns-clients`, `diagnose`). Community PRs that change first-hour behavior have outsized impact: flipping the default to full-stack start, auto-starting Ollama, or skipping `setup_platform` reintroduces the energy and security problems the project already solved.

Historical suggestion hubs asked for persona entry paths (Stage 2) and CLI subcommand rules (Stage 14). They did not pin a **quickstart contract** so onboarding stays one command, LAN-first, and portable-default.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `quickstart_beginner()` in `tu-vm.sh` | Orchestrates setup → start → optional `secure` → post-checks |
| `setup_platform()` | `.env`, SSL, secrets—do not fork a second installer |
| `start_services --portable` / `--server` | Actual compose start sets |
| `enable_secure` | Firewall; requires root |
| `run_beginner_post_checks` | Best-effort; failures do not abort quickstart today |
| `README.md` / `QUICK_REFERENCE.md` | Human onboarding |
| Stage 2 `persona-entry-paths.md` (expected sibling) | Who lands where in the first hour |
| Stage 8 `smart-startup-optimization.md` (expected sibling) | Planner for starts, not a replacement quickstart |
| Stage 12 `access-mode-and-firewall-contract.md` (expected sibling) | `secure` / `public` / `lock` |
| Stage 12 `lan-dns-client-onboarding-contract.md` (expected sibling) | `dns-clients` follow-up |
| Stage 14 `cli-subcommand-contribution-contract.md` (expected sibling) | How to add flags without a second CLI |

Out of scope:

- A GUI installer, Electron wrapper, or hosted SaaS onboarding
- Making `--server` the silent default
- Auto-starting Ollama on non-GPU laptops as part of beginner success
- Skipping `.env` / TLS generation because “the cloud agent already has files”

## Proposal

Publish a **beginner quickstart contribution contract** for PRs that touch `quickstart`, `setup_platform`, or the printed next-steps.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Flags | `quickstart_beginner` option parsing | `--portable`, `--server`, `--no-secure` stay explicit |
| Setup | `setup_platform` | Reuse; do not copy SSL/secret logic into a new script |
| Start mode | `start_services` | Portable remains default |
| Firewall | `enable_secure` | Warn + sudo hint when not root; do not fail closed into public mode |
| Next steps | stdout | Dashboard, Open WebUI, `dns-clients`, `diagnose` |
| Docs | README / QUICK_REFERENCE | Match flag names |

### Rules

1. **Portable is the beginner default.** `--server` / `--all` must remain explicit.
2. **One orchestrated path.** Quickstart calls existing functions; do not add `install.sh` that bypasses `tu-vm.sh`.
3. **`--no-secure` is opt-out, never implied.** Do not add a hidden skip for firewall in the default path.
4. **When not root, do not pretend the firewall was applied.** Keep the `sudo ./tu-vm.sh secure` hint.
5. **Post-checks may be best-effort**, but new checks should not secretly `exit 1` on optional Tier 2.
6. **Printed URLs stay LAN/TLS** (`https://tu.lan`, `https://oweb.tu.lan`) unless access-mode docs change in the same PR.
7. **GitHub remains intake.** Requests for a graphical installer stay Issues unless accepted.

### Suggested contributor checklist

```text
1. Keep ./tu-vm.sh quickstart as the documented first command
2. Confirm default mode is portable (Tier 1)
3. Confirm --server and --no-secure remain explicit
4. Reuse setup_platform / start_services / enable_secure
5. Update README and QUICK_REFERENCE if flags or URLs change
6. Run bash -n tu-vm.sh and ./tu-vm.sh help
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| First-hour flow | `quickstart` | Second installer |
| Personas | Stage 2 entry paths | Duplicate getting-started microsites |
| Firewall | Stage 12 access modes | Silent public bind “to make Wi-Fi easier” |
| Full stack | `--server` plus GPU-aware Ollama policy | Always-on Ollama for beginners |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only when onboarding flags or messages actually drift.
3. Keep cloud-agent notes in `AGENTS.md` from turning into a second beginner path.

## Acceptance criteria

- [ ] Portable remains the default beginner start set.
- [ ] `--server` and `--no-secure` stay explicit opt-in.
- [ ] Quickstart reuses `setup_platform` rather than a parallel installer.
- [ ] Non-root firewall behavior remains a warn + sudo hint.
- [ ] Docs and `tu-vm.sh help` stay aligned with flags.

## Rollback

Revert `tu-vm.sh`/docs independently. Prior quickstart returns. Docs-only publication needs no runtime rollback.

## Success metrics

- New operators reach `https://tu.lan` via one command on portable hosts.
- Fewer issues caused by accidental full-stack or public-mode first boots.
- Help text and README do not diverge on quickstart flags.
