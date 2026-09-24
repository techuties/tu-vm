---
title: n8n Runner Payload Contract
description: Constructional contract to set official N8N_RUNNERS_MAX_PAYLOAD to 64 MiB. The n8n 2.25.7 default is 1 GiB, which is a different knob from the API JSON and form-data limits.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Runner Payload Contract

## Problem

n8n `2.25.7` defines `N8N_RUNNERS_MAX_PAYLOAD` in `@n8n/config` `runners.config.ts` as the maximum size in bytes of a payload sent to a task runner. The default is `1024 * 1024 * 1024` (1 GiB).

Compose does not set it. Stage 32 enables runners; it does not set this byte cap. Stage 38 `N8N_PAYLOAD_SIZE_MAX` is the HTTP JSON body limit for the n8n process. Stage 39 `N8N_FORMDATA_FILE_SIZE_MAX` is multipart form data. Stage 29 owns the binary-data volume. A 1 GiB runner message is a fourth limit, and on a laptop it can exhaust the n8n container before those other caps matter.

`N8N_RUNNERS_INSECURE_MODE` defaults to `false` in the same file. The comment says `true` disables runner security measures. This page does not enable it.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| n8n `2.25.7` runners config | `maxPayload` default 1 GiB; insecure mode default false |
| Stage 32 runners-enabled contract (expected sibling) | Whether runners are on, not this byte cap |
| Stage 34 execution timeout (expected sibling) | `EXECUTIONS_TIMEOUT` in seconds |
| Stage 38 `N8N_PAYLOAD_SIZE_MAX` (expected sibling) | JSON body to n8n |
| Stage 39 form-data contract (expected sibling) | Multipart file size |
| Stage 29 binary-data volume (expected sibling) | Filesystem binary mode |
| GitHub Issues | Place to raise the runner cap |

Out of scope:

- A custom code-node sandbox, queue, or worker pool
- Changing `N8N_PAYLOAD_SIZE_MAX` or `N8N_FORMDATA_FILE_SIZE_MAX`
- Setting `N8N_RUNNERS_INSECURE_MODE=true`
- `N8N_PYTHON_ENABLED` (leave the image default unless an Issue says Code-node Python is unused)

## Proposal

Set the official key on the `n8n` service:

```text
N8N_RUNNERS_MAX_PAYLOAD: "67108864"
```

`67108864` is 64 MiB (`64 * 1024 * 1024`). The unit in this image is bytes. 64 MiB covers ordinary Code-node item batches on a laptop and rejects a 1 GiB runner message.

Do not add `N8N_RUNNERS_INSECURE_MODE`. The default `false` is the safe value; setting `true` is an Issue, not a compatibility shortcut.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | `N8N_RUNNERS_MAX_PAYLOAD: "67108864"` |
| Env schema | `env.example` | Comment the unit (bytes) and the 64 MiB figure |
| Docs | n8n playbook | Point large files at the Stage 29 binary volume, not the runner payload |
| Other limits | Stages 34, 38, 39 | Leave those keys on their own pages |

### Rules

1. **Official key only.** Do not invent `TU_VM_RUNNER_MAX_BYTES`.
2. **Unit is bytes.** `67108864` is 64 MiB, not 64.
3. **Do not raise Stage 38 or Stage 39** to match this cap. They limit different hops.
4. **Do not set `N8N_RUNNERS_INSECURE_MODE=true`.**
5. **GitHub remains intake** for a larger runner payload, with a note about container memory.

### Suggested contributor checklist

```text
1. Confirm n8n 2.25.7 still documents N8N_RUNNERS_MAX_PAYLOAD in bytes with a 1 GiB default
2. Set N8N_RUNNERS_MAX_PAYLOAD=67108864 on the n8n service
3. Recreate n8n
4. Confirm a small Code-node execution still runs
5. Leave N8N_PAYLOAD_SIZE_MAX, N8N_FORMDATA_FILE_SIZE_MAX, and EXECUTIONS_TIMEOUT unchanged
6. Confirm N8N_RUNNERS_INSECURE_MODE is unset
7. Do not add a runner sandbox service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Runner message size | Official `N8N_RUNNERS_MAX_PAYLOAD` | A custom queue |
| JSON body | Stage 38 `N8N_PAYLOAD_SIZE_MAX` | Reusing this byte cap for HTTP JSON |
| Multipart uploads | Stage 39 form-data key | Raising form-data to 64 MiB here |
| Large files | Stage 29 filesystem binary volume | Pushing files through the runner payload |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an n8n recreate.
3. A larger cap needs an Issue.

## Acceptance criteria

- [ ] `n8n` sets `N8N_RUNNERS_MAX_PAYLOAD=67108864`.
- [ ] `N8N_RUNNERS_INSECURE_MODE` is not set to `true`.
- [ ] Stage 38 and Stage 39 size keys are not edited on this page.
- [ ] No runner sandbox service is added.

## Rollback

Remove the key to restore the 1 GiB image default. That rollback is a reviewed Issue on a memory-limited host, not a silent default.

## Success metrics

- Runner payloads above 64 MiB are rejected by n8n.
- Ordinary Code-node runs still complete.
