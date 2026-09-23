---
title: n8n Form-Data File Size Contract
description: Constructional contract to pin official N8N_FORMDATA_FILE_SIZE_MAX=200 so multipart webhook files stay at the n8n 2.25.7 default.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Form-Data File Size Contract

## Problem

n8n `2.25.7`, the image pinned in Compose (`sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd`), sets `N8N_FORMDATA_FILE_SIZE_MAX` in `packages/@n8n/config/src/configs/endpoints.config.ts` with default `200`. The comment says it is the maximum size in MiB for a single file in multipart/form-data webhook payloads. The same file sets `N8N_PAYLOAD_SIZE_MAX` default `16`, which Stage 38 already owns.

Compose does not pin the form-data key. A later edit can raise it on the laptop Tier 2 profile without a review.

Nginx on `n8n.tu.lan` `location /` sets `client_max_body_size 20m`. Traffic through that vhost is already tighter than 200 MiB. The proxy cap and the form-data cap are different knobs. This page does not edit Nginx and does not lower the official 200 default to chase the proxy. Aligning the application number down to 20 is a separate Issue if operators want one number.

This is distinct from:

- Stage 38 `n8n-payload-size-max-contract.md` (JSON body, default 16 MiB)
- Stage 29 `n8n-binary-data-volume-contract.md` (filesystem binary data)
- Stage 9 `nginx-edge-routing-contract.md` (`client_max_body_size`)
- Stage 34 `n8n-execution-timeout-contract.md` (how long a run may last)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| n8n `2.25.7` `endpoints.config.ts` | `formDataFileSizeMax` default `200` MiB |
| `n8n` environment | Key unset; `N8N_BINARY_DATA_MODE` already `filesystem` |
| Nginx `n8n.tu.lan` `location /` | `client_max_body_size 20m` already present |
| Stage 38 payload contract (expected sibling) | JSON cap stays 16 |
| GitHub Issues | Place to raise the form-data cap or to align it with Nginx |

Out of scope:

- Changing `N8N_PAYLOAD_SIZE_MAX`
- Changing Nginx `client_max_body_size`
- A webhook buffering gateway
- Moving binary data back into Postgres

## Proposal

Pin the official default on the `n8n` service:

```text
N8N_FORMDATA_FILE_SIZE_MAX: "200"
```

Do not invent `TU_VM_FORM_MAX`. Do not set it to 20 in this change. The public vhost already stops bodies above 20 MiB. The pin stops the application default from drifting upward for any path that reaches n8n directly. Files that need more than the proxy allows belong in the existing filesystem binary-data mode or MinIO, which the stack already runs.

n8n reads the value at process start. Recreate the container after the pin.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official `200` |
| Env schema | `env.example` | Comment: MiB per form-data file, keep 200 unless an Issue says otherwise |
| Docs | n8n playbook | Point oversized files at binary mode / MinIO |
| Nginx | `client_max_body_size` | Leave it on the Stage 9 edge contract |
| JSON bodies | Stage 38 | Leave `N8N_PAYLOAD_SIZE_MAX` alone |

### Rules

1. **Official unit.** The value is mebibytes. `200` means 200 MiB per file.
2. **Do not merge it with the JSON cap.** `N8N_PAYLOAD_SIZE_MAX` stays 16.
3. **Do not chase the proxy downward in this change.** Nginx `20m` is Stage 9.
4. **Do not raise 200 to "match a workflow."** That is an Issue plus a Tier 2 memory note.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Confirm the pinned n8n 2.25.7 image still defaults N8N_FORMDATA_FILE_SIZE_MAX to 200
2. Set N8N_FORMDATA_FILE_SIZE_MAX=200 on the n8n service
3. Recreate n8n
4. Leave N8N_PAYLOAD_SIZE_MAX and Nginx client_max_body_size unchanged
5. Do not add a webhook buffering proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Multipart file cap | Official `N8N_FORMDATA_FILE_SIZE_MAX=200` | A custom body-size filter |
| JSON body cap | Stage 38 `N8N_PAYLOAD_SIZE_MAX=16` | Raising JSON to match form-data |
| Large binaries | Existing filesystem binary mode and MinIO | Raising the form-data cap |
| Proxy limit | Stage 9 Nginx edge contract | Editing `client_max_body_size` here |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an n8n recreate.
3. A value other than 200 needs an Issue.

## Acceptance criteria

- [ ] `n8n` sets `N8N_FORMDATA_FILE_SIZE_MAX=200`.
- [ ] `N8N_PAYLOAD_SIZE_MAX` and Nginx `client_max_body_size` are unchanged.
- [ ] No webhook buffering proxy is added.

## Rollback

Remove the pin to restore the same official default of 200. Setting a higher number is a reviewed Issue.

## Success metrics

- The form-data file cap stays at the n8n 2.25.7 default of 200 MiB.
- The JSON payload cap and the Nginx body cap stay on their own contracts.
