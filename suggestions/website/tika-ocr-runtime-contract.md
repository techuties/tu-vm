---
title: Tika OCR Runtime Contract
description: Constructional contract so scanned documents are read by Tesseract in the official Tika full image, with timeoutSeconds under the task cap the server already loads.
last_updated: 2026-10-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika OCR Runtime Contract

## Problem

The document pipeline asks Tika to OCR, and the pinned server cannot.

`docker-compose.yml` pins:

```text
apache/tika@sha256:90b7fa1dc018434075fce9e1d9b88b1e3d0ea6979d0cf86e116c79a8073ae973
```

That digest is the multi-arch index fetched on 2026-10-18. The linux/amd64 config history for that index records `TIKA_VERSION=3.3.1` and one `apt-get install` of `openjdk-21-jre-headless` and `ca-certificates`. The history does not install `tesseract-ocr`. The image was created 2026-05-27.

The same registry tag `3.3.1.0-full` has index digest `sha256:d8e6ed96260ad89307a93195a1b856102987a818ac648502f8efbaf313d32470`, created the same day, with the same `TIKA_VERSION=3.3.1`. Its linux/amd64 history installs `tesseract-ocr` and the language packs `eng`, `ita`, `fra`, `spa`, `deu`, and `jpn`. That is the official full image line. It is not a TU-VM Dockerfile.

`tika-config/tika-config.xml` is mounted and passed as `--config`:

```xml
<server>
  <params>
    <taskTimeoutMillis>900000</taskTimeoutMillis>
  </params>
</server>
<ocr>
  <timeout>900000</timeout>
</ocr>
```

Tika 3.3.1 `TikaServerConfig.load` calls `configure("server", ...)`. `ConfigBase.configure` applies only the child whose name is `server`. The `<ocr>` sibling is skipped. `TesseractOCRConfig` in that tag has `timeoutSeconds = 120` and `setTimeoutSeconds`. It has no `setTimeout`. `TesseractOCRParser` waits `config.getTimeoutSeconds() * 1000` milliseconds for the tesseract process.

So the file does two different things:

| XML | Tika 3.3.1 result |
|---|---|
| `<taskTimeoutMillis>900000</taskTimeoutMillis>` | Server task cap of 15 minutes. This one is live. |
| `<ocr><timeout>900000</timeout>` | Not applied. Tesseract's own wait stays 120 seconds, and only if a `tesseract` binary exists. |

The processor still escalates short PDFs to OCR. `PDF_ENABLE_OCR` and `IMAGE_ENABLE_OCR` are `true`. `_process_with_tika` sends `X-Tika-PDFOcrStrategy: ocr_and_text_extraction` on the OCR stage. On the minimal image that strategy has no Tesseract to run. The stage can still return a short body, which the processor stores as "OCR was attempted."

Checked on 2026-10-18 from the image config history and from tag `3.3.1` of `apache/tika` (`TikaServerConfig.java`, `ConfigBase.java`, `TesseractOCRConfig.java`, `TesseractOCRParser.java`). No container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika` service image pin | Minimal 3.3.1 image today |
| `apache/tika:3.3.1.0-full` | Official image that already installs Tesseract for this version |
| `tika-config/tika-config.xml` | File to keep. Fix the OCR property inside it |
| `TesseractOCRParser` params | Documented place for `timeoutSeconds` |
| Processor `X-Tika-PDFOcrStrategy` | Client signal to keep once the server can honor it |
| Stage 19 XML contribution (open PR #45) | One XML file, no second extractor, no forked image |
| Stage 50 client budget (open PR #76) | Processor waits versus `taskTimeoutMillis`. Leave those Compose numbers to that page |
| Stage 48 readiness probe (open PR #74) | Health probe. It leaves this XML file alone |

Out of scope:

- A custom Tika Dockerfile or `apt-get install tesseract` in `tu-vm.sh`
- A second OCR container, or a hosted OCR API
- Changing `TIKA_TIMEOUT_OCR_SECONDS` or `X-Tika-Timeout-Millis` math (Stage 50)
- Raising `taskTimeoutMillis` above 900000 in this change
- Parser excludes, mime denies, or a new heap setting

## Proposal

Pin the official full image for Tika 3.3.1, and set the OCR wait with the property that image's server reads.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Image | `tika` `image:` | Pin index `sha256:d8e6ed96260ad89307a93195a1b856102987a818ac648502f8efbaf313d32470` (`3.3.1.0-full`). Re-check the digest in the PR description. Do not use a floating `latest-full` tag |
| XML | `tika-config.xml` | Remove `<ocr><timeout>`. Set `timeoutSeconds` on `org.apache.tika.parser.ocr.TesseractOCRParser` |
| Pairing | Same file | Keep `timeoutSeconds` at or below 900, so the process wait stays inside `taskTimeoutMillis` of 900000 ms. 120 is the upstream default and is a safe first value |
| Proof | `docker exec ai_tika tesseract --version` | Prints a Tesseract version after the pin change |
| Client | Processor OCR header | Keep `X-Tika-PDFOcrStrategy` on the OCR stage. The metadata PUT in the same function does not send that header today; add it there only when `use_ocr` is true |

Parser params shape the 3.3.1 loader already understands:

```xml
<properties>
  <parsers>
    <parser class="org.apache.tika.parser.DefaultParser">
      <parser-exclude class="org.apache.tika.parser.ocr.TesseractOCRParser"/>
    </parser>
    <parser class="org.apache.tika.parser.ocr.TesseractOCRParser">
      <params>
        <timeoutSeconds>120</timeoutSeconds>
      </params>
    </parser>
  </parsers>
  <server>
    <params>
      <taskTimeoutMillis>900000</taskTimeoutMillis>
    </params>
  </server>
</properties>
```

The `parser-exclude` keeps the service loader from also constructing `TesseractOCRParser` with the 120-second default beside the configured one. Keep the existing `<server>` block if a smaller diff is easier. The required deletion is the unused `<ocr>` element. The required addition is `timeoutSeconds` on that parser class.

### Rules

1. **Use the official full image.** The Dockerfile that installs `tesseract-ocr` is Apache's. TU-VM only changes the pin.
2. **Name `timeoutSeconds`.** `<ocr><timeout>` is not a setter on Tika 3.3.1.
3. **Stay inside the task cap.** `timeoutSeconds` times 1000 must be less than or equal to `taskTimeoutMillis`.
4. **Leave the client budget to Stage 50.** Do not edit `TIKA_TIMEOUT_*` here.
5. **Do not add a second extractor.** Stage 19 still holds: one Tika service, one XML file.

### Suggested contributor checklist

```text
1. Confirm the new pin's image history contains tesseract-ocr
2. Confirm tika-config.xml has timeoutSeconds and no ocr/timeout element
3. Confirm timeoutSeconds * 1000 <= taskTimeoutMillis
4. Inside the running full image, tesseract --version exits 0
5. A scanned PDF still goes through the existing processor OCR stage
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tesseract | `apache/tika:3.3.1.0-full` | A project Dockerfile that apt-installs OCR |
| OCR wait | `TesseractOCRParser` `timeoutSeconds` | A new timeout element name |
| Task cap | Existing `taskTimeoutMillis` | A second server config file |
| Intake | GitHub Issue + this XML | A hosted OCR product |
