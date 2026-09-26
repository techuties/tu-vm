---
title: MCP Tool Build Pin Contract
description: Constructional contract to pin npm and pip versions in the existing MCP Dockerfiles to the registry versions recorded on 2026-09-26, instead of @latest and unpinned installs.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# MCP Tool Build Pin Contract

## Problem

Local MCP images install floating tags at build time. A later `docker compose build` can change behavior with no Compose digest bump.

| File | Install today |
|---|---|
| `mcp-tools/filesystem/Dockerfile` | `@modelcontextprotocol/server-filesystem@latest`, `supergateway@latest` |
| `mcp-tools/memory/Dockerfile` | `@modelcontextprotocol/server-memory@latest`, `supergateway@latest` |
| `mcp-tools/fetch/Dockerfile` | unpinned `pip install mcp-server-fetch`, `supergateway@latest` |
| `mcp-tools/playwright/Dockerfile` | `@playwright/mcp@latest` |
| `mcp-gateway/Dockerfile` | unpinned `npm install -g affine-mcp-server` |

Registry versions observed on **2026-09-26** (these are the pin targets, not a claim about images already built on an operator machine):

| Package | Version | Bin / note |
|---|---|---|
| `supergateway` | `4.0.0` | bin `supergateway` |
| `@modelcontextprotocol/server-filesystem` | `2026.8.31` | bin `mcp-server-filesystem` |
| `@modelcontextprotocol/server-memory` | `2026.8.31` | bin `mcp-server-memory` |
| `@playwright/mcp` | `0.0.82` | bin `playwright-mcp` |
| `mcp-server-fetch` (PyPI) | `2026.8.18` | module `mcp_server_fetch` |
| `affine-mcp-server` | `3.8.2` | bin `affine-mcp` (see the command-fallback page) |

Stage 26 `n8n-mcp-digest-pin-contract.md` owns the third-party image `ghcr.io/czlonkowski/n8n-mcp:latest`. Stage 22 provenance owns cosign for published images. Stage 18 owns sandbox shape (`--allowed-hosts *`, volumes, egress). This page only pins **Dockerfile build inputs**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-tools/*/Dockerfile` | Floating npm/pip installs |
| `mcp-gateway/Dockerfile` | Comment says preinstall so runtime does not fetch; the install is still unpinned |
| npm / PyPI | Version source for the table above |
| Stage 18 MCP sandbox (expected sibling) | How a tool image is shaped |
| Stage 26 n8n-mcp digest (expected sibling) | A different image's `:latest` tag |
| Stage 4 supply-chain gates (expected sibling) | CI scanning, not these Dockerfiles |

Out of scope:

- Runtime `npx -y` as the way to "pin" a package
- Replacing supergateway or the official MCP servers
- Digest-pinning `node:22-alpine` in the same PR (a separate Issue may do that)
- Claiming an already-built local image contains these versions

## Proposal

Replace each `@latest` and unpinned install with the version in the table. Examples:

```text
npm install -g supergateway@4.0.0 @modelcontextprotocol/server-filesystem@2026.8.31
pip install --break-system-packages mcp-server-fetch==2026.8.18
npm install -g affine-mcp-server@3.8.2
```

Keep the current `CMD` shape (`supergateway --stdio ...`, `npx @playwright/mcp` becomes the pinned package's bin if the Dockerfile already invokes it via `npx`). Prefer the installed bin over `npx` so a rebuild does not resolve a new tag. Playwright today runs `npx @playwright/mcp` with no version. After the pin, call `playwright-mcp` (the package bin) or `npx @playwright/mcp@0.0.82` so the version is visible in the `CMD`.

A later bump is a normal dependency PR that updates this page's table or, once the code is merged, the Dockerfile only. Do not leave `@latest` "for convenience."

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Filesystem, memory, fetch, playwright | `mcp-tools/*/Dockerfile` | Exact versions from the table |
| Gateway | `mcp-gateway/Dockerfile` | `affine-mcp-server@3.8.2` |
| Docs | This page | Date the registry observation |

### Rules

1. **Pin what the Dockerfile installs.** Do not add a private package mirror as a prerequisite.
2. **No runtime fetch.** The gateway Dockerfile comment is the policy. The AFFiNE command page aligns the process default.
3. **Versions are dated.** 2026-09-26 registry data. If npm moves, the PR that pins must say which version it resolved that day.
4. **Do not rewrite Stage 26.** `n8n-mcp:latest` is a different artifact.
5. **GitHub remains intake.** Security bumps arrive as Issues or Dependabot-style PRs, not as `@latest`.

### Suggested contributor checklist

```text
1. Replace @latest and unpinned pip/npm lines with the 2026-09-26 versions
2. Point CMD at the installed bin or an explicit @version
3. Leave volumes, ports, and --allowed-hosts to Stage 18
4. Do not add npx -y at container start
5. Note the pin date in the PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| MCP stdio bridge | Pinned `supergateway@4.0.0` | Unpinned `npx supergateway` |
| Filesystem / memory / playwright / fetch | The official packages, version-pinned | A from-scratch MCP server |
| AFFiNE MCP | Pinned global install already in the gateway image | `npx` on every connect |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Dockerfile pins, then a local `docker compose build` of one tool image to confirm the bin exists.
3. Existing containers keep their old layers until rebuilt.

## Acceptance criteria

- [ ] No `mcp-tools` or `mcp-gateway` Dockerfile contains `@latest` or an unpinned `affine-mcp-server` / `mcp-server-fetch` install.
- [ ] Pinned versions match the table, or the PR updates the table in the same commit with a new observation date.
- [ ] Container start does not use `npx -y` to fetch those packages.
- [ ] Stage 18 sandbox behavior and Stage 26 n8n-mcp digest are not rewritten.

## Rollback

Restore the previous Dockerfiles and rebuild. Running containers are unchanged until then.

## Success metrics

- Two builds on different days without a Dockerfile change produce the same package versions.
- Dependabot or a manual PR is the only way those versions move.
- The gateway image still contains `affine-mcp` from the pinned package.
