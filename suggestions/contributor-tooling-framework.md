---
title: Contributor Tooling Framework
description: Reuse-first tooling proposals for reproducible, privacy-safe community support.
---

# Contributor Tooling Framework

## Objective

Make issue reports reproducible without asking operators to paste secrets, entire
configuration files, or unbounded container logs.

This proposal updates the historical "operator snapshot" idea after checking the
repository's current tooling. It does not introduce another diagnostics command
that overlaps with working scripts.

## Existing tooling to reuse

| Historical suggestion | Repository capability today | Direction |
|---|---|---|
| Preflight verifier | `./tu-vm.sh check-config` and `scripts/check-config.sh` | Extend only when a concrete check is missing. |
| Operator snapshot | `./tu-vm.sh doctor --json` | Use as the support bundle's core input. |
| Local quality task | `scripts/pre-push-check.sh` | Keep as the canonical wrapper; a task runner would only alias it. |
| CI baseline | `.github/workflows/ci.yml` and focused workflows | Add checks to existing workflows instead of creating a parallel pipeline. |

The remaining gap is packaging these signals into one privacy-reviewed artifact
that a reporter can inspect and attach to a GitHub issue.

## Detailed suggestion: privacy-safe support bundle

### User workflow

Add a thin command over existing diagnostics:

```bash
./tu-vm.sh support-bundle --preview
./tu-vm.sh support-bundle --output ./tu-vm-support.tar.gz
```

The command should:

1. collect only an explicit allowlist of diagnostic fields;
2. validate and scan the staged files for secret-like values;
3. show the exact file list and field names with `--preview`;
4. create a local archive with restrictive permissions; and
5. print instructions for reviewing and attaching it to a GitHub issue.

It must never upload data or contact a third-party service.

### Versioned bundle contract

Use a stable, machine-readable layout:

```text
manifest.json
doctor.json
checks.json
services.json
README.txt
```

Recommended fields:

- `manifest.json`
  - schema version;
  - TU-VM release or commit;
  - generated timestamp and collection command;
  - included file names and SHA-256 checksums;
  - redaction and secret-scan result.
- `doctor.json`
  - output derived from `./tu-vm.sh doctor --json`;
  - normalized into structured values where practical.
- `checks.json`
  - exit status and short result for `check-config`, offline `smoke-test`, and
    optional helper contract checks;
  - no raw environment values or command output that has not been allowlisted.
- `services.json`
  - Compose service name, image name/tag, state, health, and restart count;
  - no environment, labels, mounts, command arguments, IP addresses, or host
    paths in the first version.
- `README.txt`
  - human-readable privacy warning, review checklist, and issue-linking steps.

Every field should be documented so maintainers can consume bundles across
versions and reject unsupported schemas clearly.

### Privacy and security boundary

The collector should be allowlist-based, not a full dump followed by best-effort
redaction.

Do not collect by default:

- `.env` contents or secret values;
- Docker inspect output;
- certificate or key material;
- control tokens, cookies, request headers, or database URLs;
- container logs;
- user prompts, documents, object names, chat history, or model inputs;
- absolute host paths, usernames, hostnames, public IPs, or Wi-Fi identifiers.

Required safeguards:

1. Stage files in a mode-`0700` temporary directory and write the archive as
   mode `0600`.
2. Scan values for known secret names, credential URL forms, private-key
   markers, bearer tokens, and high-entropy strings.
3. Fail closed when a scan finds a possible secret; report only the file and
   field path, never the matched value.
4. Remove temporary files on success, failure, or interruption.
5. Make `--preview` usable without creating an archive.
6. Require an explicit future option for any log capture. Log collection should
   remain out of scope for the first version.

Pattern scanning is a final guard, not permission to collect broad data.

### Implementation fit

Use a small Python standard-library collector under `scripts/` and expose it
through `tu-vm.sh`. Python already supports the current JSON diagnostics, and
its `json`, `tarfile`, `hashlib`, `tempfile`, and file-permission APIs avoid a
new runtime dependency.

The collector should call existing commands and normalize their results rather
than reimplement Docker, Compose, or configuration checks. Unknown and timed-out
checks should be represented explicitly, not silently omitted.

### Community and website integration

After the command ships:

- Update the bug issue form to request a bundle or the `doctor --json` fallback.
- Publish a support-evidence guide on the future static community website.
- Link bundle schema versions to known parsing limitations.
- Keep GitHub Issues as the support system of record; do not build a local
  upload database or dashboard inbox.
- Never embed submitted bundle contents into the public docs build.

See [Community Operations Toolkit](./community-operations-toolkit.md) for the
proposed website pages and triage flow.

## Alternatives considered

### Ask reporters to paste `doctor --json`

Keep this as the fallback. It is simple but does not include test outcomes,
checksums, or a versioned support contract.

### Export full Compose config or Docker inspection

Reject. Rendered configuration and inspect output can contain credentials,
internal addresses, mounts, and other sensitive deployment details.

### Add hosted telemetry or automatic uploads

Reject. It conflicts with TU-VM's local/private posture and creates retention,
consent, authentication, and breach-response obligations.

## Rollout and rollback

1. Define the JSON schemas and fixture bundles with synthetic values.
2. Implement `--preview` and archive generation without logs.
3. Test secret detection against seeded credentials and private-key fixtures.
4. Pilot with maintainers on local bundles that are not posted publicly.
5. Update the issue form and website guide only after the privacy review passes.
6. Add optional parsers or automation only after at least one schema remains
   stable through a release.

Rollback is documentation-first: remove the issue-form request and website link,
then disable the `tu-vm.sh` entrypoint. Existing diagnostics continue to work
independently.

## Acceptance criteria

- A bundle can be generated when some services are stopped or Docker is
  unavailable.
- Re-running against equivalent state produces the same schema and file layout.
- Automated tests prove that `.env`, private keys, tokens, credential URLs, and
  forbidden fields never enter an archive.
- The archive contains enough synthetic-test evidence to distinguish config,
  startup, health, and endpoint failures.
- A reporter can list and review every collected field before sharing.
- The command exits non-zero and leaves no archive when secret scanning fails.
- No network request occurs during collection.

## Success measures

- Fewer `needs-info` rounds before an issue can be reproduced.
- Lower median time from bug report to subsystem assignment.
- Percentage of support bundles accepted without requesting replacement data.
- Zero confirmed secret disclosures from generated bundles.
- Bundle schema changes remain backward compatible or include a documented
  migration path.
