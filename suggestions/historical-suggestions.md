# Historical Suggestions Baseline

This file records suggestion history so future work does not re-invent already implemented ideas.

## Baseline method

- Source reviewed: `CHANGELOG.md`, `README.md`, `nginx/html/index.html`, `helper/uploader.py`
- Purpose: map "already done" capabilities vs "still missing" opportunities
- Date captured: 2026-03-24

## Already implemented (do not re-propose as new)

| Area | Suggestion (historical) | Status | Evidence |
|---|---|---|---|
| Service efficiency | Tiered architecture with always-on and on-demand services | implemented | Changelog 2.0.0/2.2.0, README features |
| Dashboard operations | One-click start/stop service controls | implemented | `nginx/html/index.html`, helper control endpoints |
| Observability | Real-time status indicators and response-time checks | implemented | status probing in `index.html`, helper status APIs |
| Notifications | Dashboard success/error/progress notifications | implemented | notification system in `index.html`, Changelog 2.3.0 |
| Security | Token-gated control endpoints and IP allowlist flows | implemented | `helper/uploader.py` auth and whitelist routes |
| Document pipeline | Tika + MinIO processing and PDF status endpoint | implemented | README + Changelog 2.3.0 + helper status endpoint |
| Daily operations | Automated health-check script and update checks | implemented | README operational scripts + changelog notes |

## Previously proposed but still open (from changelog "future enhancements")

| Area | Suggestion | Status | Notes |
|---|---|---|---|
| UX presets | Quick Action Profiles (Work/AI/Storage/Energy modes) | proposed | Good candidate for dashboard UX simplification |
| Power awareness | Battery status integration in dashboard | proposed | Should be optional and privacy-safe |
| Automation | Auto-stop for inactive heavy services | proposed | Needs conservative defaults and clear override |
| Monitoring UX | Resource usage history charts | proposed | Can start with server-side snapshots and simple charts |
| Startup optimization | Fast "Tier 1 only" startup path | proposed | Could be exposed as script + dashboard action |

## New gaps identified (constructional opportunities)

| Gap | Why it matters | Suggested owner |
|---|---|---|
| No dedicated community contribution portal | New contributors lack a guided entry point | Maintainers + docs contributors |
| Single large dashboard file (`index.html`) | Hard to maintain and extend safely | Frontend maintainers |
| No explicit suggestion lifecycle in repo | Ideas can be repeated or forgotten | Project governance |
| Limited contributor tooling around proposal intake | Maintainers handle triage manually | Maintainers + automation contributors |

## Decision log entries

### 2026-03-24

- Created `/suggestions` as the canonical place for proposal history and new community-oriented suggestions.
- Established this baseline to prevent duplicate ideation in upcoming automation runs.
