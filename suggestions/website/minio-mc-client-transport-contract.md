---
title: MinIO mc Client Transport Contract
description: Constructional contract to reach MinIO on its Compose network with mc alias arguments, instead of host networking and a password embedded in a URL.
last_updated: 2026-09-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# MinIO mc Client Transport Contract

## Problem

Two MinIO clients put the root password in a URL and attach the client container to the host network:

```bash
# tu-vm.sh run_minio_mc
docker run --rm --network host \
    -e "MC_HOST_local=http://admin:${minio_pass}@127.0.0.1:9000" \
    minio/mc "$@"
```

```bash
# scripts/sync-openwebui-minio.sh
MC_ENV="MC_HOST_local=http://${ACCESS_KEY}:${MINIO_PASS}@127.0.0.1:9000"
docker run --rm --network host -e "$MC_ENV" minio/mc mb --ignore-existing "local/${BUCKET}"
```

`run_minio_mc` is how `setup_minio_buckets` creates `tika-pipe`, `n8n-workflows`, and `shared-documents` on every successful Tier 1 start. The sync script repeats the same transport on its own cron. Both images are the floating name `minio/mc`. The sync script also probes the upload volume with floating `alpine:latest`.

MinIO is already on `ai_network` at `172.20.0.21` with container name `ai_minio`. Compose publishes `127.0.0.1:9000` only as a localhost convenience. `get_compose_network_name` already reads that network from `docker inspect`. The bucket listing inside `create_backup` already uses it:

```bash
docker run --rm --network "$(get_compose_network_name)" minio/mc \
    sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc ls local"
```

That call has the right network and the wrong credential passing. The password is expanded on the host inside a single-quoted string in `sh -c`. A password that contains `'` closes the quote.

`MC_HOST_local` is a URL. MinIO documents that access and secret keys with reserved characters must be percent-encoded in that URL. Checked on 2026-09-30 with Go 1.22.2 `net/url.Parse` on `http://admin:<password>@127.0.0.1:9000`, the same shape these scripts build. `mc` is a Go program and consumes that value as a URL.

| Password | Go 1.22 `net/url` result |
|---|---|
| Letters and digits only | User `admin`, password unchanged, host `127.0.0.1:9000` |
| Contains `@` or `:` | Accepted by this parser |
| Contains `'` | Accepted by this parser, rejected by the backup `sh -c` quotes |
| Contains `/`, `?`, or `#` | Parse error (`invalid port`) |
| Contains a `%` that is not a hex escape | Parse error (`invalid URL escape`) |
| Contains a space | Parse error (`invalid userinfo`) |

`generate_secrets` strips `=`, `+`, and `/` from new MinIO passwords. It does not strip `?`, `#`, `%`, or space. Operators who set their own `.env` value are not limited to the generated alphabet. `resolve_minio_password` still falls back to the insecure default when `.env` has no value. That default happens to parse, which hides the URL bug until the password changes. Host networking is independent of the parser: every call uses it, including passwords that parse cleanly.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `get_compose_network_name` | Inspects `ai_minio` and prints the Compose network |
| `create_backup` MinIO listing | Already joins that network and calls `mc alias set` |
| `resolve_minio_password` | One password lookup for host scripts |
| `ai_minio` on `ai_network` | In-cluster API at port 9000; no host network required |
| `scripts/sync-openwebui-minio.sh` | Second copy of the host-network client |
| Stage 14 `openwebui-minio-sync-day2-contract.md` (expected sibling, open PR #40) | Playbook for forward and reverse sync. Do not rewrite it |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling, open PR #37) | When cron is installed. The secret-in-crontab bug is the sibling page on this branch |
| Stage 30 `qdrant-minio-healthcheck-binary-contract.md` (expected sibling, open PR #56) | `curl` versus `mc` **inside** the MinIO server image. This page is the **client** container |
| Stage 44 `image-update-compare-contract.md` (expected sibling, open PR #70) | Compose `image:` digest compare. Do not fold ad-hoc `docker run` images into that inventory |

Out of scope:

- A new sync daemon or a watcher beside the processor
- Changing TXT forward and reverse rules (Stage 14)
- Installing `mc` into a derived MinIO server image (Stage 30)
- Replacing Compose’s `127.0.0.1:9000` publish
- Putting the password in the crontab (sibling page on this branch)

## Proposal

One client shape for `run_minio_mc`, the sync script, and the backup listing.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Shared helper | `run_minio_mc` in `tu-vm.sh` | Compose network, `mc alias set` as discrete arguments, then the requested `mc` command |
| Sync script | `scripts/sync-openwebui-minio.sh` | Same network inspect and the same alias arguments. Delete `MC_HOST_local` |
| Backup listing | `create_backup` | Call the helper, or use the same argv form. Delete the `sh -c` password quote |
| Empty-volume probe | sync script | Do not pull `alpine:latest`. When `ai_openwebui` is running, `docker exec` and list `/app/backend/data/uploads` |
| Image | `minio/mc` | Record a digest in the implementation PR the same way Compose records `minio/minio`. Do not leave a floating name |

### Rules

1. **Join the network `ai_minio` is already on.** Use `get_compose_network_name` from `tu-vm.sh`. In the sync script, copy that inspect format. Do not pass `--network host`.
2. **Alias, then command.** `mc alias set local http://ai_minio:9000 <user> <password>` with four separate arguments and no shell. The user stays `MINIO_ROOT_USER` (Compose sets `admin`). The password is an argument, not a URL and not a quoted fragment of `sh -c`.
3. **Do not set `MC_HOST_local`.** That variable is a URL. It cannot carry an unencoded password.
4. **Do not print the password.** The helper’s success and failure lines name the bucket, not the secret.
5. **One floating image is enough to fix.** Pin `minio/mc` when the implementation PR runs. Do not also invent a mirror or a private registry.
6. **The upload probe reuses a running container.** `docker exec ai_openwebui` sees the uploads mount. If Open WebUI is stopped, skip the sync with the existing “nothing to sync” message instead of pulling `alpine:latest`.
7. **Leave Stage 14 semantics alone.** Forward sync still excludes `*.txt`. Reverse sync still includes `*.txt`. Cron opt-in is the sibling page.

### Suggested contributor checklist

```text
1. Replace --network host in run_minio_mc and the sync script with the inspected Compose network
2. mc alias set with user and password as separate argv; delete MC_HOST_local
3. Point create_backup’s listing at that helper
4. Replace alpine:latest with docker exec ai_openwebui, or skip when that container is stopped
5. Record the minio/mc digest used in the PR
6. A password containing / is passed to mc alias set unchanged and the alias succeeds
7. docker compose config is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Network | `get_compose_network_name` | `--network host` so the client can see `127.0.0.1:9000` |
| Credentials | `mc alias set` arguments | `MC_HOST_local` or `sh -c` quotes |
| Password lookup | `resolve_minio_password` and the sync script’s `.env` read | A second secret store |
| Empty upload check | `docker exec` on `ai_openwebui` | `alpine:latest` |
| Server health | Stage 30 image-honest probe | Teaching this client to curl `/minio/health/live` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Change `run_minio_mc` first, then point the sync script and the backup listing at the same shape, in one PR.
3. Re-run bucket setup against a password that contains `/` and one that contains `'`. Confirm `mc ls` still works. Docs-only publication needs no runtime rollback beyond reverting that PR.

## Acceptance criteria

- [ ] `run_minio_mc` and `scripts/sync-openwebui-minio.sh` do not pass `--network host`.
- [ ] Neither file sets `MC_HOST_local`.
- [ ] `mc alias set` receives the user and password as separate arguments, with no `sh -c`.
- [ ] The backup listing uses that same form.
- [ ] The sync script does not pull `alpine:latest`.
- [ ] The implementation PR records a `minio/mc` digest.
- [ ] Stage 14 TXT direction and Stage 30 server healthchecks are unchanged.

## Rollback

Restore the previous `docker run` lines. Buckets and the upload volume stay where they are. Host networking returns, and passwords with URL-reserved characters fail again.

## Success metrics

- Bucket setup and upload sync work when the MinIO password contains `/` or `'`.
- The `mc` container cannot see every host interface just to create `tika-pipe`.
- Contributors stop adding a third MinIO client beside `run_minio_mc` and the sync script.
