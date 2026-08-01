---
title: Compose Override Contribution Contract
description: Constructional rules for community Compose customizations that preserve upstream docker-compose.yml and reuse extension/override patterns instead of forking the stack.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Compose Override Contribution Contract

## Problem

Contributors often customize ports, resource limits, device mounts (GPU), or extra sidecars by editing `docker-compose.yml` directly. That creates painful merge conflicts on every upstream update. Historical suggestions proposed “community compose forks.” Day-to-day maintainability needs a **contract for overrides and extensions** that keeps the canonical compose file stable.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` | Canonical service definitions |
| Docker Compose override files / multiple `-f` merges | Upstream-supported customization |
| Stage 3 `extension-pilot-contract.md` (expected sibling) | Packaged extension shape |
| Stage 4 `extension-pilot-scaffold.md` (expected sibling) | `extensions/<id>/` + validator |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Nginx/allowlist safety |
| Stage 7 `service-dependency-map.md` (expected sibling) | Declared start dependencies |
| `./scripts/check-config.sh` / `docker compose config` | Render validation |
| `.gitignore` | Keep local overrides out of git when private |

Out of scope:

- Replacing Compose with a custom YAML dialect
- Publishing private host paths or LAN IPs into the main repo by default
- Letting overrides weaken TLS, auth, or allowlist defaults silently
- Duplicating Stage 3/4 extension packaging under a new name

## Proposal

Separate three customization lanes and document them on the website.

### Lanes

| Lane | Location | Audience | Upstream merge? |
|---|---|---|---|
| **Local override** | `docker-compose.override.yml` (gitignored or private) | Single operator | No—stays local |
| **Shared recipe** | Documented snippet under playbooks / website | Community copy-paste | Docs PR only |
| **First-class extension** | `extensions/<id>/` per Stage 3/4 | Reusable package | Yes—via extension contract |

### Rules

1. **Prefer override or extension over editing `docker-compose.yml`.** PRs that touch the canonical file must justify why an override cannot work.
2. **Render before claim.** `sudo docker compose -f docker-compose.yml -f <override> config --quiet` must pass.
3. **Declare security impact.** Any override that opens ports, adds `privileged`, mounts Docker socket, or changes allowlists needs an explicit SECURITY/RFC note.
4. **Stay compatible with Tier 1/Tier 2.** Overrides should not force Tier 2 services into always-on without profile awareness.
5. **Name collisions.** Extension service names must not clash with core services; document a prefix convention (`ext_<id>_`).
6. **Document rollback.** Removing the override file must restore upstream behavior.

### Suggested website living table

| Customization | Recommended lane | Example |
|---|---|---|
| GPU device for Ollama | Local override or extension | Add `device_requests` in override |
| Extra bind mount for datasets | Local override | Host path → MinIO/data volume |
| Optional monitoring tweak | Shared recipe → then extension | Documented Grafana panel first |
| New optional tool image | Extension pilot | Stage 3/4 package |

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Merge model | Compose native multi-file | Forked mega-compose in a wiki |
| Packaging | Stage 3/4 extensions | Ad-hoc zip of random YAML |
| Validation | `compose config` + check-config | Untested paste into production |
| Secrets | `.env` + Stage 8 hygiene page | Hardcoded passwords in override YAML |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Ensure `.gitignore` guidance for local override files is linked from CONTRIBUTING.
3. Cross-link Stage 3/4 extension pages as the promotion path from recipe → package.
4. Add a CI optional job later that validates sample overrides under `fixtures/compose-overrides/` (no secrets).

## Acceptance criteria

- [ ] Website clearly distinguishes local override vs shared recipe vs extension.
- [ ] CONTRIBUTING (or this page) tells contributors not to fork `docker-compose.yml` for personal tweaks.
- [ ] At least one example override snippet is documented without private host details.
- [ ] Security-sensitive override classes are called out explicitly.
- [ ] Extension pilot remains the path for reusable community packages.

## Rollback

Keep advisory. Sample fixtures can be deleted without affecting production compose. Operators delete local override files to return to upstream.

## Success metrics

- Fewer PRs that conflict on unrelated compose pin churn because of local edits.
- More extension packages and fewer “here is my entire compose” pastebins in Issues.
- Faster `update` success rate for customized installs.
