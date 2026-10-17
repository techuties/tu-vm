---
title: Announcement Firewall Status Contract
description: Constructional contract so the landing-page firewall announcement reads ufw status output, and reads it from the host firewall rather than from inside the helper image.
last_updated: 2026-10-17
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Announcement Firewall Status Contract

## Problem

`announcements()` in `helper/uploader.py` can add two firewall rows when `ENABLE_HOST_CHECKS=1`:

```text
if 'inactive' in out:
    title = Firewall Disabled
elif 'allow 80/tcp' in out and 'allow 443/tcp' in out:
    title = Public Access Enabled
```

`out` is `ufw status` lowercased. `ufw status` prints a table. The To column contains `80/tcp`. The Action column contains `ALLOW`. The words are not the command string `allow 80/tcp`.

Checked on 2026-10-17 by applying that condition to the two layouts `ufw status` produces after `./tu-vm.sh public` and after `./tu-vm.sh secure`, plus the inactive line:

| Status text | `inactive` matches | `allow 80/tcp` and `allow 443/tcp` match |
|---|---|---|
| `Status: inactive` | yes | no |
| `80/tcp ALLOW Anywhere` and `443/tcp ALLOW Anywhere` | no | no |
| `80/tcp ALLOW 192.168.1.0/24` and `443/tcp ALLOW 192.168.1.0/24` | no | no |

Public mode therefore never sets **Public Access Enabled**. Secure mode, which is the LAN allow, does not set it either. That second result is what we want. The first result is the miss: the announcement cannot tell public mode from a table that only has LAN allows, because both fail the same string test.

The lookup also runs in the helper process. The helper service is `python:3-alpine`. Its command installs `docker-cli`, `curl`, and Python packages. It does not install `ufw`. The code looks for `/usr/sbin/ufw`, `/sbin/ufw`, or `/usr/bin/ufw` on that filesystem. Those paths are absent in the image, and the compose service does not mount the host `ufw` binary or the host firewall state. `ENABLE_HOST_CHECKS` defaults to off. Turning it on inside this container still does not see the host rules.

Stage 55 (open PR #81) owns the order of `ufw deny` and `ufw allow` in `enable_secure`. This page does not reorder those commands. It only makes the existing announcement describe the table those commands already produce.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `announcements()` host-check block | The rows to correct |
| `ENABLE_HOST_CHECKS` | Stays off unless an operator opts in |
| `./tu-vm.sh public` and `./tu-vm.sh secure` | The commands that create the rules |
| `ufw status` | The report to parse |
| Helper compose service | Alpine image with the Docker socket. Not a host firewall view |
| Stage 55 firewall command order (expected sibling, open PR #81) | Rule insertion order. Do not change it here |
| Stage 12 announcement categories (expected sibling) | `type` and `priority` values. Keep them |

Out of scope:

- Installing UFW from the helper container
- A new firewall, nftables rewrite, or Tailscale ACL product
- Changing who may call `/announcements`
- Reordering `enable_secure` rules
- Parsing `ufw status verbose` counters

## Proposal

Parse the status table, and run `ufw` where the host rules are visible.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Match | `announcements()` | Treat a row as public when the To field is `80/tcp` or `443/tcp`, the Action field starts with `allow`, and the From field is `anywhere` |
| LAN | Same parser | A From field that is a CIDR or a single address is the secure-mode allow. Do not title that row Public Access Enabled |
| Inactive | Same function | Keep the `inactive` row. `Status: inactive` already matches |
| Where | Host or helper | Run `ufw status` on the host (the same place `tu-vm.sh secure` runs it) and have the helper read that text, or document that the check stays off until the helper can see host `ufw`. Do not `apk add` a firewall into the status API |
| Flag | `ENABLE_HOST_CHECKS` | Leave the default unset. The corrected parser is what runs when an operator sets it |

### Rules

1. **Parse columns, not the command string.** `80/tcp` in To plus `anywhere` in From is the public allow.
2. **A LAN From address is not public mode.** `192.168.1.0/24` must not raise Public Access Enabled.
3. **Inactive stays a warning.** That branch already matches the status line.
4. **Do not install UFW in `python:3-alpine`.** The status API is not the firewall host.
5. **Do not change `enable_secure` or `enable_public` in this patch.** Stage 55 owns command order.
6. **Keep the announcement JSON keys.** `title`, `message`, `type`, `timestamp`, and `priority` stay. Public access stays `type: warning`.

### Suggested contributor checklist

```text
1. Feed a status table with 80/tcp ALLOW Anywhere and confirm the public-access title is present
2. Feed 80/tcp ALLOW 192.168.1.0/24 and confirm that title is absent
3. Feed Status: inactive and confirm Firewall Disabled is present
4. Confirm the helper image command does not gain an ufw package
5. Confirm enable_secure and enable_public are unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Rule report | `ufw status` text the host already prints | A firewall metrics exporter |
| Mode changes | `./tu-vm.sh secure` and `./tu-vm.sh public` | A second firewall wrapper |
| Opt-in | `ENABLE_HOST_CHECKS` | Always probing the host from the dashboard |
