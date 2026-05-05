# Security policy

## Supported versions

Security fixes are applied on the active development branch (`main` / `dev`) and tagged releases as described in [CHANGELOG.md](CHANGELOG.md). Prefer running a recent tag or fast-forwarded `main` for production-like deployments.

## Reporting a vulnerability

**Please do not** open a public issue with exploit code, payloads, or step-by-step break-ins.

Preferred path:

1. Open **[Report a vulnerability](https://github.com/techuties/tu-vm/security/advisories/new)** (repository **Security** tab) if private reporting is enabled for this repo.
2. If that entry point is unavailable, create a **non-technical** issue (e.g. title `Security — private report needed`) asking maintainers for a private channel, or use organisation contact procedures if published by TechUties.

Include:

- Affected surface (e.g. nginx helper, compose service, script)
- Impact summary (confidentiality / integrity / availability) without weaponised details until coordinated
- TU-VM revision or image tag if known

Maintainers will aim to acknowledge in a reasonable window; severity and fix timeline depend on impact and reproducibility.

## Scope notes

TU-VM is intended for **private / LAN-first** operation. Misconfiguration (e.g. exposure of control tokens, public bind of sensitive ports) may be documented as hardening guidance rather than tracked as code defects — reports should still clarify default vs misconfiguration when possible.
