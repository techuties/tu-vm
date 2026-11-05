---
title: PDF Test Working Directory Contract
description: Constructional contract so tu-vm.sh pdf-test uploads the file it generated and keeps the project log in the project directory.
last_updated: 2026-11-05
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# PDF Test Working Directory Contract

## Problem

`test_pdf_processing` builds a sample at `/tmp/test.pdf`, then, when `pdflatex` is on `PATH`, runs this:

```bash
cd /tmp && pdflatex test.tex >/dev/null 2>&1 && mv test.pdf "$test_pdf" || {
    warn "PDF generation failed, using simple test file"
    echo "Test PDF content" > "$test_pdf"
}
```

`test_pdf` is `/tmp/test.pdf`. `pdflatex` writes `test.pdf` in the current directory. After `cd /tmp`, that path and `$test_pdf` are the same file.

GNU `mv` 9.4 exits 1 and prints `are the same file`. The `&&` chain fails. The `||` branch runs and replaces the generated PDF with the line `Test PDF content`. The upload that follows sends that text, with a `.pdf` name, into `tika-pipe`.

The `cd` is not in a subshell. `main` has already `cd`'d to the project, and `LOG_FILE` is the relative path `tu-vm.log`. After this line, `info`, `warn`, and `error` append to `/tmp/tu-vm.log`. The project file stops at whatever was written before the `cd`.

`pdflatex` is not installed on this machine, so the `if ! command -v pdflatex` branch is the one a local `pdf-test` would take. That branch does not `cd`. The defect is the other branch, replayed here with the same operators.

Replayed on 2026-11-05 with Bash 5.2.21 and GNU `mv` 9.4. A file was placed where `pdflatex` writes `test.pdf`. The repository was not used as the working directory. `/tmp/tu-vm.log` from the replay was removed. `./tu-vm.sh pdf-test` was not run. `.env` was not created.

| Step | Result |
|---|---|
| `cd /tmp && false` in the current shell | Working directory stays `/tmp` (`false` stands in for a failed `pdflatex`) |
| Append to relative `tu-vm.log` after that `cd` | The line is in `/tmp/tu-vm.log`. The directory that was current before the `cd` keeps only the earlier line |
| `mv test.pdf /tmp/test.pdf` when both names are that file | Exit 1, `are the same file`. The bytes stay until the next command |
| Same `mv` in the `cmd && mv \|\| { echo fallback > dest; }` shape | The fallback runs and the file contents become `Test PDF content` |

`log()` has no other path. It always appends to `$LOG_FILE`. A subshell around the `cd` leaves that variable pointed at the project log.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `test_pdf_processing` | The `pdf-test` command |
| `pdflatex` | Optional generator already in the branch |
| Plain-text fallback | Already used when `pdflatex` is missing or the generator fails |
| `LOG_FILE=tu-vm.log` | Project log, relative to the directory `main` selected |
| `run_minio_mc` / the `mc cp` in this function | Upload of `/tmp/test.pdf` |
| Stage 54 `pdf-cli-probe-contract.md` (open PR #80) | MinIO password on this upload |

Out of scope:

- Installing a TeX distribution in the image
- The MinIO password (Stage 54)
- Changing `log()` for every command
- The processor's OCR settings

## Proposal

Run `pdflatex` in a subshell so the project directory stays current. Move the PDF only when the source and the destination are different files. If generation fails, keep the plain-text fallback. Upload the file that those steps left at `/tmp/test.pdf`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Generator | The `cd /tmp && pdflatex && mv` line | `(cd /tmp && pdflatex test.tex)` so the parent shell stays in the project |
| Move | `mv test.pdf "$test_pdf"` | Skip the move when the generator already wrote `$test_pdf`, or write the PDF somewhere else and move that path |
| Fallback | The `||` block | Run only when `pdflatex` failed, not when `mv` refused a same-file rename |
| Log | `LOG_FILE` | Stays the project file because the shell never leaves the project |

### Rules

1. **A successful `pdflatex` keeps its PDF.** The bytes at `/tmp/test.pdf` stay the generated file through the upload.
2. **Same-file `mv` is not a generation failure.** Exit 1 from `mv` on identical paths must not trigger the plain-text fallback.
3. **The project log stays the project log.** Lines after generation append to `$SCRIPT_DIR/tu-vm.log`.
4. **The missing-`pdflatex` fallback stays.** This machine has no `pdflatex`. That branch may still write `Test PDF content`.
5. **Stage 54 still owns the password.** The `mc` line keeps whatever credential fix that page specifies.
6. **No new PDF toolkit.** `pdflatex` or the existing one-line fallback.

### Suggested contributor checklist

```text
1. From a project directory, run the generator branch with a stub that writes /tmp/test.pdf
2. Confirm /tmp/test.pdf is still those bytes, not the line "Test PDF content"
3. Confirm the shell's working directory is still the project and the next log line is in tu-vm.log
4. Confirm a failed generator still writes the plain-text fallback
5. Confirm the mc password line is unchanged
6. Confirm ./tu-vm.sh pdf-test was not required and .env was not created
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| PDF bytes | `pdflatex` already called here | A new document library |
| Failure file | The existing one-line fallback | Skipping the upload |
| Working directory | A subshell `(cd /tmp && …)` | `cd` in the `tu-vm.sh` process |
| Log file | Relative `tu-vm.log` after `main` enters the project | A second log path |
| Intake | GitHub Issue | A test-result service |

### Acceptance check

- [ ] When the generator writes `/tmp/test.pdf`, that file is the one `mc cp` uploads.
- [ ] `mv` onto the same path does not replace the PDF with `Test PDF content`.
- [ ] After the generator branch, the working directory is still the project directory.
- [ ] A log line written after generation is in the project `tu-vm.log`, not `/tmp/tu-vm.log`.
- [ ] A missing or failed `pdflatex` still uses the plain-text fallback.
- [ ] The MinIO password on the upload line is unchanged.
- [ ] `.env` was not created, and `./tu-vm.sh pdf-test` was not run against a live stack.

### Rollback

Restore the `cd /tmp && pdflatex && mv` chain in the current shell. A host with `pdflatex` again replaces the generated PDF with `Test PDF content` and appends the rest of the command's log to `/tmp/tu-vm.log`.
