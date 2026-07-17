# Website and Documentation Framework

## Status

**Proposed.** This is the canonical framework recommendation. Older website
files in this folder remain useful research, but their framework choices should
not be treated as separate decisions.

## Goal

Publish the existing Markdown as a searchable community website without adding
a CMS, a second source of truth, or another always-on service.

The website should:

- preserve the current Nginx landing page as the operator dashboard;
- make installation, operations, security, and contribution guidance easy to
  browse;
- expose the suggestion lifecycle and its decision history;
- build to static files that work without public internet access; and
- let contributors use ordinary Markdown pull requests.

## Current repository assets to reuse

| Existing asset | Website role |
|---|---|
| `nginx/html/index.html` | Operational landing page and link to `/docs/` |
| `README.md` and `QUICK_REFERENCE.md` | Getting-started source material |
| `docs/playbooks/README.md` | Initial operations collection |
| `suggestions/*.md` | Proposal history and curated website content |
| `CONTRIBUTING.md` | Submission, labels, review, and release linkage |
| GitHub Issue Forms | Public suggestion intake; no custom intake API |
| `lychee.toml` and docs-links workflow | Existing link-quality gate |
| Nginx | Static delivery under `/docs/`; no new runtime container |

## Framework recommendation

Adopt **MkDocs Material** for the first production spike.

Why it fits this repository:

1. It produces static HTML, so the deployed system adds no application server,
   database, or new exposed port.
2. The repository already has maintained Python components and Python checks;
   this avoids introducing a second JavaScript application solely for docs.
3. Navigation, local search, code annotations, accessible color schemes, and
   responsive layouts are available as established features.
4. Content stays portable Markdown. Framework-specific syntax should be
   optional so a future migration remains mechanical.

### Alternatives and selection rule

| Framework | Choose when | Why it is not the default now |
|---|---|---|
| MkDocs Material | Documentation and community knowledge are the main product | Recommended |
| Astro + Starlight | The project needs a broader marketing site with custom components | Adds a Node build and more frontend surface |
| Docusaurus | Multi-version product docs are required immediately | Versioning and plugin surface are unnecessary initially |
| VitePress | The maintainers standardize on Vue/Vite elsewhere | No existing Vue toolchain in this repository |
| Custom HTML/JS | Never for the documentation corpus | Reimplements navigation, search, accessibility, and build tooling |

Before committing to the framework, run a disposable spike against the real
playbooks and ten representative suggestion files. Accept MkDocs only if local
search, deep links, mobile navigation, and a clean static Nginx deployment all
work without modifying source content.

## Publishing architecture

```text
GitHub Issue Form ──discussion/triage──> curated suggestions/*.md
                                              │
Existing docs + curated suggestions ──static build and checks──> site/
                                                                │
                                                         Nginx /docs/
```

- GitHub Issues remain the intake and conversation system.
- Markdown records accepted context, decisions, and implementation evidence.
- Generated indexes are build artifacts, not hand-maintained copies.
- `site/` should be ignored by Git and rebuilt in CI or release packaging.
- The browser receives static assets only; suggestion publishing must not grant
  Docker-control or helper-API privileges.

## Proposed information architecture

1. **Get Started** — prerequisites, secure setup, first boot, and verification.
2. **Operate** — service controls, status, backup, recovery, and playbooks.
3. **Architecture** — service map, trust boundaries, storage, and data flows.
4. **Security** — LAN-first defaults, secrets, allowlists, and reporting.
5. **Community** — contribution path, review standards, governance, and support.
6. **Suggestions** — submit, status board, decisions, implemented ideas, and
   archive.

The landing dashboard should link to these sections but should not duplicate
their long-form content.

## Content ownership and source-of-truth rules

- Operational facts belong beside the implementation or in playbooks.
- Suggestion discussion belongs in its GitHub Issue.
- A curated suggestion page records the stable proposal, decision, and outcome.
- Release behavior belongs in `CHANGELOG.md` and release notes; an implemented
  suggestion links there instead of copying the release narrative.
- Every page has one canonical URL. Redirect moved pages rather than publishing
  aliases.
- Generated pages include a visible source link and build revision.

## Delivery stages

### Stage A: representative spike

- Build the homepage, one playbook, and representative active, rejected, and
  implemented suggestions.
- Verify offline search, anchor links, keyboard navigation, mobile layout, and
  Nginx subpath behavior.
- Record the framework decision and rejected alternatives.

### Stage B: minimum useful site

- Publish Get Started, Operate, Community, and Suggestions navigation.
- Add the community page set from
  [`website-community-pages.md`](./website-community-pages.md).
- Link `/docs/` from the existing dashboard and root README.
- Keep the current Markdown locations until migration value is proven.

### Stage C: quality gates

- Extend the existing Lychee job to all published Markdown.
- Add Markdown style and frontmatter-schema checks.
- Build the site in CI with warnings treated as errors.
- Run a browser smoke test for navigation, search, and missing assets.

### Stage D: sustainable operations

- Generate status and recently-updated views from metadata.
- Add versioned docs only when two supported TU-VM release lines differ.
- Review stale and orphaned pages as part of the existing triage cadence.

## Security, privacy, and accessibility guardrails

- Use local search by default; do not send queries or operator browsing data to
  a hosted search service.
- Pin build dependencies and scan the generated site for unexpected external
  scripts.
- Do not render unsanitized Issue comments or remote HTML.
- Preserve LAN-only deployment and the existing Nginx control allowlist.
- Meet WCAG 2.2 AA basics: keyboard access, visible focus, semantic headings,
  sufficient contrast, descriptive links, reduced-motion support, and
  non-color status labels.

## Acceptance criteria

- A clean checkout can build the site with one documented command.
- Nginx serves the generated site at `/docs/` with no new runtime service.
- Existing dashboard and control routes behave unchanged.
- Search works with the network disconnected.
- Every published suggestion shows status, owner, last review date, source
  Issue, related proposals, and decision or next action.
- CI rejects broken internal links, invalid frontmatter, and failed site builds.
- A contributor can preview a changed page using the same tool versions as CI.
- Rollback consists of restoring the previous static artifact and dashboard
  link; no data migration is required.

## Related suggestions

- [Website community pages](./website-community-pages.md)
- [Website day-to-day tooling](./website-day-to-day-tooling.md)
- [Website community governance](./website-community-governance.md)
- [Implementation backlog](./implementation-backlog.md)
