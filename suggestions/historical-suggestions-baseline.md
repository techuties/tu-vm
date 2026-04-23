# Historical Suggestions Baseline

This document summarizes constructive suggestions that already exist in repository documentation, so new work can extend them instead of recreating them.

## Existing direction already documented

## 1) Community and collaboration signals

- AFFiNE is already positioned as a collaboration workspace.
- The architecture already supports operator-facing workflows via Open WebUI and n8n.
- Existing scripts (`daily-checkup`, `pre-push-check`, `rollout-gates`, `langgraph-e2e-smoke`) already enable quality gates and operational discipline.

**Implication:** website suggestions should surface and systematize these community pathways rather than inventing a brand-new platform.

## 2) Product quality and trust signals

- Security posture is already strong (token auth, TLS, rate limiting, verification layer, proof signing).
- Reliability patterns are already present (backup/restore, health endpoints, smoke checks, update rollback).
- Changelog history shows iterative improvement cycles around performance, dashboard UX, and processing reliability.

**Implication:** website should communicate these trust foundations with concrete, inspectable evidence pages (status, release notes, compatibility, governance decisions).

## 3) Operational simplification direction

- `tu-vm.sh` is the central operator interface.
- Tiered service startup is already implemented to reduce resource overhead.
- Dashboard controls already exist for start/stop and service visibility.

**Implication:** new suggestions should focus on reducing cognitive load for contributors and operators by reusing existing command and dashboard patterns.

## Gaps not yet formalized

The current docs are technically rich but do not yet define:

- A contributor lifecycle for website/community participation
- A shared intake and decision process for proposals
- A public-facing roadmap/status model for community visibility
- A lightweight framework for documenting accepted/rejected suggestions

These gaps are addressed in the companion suggestion files in this folder.
