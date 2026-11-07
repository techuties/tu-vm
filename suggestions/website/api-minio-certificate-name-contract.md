---
title: MinIO API Certificate Name Contract
description: Constructional contract so the self-signed certificate names api.minio.tu.lan, the host Nginx and Pi-hole already publish.
last_updated: 2026-11-07
owner: maintainers
status: proposed
theme: security
impact: high
---

# MinIO API Certificate Name Contract

## Problem

MinIO's S3 API is served as `api.minio.tu.lan`. The certificate the stack generates does not name that host.

`generate_ssl_certificates` in `tu-vm.sh` builds one self-signed certificate:

```text
openssl req -x509 ... -addext "subjectAltName=DNS:$domain,DNS:*.$domain,DNS:localhost,IP:127.0.0.1"
```

With `domain=tu.lan`, OpenSSL 3.0.13 prints:

```text
DNS:tu.lan, DNS:*.tu.lan, DNS:localhost, IP Address:127.0.0.1
```

`openssl x509 -checkhost` against that certificate on 2026-11-07:

| Host | Result |
|---|---|
| `tu.lan` | does match certificate |
| `minio.tu.lan` | does match certificate |
| `oweb.tu.lan` | does match certificate |
| `api.minio.tu.lan` | does NOT match certificate |
| `foo.bar.tu.lan` | does NOT match certificate |

The wildcard is one label. `*.tu.lan` covers `minio.tu.lan` and does not cover `api.minio.tu.lan`.

The name is already in the operator path:

- `nginx/conf.d/default.conf` has `server_name api.minio.tu.lan` on port 80 and on port 443, proxying to MinIO port 9000.
- `sync_pihole_dns_records` includes `api.minio.tu.lan` in the `*.tu.lan` name list.
- `show_access_info` prints `https://api.minio.tu.lan`.

A client that checks the certificate, including `mc` and rclone against that URL, fails the name check even after the operator trusts the self-signed certificate. The console host `minio.tu.lan` is not the failing name.

The certificate files were written under `/tmp` for the check. `ssl/nginx.crt` and `ssl/nginx.key` in the repo were not created. `.env` was not created.

Stage 56 (open PR #82, `tls-certificate-san-refresh-contract.md`) owns reissue when `DOMAIN` or a host IP changes, and adding the LAN address to the SAN list. That page does not mention `api.minio`. This page only adds the DNS name the wildcard misses. Stage 10 (open PR #36) owns the lifecycle rule: keep this generator, do not add a public CA.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `generate_ssl_certificates` | The `openssl req -addext` line to extend |
| `server_name api.minio.tu.lan` | The Nginx name that must appear on the certificate |
| Pi-hole name list in `sync_pihole_dns_records` | Already publishes `api.minio.tu.lan` |
| `show_access_info` | Already prints the API URL |
| Stage 56 SAN refresh page (open PR #82) | IP address and reissue when files already exist |
| Stage 10 TLS lifecycle page (open PR #36) | No public CA |

Out of scope:

- Let's Encrypt, a private CA product, or a second certificate file
- Rewriting `server_name` lines (Stage 32, open PR #58)
- The early return when `ssl/nginx.crt` already exists (Stage 56, open PR #82)
- Cipher suite tokens (Stage 49, open PR #75)

## Proposal

Add the API host to the SAN string this function already passes to OpenSSL.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| SAN list | `generate_ssl_certificates` | Include `DNS:api.minio.$domain` in the existing `-addext` value, next to `DNS:$domain` and `DNS:*.$domain` |
| Reissue | Stage 56's refresh, when that page is implemented | Keep `DNS:api.minio.$domain` in the list that gets rewritten. Do not implement the early-return change on this page |

### Rules

1. **One certificate.** Do not add `ssl/minio.crt` or a second `openssl` invocation.
2. **Explicit name.** `DNS:api.minio.$domain` is required. A second wildcard such as `*.*.$domain` is not a substitute. Browsers and OpenSSL do not treat that as a cover for this name.
3. **Existing names stay.** `tu.lan`, `*.tu.lan`, `localhost`, and `127.0.0.1` remain. Stage 56 may add the LAN IP beside them.
4. **Nginx and Pi-hole stay.** Do not rename `api.minio.tu.lan` to a single-label host.
5. **No public CA.** Trust remains the operator's choice for this self-signed file.
6. **Do not write repo `ssl/` during review.** Prove the name with a certificate under `/tmp`.

### Suggested contributor checklist

```text
1. Generate a certificate with the current -addext string and confirm checkhost rejects api.minio.tu.lan
2. Add DNS:api.minio.$domain and confirm checkhost matches api.minio.tu.lan
3. Confirm minio.tu.lan, oweb.tu.lan, and tu.lan still match
4. Confirm foo.bar.tu.lan still does not match
5. Confirm the Nginx server_name and the Pi-hole name list were not edited
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Certificate | `generate_ssl_certificates` | A new CA container |
| Name source | `server_name api.minio.tu.lan` and the Pi-hole name list | A hard-coded second domain |
| Proof | `openssl x509 -checkhost` | A browser-only check |
| Intake | GitHub Issue | A certificate portal |

### Acceptance check

- [ ] A certificate from `generate_ssl_certificates` with `DOMAIN=tu.lan` makes `openssl x509 -checkhost api.minio.tu.lan` print `does match certificate`.
- [ ] `minio.tu.lan`, `oweb.tu.lan`, and `tu.lan` still match.
- [ ] `foo.bar.tu.lan` does not match.
- [ ] The function still writes `ssl/nginx.crt` and `ssl/nginx.key` only.
- [ ] Nginx `server_name` lines and the Pi-hole name list are unchanged.
- [ ] The proof certificate was written under `/tmp`, not into the repo `ssl/` directory, and `.env` was not created.

### Rollback

Remove `DNS:api.minio.$domain` from the `-addext` string. `api.minio.tu.lan` fails the name check again. The other names stay.
