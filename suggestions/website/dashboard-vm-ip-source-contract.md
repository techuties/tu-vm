---
title: Dashboard VM IP Source Contract
description: Constructional contract so the landing KPI shows the host HOST_IP already detected by tu-vm.sh, and the helper does not discover an address by dialing 8.8.8.8.
last_updated: 2026-09-29
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Dashboard VM IP Source Contract

## Problem

`GET /status` sets `vm_ip` like this:

```text
vm_ip = HOST_IP if set else get_vm_ip()
```

`get_vm_ip()` opens a UDP socket and connects to `8.8.8.8` port 80, then reads the socket’s local address. On failure it returns `127.0.0.1`.

`helper_index` is attached to `ai_network` at `172.20.0.19`. It is not on the host network. The local address of a socket whose route points at `8.8.8.8` is the container address, not the LAN address operators use for `https://<ip>`.

Compose passes `HOST_IP=${HOST_IP}`. When `.env` has no `HOST_IP`, the variable inside the container is empty, `os.environ.get('HOST_IP')` is falsy, and the fallback runs. The landing page writes that value into the VM KPI:

```text
if (full.vm_ip) document.getElementById('kpi-vm').textContent = full.vm_ip;
```

`tu-vm.sh` already detects a host address and writes `HOST_IP` before normal starts. The helper does not need a second detector, and the detector it has cannot see the host’s LAN address from this network namespace.

Checked on 2026-09-29 in `helper/uploader.py` (`get_vm_ip`, `status`), `nginx/html/index.html` (KPI assignment), and `docker-compose.yml` (`helper_index` network and `HOST_IP`).

Stage 44 owns load, memory, disk, and battery, including the fact that those reads happen inside the container. This page is only `vm_ip`. Do not reopen the metric-source contract.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` HOST_IP detection | Host-side address already written to `.env` |
| Compose `HOST_IP=${HOST_IP}` | The only address the helper should display |
| `fixtures/status-full-contract.json` and `scripts/validate_status_full_contract.py` | `vm_ip` is a string field. Empty string still satisfies the type |
| Landing KPI `kpi-vm` | Displays whatever `/status` returns |
| Stage 44 `host-metrics-source-contract.md` (expected sibling, open PR #70) | Load, memory, disk, battery. Not this field |
| Stage 12 LAN DNS onboarding (expected sibling, open PR #38) | How clients find `*.tu.lan`. Not the KPI fallback |

Out of scope:

- Host networking for the helper
- A public IP geolocation or STUN call
- Changing Pi-hole `ServerIP` or DNS bind (they already use `HOST_IP`)
- Mounting the host `/proc` to guess an address

## Proposal

Show the host-provided `HOST_IP` or show nothing. Delete the UDP fallback.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Helper | `status()` | `vm_ip` is `os.environ.get('HOST_IP', '').strip()`. Do not call `get_vm_ip()` |
| Helper | `get_vm_ip` | Remove it if nothing else in `uploader.py` calls it |
| Dashboard | `kpi-vm` | When `vm_ip` is empty, show a short local label such as `not set` rather than a container address |
| Contract fixture | `fixtures/status-full-contract.json` | Keep `vm_ip` as a string. Do not require a dotted quad |

### Rules

1. **No outbound discovery.** The helper must not connect to `8.8.8.8` or any other public address to learn its IP.
2. **Empty means unset.** An empty `HOST_IP` is reported as an empty string. Do not substitute `172.20.0.19` or `127.0.0.1`.
3. **Do not attach the helper to the host network** to make the old socket trick work.
4. **Do not parse `ip route` inside the container.** That still sees the Docker network.
5. **Leave Stage 44 metrics alone.** Load, memory, disk, and battery stay on that contract.
6. **The status fixture stays a string check.** `scripts/validate_status_full_contract.py` should keep accepting any string, including empty.

### Suggested contributor checklist

```text
1. status() reads only HOST_IP
2. Remove the 8.8.8.8 socket if it is unused
3. Dashboard shows a local empty label when vm_ip is blank
4. python3 -m py_compile helper/uploader.py
5. validate_status_full_contract.py still passes
6. Do not change load, memory, disk, or battery reads
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| LAN address | `HOST_IP` from `tu-vm.sh` | UDP connect to a public resolver |
| Empty state | Existing KPI element with static text | A second status service |
| Shape check | `scripts/validate_status_full_contract.py` | A new schema package |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Patch the helper and the one KPI branch together so an empty string does not render as a blank box with no explanation.
3. Reload the helper. With `HOST_IP` set, the KPI matches `.env`. With it unset, the KPI does not show a `172.20.` address.

## Acceptance criteria

- [ ] `uploader.py` contains no connect to `8.8.8.8`.
- [ ] `vm_ip` in `/status` equals the trimmed `HOST_IP` env value.
- [ ] Unset `HOST_IP` yields an empty string, not a container address and not `127.0.0.1`.
- [ ] The dashboard does not present that empty string as a reachable VM address.
- [ ] The status fixture still requires `vm_ip` to be a string.
- [ ] Load, memory, disk, and battery fields are unchanged.

## Rollback

Restore `get_vm_ip` and recreate the helper container. Docs-only publication needs no runtime rollback.

## Success metrics

- The VM KPI matches the address `tu-vm.sh` stored, which is the address printed in the CLI banner.
- An air-gapped helper start does not depend on a route to a public resolver to render the landing page.
