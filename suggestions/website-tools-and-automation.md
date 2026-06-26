# Website Suggestions: Tools and Automation for Daily Operations

## Problem statement

As community participation grows, maintainers can lose time to repetitive work:

- Reviewing similar suggestions repeatedly.
- Keeping Markdown pages and links consistent.
- Explaining the same process expectations to new contributors.
- Communicating proposal status across issues, PRs, docs, and releases.
- Tracking which ideas moved from discussion to implementation.

Without lightweight tooling, community participation creates friction instead of leverage.

## Proposed solution

Implement a practical maintainer acceleration layer around the website and suggestion process.

The layer should use tools the project already understands:

- Markdown files in `suggestions/`.
- GitHub Issues, Discussions, PRs, labels, and release notes.
- Small scripts in `scripts/`.
- Static JSON generated at build or CI time.
- Optional read-only dashboard widgets after the data model is stable.

Avoid building a custom suggestion platform until the simpler path fails on a concrete requirement.

## Guiding principle

Favor small automations with immediate value over large one-time platform rewrites.

## Tooling suggestions

### 1) Suggestion quality validator

#### Goal

Ensure every active suggestion is actionable, comparable, and easy to review.

#### Recommended checks

- Required frontmatter fields:
  - `title`
  - `status`
  - `area`
  - `owner`
  - `related`
- Allowed status values only.
- Required sections:
  - Problem statement
  - Historical overlap
  - Existing solutions scan
  - Proposed solution
  - Risks and mitigations
  - Rollout and rollback
  - Acceptance criteria
  - Success metrics
- Internal links resolve.
- No new active suggestion is missing a related-history reference.

#### Implementation direction

- Add a Python script that scans `suggestions/` and emits human-readable text plus optional JSON.
- Start as a warning-only report.
- Make only precise checks blocking in CI, such as invalid status values or broken local links.
- Reuse the style of existing validation scripts rather than introducing a large docs toolchain first.

#### Suggested command shape

```bash
python3 scripts/validate-suggestions.py --path suggestions
python3 scripts/validate-suggestions.py --path suggestions --json
```

### 2) Duplicate and overlap detection

#### Goal

Avoid reinventing features that were already discussed.

#### Approach

Start with deterministic local matching:

1. Extract titles, headings, tags, and required summary sections.
2. Normalize words and remove common stop words.
3. Score overlap by shared keywords and phrase matches.
4. Print the top related suggestions when a file is new or changed.

Example output:

```text
Potentially related suggestions:
- suggestions/website-community-framework.md (governance, roles, review)
- suggestions/community-system-framework.md (status, lifecycle, metadata)
- suggestions/implementation-backlog.md (open roadmap item)
```

#### TU-VM fit

- Can run entirely with Python standard library at first.
- Can produce JSON for a future website index.
- Can later use Qdrant/embeddings if historical content becomes too large for keyword matching.

### 3) Generated suggestion index

#### Goal

Make proposal status visible without manually editing index pages after every change.

#### Output

Generate:

- `suggestions-index.json` for website/dashboard consumption.
- Markdown or HTML index grouped by:
  - status
  - area
  - owner
  - last reviewed date
  - related historical files

#### Suggested fields

```json
{
  "title": "Website and Documentation Framework",
  "status": "review",
  "area": "website",
  "owner": "unassigned",
  "source": "suggestions/website-and-docs-framework.md",
  "related": ["historical-patterns-from-project.md"]
}
```

Keep the generated output out of hand-edited source docs unless the project explicitly wants committed build artifacts.

### 4) Decision transparency dashboard

#### Goal

Make community decisions visible without maintainers writing manual status posts.

#### Recommended dashboard modules

- Pipeline counts by status.
- Recently accepted suggestions.
- Implemented suggestions in the latest release.
- Suggestions missing owner or review date.
- Top requested themes: security, UX, automation, docs, integrations.

#### Technical options

1. Static website page generated from Markdown metadata.
2. Static JSON rendered into the existing landing page.
3. Helper API endpoint for dynamic stats if maintainers want live data.

Keep dashboard widgets read-only until authorization and moderation boundaries are explicitly designed.

### 5) Contributor onboarding tools

#### Goal

Lower first-contribution friction.

#### Practical additions

- First suggestion template with examples.
- Good suggestion checklist.
- "How to avoid duplicates" guide.
- "How decisions are made" guide.
- "What gets prioritized" guide.
- Path map from topic to code owner area:
  - dashboard UI -> `nginx/html/index.html`, `helper/uploader.py`
  - service orchestration -> `docker-compose.yml`, `tu-vm.sh`
  - docs and website -> `README.md`, `docs/`, `suggestions/`
  - document processing -> `tika-minio-processor/`

### 6) AI-assisted maintainer workflows

#### Goal

Use existing private-AI capabilities to reduce repetitive review work while keeping humans in control.

#### Suggested helpers

- Suggestion summarizer:
  - short summary
  - impacted components
  - likely area labels
  - missing required sections
- Risk highlighter:
  - network exposure
  - auth/control path impact
  - data retention or backup impact
  - new dependency risk
- Merge candidate detector:
  - related historical suggestions
  - overlapping acceptance criteria
  - proposed consolidation target

#### Governance note

AI output is advisory. Human maintainers record final labels, status, and decision rationale.

### 7) Operational response templates

Standardize recurring community communication:

- Accepted with scope.
- Needs revision.
- Rejected with rationale.
- Deferred with trigger for reconsideration.
- Merged with existing suggestion.
- Implemented and released.

Templates reduce inconsistency while still allowing maintainers to add human context.

### 8) Release-note integration

#### Goal

Connect delivered work back to community suggestions automatically.

#### Suggested practice

- Each accepted suggestion receives a stable ID or file slug.
- PRs reference the suggestion file or issue.
- Changelog entries include delivered community suggestions when relevant.
- Release notes link back to accepted/implemented suggestion pages.

#### Benefit

Community members can trace:

```text
idea -> discussion -> decision -> implementation -> release
```

## Suggested lightweight automation stack

1. Markdown link checks.
2. Suggestion structure validator.
3. Duplicate/overlap report.
4. Generated suggestion index JSON.
5. Website page generated from the index.
6. Read-only dashboard widget.
7. Optional semantic search after keyword matching is insufficient.

## Risks and mitigations

### Risk: automation noise

Too many warnings can discourage contributors.

Mitigation:

- Keep checks focused on high-value structure issues.
- Make subjective findings advisory.
- Document every blocking rule in plain language.

### Risk: over-engineering early

Advanced tooling before contributor volume justifies it can become maintenance debt.

Mitigation:

- Start with scripts and static outputs.
- Add dynamic services only after a stable data model exists.
- Prefer GitHub-native workflows for discussion and decisions.

### Risk: opaque moderation

Trust drops if tools auto-score proposals without explanation.

Mitigation:

- Show why a duplicate or risk was flagged.
- Require human decision rationale for accepted, rejected, and superseded statuses.
- Keep historical files searchable.

### Risk: dashboard/control boundary confusion

Community widgets on the operator dashboard could be mistaken for service controls.

Mitigation:

- Make suggestion widgets read-only.
- Visually separate community status from service control panels.
- Keep moderation actions in GitHub or the docs workflow unless a permission model is designed.

## Success metrics

- Fewer duplicate suggestion submissions.
- Higher share of suggestions with complete required sections on first review.
- More implemented suggestions linked to release notes.
- Lower review churn from missing validation or rollback notes.
- Faster routing of proposals to the right domain reviewers.

## Recommended first implementation sequence

1. Add or normalize suggestion metadata and required sections in canonical files.
2. Add a validator for status values, required sections, and internal links.
3. Add duplicate hinting against existing `suggestions/` files.
4. Generate a static suggestion index.
5. Publish the index through the selected website framework.
6. Add a read-only landing dashboard summary if the generated data proves useful.

