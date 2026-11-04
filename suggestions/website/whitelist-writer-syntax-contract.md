---
title: Allowlist Writer Syntax Contract
description: Constructional contract so tu-vm.sh whitelist-add and whitelist-remove write nginx/dynamic/control_allowlist.conf with the helper's ipaddress writer.
last_updated: 2026-11-04
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Allowlist Writer Syntax Contract

## Problem

Day-to-day allowlist edits from the shell go through `whitelist_add` and `whitelist_remove` in `tu-vm.sh`. Both hand a Python program to `python3` through a quoted heredoc (`<<'PY'`). The program that should write `nginx/dynamic/control_allowlist.conf` contains backslash-escaped quotes:

```text
tmp.write_text("\n".join(header + [f\"allow {x};\" for x in existing] + [\"deny all;\", \"\"]))
```

Python 3.12.3 reports `SyntaxError: unexpected character after line continuation character` on that line. `set -euo pipefail` then leaves the shell command. The allowlist file is unchanged, and Nginx is not reloaded.

The IP check that runs first is a different heredoc, and it is not quoted:

```bash
python3 - <<PY >/dev/null 2>&1
import ipaddress,sys
ipaddress.ip_address("$ip")
PY
```

Bash substitutes `$ip` into the Python source. A documentation address passes. An argument that is not an IP address can close the string and run as Python.

Replayed on 2026-11-04. The repository allowlist was not opened. No container was started.

| Input | Result |
|---|---|
| `203.0.113.10` through the unquoted check | Exit 0 |
| The quoted writer, same address, temp path | Exit 1, `SyntaxError` on the `f\"allow` line |
| `not-an-ip` passed to `ipaddress.ip_address` directly | `ValueError` |
| An argument that is not an IP address, fed through the unquoted check | Exit 0, and a 3-byte file appeared under `/tmp`. That file was removed |
| `192.0.2.0/24` | `ipaddress.ip_address` raises `ValueError`. `ipaddress.ip_network(..., strict=False)` returns `192.0.2.0/24` |

`helper/uploader.py` already contains the writer these commands are aiming at. `_normalize_allow_entry` accepts a single address or a network. `_write_allowlist` validates, de-duplicates, and replaces the file atomically. The shell commands should call that behavior, with the address passed as `sys.argv`, inside a quoted heredoc.

Checked by compiling the heredoc bodies extracted from `whitelist_add` and `whitelist_remove`, and by the replay above. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `whitelist_add` / `whitelist_remove` | The shell commands operators run |
| `whitelist_list` | Read path. Its quoted heredoc compiles. Leave it |
| `helper/uploader.py` `_normalize_allow_entry` | Address and network parsing the file format already allows |
| `helper/uploader.py` `_write_allowlist` | Header, `allow` lines, `deny all;`, atomic replace |
| `nginx/dynamic/control_allowlist.conf` | The file both sides already share |
| `reload_nginx` | `docker kill -s HUP ai_nginx` after a successful write |
| Stage 13 `ip-allowlist-day2-contract.md` (open PR #39) | Default deny, no production addresses in git, lockout recovery. Unchanged here |

Out of scope:

- Opening control routes to every client
- Adding an account system or a second allowlist file
- Changing the helper HTTP routes `/whitelist/add` and `/whitelist/remove`
- Rewriting Nginx `include` rules for `/control/`

## Proposal

Make the shell writer the same program the helper already runs. Pass the operator's address as an argument. Keep the heredoc quoted so the address cannot become Python source.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Validation | The unquoted `<<PY` check in `whitelist_add` | Quoted heredoc, `ipaddress` on `sys.argv`. Same acceptance rule as `_normalize_allow_entry` |
| Write | Quoted heredocs in `whitelist_add` and `whitelist_remove` | Plain f-strings, as in `_write_allowlist`. Keep entries that are networks |
| Read | `whitelist_list` | Show networks as well as single addresses, using the same normalizer |
| Reload | `reload_nginx` | Call it only after the writer exits 0, as today |
| Policy | Stage 13 page | Leave default deny and the "no production IPs in git" rule in that page |

### Rules

1. **The writer has to compile.** `python3 -m py_compile` is the wrong tool for a heredoc. Compiling the extracted body must succeed.
2. **The address is data.** `sys.argv` is the only way it enters Python. The heredoc delimiter stays quoted.
3. **One file shape.** Header, `allow <entry>;` lines, then `deny all;`. Networks that `_normalize_allow_entry` accepts survive an add or a remove of some other entry.
4. **A normal address is written.** `203.0.113.10` produces an `allow` line and the command exits 0.
5. **A value that is neither an address nor a network is rejected** before the file is opened for write, and it does not run as code.
6. **Stage 13 still owns policy.** This page does not allow `allow all`, and it does not commit real client addresses.

### Suggested contributor checklist

```text
1. Extract both quoted writer bodies and compile them
2. Add 203.0.113.10 on a temp copy of the allowlist and confirm the allow line
3. Add 192.0.2.0/24, then add 203.0.113.10, and confirm the network line is still present
4. Pass a value that is not an address or a network and confirm exit 1 with the file unchanged
5. Confirm helper _write_allowlist and the Nginx include lines are unchanged
6. Confirm the repo allowlist and .env were not used to prove this page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Parse and write | `_normalize_allow_entry` and `_write_allowlist` | A second allowlist language |
| Argument passing | `sys.argv` and a quoted heredoc | Interpolating the address into source |
| Reload | Existing `reload_nginx` | A new Nginx process |
| Intake | GitHub Issue | A local allowlist queue |

### Acceptance check

- [ ] The Python bodies in `whitelist_add` and `whitelist_remove` compile.
- [ ] `203.0.113.10` is written as `allow 203.0.113.10;` and the command exits 0.
- [ ] A network such as `192.0.2.0/24` is kept across a later add or remove.
- [ ] An argument that is not an address or a network does not execute as Python and does not change the file.
- [ ] The heredoc that reads the address is quoted, and the address arrives as `sys.argv`.
- [ ] `helper/uploader.py` `_write_allowlist` is unchanged.
- [ ] `.env` was not created to prove this, and the repository allowlist was not modified.

### Rollback

Restore the previous heredocs. The helper HTTP routes continue to write the file. The shell commands return to failing at the `SyntaxError` for every address.
