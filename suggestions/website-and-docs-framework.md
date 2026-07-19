# Website and Documentation Framework

## Decision

Keep the operational dashboard and the community documentation as separate surfaces:

- `nginx/html/index.html` remains the resilient, low-dependency control plane.
- Markdown in the repository remains the source for guides and curated proposal summaries.
- GitHub Issues remains the suggestion intake and discussion system.
- A static documentation framework is introduced only when navigation, search, or versioning can no longer be maintained well in the repository.

This separation avoids coupling service controls to a public content stack and avoids building a second issue tracker, voting database, or moderation API.

## Existing foundation to reuse

| Need | Existing source | Reuse rule |
|---|---|---|
| Suggestions | [Idea / suggestion issue form](../.github/ISSUE_TEMPLATE/suggestion.yml) | Link to Issues; do not create another submission API. |
| Contribution process | [`CONTRIBUTING.md`](../CONTRIBUTING.md) | Render or link it; do not fork its instructions. |
| Security reporting | [`SECURITY.md`](../SECURITY.md) | Keep private-reporting language canonical. |
| Operations content | [`docs/playbooks/README.md`](../docs/playbooks/README.md) | Split into pages only when a static site is adopted. |
| Release history | [`CHANGELOG.md`](../CHANGELOG.md) and GitHub Releases | Generate summaries or links; do not maintain parallel release notes. |
| Runtime health | helper `/status/*` and the Nginx dashboard | Never expose control endpoints through a public docs build. |
| Content quality | docs link workflow and pre-commit hooks | Extend the existing checks before adding another toolchain. |

## Framework adoption gate

Do not add a JavaScript or Python docs toolchain only to render the current small page set. Adopt a framework when at least two of these conditions are true:

1. Operators need versioned documentation for supported TU-VM releases.
2. Navigation spans enough pages that the repository index is hard to use.
3. Local full-text search becomes a repeated user request.
4. Reusable callouts, compatibility tables, or generated indexes reduce measurable maintenance work.
5. A maintainer is assigned to dependency updates and broken-build ownership.

Until then, Markdown plus GitHub rendering is the lowest-risk website publishing system.

## Framework selection

Choose one static framework after a small proof of concept; do not maintain multiple implementations.

| Option | Choose when | Strengths | Cost / guardrail |
|---|---|---|---|
| **Astro Starlight** (preferred default) | Static docs need fast builds, local search, and occasional custom components | Accessible defaults, Markdown/MDX, static output, lightweight runtime | Adds Node dependencies; pin the package manager and commit the lockfile. |
| **Docusaurus** | Versioned docs and a large plugin/community ecosystem are primary requirements | Mature versioning, navigation, localization, search integrations | Heavier client bundle and configuration; avoid if versioning is unused. |
| **MkDocs Material** | Maintainers prefer Python and almost all content stays Markdown-only | Simple authoring, strong navigation/search, broad docs adoption | Python environment becomes part of contributor setup. |
| **Next.js or another SSR app** | Authenticated, transactional community features are proven requirements | Dynamic application ecosystem | Not justified for static docs or issue summaries; requires a new runtime and security boundary. |

The proof of concept should render the same representative pages in the leading two candidates: one playbook, one suggestion status page, and one release/compatibility page. Compare build reproducibility, keyboard navigation, search, offline behavior, container image size, and maintenance surface.

## Target architecture

```text
GitHub Issues ── discussion and lifecycle ──┐
                                            ├─ curated Markdown ── static docs build
Repository docs ── operational truth ───────┘                         │
                                                                       └─ Nginx read-only route

helper API ── runtime status/control ── existing operational dashboard only
```

The static build must not require PostgreSQL, a new community API, or browser calls to GitHub. If recent issue/release data is shown, generate a cached JSON snapshot in CI with a safe empty-state fallback. Use a read-only token with the minimum repository scope, export only reviewed fields (issue number, title, public labels/status, and public URLs), exclude author email/body/comment text by default, and discard the snapshot when generation fails rather than serving stale private data.

## Operational dashboard evolution boundary

Modularizing the Nginx dashboard should not turn it into the documentation framework or a runtime plugin host. Keep its service UI data-driven and reviewable:

1. Extract existing JavaScript and CSS without changing behavior.
2. Define a small service-card registry with `id`, visible label, status endpoint, tier, visibility, supported controls, and accessible status text.
3. Validate registry service IDs and endpoints against Compose/helper inventories using the documentation drift check in [`implementation-backlog.md`](./implementation-backlog.md#p1-5-documentation-to-runtime-drift-validator).
4. Render repeated card behavior from the registry; retain explicit components for genuinely different workflows.
5. Add shared CSS tokens for contrast, focus, spacing, status text, and reduced motion before adding themes.

The registry is declarative data, not executable community code. It must not contain tokens, arbitrary URLs, inline scripts, or controls that are absent from the helper allowlist. Authentication and authorization remain enforced by the helper and Nginx boundaries, regardless of whether a control is visible.

This pattern lowers the cost of reviewed integrations without adding React, a component marketplace, or client-side extension execution to the control plane.

## Information architecture

1. **Get started** — install, architecture overview, first health check.
2. **Operate** — playbooks, backup/restore, upgrades, troubleshooting.
3. **Integrate** — supported MCP tools, extension contract, compatibility.
4. **Contribute** — contribution guide, local checks, ownership, security.
5. **Suggestions** — submit link, lifecycle, curated status, decisions, shipped outcomes.
6. **Releases** — changelog, version compatibility, migration notes.

Each page should name its canonical source and include an “Edit this page” link when publicly hosted.

## Publishing and automation

Implement automation incrementally:

1. Keep link checking scoped to the canonical suggestion pages.
2. Add a narrow markdownlint configuration for heading order, fenced code languages, and duplicate headings.
3. Validate suggestion metadata and internal links with one repository script.
4. Detect drift between active docs and Compose service IDs, helper routes, and `tu-vm.sh` commands without starting the stack.
5. Generate navigation and status indexes from metadata; fail if generated output is stale.
6. Add build and accessibility checks only when the static site exists.
7. Add browser smoke tests for navigation, search, mobile layout, and broken client-side routes.

Automation should produce actionable file-and-line errors and run through the same command locally and in CI.

## Security, privacy, and accessibility gates

- Publish only read-only project content; keep `/control/*`, tokens, allowlists, local hostnames, and operator logs out of the public build.
- Keep external analytics disabled by default. If adopted, document retention and honor opt-out; prefer no-cookie, aggregate analytics.
- Bundle or self-host assets where practical so a LAN deployment remains useful without third-party availability.
- Require semantic landmarks, ordered headings, visible focus, keyboard navigation, descriptive link text, and WCAG 2.2 AA contrast.
- Respect reduced-motion preferences and test layouts at narrow mobile widths.
- Give diagrams text alternatives; give any charts accessible summaries and non-color-only status labels.

## Implementation stages

### Stage 1 — curate without a framework

- Use the canonical path in [`README.md`](./README.md).
- Apply the page and metadata model in [`website-community-pages.md`](./website-community-pages.md).
- Remove or mark contradictory historical proposals as superseded.
- Expand existing link checks and add metadata validation.

### Stage 2 — static-site proof of concept

- Evaluate Astro Starlight and the best team-fit alternative against the same content.
- Record the decision, rejected option, dependency ownership, build command, and rollback.
- Preserve existing repository URLs or add redirects.

### Stage 3 — publish read-only community content

- Serve the static output on a separate route or host.
- Add local search, version/compatibility notes, and generated suggestion indexes.
- Keep “Submit a suggestion” as a link to the existing GitHub issue form.

### Stage 4 — validate before adding dynamic features

- Review search usage, broken-link trends, support-question repetition, and contributor feedback.
- Add dynamic capabilities only for a demonstrated problem that static generation and GitHub cannot solve.

## Acceptance criteria

Stage 1:

- A new contributor can reach the issue form, contribution checks, and current backlog from the canonical hub.
- Every published suggestion links to its issue/decision/implementation source.
- CI checks links in all canonical suggestion pages.

After metadata tooling exists:

- CI rejects invalid lifecycle metadata, duplicate IDs, and missing required evidence.

After a static site exists:

- The site builds reproducibly from a clean checkout and serves as static files.
- The docs route remains useful when helper, PostgreSQL, or the internet is unavailable.
- No privileged runtime endpoint or secret is included in generated content.
- Browser checks catch inaccessible core navigation and broken client-side routes.
