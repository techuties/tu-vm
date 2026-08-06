---
title: Open WebUI Web-Search Contract
description: Constructional contract for community contributions to Open WebUI web-search loaders that reuses check-openwebui-websearch and privacy-first defaults instead of inventing a search SaaS.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Open WebUI Web-Search Contract

## Problem

Optional web search inside Open WebUI is powerful and easy to misconfigure: wrong loaders, leaked API keys, or silent failures that look like “AI is broken.” Historical suggestions invent always-on crawler fleets or send query logs to third parties by default. Contributors need a **reuse-first web-search contract** centered on the existing checker and privacy posture.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh check-openwebui-websearch` | Validate Open WebUI web-search loader config |
| Open WebUI Compose service + env | Search feature wiring |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Broader Open WebUI contribution rules |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | Safe `env.example` evolution for search keys |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotating optional search API keys |
| Stage 9 `privacy-preserving-usage-analytics.md` (expected sibling) | Local-only analytics—not query exfiltration |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Guardrails when agents trigger tools |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | MCP/tool wiring adjacent to search tools |

Out of scope:

- Making outbound web search mandatory for all installs
- Shipping operator search queries, results, or API keys to public Issues
- Building a TU-VM-hosted public search engine / crawler farm
- Bypassing LAN-first defaults to expose search admin APIs on the WAN

## Proposal

Publish an **Open WebUI web-search contract** that separates enablement, validation, and privacy.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Checker | `check-openwebui-websearch` | Clear pass/fail; redacts secrets |
| Env / secrets | `env.example` + `.env` (local) | Placeholders only in git; rotation notes |
| Loader selection | Open WebUI search settings / docs | Documented defaults and failure modes |
| Playbooks | `#playbook-open-webui-websearch` (proposed) | Enable → check → private smoke |
| Tool / agent use | MCP or Workflow Operator paths | Stage 7 / Stage 11 guardrails |

### Rules

1. **Search is optional.** Default installs must remain useful offline/LAN-only without web search.
2. **Validate with the checker.** PRs that touch search wiring include `check-openwebui-websearch` evidence when the stack can run it.
3. **Keys never land in git.** Search API tokens stay in `.env`; samples use `CHANGE_ME` / empty placeholders.
4. **No query dumps in Issues.** Reproduce with synthetic queries; redact URLs that reveal private context.
5. **Document egress.** Any loader that calls the public internet must say so in operator docs (and respect firewall modes).
6. **Prefer least privilege.** Community defaults should avoid broad scrapers that hammer sites or store unbounded result caches on disk.
7. **GitHub remains intake.** New loader proposals are Issues/PRs linked to this contract—not ad-hoc dashboard forks.

### Suggested playbook shape

```text
#playbook-open-webui-websearch
1. Confirm operator wants outbound search (secure/public mode implications)
2. Set required keys in .env (never commit them)
3. Restart / reload Open WebUI per README if needed
4. ./tu-vm.sh check-openwebui-websearch
5. Private UI smoke with a non-sensitive synthetic query
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Product surface | Open WebUI web-search settings | Custom search portal in Nginx |
| Validation | Existing checker | Guessing from UI screenshots alone |
| Secrets | `.env` + Stage 8 rotation | Keys in Compose labels or seed SQL |
| Privacy | Synthetic queries + redaction | Pasting real user search history |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-open-webui-websearch` when docs polish lands.
3. Cross-link Stage 10 Open WebUI, Stage 12 env-schema, and Stage 8 secret rotation pages.
4. Prefer **code** checker clarity (actionable errors) over new suggestion files.

## Acceptance criteria

- [ ] Optional-by-default rule is explicit.
- [ ] Checker is the primary validation path.
- [ ] Secret and query redaction rules are explicit.
- [ ] Egress / firewall implications are called out.
- [ ] No mandatory public crawler farm is proposed.

## Rollback

Disable web search in Open WebUI settings and remove optional keys from `.env`; LAN chat continues without outbound search. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer “search broken” Issues without checker output.
- Fewer accidental key commits in PRs touching search.
- Decline in proposals to replace Open WebUI search with an unmanaged crawler.
