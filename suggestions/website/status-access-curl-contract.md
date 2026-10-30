---
title: Status Access Curl Contract
description: Constructional contract so tu-vm.sh status reports Tier 1 health from check_service_health instead of an unbounded curl of the VM IP.
last_updated: 2026-10-30
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Status Access Curl Contract

## Problem

`show_status` prints Tier 1 and Tier 2 results from `check_service_health` and `docker inspect`, then calls `show_access_info`. That function ends with:

```text
if curl -k -s -o /dev/null "https://$vm_ip"; then
    echo "Services are accessible"
else
    echo "Services may not be accessible"
fi
```

`vm_ip` comes from `get_vm_ip`. The curl has no `--fail`, no `--max-time`, and no `--resolve`. Curl's exit status is 0 for any completed HTTP response, including 500. A peer that accepts TCP and then stalls holds the command until the client gives up, and `./tu-vm.sh status` is stuck inside this `if`.

Replayed on 2026-10-30 against loopback, using the same `-k -s -o /dev/null` shape:

| Peer | Flags | Result |
|---|---|---|
| HTTP 500 | `-k -s -o /dev/null` | Exit 0, `%{http_code}` 500 |
| HTTP 500 | `-fsS -o /dev/null` | Exit 22 |
| TCP accept, no TLS bytes | `-k -s -o /dev/null`, wrapped by `timeout 3` | Exit 124. Curl was still running at 3 seconds |
| TCP accept, no TLS bytes | `--max-time 1` | Exit 28 |

The landing vhost serves the dashboard as static files:

```text
root /usr/share/nginx/html;
index index.html;
location / {
    try_files $uri /index.html;
}
```

Its `location = /health` returns `200` from Nginx itself. A successful curl of `https://$vm_ip` means the default server answered. It does not mean Postgres, Redis, Qdrant, MinIO, Open WebUI, or the helper answered. `show_status` can print red Tier 1 rows and then a green "Services are accessible" line from this curl.

Stage 52 (open PR #78) owns `test_endpoints` and `scripts/smoke-test.sh --live`, which set `Host` and still send the IP as SNI. This curl does not set `Host`. It is a different check, in `show_access_info` only. Stage 57 (open PR #83) owns the hardcoded `tu.lan` strings printed above the curl. This page does not rename those hostnames.

Checked on 2026-10-30 by reading `show_access_info`, `show_status`, and the `tu.lan` server block. The curl table was replayed locally. Nginx was not started. `tu-vm.sh` was not executed.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `check_service_health` | Per-service running and healthcheck result `show_status` already prints |
| `show_status` Tier 1 loop | The list this summary should agree with |
| Landing `try_files` and `location = /health` | Why a 200 from Nginx is not a data-plane check |
| `get_vm_ip` | Source of the address. Unchanged here |
| Stage 52 endpoint SNI (open PR #78) | `test_endpoints` and live smoke. Unchanged here |
| Stage 57 domain suffix (open PR #83) | The `tu.lan` labels in `show_access_info`. Unchanged here |
| Stage 48 startup gate (open PR #74) | How long Tier 1 may stay `starting`. Unchanged here |

Out of scope:

- A new monitoring agent
- Changing `test_endpoints` or the live smoke script (Stage 52)
- Rewriting `get_vm_ip`
- Replacing the printed hostnames (Stage 57)
- Dashboard tiles in `nginx/html/index.html`

## Proposal

Make the closing line of `show_access_info` repeat the Tier 1 results `show_status` already computed.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Summary | `show_access_info` | Delete the bare `curl` of `https://$vm_ip` |
| Wording | Same function | Print "Tier 1 services are up" only when every `check_service_health` call in the Tier 1 loop succeeded |
| Failure | Same function | When any Tier 1 service failed, print that name. Reuse the service id the loop already uses |
| Edge, if a curl remains | Same function | Label it "landing page", use `--fail` and `--max-time 5`, and do not call the result "services" |
| SNI | Leave it | Any remaining named-vhost curl follows Stage 52. This change does not have to land that work |

### Rules

1. **The green line matches the Tier 1 icons above it.** `check_service_health` is the signal. A static `index.html` response is not.
2. **HTTP 500 is not success.** The replay exited 0 without `--fail` and 22 with `--fail`.
3. **Status returns.** A peer that accepts and stalls must not hold the command. `--max-time 5` is enough if a curl is still required. The Tier 1 inspect path does not need a curl.
4. **Do not edit `test_endpoints`.** Stage 52 owns that SNI bug.
5. **Do not edit the hostname strings.** Stage 57 owns `tu.lan` in this function.

### Suggested contributor checklist

```text
1. Confirm show_access_info no longer curls https://$vm_ip with only -k -s
2. Confirm a failed Tier 1 check_service_health does not print "Services are accessible"
3. Confirm an HTTP 500 peer is not treated as success if any curl remains
4. Confirm a stalled TCP accept cannot hold the command for more than 5 seconds
5. Confirm test_endpoints, get_vm_ip, and the tu.lan labels are not edited
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service up | `check_service_health` already called by `show_status` | A second probe of the static dashboard |
| Time bound | Curl `--max-time` if a curl remains | An unbounded client |
| HTTP failure | Curl `--fail` | Exit 0 on status 500 |
| Intake | GitHub Issue | A status SaaS |
