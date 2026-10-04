---
title: Update Check Now Button Contract
description: Constructional contract so the landing-page Check Now button reports the existing checkup file instead of labeling a placeholder as up to date.
last_updated: 2026-10-04
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Update Check Now Button Contract

## Problem

The landing page has a button labeled **Check Now**. Its handler does not check anything:

```javascript
async function checkUpdates() {
  const btn = document.getElementById('btn-update-check');
  btn.disabled = true; btn.textContent = 'Checking...';
  await refreshUpdates();
  btn.disabled = false; btn.textContent = 'Check Now';
}
```

`refreshUpdates` GETs `/status/updates`. Helper `check_updates` reads `/tmp/tu-vm-update-status.json` and, when `last_check` is less than 24 hours old, returns that JSON unchanged. When the file is missing, stale, or unreadable, helper writes and returns:

```json
{
  "updates_available": false,
  "message": "Awaiting daily update check (scheduled)"
}
```

The page treats every `updates_available: false` payload as current:

```javascript
title.textContent = 'System Up to Date';
```

The placeholder message is appended underneath that title. An operator who clicks **Check Now** before the daily job has run sees a green "up to date" state for a check that did not happen.

Two host writers already own the file:

| Writer | What it does |
|---|---|
| `scripts/daily-checkup.sh` `check_for_updates` | Digest and package check. Writes `updates_available`, `message`, `details`, `last_check` |
| `tu-vm.sh` `write_update_notification_entry` | Writes the same shape after an update |

`tu-vm.sh update-check` (`update_check`) prints per-service lines to the terminal. It does not write `/tmp/tu-vm-update-status.json`. Pointing the button at that function would still leave the dashboard file untouched.

Checked by reading `nginx/html/index.html` (`checkUpdates`, `refreshUpdates`) and `check_updates` in `helper/uploader.py`, then `check_for_updates` in `scripts/daily-checkup.sh` and `update_check` / `write_update_notification_entry` in `tu-vm.sh`. The button was not clicked against a live stack.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `#btn-update-check` | The control whose label overclaims the handler |
| `GET /updates` | Cache read plus placeholder writer |
| `scripts/daily-checkup.sh` | Scheduled producer of the real payload |
| `write_update_notification_entry` | Producer used when an update finishes |
| Stage 44 update-status file (expected sibling, open PR history) | Timezone parsing of `last_check`. Leave that logic alone |
| Stage 10 safe-update contribution (expected sibling) | How `./tu-vm.sh update` is allowed to change the stack |

Out of scope:

- A new vulnerability feed, registry scanner, or Flask package checker
- Running `apt` inside the helper container
- Changing the 24-hour freshness window's timezone comparison
- Applying updates from the browser

## Proposal

Keep one status file and the two writers that already fill it. Change the button and the empty state so they describe that file.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Label | `index.html` button and `checkUpdates` | Say **Refresh status**. The handler may keep calling `refreshUpdates` |
| Title | `refreshUpdates` | If `message` is the placeholder, or if `last_check` is absent, title the card with that message. Reserve **System Up to Date** for a payload a real writer produced with `updates_available: false` |
| Placeholder | `check_updates` | When the file is missing or stale, return the awaiting message and do not persist `updates_available: false` as if a check had succeeded. Writing the placeholder is what makes the next 24 hours look checked |
| Real check | Unchanged | Operators and cron keep using `scripts/daily-checkup.sh`. After an update, keep calling `write_update_notification_entry` |
| Optional bridge | `update_check` | If a later change wants the CLI check on the dashboard, have it call `write_update_notification_entry` with the count it already computes. Do not add a third JSON shape |

### Rules

1. **The file is the product.** The dashboard displays it. The dashboard does not invent a second check.
2. **False means a writer said false.** A helper-created placeholder is not a successful check.
3. **Do not shell out to apt from Flask.** OS package checks stay in `daily-checkup.sh`, which already runs on the host.
4. **Do not download images from the button.** `update_check` pulls tags. That stays a deliberate CLI action.
5. **Leave Stage 44's timestamp parsing in place.** This page changes the label, the title branch, and whether the placeholder is stored.
6. **Applying updates stays `./tu-vm.sh update`.** The existing on-page command block is the right next step when `updates_available` is true.

### Suggested contributor checklist

```text
1. Read checkUpdates, refreshUpdates, and helper check_updates
2. Rename the button to Refresh status
3. Show the awaiting message as the title when no writer has checked
4. Stop saving the placeholder as updates_available false
5. Click the button with no status file and confirm the title is not System Up to Date
6. Run daily-checkup.sh and confirm a real false still reads System Up to Date
7. Do not add a scanner endpoint
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Scheduled check | `scripts/daily-checkup.sh` | Flask calling apt or `docker pull` |
| Post-update notice | `write_update_notification_entry` | A new status schema |
| Button | A refresh of the existing GET | A label that says Check Now |
| Apply | `./tu-vm.sh update` | A browser button that mutates the stack |

## Acceptance criteria

- The button text does not say it is checking for updates.
- A missing status file does not render **System Up to Date**.
- Helper does not write `updates_available: false` merely because the file was absent.
- A checkup file with `updates_available: false` still renders **System Up to Date**.
- A checkup file with `updates_available: true` still reveals the existing `./tu-vm.sh update` hint.
- No new update endpoint or image pull is added.

## Verification notes

Traced the click handler to `GET /updates` and the placeholder branch on 2026-10-04. `update_check` has no write to `UPDATE_STATUS_FILE`; `write_update_notification_entry` is the function that does.

## Rollback

Restore the button label and the placeholder write. The checkup script is unchanged.
