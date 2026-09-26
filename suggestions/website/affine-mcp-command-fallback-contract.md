---
title: AFFiNE MCP Command Fallback Contract
description: Constructional contract to make the mcp-gateway AFFiNE command default the preinstalled bin affine-mcp, matching Compose and the npm package, instead of npx plus a package name.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# AFFiNE MCP Command Fallback Contract

## Problem

`mcp-gateway/app.py` connects to AFFiNE with:

```text
command = os.getenv("MCP_AFFINE_COMMAND", "npx")
raw_args = os.getenv("MCP_AFFINE_ARGS", "affine-mcp-server")
```

That fallback runs only when the variables are **unset**. Compose sets them:

```text
MCP_AFFINE_COMMAND: ${MCP_AFFINE_COMMAND:-affine-mcp}
MCP_AFFINE_ARGS: ${MCP_AFFINE_ARGS:-}
```

`env.example` matches Compose (`MCP_AFFINE_COMMAND=affine-mcp`, empty args). The live Compose path is already `affine-mcp` with no extra arguments.

The npm package `affine-mcp-server` **3.8.2** (registry on 2026-09-26) publishes bin **`affine-mcp`**, not a bin named `affine-mcp-server`. `mcp-gateway/Dockerfile` installs that package globally so the process does not fetch at runtime. The Python fallback (`npx` + `affine-mcp-server`) disagrees with the bin, with Compose, and with the Dockerfile comment. It matters for tests, for a hand-run gateway, and for an operator who unsets `MCP_AFFINE_COMMAND`.

The build-pin page owns pinning `affine-mcp-server@3.8.2`. This page only aligns the **command default**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-gateway/app.py` `_connect` | `npx` / `affine-mcp-server` fallback |
| Compose `mcp_gateway` environment | Default command `affine-mcp`, empty args |
| `env.example` | Same command name |
| `mcp-gateway/Dockerfile` | Global install, currently unpinned |
| npm `affine-mcp-server@3.8.2` | bin `affine-mcp` |
| Build-pin page (this stage) | Pin the install |
| Stage 15 MCP gateway ops (expected sibling) | Broader gateway contribution rules |

Out of scope:

- A second AFFiNE MCP image or HTTP proxy (`affine-mcp-http-proxy` exists upstream and is not required)
- Changing `AFFINE_API_TOKEN` / cookie / email auth, which `_connect` already requires
- Rewriting Stage 9 AFFiNE collaboration or Stage 19 AFFiNE backup pages
- Runtime `npx -y` as the supported path

## Proposal

1. Change the code defaults to `command="affine-mcp"` and `args=""` (empty string). `shlex.split("")` yields no arguments, which matches Compose.
2. Keep reading `MCP_AFFINE_COMMAND` and `MCP_AFFINE_ARGS` so operators can override.
3. Do not set the default command to `npx`. The image already installs the bin. The build-pin page makes that install reproducible.
4. Leave Compose and `env.example` on `affine-mcp` unless a future package renames the bin. A rename is an Issue that updates Compose, the example, and this default together.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Fallback | `AffineMcpConnection._connect` | Defaults `affine-mcp` and empty args |
| Image | Dockerfile pin (build-pin page) | `@3.8.2` so the bin exists |
| Env | Compose / `env.example` | No change if they already say `affine-mcp` |

### Rules

1. **The bin name wins.** `affine-mcp` is what the package installs.
2. **Empty args stay empty.** Do not pass the package name as an argument to the bin.
3. **No runtime fetch.** `npx` is not the fallback.
4. **Auth stays as it is.** Missing AFFiNE token, cookie, and email/password still raises `No AFFiNE auth configured.`
5. **GitHub remains intake.** A different command belongs in env, not a hard-coded path to a developer laptop.

### Suggested contributor checklist

```text
1. Read MCP_AFFINE_COMMAND defaults in app.py, Compose, and env.example
2. Set the Python fallback to affine-mcp and empty args
3. Confirm the Dockerfile install provides that bin (build-pin page)
4. Do not add npx or a second AFFiNE server
5. Leave AFFiNE credential checks unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| AFFiNE tools | Preinstalled `affine-mcp` bin | `npx affine-mcp-server` on each connect |
| Version | `affine-mcp-server@3.8.2` from the build-pin page | Floating `npm install -g` |
| Credentials | Existing token / cookie / email checks | A new AFFiNE login service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: the two default strings in `_connect`, in the same PR as the Dockerfile pin when possible.
3. Compose users see no change. The fallback changes only when the env vars are unset.

## Acceptance criteria

- [ ] Unset `MCP_AFFINE_COMMAND` uses `affine-mcp`, not `npx`.
- [ ] Unset `MCP_AFFINE_ARGS` passes no arguments.
- [ ] Compose defaults remain `affine-mcp` and empty args.
- [ ] Missing AFFiNE credentials still fail closed.
- [ ] No second AFFiNE MCP service is added.
- [ ] The build-pin page remains the place that names `@3.8.2`.

## Rollback

Restore the `npx` / `affine-mcp-server` defaults. Compose behavior stays on `affine-mcp`.

## Success metrics

- A gateway started without those env vars uses the bin the image installed.
- Connect attempts do not download npm packages.
- Operators keep one command name across Compose, `env.example`, and code.
