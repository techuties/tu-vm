---
title: Open WebUI Profile Image URL Forwarding Contract
description: Constructional contract to set official ENABLE_PROFILE_IMAGE_URL_FORWARDING=false so avatar endpoints do not 302 browsers to attacker-stored origins.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Profile Image URL Forwarding Contract

## Problem

Official Open WebUI documents `ENABLE_PROFILE_IMAGE_URL_FORWARDING` with default `true`. When a user or model `profile_image_url` is an external `http(s)` URL, the profile-image endpoint answers with `302 Found`. The browser then requests that origin directly and sends client IP, User-Agent, and Referer.

On a shared LAN community stack, any account that can store an avatar URL can use that redirect to observe who rendered the avatar. Compose does not set the flag today, so the product default stays on.

The same official reference states this variable is read once at startup. It is not a `ConfigVar` and the Admin UI cannot change it. A Compose pin is the source of truth.

This is distinct from:

- Stage 36 `openwebui-session-cookie-contract.md` (session cookie flags)
- Stage 36 `openwebui-persistent-config-honesty-contract.md` (ConfigVar store; this flag is startup-only)
- Stage 33 `openwebui-community-sharing-contract.md` (chat share links)
- Stage 38 `openwebui-admin-chat-access-contract.md` (admin reading other chats)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | Set the flag `false` to suppress external avatar redirects |
| Official env reference | Default `true`; data URIs and same-origin images still render |
| `open-webui` environment | Flag unset (product default on) |
| GitHub Issues | Place to request Gravatar or IdP avatar redirects later |

Out of scope:

- A custom avatar proxy or image-cache service
- Changing `PROFILE_IMAGE_ALLOWED_MIME_TYPES` or `PROFILE_IMAGE_MAX_DATA_URI_SIZE` in this contract
- Rewriting community-sharing or session-cookie pages

## Proposal

Set the official startup flag on the `open-webui` service:

```text
ENABLE_PROFILE_IMAGE_URL_FORWARDING: "false"
```

Do not invent `TU_VM_BLOCK_AVATARS`. Bundled default images, data URIs, and same-origin static images continue to load. Operators who rely on Gravatar or an identity-provider redirect keep the product default only through an accepted Issue.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that external avatar redirects are off |
| Docs | Open WebUI playbook | Note that data-URI avatars still work |
| Code | Recreate the container | Startup-only; Admin UI cannot override |

### Rules

1. **Official key only.** Match the Open WebUI env reference spelling.
2. **Leave MIME and size limits alone.** Those are separate official keys.
3. **Do not add an image proxy.** The bundled default image is the fallback.
4. **Startup pin.** Recreate Open WebUI after the change. Do not document an Admin toggle for this flag.
5. **GitHub remains intake.** External-avatar exceptions stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_PROFILE_IMAGE_URL_FORWARDING
2. Set the flag false on the open-webui service
3. Recreate Open WebUI
4. Store an external http avatar URL and confirm the endpoint serves the bundled image
5. Confirm a data-URI PNG avatar still renders
6. Do not add an avatar proxy service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop avatar redirects | Official `ENABLE_PROFILE_IMAGE_URL_FORWARDING` | A custom image proxy |
| Inline avatars | Official data-URI path (unchanged) | Blocking all profile images |
| Exceptions | GitHub Issue | A per-user redirect allowlist service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and a container recreate.
3. Missing external avatars are expected on a LAN community VM.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_PROFILE_IMAGE_URL_FORWARDING=false`.
- [ ] No avatar-proxy container or helper route is added.
- [ ] MIME allowlist and max data-URI size are unchanged by this contract.

## Rollback

Remove the key or set it `true` (official default) and recreate Open WebUI. External `http(s)` avatars redirect again.

## Success metrics

- Profile-image responses for external URLs do not return `302` to a third-party origin.
- Data-URI and bundled avatars still render in the chat UI.
