---
title: Allowlist Network Rewrite Contract
description: Constructional contract so tu-vm.sh allowlist rewrites keep the CIDR networks Nginx and the helper already accept.
last_updated: 2026-10-06
owner: maintainers
status: proposed
theme: security
impact: high
---

# Allowlist Network Rewrite Contract

## Problem

Nginx `allow` accepts a single address or a network. The helper already stores both. The shell commands that operators use every day keep only single addresses, and a later add or remove deletes every network line.

`helper/uploader.py` normalizes one entry like this:

```python
def _normalize_allow_entry(raw):
    raw = (raw or "").strip()
    if not raw:
        return None
    try:
        if "/" in raw:
            return str(ipaddress.ip_network(raw, strict=False))
        return str(ipaddress.ip_address(raw))
    except Exception:
        return None
```

`_read_allowlist` keeps a valid network. `_write_allowlist` writes it back as `allow 192.168.1.0/24;`. The dashboard list shows whatever that reader returns.

`./tu-vm.sh whitelist-list`, `whitelist-add`, and `whitelist-remove` do not use that helper. Each embedded snippet does:

```python
raw = line[len("allow "):].strip().rstrip(";").strip()
try:
    existing.append(str(ipaddress.ip_address(raw)))
except Exception:
    pass
```

`ipaddress.ip_address("192.168.1.0/24")` raises `ValueError`. The exception handler drops the line. Checked with the interpreter on 2026-10-06:

| File line | `ip_address` | Helper normalizer |
|---|---|---|
| `192.168.1.10` | kept | kept |
| `192.168.1.0/24` | dropped | `192.168.1.0/24` |
| `2001:db8::/64` | dropped | `2001:db8::/64` |
| `10.0.0.0/8` | dropped | `10.0.0.0/8` |

`whitelist-list` therefore prints a shorter list than Nginx is enforcing. `whitelist-add` of a normal address rewrites the file from that shorter list, so the network is gone after a routine add. `whitelist-remove` of a single address does the same rewrite. `whitelist-remove 192.168.1.0/24` fails earlier, on `ip_address` of the argument, and leaves the file unchanged, so the operator also cannot remove a network from the shell.

The dashboard add route has the same split. `whitelist_add` validates with `ipaddress.ip_address` and answers HTTP 400 for a network, while the file writer beside it would have stored one.

`is_docker_ip` in `whitelist_auto` also calls `ip_address`. A network never counts as docker-internal. An allowlist that contains only `172.20.0.0/16` is treated as a real client entry, and the empty-list bootstrap will not run. A LAN network such as `192.168.1.0/24` should keep blocking bootstrap; that part is right once the entry is classified as a non-docker network.

Checked on 2026-10-06 in `tu-vm.sh` (`whitelist_list`, `whitelist_add`, `whitelist_remove`) and `helper/uploader.py` (`_normalize_allow_entry`, `whitelist_add`, `is_docker_ip`). The commands were not run against a live Nginx.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `_normalize_allow_entry` | Already returns an address or a network |
| `_read_allowlist` / `_write_allowlist` | Round-trip those values and finish with `deny all;` |
| `whitelist_auto` | Bootstrap only when no non-docker entry remains |
| `./tu-vm.sh whitelist-list`, `whitelist-add`, `whitelist-remove` | The day-to-day commands that drop networks on rewrite |
| Dashboard `whitelist_add` | Rejects the form the helper writer accepts |
| `nginx/conf.d/default.conf` `include` of `control_allowlist.conf` | Nginx is what enforces the file |
| Stage 13 `ip-allowlist-day2-contract.md` (expected sibling) | How operators add and remove entries. It does not define the parser |
| Stage 43 client-IP trust (expected sibling, open PR #69) | Which header supplies the client address. Not which syntax the file may hold |

Out of scope:

- A new access-control service, OAuth gateway, or second allowlist file
- Changing the Nginx locations that include the file
- Publishing production addresses in the repository
- Auto-enrolling every visitor (the empty-list bootstrap stays as it is)

## Proposal

Use one entry rule in the helper and in the three shell snippets.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Parser | Helper `_normalize_allow_entry` | Keep it as the source of the rule. A value containing `/` is `ip_network(..., strict=False)`. Anything else is `ip_address`. Invalid values are skipped |
| Shell | `whitelist_list`, `whitelist_add`, `whitelist_remove` | Parse and write with that same rule. On add or remove, copy network lines through instead of `except: pass` |
| Dashboard add | `whitelist_add` | Accept an address or a network via `_normalize_allow_entry`. Keep HTTP 400 for a value that normalizes to nothing |
| Docker classification | `is_docker_ip` | For a network, return true when the network is a subnet of `DOCKER_SUBNET` or equal to it. For an address, keep the current membership test |
| File shape | Both writers | Still emit `allow <entry>;` lines and a final `deny all;` |

### Rules

1. **A rewrite is lossless.** After `whitelist-add` of a new address, every network that was in the file is still in the file.
2. **List matches the file.** `whitelist-list` prints each `allow` entry the helper would return, including networks.
3. **Remove is exact.** `whitelist-remove 192.168.1.0/24` deletes that network and leaves other lines in place.
4. **Invalid lines stay dropped.** A hostname or `allow all` is not a client entry. Skipping those is the current helper behavior; keep it.
5. **Do not add a second store.** The file remains `nginx/dynamic/control_allowlist.conf`.

### Suggested contributor checklist

```text
1. Put `allow 192.168.1.0/24;` and `allow 192.168.1.10;` in the allowlist file
2. Run whitelist-list and confirm both lines appear
3. Run whitelist-add 192.168.1.11 and confirm the network line is still present
4. Run whitelist-remove 192.168.1.0/24 and confirm only that line is gone
5. POST /whitelist/add with {"ip":"10.0.0.0/8"} and confirm HTTP 200 and a stored network
6. Confirm `allow all` is still ignored
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Parse | `ipaddress`, already imported in both files | A regex ACL library |
| Persist | The existing atomic temp-file replace | A database of allow entries |
| Enforce | The Nginx `include` already on `/control/` and `/whitelist/` | An application-level copy of `allow`/`deny` |
| Operator CLI | `./tu-vm.sh whitelist-*` | A new control binary |

## Acceptance criteria

- `whitelist-add` of a single address preserves existing network lines.
- `whitelist-remove` of a network removes that network and preserves other lines.
- `whitelist-list` prints network lines the helper reader keeps.
- Dashboard add accepts one CIDR and still rejects a hostname.
- A network that is inside `DOCKER_SUBNET` counts as docker-internal for bootstrap.
- The file still ends with `deny all;`.

## Verification notes

Interpreter check on 2026-10-06: `ip_address("192.168.1.0/24")` raises `ValueError`; `ip_network("192.168.1.0/24", strict=False)` returns `192.168.1.0/24`. The same drop is what the `except` blocks in `whitelist_add` and `whitelist_remove` do. Nginx was not reloaded.

## Rollback

Restore the three shell snippets and `whitelist_add` so they call `ip_address` only. Networks already stored by the helper remain valid Nginx until the next shell rewrite.
