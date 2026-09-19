---
title: Open WebUI Version Update Check Contract
description: Constructional contract to set official ENABLE_VERSION_UPDATE_CHECK=false so Open WebUI does not probe GitHub for newer releases, without turning on full OFFLINE_MODE or rewriting Stage 33 Hugging Face offline embeddings.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Open WebUI Version Update Check Contract

## Problem

The `open-webui` service does not set `ENABLE_VERSION_UPDATE_CHECK`. Official Open WebUI defaults that flag to `true` and contacts GitHub to decide whether to show an update notice. On a digest-pinned private VM, that check is noise: the supported bump path is `./tu-vm.sh update` plus Stage 15 safe-update, not “click the cloud badge.”

`OFFLINE_MODE=true` would also disable the check, but it is a broader official switch (embeddings, remote features). Community suggestions that “just enable offline mode for privacy” over-constrain RAG. Upstream added `ENABLE_VERSION_UPDATE_CHECK` so operators can silence GitHub without full offline mode.

This is distinct from:

- Stage 33 `openwebui-offline-embeddings-contract.md` (HF cache / `HF_HUB_OFFLINE`, not GitHub tags)
- Stage 35 `openwebui-scarf-analytics-contract.md` (Scarf pixels, not version probes)
- Stage 35 `n8n-version-notifications-contract.md` (n8n `api.n8n.io/versions/`)
- Stage 32 unofficial `WEBUI_*` honesty (wrong keys, not this official flag)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | No version-check key; image is digest-pinned |
| Official Open WebUI env | `ENABLE_VERSION_UPDATE_CHECK`, `OFFLINE_MODE` |
| `./tu-vm.sh update` + Stage 15 (expected sibling) | How this repo bumps the digest |
| GitHub Releases / `CHANGELOG.md` | Human update channel |
| GitHub Issues suggestion form | Intake if someone wants a LAN release badge later |

Out of scope:

- Setting `OFFLINE_MODE=true` as a substitute
- Rewriting Stage 33 HF offline embeddings
- A dashboard “Open WebUI is outdated” product
- Scraping GitHub releases from the helper

## Proposal

Set the official granular flag:

```text
ENABLE_VERSION_UPDATE_CHECK: "false"
```

Leave `OFFLINE_MODE` unset/false unless a later Issue needs full offline. Do not invent `TU_VM_WEBUI_SKIP_UPDATE`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that updates are `tu-vm.sh update` |
| Docs | Open WebUI playbook | No in-app GitHub badge; Releases remain the channel |

### Rules

1. **Official key only.** Do not invent a project-local skip flag.
2. **Do not use `OFFLINE_MODE` for this.** Stage 33 already owns embedding offline.
3. **Do not confuse with Scarf.** Analytics is a different official key.
4. **GitHub remains intake.** In-app update UX requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_VERSION_UPDATE_CHECK
2. Set the flag false on the open-webui service
3. Recreate and confirm no GitHub version probe on admin home
4. Keep OFFLINE_MODE off unless embeddings require it (Stage 33)
5. Point operators at tu-vm.sh update
6. Do not rewrite Stage 33 offline-embeddings
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Silence GitHub version badge | Official `ENABLE_VERSION_UPDATE_CHECK` | Full `OFFLINE_MODE` |
| HF model fetch | Stage 33 official HF/offline keys | Mixing model cache with version checks |
| Scarf / DNT | Stage 35 Scarf page + existing DNT | One mega privacy env |
| Image bumps | Stage 15 + `tu-vm.sh update` | Teaching operators to follow the in-app badge |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Missing in-app badge is expected.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_VERSION_UPDATE_CHECK=false`.
- [ ] `OFFLINE_MODE` is not used as the substitute.
- [ ] Stage 33 offline-embeddings page is not rewritten.
- [ ] Docs point at `tu-vm.sh update` / Releases.

## Rollback

Set the flag `true` (official default). Volume/admin config remains.

## Success metrics

- Recreating Open WebUI does not query GitHub for newer tags.
- Community update PRs keep using digest pins instead of chasing the in-app badge.
