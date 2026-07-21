# Constructive Community Website Roadmap

**Status:** focused proposals after historical review
**Last reviewed:** 2026-07-21
**Scope:** community content that can be published on a future documentation website without changing the operational dashboard into a social platform

## Historical review and boundaries

TU-VM already has the foundations that these proposals should reuse:

- GitHub Issue forms and pull requests provide suggestion intake, discussion, reactions, identity, moderation, and implementation links.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) defines the contributor path.
- [`CHANGELOG.md`](../CHANGELOG.md) and GitHub Releases record shipped work.
- [`docs/playbooks/`](../docs/playbooks/README.md) contains operator-facing recipes.
- [`helper/chat-context/`](../helper/chat-context/) contains context files that can seed Open WebUI.
- `n8n`, MCP Gateway, AFFiNE, MinIO, Qdrant, and Tika already provide useful integration surfaces.
- The Nginx landing page is a local control plane and should remain small, dependable, and usable without an internet connection.

The repository also contains many overlapping website, governance, voting, and tooling proposals. This roadmap does not propose:

- a second suggestion database;
- dashboard authentication for public participation;
- a local voting or reputation system;
- a custom discussion service;
- another generic documentation-framework comparison.

Those capabilities would duplicate GitHub, add personal-data and moderation responsibilities, and couple community traffic to a private operator surface. The website should publish a curated, read-only view and direct participation to the existing GitHub workflow.

## Proposal 1: Community knowledge-pack commons

### Knowledge-pack problem

The files in `helper/chat-context/` provide useful n8n and AFFiNE knowledge, and `scripts/seed-chat-context.sh` copies them into the Open WebUI uploads volume. There is no documented contract for community authors to add or update these assets. Reviewers currently have no standard way to answer:

- Which TU-VM and upstream versions does a pack support?
- Where did its source material come from?
- Does it contain secrets, private URLs, unsafe instructions, or unlicensed content?
- How can a reviewer test retrieval quality and safely remove the pack?

### Existing knowledge-pack systems to reuse

- Keep `helper/chat-context/` as the version-controlled source.
- Keep `scripts/seed-chat-context.sh` as the installation path until a manifest is proven necessary.
- Use pull requests for review and Git history for attribution.
- Use the future static docs website only as a catalog and contributor guide.
- Use MinIO/Open WebUI as runtime consumers; do not create another content store.

### Knowledge-pack website experience

Publish a **Knowledge Packs** section with:

1. A catalog page listing title, purpose, domain, language, maintainer, compatibility, source license, and validation status.
2. A contribution guide that explains sanitization, source attribution, test evidence, and update expectations.
3. A pack detail page generated from repository metadata, with installation and removal commands.
4. A visible security note that packs are community-reviewed context, not executable tools or trusted system instructions.

The first catalog should describe the three existing assets before accepting new ones:

- `n8n_workflow_examples.json`
- `assistant_context_affine_n8n.txt`
- `assistant_context_affine_deep_dive.txt`

### Minimal metadata contract

Start with metadata in the catalog source rather than one sidecar file per asset. Split into per-pack manifests only when independent versioning or automation justifies the extra files.

Required fields:

- stable ID and human-readable title;
- summary and intended audience;
- source paths and content format;
- upstream products and tested versions;
- language and approximate size;
- maintainer or owning team;
- source URLs, licenses, and attribution;
- security review date;
- validation command or review checklist;
- deprecation or replacement link.

### Review and safety gates

- Reject credentials, tokens, personal information, internal hostnames, and production examples.
- Require provenance for copied or generated material.
- Treat instructions that trigger tools, writes, downloads, or network access as security-sensitive.
- Validate JSON syntax and text encoding automatically.
- Review large context additions for retrieval noise and prompt-injection language.
- Require a clean seed into an isolated test volume and verify that removal restores the previous state.
- Never fetch community pack content at runtime; releases must contain the reviewed version.

### Knowledge-pack rollout and rollback

1. Inventory and document the existing three assets.
2. Add the catalog page and contribution checklist.
3. Pilot one community update to an existing pack.
4. Add warning-only metadata validation after the format stabilizes.
5. Enforce required fields only for active packs.

Rollback is documentation-first: remove a catalog entry, revert the pack commit, rerun the seed command, and document whether previously copied files need explicit deletion. Existing installations must continue to work when website publishing is unavailable.

### Knowledge-pack acceptance criteria

- Every active pack has ownership, provenance, compatibility, and validation information.
- A contributor can update a pack using only the documented GitHub workflow.
- CI detects malformed JSON and missing required catalog metadata.
- A reviewer can install, inspect, and remove a pack without touching unrelated Open WebUI data.
- No pack requires an external request during normal TU-VM operation.

## Proposal 2: Curated integration and recipe catalog

### Integration catalog problem

Integration knowledge is spread across the root README, Compose configuration, scripts, model context, and upstream documentation. Contributors can easily create a second setup path that conflicts with existing service names, security controls, or health checks.

### Existing integration systems to reuse

- Use Docker Compose service definitions as the runtime inventory.
- Link to current `tu-vm.sh` commands rather than duplicating shell logic.
- Reuse helper health endpoints and existing smoke scripts as evidence.
- Treat [`extensions-and-integration-framework.md`](./extensions-and-integration-framework.md) as the future package contract, not a prerequisite for publishing useful recipes.
- Use GitHub Issues and pull requests for submissions and review.

### Integration catalog website experience

Publish an **Integrations and Recipes** catalog with filters for:

- capability: automation, storage, retrieval, observability, or tool access;
- runtime tier and resource profile;
- bundled, optional, experimental, or external status;
- data access: none, read-only, write, or administrative;
- outbound network requirement;
- tested TU-VM release.

Each detail page should contain:

- the operator problem solved;
- supported topology and dependencies;
- required configuration names without secret values;
- exact enable, health-check, smoke-test, disable, and rollback commands;
- data locations and backup implications;
- inbound and outbound network behavior;
- known incompatibilities;
- maintainer, last validation date, and evidence link.

Start with bundled integrations: Open WebUI, n8n, MinIO, Qdrant, Tika, AFFiNE, MCP Gateway, LangGraph Supervisor, and Browserless. A bundled entry documents reality; it does not imply that the extension framework has shipped.

### Submission and review rubric

Score each recipe on:

1. Reuse of existing TU-VM commands and services.
2. Operator value and reproducible use case.
3. Least-privilege data and network access.
4. Validation quality, including expected success and failure output.
5. Upgrade and rollback clarity.
6. Maintenance ownership and upstream health.

Do not accept catalog entries that require privileged containers, host Docker socket access, unpinned remote scripts, plaintext secrets, or undocumented outbound telemetry unless maintainers explicitly approve and label the risk.

### Integration catalog rollout and rollback

1. Generate an inventory of bundled services from Compose.
2. Manually publish three reference entries representing read-only, write-capable, and external-network integrations.
3. Review the format with operators and first-time contributors.
4. Add warning-only drift checks between catalog service IDs and Compose.
5. Consider extension manifests only after at least one external integration needs lifecycle automation.

The catalog is non-authoritative for execution. If publishing breaks, operators continue to use `README.md`, `tu-vm.sh`, and playbooks. Removing a bad recipe must not change running services.

### Integration catalog acceptance criteria

- Every bundled catalog entry links to real commands and a current health check.
- Security and data-flow fields are visible before setup instructions.
- A first-time contributor can validate a recipe without guessing service names.
- Catalog CI reports stale Compose service references.
- No catalog page can directly execute operator controls.

## Proposal 3: Privacy-first community and release digest

### Release-digest problem

Static release and changelog links exist, but operators cannot see concise project highlights from the LAN dashboard without leaving TU-VM. Calling GitHub from each private installation would leak operator activity and introduce an availability dependency.

### Existing release systems to reuse

- Use GitHub Releases and `CHANGELOG.md` as the editorial sources.
- Use Release Drafter labels and linked issues for community attribution.
- Reuse the existing landing-page "What is new" area and its static fallback links.
- Serve generated content from Nginx or the helper API on the same origin.

### Proposed publishing path

Generate a small, versioned JSON document during a trusted release or documentation build. It should include:

- release name and publication date;
- up to three short operator-relevant highlights;
- links to local documentation where possible;
- community issue or contributor attribution when public;
- schema version and generation timestamp.

Ship the generated file with TU-VM. The dashboard reads only that local artifact. It must not call GitHub, analytics services, CDNs, or a project-controlled tracking endpoint from an operator installation.

### Content and accessibility rules

- Keep highlights factual and under a fixed length.
- Do not include avatars, tracking images, or third-party embeds.
- Render links with descriptive text and preserve keyboard navigation.
- Announce content updates without stealing focus.
- Display the artifact timestamp and retain the current static links as fallback.
- Do not expose private issue text, email addresses, or contributor data beyond public attribution already present in the release.

### Release-digest rollout and rollback

1. Define and validate the JSON schema.
2. Generate a fixture from the current `CHANGELOG.md`.
3. Render it in a static test page or dashboard fixture.
4. Add the same-origin read path behind a feature flag.
5. Enable it by default only after offline and malformed-data tests pass.

Rollback disables the panel or removes the artifact; existing release and changelog links remain available.

### Release-digest acceptance criteria

- Browser network inspection shows no third-party request from the digest.
- Missing, stale, or malformed JSON degrades to the static links.
- The digest is readable with keyboard and screen-reader navigation.
- Release highlights are generated once and remain deterministic for a release.
- At least one shipped item links back to public community contribution evidence when available.

## Suggested sequence

1. Knowledge-pack inventory and contributor contract.
2. Three bundled integration catalog entries.
3. Local release-digest schema and fixture.
4. Warning-only catalog drift checks.
5. Website publication after the documentation framework passes the adoption gates in [`website-and-docs-framework.md`](./website-and-docs-framework.md).

## Shared success signals

- Fewer duplicated integration and setup proposals.
- Every published asset has an owner, validation date, and rollback path.
- Community contributions can be reviewed without a maintainer reconstructing provenance or security impact.
- Website publication adds no mandatory external telemetry or runtime dependency.
- Operational guidance remains usable when GitHub and the documentation website are unavailable.
