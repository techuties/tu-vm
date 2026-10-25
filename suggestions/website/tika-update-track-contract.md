---
title: Tika Update Track Contract
description: Constructional contract so tu-vm.sh update follows the Tika 3.3.1 full tag instead of apache/tika:latest, which is 4.1.0 and has no Tesseract.
last_updated: 2026-10-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika Update Track Contract

## Problem

`./tu-vm.sh update` will move Tika off the reviewed 3.3.1 line onto Tika 4.1.0.

`OFFICIAL_UPDATE_IMAGE_PAIRS` contains:

```text
tika|apache/tika:latest|apache/tika
```

For a pinned service, `update_system` pulls that source tag and, when `RepoDigests` differs from the Compose `image:` line, rewrites the pin in `docker-compose.yml`.

Checked on 2026-10-25 against Docker Hub, without starting a container:

| Fact | Value |
|---|---|
| Tag | `apache/tika:latest` |
| Index digest | `sha256:fe2c6e3fca77b986ff3368107a20fa5060a3eefd03d14c12b45c0334626335d2` |
| Image created | 2026-10-21 |
| `TIKA_VERSION` | `4.1.0` |
| Package install in the linux/amd64 history | `openjdk-25-jre-headless` and `ca-certificates` |

That history does not install `tesseract-ocr`. The Compose pin today is the 3.3.1 index `sha256:90b7fa1dc018434075fce9e1d9b88b1e3d0ea6979d0cf86e116c79a8073ae973`. Those digests differ, so the next update rewrites the file.

Stage 58 (open PR #84) says the service should pin official `apache/tika:3.3.1.0-full` (`sha256:d8e6ed96260ad89307a93195a1b856102987a818ac648502f8efbaf313d32470`), because that 3.3.1 image is the one that installs Tesseract. Tracking `:latest` replaces either the current pin or that full pin with 4.1.0, and the 4.1.0 history above is still the minimal JRE image. The processor, `tika-config.xml`, and the Stage 58 `timeoutSeconds` property are written for 3.3.1.

`apache/tika:latest` is a floating tag. A later update can move the pin again without a reviewed diff. The community update path is already `./tu-vm.sh update`. It needs a tag that stays on the line Stage 58 names.

Checked by reading `OFFICIAL_UPDATE_IMAGE_PAIRS` and the registry config history for `apache/tika:latest`. The token used for the manifest was not stored.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` `OFFICIAL_UPDATE_IMAGE_PAIRS` | The one line to change for `tika` |
| `update_system` pull-and-rewrite | Keep this mechanism. Change the tag it pulls |
| Compose `tika` `image:` | The pin the rewrite compares |
| Stage 58 OCR runtime (open PR #84) | Names `3.3.1.0-full` and `timeoutSeconds`. This page does not edit the XML |
| Stage 44 image compare (open PR #70) | How the daily checkup compares digests. This page does not change that script |
| Stage 26 n8n-mcp pin (open PR #52) | Floating-tag policy for a different image |

Out of scope:

- Editing `tika-config.xml` or the processor timeout headers
- A TU-VM Dockerfile that installs Tesseract
- Pulling images during this docs change
- Retargeting every other pair in `OFFICIAL_UPDATE_IMAGE_PAIRS`
- Adding Watchtower, Diun, or a second updater

## Proposal

Point the Tika pair at the 3.3.1 full tag Stage 58 already selected.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Pair | `OFFICIAL_UPDATE_IMAGE_PAIRS` | Replace `apache/tika:latest` with `apache/tika:3.3.1.0-full` |
| Pin | Compose, when Stage 58 is implemented | Keep the full-image digest. Re-check it in that PR |
| Guard | `update_system` | If the pulled digest's config env `TIKA_VERSION` is not `3.3.1`, skip the rewrite and warn. Do not write a 4.x digest into Compose |
| Proof | `docker image inspect` after a deliberate pull | `TIKA_VERSION=3.3.1` and the history contains `tesseract-ocr` |

The pair stays a single string. The rewrite logic can stay. Only the tag and the version guard change.

### Rules

1. **Track `3.3.1.0-full`.** `apache/tika:latest` on 2026-10-25 is 4.1.0.
2. **Refuse a major jump inside `update_system`.** A 4.x pin is a reviewed PR, not a digest rewrite.
3. **Keep Stage 58's XML and image pin.** This page does not choose a different OCR property.
4. **Leave the checkup compare on Stage 44.** The daily report and the update rewrite should name the same tag once Stage 44 reads Compose. Until then, this pair is the update side only.
5. **Do not add an updater container.** `./tu-vm.sh update` remains the command.

### Suggested contributor checklist

```text
1. Confirm the tika pair source tag is apache/tika:3.3.1.0-full
2. Confirm apache/tika:latest is not in OFFICIAL_UPDATE_IMAGE_PAIRS
3. Confirm a pulled config with TIKA_VERSION other than 3.3.1 does not rewrite Compose
4. Confirm the image chosen by the pair lists tesseract-ocr in its history
5. Confirm tika-config.xml is unchanged by this PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tika line | `apache/tika:3.3.1.0-full` | `apache/tika:latest` |
| Applying updates | Existing `update_system` rewrite | A second update daemon |
| OCR capability | Stage 58 full image | The 4.1.0 minimal history |
| Major upgrades | A reviewed Compose PR | An automatic digest replace |
| Intake | GitHub Issue | A forked Tika image |
