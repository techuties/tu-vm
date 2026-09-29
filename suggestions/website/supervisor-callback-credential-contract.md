---
title: Supervisor Callback Credential Contract
description: Constructional contract so only the LangGraph supervisor token can skip a second gateway delegation, using the secret the stack already has.
last_updated: 2026-09-29
owner: maintainers
status: proposed
theme: security
impact: high
---

# Supervisor Callback Credential Contract

## Problem

Write tools whose names start with `n8n_` are delegated to `langgraph-supervisor`. The supervisor calls `POST /invoke` on the gateway again so the tool actually runs. To stop that second call from delegating forever, the supervisor sends header `X-LangGraph-Supervised: 1` with `Authorization: Bearer <MCP_GATEWAY_TOKEN>`.

The gateway decides with the header alone:

```text
is_supervised_call = header in {1, true, yes, on}
if not is_supervised_call:
    enforce write approval
if supervisor enabled and tool is delegated and not is_supervised_call:
    delegate to the supervisor
else:
    run the tool
```

Any caller who already has `MCP_GATEWAY_TOKEN` can send the same header. The gateway then skips delegation and skips `_enforce_write_approval`. `confirm=true` inside the tool handler still runs. The supervisor’s audit, dedupe, and strict-verify pass do not.

`LANGGRAPH_SUPERVISOR_TOKEN` already exists. The gateway uses it when it calls the supervisor. The supervisor accepts it (or falls back to `MCP_GATEWAY_TOKEN` when it is empty). The callback into the gateway does not use it. The loop break is a header, not that secret.

Checked on 2026-09-29 in `mcp-gateway/app.py` (`invoke`, around the `is_supervised_call` branch) and `langgraph-supervisor/app.py` (`_gateway_invoke`).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `MCP_GATEWAY_TOKEN` | Caller credential for Open WebUI and other clients |
| `LANGGRAPH_SUPERVISOR_TOKEN` | Already the supervisor’s own secret when set |
| `X-LangGraph-Supervised` | Loop-break signal. It must not be sufficient by itself |
| `confirm=true` in n8n tool handlers | Stays. This page does not remove it |
| `scripts/langgraph-e2e-smoke.sh` | Already expects a write without `confirm=true` to be denied |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling, open PR #37) | Operator postures. Do not rewrite that policy page |
| Stage 15 gateway ops and supervisor smoke (expected siblings, open PR #41) | How to change and smoke the pipeline |
| Stage 18 helper control-auth (expected sibling, open PR #44) | Helper `CONTROL_TOKEN`. Different credential |

Out of scope:

- A new approval inbox or human-in-the-loop product
- Removing `confirm=true`
- Disabling the supervisor to make the header irrelevant
- Logging either token

## Proposal

Treat the supervisor callback as a second bearer, using the env var the stack already has.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Gateway | `invoke` in `mcp-gateway/app.py` | `is_supervised_call` is true only when the bearer matches `LANGGRAPH_SUPERVISOR_TOKEN` and that value is non-empty and different from `MCP_GATEWAY_TOKEN` |
| Supervisor | `_gateway_invoke` | Send `Authorization: Bearer <LANGGRAPH_SUPERVISOR_TOKEN>` on the callback. Keep the header only as a label, not as the check |
| Compose / env | existing `LANGGRAPH_SUPERVISOR_TOKEN` | `generate-secrets` must set it to a distinct value. Empty must not mean “share the gateway token for the callback” |
| Smoke | `scripts/langgraph-e2e-smoke.sh` | Keep the confirm-deny check. Add a note that a gateway-token call with the header still delegates |

### Rules

1. **The header does not authenticate.** A client bearer equal to `MCP_GATEWAY_TOKEN` always takes the delegate path for delegated write tools.
2. **The callback bearer is `LANGGRAPH_SUPERVISOR_TOKEN`.** Compare it with `hmac.compare_digest`, the same way the gateway already compares `MCP_GATEWAY_TOKEN`.
3. **The two tokens must differ.** If they are equal or the supervisor token is empty, do not take the supervised shortcut. Fail closed into delegation (or HTTP 500 on the supervisor if it has no distinct token), rather than running the tool inline.
4. **Keep `confirm=true`.** The callback still goes through the tool handler. Do not add a bypass for confirm.
5. **Write approval still applies to client calls.** Skipping `_enforce_write_approval` is allowed only on the callback that presented the supervisor token.
6. **Do not print tokens.** Errors may name the missing env var. They must not echo the value.
7. **Health stays unauthenticated.** Do not add the supervisor URL or either token to new `/health` fields. The URL already present is Stage 15’s “do not leak tool config” rule; do not add more.

### Suggested contributor checklist

```text
1. Set LANGGRAPH_SUPERVISOR_TOKEN to a different value from MCP_GATEWAY_TOKEN
2. Gateway: supervised shortcut only for that distinct bearer
3. Supervisor: callback uses LANGGRAPH_SUPERVISOR_TOKEN
4. hmac.compare_digest for both comparisons
5. Client call with MCP_GATEWAY_TOKEN and X-LangGraph-Supervised still delegates
6. langgraph-e2e-smoke still denies a write that omits confirm=true
7. Do not log token values
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Loop break | Existing `LANGGRAPH_SUPERVISOR_TOKEN` | A new auth service |
| Client auth | Existing `MCP_GATEWAY_TOKEN` | Sharing one token for both directions |
| Compare | `hmac.compare_digest` already used in `_check_auth` | `==` on the callback secret |
| Deny proof | `scripts/langgraph-e2e-smoke.sh` | Turning the supervisor off |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Ship the gateway check and the supervisor callback header change together, with a distinct token in `env.example` comments (no real secret).
3. Recreate `ai_mcp_gateway` and `ai_langgraph_supervisor`. Run the existing e2e smoke.

## Acceptance criteria

- [ ] A request authed with `MCP_GATEWAY_TOKEN` and `X-LangGraph-Supervised: 1` still delegates n8n write tools.
- [ ] The supervisor callback presents `LANGGRAPH_SUPERVISOR_TOKEN`, and that path does not delegate again.
- [ ] Equal or empty supervisor token does not enable the shortcut.
- [ ] Token comparison uses `hmac.compare_digest`.
- [ ] A write without `confirm=true` is still denied.
- [ ] Neither token appears in logs, `/health`, or the PR diff.

## Rollback

Redeploy the previous gateway and supervisor images or git revert, and restart both containers. If the new supervisor cannot authenticate, writes fail closed instead of running inline. Docs-only publication needs no runtime rollback.

## Success metrics

- Skipping the supervisor requires the supervisor’s own secret.
- The existing confirm-deny smoke still passes.
- Operators rotate one existing env var, not a new credential store.
