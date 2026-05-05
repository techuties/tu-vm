# Suggestion 01: Website Platform Framework (Do Not Reinvent)

## Goal

Create a maintainable website/docs layer for TU-VM that:

- uses a proven framework,
- is friendly for community contributions,
- fits the current Docker + Nginx deployment model, and
- can be adopted incrementally without breaking existing workflows.

## Current baseline in this repository

- Existing landing/service hub page: `nginx/html/index.html`
- Existing long-form docs: `README.md`, `QUICK_REFERENCE.md`, `CHANGELOG.md`
- Runtime architecture already organized and documented in detail

This means TU-VM already has content and structure; the missing piece is a dedicated docs website framework for scaling community knowledge.

## Recommendation

Adopt **VitePress** as the docs website framework, with Markdown as source of truth.

### Why VitePress (vs building custom docs pages)

1. **Markdown-native** and fast
   - Reuses existing contributor skills.
   - Keeps contribution barrier low.
2. **Static output**
   - Works well with existing Nginx static serving model.
   - No extra backend service is required.
3. **Good default UX**
   - Built-in search integration options, sidebar/nav, code blocks, dark mode.
4. **Low operational overhead**
   - Fewer moving parts than a custom docs app.
   - Simple CI build/deploy path.

## Framework comparison (high-level)

| Option | Strengths | Trade-offs | Fit for TU-VM |
|---|---|---|---|
| VitePress | Fast, markdown-first, simple static deploy | Smaller plugin ecosystem than Docusaurus | **Strong fit** |
| Docusaurus | Very rich ecosystem, versioning features | Heavier setup/runtime complexity | Good fit, but more overhead |
| MkDocs Material | Great docs UX, mature | Python-based toolchain split from current JS/web stack | Moderate fit |
| Custom HTML/CSS/JS | Full control | High maintenance, reinvents solved problems | Weak fit |

## Proposed information architecture

1. **Getting Started**
   - Quickstart, prerequisites, first boot checks.
2. **Operations**
   - Start/stop, tier model, secure/public/lock modes, update/rollback.
3. **Architecture**
   - Service map, data flow, MCP Gateway, LangGraph Supervisor.
4. **Workflows & Automation**
   - n8n engineering patterns, workflow diagnostics, tool references.
5. **Community Suggestions**
   - Curated proposals and accepted improvements (this folder can seed it).

## Suggested technical layout

```text
docs/
  index.md
  getting-started/
  operations/
  architecture/
  workflows/
  suggestions/
```

Generated static site can be deployed into a path served by Nginx (for example `/docs`), while retaining `nginx/html/index.html` as the operational service dashboard.

## Community-focused features to enable

- "Edit this page" links to reduce friction for first contributions.
- Contribution guide for docs style, section naming, and review expectations.
- Labels for proposal maturity: `draft`, `trial`, `accepted`, `deprecated`.
- Cross-linking from dashboard UI docs to backend scripts and compose services.

## Risks and mitigations

1. **Risk: docs drift from implementation**
   - Mitigation: docs update checklist in PR template.
2. **Risk: too much migration at once**
   - Mitigation: migrate docs in phases; keep existing Markdown files valid.
3. **Risk: framework lock-in concerns**
   - Mitigation: keep content in plain Markdown with minimal custom syntax.

## Concrete next actions

1. Choose framework officially (proposed: VitePress).
2. Scaffold docs site in a dedicated `docs/` directory.
3. Migrate `QUICK_REFERENCE.md` first (lowest risk/high value).
4. Link docs site from the landing page and root `README.md`.
5. Add contribution rules and review checklist for docs PRs.
