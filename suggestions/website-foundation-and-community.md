# Website Foundation and Community Model (Suggestion)

## Why this suggestion exists

The repository already has a strong operational dashboard (`nginx/html/index.html`), reliable service controls, and clear security boundaries.  
The next step is to make the website easier to evolve by contributors without replacing proven architecture.

This proposal focuses on:

1. preserving the current operational UX,
2. adding a contribution-friendly website layer,
3. and defining governance that keeps quality/security high.

## What to keep (avoid re-inventing)

Use existing strengths as permanent foundation:

- **Current dashboard as control plane**: keep `nginx/html/index.html` for service operations.
- **Existing status/control APIs**: continue using `/status/*`, `/control/*`, `/whitelist/*`.
- **Tier model messaging**: Tier 1/Tier 2 is already a clear mental model in docs and UI.
- **Operational scripts**: keep `tu-vm.sh` and `scripts/*` as canonical maintenance path.

## Proposed website architecture

### 1) Split website concerns into two lanes

- **Lane A: Operations UI (existing)**
  - Current dashboard remains minimal, fast, and production-safe.
  - Changes here require stricter review due to operational impact.

- **Lane B: Community content site (new build output)**
  - Docs, tutorials, release highlights, contribution guides.
  - Generated from Markdown and published as static files under Nginx.

### 2) Framework recommendation

Use **Astro** for the community content site.

Why Astro fits this repo:

- Markdown-first workflow (good for community contributions)
- Static output (easy to host with existing Nginx setup)
- Fast build and low runtime complexity
- Component option when interactive pages are needed

Alternative if team wants docs-first only: **MkDocs Material**.

## Community contribution framework

### Suggestion lifecycle

Define a lightweight, repeatable path:

1. **Idea submission** (suggestion template)
2. **Triage** (owner labels as `accepted`, `needs-info`, or `rejected`)
3. **Design note** (short Markdown proposal with impact/risk)
4. **Implementation PR**
5. **Post-release note** (link to changelog entry)

### Roles

- **Maintainers**: approve operationally sensitive changes.
- **Community contributors**: docs, UX improvements, tutorial content, non-sensitive UI work.
- **Ops reviewers**: validate security and service-control behavior for dashboard changes.

### Decision rules (small but clear)

- Any change touching `/control/*` behavior requires 2 approvals.
- Any documentation-only change can merge with 1 maintainer approval.
- Suggestion is considered complete only when acceptance criteria are satisfied in PR text.

## Recommended folder model for website evolution

Keep structure explicit:

```text
nginx/html/                 # Existing operational dashboard
website/                    # Astro or MkDocs source (community-facing content)
website/content/            # Markdown docs/tutorials/releases
website/components/         # Optional UI components
website/public/             # Static assets
```

## Guardrails for sustainable growth

- Keep runtime dependencies low (prefer static content over JS-heavy patterns).
- Add clear ownership per website area.
- Avoid duplicate documentation by linking to canonical docs (`README.md`, `QUICK_REFERENCE.md`).
- Require each new page to include:
  - purpose,
  - intended audience,
  - maintenance owner,
  - last validation date.

## Near-term implementation slices

### Slice 1 (low risk)

- Create website content skeleton.
- Add contributor guide and suggestion template.
- Publish static pages via Nginx.

### Slice 2 (medium risk)

- Add navigation/search.
- Add release highlights pages sourced from `CHANGELOG.md`.

### Slice 3 (higher impact)

- Add authenticated operator docs or advanced runbooks.
- Introduce community voting/feedback if moderation process is ready.

## Acceptance criteria for this foundation

- Community can submit suggestions without editing operational code.
- Website content updates are Markdown-first and reviewable in PR diff.
- Dashboard operational behavior remains unchanged unless explicitly targeted.
- Maintainers can trace each shipped website change back to a suggestion.
