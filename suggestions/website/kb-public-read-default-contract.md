---
title: Knowledge Base Public Read Contract
description: Constructional contract to default KB_PUBLIC_READ_ENABLED to false so anonymous callers cannot read the public knowledge bucket through the Open WebUI vhost.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: security
impact: high
---

# Knowledge Base Public Read Contract

## Problem

`KB_PUBLIC_READ_ENABLED` defaults to true in three places that ship together:

- `docker-compose.yml` on `mcp_gateway` (`${KB_PUBLIC_READ_ENABLED:-true}`)
- `env.example`
- `mcp-gateway/app.py` `_env_bool("KB_PUBLIC_READ_ENABLED", True)`

When the flag is true and the request has no bearer token, `invoke` skips `_check_auth` for read tools. Those tools are `kb_list_objects`, `kb_get_object`, `kb_extract_text`, and `kb_search`.

`_assert_bucket_allowed` then allows only `KB_PUBLIC_BUCKET` (default `kb-public`). `KB_PRIVATE_BUCKET` stays denied for that anonymous call. Writes are not in the read-tool set, so `kb_put_object` and `kb_index_document` still require a token.

`kb_get_object` returns UTF-8 text, or base64 when `asText` is false. `kb_extract_text` sends the object through Tika. `kb_search` reads index JSON under the bucket's index prefix.

Nginx publishes this API on the Open WebUI vhost. `nginx/conf.d/default.conf` `server_name oweb.tu.lan` has `location /api/mcp/` proxying to `http://172.20.0.26:9002/` and does not add a bearer token. A client that can open `https://oweb.tu.lan/api/mcp/` can call those read tools without an Open WebUI login whenever the flag is true.

That default fights the private-LAN posture. A community catalog that should be anonymous is an explicit opt-in, using the flag that already exists.

Write-approval tokens and the LangGraph supervisor stay on the autonomous-write policy page. This page only changes the anonymous-read default.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `KB_PUBLIC_READ_ENABLED` | Already the on/off switch |
| `MCP_GATEWAY_TOKEN` | Bearer check `_check_auth` already uses |
| Public vs private bucket | `_assert_bucket_allowed` already splits them |
| `location /api/mcp/` | LAN entry that does not inject a token |
| Write tools | Still authenticated when the flag is true |
| Autonomous-write policy (expected sibling) | `MCP_WRITE_APPROVAL_REQUIRED`, separate decision |
| Stage 8 knowledge catalog (expected sibling) | What belongs in a knowledge pack |

Out of scope:

- A new auth service, login wall, or session database in front of the gateway
- Removing the public bucket
- Changing write approval or supervisor delegation
- Putting MinIO's console on the public internet

## Proposal

Default the flag off in Compose and in `env.example`:

```text
KB_PUBLIC_READ_ENABLED=false
```

Change the code default in `_env_bool("KB_PUBLIC_READ_ENABLED", True)` to `False` so a missing variable matches Compose.

Anonymous community publishing, when someone wants it, sets the same variable back to `true` in `.env` and documents that `kb-public` is readable by anyone who can reach `oweb.tu.lan`. Private objects stay in `kb-private` either way.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `mcp_gateway` environment | Default `false` |
| Env schema | `env.example` | `KB_PUBLIC_READ_ENABLED=false` plus a one-line opt-in comment |
| Gateway | `_env_bool` default | `False` |
| Docs | MCP playbook | How to opt in for an anonymous catalog |
| Edge | Nginx `/api/mcp/` | Leave the proxy; it already relies on the gateway token |

### Rules

1. **Reuse the flag and the bearer token.** Do not add an auth gateway.
2. **Shipped default is false.** `true` is the opt-in for a public catalog.
3. **Private bucket behavior stays.** Anonymous calls never gain `kb-private`.
4. **Writes stay authenticated.** This change does not loosen `kb_put_object`.
5. **Opt-in is an operator `.env` change**, recorded in an Issue so the community can see that the catalog is public.

### Suggested contributor checklist

```text
1. Set the Compose default and env.example to false
2. Set the Python default to False
3. Restart mcp_gateway
4. Call kb_list_objects on /api/mcp/invoke without a bearer token and confirm 401
5. Call the same tool with MCP_GATEWAY_TOKEN and confirm the public bucket lists
6. Confirm a tokenless call still cannot read kb-private when the flag is later set true
7. Leave write-approval settings unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Authenticated reads | Existing `MCP_GATEWAY_TOKEN` | A second login service |
| Anonymous catalog | Existing boolean opt-in | A public MinIO policy change |
| Private objects | Existing private bucket check | A new ACL language |
| Write control | Existing write-approval policy | Folding approval into this flag |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Compose default, `env.example`, the Python default, and a restart of `mcp_gateway`.
3. Operators who already rely on anonymous reads set `KB_PUBLIC_READ_ENABLED=true` in `.env` before recreating the gateway.

## Acceptance criteria

- [ ] Compose, `env.example`, and the Python default are false.
- [ ] A tokenless knowledge read through `/api/mcp/` is rejected.
- [ ] A bearer token still lists `kb-public`.
- [ ] Write tools still require a token.
- [ ] No new auth service is added.

## Rollback

Set `KB_PUBLIC_READ_ENABLED=true` to restore anonymous reads of `kb-public` only.

## Success metrics

- LAN clients without the gateway token cannot read knowledge objects.
- An operator can still open a public catalog with one documented variable.
