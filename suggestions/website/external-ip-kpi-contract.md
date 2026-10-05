---
title: External IP Tile Contract
description: Constructional contract to remove the landing External IP tile, because GET /status has no external_ip or ip field and a public lookup would fight the LAN-only design.
last_updated: 2026-10-05
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# External IP Tile Contract

## Problem

The system-status strip has five tiles. Four of them are filled from `GET /status` (Nginx path `/status/full`):

```javascript
if (full.vm_ip) document.getElementById('kpi-vm').textContent = full.vm_ip;
if (full.cpu_cores) document.getElementById('kpi-cpu').textContent = full.cpu_cores;
if (full.memory_mb) document.getElementById('kpi-mem').textContent = full.memory_mb.used+'/'+full.memory_mb.total+' MB';
if (full.disk_mb) document.getElementById('kpi-disk').textContent = full.disk_mb.used+'/'+full.disk_mb.total+' MB';
```

The fifth tile is different:

```html
<div class="kpi"><div class="kpi-label">External IP</div><div class="kpi-value" id="kpi-ext">--</div></div>
```

```javascript
if (full.external_ip||full.ip) document.getElementById('kpi-ext').textContent = full.external_ip||full.ip||'--';
```

`status()` returns `vm_ip`, `services`, booleans for six sockets, and optional `load_avg`, `memory_mb`, `disk_mb`, and `cpu_cores`. It does not set `external_ip` or `ip`. `fixtures/status-full-contract.json` does not list those keys. `scripts/validate_status_full_contract.py` does not require them.

A search of the repository for `external_ip`, `EXTERNAL_IP`, `kpi-ext`, and a JSON field named `ip` finds only this landing-page pair. No host script writes a public address into the helper.

The tile therefore stays `--` for every operator, on every refresh.

Checked on 2026-10-05 by reading `nginx/html/index.html` (the KPI markup and `refreshServices`) and `status()` in `helper/uploader.py`, then searching the tree for a writer. The page was not loaded in a browser.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `#kpi-ext` | A label with no producer |
| `status()` | The payload `/status/full` already returns |
| `fixtures/status-full-contract.json` | The keys CI treats as the status shape |
| `tu-vm.sh` `HOST_IP` | The LAN address Stage 45 already assigns to `vm_ip` |
| Stage 45 `dashboard-vm-ip-source-contract.md` (expected sibling, open PR #71) | `vm_ip` only. It already rules out a public-address lookup |
| Stage 44 `host-metrics-source-contract.md` (expected sibling, open PR #70) | Load, memory, disk, battery. Not this tile |

Out of scope:

- Filling the tile from a STUN, ipify, or `8.8.8.8` call
- Changing how `vm_ip` is chosen
- Moving memory and disk reads onto the host
- Publishing the VM on a public address

## Proposal

Delete the External IP tile and the two lines that would have filled it. The status strip keeps VM IP, CPU, memory, and disk.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Markup | `#kpi-ext` | Remove the tile |
| Script | `refreshServices` | Remove the `external_ip` / `ip` assignment |
| Helper | `status()` | Leave the JSON as it is. Do not add a public address field |
| Fixture | `fixtures/status-full-contract.json` | Do not add `external_ip` |

### Rules

1. **A tile needs a writer that already exists.** This one has none.
2. **Do not discover a public address from the helper.** The helper sits on `ai_network`. Stage 45 already forbids dialing out to learn an address, and that rule covers this tile too.
3. **Leave `kpi-vm` on the Stage 45 contract.** This page does not change `HOST_IP` or `get_vm_ip()`.
4. **Leave Stage 44 metrics on that contract.** Memory and disk stay where they are.
5. **The status fixture stays the current key set.** Validators should keep failing a payload that drops `vm_ip`, and they should keep ignoring a public-IP key because it is not part of the contract.

### Suggested contributor checklist

```text
1. Read the kpi-ext markup and the refreshServices assignment
2. Confirm status() and the fixture have no external_ip field
3. Remove the tile and the assignment
4. Reload the landing page and confirm the strip no longer says External IP
5. Confirm vm_ip, cpu, memory, and disk still render
6. Do not add an outbound IP lookup
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| LAN address | Existing VM IP tile and `HOST_IP` | A second tile plus a new lookup |
| Status shape | `fixtures/status-full-contract.json` | An undocumented `external_ip` key |
| Empty data | Remove the control | A permanent `--` |

## Acceptance criteria

- The landing page has no External IP label and no `kpi-ext` element.
- `refreshServices` does not read `external_ip` or `ip`.
- `status()` does not grow a public-address field.
- The status fixture and its validator stay on the current required keys.
- VM IP, CPU, memory, and disk tiles still bind to the fields they use today.

## Verification notes

Traced the assignment to `full.external_ip||full.ip` on 2026-10-05. `status()`'s `res` dict has no such keys. `rg` over the repo returned the landing page as the only match.

## Rollback

Restore the tile and the assignment. The helper payload is unchanged, so the restored tile shows `--` again.
