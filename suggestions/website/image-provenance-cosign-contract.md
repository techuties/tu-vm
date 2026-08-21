---
title: Image Provenance and Cosign Verify Contract
description: Constructional contract for verifying digest-pinned Compose images with cosign or equivalent provenance, without replacing Trivy CVE scans or the safe-update pin map.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: security
impact: high
---

# Image Provenance and Cosign Verify Contract

## Problem

Compose services are already digest-pinned (`image: name@sha256:…`). That answers “which bits run” but not “who produced them.” `safe-update` / pin maps (Stage 15) bump digests. Trivy (Stage 4 / current workflow) scans **config** and may later scan image CVEs. Neither verifies a Sigstore signature or in-toto attestation.

Community PRs that notice “we pin but do not verify” tend to propose a private Harbor, pulling only from a vendor marketplace, or treating Dependabot as provenance.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `image: …@sha256:` | Content pin for most Tier 1/2 services |
| `.github/workflows/trivy.yml` | IaC/config scan; `exit-code: 0` today |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVE + optional SBOM |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin / check / rollback channels |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | Digest bump and apply/rollback |
| Stage 21 `multi-arch-image-policy-contract.md` (expected sibling) | Index digest vs arch-specific digest |

Out of scope:

- Replacing digest pins with mutable tags
- Making Trivy a signature verifier
- Requiring a private registry before public cosign keys exist
- Blocking every unsigned community image on first landing

## Proposal

Add an **opt-in verify lane** that checks signatures for digest pins we already maintain, using official `cosign` (or `docker trust` only if a pin already publishes DCT). Keep CVE scanning and pin updates as separate jobs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Verify | `scripts/verify-image-provenance.sh` | `cosign verify` / `verify-attestation` per pin |
| Inventory | Existing pin map / compose images | Reuse Stage 15 map; do not fork a second list |
| CI | Optional workflow or `workflow_dispatch` | Fail-closed only after a known-good key set exists |
| Docs | Playbook + this page | Which images have public keys vs unsigned |
| Intake | GitHub Issues | New keys and exceptions stay public |

### Rules

1. **Pins stay the source of truth.** Provenance verifies the digest already in Compose. Do not introduce a parallel “signed latest” channel.
2. **Distinct from CVE and update.** Trivy answers vulnerabilities. `safe-update` answers freshness. Cosign answers authenticity.
3. **Reuse official cosign.** Do not write a custom signature format or a TU-VM registry.
4. **Default off until keys are listed.** A failing verify job on unsigned upstreams (common for community images) would brick CI. Start with a documented allowlist of images that publish Sigstore identities.
5. **Multi-arch follows Stage 21.** Verify the **index** digest the compose file uses, not a single-arch child, unless the pin is already arch-specific.
6. **SBOM is optional evidence**, not a substitute. CycloneDX from Stage 4 may attach later; it does not replace signatures.
7. **GitHub remains intake.** Requests for Harbor or air-gap mirrors stay Issues unless they wrap this verify script.

### Suggested contributor checklist

```text
1. Collect image@sha256 lines from docker-compose.yml
2. Do not add a second pin file
3. For each image, record whether a public cosign identity exists
4. Add verify script that skips unsigned pins with an explicit reason
5. Keep Trivy and safe-update jobs unchanged
6. Fail CI only for pins on the signed allowlist
7. Never commit registry credentials
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Authenticity | Official `cosign` + existing digests | A private registry as a prerequisite |
| CVEs | Stage 4 Trivy / Grype | Treating signatures as vulnerability scans |
| Freshness | Stage 15 `safe-update` | Dependabot as provenance |
| Arch | Stage 21 multi-arch index digests | Verifying the wrong child manifest |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `scripts/verify-image-provenance.sh` that reads Compose pins and verifies the signed subset.
3. Optional: `workflow_dispatch` CI job; promote to PR gate only after the allowlist is stable.

## Acceptance criteria

- [ ] Digest pins remain the compose source of truth.
- [ ] Verify is distinct from Trivy and safe-update.
- [ ] Unsigned images are skipped with a recorded reason, not a hard fail by default.
- [ ] No private registry is required.
- [ ] Secrets are not written to the repo.

## Rollback

Remove the verify script/job. Pins, Trivy, and `safe-update` stay. Runtime images are unchanged.

## Success metrics

- Maintainers can state which pins are signature-verified.
- CI does not fail the whole stack because one unsigned upstream exists.
- CVE and update workflows are not overloaded with provenance checks.
