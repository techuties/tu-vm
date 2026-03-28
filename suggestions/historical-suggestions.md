# Historical Suggestions Baseline

This file captures what is already in place so future proposals do not re-invent existing features.

## Already Implemented (Use as Building Blocks)

| Area | Existing Capability | Where It Lives |
|---|---|---|
| Service visibility | Real-time service badges and health probes (`/status/*`) | `nginx/html/index.html`, `helper/uploader.py` |
| Operations control | Start/stop services with token auth (`/control/<service>/<action>`) | `helper/uploader.py` + dashboard buttons |
| Security controls | IP allowlist management and bootstrap (`/whitelist/*`) | `helper/uploader.py`, Nginx dynamic include |
| Update awareness | Daily update status and user notification hooks | `scripts/daily-checkup.sh`, `helper/uploader.py`, dashboard JS |
| Incident awareness | Announcements feed from health/log/update checks | `helper/uploader.py` (`/announcements`) |
| Laptop efficiency model | Tier 1 always-on + Tier 2 on-demand service strategy | `README.md`, compose/service control paths |

## Partially Implemented (Good Starting Points)

| Topic | Current State | Gap to Close |
|---|---|---|
| Announcements UX | Feed and dropdown exist | No community authorship, no categories/tags, no archival view |
| Operational guidance | Helpful status messages and tips | No structured “playbook” links by issue type |
| Contribution visibility | Contributor acknowledgement exists | No “how to propose/track suggestions” website flow |
| Status data | JSON status files and APIs exist | No persistent suggestion data model (proposal lifecycle) |

## Not Implemented Yet (Primary Opportunity)

1. **Community Suggestions Board**  
   No first-class submission, voting, moderation, or lifecycle tracking for suggestions.
2. **Suggestion Prioritization Framework**  
   No scoring model for impact/effort/risk to guide what gets implemented next.
3. **Maintainer Workflow Tools**  
   No automated triage templates, duplicate detection, or release-note mapping for accepted suggestions.

## Reuse-First Guidance

- Reuse current stack before adding new heavy components:
  - Extend `helper/uploader.py` with suggestion endpoints.
  - Keep Nginx-served UI as static-first HTML/JS unless server-side rendering becomes necessary.
  - Reuse announcement and notification patterns already present in the landing page.
- Only introduce a new service if the data model, moderation, or scale clearly outgrows the current helper API.

## Historical Decision Rules

When evaluating a new suggestion:

1. **Check overlap** with this baseline first.
2. **Prefer extension** of existing APIs and UI components.
3. **Define lifecycle state** (`proposed`, `accepted`, `implemented`, `rejected`).
4. **Record implementation path** (files/endpoints touched) to keep future proposals aligned.
