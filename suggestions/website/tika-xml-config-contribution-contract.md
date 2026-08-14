---
title: Tika XML Config Contribution Contract
description: Constructional contract for community changes to tika-config/tika-config.xml so parsers, OCR, and timeouts stay in the existing Apache Tika service instead of a second extractor.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika XML Config Contribution Contract

## Problem

Apache Tika is the document-extraction engine for Open WebUI and `tika_minio_processor`. The service already mounts a custom file:

```text
./tika-config/tika-config.xml:/tika-config/tika-config.xml:ro
```

and starts with `--config /tika-config/tika-config.xml`. Today that file only raises `taskTimeoutMillis` and OCR `timeout` to 900000 ms (15 minutes) for large PDFs. Community PRs that need a new parser, a mime-type deny, or a smaller timeout tend to either fork the Tika image or add another extractor sidecar.

Stage 10 describes the **document pipeline** (Tika + MinIO + processor). Stage 13/14 cover PDF day-2 ops and the Tika/PyMuPDF loader switch. Contributors still need an **XML contribution contract** so parser and timeout changes stay reviewable, energy-aware, and LAN-first.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika-config/tika-config.xml` | Checked-in Tika properties (timeouts only today) |
| `docker-compose.yml` `tika` | `apache/tika` digest, `--config`, `JAVA_TOOL_OPTIONS` heap |
| `tika_minio_processor` | Watches MinIO and calls Tika |
| Open WebUI `TIKA_SERVER_URL` | `http://ai_tika:9998` |
| CHANGELOG 2.3.0 | Documents the 5 → 15 minute timeout change |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Pipeline ops, not XML schema |
| Stage 13 `pdf-operator-day2-contract.md` (expected sibling) | `pdf-logs` / test / reset toolkit |
| Stage 14 `pdf-loader-switch-day2-contract.md` (expected sibling) | Tika vs PyMuPDF toggle |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | Heap (`-Xmx1536m`) is a budget, not an XML knob |

Out of scope:

- Replacing Tika with Unstructured, Docling, or a hosted OCR API as a merge prerequisite
- Baking a one-off `tika-config.xml` into a custom image instead of the bind mount
- Raising heap or timeout without an energy/disk note
- Changing `CONTENT_EXTRACTION_ENGINE` defaults without the Stage 14 loader contract

## Proposal

Treat `tika-config/tika-config.xml` as the **community contribution surface** for extraction behavior.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Timeouts | `<server><params><taskTimeoutMillis>` and `<ocr><timeout>` | Keep them equal; document why |
| Parser enable/disable | Tika `<parsers>` / `<parser-exclude>` | Cite the mime type and a sample file |
| OCR | `<ocr>` only | Do not add a second OCR container |
| Mime deny | Tika detector / parser exclude | Prefer deny of dangerous or huge types over a new service |
| Heap | `JAVA_TOOL_OPTIONS` in Compose | Same PR as XML if timeout and heap must move together |

### Rules

1. **One extractor.** Keep Apache Tika as the default engine. New extractors are Issues, not silent Compose sidecars.
2. **Edit the bind-mounted XML.** Do not copy a private config into the image layer.
3. **Keep timeouts paired.** `taskTimeoutMillis` and OCR `timeout` must stay aligned so OCR does not outlive the task.
4. **State energy cost.** Longer timeouts and larger heaps hold CPU/RAM on laptops. Call that out in the PR.
5. **Do not weaken LAN-first defaults.** XML must not enable remote fetch of untrusted URLs beyond what the processor already does.
6. **Sample evidence.** Parser or mime changes include a small fixture (or a pointer to an existing PDF test) and `./tu-vm.sh` PDF status/logs notes.
7. **GitHub remains intake.** Requests for a hosted OCR product stay Issues unless accepted as scoped work.

### Suggested contributor checklist

```text
1. Read tika-config/tika-config.xml and the tika service block
2. Change only the XML keys required for the mime/timeout/parser need
3. Keep taskTimeoutMillis and ocr.timeout equal
4. If heap must change, edit JAVA_TOOL_OPTIONS in the same PR
5. Note energy impact (longer OCR holds 0.5–1.5G)
6. Exercise an existing PDF test or pdf-logs after processor + Tika are up
7. Do not add a second extractor image
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Extraction behavior | Tika XML + existing image digest | Custom Tika fork |
| Pipeline wiring | Existing MinIO processor + Open WebUI URL | A second watch/loop service |
| Day-2 ops | Stage 13 PDF toolkit | Ad-hoc `docker exec` runbooks only in chat |
| Loader choice | Stage 14 Tika / PyMuPDF switch | Shipping both as always-on Tier 1 |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: a short comment block in `tika-config.xml` listing allowed keys and the paired-timeout rule.
3. Optional CI: fail if the XML is not well-formed (`xmllint --noout`).

## Acceptance criteria

- [ ] Single-extractor rule is stated.
- [ ] Bind-mounted XML is the contribution surface.
- [ ] Paired timeout rule is mandatory.
- [ ] Energy/heap coupling is documented.
- [ ] Second extractor images are out of scope for community PRs.

## Rollback

Revert the XML and Compose heap independently. A well-formedness check can be removed without changing running Tika. Do not lower timeouts below the CHANGELOG 2.3.0 15-minute baseline without a migration note.

## Success metrics

- Parser/timeout PRs edit `tika-config.xml` instead of adding sidecars.
- Task and OCR timeouts stay equal in-tree.
- PDF pipeline playbooks keep working after community XML changes.
