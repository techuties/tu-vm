# Website Community Governance Suggestions

## Objective

Create a predictable, transparent, and low-friction process for community suggestions so contributors know:

- where to submit ideas,
- how ideas are evaluated,
- what quality criteria apply,
- and why decisions are made.

This process should be simple enough for day-to-day use but robust enough to maintain technical quality.

---

## 1) Suggestion lifecycle (single source of truth)

Use the machine-readable statuses defined in
[`website-community-pages.md`](./website-community-pages.md):

1. **Intake** — `submitted`, then `triaged`.
2. **Evaluation** — `discussing`, `needs-rework`, or `deferred`.
3. **Delivery** — `accepted`, `in-progress`, then `implemented`.
4. **Closed history** — `rejected`, `superseded`, or `withdrawn`.

Measurement is an action recorded on an `implemented` suggestion, not a
separate status. “Accepted with constraints” is an `accepted` decision whose
constraints are written in the decision section.

### Why this helps

- Prevents good ideas from being lost.
- Reduces duplicate effort.
- Creates a learnable process for new contributors.

---

## 2) Suggestion quality bar

Require each proposal to include:

1. **Problem statement**
   - What specific user/developer pain is being solved?
2. **Current behavior**
   - What happens today and where?
3. **Proposed change**
   - What exactly should be added/changed?
4. **Reuse strategy**
   - Which existing TU-VM component(s) can handle this?
5. **Operational impact**
   - Complexity, maintenance burden, and security considerations.
6. **Success criteria**
   - Measurable outcomes after rollout.

### Fast rejection criteria

Reject or return for rework if suggestion:

- duplicates existing functionality without clear improvement,
- requires major complexity without measurable benefit,
- bypasses existing security guardrails without justification,
- conflicts with architecture direction (unless it explicitly proposes a direction change with trade-offs).

---

## 3) Roles and responsibilities

### Community Contributor
- Submits suggestion with required template.
- Participates in discussion and clarifies requirements.

### Triage Maintainer
- Classifies scope and component ownership.
- De-duplicates against existing suggestions and known roadmap items.
- Moves suggestion into discussion or decision.

### Technical Maintainer
- Assesses architectural fit and risk.
- Verifies implementation feasibility.
- Defines acceptance criteria for execution.

### Release Maintainer
- Ensures accepted suggestions are traceable to releases/changelog.
- Monitors post-release outcomes.

---

## 4) Decision model

Use explicit decision outcomes that map directly to lifecycle values:

- **`accepted`**: scoped and approved for implementation. Record any
  architecture, security, or performance constraints in the rationale.
- **`needs-rework`**: promising but incomplete or mis-scoped.
- **`deferred`**: valid but blocked by a named re-open condition.
- **`rejected`**: out of scope, duplicate, too risky, or low impact.
- **`superseded`**: replaced by a linked proposal.

Every decision should include:

1. A one-line decision summary.
2. Reasoning (2-5 bullets).
3. Next steps (if applicable).

This avoids ambiguous “maybe later” outcomes.

---

## 5) Community communication standards

When responding to suggestions:

- acknowledge the problem before debating implementation details,
- provide concrete alternatives when rejecting,
- avoid vague statements like “not aligned” without evidence,
- link to relevant docs/architecture constraints.

### Suggested response template

1. **Decision**: Accepted / Needs rework / Rejected
2. **Reason**: Short rationale tied to architecture and impact
3. **What would make it acceptable** (if rework)
4. **Next checkpoint**: where this is tracked and reviewed

---

## 6) Governance metrics (monthly review)

Track governance health with a small KPI set:

- Number of new suggestions
- Triage time (submission to first maintainer response)
- Decision time (submission to final decision)
- Acceptance rate
- Implementation completion rate for accepted items
- Post-implementation satisfaction signal (feedback/reopen rate)

### Warning signals

- Rising decision latency
- Low implementation rate of accepted suggestions
- Frequent post-implementation reversals
- High duplicate suggestion volume

These indicate process friction or unclear documentation.

---

## 7) Integration with TU-VM operations

Leverage existing assets without expanding the control plane:

- Use the **Nginx landing page** as the entry point for community guidance.
- Publish suggestion summaries and states as generated static files under
  `/docs/`.
- Use existing Issue, PR, Release Drafter, and changelog links to publish
  accepted and shipped updates.
- Keep the helper API limited to its operational status/control purpose; the
  website must not require helper credentials or a suggestion endpoint.

Keep governance lightweight: start with Markdown records and deterministic
static views, then add automation only when measured volume justifies it.

---

## 8) Suggested first implementation steps

1. Publish the canonical lifecycle and template in the website **Contribute**
   section.
2. Add a visible generated suggestion status page.
3. Trial the lifecycle on a small batch of real proposals with a named
   maintainer review cadence.
4. Adjust criteria and response targets from observed submission volume.

This creates a practical feedback loop without overengineering.

