# Website Feature Suggestions (Community-Centered, Non-Duplicative)

This document proposes concrete dashboard/website improvements that align with the repository’s existing direction and avoid duplicating solved capabilities.

---

## What already exists (so we do not duplicate)

Before adding new features, preserve these proven patterns:

- Real-time status and service controls
- Tier 1 vs Tier 2 operational model
- Update check UI and safety-first update guidance
- Control token + allowlist model
- Pipeline explainers for MCP/LangGraph/n8n and Tika/RAG
- Announcement/notification systems

The suggestions below are extensions, not replacements.

---

## Priority 1: Quick Action Profiles

### Why this matters
The changelog explicitly mentions “Quick Action Profiles” as a future enhancement. This is high-impact and already conceptually validated.

### Suggestion
Add one-click profiles in the dashboard:

- Work Mode (core + n8n + gateway + supervisor)
- AI Mode (core + ollama + open-webui dependencies)
- Full Storage (core + minio + tika + qdrant)
- Energy Save (Tier 1 only)

### Implementation notes

- Keep profile definitions as data (JSON) so community can tune without editing JS logic.
- Add dry-run preview: “This profile will start X and stop Y.”
- Route all actions through existing control endpoints to retain security posture.

### Acceptance criteria

- Operators can apply a profile in one click.
- Resulting service states match profile declaration.
- Profile application reports partial failures clearly.

---

## Priority 2: Service Dependency Assistance (Advisory-first)

### Why this matters
Users currently manage many service relationships manually. This is error-prone.

### Suggestion
When starting a service, show dependency hints:

- “Starting MCP Gateway works best with n8n online.”
- “RAG features require Qdrant + embeddings backend.”

Start with advisory hints only; optional auto-start can be a later gated toggle.

### Implementation notes

- Define dependencies in a simple map.
- Present hints before sending control call.
- Keep manual override (“Start anyway”).

### Acceptance criteria

- Dashboard surfaces dependencies contextually.
- No forced behavior changes in first release.

---

## Priority 3: Historical Uptime/Latency Snapshots

### Why this matters
Current dashboard shows point-in-time checks. Operators benefit from trend visibility.

### Suggestion
Store lightweight rolling metrics (for example 24h and 7d):

- per-service uptime ratio
- median response time
- last outage timestamp

### Implementation notes

- Persist tiny JSON snapshots via helper API.
- Keep collection interval aligned with existing polling cadence to avoid resource spikes.
- Use accessible charts with alt text and keyboard-focus labels.

### Acceptance criteria

- At least one trend graph per metric group is visible.
- Data survives dashboard reload and container restarts (via mounted state).

---

## Priority 4: Community Suggestion Intake Panel

### Why this matters
The request emphasizes a community-based system. The website can become the front door for improvement ideas.

### Suggestion
Add a “Suggest an Improvement” panel with:

- category selection (UX, performance, security, docs)
- expected impact
- reproducibility/steps (if bug)
- optional “I can contribute code/docs” checkbox

### Implementation notes

- Start with writing structured entries to local JSON/markdown queue.
- Optionally sync queue to GitHub Discussions/Issues in later phase.
- Display latest accepted suggestions on dashboard (“community wins”).

### Acceptance criteria

- Suggestions can be submitted and stored in structured format.
- Maintainers can review and triage without external tooling.

---

## Priority 5: Contributor Readiness Widgets

### Why this matters
Make contribution easier from inside the dashboard.

### Suggestion
Add small widgets linking to:

- “How to run checks”
- “How to propose a change”
- “Known high-impact tasks”
- “Safety checklist before pushing”

### Implementation notes

- Pull content from versioned docs files (single source of truth).
- Keep widget copy concise and version-aware.

### Acceptance criteria

- New contributors can discover workflows in under 2 clicks.
- Guidance matches current repository scripts/commands.

---

## Priority 6: Role-Oriented Views

### Why this matters
Different users need different detail levels.

### Suggestion
Offer view modes:

- Operator view: status, controls, updates, alerts
- Builder view: pipeline internals, diagnostics links, script shortcuts
- Auditor view: security posture summary and verification signals

### Implementation notes

- Reuse existing data; mostly presentation-layer adaptation.
- Persist selected mode in local storage.

### Acceptance criteria

- View mode switch changes emphasis without removing critical controls.
- No server-side complexity required in first iteration.

---

## Priority 7: Accessibility and Mobile Hardening

### Why this matters
Dashboard usage includes tablets/phones and mixed skill users.

### Suggestion

- Ensure all interactive controls have ARIA labels and keyboard focus states.
- Improve small-screen spacing and card action ergonomics.
- Add readable contrast checks for status colors.

### Acceptance criteria

- Keyboard-only flow can trigger controls and navigate alerts.
- No clipped/overlapping content at common mobile widths.

---

## Sequenced implementation path

1. Quick Action Profiles
2. Dependency Assistance
3. Uptime/Latency Snapshots
4. Suggestion Intake Panel
5. Role-Oriented Views
6. Accessibility/Mobile hardening (parallelizable with all above)

This order provides immediate user value while building the foundation for a sustained community contribution loop.
