# Website Tooling and Operations Suggestions

This proposal focuses on practical frameworks and tools that make day-to-day community operations easier while matching TU-VM’s current architecture.

## Design principles

1. **Do not duplicate systems** already present in TU-VM.
2. **Automate repetitive governance tasks** (triage, status updates, reminders).
3. **Keep all write paths auditable** and guarded.
4. **Expose public progress** with minimal manual overhead.

## Recommended framework stack

## 1) Suggestions as structured records

Use a structured schema for each website/community suggestion:

- `id`
- `title`
- `status` (Proposed, Triaged, Planned, In Progress, Shipped, Declined)
- `category` (docs, UX, security, automation, performance, integrations)
- `summary`
- `impact`
- `implementation_notes`
- `evidence_links` (commits/changelog/checks)
- `owner`
- `last_updated`

This can be represented in markdown frontmatter or JSON/YAML files, then rendered on the website.

## 2) n8n workflow automations for community operations

Implement small workflows to reduce manual work:

1. **Suggestion Intake Workflow**
   - Trigger: new suggestion file/submission
   - Actions: validate required fields, assign default category/status, notify maintainers
2. **Status Drift Workflow**
   - Trigger: scheduled run
   - Actions: detect stale suggestions (no update in N days), notify owner/reviewer
3. **Shipment Evidence Workflow**
   - Trigger: suggestion moved to Shipped
   - Actions: verify changelog entry and linked implementation evidence

## 3) Guarded automation via MCP Gateway + LangGraph Supervisor

For automated write actions:

- Route mutable operations through existing supervised patterns.
- Require explicit “confirm” flags for sensitive status transitions if needed.
- Log all automated transitions with trace IDs for auditability.

This keeps the community system aligned with TU-VM’s security model.

## 4) Website publishing workflow

Use a simple publish pipeline:

1. Validate suggestion metadata/schema
2. Build suggestion index pages
3. Publish with timestamp + source revision
4. Expose a “last synced” indicator on Suggestions and Roadmap pages

## 5) Contributor experience tooling

Add low-friction operational aids:

- Suggestion templates for common categories
- “First-good-suggestion” labels/tags for newcomers
- A checklist bot/workflow that comments missing fields/evidence
- Weekly digest generation (new, progressed, shipped, blocked suggestions)

## Implementation constraints and anti-patterns

Avoid:

- Introducing a separate proposal tracker disconnected from repo history
- Allowing status changes without rationale/evidence
- Adding heavyweight infrastructure for simple workflows

Prefer:

- Reusing existing scripts and containerized services
- Incremental rollout with clear rollback steps
- Documentation updates coupled to shipped changes

## Operational KPIs

Track lightweight health metrics for the community system:

- Time from Proposed to Triaged
- Percentage of suggestions with full metadata
- Percentage of Shipped suggestions with linked evidence
- Number of stale suggestions older than threshold
- Community contribution ratio (non-maintainer initiated suggestions)
