---
title: Fixture and Contract-Test Contribution
description: Constructional contract for community contributions to fixtures and schema validators that keep helper and dashboard contracts stable without inventing a second test framework.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Fixture and Contract-Test Contribution

## Problem

Dashboard and helper integrations break when JSON shapes drift. Historical suggestions invent heavyweight end-to-end grids or skip fixtures entirely. The repository already has `fixtures/` and validators such as `scripts/validate_status_full_contract.py`. Contributors need a **reuse-first contract** for evolving those fixtures day to day.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `fixtures/status-full-contract.json` | Canonical `/status/full` shape |
| `scripts/validate_status_full_contract.py` | CI/local schema check |
| `scripts/helper-contract-check.sh` | Live helper JSON + control **401** |
| `scripts/smoke-test.sh` | Offline/live smoke |
| CI workflow | Runs fixture validation on PRs |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | Optional live helper profile |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Rules for evolving helper APIs |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Playwright direction for UI |
| Stage 6 `website-frontmatter-ci-contract.md` (expected sibling) | Docs frontmatter CI (adjacent pattern) |

Out of scope:

- Replacing fixture validators with a mandatory proprietary test cloud
- Capturing production `/status/full` payloads that include secrets into git
- Skipping contract updates when helper fields change “because the UI still looks fine”
- Duplicating Playwright coverage goals already tracked in Stage 4

## Proposal

Publish a **fixture and contract-test contribution contract** for schema-sensitive changes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Status fixture | `fixtures/status-full-contract.json` | Additive fields documented; validator green |
| Validator code | `scripts/validate_status_full_contract.py` | `python3` compile + CI |
| Helper live checks | `helper-contract-check.sh` | 401 + JSON assertions |
| New fixtures | `fixtures/` | Naming, redaction, README/pointer in docs |
| Docs | CONTRIBUTING / playbooks | When to update fixtures |

### Rules

1. **Fixture-additive by default.** New optional fields extend the contract; removals/renames need deprecation notes (Stage 6) and dashboard follow-up.
2. **Redact everything.** Fixtures must not contain real tokens, allowlisted client IPs, hostnames that identify customers, or document contents.
3. **Same validator in CI and locally.** Do not invent a second incompatible checker for `/status/full`.
4. **Helper changes update fixtures in the same PR** (or a strict stacked PR pair) when shape changes.
5. **Prefer pure functions.** Validators should run without Docker when checking static fixtures.
6. **UI is not the schema.** Playwright (Stage 4) complements fixtures; it does not replace them.
7. **GitHub remains intake.** Proposals for new contract surfaces start as Issues with sample (redacted) payloads.

### Suggested contributor checklist

```text
1. Describe the shape change in the PR (additive vs breaking)
2. Update fixtures/status-full-contract.json (redacted)
3. python3 scripts/validate_status_full_contract.py
4. ./scripts/helper-contract-check.sh   # if helper runtime available
5. ./scripts/smoke-test.sh
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Schema guard | Existing Python validator + fixture | Ad-hoc `jq` snippets as the only CI gate |
| Live proof | helper-contract-check | Production dumps with secrets |
| UI proof | Stage 4 Playwright direction | Screenshot-only contract claims |
| Breaking changes | Stage 6 deprecation notices | Silent field renames |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link from CONTRIBUTING “Local checks” when implementing docs polish.
3. Cross-link Stage 7 helper-api and Stage 5 compose-ci-live-profile pages.
4. Prefer **code** validator improvements (clearer error messages) next.

## Acceptance criteria

- [ ] Fixture-additive default is explicit.
- [ ] Redaction rule is explicit.
- [ ] Same-PR (or stacked) fixture update expectation is stated.
- [ ] Checklist names the canonical validator command.
- [ ] No second proprietary test cloud is required.

## Rollback

Revert fixture/validator commits independently; CI continues on the previous contract file. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer helper PRs merge without fixture updates.
- Clearer CI failures pointing at field-level diffs.
- Decline in “add Testcontainers everywhere” suggestions for simple shape guards.
