---
title: Dashboard Untrusted Text Contract
description: Constructional contract to render helper announcement text, processor filenames, and control errors as text in the existing landing page, without a new UI framework.
last_updated: 2026-09-27
owner: maintainers
status: proposed
theme: dashboard
impact: high
---

# Dashboard Untrusted Text Contract

## Problem

The landing page inserts several strings with `innerHTML`. Those strings are not authored by the dashboard. They come from container logs, object keys, and HTTP bodies.

`renderAnnouncements()` builds each row like this:

```text
li.innerHTML = title + message
```

`/announcements` copies `error_details` from `/tmp/tu-vm-log-status.json` into `message`. `scripts/daily-checkup.sh` fills that field with a raw `docker logs` sample (JSON-escaped, then decoded by `fetch`). A log line that contains markup is executed in the operator browser. The page also keeps `CONTROL_TOKEN` in `localStorage` under `control-token`.

`showNotification()` assigns its `message` argument with `innerHTML`. Callers pass:

- `current_file` from `GET /status/pdf-processing`, which is the object key written by `UniversalMinIOProcessor._update_status`
- the raw `POST /control/...` response body on failures other than 401 and 403

The first PDF toast therefore treats an object key as HTML. Later progress updates already use `textContent` for that same node.

Stage 12 `dashboard-announcements-contract.md` (expected sibling, open PR #38) owns the announcement item shape, priority taxonomy, and the rule that messages stay operational. It does not say how the browser inserts those strings. This page only changes **insertion**. It does not add a sanitizer library, a component framework, or a second dashboard.

`a.type` is also concatenated into `className` (`ann-` + type). Assigning `className` does not run markup. Map it through the existing type set anyway so a later edit cannot move that concatenation into HTML.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/html/index.html` `renderAnnouncements()` | `innerHTML` of `a.title` and `a.message` |
| `nginx/html/index.html` `showNotification()` | `innerHTML` of `message`; `type` is a local label today |
| `nginx/html/index.html` `checkPDF()` | First toast uses `showNotification('Processing: ' + current_file)` |
| `nginx/html/index.html` `controlService()` | `showNotification('Failed: ' + body)` for unexpected statuses |
| `helper/uploader.py` announcements | Copies up to 120 characters of `error_details` into the message |
| `scripts/daily-checkup.sh` `check_log_errors()` | Writes the log sample into `/tmp/tu-vm-log-status.json` |
| `tika-minio-processor/universal_processor.py` `_update_status()` | Stores the object key as `current_file` |
| Stage 12 dashboard announcements (expected sibling) | Item shape and priority; keep it |

Out of scope:

- DOMPurify, a Markdown renderer, or a new frontend framework
- Rewriting announcement categories, priorities, or playbook wording
- Filtering `<` out of MinIO object keys or container logs
- Moving the control token out of `localStorage` (Stage 18 owns token transport)
- Extracting CSS/JS into modules (already tracked as backlog P2-1)

## Proposal

Create text nodes for untrusted strings. Keep the current page, the current JSON, and the current toast function.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Announcement rows | `renderAnnouncements()` | `textContent` for title, relative time, and message |
| Type class | same function | Allow only `info`, `warning`, `critical`, `update`; otherwise `info` |
| Toasts | `showNotification()` | Put `message` in a text node. Keep `type` as the local enum `success` / `error` / `info`. |
| Allowlist rows | `renderAllowlist()` | Keep using a text node for the address. Bind remove with `data-ip` and a listener, not an `onclick` string. |
| Proof | Landing page, helper up | A log sample or object key containing `<img` renders as visible text |

### Rules

1. **Text from the helper, logs, or object storage is text.** Do not concatenate it into HTML.
2. **Do not add a sanitizer dependency.** `textContent` is enough for this page.
3. **Keep the Stage 12 item shape.** `title`, `message`, `type`, `priority`, and `timestamp` stay. This change does not alter `/announcements` JSON.
4. **Progress width stays a number.** `checkPDF()` already clamps `progress` to 0–100 before setting CSS width. Do not interpolate `current_file` into a style attribute.
5. **Allowlist addresses stay out of inline handlers.** `ipaddress` normalization makes today's `onclick` string safe; do not rely on that remaining true.
6. **GitHub remains intake.** A request to replace the landing page with another UI toolkit is an Issue, not part of this fix.

### Suggested contributor checklist

```text
1. Replace the announcement innerHTML assignment with createElement and textContent
2. Allowlist a.type before using it as a class suffix
3. Set the notification message with textContent
4. Pass current_file and control error bodies only as text
5. Render allowlist addresses as text and remove them via data-ip
6. Load the dashboard and confirm a literal <img in a message is visible text
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Untrusted strings | DOM `textContent` on the existing page | DOMPurify, Markdown, or a SPA rewrite |
| Announcement schema | Stage 12 item shape | A new alerts service |
| Proof | One page load with a hostile sample string | A screenshot-only review |
| Asset split | Later P2-1 extraction | Mixing a framework migration into this fix |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Patch `nginx/html/index.html` only. Helper JSON and the checkup script can stay, because the browser stops interpreting them.
3. Verify with the landing page served by Nginx, or by opening the HTML file and stubbing `fetch` if the stack is down. The sample string `<img src=x onerror=alert(1)>` must appear as text in the announcement list and in a processing toast.
4. Confirm Start/Stop and the allowlist remove button still run.

## Acceptance criteria

- [ ] Announcement title and message are assigned with `textContent` (or equivalent text nodes).
- [ ] `showNotification` does not put `message` through `innerHTML`.
- [ ] `current_file` and control error bodies are not interpreted as HTML.
- [ ] `a.type` outside `info` / `warning` / `critical` / `update` becomes `info`.
- [ ] Allowlist remove does not build an `onclick` string from the address.
- [ ] Announcement JSON fields and priorities are unchanged.
- [ ] No new frontend dependency is added.

## Rollback

Revert the landing-page script. Announcements and toasts return to string HTML. Docs-only publication needs no runtime rollback.

## Success metrics

- A markup-bearing log sample or object key cannot read `localStorage['control-token']` or call `/control`.
- Operators still see the log sample and the filename as readable text.
- The page does not gain a second UI stack.
