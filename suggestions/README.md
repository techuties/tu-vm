# Community Suggestions Hub

This folder captures **constructive, implementation-ready suggestions** for evolving TechUties VM into a stronger community-driven platform without duplicating what already exists.

## Why this exists

The project already has major strengths:
- Tiered service architecture and dashboard controls
- Strong security posture (secure/public/locked modes)
- Daily health checks and smart announcements
- Rich document pipeline (Tika + MinIO + Open WebUI sync)

These suggestion files focus on **what to build next** by extending those foundations.

## Historical signals used (to avoid reinventing)

The suggestions in this folder directly build on:
- `CHANGELOG.md` "Future Enhancements" notes:
  - Quick Action Profiles
  - Battery status integration
  - Auto-stop for inactive services
  - Resource usage history
  - Smart startup optimization
- Existing architecture and controls documented in `README.md`
- Existing operational surfaces in `tu-vm.sh`, helper API, dashboard, and monitoring stack

## Suggestion map

- `01_website-information-architecture.md`  
  Website structure and content model for a community-first docs + portal experience.

- `02_community-framework-and-governance.md`  
  Contribution framework, decision model, and release workflow for community ownership.

- `03_developer-experience-and-tooling.md`  
  Practical tools that improve day-to-day contributor velocity and consistency.

- `04_feature-roadmap-from-historical-suggestions.md`  
  Concrete implementation roadmap that extends historical suggestions already listed in changelog notes.

## Working principles for all suggestions

1. Reuse existing components first (helper API, dashboard, scripts, docker-compose services).
2. Prefer modular additions over deep rewrites.
3. Keep self-hostable defaults and LAN-first safety posture.
4. Design for maintainability by a distributed contributor community.
