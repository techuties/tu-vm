---
title: Compose Extension Fields DRY Contract
description: Constructional contract for official Compose x- extension fields and YAML anchors so repeated DNS (and later logging) blocks are shared without a Compose preprocessor.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Compose Extension Fields DRY Contract

## Problem

Nearly every service repeats the same fragment:

```yaml
    dns:
      - 127.0.0.11
      - 172.20.0.16
```

The same pattern will return for Stage 11 `logging:`, Stage 28 `pull_policy: missing`, and common `deploy.resources` reservations. Today a contributor who changes Pi-hole’s DNS IP must touch twenty services. That is how IP conflicts and missed `dns:` entries happen (see the `mcp-playwright` / `n8n_mcp` comment in Compose).

The Compose specification already has **extension fields** (`x-*`) and YAML merge keys. The project does not need Jsonnet, Helm, or a custom `render-compose.py`.

This is not Stage 8 `compose.override.yml` (local operator deltas) and not Stage 19 `profiles:` (which services start). It is how **shared fragments** live in the committed file.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Repeated `dns:` blocks in `docker-compose.yml` | Immediate DRY target |
| Compose spec extension fields (`x-*`) | Official, ignored by the engine as service keys |
| YAML anchors / merge (`&`, `<<:`) | Supported by Compose file parse |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local overrides, not committed DRY |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling) | Start sets, not fragments |
| Stage 28 include-split contract | File layout after fragments exist |

Out of scope:

- A Jinja/Jsonnet/CUE preprocessor in CI
- Helm or Kustomize for a Compose stack
- Changing Pi-hole’s `172.20.0.16` address (Stage 18 IPAM)
- Implementing Stage 11 logging here — only reserve an `x-logging` hook

## Proposal

Introduce a short **extension map** at the top of `docker-compose.yml` (or the include root):

```yaml
x-dns-pihole: &dns-pihole
  dns:
    - 127.0.0.11
    - 172.20.0.16

x-pull-digest: &pull-digest
  pull_policy: missing
```

Services merge what they need:

```yaml
  nginx:
    <<: [*dns-pihole, *pull-digest]
    image: nginx@sha256:…
```

Pi-hole itself **must not** merge `x-dns-pihole` (it uses public resolvers). Helper / custom DNS stays explicit.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose root | top-level `x-*` | Anchors for dns, optional pull, later logging |
| Services | merge keys | Replace pasted `dns:` lists |
| Docs | this page + Stage 18 IPAM | Changing `172.20.0.16` is one anchor |
| CI | `./scripts/check-config.sh` | Already renders the merged file |

### Rules

1. **Official Compose only.** `x-*` and YAML anchors. No new render step.
2. **One concern per anchor.** Do not create `x-everything` that hides resource limits.
3. **Exceptions stay local.** Pi-hole DNS, helper `extra_hosts`, and `mcp-playwright` IP comments remain explicit.
4. **Do not merge secrets.** Passwords stay in env.
5. **GitHub remains intake.** Requests for “generate compose from JSON” stay declined unless Compose cannot express the change.

### Suggested contributor checklist

```text
1. Add x-dns-pihole (and optionally x-pull-digest) at file top
2. Replace identical dns: blocks via <<: *dns-pihole
3. Leave pihole, and any service with a different dns:, explicit
4. Confirm docker compose config still renders
5. Confirm rendered dns lists match today’s 127.0.0.11 + 172.20.0.16
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Shared fragments | Compose `x-*` + YAML anchors | Jinja / Jsonnet / Helm |
| Local experiments | `compose.override.yml` (Stage 8) | Editing twenty `dns:` lists |
| File size later | Stage 28 `include:` | A custom splitter first |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: dns anchor first (highest repetition). Add pull/logging anchors when those keys land.
3. Keep the include-split PR **after** anchors exist so fragments are not copied into every file.

## Acceptance criteria

- [ ] Top-level `x-dns-pihole` (or equivalent) exists and is merged by services that today paste the same two resolvers.
- [ ] Pi-hole and other exceptions remain explicit.
- [ ] No new preprocessor script is added.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] Rendered DNS lists match the pre-change values.

## Rollback

Inline the `dns:` lists again and delete the `x-*` map. Runtime behavior is unchanged.

## Success metrics

- Changing Pi-hole’s container DNS IP is a one-anchor edit.
- Community PRs stop pasting a fourth copy of `127.0.0.11`.
- Include-split (Stage 28) reuses the same anchors instead of inventing a template language.
