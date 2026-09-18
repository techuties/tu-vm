---
title: n8n Restrict File Access Contract
description: Constructional contract to jail n8n Read/Write File nodes with official N8N_RESTRICT_FILE_ACCESS_TO on a dedicated volume, instead of adding a file-proxy sidecar.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Restrict File Access Contract

## Problem

The `n8n` service mounts `n8n_data` at `/home/node/.n8n` and does not set `N8N_RESTRICT_FILE_ACCESS_TO`. Official n8n File nodes can then read or write any path the container user can see. A shared LAN instance lets a workflow author walk credentials, the settings file, or (if extra host binds are added later) unexpected host paths.

Community suggestions that “sandbox n8n files” often propose a fuse proxy, a second VM, or copying Stage 29 binary-data volume work. The official allowlist is already there and is unset today.

This is distinct from:

- Stage 29 `n8n-binary-data-volume-contract.md` (where *execution binary* blobs live; `N8N_BINARY_DATA_MODE=filesystem` is already set)
- Stage 32 `n8n-settings-file-permissions-contract.md` (mode on `~/.n8n` settings file)
- Stage 33 `n8n-block-env-access-in-node-contract.md` (process.env, not filesystem)
- Official `N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES` (defaults `true`; keep it; this page owns the *allowlist*)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` volumes | `n8n_data:/home/node/.n8n` only |
| Official n8n security env | `N8N_RESTRICT_FILE_ACCESS_TO` (semicolon-separated dirs) |
| Official n8n security env | `N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES` already defaults true |
| Stage 29 binary volume (expected sibling) | Execution binaries, not File-node jail |

Out of scope:

- A file-proxy sidecar, FUSE layer, or gVisor product
- Rewriting Stage 29 binary-data volume
- Rewriting Stage 32 settings-file permissions
- Bind-mounting the Docker host root “for convenience”

## Proposal

Add a dedicated named volume (or bind under the project data dir) and set the official allowlist:

```text
N8N_RESTRICT_FILE_ACCESS_TO: /home/node/.n8n-files
N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES: "true"
```

Mount that path read-write. Do not point the allowlist at `/home/node/.n8n` (credentials and settings live there). Do not add a TU-VM file-broker API.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment + volumes | Official allowlist + `n8n_files` volume |
| Env schema | `env.example` | Comment only unless operators need a custom path |
| Docs | n8n playbook | File nodes may only use the jail path |

### Rules

1. **Official key only.** Do not invent `TU_VM_N8N_FILE_ROOT`.
2. **Do not confuse with binary data.** Stage 29 owns execution binaries.
3. **Do not confuse with settings-file mode.** Stage 32 owns `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS`.
4. **Keep `.n8n` blocked.** Leave `N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES=true`.
5. **GitHub remains intake.** Requests for host-path binds stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_RESTRICT_FILE_ACCESS_TO
2. Add n8n_files volume and the official allowlist
3. Recreate n8n and verify File nodes cannot read ~/.n8n/config
4. Document the jail path for community workflows
5. Do not add a file-proxy sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Limit File nodes | Official `N8N_RESTRICT_FILE_ACCESS_TO` | A proxy or extra container |
| Protect credentials dir | Official `N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES` | Copying secrets out to “safe” files |
| Share files with MCP | Existing `mcp_shared` + explicit design | Bind-mounting `/` into n8n |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one volume + two env lines + one playbook sentence.
3. Call out File-node path breakage in release notes if local workflows used arbitrary paths.

## Acceptance criteria

- [ ] `n8n` sets `N8N_RESTRICT_FILE_ACCESS_TO` to a dedicated directory.
- [ ] That directory is a named volume, not `~/.n8n`.
- [ ] Docs mention the jail path.
- [ ] No file-proxy sidecar is added.
- [ ] Stage 29 / 32 / 33 n8n pages are not rewritten.

## Rollback

Remove the allowlist env (and optionally the extra volume). File nodes regain container-wide access. Existing `n8n_data` remains.

## Success metrics

- A sample File node cannot read `/home/node/.n8n`.
- Hardening PRs cite this allowlist instead of a new filesystem product.
