---
title: MinIO SSE and KMS Contract
description: Constructional contract for optional MinIO server-side encryption at rest using SSE-S3 or a local KMS secret, without Vault, a second object store, or changing bucket ILM.
last_updated: 2026-08-23
owner: maintainers
status: proposed
theme: security
impact: high
---

# MinIO SSE and KMS Contract

## Problem

`minio_data` stores RAG corpora, n8n workflow objects, and processed text as plaintext on the host volume. Disk theft, an unsanitized host backup, or a copied volume tarball exposes object bytes.

README already claims backup archives are encrypted (they are not — see the backup-archive contract). Contributors who notice plaintext objects often propose Ceph, SeaweedFS, or HashiCorp Vault as a KMS.

Stage 15 covers **bucket naming and corpus hygiene**. Stage 23 covers **versioning and ILM**. This page is only **how objects are encrypted at rest inside MinIO**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `minio` | Official image; root user/password; no KMS env |
| `tu-vm.sh` `setup_minio_buckets` / `mc` helper | Existing bucket bootstrap path |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Volume/corpus hygiene, not SSE |
| Stage 15 `minio-bucket-lifecycle-contract.md` (expected sibling) | Bucket names and retention |
| Stage 23 `minio-object-versioning-ilm-contract.md` (expected sibling) | Versioning / noncurrent expire |
| Stage 9 `offsite-backup-rclone-contract.md` (expected sibling) | Remote copy of **archives**, not object SSE |

Out of scope:

- Replacing MinIO
- HashiCorp Vault, cloud KMS, or a KES cluster
- Encrypting host LUKS in this contract (host disk encryption is an operator OS choice)
- Changing ILM rules or bucket names in the same PR

## Proposal

Keep plaintext SSE **off** as the energy-and-simplicity default. Offer **opt-in SSE-S3** using MinIO's built-in key, or a single local `MINIO_KMS_SECRET_KEY`, applied with existing `mc encrypt`.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | no KMS env | Today's clone path |
| Opt-in SSE-S3 | `mc encrypt set sse-s3 <alias>/<bucket>` in bucket setup | Existing `mc` helper |
| Optional local KMS | `MINIO_KMS_SECRET_KEY` on `minio` | Official MinIO env; one key in `.env` |
| Docs | playbook + `env.example` comment | How to enable; how to disable new writes |

### Rules

1. **Opt-in only.** Do not enable SSE on every laptop; CPU and key-loss risk are real.
2. **Use MinIO SSE, not a sidecar encryptor.** No custom Python wrapper around PUT/GET.
3. **Prefer SSE-S3 before KES.** A single local KMS secret is enough. Do not add Vault or a KES replica set.
4. **ILM stays Stage 23.** Encryption flags must not rewrite versioning or expire rules.
5. **Key loss is data loss.** Document that `MINIO_KMS_SECRET_KEY` belongs in `.env` backups and that rotation is a planned maintenance task, not a dashboard click.
6. **GitHub remains intake.** Requests for Ceph/Vault stay Issues.

### Suggested contributor checklist

```text
1. Read minio service env and setup_minio_buckets
2. Add an opt-in flag (for example MINIO_SSE=s3) defaulting to off
3. When on, call mc encrypt set via the existing mc helper after buckets exist
4. Do not add Vault, KES HA, or a second object store
5. Leave versioning/ILM commands unchanged
6. Document key backup and the irreversible cost of losing MINIO_KMS_SECRET_KEY
7. Confirm existing mc alias and healthcheck still work
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Object SSE | Official MinIO SSE-S3 / `mc encrypt` | Custom encrypt-on-write workers |
| Key storage | `.env` / optional Stage 22 `*_FILE` | Vault, cloud KMS, committed keys |
| Lifecycle | Stage 23 `mc ilm` | Encoding retention inside ciphertext metadata |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one env flag + `mc encrypt` in the existing bucket setup path.
3. Keep default clones unencrypted until an operator opts in.

## Acceptance criteria

- [ ] Default `docker compose up` does not require a KMS key.
- [ ] Opt-in SSE uses official MinIO SSE-S3 or `MINIO_KMS_SECRET_KEY`.
- [ ] No Vault / KES cluster / second object store is introduced.
- [ ] Stage 23 versioning/ILM commands remain valid on encrypted buckets.
- [ ] Key-backup and key-loss behavior is documented beside `env.example`.

## Rollback

Unset the flag and stop applying `mc encrypt` to new buckets. Existing ciphertext objects still need the old key; do not promise silent plaintext downgrade.

## Success metrics

- Operators who want at-rest object encryption can enable it without a new product.
- Contributors stop proposing Vault as a prerequisite for MinIO on a LAN VM.
- Bucket setup remains one `mc` helper path.
