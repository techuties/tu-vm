## Summary

<!-- Link issues: Fixes #123 / Closes #456 / Refs #789 -->

## Scope

<!-- Compose-only change / helper / nginx / docs — keep PRs focused -->

## Release notes (maintainers)

<!-- Optional: labels drive Release Drafter sections on main (bug, enhancement, documentation, breaking, skip-changelog, …). See CONTRIBUTING.md. -->

## Security & RFC

- [ ] Does **not** expose secrets, tokens, or production `.env` values in repo or CI logs.
- [ ] Control-plane / nginx allowlist behavior unchanged unless intentional and documented.
- [ ] Breaking operational behavior called out in README or playbooks where operators would notice.

## Verification

<!-- Commands you ran locally -->

- [ ] `./scripts/smoke-test.sh` (and `./scripts/smoke-test.sh --live` if nginx tier was up)
- [ ] `./scripts/check-config.sh` or `./scripts/check-config.sh --strict` as appropriate

- [ ] Does **not** expose secrets, tokens, or production `.env` values in repo or CI logs.
- [ ] Control-plane / nginx allowlist behavior unchanged unless intentional and documented.
- [ ] Breaking operational behavior called out in README or playbooks where operators would notice.

## Verification

<!-- Commands you ran locally -->

- [ ] `./scripts/smoke-test.sh` (and `./scripts/smoke-test.sh --live` if nginx tier was up)
- [ ] `./scripts/check-config.sh` or `./scripts/check-config.sh --strict` as appropriate
