# Community Suggestions Hub

This folder contains practical, implementation-ready suggestions for improving the TechUties VM platform with a **community-first approach**.

The recommendations focus on:
- Reusing mature frameworks instead of rebuilding core capabilities
- Improving daily contributor workflows and operator experience
- Creating transparent governance so community proposals can move from idea to production

## Why this exists

To avoid reinventing the wheel, we should standardize on proven open-source patterns, then customize only where the project has unique needs.

## Current recommendation in one sentence

Use **GitHub Issues + Markdown proposal pages as the source of truth**, generate a public documentation website from those pages with a mature docs framework, and surface only lightweight community status widgets in the existing TU-VM landing dashboard.

## Suggestion map

1. [Community System Framework](./community-system-framework.md)  
   Defines how suggestions are proposed, reviewed, accepted, and implemented.

2. [Website and Documentation Framework](./website-and-docs-framework.md)  
   Recommends Docusaurus-first website structure, content ownership, accessibility, and generated suggestion pages.

3. [Day-to-Day Tooling Framework](./day-to-day-tooling.md)  
   Covers operational tooling, automation, quality gates, and contributor productivity.

4. [Website Tools and Automation](./website-tools-and-automation.md)  
   Describes validator, duplicate detection, dashboard, and release-note automation ideas.

5. [Implementation Backlog](./implementation-backlog.md)  
   Separates completed infrastructure from the next high-value work items.

## Anti-reinvention baseline

The following capabilities already exist or are represented in repository infrastructure and should be reused before proposing replacements:

- GitHub issue templates for bugs and ideas.
- Pull request checklist with security, rollback, and validation prompts.
- CI for Docker Compose rendering, shell syntax, smoke checks, and `/status/full` contract validation.
- Docs link workflow, Trivy configuration scan, Dependabot, stale workflow, Release Drafter, CODEOWNERS placeholder, and optional pre-commit hooks.
- Landing dashboard links to playbooks, changelog, releases, and community surfaces.

New suggestions should identify which of those surfaces they extend.

## Working principles

- **Community-first**: proposals are public, discussable, and traceable
- **Low-friction contribution**: templates, examples, and automation for common tasks
- **Operational reliability**: every accepted idea includes rollout and rollback guidance
- **Security and privacy by default**: preserve TU-VM's private-AI posture while expanding ecosystem value

## Suggested execution sequence

### Phase 1 (Foundation)

Done on the GitHub-native path: suggestion + PR templates, [`CONTRIBUTING.md`](../CONTRIBUTING.md), CI smoke/check-config, starter [`docs/playbooks/`](../docs/playbooks/README.md), landing links.

Still open:

- Dedicated docs site structure and navigation (Docusaurus-first; optional static site later)
- Explicit maintainer label/ownership conventions documented beside Issues
- Suggestion page frontmatter and generated status indexes

### Phase 2 (Acceleration)

- Automation for triage and stale-issue workflows (labels, bots)
- Playbook surfacing from the dashboard with clear anchors
- Lightweight adoption metrics (release cadence, time-to-close by label)
- Duplicate suggestion hints generated from existing Markdown and open issues

### Phase 3 (Scale)

- Open community working groups
- Create plugin/integration curation process
- Publish quarterly roadmap and retrospective summaries

See [`implementation-backlog.md`](./implementation-backlog.md) for the trimmed backlog and the next ten prioritized recommendations.
