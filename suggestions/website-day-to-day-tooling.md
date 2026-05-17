# Website Suggestions - Day-to-Day Tooling for Community Operations

## Objective
Reduce maintainer overhead by automating repetitive tasks around suggestions, triage, releases, and communication.

## Tooling Recommendations

## 1) Suggestion templates and schema checks
- Enforce a structured suggestion template.
- Add CI validation for required sections (problem, impact, success criteria, effort).
- Reject malformed submissions early.

Recommended implementation:

- Use markdown frontmatter for repository-backed suggestion pages.
- Validate frontmatter with a small script or existing markdown tooling before adding custom services.
- Keep the GitHub Issue template aligned with the markdown template so ideas can move from issue to website page without rewriting.

## 2) Auto-triage assistant
- Rule-based tagging on submission:
  - docs, UI, infra, security, performance, automation
- Duplicate detection using title/keyword similarity.
- Route high-risk suggestions (security/runtime controls) to maintainers first.

Recommended implementation:

- Start with GitHub labels and Actions-based validation.
- Use keyword matching against `suggestions/*.md`, issue titles, and accepted roadmap items.
- Keep duplicate detection advisory until maintainers trust the signal.

## 3) Prioritization helper
- Daily/weekly job calculates priority scores from:
  - vote count
  - age
  - severity/impact
  - estimated implementation size
- Output top-N queue for planning meetings.

Recommended implementation:

- Store the formula in a versioned config file so the community can review changes.
- Use GitHub reactions/comments as the first demand signal.
- Include risk and resource impact so popularity does not override security or operational safety.

## 4) Changelog synchronizer
- When suggestion status changes to `Completed`, prompt maintainers to:
  - attach implementation reference (commit/tag)
  - add changelog entry
  - link back from suggestion page

## 5) Notification automation
- Broadcast changes to community channels when:
  - suggestions accepted
  - status moved to in-progress
  - completed and released
- Keep notification digest mode to prevent spam.

Recommended implementation:

- Use Release Drafter and GitHub release notes as the primary source.
- Add website "community wins" or changelog highlights from release data once link stability is proven.
- Prefer digest summaries over per-event notifications.

## 6) Contributor productivity toolkit
- `make` or script shortcuts for:
  - local docs preview
  - markdown lint checks
  - suggestion schema validation
  - local API/dev server startup
- Include one-command bootstrap for new contributors.

Recommended implementation:

- Expose common flows through existing scripts or `tu-vm.sh` aliases.
- Use `pre-commit` for local whitespace, merge-conflict, YAML, and shell syntax checks.
- Add markdownlint or an equivalent narrow rule set for `docs/`, root policy files, and canonical suggestions.
- Add Playwright only for core website/dashboard flows where browser behavior matters.

## 7) Quality and accessibility checks for website pages
- Automated checks for:
  - broken links
  - heading hierarchy
  - color contrast failures
  - keyboard navigation basics
  - ARIA landmarks on key pages

Recommended implementation:

- Keep link checking in GitHub Actions and reuse existing docs-link workflow patterns.
- Add a small accessibility smoke suite for community pages once a static site exists.
- Require meaningful link text and stable anchors for playbook/dashboard deep links.

## Mature tools to prefer

| Need | Suggested mature tool/path | Why |
|------|----------------------------|-----|
| Static docs website | Docusaurus, MkDocs Material, or Astro/Starlight | Markdown-first, contributor-friendly, well maintained |
| Link checks | Existing docs-links workflow / Lychee-style checker | Avoids broken navigation as suggestions grow |
| Markdown style | markdownlint with a narrow repo-specific rule set | Keeps pages readable without blocking useful content |
| Local checks | pre-commit plus existing scripts | Fast feedback before PRs |
| Release linkage | Release Drafter + `CHANGELOG.md` | Keeps shipped suggestions traceable |
| Dependency upkeep | Dependabot for GitHub Actions and package manifests | Reduces maintainer toil |
| Browser confidence | Playwright smoke tests | Verifies real website/dashboard interactions |
| Security visibility | Trivy/Grype/SBOM exports where appropriate | Fits the platform's private-AI and operator-safety posture |

## Suggested Implementation Sequence
1. Template + schema validation
2. Auto-tagging and duplicate checks
3. Priority score generator
4. Changelog sync reminders
5. Notification digests

## Risks and Mitigations
- **Risk:** automation noise  
  **Mitigation:** start in suggestion mode (non-blocking), then enforce once stable.

- **Risk:** inaccurate duplicate detection  
  **Mitigation:** keep human override and merge suggestions manually.

- **Risk:** maintainer trust in scoring  
  **Mitigation:** make formula visible and editable in config.

## Definition of Done for Tooling Rollout
- New suggestions are consistently structured.
- Triage time decreases measurably.
- Completed items reliably appear in changelog/release communication.
- Contributors can onboard and contribute with minimal manual guidance.
