---
title: Compose Include Split Contract
description: Constructional contract for official Compose include so the monolith can be split for community CODEOWNERS and reviews without a custom stack splitter or a second orchestrator.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Compose Include Split Contract

## Problem

`docker-compose.yml` is an 880-line monolith. Community PRs that touch n8n, AFFiNE, or MCP tools all collide on one file. `CODEOWNERS` cannot route “MCP reviewers” without also pinging them for Nginx TLS. New contributors cannot see the Tier 1 surface without scrolling past AFFiNE migration.

The Compose specification already has **`include:`** (Compose file version that Docker Compose v2 supports). The project already has `COMPOSE_FILE` / `-f` conventions inside `tu-vm.sh` and `check-config.sh`. We do not need a Helm chart, a `render-stack.py`, or a monorepo codegen.

This is not Stage 8 overrides (local, uncommitted). It is not Stage 19 `profiles:` (what starts). It is **file layout** so humans and CODEOWNERS can work.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` | Current single source |
| `tu-vm.sh` `DOCKER_COMPOSE_FILE` | CLI entry |
| `./scripts/check-config.sh` / smoke-test | Render path |
| Stage 5 `codeowners-review-routing` / Stage 16 CODEOWNERS (expected siblings) | Review routing once files exist |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local deltas stay `compose.override.yml` |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling) | Start sets; complementary |
| Stage 28 extension-fields contract | Shared `x-*` anchors live in the include root |

Out of scope:

- Kubernetes / Nomad / a custom orchestrator
- Splitting helper Python or nginx vhosts in the same PR
- Changing Tier 1 vs Tier 2 start policy
- Generating Compose from JSON

## Proposal

Keep **one committed root** that Compose and `tu-vm.sh` already know: `docker-compose.yml`. Turn that root into an include list plus shared `x-*` anchors and the `volumes:` / `networks:` declarations.

Suggested first split (not a dozen micro-files):

```text
docker-compose.yml          # include list, x-* anchors, volumes, networks
compose/tier1-core.yml      # postgres redis qdrant open-webui pihole nginx helper
compose/tier1-docs.yml      # tika minio tika_minio_processor
compose/tier2-ai.yml        # ollama browserless
compose/tier2-n8n.yml       # n8n n8n_mcp mcp_gateway langgraph_supervisor
compose/tier2-affine.yml    # affine affine_migration affine_postgres affine_redis
compose/tier2-mcp-tools.yml # mcp-playwright filesystem fetch memory
```

Root sketch:

```yaml
include:
  - path: compose/tier1-core.yml
  - path: compose/tier1-docs.yml
  - path: compose/tier2-ai.yml
  - path: compose/tier2-n8n.yml
  - path: compose/tier2-affine.yml
  - path: compose/tier2-mcp-tools.yml

x-dns-pihole: &dns-pihole
  dns:
    - 127.0.0.11
    - 172.20.0.16

volumes:
  # existing named volumes (unchanged keys)

networks:
  ai_network:
    # existing IPAM
```

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `docker-compose.yml` + `compose/*.yml` | Official `include:` |
| `tu-vm.sh` | `DOCKER_COMPOSE_FILE` | Stay pointing at the root file |
| Scripts | smoke / check-config / helper mount | Keep `-f docker-compose.yml` |
| CODEOWNERS | `compose/tier2-*.yml` | Route MCP/n8n/AFFiNE reviewers |
| Helper | `./docker-compose.yml:/app/docker-compose.yml` | Root file is enough if include paths resolve |

### Rules

1. **One root file.** Do not teach operators a five-flag `docker compose -f a -f b` ritual. `include:` is the ritual.
2. **Stable volume and network names.** Renaming `postgres_data` or `ai_network` is a data event, not a split.
3. **Anchors live in the root** (or a tiny `compose/_fragments.yml` included first). Do not duplicate `x-dns-pihole` per file.
4. **Helper bind-mount.** If include paths are relative, mount the project directory (already `.:/docker-project:ro`) and set the working compose path accordingly. Do not copy fragments into the image.
5. **GitHub remains intake.** Requests for “generate the stack from a spreadsheet” stay declined.

### Suggested contributor checklist

```text
1. Land Stage 28 x-* dns anchors first (or in the same PR)
2. Move services into the six compose/*.yml files without renaming volumes
3. Leave docker-compose.yml as include + volumes + networks + anchors
4. Keep tu-vm.sh and smoke-test on docker-compose.yml only
5. Confirm docker compose config still renders the same service list
6. Add CODEOWNERS lines for compose/tier2-*.yml
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| File split | Compose `include:` | Helm / Jsonnet / `render-compose.py` |
| Local extras | `compose.override.yml` | Forking the include tree |
| What starts | Stage 19 `profiles:` | Encoding start policy in file names only |
| Review routing | CODEOWNERS on `compose/` | Mentions in every monolith PR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** after the DRY anchors exist so fragments are not copy-pasted into six files.
3. Do the split as its own PR (easy revert). Do not mix pin bumps or resource limits into that PR.

## Acceptance criteria

- [ ] `docker-compose.yml` remains the only file operators and `tu-vm.sh` name.
- [ ] Services live under `compose/*.yml` via official `include:`.
- [ ] Named volumes and `ai_network` IPAM keys are unchanged.
- [ ] `docker compose config` service list matches the pre-split list.
- [ ] smoke-test / check-config / helper still use the root file.
- [ ] No preprocessor script is added.

## Rollback

Concatenate the included files back into `docker-compose.yml` and delete `compose/`. Volume data is unchanged.

## Success metrics

- n8n PRs no longer rewrite Nginx lines by accident.
- CODEOWNERS can require MCP reviewers only on `compose/tier2-mcp-tools.yml`.
- New contributors open `compose/tier1-core.yml` and see the always-on set.
