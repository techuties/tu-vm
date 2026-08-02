---
title: Ollama Model Catalog Contribution
description: Constructional contract for community contributions that document and recommend local Ollama models using a small YAML catalog and playbooks instead of inventing a model marketplace.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: integrations
impact: medium
---

# Ollama Model Catalog Contribution

## Problem

Ollama is already a Tier 2 inference engine in Compose. Community threads and historical suggestions repeatedly ask “which model should I pull on 8GB / 16GB / GPU?” Answers live in chat, stale gists, or proposed custom model stores. Day-to-day life needs a **reuse-first catalog** that points at `ollama pull` and hardware classes—not a reinvented Hugging Face.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `ollama` service | Local model runtime |
| Open WebUI | Operator-facing model selection UI |
| Stage 2 `hardware-compatibility-matrix.md` (expected sibling) | RAM/GPU class fit |
| Stage 2 `persona-entry-paths.md` (expected sibling) | First-hour routes including AI Mode |
| Stage 2/4 operator profiles | When Ollama should be running |
| Stage 7 `service-dependency-map.md` (expected sibling) | Open WebUI ↔ Ollama deps |
| Stage 4/1 MCP catalogs | Parallel pattern for YAML + CI catalogs |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |

Out of scope:

- Hosting model weights in this git repository
- Building a TU-VM-specific model registry or paid marketplace
- Making Ollama Tier 1 / always-on
- Auto-pulling large models during `./tu-vm.sh start` without explicit consent

## Proposal

Publish a **model catalog contribution contract** mirroring the MCP catalog pattern at human scale first, machine-validated second.

### Suggested layout

```text
models/
  catalog.yaml          # id, ollama_name, min_ram_gb, min_vram_gb, personas, notes
  README.md             # how to propose entries
```

### Entry fields (v1)

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Stable slug, e.g. `llama3-8b-q4` |
| `ollama_name` | yes | Exact `ollama pull` target |
| `min_ram_gb` | yes | Align with Stage 2 hardware classes |
| `min_vram_gb` | no | GPU path; omit for CPU-only tips |
| `personas` | no | `researcher`, `coder`, … |
| `quantization` | no | Human hint only |
| `license_notes` | yes | Short redistribution/use caution |
| `verified_on` | no | TU-VM version or date smoke-tested |

### Contribution rules

1. **Document, do not vendor weights.**
2. **Prefer official Ollama library names** over opaque custom blobs unless an extension package owns the pull script.
3. **Tie entries to hardware classes** so 8GB hosts are not nudged toward 70B models.
4. **Keep Tier 2 explicit**—catalog pages must say how to leave Ollama stopped.
5. **No secret keys** in catalog notes (some gated models need operator-local auth; document the env var name only).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Runtime | Existing Ollama service | New inference sidecar per model family |
| Discovery | YAML catalog + website page | Scraping random model blogs into the dashboard |
| Validation | Optional CI schema check (Stage 6 frontmatter pattern) | Manual-only forever with drift |
| UI | Open WebUI model picker | Rebuilding a model store inside nginx HTML |

## Rollout

1. Land this page; add a stub `models/catalog.yaml` only when maintainers are ready for the code PR.
2. Cross-link Stage 2 hardware matrix classes (`class_id`).
3. Add playbook anchor `#playbook-pull-model` with copy-paste `docker exec` / `ollama pull` examples.
4. Optional later: `scripts/validate-models-catalog.py` following Stage 4 MCP catalog CI.

## Acceptance criteria

- [ ] Catalog contributions never commit model weight binaries.
- [ ] Each entry states minimum RAM (and VRAM when relevant).
- [ ] Docs state Ollama remains optional Tier 2.
- [ ] License/use notes are present for every entry.
- [ ] First milestone can be docs-only; CI validation is optional follow-up.

## Rollback

Remove or deprecate catalog entries via Stage 6 deprecation notices. Operators keep whatever models already pulled locally; stopping Ollama does not require catalog presence.

## Success metrics

- Fewer duplicate “what model fits my RAM?” Issues.
- Community PRs add catalog rows instead of proposing a custom model hub.
- Hardware-class misfit complaints drop after matrix + catalog cross-links ship.
