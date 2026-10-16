---
title: TLS Certificate SAN Refresh Contract
description: Constructional contract so generate_ssl_certificates reissues the self-signed certificate when DOMAIN or the host IPv4 addresses change, and includes the IP the default Nginx vhost already allows.
last_updated: 2026-10-16
owner: maintainers
status: proposed
theme: security
impact: high
---

# TLS Certificate SAN Refresh Contract

## Problem

`start_services` calls `ensure_host_ip_configured` and then `generate_ssl_certificates`. The certificate function returns immediately when both files exist:

```text
ssl/nginx.crt
ssl/nginx.key
```

It never reads `HOST_IP` or `TAILSCALE_IP`. On a first run the SAN extension is exactly:

```text
DNS:$domain, DNS:*.$domain, DNS:localhost, IP:127.0.0.1
```

Checked on 2026-10-16 by running that `openssl req -x509 -addext` invocation with `domain=tu.lan` into `/tmp` (the repo `ssl/` directory was not written). `openssl x509 -noout -ext subjectAltName` printed:

```text
DNS:tu.lan, DNS:*.tu.lan, DNS:localhost, IP Address:127.0.0.1
```

A second run of the guard, against a pair of empty files in a temp directory, took the early return and did not generate again.

The default Nginx server is written for direct IP access. Both the port 80 and port 443 `default_server` blocks allow a `Host` that is `tu.lan` or an IPv4 address, and close every other name. A browser that opens `https://` plus the LAN address from `HOST_IP` is speaking to a vhost the config allows, with a certificate that does not name that address. Changing `DOMAIN` in `.env` has the same gap: Pi-hole sync and, once Stage 32 lands, server names follow `DOMAIN`, and the existing cert stays on the previous names because the files are already there.

Stage 10 (open PR #36) is the lifecycle contribution rule: keep `generate_ssl_certificates`, do not add a public CA, and do not treat a generic self-signed warning as a reason for telemetry. This page is the SAN list and the early return inside that function. Stage 49 (open PR #75) owns the cipher tokens. Stage 32 (open PR #58) owns rewriting `server_name` from `DOMAIN`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `generate_ssl_certificates` | The only issuer. It already shells out to `openssl req` |
| `ensure_host_ip_configured` | Runs earlier in `start` and writes `HOST_IP` when it can detect one |
| `get_tailscale_ip` / `ensure_tailscale_ip_configured` | The other IPv4 already stored for DNS |
| `DOMAIN` in `.env` | Already interpolated into the CN and the DNS SANs on first issue |
| Nginx `default_server` host check | Accepts `tu.lan` or an IPv4 `Host` |
| Stage 10 TLS lifecycle page (expected sibling, open PR #36) | Process rules. Do not add Certbot here |
| Stage 32 server-name page (expected sibling, open PR #58) | Nginx names. This page does not template `default.conf` |
| Stage 20 IPv6 page (open PR #46) | IPv6 listen policy. Do not add an IPv6 SAN rule here |

Out of scope:

- Let's Encrypt, certbot, or inbound TCP 80 from the public internet
- Committing `ssl/nginx.key`
- Replacing the self-signed cert with a private CA product
- Cipher suite changes
- Rewriting `server_name` lines

## Proposal

Keep one `openssl` invocation. Reissue when the names the operator already configured are not on the certificate.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Names | `generate_ssl_certificates` | Build the SAN from `DOMAIN` (default `tu.lan`), `DNS:*.$domain`, `DNS:localhost`, `IP:127.0.0.1`, plus `IP:` for `HOST_IP` and `TAILSCALE_IP` when each value is an IPv4 address |
| Refresh | Same function | If the cert exists, read `subjectAltName` with `openssl x509 -noout -ext subjectAltName`. Reissue when any required name is absent. If `openssl` cannot read the cert, reissue |
| Stamp | Optional one-line file `ssl/nginx.san` next to the cert, mode `644`, no key material | Record the SAN string that was requested so the next start can compare without depending on openssl text wrapping. The key stays mode `600` |
| Order | `start_services` | Keep generating after `ensure_host_ip_configured` and `ensure_tailscale_ip_configured` so those values exist |
| Failure | Same function | A failed `openssl` stays a non-zero exit. Do not leave a half-written key. Write to a temp file in `ssl/` and rename |

### Rules

1. **First start and a changed address both produce a cert that matches this start.** An existing pair is not by itself a reason to return.
2. **Only add an IP that parses as IPv4.** An empty `HOST_IP` adds nothing. Do not copy the placeholder `10.211.55.12` or `CHANGE_ME` into the SAN. `ensure_host_ip_configured` already replaces those before this function runs. If detection failed and the value is still empty or a placeholder, skip that IP.
3. **Do not enable UFW or publish port 80 to the internet as part of reissue.**
4. **Nginx stays on the same two files.** `ssl_certificate` paths in `default.conf` do not change.
5. **Self-signed warnings for a name that is on the cert remain operator trust-store work.** Stage 10 already says that. This contract only adds the names the vhost and `.env` already use.

### Suggested contributor checklist

```text
1. With no cert, generate and confirm SAN contains DNS:tu.lan, DNS:*.tu.lan, and IP:127.0.0.1
2. Set HOST_IP=192.0.2.10 and confirm the new cert contains IP:192.0.2.10
3. Change DOMAIN to lab.example with the old cert still present and confirm the reissued SAN contains DNS:lab.example
4. Run start again with the same DOMAIN and HOST_IP and confirm the key inode is unchanged
5. Confirm ssl/nginx.key is mode 600 and the key was not printed
6. Confirm https://192.0.2.10 presents a cert whose SAN includes that address
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Issuer | `openssl req -x509` already called by `tu-vm.sh` | Certbot or a certificate controller |
| Address source | `HOST_IP` and `TAILSCALE_IP` already written before this function | A new discovery daemon |
| Name check | `openssl x509 -ext subjectAltName` | A custom ASN.1 parser |
| Edge | The existing default server | A second listener for bare IPs |
