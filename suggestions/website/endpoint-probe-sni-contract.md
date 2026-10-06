---
title: Endpoint Probe SNI Contract
description: Constructional contract so tu-vm.sh and the live smoke script select a named Nginx vhost by SNI instead of only sending a Host header to an IP.
last_updated: 2026-10-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Endpoint Probe SNI Contract

## Problem

Two day-to-day checks report Open WebUI, n8n, AFFiNE, and Pi-hole as down while those vhosts can be healthy. Both checks curl an IP address and set `Host` without setting TLS SNI.

`tu-vm.sh` `test_endpoints` does this after `vm_ip=$(get_vm_ip)`:

```bash
status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: oweb.tu.lan" "https://$vm_ip/")"
```

The same shape is used for `n8n.tu.lan`, `affine.tu.lan`, and `pihole.tu.lan` (`/admin/`). `run_beginner_post_checks` calls `test_endpoints` during setup, and the `test_endpoints` command calls it directly. A failed check returns non-zero.

`scripts/smoke-test.sh --live` does the same against loopback:

```bash
curl -fsSk -o /dev/null -w "oweb /health/db -> %{http_code}\n" -H "Host: oweb.tu.lan" "https://127.0.0.1/health/db"
```

The landing probe in that script sends `Host: tu.lan` to `https://127.0.0.1/health`. That one matches the default server. The Open WebUI probe does not.

Curl uses the host in the URL as SNI. For `https://192.0.2.10/` or `https://127.0.0.1/`, SNI is that IP. Nginx picks the certificate and the server block from SNI before it reads `Host`. No `server_name` is an IP address. The handshake lands on the default server:

```nginx
server {
    listen 443 ssl default_server;
    server_name tu.lan;
    if ($host !~* "^(tu\\.lan|[0-9]{1,3}(\\.[0-9]{1,3}){3})$") {
        return 444;
    }
}
```

`$host` is the `Host` header. `oweb.tu.lan` fails the pattern, and `return 444` closes the connection. Curl's status is then typically `000`, and both scripts record a failure. The named server blocks (`oweb.tu.lan`, `n8n.tu.lan`, `affine.tu.lan`, `pihole.tu.lan`) never see the request.

`scripts/langgraph-e2e-smoke.sh` already solves this. When `getent hosts` misses the name, it adds:

```bash
curl_resolve=(--resolve "${base_host}:${base_port}:${resolve_ip}")
```

`--resolve` makes the URL host the vhost name, so SNI and `Host` are that name, while the TCP connection still goes to the chosen IP.

Stage 45 (open PR #71) owns a different bug on the vhost that this probe never reaches: `location /health` is a prefix, so `/health/db` and `/healthz` are static `healthy` answers once a request does arrive at `oweb.tu.lan` or `n8n.tu.lan`. Fixing SNI without that exact-match change still hides `/health/db`. Fixing only the prefix leaves these curls on the default server. Both contracts have to land before `smoke-test.sh --live` can see Open WebUI's real health route.

The Pi-hole URL path `/admin/` is unchanged here. The comment in `test_endpoints` says the vhost root is expected to answer 403. Whether that path still exists on the pinned image is a separate Pi-hole contract.

Checked on 2026-10-06 by reading `test_endpoints`, `run_beginner_post_checks`, `scripts/smoke-test.sh`, `scripts/langgraph-e2e-smoke.sh`, and the `default_server` block in `nginx/conf.d/default.conf`. Nginx was not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `test_endpoints` | Beginner and on-demand vhost check |
| `scripts/smoke-test.sh` Phase C | CI-able live probe when `--live` is passed |
| `scripts/langgraph-e2e-smoke.sh` | Working `--resolve` pattern |
| Default `server` on 443 | Intentional 444 for a `Host` that is not `tu.lan` or an IPv4 literal |
| Named `server_name` blocks | The sites the probes mean to reach |
| Stage 45 `nginx-static-health-prefix-contract.md` (expected sibling, open PR #71) | `location = /health` so app paths are proxied |
| Stage 16 smoke contribution (expected sibling) | How contributors extend smoke checks. It does not set SNI |

Out of scope:

- Relaxing the default server so any `Host` is accepted
- Adding public DNS for `*.tu.lan`
- A new probe daemon or browser runner
- Editing `location /health` (Stage 45)
- Requiring n8n or AFFiNE to be up during Tier 1 setup

## Proposal

Point each named check at a URL whose host is the vhost, and pin the address with `--resolve`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Helper in `tu-vm.sh` | Next to `test_endpoints` | One function that runs `curl -k -s -o /dev/null -w '%{http_code}' --resolve "<name>:443:<ip>" "https://<name><path>"`. No separate `Host` header is required once the URL host is the vhost |
| Beginner check | `test_endpoints` | Use that helper for `tu.lan` `/`, `oweb.tu.lan` `/`, and Pi-hole. For n8n and AFFiNE, treat HTTP 502/503 as "vhost reached, Tier 2 stopped" and do not fail beginner setup on those two codes. Fail on `000` and `444` |
| Smoke | `scripts/smoke-test.sh` Phase C | `--resolve oweb.tu.lan:443:127.0.0.1` and request `https://oweb.tu.lan/health/db`. Keep the landing probe on `tu.lan`, also via `--resolve`, so it does not depend on SNI falling through to `default_server` |
| Names | Both scripts | Keep the names already in the curls (`tu.lan`, `oweb.tu.lan`, `n8n.tu.lan`, `affine.tu.lan`, `pihole.tu.lan`). A `DOMAIN` override can wait for the existing server-name contract; do not invent a second map here |
| Pi-hole path | Unchanged | Still request `/admin/` until a Pi-hole page changes that path |

### Rules

1. **SNI equals `server_name`.** The URL host is the vhost. `--resolve` only chooses the TCP address.
2. **Keep the default-server 444.** It is what stops an unknown `Host` on the IP. Probes must not need that `if` to be removed.
3. **Tier 2 may be stopped.** A 502 from `n8n.tu.lan` after SNI is correct means the proxy ran. Beginner setup should say that, and should still fail when the code is `000`.
4. **Open WebUI is Tier 1.** After Stage 45 makes `/health/db` a proxied path, the smoke probe expects the upstream status, not the static `healthy` body and not `000`.
5. **Reuse curl.** Do not add a Python HTTP stack for this check.

### Suggested contributor checklist

```text
1. With Nginx up and Open WebUI up, smoke-test.sh --live prints a non-000 code for oweb /health/db
2. curl -k --resolve oweb.tu.lan:443:127.0.0.1 https://oweb.tu.lan/ does not hit the tu.lan 444 rule
3. Beginner test_endpoints passes the landing and Open WebUI checks on a healthy Tier 1
4. With n8n stopped, test_endpoints reports the vhost as reached with 502 and does not fail the whole beginner check for that alone
5. A request to the IP with Host oweb.tu.lan and no --resolve still gets 444 from the default server
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| SNI | `curl --resolve`, already used by the LangGraph smoke script | A custom TLS client |
| Pass/fail | The existing exit codes in `test_endpoints` and `smoke-test.sh` | A new status service |
| Health body | Stage 45 exact location, then the app's own route | Another static `return 200` |
| Community signal | GitHub issue when a vhost name changes | Hard-coding a second domain list in the dashboard |

## Acceptance criteria

- `test_endpoints` and `smoke-test.sh --live` use `--resolve` for every named vhost.
- A healthy Open WebUI is not reported down solely because SNI was an IP.
- The default server still returns 444 for `Host: oweb.tu.lan` when SNI is the bare IP.
- Beginner setup does not require n8n or AFFiNE to be running.
- No new probe dependency is added.

## Verification notes

Read on 2026-10-06. `test_endpoints` curls `https://$vm_ip/` with only `-H "Host: ..."`. `smoke-test.sh` curls `https://127.0.0.1/health/db` with `Host: oweb.tu.lan`. The default server's `if` returns 444 unless `$host` is `tu.lan` or an IPv4 literal. `langgraph-e2e-smoke.sh` is the in-repo `--resolve` example. Nginx was not started, so the `000` curl behavior was not captured live.

## Rollback

Remove `--resolve` and restore the IP URL plus `Host` header. Named vhosts go back to the default-server 444 path.
