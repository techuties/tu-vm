---
title: Optional Command Argument Contract
description: Constructional contract so tu-vm.sh help text that marks an argument optional still runs when that argument is omitted under set -u.
last_updated: 2026-11-02
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Optional Command Argument Contract

## Problem

`tu-vm.sh` starts with `set -euo pipefail`. Help describes three commands whose second word is optional, and one command that explains itself when the file is missing:

```text
logs [service]           Show service logs
backup [name]            Create backup with optional name
pdf-logs [service]       Show PDF processing logs (tika/minio/processor)
restore <file>           Restore from backup file
```

`show_logs` and `show_pdf_logs` both print usage when the service name is empty. `create_backup` defaults the name:

```bash
local backup_name="${1:-backup_$(date +%Y%m%d_%H%M%S)}"
```

`restore_backup` prints `Please specify backup file` when the file is empty, then exits through `error`.

`main` never reaches those branches for a bare command. The arms pass an unset parameter:

```bash
logs)
    show_logs "$2"
backup)
    create_backup "$2"
restore)
    restore_backup "$2"
pdf-logs)
    show_pdf_logs "$2"
```

Under `set -u`, `"$2"` is an error when the operator typed only the command. Other arms in the same `case` already use the safe form: `start_single_service "${2:-}"`, `whitelist_add "${2:-}"`, and `fix_openwebui_audio_config "${2:-whisper-1}"`.

Replayed on Bash 5.2.21 without executing `tu-vm.sh` (that script's `main` would create `.env` through `check_env_file`). A copy of the four arms and the four function heads:

| Invocation | Result |
|---|---|
| `show_logs "$2"` with no second parameter | `unbound variable`, exit 1, usage not printed |
| `show_pdf_logs "$2"` | `unbound variable`, exit 1, usage not printed |
| `create_backup "$2"` | `unbound variable`, exit 1, default name not used |
| `restore_backup "$2"` | `unbound variable`, exit 1, the "specify backup file" message not printed |
| The same four functions called as `"${2:-}"` | Usage, usage, `backup_default`, and the restore message, each exit 0 from the function body |

`./tu-vm.sh logs nginx` is the path that already works, because `$2` is set. The help brackets are the path that fails.

Checked on 2026-11-02 by reading `show_help`, `main`, `show_logs`, `show_pdf_logs`, `create_backup`, and `restore_backup`, and by the replay above. `.env` was not created. No backup was written.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `set -euo pipefail` | The mode that rejects an unset `$2` |
| `"${2:-}"` in `main` | The form `start-service` and `whitelist-add` already use |
| `show_logs` / `show_pdf_logs` empty check | Usage text the operator should see |
| `create_backup` default name | The name help promises when `[name]` is omitted |
| `restore_backup` empty check | The message help's required file should produce |
| Stage 63 and Stage 64 backup pages (open PRs #89 and #90) | Volume loop, dump rotation, and the running-state gate. Unchanged here |
| Stage 47 backup restore apply (open PR #73) | What restore writes. Unchanged here |

Out of scope:

- A new CLI framework or a `getopts` rewrite
- The body of `create_backup` and `restore_backup`
- Commands whose help does not take a second word

## Proposal

Pass an empty string from `main` when the operator omits the optional word. Let the functions keep the behavior they already implement.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Logs | `logs)` | `show_logs "${2:-}"` |
| PDF logs | `pdf-logs)` | `show_pdf_logs "${2:-}"` |
| Backup | `backup)` | `create_backup "${2:-}"` |
| Restore | `restore)` | `restore_backup "${2:-}"` |
| Function bodies | The four functions | Leave defaults and usage text in place |

### Rules

1. **Optional help text must run under `set -u`.** `logs`, `pdf-logs`, and `backup` with no second word reach the function.
2. **`restore` with no file reaches its own message.** The unbound-variable abort is not that message.
3. **A provided second word is unchanged.** `logs nginx`, `backup my-backup`, and `restore backup.tar.gz` still pass that word.
4. **Do not edit backup or restore internals.** Stage 63, Stage 64, and Stage 47 own those bodies.
5. **Do not drop `set -u`.** The fix is the default expansion the neighboring arms already use.

### Suggested contributor checklist

```text
1. Run the four arms with no second parameter under set -u and confirm each function starts
2. Run logs with a service name and confirm that name is the argument
3. Confirm create_backup still defaults only when the argument is empty
4. Confirm the volume loop, the dump gate, and the restore copy were not edited
5. Confirm set -euo pipefail is still the first mode line
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Optional positional word | `"${2:-}"` already in this `case` | A CLI parsing library |
| Usage text | The `if [[ -z ... ]]` branches already in the functions | A second help printer |
| Default backup name | `create_backup`'s existing `${1:-...}` | A new naming service |
| Intake | GitHub Issue | A wrapper script around `tu-vm.sh` |

### Acceptance check

- [ ] `logs`, `pdf-logs`, `backup`, and `restore` in `main` use `"${2:-}"`.
- [ ] Bare `logs` and bare `pdf-logs` print the usage those functions already have.
- [ ] Bare `backup` uses the function's default name.
- [ ] Bare `restore` prints the function's missing-file message.
- [ ] `create_backup` and `restore_backup` bodies are unchanged.
- [ ] `./tu-vm.sh` was not executed to prove this, so `.env` was not created.

### Rollback

Restore the four `"$2"` expansions. Commands typed with a second word behave the same either way. Bare commands return to the unbound-variable abort.
