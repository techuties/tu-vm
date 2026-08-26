---
title: Helper Resource Limits Contract
description: Constructional contract for deploy.resources on helper_index, the last unbounded always-on first-party service, reusing the Nginx/Pi-hole budget instead of a memory governor.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Helper Resource Limits Contract

## Problem

`helper_index` runs for the life of the stack and has **no** `deploy.resources`. Nginx and Pi-hole, which do comparable "small always-on" work, are capped at 256M / 0.25 CPU. Tika and MinIO are covered by Stage 26. The helper is the remaining unbounded always-on first-party container.

The startup command installs `docker-cli`, `docker-cli-compose`, and pip packages **inside** the cgroup. Without a limit, a stuck `pip install` or a runaway `/status` Docker listing can push the helper past the laptop energy budget. With a limit that is too small **before** Stage 22 bake, apk/pip gets OOM-killed and the dashboard never comes up.

Stage 18 tells contributors **how** to pick a budget. This page picks the **helper's** budget.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Nginx / Pi-hole `deploy.resources` | 256M / 0.25 CPU pattern to copy |
| Helper command (apk + pip + Flask) | Why the first-boot reservation must be honest |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | How to budget new services |
| Stage 22 `helper-index-image-bake-contract.md` (expected sibling) | Removes apk/pip from the running cgroup |
| Stage 26 `tika-minio-resource-limits-contract.md` (expected sibling) | Same move for the previous unbounded pair |
| This stage CPU-share page | Relative weight, not the hard cap |

Out of scope:

- A userspace memory governor or `tu-vm.sh` helper watchdog
- Changing Flask concurrency or adding gunicorn as a prerequisite
- Limits for `mcp-gateway` / `langgraph_supervisor` (Tier 2; separate Issue if still unbounded)
- Lowering the cap to "Alpine minimum" before bake

## Proposal

Give `helper_index` an explicit cgroup budget that fits today's apk+pip boot and tomorrow's baked image.

### Contribution lanes

| Lane | When | Memory | CPUs |
|---|---|---|---|
| Now (floating/pinned `python:3-alpine` + apk/pip) | until Stage 22 | limit **512M**, reservation **256M** | limit `0.50`, reservation `0.10` |
| After bake | Stage 22 PR | drop to **256M** / `0.25` to match Nginx | same as Nginx |
| Docs | this page + Stage 18 | Helper is not exempt from budgets |

### Rules

1. **Copy an existing block.** Use the same YAML shape as Nginx/Pi-hole. Do not add a new "helper resources" schema.
2. **Do not under-limit apk/pip.** 256M total is wrong while the command still compiles wheels. 512M is the honest current cap.
3. **Lower the cap in the bake PR.** Stage 22 must not leave the 512M "just in case" once pip is gone.
4. **Shares stay on the sibling page.** This page sets hard caps only.
5. **GitHub remains intake.** "Rewrite helper in Go to fit 32M" stays an Issue.

### Suggested contributor checklist

```text
1. Add deploy.resources to helper_index (512M / 0.50 limit)
2. Copy the YAML shape from nginx, not a new structure
3. Do not add a helper watchdog script
4. After Stage 22 bake, reduce to 256M / 0.25
5. Confirm helper still serves /health on a test stack
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hard cap | Compose `deploy.resources` | Unbounded Flask or a governor |
| First-boot install | 512M until bake | 256M that OOM-kills pip |
| Post-bake budget | Nginx 256M / 0.25 | Keeping 512M forever |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: 512M block now.
3. In the Stage 22 bake PR, lower to the Nginx numbers.

## Acceptance criteria

- [ ] `helper_index` has `deploy.resources` limits and reservations.
- [ ] Current (pre-bake) memory limit is ≥ 512M.
- [ ] YAML shape matches Nginx/Pi-hole.
- [ ] No helper watchdog or governor is added.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Remove the `deploy.resources` block. Image and Flask code are unchanged.

## Success metrics

- Helper disappears from "unbounded Tier 1" reviews.
- Bake PRs include the 256M downsize.
- New first-party always-on services copy a budget in the same PR.
