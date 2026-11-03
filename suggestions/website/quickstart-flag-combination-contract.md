---
title: Quickstart Flag Combination Contract
description: Constructional contract so tu-vm.sh quickstart accepts --server and --no-secure together, using the case arms the function already has.
last_updated: 2026-11-03
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Quickstart Flag Combination Contract

## Problem

Help lists two explicit quickstart modifiers:

```text
quickstart               One-command beginner setup (portable mode)
quickstart --server      One-command full-stack setup
quickstart --no-secure   Skip firewall step (not recommended)
```

`main` forwards one word:

```bash
quickstart|easy-start|easy)
    quickstart_beginner "${2:-}"
```

`quickstart_beginner` switches on that single string. Each arm sets one outcome. `--server` sets server mode and leaves `apply_secure=auto`, so a root run calls `enable_secure`. `--no-secure` sets portable mode and `apply_secure=never`. A separate token, `--server-no-secure`, sets both, and help does not mention it.

Replayed on Bash 5.2.21 with the same `case`, without executing `tu-vm.sh`:

| Command words | Word `main` passes | Result |
|---|---|---|
| `quickstart --server --no-secure` | `--server` | `mode=server`, `secure=auto` |
| `quickstart --no-secure --server` | `--no-secure` | `mode=portable`, `secure=never` |
| `quickstart --server-no-secure` | `--server-no-secure` | `mode=server`, `secure=never` |
| `quickstart` | empty | `mode=portable`, `secure=auto` |

The first command is the one an operator types from the two help lines. It still applies the firewall. The second command drops `--server`. Neither prints `Unknown quickstart option`, because the extra word never reaches the function.

Checked on 2026-11-03 by reading `show_help`, the `quickstart` arm in `main`, and `quickstart_beginner`. The function was not executed, so `setup_platform`, `start_services`, and `enable_secure` did not run. `.env` was not created.

The beginner quickstart contribution page on branch `cursor/community-suggestions-system-0fa7` already says portable stays the default and `--no-secure` stays opt-in. This page is the parser that currently cannot see both words.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `quickstart_beginner` | Setup, start, optional `enable_secure`, post-checks |
| `case` arms for `--server`, `--portable`, `--no-secure`, `--server-no-secure` | The outcomes to keep |
| `setup_platform` | Secrets, DNS, SSL. Still the only installer step |
| `start_services --server` / `--portable` | The two start forms quickstart already calls |
| `enable_secure` | The firewall step `--no-secure` skips |
| `show_help` beginner block | The two flags operators see |
| Stage 18 beginner quickstart page (branch `cursor/community-suggestions-system-0fa7`) | Portable default, one command, firewall opt-out stays explicit |
| Stage 55 firewall command order (open PR #81) | What `enable_secure` appends. Unchanged here |

Out of scope:

- A new installer, a GUI, or a flag-parsing library
- Making `--server` the default
- Making `--no-secure` the default
- Editing `enable_secure` (Stage 55)

## Proposal

Forward every word after `quickstart`, and let each existing arm set its own field. `--server` and `--no-secure` may both be present.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Dispatch | `quickstart` arm in `main` | `quickstart_beginner "${@:2}"` |
| Parse | `quickstart_beginner` | Loop over `"$@"` and apply the current arms. An unknown word still calls `error` with the existing usage text |
| Server | `--server`, `server`, `--all` | Set `mode=server` and leave the secure flag as it stands |
| Firewall opt-out | `--no-secure` | Set `apply_secure=never` and leave the mode as it stands |
| Alias | `--server-no-secure` | Keep setting both, so a script that already passes that token still works |
| Help | Beginner examples | Show `quickstart --server --no-secure` as the combined form |

### Rules

1. **Portable remains the default.** No flag still calls `start_services --portable`.
2. **`--server` and `--no-secure` compose.** Together they call `start_services --server` and skip `enable_secure`.
3. **Order does not matter.** `--no-secure --server` and `--server --no-secure` are the same outcome.
4. **An unknown word still fails.** `quickstart --servers` prints the usage `error` already uses.
5. **`--server-no-secure` remains accepted.** It is the one-token form of the same pair.
6. **The firewall function is unchanged.** Skipping it means the existing `apply_secure=never` branch.

### Suggested contributor checklist

```text
1. Replay quickstart --server --no-secure and confirm both mode=server and secure=never
2. Replay quickstart --no-secure --server and confirm the same pair
3. Replay bare quickstart and confirm portable plus secure=auto
4. Replay an unknown token and confirm the existing error text
5. Confirm enable_secure and start_services bodies were not edited
6. Confirm .env was not created to prove this page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Flag meanings | The `case` arms already in `quickstart_beginner` | A CLI parsing library |
| Extra words | `"${@:2}"`, the form `doctor` and `check-config` already use in `main` | Reading only `$2` |
| Install step | `setup_platform` | A second setup script |
| Intake | GitHub Issue | A wrapper around `quickstart` |

### Acceptance check

- [ ] The `quickstart` arm passes `"${@:2}"`.
- [ ] `quickstart --server --no-secure` selects server mode and `apply_secure=never`.
- [ ] `quickstart --no-secure --server` selects the same pair.
- [ ] Bare `quickstart` stays portable and still applies secure mode when root.
- [ ] `--server-no-secure` still selects server mode and skips the firewall.
- [ ] An unknown token still fails with the current usage text.
- [ ] `enable_secure` is unchanged.
- [ ] `./tu-vm.sh quickstart` was not executed to prove this, so `.env` was not created.

### Rollback

Pass `"${2:-}"` again and restore the single-argument `case`. One-flag commands behave the same. Two-flag commands return to honoring only the first flag.
