# Website Framework Suggestions (Community-First)

Status key: `proposed` | `in-progress` | `implemented` | `deferred` | `superseded`

## Context

Current implementation is a single landing/dashboard page (`nginx/html/index.html`) with direct inline JS and CSS, backed by helper endpoints in `helper/uploader.py`.

That is practical and fast, but it is harder for the community to extend safely over time. The suggestions below aim to improve maintainability and contribution flow without breaking the current architecture.

---

## 1) Introduce a lightweight front-end structure without a full rewrite

- **Status:** `proposed`
- **Problem:** Monolithic HTML/CSS/JS in one file increases merge conflicts and discourages focused community PRs.
- **Suggestion:**
  - Split landing page into:
    - `nginx/html/index.html` (layout shell)
    - `nginx/html/assets/app.css`
    - `nginx/html/assets/app.js`
    - `nginx/html/assets/modules/` for isolated features (status polling, service controls, announcements)
  - Keep current UX and behavior unchanged in first pass.
- **Why this matters for community:**
  - New contributors can work on one module without touching unrelated code.
  - Easier code review and ownership per area.
- **Acceptance criteria:**
  - No visible UX regression.
  - Same API calls and controls continue to function.
  - PR diff size for feature changes drops due to modular files.

---

## 2) Add a suggestion-driven plugin registry for dashboard cards

- **Status:** `proposed`
- **Problem:** New cards/features currently require manual edits in multiple places.
- **Suggestion:**
  - Create a JSON-driven registry consumed by front-end rendering logic.
  - Example registry fields:
    - `id`, `title`, `description`
    - `healthEndpoint`, `openUrl`
    - `tier` (always-on / on-demand)
    - `controls` (start/stop supported)
    - `visibility` flags
  - Render service cards based on registry rather than hardcoded markup.
- **Community benefit:**
  - Contributors can add integrations with small, declarative changes.
  - Encourages discussion around schema evolution instead of one-off implementations.
- **Acceptance criteria:**
  - Existing services rendered from registry.
  - Adding one new service does not require editing core rendering logic.

---

## 3) Establish a design token layer for accessibility and consistency

- **Status:** `proposed`
- **Problem:** Colors and spacing are currently hand-managed in inline CSS; consistent a11y checks are difficult.
- **Suggestion:**
  - Define CSS custom properties for:
    - semantic colors (`--color-bg`, `--color-surface`, `--color-success`, `--color-warning`, `--color-danger`)
    - spacing scale
    - typography scale
    - focus ring styles
  - Add keyboard-visible focus states for interactive elements.
  - Validate contrast for status text and badges.
- **Community benefit:**
  - Easier theme and branding contributions.
  - Better accessibility for wider contributor/user base.
- **Acceptance criteria:**
  - All interactive elements keyboard-focusable and visibly focused.
  - Contrast ratios pass for main text and critical statuses.

---

## 4) Move to an event/update feed endpoint for status changes

- **Status:** `proposed`
- **Problem:** Polling many endpoints every cycle can add noise and complexity.
- **Suggestion:**
  - Keep polling as fallback.
  - Add a consolidated status endpoint or server-sent event (SSE) stream from helper service.
  - Front-end subscribes to one source for service states and announcements.
- **Community benefit:**
  - Clearer mental model.
  - Smaller surface area for client-side bug fixes.
- **Acceptance criteria:**
  - Dashboard still works when live stream unavailable (fallback).
  - Reduced repeated request load during normal operation.

---

## 5) Add a docs-backed UI change checklist for contributors

- **Status:** `proposed`
- **Problem:** UI changes can unintentionally break service controls or accessibility.
- **Suggestion:**
  - Embed a short checklist section in this file for PR authors:
    - keyboard navigation tested
    - mobile viewport checked
    - error state and loading state tested
    - control token path unaffected
    - no secrets surfaced in UI logs
- **Community benefit:**
  - Improves quality and confidence for first-time contributors.
- **Acceptance criteria:**
  - Checklist referenced in contribution flow and used in feature PRs.

---

## 6) Optional framework path (only if complexity grows)

- **Status:** `deferred`
- **Suggestion:** Evaluate migration to a small framework (for example, Svelte or Vue with static output) only when:
  - module count grows significantly,
  - testing complexity exceeds plain JS maintainability,
  - community contributors request stronger component ergonomics.
- **Guardrail:** Avoid framework migration solely for trend reasons; preserve lightweight deployment.

