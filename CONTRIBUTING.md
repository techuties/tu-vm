# Contributing to TU-VM

TU-VM is operated from this repository and Docker Compose. We keep contribution friction low while preserving LAN-first defaults and safe operational boundaries.

## GitHub does not “create” our Markdown for you

Everything under version control—including `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `AGENTS.md`, `CHANGELOG.md`, `docs/playbooks/`, `suggestions/`, and `.github/` (workflows + issue templates)—**only appears on GitHub after you push (or merge) to the remote**. An empty org/repo will stay empty until commits land on the **default branch** (`Settings → General → Default branch`).

Use the checklist below once your first push is on GitHub so you can confirm templates, policies, and automation are wired up.

### Checklist: confirm integration on GitHub

1. **Default branch** — Ensure the branch you merged (`main`, `dev`, etc.) is the default branch you expect; many features (Release Drafter, issue template picker) read from **default** only.

2. **Actions enabled** — `Settings → Actions → General`: allow workflows (subject to org policy). Open the **Actions** tab; you should see workflows such as **CI**, **Docs links**, **Trivy**, **Release Drafter**, **Stale**. If nothing ran yet, open a workflow → **Run workflow** (where `workflow_dispatch` is available) or push a tiny commit.

3. **Docs link job** — Workflow **Docs links** runs on **every** push/PR to `main` / `dev` and lists the Markdown files it checks in the run **Summary**. A green run means lychee validated links in those files; red means a URL needs fixing or excluding.

4. **Issue templates** — `Issues → New issue`: you should see **Bug report** and **Idea / suggestion**. If GitHub only offers a blank issue, confirm `.github/ISSUE_TEMPLATE/*.yml` and `config.yml` exist on the default branch.

5. **`SECURITY.md`** — `Security → Security policy` (or **Report a vulnerability** if the org enabled private reporting). The policy text comes from the `SECURITY.md` file in the repo root on the default branch.

6. **Pull request template** — Open **New pull request**: the description should start from [`.github/pull_request_template.md`](.github/pull_request_template.md).

7. **Labels** — GitHub does not pre-seed our label set. Create the ones you use (`bug`, `suggestion`, `triage`, `needs-info`, …) under `Issues → Labels`, or issue templates that set `labels: [...]` may fail until those labels exist.

8. **Dependabot** — [`.github/dependabot.yml`](.github/dependabot.yml) opens PRs when enabled for the repo/org (`Settings → Code security and analysis`). The first PR can take up to the scheduled interval.

9. **CODEOWNERS** — [CODEOWNERS](CODEOWNERS) uses a **placeholder team** until you replace `@techuties/tu-vm-maintainers` with real `@org/team` or `@username` handles; invalid handles do not assign reviewers until fixed.

10. **Release Drafter** — [`.github/workflows/release-drafter.yml`](.github/workflows/release-drafter.yml) runs on **pushes to `main`** (and manual dispatch). Pushes only to `dev` will **not** update the draft release until you merge to `main` or run the workflow against `main`.

## Suggestions and roadmap

- **Ideas and enhancements**: open a GitHub Issue using the **Idea / suggestion** template, or start from [Issues](https://github.com/techuties/tu-vm/issues).
- **Bugs**: use the **Bug report** template (include reproduction steps and revision).
- **Security vulnerabilities**: follow [SECURITY.md](SECURITY.md). Prefer **Security → Report a vulnerability** when GitHub enables private reporting for this repo — do not post exploit chains in public issues.

### Labels (maintainers + helpers)

Create labels as needed when absent; typical meanings:

| Label | Use |
|-------|-----|
| `bug` | Incorrect or broken behaviour |
| `suggestion` | Feature / enhancement proposal |
| `triage` | Needs maintainer sorting |
| `needs-info` | Waiting on reporter details — [**Stale**](https://github.com/actions/stale) automation pings after ~21 inactive days |
| `stale` | Applied by automation; remove when active again |
| `pinned` | Do not auto-mark stale |
| `documentation` / `docs` | Doc-only PRs (Release Drafter bucket) |
| `chore` / `dependencies` | Maintenance bucket |
| `breaking` | Breaking change — bump major in Release Drafter |
| `enhancement` / `feature` | Features bucket — minor bump |
| `skip-changelog` | PR omitted from draft release notes |
| `good first issue` | Friendly starter work |

### Releases and changelog linkage

- **Merged PRs to `main`** update a **draft** GitHub Release via [Release Drafter](https://github.com/release-drafter/release-drafter) (workflow `.github/workflows/release-drafter.yml`, config `.github/release-drafter.yml`).
- **Link PRs to Issues** using `Fixes #123`, `Closes #456`, or `Refs #789` in the PR description so GitHub connects history.
- Apply **`documentation`**, **`bug`**, **`enhancement`**, **`breaking`**, etc. on PRs when sensible so draft notes land under the right section.
- Publishing: edit the draft release notes if needed, then **publish** and tag when ready (`v*` tags align with Release Drafter’s resolver).

Human-edited highlights remain welcome in [CHANGELOG.md](CHANGELOG.md); mirror or summarise Release contents there when cutting a formal release.

### Design discussion

When **Discussions** is enabled for this repository (**Settings → General → Features**), use them for early design chat; if the tab is not available, open a **Idea / suggestion** issue instead.

## Local checks before you push

From the repository root:

```bash
./scripts/smoke-test.sh
./tu-vm.sh help
```

Optional stricter validation when `.env` is configured:

```bash
./scripts/check-config.sh --strict
```

The repo ships [`scripts/pre-push-check.sh`](scripts/pre-push-check.sh) as a convenience wrapper (requires Docker for compose rendering).

## Operational playbooks

Short, operator-focused recipes live under [`docs/playbooks/`](docs/playbooks/) (safe updates, recovery, DNS, MCP smoke).

## Optional tooling

### Pre-commit

```bash
pip install pre-commit   # once
pre-commit install
pre-commit run --all-files
```

Configuration lives in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) (EOF/whitespace, merge markers, YAML checks under `.github/`, `bash -n` on `tu-vm.sh` and `scripts/*.sh`). `docker-compose.yml` is excluded from generic YAML lint because Compose uses richer syntax than many YAML linters tolerate.

### Release note helper

```bash
./tu-vm.sh release-notes v2.0.0
# or
./scripts/release-note-helper.sh v2.0.0
```

### `/status/full` JSON contract

Nginx exposes helper [`GET /status`](helper/uploader.py) as `/status/full`. If you change that payload shape, update [`fixtures/status-full-contract.json`](fixtures/status-full-contract.json). CI runs [`scripts/validate_status_full_contract.py`](scripts/validate_status_full_contract.py).

### CODEOWNERS and branch protection

[`CODEOWNERS`](CODEOWNERS) uses placeholder `@techuties/tu-vm-maintainers` — replace with your GitHub team or `@username` handles. Optionally enable **branch protection → require review from Code Owners** for sensitive paths.

### Extra CI automation

- [`.github/workflows/docs-links.yml`](.github/workflows/docs-links.yml) — lychee link checks on core Markdown.
- [`.github/workflows/trivy.yml`](.github/workflows/trivy.yml) — Trivy **config** scan of the repo root (Compose + Dockerfiles; misconfiguration hints). Uses `exit-code: 0` so findings are informational until you tighten policy.
- [`.github/dependabot.yml`](.github/dependabot.yml) — weekly GitHub Actions bump PRs.

## Code and config style

- Prefer small, reviewable changes that match existing script and YAML patterns.
- Do not commit real `.env` files or credentials.
- When changing nginx, helper APIs, or control endpoints, update landing/helper expectations and mention verification steps in the PR.
