---
title: Supply-Chain Community Gates
description: Constructional community workflow for image CVE scanning, severity gates, and optional SBOM export using existing Trivy/Dependabot patterns.
last_updated: 2026-07-27
owner: maintainers
status: proposed
theme: security
impact: high
---

# Supply-Chain Community Gates

## Problem

The repository already runs Trivy **config** scanning on `docker-compose.yml`, Dependabot for Actions, and pins many images. Historical suggestions and the implementation backlog still ask for deeper supply-chain hygiene: **image CVE scans**, fail-on-severity once noise is triaged, and optional SBOM artifacts for regulated operators. Without a published community contract, each PR invents a different scanner story—or ignores pinned-image risk entirely.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `.github/workflows/trivy.yml` | Config scan baseline |
| `.github/dependabot.yml` | Action dependency PRs |
| Pinned images in `docker-compose.yml` | Deterministic runtime versions |
| Stage 3 `community-quality-gates.md` | Change-type → evidence matrix |
| Release Drafter + Releases | Ship channel for SBOM attachment |
| GitHub Security / code scanning UI | Native result surfacing when enabled |

Out of scope:

- Building a custom vulnerability database
- Blocking every LOW finding on day one
- Scanning operator host OS packages outside the Compose images
- Uploading SBOMs to third-party SaaS by default (LAN-first posture)

## Proposal

Publish a **supply-chain gates** website page that defines phased adoption using mature tools (Trivy or Grype—not a bespoke scanner).

### Phase A — Inventory (advisory)

1. Add a workflow (or extend Trivy) that iterates **pinned Compose images**.
2. Emit SARIF or standard Trivy/Grype output to the Actions summary.
3. Keep `exit-code: 0` while maintainers triage noise and document false positives.
4. Maintain a short allowlist/exception file only when a CVE is accepted with expiry + rationale (link Decision Log).

### Phase B — Severity gates

Once baseline noise is understood:

| Severity | Gate |
|---|---|
| CRITICAL | Fail CI on `main`/`dev` PRs that introduce or leave unfixed CRITICAL in touched images |
| HIGH | Fail after triage window; start as warn |
| MEDIUM/LOW | Report only unless explicitly escalated |

Prefer failing on **newly introduced** findings in changed images when full-gate noise is still high.

### Phase C — Optional SBOM on release

On published `v*` releases:

- Generate CycloneDX or SPDX for the Compose image set (Syft/Trivy SBOM).
- Attach the artifact to the GitHub Release.
- Document that SBOMs describe **container images**, not the operator’s entire host.

Do not require SBOM for every PR.

### Community day-to-day workflow

| Actor | Action |
|---|---|
| Contributor changing images | Run local Trivy/Grype against the new pin when possible; cite results in PR |
| Reviewer | Check workflow summary; demand Decision Log for accepted CRITICAL/HIGH exceptions |
| Maintainer | Tune severity gates; refresh exceptions with expiry dates |
| Operator | Consume Release SBOM when their compliance process needs it |

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Image CVE scan | Trivy or Grype in GitHub Actions | Homegrown CVE crawler |
| Action deps | Dependabot (already present) | Manual weekly bumps only |
| Exceptions | Time-boxed Decision Log entries | Silent forever-ignores |
| Inventory | CycloneDX/SPDX | Proprietary lock-in formats |
| Secrets | Never echo registries creds in logs | Debug dumps of pull tokens |

### Suggested workflow sketch

```yaml
# Conceptual — adapt to existing trivy.yml style
name: image-cves
on:
  pull_request:
  schedule:
    - cron: "0 6 * * 1"
jobs:
  scan-pinned-images:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Extract pinned images
        run: # parse docker-compose.yml image: lines
      - name: Trivy image scan
        # severity CRITICAL,HIGH; exit-code policy per phase
```

Exact YAML belongs in a follow-up implementation PR; this page is the community contract.

## Acceptance criteria

- [ ] Documented image list source (Compose pins) and scan command.
- [ ] Advisory workflow produces visible CI summaries.
- [ ] Severity gate policy written before fail-closed is enabled.
- [ ] Exception process requires rationale + expiry + Decision Log link.
- [ ] Optional Release SBOM steps documented; default remains opt-in until maintainers enable it.
- [ ] No third-party upload of SBOM/CVE data unless explicitly configured.

## Rollout and rollback

1. Phase A advisory on schedule + PRs that touch Compose images.
2. Phase B fail-closed for CRITICAL after triage.
3. Phase C SBOM on release.
4. Rollback = disable fail gate or workflow; keep docs as intent.

## Success signals

- Image bumps include scan evidence without maintainer prompting.
- CRITICAL findings do not linger silently on `dev`/`main`.
- Regulated operators can download an SBOM from Releases without a side channel.
