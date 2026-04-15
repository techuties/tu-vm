# Historical Suggestions Baseline (Do Not Duplicate)

This file captures suggestion-like items already present in the project docs and changelog so future proposals can start from known context.

## Already Implemented (baseline capabilities)

These are no longer "new suggestions" and should be referenced rather than re-proposed:

- Tiered service architecture (Tier 1 always-on + Tier 2 on-demand)
- Dashboard service start/stop controls and status indicators
- Daily health checks and pre-push operational checks
- Safe update workflow with backup/rollback flow
- MCP Gateway diagnostics and workflow validation guidance
- LangGraph verification + audit trail pattern for write operations
- Changelog refresh helper script (`scripts/changelog-refresh.sh`)

## Historical Backlog Items (from prior project notes)

The changelog includes a "future enhancements" backlog that can be formalized into community proposals:

1. Quick action profiles (e.g., Work Mode / AI Mode / Energy Save)
2. Battery status integration into dashboard visibility
3. Auto-stop for inactive services (optional idle timeout)
4. Resource usage history and charting
5. Smart startup optimization shortcuts
6. Auto-starting service dependencies only when needed
7. Usage analytics and recommendation engine for service operations
8. Additional mobile dashboard optimization

## Current Gaps Identified

From current docs, these process-level gaps remain:

- No dedicated contributor-facing suggestion intake framework
- No structured scoring model for selecting suggestions
- No canonical decision log linking "suggestion -> implementation -> release note"
- No public community page model for roadmap transparency

## Rule for New Suggestions

Before creating a new suggestion:

1. Check this file for overlap.
2. Check `CHANGELOG.md` for implemented or planned equivalents.
3. If overlap exists, create an "extension proposal" instead of a duplicate proposal.
