---
title: RAG Knowledge Contribution Contract
description: Community path for contributing private knowledge corpora through MinIO, Tika, Qdrant, and Open WebUI—reusing the existing document intelligence plane instead of a new CMS.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: community
impact: high
---

# RAG Knowledge Contribution Contract

## Problem

Community members want to share runbooks, architecture notes, and curated datasets with local RAG (Open WebUI + Qdrant) without uploading private data to third-party doc hosts. Historical suggestions reinvent “knowledge bases” or external wikis. TU-VM already has MinIO, Tika, the MinIO processor, Qdrant, and Open WebUI—the missing piece is a **website contract** for how community knowledge packs are shaped, reviewed, and installed.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| MinIO + `setup-minio` / rclone mounts | Object storage for corpora |
| `tika` + `tika_minio_processor` | Document extraction pipeline |
| Qdrant | Vector index |
| Open WebUI | Operator-facing chat + RAG |
| Knowledge packs proposal (PR #24) | Adjacent reusable content direction |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Parallel catalog pattern for tools |
| Stage 6 `n8n-workflow-catalog.md` (expected sibling) | Parallel catalog pattern for workflows |
| Stage 6 `airgap-docs-mirror.md` (expected sibling) | Offline docs distribution |
| Stage 3 `extension-pilot-contract.md` (expected sibling) | Packaging shape when Compose is required |
| [`SECURITY.md`](../../SECURITY.md) / Stage 8 secret hygiene | Keep credentials out of corpora |

Out of scope:

- Building a multi-tenant cloud CMS inside Nginx
- Automatic sync of private corpora to public GitHub
- Replacing AFFiNE/Open WebUI with a new editor product
- Training or fine-tuning foundation models as a prerequisite for docs RAG

## Proposal

Define a **knowledge pack** contribution lane parallel to MCP and n8n catalogs.

### Pack shape (suggested)

```text
knowledge-packs/<id>/
  manifest.yaml          # id, title, license, sources, privacy_class
  README.md              # install notes, expected buckets, Open WebUI tips
  documents/             # optional sample docs safe for public git
  scripts/install.sh     # optional: mc/rclone helpers calling existing tools
```

### Privacy classes

| Class | Meaning | Allowed in public git? |
|---|---|---|
| `public` | Intentionally shareable samples | Yes |
| `operator-local` | Installed from operator’s own files | No—document process only |
| `restricted` | Regulated or personal data | No—never solicit uploads to Issues |

### Rules

1. **Reuse the pipeline.** Packs target MinIO buckets → Tika processor → Qdrant collections → Open WebUI knowledge config; do not invent a second ingest daemon.
2. **Manifest required.** `id`, license, privacy_class, and expected bucket/collection names are mandatory.
3. **No secrets in packs.** Tokens, `.env`, and customer documents must not appear in PRs.
4. **License clarity.** Each pack states redistribution terms for sample docs.
5. **Idempotent install.** Re-running install must not duplicate destructively without an explicit flag.
6. **Air-gap friendly.** Prefer packs that work with Stage 6 docs mirror / local file copy.
7. **GitHub remains intake.** Proposals and reviews stay on Issues/PRs; the website publishes the catalog view.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Storage | MinIO | Parallel S3-compatible sidecars per pack |
| Parsing | Tika processor | Per-format one-off Python in each pack |
| Vectors | Qdrant | Embedding SaaS that phones home by default |
| UX | Open WebUI knowledge features | Custom chat UI for docs |
| Catalog pattern | MCP / n8n catalog lessons | Unstructured folder dumps |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Align with PR #24 knowledge-pack ideas; do not fork a second layout if #24 merges first—extend it.
3. Add `knowledge-packs/README.md` only when the first public sample pack lands.
4. Optional later: `scripts/validate-knowledge-pack.sh` mirroring Stage 4 extension validation.

## Acceptance criteria

- [ ] Website describes pack layout, privacy classes, and reuse of MinIO/Tika/Qdrant/Open WebUI.
- [ ] Public sample packs (when added) contain only `public` class documents.
- [ ] Install path documents how to keep `operator-local` data off GitHub.
- [ ] Catalog pattern references MCP/n8n siblings instead of inventing unrelated metadata.
- [ ] No requirement for cloud accounts to use a pack on a LAN install.

## Rollback

Remove sample packs and validators without touching core Compose services. Operators delete MinIO prefixes/collections created by a pack using documented cleanup steps.

## Success metrics

- Community runbooks are installable as packs rather than pasted into chat.
- Fewer requests for an external hosted wiki for private ops knowledge.
- Clear rejection path when PRs include restricted documents.
