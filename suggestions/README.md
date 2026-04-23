# Suggestions Hub

This folder documents **constructive, implementation-ready suggestions** for the TU-VM website and community ecosystem.

It is designed to prevent duplicate effort by:

1. Capturing ideas already present in current project docs and changelog notes.
2. Translating those ideas into clear website/product suggestions.
3. Proposing reusable frameworks and tooling for day-to-day community operations.

## How to use these files

- Start with `historical-suggestions-baseline.md` to understand what has already been proposed or partially implemented.
- Review `website-community-framework.md` for the website architecture and feature model.
- Review `website-tooling-and-operations.md` for contributor workflows and automation tooling.
- Use `website-roadmap.md` to prioritize implementation steps by impact and technical dependency.

## Scope

These suggestions focus on:

- Community-based contribution and governance patterns
- Website information architecture and UX
- Practical tools that make ongoing maintenance easier
- Reusing existing TU-VM building blocks (Open WebUI, n8n, MCP Gateway, LangGraph Supervisor, dashboard helper API)

## Change management guidance

When implementing a suggestion:

1. Reuse existing scripts/services where possible.
2. Keep security defaults aligned with current TU-VM posture (token auth, least privilege, rate limiting).
3. Prefer small, reversible changes with clear rollback paths.
4. Update changelog notes when suggestions are shipped.
