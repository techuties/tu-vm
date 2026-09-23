---
title: Open WebUI Profile Image Data URI Size Contract
description: Constructional contract to set official PROFILE_IMAGE_MAX_DATA_URI_SIZE so inline avatars and model icons cannot grow Postgres and Redis without a cap.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Profile Image Data URI Size Contract

## Problem

The pinned Open WebUI image reads `PROFILE_IMAGE_MAX_DATA_URI_SIZE` once at startup in `backend/open_webui/env.py`. The comment in that revision says an unset value disables the cap. Compose leaves the key unset, so a `data:image/...;base64,...` avatar or model icon can be stored at any length.

Current Open WebUI env reference describes the same key: the limit is the length of the data URI in bytes, it applies to user avatars and model icons, and `262144` (256 KiB of base64 text) is about 190 KiB of image. `http(s)` URLs and built-in static paths are not counted. The key is not a `ConfigVar`.

This is distinct from Stage 38 `openwebui-profile-image-url-forwarding-contract.md` (expected sibling), which pins `ENABLE_PROFILE_IMAGE_URL_FORWARDING=false` so the profile endpoint does not redirect browsers to an external origin. Forwarding and inline size are different knobs. This page does not change forwarding.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Unset `PROFILE_IMAGE_MAX_DATA_URI_SIZE` means no cap; read at startup |
| Open WebUI env reference | Example cap `262144` bytes of the data URI |
| Stage 38 forwarding contract (expected sibling) | External URL redirects |
| Postgres + Redis | Where oversized inline images land |
| GitHub Issues | Place to raise the cap |

Out of scope:

- An avatar bucket, image proxy, or Gravatar service
- Changing `ENABLE_PROFILE_IMAGE_URL_FORWARDING` (Stage 38)
- Changing `PROFILE_IMAGE_ALLOWED_MIME_TYPES` unless an Issue names a missing type
- Admin export or chat-access settings (Stage 38)

## Proposal

Set the official key on the `open-webui` service:

```text
PROFILE_IMAGE_MAX_DATA_URI_SIZE: "262144"
```

That is the documented example: 256 KiB of base64 text. Do not invent `TU_VM_AVATAR_MAX`. Because the key is startup-only, a change needs an Open WebUI recreate. Admin UI cannot override it.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `262144` |
| Env schema | `env.example` | Comment: bytes of the data URI, not decoded pixels |
| Docs | Open WebUI playbook | Point external avatars at Stage 38, not a larger inline cap |
| Storage | Postgres / Redis | No new avatar volume |

### Rules

1. **Bytes of the data URI.** The cap is the stored string, which is larger than the raw image.
2. **Only `data:` URIs.** HTTP avatar URLs stay on the Stage 38 forwarding contract.
3. **Startup-only.** Do not document an Admin toggle for this key on this image.
4. **Do not add object storage for avatars.** The cap is the official bound.
5. **GitHub remains intake.** A larger cap names who needs it.

### Suggested contributor checklist

```text
1. Confirm the pinned image still treats an empty PROFILE_IMAGE_MAX_DATA_URI_SIZE as no cap
2. Set PROFILE_IMAGE_MAX_DATA_URI_SIZE=262144 on the open-webui service
3. Recreate Open WebUI
4. Confirm a data URI longer than 262144 bytes is rejected on save
5. Leave ENABLE_PROFILE_IMAGE_URL_FORWARDING to Stage 38
6. Do not add an avatar store
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Inline avatar bytes | Official `PROFILE_IMAGE_MAX_DATA_URI_SIZE` | A custom image service |
| External avatar URLs | Stage 38 forwarding flag | Folding redirects into this page |
| MIME allowlist | Existing `PROFILE_IMAGE_ALLOWED_MIME_TYPES` default | A new content sniffer |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an Open WebUI recreate.
3. A higher cap needs an Issue that accepts the Postgres and Redis growth.

## Acceptance criteria

- [ ] `open-webui` sets `PROFILE_IMAGE_MAX_DATA_URI_SIZE=262144`.
- [ ] `ENABLE_PROFILE_IMAGE_URL_FORWARDING` is not edited by this change.
- [ ] No avatar proxy or object-storage path is added.

## Rollback

Remove the key to restore the uncapped inline default. That rollback should be explicit, because the pin exists to stop unbounded rows.

## Success metrics

- New inline avatars and model icons above 256 KiB of data-URI text are rejected.
- Profile-image URL forwarding behavior is unchanged by this page.
