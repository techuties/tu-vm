# Implementation Roadmap

## Objective

Deliver the community suggestions in controlled phases that prioritize stability, adoption, and measurable outcomes.

## Phase 1 - Foundation (Weeks 1-2)

## Deliverables

- Establish module manifest standard (`module.yml`)
- Add community command namespace to `tu-vm.sh`
- Add `community doctor` baseline checks
- Publish contributor workflow documentation

## Exit criteria

- At least one reference module uses the manifest
- Contributors can run discovery + health checks from one command

## Phase 2 - Productivity (Weeks 3-4)

## Deliverables

- Module scaffolding tool for new contributions
- Reusable templates for common workflows
- Diagnostics and log summary helpers

## Exit criteria

- New module scaffolded in under 15 minutes
- Reduced setup steps for first-time contributors

## Phase 3 - Governance and reliability (Weeks 5-6)

## Deliverables

- Lightweight RFC process in active use
- Quality/security checklists enforced in contribution flow
- Module ownership model and support expectations

## Exit criteria

- All new module proposals include rollback and success metrics
- No unowned modules in active use

## Phase 4 - Community scaling (Weeks 7-8)

## Deliverables

- Public module registry view (status, owner, maturity)
- Community tag taxonomy and discovery enhancements
- Operational metrics dashboard for community features

## Exit criteria

- Contributors can discover reusable modules quickly
- Adoption metrics are visible and reviewed regularly

## Suggested KPIs

- Contribution lead time (proposal to merge)
- Mean time to resolve module incidents
- Number of reusable modules adopted by multiple contributors
- Frequency of operational regressions post-release
- Onboarding completion rate for first-time contributors

## Risks and mitigations

1. **Risk**: Tooling complexity increases too quickly  
   **Mitigation**: Keep initial CLI surface minimal and iterative.

2. **Risk**: Inconsistent module quality  
   **Mitigation**: Enforce required checks and owner assignment.

3. **Risk**: Resource pressure on laptop-class environments  
   **Mitigation**: Require module resource profiles and on-demand defaults.

4. **Risk**: Community fatigue due to unclear process  
   **Mitigation**: Use short RFC templates and visible decision outcomes.

## Immediate next actions

1. Approve the manifest contract and command namespace.
2. Implement `community doctor` as the first shared quality tool.
3. Pilot one community module end-to-end using the new framework.

