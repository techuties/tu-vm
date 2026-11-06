---
title: Community Suggestions Website
description: Publishable Stage 70 website markdown for the knowledge-base read size cap, the webhook confirm gate, and unverified write dedupe.
last_updated: 2026-11-06
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend so day-to-day knowledge-base reads, webhook runs, and failed workflow writes stay reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the MCP gateway, the LangGraph supervisor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#95 already specify the docs framework, governance, and the product contracts through Stage 69.

**Stage 70** (this run) records three defects checked on 2026-11-06. They are not restatements of Stages 1–69.

- `KB_MAX_OBJECT_BYTES` stops an oversized `kb_put_object`. `kb_get_object`, `kb_extract_text`, and `kb_index_document` call `get_object_bytes`, which reads the whole object. A 10 MiB plus one byte payload is rejected on put and returned in full on get.
- `n8n_run_webhook` is a write tool. Its handler and schema never require `confirm=true`. `n8n_diagnose_workflow` is not a write tool, and a `testPayload` still POSTs to `/webhook-test/`. The chain smoke only proves the deny path for `n8n_create_workflow`.
- After a write that the gateway marks `claimed: false` and `status: unverified`, both dedupe stores keep that row. The next call with the same intent returns the failure and does not run the tool again.

The contracts:

- Apply `KB_MAX_OBJECT_BYTES` on every gateway read of an object, using the constant put already uses.
- Require `confirm=true` before a webhook is dispatched, including the diagnose test trigger, and extend the existing smoke deny check.
- Store a dedupe row only when the write is claimed. Keep the proof log of the failure so a retry with the same intent can run.

No second object store, approval product, or workflow engine.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–69 website pages (open PRs #27–#95) | Implement those contracts in code; leave their pages as they are |
| `KB_MAX_OBJECT_BYTES` | Size ceiling put already enforces |
| `confirm=true` on the other n8n write handlers | The check to copy |
| `scripts/langgraph-e2e-smoke.sh` | Deny-path smoke to extend |
| Gateway `proof_store` and supervisor audit store | Failure log that stays |

Stage 41 (open PR #67) owns whether anonymous clients may call knowledge-base reads. This stage leaves that default alone and only bounds how many bytes a read pulls. Stage 42 (open PR #68) owns the processor download cap and assumed the gateway read path already used `KB_MAX_OBJECT_BYTES`. The put path does. The read path does not. Stage 45 (open PR #71) owns adding delete tools to the supervisor write set. Stage 47 (open PR #73) owns the empty write-approval token list. Stage 11 (open PR #37) owns the operator policy for confirm, rate limits, and circuit breakers.

## Page map (Stage 70)

| Page | Purpose |
|---|---|
| [Knowledge-base read byte cap](./kb-read-byte-cap-contract.md) | A get, extract, or index must stop at the same byte ceiling as put |
| [Webhook confirm gate](./webhook-confirm-gate-contract.md) | A webhook dispatch must require the confirm flag the other writes use |
| [Unverified write dedupe](./unverified-write-dedupe-contract.md) | A failed verification must not block a retry of the same intent |

## Expected sibling pages

Stages 1–69 are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Leave those files uncopied here.

Representative filenames only: `kb-public-read-default-contract.md`, `processor-object-byte-budget-contract.md`, `autonomous-write-guard-policy.md`, `write-approval-fail-closed-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 70** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Object size | `KB_MAX_OBJECT_BYTES` on read and put | A second quota service |
| Webhook safety | The existing `confirm=true` check and `langgraph-e2e-smoke.sh` | A new approval product |
| Idempotency | The existing dedupe stores, claimed rows only | A new job queue |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: knowledge-base reads stop at the configured byte ceiling
3. Operator day-to-day: an unconfirmed webhook is denied the same way an unconfirmed create is denied
4. Operator day-to-day: a write that failed verification can be retried with the same intent

When a static site is adopted, move or mount these pages into the docs content root. Keep a single editable copy.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
