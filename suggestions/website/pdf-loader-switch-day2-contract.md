---
title: PDF Loader Switch Day-2 Contract
description: Constructional day-to-day contract for scripts/switch-pdf-loader.sh (Tika vs PyMuPDF) that complements PDF operator status tools without inventing a parallel document-engine product.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# PDF Loader Switch Day-2 Contract

## Problem

Operators sometimes need to toggle PDF extraction engines when Tika is heavy or PyMuPDF is insufficient. Historical suggestions replace the whole pipeline or hardcode one engine in undocumented Compose edits. Stage 13 covers PDF *status/test/logs/reset*; Stage 10 covers pipeline engineering. This page contracts the **loader switch** helper for day-to-day use.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/switch-pdf-loader.sh` | Toggle `tika` vs `pymupdf` |
| Stage 13 `pdf-operator-day2-contract.md` (expected sibling) | `pdf-status` / `pdf-test` / `pdf-logs` / `pdf-reset` |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Processor/Compose contribution rules |
| Stage 14 Open WebUI ↔ MinIO sync page (sibling) | Ensure inputs reached MinIO before blaming loader |
| Stage 2 `hardware-compatibility-matrix.md` (expected sibling) | CPU/RAM expectations for OCR-heavy paths |
| Stage 6 `deprecation-notice-framework.md` (expected sibling) | If a loader path is retired |
| Helper PDF processing status | Dashboard progress notifications |

Out of scope:

- Mandatory cloud OCR vendors as the default community path
- Silent Compose image edits that bypass the switch script
- Using loader switches to fix MinIO credential or sync outages
- Committing private PDFs as “switch test fixtures”

## Proposal

Publish a **PDF loader switch day-2 contract** with explicit decision and verification steps.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Switch script | `scripts/switch-pdf-loader.sh` | Supported values; failure messages |
| Operator docs | playbooks / README | When to choose each loader |
| Pipeline engineering | Stage 10 | New engines or processor changes |
| Runtime proof | Stage 13 PDF day-2 tools | Before/after `pdf-test` |
| Hardware guidance | Stage 2 matrix | Class fit for Tika/OCR |

### Rules

1. **Prefer the script over hand-editing.** Documented loader changes go through `switch-pdf-loader.sh` (or a future `tu-vm.sh` thin wrapper).
2. **Diagnose layer first.** Confirm sync + MinIO + processor health before switching engines.
3. **Prove with tiny public PDFs.** Use Stage 13 `pdf-test` / status tools; never upload private corpora to “try switches” in shared logs.
4. **Name the trade-offs.** Community docs should say Tika (heavier/general) vs PyMuPDF (lighter/limited) in plain language.
5. **Resource honesty.** Point at hardware matrix classes when recommending Tika/OCR-heavy defaults.
6. **No silent defaults drift.** PRs that change the default loader need CHANGELOG/operator notes (Stage 14 release-notes contract).
7. **GitHub remains intake.** New engine proposals are Issues evaluated against extending the existing switch, not parallel stacks.

### Suggested playbook shape

```text
#playbook-pdf-loader
1. ./tu-vm.sh pdf-status          # or equivalent Stage 13 tools
2. ./scripts/sync-openwebui-minio.sh   # if uploads may be unsynced
3. ./scripts/switch-pdf-loader.sh tika|pymupdf
4. ./tu-vm.sh pdf-test            # tiny public-domain sample
5. ./tu-vm.sh pdf-logs            # confirm engine path on failure
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Engine toggle | `switch-pdf-loader.sh` | Undocumented Compose surgery |
| Runtime proof | Stage 13 PDF day-2 toolkit | Guessing from UI alone |
| Pipeline code | Stage 10 contract | Parallel ingest rewrite |
| Default changes | CHANGELOG + release notes | Quiet default flips |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-pdf-loader` when docs polish lands (Stage 10 already anticipated this anchor).
3. Cross-link Stage 13 PDF day-2 and Stage 14 sync pages.
4. Prefer **code** a thin `tu-vm.sh pdf-loader` wrapper for discoverability (Stage 14 CLI contract).

## Acceptance criteria

- [ ] Loader switch is distinct from PDF status/reset and pipeline engineering pages.
- [ ] Diagnose-before-switch and public-sample proof rules are explicit.
- [ ] Trade-off and hardware-honesty guidance is present.
- [ ] Default-loader changes require operator-facing notes.
- [ ] No cloud OCR prerequisite is introduced.

## Rollback

Re-run the switch script to the previous loader; restart affected services per script semantics. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer undocumented Compose edits for loader changes.
- Clearer triage between sync failures and engine limitations.
- Decline in “replace Tika entirely” suggestions when a toggle suffices.
