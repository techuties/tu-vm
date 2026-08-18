---
title: WSL2 Contributor Path Contract
description: Constructional contract for documenting a WSL2 day-to-day contributor path that reuses existing scripts, systemd notes, and Docker-in-Linux instead of a second Windows-native stack.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: contributor-experience
impact: medium
---

# WSL2 Contributor Path Contract

## Problem

TU-VM assumes a Linux host with Docker Compose, port 53 for Pi-hole, and Unix line endings. A large share of community contributors work on Windows. Without a documented WSL2 path they install Docker Desktop *and* a second copy of the stack on Windows, bind-mount `/mnt/c/...` (NTFS) into Compose, or open PRs with CRLF and `docker.sock` from Windows.

Stage 5 covers Dev Containers/Codespaces. Stage 18 covers portable quickstart. Neither names **WSL2** as the Windows contributor environment.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Linux-oriented local checks; no WSL section |
| [`AGENTS.md`](../../AGENTS.md) | DinD notes (`fuse-overlayfs`, `iptables-legacy`) — cloud agents, not WSL |
| `scripts/pre-push-check.sh` / `smoke-test.sh` | Same gates contributors should run in WSL |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Codespaces/Dev Container — complementary |
| Stage 12 `host-port-binding-contract.md` (expected sibling) | Port 53 / 80 / 443 conflicts |
| Stage 20 `systemd-user-unit-install-contract.md` | Same unit file; WSL systemd enablement |
| `.gitattributes` / `.editorconfig` | May be absent; CRLF risk |

Out of scope:

- A native Windows Compose port (Hyper-V, named pipes as the default)
- Supporting Git Bash without WSL
- Docker Desktop *on Windows* as the prescribed engine (WSL2 Linux docker-ce is preferred)
- Changing Pi-hole to skip port 53 instead of documenting the conflict

## Proposal

Document **Ubuntu WSL2 + Docker Engine inside the distro** as the Windows community path.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Docs | `CONTRIBUTING.md` short section + this page | Clone **inside** `~/` not `/mnt/c` |
| Line endings | `.gitattributes` for `*.sh` `eol=lf` | Prevents `bash -n` surprises |
| systemd | `wsl.conf` `[boot] systemd=true` | Needed for user units and some Docker installs |
| DNS | Port 53 vs Windows / systemd-resolved | Same conflict `tu-vm.sh` already handles |
| Engine | docker-ce in WSL, or Docker Desktop *WSL backend* | One engine, not two |
| Tests | `./scripts/pre-push-check.sh` | Identical to Linux |

### Rules

1. **Repo lives on the Linux filesystem.** `~/src/tu-vm`, not `/mnt/c/Users/...`. NTFS bind mounts break overlayfs, exec bits, and inotify for the processor.
2. **One Docker.** Either Docker Engine in WSL **or** Docker Desktop with the WSL integration backend — not both fighting over the socket.
3. **Same scripts.** Do not add `tu-vm.ps1` as a parallel control plane. Contributors run `./tu-vm.sh` from bash.
4. **CRLF is a defect.** Shell scripts and Compose files must be LF. Prefer `.gitattributes`.
5. **Port 53.** Document that Windows Internet Connection Sharing, mirrored networking, and local DNS can steal 53; Pi-hole guidance stays the existing `tu-vm.sh`/playbook path.
6. **Do not lower LAN-first defaults** to make Windows easier (no “publish everything to 0.0.0.0” shortcut).
7. **GitHub remains intake.** Requests for a Windows installer MSI stay Issues.

### Suggested contributor checklist

```text
1. Use Ubuntu WSL2; enable systemd if using the user unit
2. Clone into the Linux home directory
3. Install one Docker engine (WSL docker-ce or Desktop WSL backend)
4. Copy env.example → .env; generate secrets; create SSL + allowlist as documented
5. ./scripts/pre-push-check.sh
6. Confirm files are LF (git add --renormalize if needed)
7. Do not mount the repo from C:\
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Windows contrib | WSL2 + existing bash scripts | PowerShell control plane |
| Repeatable env | Stage 5 Dev Container inside WSL | A second “windows/” compose file |
| Line endings | `.gitattributes` `eol=lf` | Editor-only conventions |
| Boot | Stage 20 user unit under WSL systemd | Task Scheduler calling `wsl.exe` ad-hoc |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code/docs**: a short `CONTRIBUTING.md` WSL subsection + `.gitattributes` for `*.sh`.
3. Optional: CI `file`/`gitattributes` check for shell scripts.

## Acceptance criteria

- [ ] WSL2 + Linux clone path is the documented Windows route.
- [ ] NTFS `/mnt/c` clones are explicitly discouraged.
- [ ] No parallel PowerShell control plane is introduced.
- [ ] CRLF policy is stated.
- [ ] Port 53 conflict is acknowledged, not redesigned.

## Rollback

Remove the CONTRIBUTING subsection and `.gitattributes` independently. Linux contributors are unaffected. Do not keep a half-finished `tu-vm.ps1`.

## Success metrics

- Windows contributors run the same smoke/pre-push scripts.
- Fewer PRs with CRLF or `/mnt/c` overlayfs failures.
- Docker Desktop vs docker-ce confusion is answered in one place.
