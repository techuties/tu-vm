---
title: Rollout Gates and Proof-Store Contract
description: Constructional contract for day-to-day use of scripts/rollout-gates.sh and the MCP Gateway proof store so community releases verify supervised writes without inventing a second release-quality product.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Rollout Gates and Proof-Store Contract

## Problem

Supervised autonomous writes need measurable proof before and after risky updates. Historical suggestions invent external audit SaaS or “just disable verification.” TU-VM already records proof-store rows and ships `scripts/rollout-gates.sh`. The community website needs an **ops gate contract**—distinct from Stage 11 operator write-guard *policy* and Stage 7 gateway *code* contribution.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/rollout-gates.sh` | Windowed claimed-verify / mismatch rate gate |
| MCP Gateway proof store volume | Local evidence (`proof-store.json`) |
| README rollout-gates notes | Default thresholds and volume path caveats |
| `scripts/langgraph-e2e-smoke.sh` | Deny-path smoke for unconfirmed writes |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Env postures and day-to-day guard tone |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Code changes to gateway/supervisor |
| Stage 8 `release-canary-community-program.md` (expected sibling) | Human canary checklist |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (expected sibling) | Named scenario wrappers |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVE gates (complementary) |

Out of scope:

- Shipping proof-store contents to public GitHub Issues
- Replacing local proof with a mandatory cloud audit vendor
- Documenting how to delete proof rows to pass the gate
- Conflating this gate with Compose healthchecks (Stage 13) or Trivy (Stage 4)

## Proposal

Publish a **rollout gates / proof-store contract** for maintainers, canaries, and docs authors.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Gate script | `scripts/rollout-gates.sh` | Threshold flags; clear failure messages |
| Proof path docs | README / playbooks | Compose project name / volume prefix notes |
| Operator policy | Stage 11 write-guard page | When to run the gate |
| Canary / release | Stage 8 canary + this gate | Pre/post update evidence |
| Schema evolution | Gateway proof writers | Additive fields; redaction rules |

### Rules

1. **Gate measures claimed vs verified**—it does not replace human canaries or smoke tests.
2. **Keep proof local.** Share only aggregate rates in Issues; never paste raw proof rows with payloads.
3. **Path honesty.** Document that default volume paths assume the Compose project prefix; pass an explicit path when names differ.
4. **Fail closed on mismatch.** Docs must not recommend lowering thresholds to silence real supervision bugs.
5. **Pair with deny-path smoke.** After guard/gateway changes, `langgraph-e2e-smoke` (or equivalent) still proves unconfirmed writes fail.
6. **Complementary supply-chain.** Image CVE gates (Stage 4) answer “should we pull?”; proof gates answer “are supervised writes still trustworthy?”
7. **GitHub remains intake.** Threshold policy changes for defaults go through Issues + Decision Log.

### Suggested day-to-day flow

```text
#playbook-rollout-gates
1. Ensure MCP gateway + supervisor paths are in use if you rely on supervised writes
2. ./scripts/rollout-gates.sh [proof-store-path]
3. On failure: diagnose gateway/supervisor verification—do not delete proof to pass
4. After stack update: re-run gate + ./scripts/langgraph-e2e-smoke.sh
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Evidence store | Existing gateway proof volume | External audit SaaS prerequisite |
| Gate math | `rollout-gates.sh` | Spreadsheet-only release signoff |
| Operator posture | Stage 11 write-guard policy | Disabling supervision to green CI |
| Human validation | Stage 8 canary program | Proof gate as the only signal |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-rollout-gates` when implementing docs polish.
3. Cross-link Stage 11 write-guard, Stage 7 AI pipeline, Stage 8 canary.
4. Prefer **code** clearer path/threshold UX in `rollout-gates.sh` over new platforms.

## Acceptance criteria

- [ ] Distinction from write-guard policy and AI pipeline code contracts is explicit.
- [ ] Local-only / no-raw-paste rule is stated.
- [ ] Volume path prefix caveat is documented.
- [ ] Fail-closed guidance forbids deleting proof to pass.
- [ ] Playbook orders gate + deny-path smoke around updates.

## Rollback

Revert script/docs changes; operators may stop running the gate. Proof volume data remains local host state. Docs-only publication needs no runtime rollback.

## Success metrics

- More update/canary writeups cite gate output aggregates.
- Fewer “turn off verification” workarounds in community docs.
- Mismatch spikes caught before broad weekly updates.
