# Website Community Framework Suggestion

## 1) Problem statement

TU-VM has strong technical capabilities, but community contributions are currently distributed across code, docs, and ad-hoc discussions. Without a clear website-level framework, useful ideas can be lost, duplicated, or hard to prioritize.

## 2) Objective

Create a community-based website framework that:

- Makes suggestions easy to submit and discover.
- Uses clear review/decision states.
- Reuses existing TU-VM components instead of introducing a heavy new platform.
- Keeps maintainers in control while allowing community momentum.

## 3) Reuse-first approach (do not reinvent)

The framework should build on existing assets already present in this repository:

- `nginx/html/index.html` for public-facing sections and navigation.
- `helper/uploader.py` for lightweight API endpoints that can support suggestion intake and listing.
- Existing operational controls and status model from the helper dashboard.
- Existing security model through Nginx + tokenized backend endpoints.

This avoids introducing a full CMS in phase 1.

## 4) Proposed website information architecture

Add a dedicated website section called **Community Suggestions** with these pages:

1. **/community/suggestions**
   - Browse all suggestions.
   - Filter by status, category, and effort band.
   - Search by keyword and tag.

2. **/community/suggestions/new**
   - Structured submission form.
   - Required fields enforce quality and comparability.

3. **/community/suggestions/{id}**
   - Single suggestion page with timeline, rationale, and decision notes.

4. **/community/roadmap**
   - Accepted suggestions grouped by release or milestone.
   - Public signal of what is likely next.

## 5) Suggestion schema (minimum standard)

Use a consistent schema for every suggestion:

- `title` (short and specific)
- `problem` (current pain or gap)
- `proposal` (what should change)
- `scope` (services/components affected)
- `reuse_plan` (which current modules are reused)
- `alternatives_considered`
- `risks`
- `success_metrics`
- `status` (`new`, `triaged`, `in_review`, `accepted`, `planned`, `in_progress`, `done`, `rejected`)
- `owner` (maintainer or working group)
- `community_signals` (votes/comments count)

## 6) Categories for clarity

Define a fixed category set so users can find relevant proposals:

- Platform UX
- Docs and onboarding
- Tooling and automation
- Reliability and operations
- Security and governance
- Integrations (n8n, Open WebUI, AFFiNE, MinIO, etc.)

## 7) Submission quality guardrails

To reduce low-quality noise, the submission form should require:

- A concrete problem statement with at least one reproducible example.
- Explicit statement of whether existing components can be reused.
- A measurable success criterion.
- Risk callout for security, performance, and maintenance burden.

## 8) Community interaction model

Support community participation without losing maintainability:

- Lightweight voting (signal only, not automatic decision).
- Comment thread for clarifications and implementation notes.
- Maintainer pin/comment for official status updates.
- Changelog link when suggestion is implemented.

## 9) UX recommendations

- Keep the page simple and fast (server-rendered or minimal JS).
- Use readable status badges with strong contrast.
- Include clear empty states and “next best action” prompts.
- Add “related suggestions” block based on shared tags/category.

## 10) SEO and discoverability

- Human-readable URLs (`/community/suggestions/slugs`).
- Structured metadata (title, description, tags).
- Internal links from README/docs to accepted suggestions.
- Add a “community suggestions” section on the landing page.

## 11) Analytics and metrics

Track practical metrics:

- Suggestion throughput (submitted/accepted/implemented per month).
- Median time from `new` to `triaged`.
- Duplicate rate (proxy for discoverability quality).
- Community participation (votes/comments per suggestion).

## 12) Initial deliverable (MVP)

For phase 1, ship:

1. Listing page + detail page.
2. Submission endpoint with schema validation.
3. Status lifecycle display.
4. One-way sync from accepted suggestions to roadmap view.

This is enough to establish a durable, community-based loop.
