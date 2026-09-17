---
title: Ollama Keep-Alive Unload Contract
description: Constructional contract to set official OLLAMA_KEEP_ALIVE and OLLAMA_MAX_LOADED_MODELS so idle models leave RAM/VRAM while the Tier 2 container stays running, instead of a second autostop product.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Ollama Keep-Alive Unload Contract

## Problem

The `ollama` service is Tier 2 (`restart: "no"`) with a 2G memory limit and no official keep-alive env. Once a model is loaded, Ollama’s default keep-alive (typically five minutes, image-dependent) may keep weights in RAM/VRAM after the chat ends. Laptop operators then see idle memory stay high even though the container is “quietly running.”

Community suggestions then rewrite Stage 7 idle autostop (stop the container) or Stage 7 battery widgets. Stopping Ollama is a different control. This page is only **in-process model unload** with official Ollama keys.

This is distinct from:

- Stage 7 `tier2-idle-autostop-policy.md` (stop/start the container)
- Stage 7 `battery-power-operator-signals.md` (dashboard battery chip)
- Stage 8 `smart-startup-optimization.md` (when to start Tier 2)
- Stage 10 `gpu-acceleration-contribution-contract.md` (GPU enablement)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ollama` service | No `OLLAMA_*` keep-alive env today |
| Official Ollama env | `OLLAMA_KEEP_ALIVE`, `OLLAMA_MAX_LOADED_MODELS` |
| Dashboard / `tu-vm.sh` | Start/stop the container (Stage 7) |
| `env.example` | `OLLAMA_GPU_MEMORY` exists; not keep-alive |

Out of scope:

- A second idle-autostop implementation
- Changing Tier 2 restart policy
- An Ollama Kubernetes operator or model catalog rewrite (Stage 8 catalog is a different page)
- Forcing GPU off

## Proposal

Set official keys on the `ollama` service with interpolable defaults aimed at laptops, for example:

```text
OLLAMA_KEEP_ALIVE: ${OLLAMA_KEEP_ALIVE:-2m}
OLLAMA_MAX_LOADED_MODELS: ${OLLAMA_MAX_LOADED_MODELS:-1}
```

Confirm syntax against the pinned `ollama/ollama` digest (`2m` duration vs seconds). Expose both in `env.example`. Workshop hosts that want models hot can set `OLLAMA_KEEP_ALIVE=-1` (official “forever” on current Ollama) without a fork.

Do not add a helper loop that curls `/api/generate` to unload models. Ollama already unloads when keep-alive expires.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `ollama` environment | Official keep-alive + max loaded |
| Env schema | `env.example` | Same keys, laptop defaults documented |
| Docs | energy / Ollama playbook | Unload vs container stop (Stage 7) |

### Rules

1. **Official keys only.** Do not invent `TU_VM_OLLAMA_UNLOAD_CRON`.
2. **Do not rewrite Stage 7 autostop.** Container stop stays that page.
3. **Do not add a helper unload loop.**
4. **GitHub remains intake.** Requests for multi-model routing stay Issues.

### Suggested contributor checklist

```text
1. Confirm keep-alive syntax on the pinned Ollama digest
2. Add interpolable OLLAMA_KEEP_ALIVE and OLLAMA_MAX_LOADED_MODELS
3. Load a model, wait past keep-alive, confirm RAM/VRAM drop while the container stays Up
4. Document -1 / longer values for workshop hosts
5. Do not implement a second autostop in this PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Unload idle weights | Official Ollama env | Custom unload daemon |
| Stop the container | Stage 7 idle autostop | Mixing stop into this page |
| Battery UI | Stage 7 battery signals | Treating keep-alive as a widget |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two Compose lines + `env.example`.
3. Mention that the first token after idle unload will be slower (cold load).

## Acceptance criteria

- [ ] `ollama` sets official keep-alive and max-loaded keys with interpolable defaults.
- [ ] Docs contrast “unload model” vs “stop container”.
- [ ] No unload sidecar or second autostop is added.
- [ ] Stage 7 pages are not rewritten.

## Rollback

Remove the two keys. Image defaults apply again. Models and the named volume remain.

## Success metrics

- Idle laptop memory drops after keep-alive without stopping Ollama.
- Energy Issues split cleanly: this page for weights, Stage 7 for container stop.
