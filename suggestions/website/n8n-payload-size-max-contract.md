---
title: n8n Payload Size Contract
description: Constructional contract to pin official N8N_PAYLOAD_SIZE_MAX=16 so n8n JSON bodies stay at the documented 16 MiB limit.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Payload Size Contract

## Problem

Official n8n endpoint configuration documents `N8N_PAYLOAD_SIZE_MAX` as the maximum payload size in MiB. The default is `16`. The same page says raising it uses more memory and CPU and needs an n8n restart. TU-VM runs n8n as an on-demand Tier 2 service on a laptop energy profile. Compose does not pin the key, so a later edit can raise it without a review.

Nginx on `n8n.tu.lan` sets `client_max_body_size 20m` for `location /`. That proxy cap and the n8n JSON payload cap are different knobs. Matching n8n to 20, or higher, is how a laptop OOM starts. Stage 9 `nginx-edge-routing-contract.md` remains the place to discuss the proxy body size. This page pins the n8n application limit.

This is distinct from:

- Stage 29 `n8n-binary-data-volume-contract.md` (filesystem binary data, not the JSON body cap)
- `N8N_FORMDATA_FILE_SIZE_MAX` (official default 200 MiB for form-data files; out of this contract)
- Stage 34 `n8n-execution-timeout-contract.md` (how long a run may last)
- Stage 26 resource limits (container memory budget)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official n8n endpoints reference | `N8N_PAYLOAD_SIZE_MAX` default `16` MiB |
| `n8n` environment | Key unset; `N8N_BINARY_DATA_MODE` already `filesystem` |
| Nginx `n8n.tu.lan` `location /` | `client_max_body_size 20m` already present |
| Stage 29 binary volume (expected sibling) | Where large binaries live |
| GitHub Issues | Place to request a higher cap with a memory note |

Out of scope:

- Changing Nginx `client_max_body_size`
- Lowering `N8N_FORMDATA_FILE_SIZE_MAX` in this change
- A custom webhook gateway that re-buffers bodies
- Moving binary data back to the database

## Proposal

Pin the official default on the `n8n` service:

```text
N8N_PAYLOAD_SIZE_MAX: "16"
```

Do not invent `TU_VM_MAX_BODY`. Do not raise the value to match Nginx `20m`. Webhook and API JSON above 16 MiB should move to the existing filesystem binary-data mode or to object storage, which the stack already runs. A higher cap needs an Issue that names the workflow and confirms the Tier 2 memory limit still holds.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official `16` |
| Env schema | `env.example` | Comment: MiB, keep 16 on the laptop profile |
| Docs | n8n playbook | Point oversized files at binary mode / MinIO |
| Nginx | `client_max_body_size` | Leave it on the Stage 9 edge contract |

### Rules

1. **Official unit.** The value is mebibytes. `16` means 16 MiB.
2. **Do not chase the proxy.** Nginx `20m` is not a reason to set n8n to 20.
3. **Form-data file cap stays out.** `N8N_FORMDATA_FILE_SIZE_MAX` needs its own Issue.
4. **Large files use existing storage.** Binary filesystem mode and MinIO are already in the stack.
5. **GitHub remains intake.** Increases name the workflow and the memory budget.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_PAYLOAD_SIZE_MAX default 16
2. Set N8N_PAYLOAD_SIZE_MAX=16 on the n8n service
3. Restart n8n
4. Confirm a JSON body over 16 MiB is rejected
5. Leave Nginx client_max_body_size and N8N_FORMDATA_FILE_SIZE_MAX unchanged
6. Do not add a webhook buffering proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| JSON body cap | Official `N8N_PAYLOAD_SIZE_MAX=16` | A custom body-size filter |
| Large binaries | Existing `N8N_BINARY_DATA_MODE=filesystem` and MinIO | Raising the JSON cap |
| Proxy limit | Stage 9 Nginx edge contract | Editing `client_max_body_size` here |
| Runaway runs | Stage 34 execution timeout | Treating timeout and payload as one setting |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an n8n recreate.
3. Workflows that need larger JSON file an Issue before the number changes.

## Acceptance criteria

- [ ] `n8n` sets `N8N_PAYLOAD_SIZE_MAX=16`.
- [ ] Nginx `client_max_body_size` and `N8N_FORMDATA_FILE_SIZE_MAX` are unchanged.
- [ ] No webhook buffering proxy is added.

## Rollback

Remove the pin to restore the same official default of 16. Setting a higher number is a reviewed Issue, not a silent Compose tweak.

## Success metrics

- n8n rejects JSON payloads above 16 MiB.
- The Tier 2 memory limit is not raised to "make webhooks fit."
