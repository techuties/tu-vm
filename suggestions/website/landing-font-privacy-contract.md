---
title: Landing Font Privacy Contract
description: Constructional contract so the LAN dashboard uses the system font stack already in its stylesheet and does not request fonts from Google.
last_updated: 2026-10-18
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Landing Font Privacy Contract

## Problem

Opening the landing page asks Google for fonts.

`nginx/html/index.html` starts its stylesheet with:

```css
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Outfit:wght@300;400;500;600;700&display=swap');
```

That CSS URL returns a stylesheet that points at `fonts.gstatic.com`. The browser sends it when the dashboard loads. The rest of the file already names fallbacks:

| Rule | Families |
|---|---|
| `html, body` | `'Outfit', system-ui, -apple-system, sans-serif` |
| `.svc-url`, `.kpi-value`, inputs, allowlist rows | `'JetBrains Mono', monospace` |

If the import fails or is removed, those generic families still match. The page does not need the remote files to render.

`nginx/nginx.conf` sets a Content-Security-Policy whose `style-src` and `font-src` would block this import. The landing `server` in `nginx/conf.d/default.conf` sets its own `add_header` lines (HSTS, nosniff, `X-Frame-Options`, referrer, XSS). Nginx then does not send the HTTP-level policy on that vhost. Stage 42 (open PR #68) records that inheritance rule and says not to copy the HTTP policy onto application vhosts. The font request is therefore sent today. Turning the HTTP policy on just to hide the import would be that other page's decision, and it would also change script and connect rules.

Checked on 2026-10-18 by reading `nginx/html/index.html`, `nginx/nginx.conf`, and the landing `server` block. No browser was required to see the `@import`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/html/index.html` stylesheet | The `@import` to remove, and the fallbacks to keep |
| Landing `server` headers | Security headers that already replace the HTTP-level set |
| `nginx/nginx.conf` CSP | Present, and not what this vhost sends |
| Stage 42 header inheritance (open PR #68) | Do not "fix" fonts by promoting that CSP |
| Stage 43 untrusted text (open PR #69) | `textContent` for dashboard strings. Unrelated to stylesheets |

Out of scope:

- Vendoring Outfit or JetBrains Mono, or adding a font build step
- A font proxy, or self-hosting a Google CSS mirror
- Enabling the `nginx.conf` Content-Security-Policy on `tu.lan`
- Restyling the dashboard

## Proposal

Delete the `@import`. Keep the `font-family` lists so `system-ui` and `monospace` apply.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Stylesheet | `nginx/html/index.html` | Remove the `fonts.googleapis.com` `@import` |
| Families | Same file | Leave `'Outfit', system-ui, ...` and `'JetBrains Mono', monospace` in place. The first missing family is skipped |
| Proof | Response body | `curl -sk https://127.0.0.1/ -H 'Host: tu.lan'` does not contain `fonts.googleapis.com` or `fonts.gstatic.com` |
| Headers | Landing `server` | No `add_header` edit in this change |

### Rules

1. **Stop the request.** The dashboard HTML must not reference `fonts.googleapis.com` or `fonts.gstatic.com`.
2. **Use the fallbacks already written.** Do not add a new font file to the repository for this change.
3. **Leave the CSP where Stage 42 put it.** Do not attach `nginx.conf`'s policy to the landing vhost in order to block the import.
4. **Keep the layout.** Colors, cards, and the service grid stay as they are.

### Suggested contributor checklist

```text
1. Grep nginx/html for fonts.googleapis.com and fonts.gstatic.com
2. Confirm html/body still lists system-ui
3. Confirm monospace is still the fallback for the mono rules
4. Fetch the landing HTML and confirm those host names are absent
5. Confirm nginx.conf CSP was not copied onto the landing server
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| UI type | `system-ui` and `monospace` already in the stylesheet | A downloaded webfont |
| Privacy | A page that does not call Google | A CSP change owned by Stage 42 |
| Delivery | The existing Nginx static root | A font CDN |
