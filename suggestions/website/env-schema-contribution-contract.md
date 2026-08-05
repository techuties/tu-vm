---
title: Env Schema Contribution Contract
description: Constructional contract for community contributions that evolve env.example and configuration checks without committing secrets or inventing a separate secrets platform.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Env Schema Contribution Contract

## Problem

New services and features usually need environment knobs. Historical suggestions invent dotenv UIs, remote secret managers, or commit “example” values that look like production credentials. Contributors need a **reuse-first env schema contract** so day-to-day configuration stays documented, validated, and secret-safe.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` | Canonical commented schema for operators |
| `./tu-vm.sh generate-secrets` | Local secret materialization into `.env` |
| `scripts/check-config.sh` (+ `--ci` / `--strict`) | Required-file and value hygiene |
| `.gitignore` excluding `.env` | Prevents credential commits |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotation lifecycle after secrets exist |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local Compose customization lane |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | CI interpolation without real secrets |
| `AGENTS.md` / cloud notes | Docs-only checks via `env.example` sourcing |

Out of scope:

- Committing live `.env` files or production passwords
- Mandatory HashiCorp Vault / cloud KMS for single-host LAN installs
- Building a dashboard “secrets editor” that stores credentials in the browser
- Silently renaming widely used variables without deprecation notes (Stage 6)

## Proposal

Publish an **env schema contribution contract** with lanes for schema, validation, and docs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Schema comments | `env.example` | New vars documented with safe placeholders |
| Secret generation | `generate-secrets` paths in `tu-vm.sh` | Only generates into ignored `.env` |
| Validation | `scripts/check-config.sh` | New required checks are CI-safe |
| Compose wiring | `docker-compose.yml` `${VAR}` usage | Defaults fail closed or match example |
| Docs / playbooks | `#playbook-env-schema` (proposed) | Copy example → generate-secrets → check-config |
| Deprecation | Stage 6 deprecation framework | Rename/removal notices |

### Rules

1. **`env.example` is the schema.** New operator-facing knobs land there with comments before code assumes them.
2. **Placeholders only.** Use obviously fake values (`changeme`, `example.local`); never paste real tokens.
3. **Generation stays local.** Secret creation continues via `generate-secrets` / documented helpers—not CI logs.
4. **Checks stay runnable without Docker when possible.** Prefer `check-config`/`--ci` patterns already used in Actions.
5. **Compose defaults must not weaken security silently.** Binding/auth-related defaults need explicit justification.
6. **Pair with rotation guidance** when adding credentials (Stage 8 secret-rotation).
7. **GitHub remains intake.** Schema debates are Issues/PRs.

### Suggested playbook shape

```text
#playbook-env-schema
1. cp env.example .env   # if missing
2. ./tu-vm.sh generate-secrets
3. Edit only the operator-facing knobs you understand
4. ./scripts/check-config.sh --strict
5. Never commit .env
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Schema docs | Commented `env.example` | Parallel YAML “config product” |
| Secrets | Local `generate-secrets` | Committing ciphertext that still embeds real secrets |
| Validation | `check-config` + CI | Dashboard forms writing secrets to disk by default |
| Local overrides | Compose override lane (Stage 8) | Forking `env.example` per contributor without upstreaming |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-env-schema` when implementing docs polish.
3. Cross-link Stage 8 secret-rotation / compose-override and Stage 6 deprecation pages.
4. Mention in CONTRIBUTING for PRs that add Compose services.

## Acceptance criteria

- [ ] Lanes distinguish schema comments vs secret generation vs validation.
- [ ] Rule forbids committing `.env` or real credentials in examples.
- [ ] New variables require `env.example` comments and check-config consideration.
- [ ] Security-sensitive defaults need explicit justification.
- [ ] Rotation/deprecation cross-links are present.

## Rollback

Remove unused variables from `env.example` and Compose; operators keep local `.env` values until they prune manually. No registry or external secret store to tear down.

## Success metrics

- Fewer PRs that introduce undocumented env vars.
- CI continues to interpolate from `env.example` without real secrets.
- Secret-related Issues cite generate-secrets / rotation contracts instead of asking maintainers for passwords.
