---
title: Helper Project Mount Contract
description: Constructional contract to drop the unused repository bind on helper_index so operator secrets and TLS keys are not readable in that container.
last_updated: 2026-09-28
owner: maintainers
status: proposed
theme: security
impact: high
---

# Helper Project Mount Contract

## Problem

`helper_index` is the landing-page API. Its Compose service bind-mounts the working tree:

```text
- ./helper:/app
- ./docker-compose.yml:/app/docker-compose.yml:ro
- .:/docker-project:ro
- ./nginx/dynamic:/nginx-dynamic
- /var/run/docker.sock:/var/run/docker.sock
- /tmp:/tmp
```

A search of `helper/` finds no read of `/docker-project` or of `/app/docker-compose.yml`. The start command runs `docker compose version`, which does not need a Compose file. The Python process is the image default user, root.

`generate-secrets` writes `.env` with mode `600`. That mode does not hide the file from root inside this container. The same tree holds `ssl/nginx.key` on a machine that has finished first-time setup. Both become readable at `/docker-project/.env` and `/docker-project/ssl/` for as long as the container is running.

The Docker socket is a separate, larger privilege. Stage 18 `helper-control-auth-contract.md` (expected sibling, open PR #44) already says the socket stays a privileged review item. This page does not remove it. This page removes mounts the application does not use.

The `/tmp` mount is shared status files. That behavior is the [update status file](./update-status-file-contract.md) contract, not this one.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `helper_index.volumes` | Mount list to trim |
| `helper/uploader.py` | Talks to the Docker socket and writes `ALLOWLIST_FILE` under `/nginx-dynamic` |
| `./tu-vm.sh generate-secrets` | Creates `.env` and `chmod 600` |
| `ssl/nginx.crt` and `ssl/nginx.key` | TLS material that must stay on the Nginx service, which already mounts `./ssl` read-only |
| Stage 18 helper control-auth (expected sibling) | Token, 401, socket review |

Out of scope:

- Removing `/var/run/docker.sock` from the helper
- Moving TLS termination out of Nginx
- A secrets manager, Vault, or SOPS rollout
- Changing which routes require `CONTROL_TOKEN`

## Proposal

Mount only paths the helper reads or writes.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Unused tree | `helper_index.volumes` | Delete `.:/docker-project:ro` |
| Unused Compose file | `helper_index.volumes` | Delete `./docker-compose.yml:/app/docker-compose.yml:ro` |
| Code | keep `./helper:/app` | The Flask app stays a bind so operators can edit `uploader.py` without an image rebuild until the image contract lands |
| Allowlist | keep `./nginx/dynamic:/nginx-dynamic` | `_write_allowlist` still has to rewrite `control_allowlist.conf` |
| Proof | `scripts/check-config.sh` or a short comment in the Compose service | Fail or warn if `helper_index` volumes contain `docker-project` |

### Rules

1. **The helper does not mount the repository root.** No `.:` source on `helper_index`.
2. **The helper does not mount the Compose file** unless a later change actually reads that path. Today it does not.
3. **Nginx keeps `./ssl`.** Do not copy certificates into the helper image or into another service to “share” them.
4. **`.env` stays on the host.** Compose interpolation already passes `HOST_IP` and `CONTROL_TOKEN` into the service environment. Do not also expose the file.
5. **Do not print secret values** from a check script. A volume-source check is a string compare on the Compose YAML.
6. **Leave the Docker socket** for a change that replaces the raw socket API. That is Stage 18’s review item, not this page.

### Suggested contributor checklist

```text
1. Confirm helper/ has no /docker-project or docker-compose.yml reads
2. Remove the two unused volume lines
3. Start the helper and confirm /status and /health still answer
4. Confirm /nginx-dynamic writes still reload Nginx
5. Confirm the container process cannot open /docker-project/.env
6. Do not log CONTROL_TOKEN or file contents in the proof
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Secret injection | Compose `environment` from `.env` | Bind-mounting the env file “just in case” |
| TLS | The existing Nginx `./ssl` mount | A second copy of the key in the helper |
| Allowlist edits | The existing `/nginx-dynamic` mount and `./tu-vm.sh whitelist-*` | A new config service |
| Review | A Compose volume assertion in the existing config check | A custom policy daemon |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Delete the two volume lines in the same commit as the assertion.
3. Recreate `ai_helper_index`. No data volume is removed by this change.

## Acceptance criteria

- [ ] `helper_index` volumes do not include the repository root or a Compose-file bind.
- [ ] `GET /health` on the helper still returns ok after recreate.
- [ ] Allowlist write and Nginx HUP still work for an operator who already has a token.
- [ ] A shell in the helper container cannot read `.env` or `ssl/nginx.key` from a project mount.
- [ ] The Docker socket mount is unchanged.
- [ ] Stage 18 token rules are unchanged.

## Rollback

Put the two volume lines back and recreate the container. Docs-only publication needs no runtime rollback.

## Success metrics

- A helper compromise via the Flask app no longer includes a direct read of host `.env` and TLS keys.
- Contributors can see, from Compose alone, which host paths the landing API is allowed to touch.
