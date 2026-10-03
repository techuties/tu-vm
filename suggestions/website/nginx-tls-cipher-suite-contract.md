---
title: Nginx TLS Cipher Suite Contract
description: Constructional contract to replace two nonexistent OpenSSL cipher names repeated on eight HTTPS server blocks with one included suite list.
last_updated: 2026-10-03
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Nginx TLS Cipher Suite Contract

## Problem

`nginx/conf.d/default.conf` sets this `ssl_ciphers` line on all eight HTTPS servers (`tu.lan`, `n8n.tu.lan`, `oweb.tu.lan`, `affine.tu.lan`, `ollama.tu.lan`, `pihole.tu.lan`, `minio.tu.lan`, `api.minio.tu.lan`):

```text
ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384
```

OpenSSL 3.0.13 on 2026-10-03:

| Cipher string | Result |
|---|---|
| `ECDHE-RSA-AES256-GCM-SHA512` | exit 1, `no cipher match` |
| `DHE-RSA-AES256-GCM-SHA512` | exit 1, `no cipher match` |
| The full four-name string | exit 0 |

The successful selection does not contain either SHA-512 name. The TLS 1.2 suites that remain are `ECDHE-RSA-AES256-GCM-SHA384` and `DHE-RSA-AES256-GCM-SHA384`. AES-GCM cipher suites use SHA-256 or SHA-384. The SHA-512 tokens look stricter than the suites Nginx can offer.

`SSL_CTX_set_cipher_list` (what Nginx `ssl_ciphers` calls) succeeds when at least one name matches, so `nginx -t` can still pass. Operators reading the file believe SHA-512 suites are enabled. They are not. The same string is copied eight times, so a correction in one server leaves the other seven wrong.

`ssl_protocols` is `TLSv1.2 TLSv1.3`. TLS 1.3 suites are not controlled by this `ssl_ciphers` list. Leave that protocol line in place.

Checked with the host `openssl ciphers` command and a count of `ssl_ciphers` in `nginx/conf.d/default.conf` (eight). The Nginx container was not started. Confirm `nginx -t` inside the pinned `nginx` image before merge, because that image's OpenSSL is the one that loads the file.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ssl_ciphers` in eight server blocks | The duplicated list |
| `ssl_protocols TLSv1.2 TLSv1.3` | The protocol floor to keep |
| `ssl_certificate` / `ssl_certificate_key` | The existing self-signed pair |
| `include /etc/nginx/conf.d/*.conf` | How a shared snippet is loaded |
| Stage 12 Nginx edge routing (expected sibling) | Virtual hosts and proxying |
| Stage 36 TLS certificate lifecycle (expected sibling) | Certificate files, not suite names |

Out of scope:

- Replacing Nginx with another proxy
- Public ACME or a new certificate authority
- Disabling TLS 1.3
- A new cipher-scanning container

## Proposal

Put one suite list in a snippet every HTTPS server includes.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Snippet | `nginx/conf.d/ssl-ciphers.conf` included from each HTTPS server | One `ssl_ciphers` and one `ssl_protocols` line |
| Names | That snippet | Keep `ECDHE-RSA-AES256-GCM-SHA384`. Drop both `*-SHA512` tokens |
| DHE | Same line | Keep `DHE-RSA-AES256-GCM-SHA384` only if `openssl ciphers` on the pinned image still prints it and a `ssl_dhparam` file exists. Otherwise ship the ECDHE suite only |
| Call sites | Eight `server` blocks | Replace the inline directive with `include` |
| Check | Contributor checklist | `openssl ciphers` on each token, then `nginx -t` in the pinned image |

A single include is the Nginx mechanism this repo already uses for `conf.d` and the control allowlist. It does not add a process.

### Rules

1. **Every token must match a suite.** `openssl ciphers TOKEN` exits 0 for each colon-separated name before the pull request merges.
2. **TLS 1.2 and TLS 1.3 both stay.** Do not narrow `ssl_protocols` while fixing names.
3. **One list.** After the change, `grep -c ssl_ciphers nginx/conf.d/default.conf` is 0, and the snippet contains the only `ssl_ciphers` directive.
4. **Prefer ECDHE.** DHE is optional and needs a known DH parameter file. Missing `ssl_dhparam` means the DHE name is decorative.
5. **Do not add a scanner container.** `openssl` on the operator host and `nginx -t` in the existing image are the checks.

### Suggested contributor checklist

```text
1. Run openssl ciphers on each name in the current string and record which exit 0
2. Add nginx/conf.d/ssl-ciphers.conf with the names that matched
3. Replace the eight inline ssl_ciphers lines with include
4. nginx -t inside the pinned nginx image exits 0
5. A TLS 1.2 client negotiates ECDHE-RSA-AES256-GCM-SHA384
6. TLS 1.3 is still offered
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Shared TLS lines | Nginx `include` | Eight copied server blocks |
| Suite check | `openssl ciphers` and `nginx -t` | A custom cipher linter service |
| Certificates | Existing `ssl/nginx.crt` flow | A new CA |
| Intake | GitHub Issue | A security-policy microsite |

## Acceptance criteria

- Neither SHA-512 cipher name remains in `nginx/conf.d`.
- Exactly one `ssl_ciphers` directive exists, in the shared snippet.
- `nginx -t` succeeds in the pinned Nginx image.
- `ssl_protocols` still lists TLSv1.2 and TLSv1.3.

## Verification notes

Host command was OpenSSL 3.0.13 (`openssl version`). The two SHA-512 names failed alone. The four-name string exited 0 and printed `ECDHE-RSA-AES256-GCM-SHA384` and `DHE-RSA-AES256-GCM-SHA384` as the TLS 1.2 selections. Docker was not running, so the in-image `nginx -t` is still required before merge.

## Rollback

Restore the inline `ssl_ciphers` lines and remove the include. HTTPS returns to today's behavior, including the ignored SHA-512 tokens.
