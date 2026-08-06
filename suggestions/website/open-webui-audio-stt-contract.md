---
title: Open WebUI Audio / STT Contract
description: Constructional contract for community contributions to Open WebUI speech-to-text configuration that reuses check-openwebui-audio and fix-openwebui-audio instead of inventing a parallel voice product.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Open WebUI Audio / STT Contract

## Problem

Operators enable speech-to-text (STT) in Open WebUI and then hit silent config drift between the UI, database, Redis, and Compose env. Historical suggestions reinvent cloud voice gateways or always-on microphone agents. The community needs a **reuse-first audio/STT contract** that extends the existing check/fix helpers for day-to-day recovery.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh check-openwebui-audio` | Validate Open WebUI STT config consistency |
| `./tu-vm.sh fix-openwebui-audio` | Repair STT config (DB + Redis) |
| Open WebUI Compose service + env | Primary chat UI and audio settings surface |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Broader UI/init/tool wiring rules |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local-only audio experiments |
| Stage 9 `privacy-preserving-usage-analytics.md` (expected sibling) | Local-only metrics—no voice upload analytics |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | General triage order when audio is one symptom |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |

Out of scope:

- Mandatory cloud STT vendors as the default path
- Storing or uploading operator voice samples to public GitHub Issues
- Building a second voice assistant product beside Open WebUI
- Auto-enabling microphones on every client without operator consent

## Proposal

Publish an **Open WebUI audio / STT contract** with clear lanes for contributors and operators.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Check helper | `check-openwebui-audio` path in `tu-vm.sh` / scripts | Deterministic pass/fail; no secret print |
| Fix helper | `fix-openwebui-audio` | Idempotent repair; documents what it mutates |
| Env / Compose wiring | Open WebUI audio-related env keys | `env.example` comments; Stage 12 env-schema rules |
| Docs / playbooks | `#playbook-open-webui-audio` (proposed) | Check → fix → verify order |
| Local experiments | Compose overrides | Stage 8 override contract |

### Rules

1. **One voice surface.** Improve Open WebUI STT before proposing a parallel voice stack.
2. **Check before fix.** Day-to-day runbooks start with `check-openwebui-audio`.
3. **Fix stays scoped.** Repair helpers may touch Open WebUI DB + Redis audio keys only—not unrelated services.
4. **No voice in Issues.** Contributors paste checker output (redacted), never audio files or transcripts with personal content.
5. **Secrets stay out of logs.** API keys for optional remote STT never appear in checker stdout or CI logs.
6. **Tier honesty.** Document whether Ollama/local STT or an optional remote loader is assumed.
7. **GitHub remains intake.** Feature ideas for new STT backends go through Issues/PRs with this contract linked.

### Suggested playbook shape

```text
#playbook-open-webui-audio
1. Ensure Open WebUI (and dependencies) are up
2. ./tu-vm.sh check-openwebui-audio
3. ./tu-vm.sh fix-openwebui-audio   # only if check fails and repair is desired
4. ./tu-vm.sh check-openwebui-audio # confirm green
5. Manual UI smoke: one short non-sensitive phrase in a private LAN session
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| STT product | Open WebUI audio settings | Custom nginx-hosted voice SPA |
| Recovery | Existing check/fix helpers | Manual Redis surgery without docs |
| Privacy | Local LAN testing | Pasting recordings into public trackers |
| Experiments | Compose overrides | Hardcoding vendor keys in git |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-open-webui-audio` when implementing docs polish.
3. Cross-link Stage 10 Open WebUI contract and Stage 12 diagnostics.
4. Prefer **code** improvements to check/fix messaging over more suggestion prose.

## Acceptance criteria

- [ ] Lanes distinguish check vs fix vs env vs docs.
- [ ] Check-before-fix rule is explicit.
- [ ] Voice/transcript privacy rule is explicit.
- [ ] Playbook lists the default recovery command order.
- [ ] No mandatory cloud STT default is introduced.

## Rollback

Remove experimental STT env keys or helper flags; operators continue with Open WebUI UI settings and README troubleshooting. No stack-wide downtime required for docs-only publication.

## Success metrics

- More audio Issues cite `check-openwebui-audio` output.
- Fewer proposals to replace Open WebUI with a voice SaaS.
- Faster recovery from DB/Redis STT config drift.
