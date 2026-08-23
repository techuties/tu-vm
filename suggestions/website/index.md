---
title: Community Suggestions Website
description: Publishable Stage 24 community website markdown for unused Nginx worker env keys, Redis ACL users, MinIO SSE/KMS, host sysctl knobs, Compose depends_on health conditions, backup archive encryption, and unused HEALTH_CHECK_* intervals—extending Stages 1–23 without reinventing frameworks or community intake.
last_updated: 2026-08-23
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated, read-only pages that a future static docs site can ship without creating a second editable tree.

Participation stays on GitHub. These pages explain how the community system works, which frameworks to reuse, and which living contracts keep day-to-day work easy.

## Why this exists

TU-VM already has strong operational surfaces (`tu-vm.sh`, helper API, Nginx dashboard, playbooks, CI, smoke/pre-push gates, Compose IPAM, local tar backup, and digest-pinned images). Historical suggestion branches repeatedly asked for the same foundations:

1. Clear website information architecture for docs, operations, and community
2. Lightweight governance and contribution workflow
3. Practical tooling that reduces daily friction
4. Reuse of mature frameworks instead of custom platforms

**Stage 24** (this run) adds **env-honesty, Redis-ACL, object-SSE, host-sysctl, depends_on-health, archive-crypto, and health-interval constructional contracts** that remained open after Stage 1–23 drafts and consolidation PRs (#23–#49):

- Wire or delete advertised `NGINX_WORKER_*` keys
- Optional Redis ACL users on top of `requirepass`
- Opt-in MinIO SSE-S3 / local KMS secret
- Optional host sysctl drop-in (inotify, swappiness)
- Compose `depends_on` uses `service_healthy` when a probe exists
- Optional encryption wrap for `tu-vm.sh` backup tarballs
- Wire or delete advertised `HEALTH_CHECK_*` keys

These are **constructional**: they tell contributors how to extend existing `nginx.conf`, official Redis ACL, MinIO `mc encrypt`, `sysctl.d`, Compose health conditions, `age`/`openssl`, and Compose interpolation without inventing an Nginx control plane, Redis Cluster, Vault, a sysctl sidecar, a start orchestrator, restic-as-default, or a health SaaS.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake and discussion |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`CHANGELOG.md`](../../CHANGELOG.md) / Releases | Shipped-work record |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting path |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing dashboard | Local control plane (not a social platform) |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–22 website pages (open PRs #27–#48) | Contracts and living artifacts—implement, do not rewrite |
| Stage 23 website pages (open PR #49) | Snippets, ILM, read-only rootfs, GUCs, Qdrant memory, timezone, role networks |
| Consolidation / knowledge packs / support / change-aware PRs (#23–#26) | Adjacent proposals—extend, do not duplicate |

Do **not** add a local voting database, suggestion queue API, or dashboard authentication for public participation. The website publishes curated views and links back to GitHub.

## Page map (Stage 24)

| Page | Purpose |
|---|---|
| [Nginx worker env wiring](./nginx-worker-env-wiring-contract.md) | Wire or delete unused `NGINX_WORKER_*` keys |
| [Redis ACL users](./redis-acl-users-contract.md) | Optional ACL file on top of `requirepass` |
| [MinIO SSE / KMS](./minio-sse-kms-contract.md) | Opt-in SSE-S3 or local KMS secret |
| [Host sysctl tuning](./host-sysctl-tuning-contract.md) | Optional inotify / swappiness drop-in |
| [Compose depends_on health](./compose-depends-on-health-contract.md) | `service_healthy` when a probe exists |
| [Backup archive encryption](./backup-archive-encryption-contract.md) | Optional wrap so README matches `create_backup` |
| [Healthcheck interval env](./healthcheck-interval-env-contract.md) | Wire or delete unused `HEALTH_CHECK_*` keys |

## Expected sibling Stage 1 pages

When merged from the Stage 1 website proposal, keep these as siblings (same folder, one content root later):

| Page | Purpose |
|---|---|
| `how-to-submit.md` | High-signal suggestion writing and dedupe checks |
| `status-board.md` | Curated projection of suggestion lifecycle |
| `day-to-day-community-tools.md` | Frameworks and commands that ease daily work |
| `mcp-tools-catalog.md` | Human contribution contract for optional MCP tool images |

## Expected sibling Stage 2 pages

| Page | Purpose |
|---|---|
| `hardware-compatibility-matrix.md` | Living host/RAM/GPU/storage fit artifact |
| `persona-entry-paths.md` | First-hour routes for operators and contributors |
| `operator-service-profiles.md` | Named Tier 1/Tier 2 profiles for resource control |

## Expected sibling Stage 3 pages

| Page | Purpose |
|---|---|
| `decision-log.md` | Accepted / deferred / declined rationale |
| `implemented-showcase.md` | Changelog-adjacent proof that community ideas shipped |
| `docs-framework-adoption.md` | Starlight-first adoption gates |
| `community-quality-gates.md` | Day-to-day evidence map |
| `extension-pilot-contract.md` | Compose-backed extension package shape |
| `hardware-class-intake.md` | Optional Issue-form `class_id` |

## Expected sibling Stage 4 pages

| Page | Purpose |
|---|---|
| `mcp-catalog-ci-contract.md` | `mcp-tools/catalog.yaml` schema + CI validation |
| `operator-profile-cli.md` | `tu-vm.sh profile` list/show/apply `--plan` |
| `extension-pilot-scaffold.md` | First `extensions/<id>/` package + validator |
| `supply-chain-community-gates.md` | Image CVE scans, severity gates, optional SBOM |
| `dashboard-modularization-smoke.md` | Extract Nginx assets + Playwright Tier-1 smoke |
| `stage-merge-playbook.md` | Reconcile Stage hubs without losing siblings |

## Expected sibling Stage 5 pages

| Page | Purpose |
|---|---|
| `devcontainer-contributor-environment.md` | Repeatable Codespaces/Dev Containers setup |
| `compose-ci-live-profile.md` | Minimal Compose profile for live `/status/full` |
| `playbook-version-matrix.md` | Release-aware notes for operator playbooks |
| `community-label-and-board-contract.md` | GitHub labels + Projects as the OS |
| `community-health-digest.md` | Privacy-safe metrics as static markdown |
| `task-runner-wrapper.md` | `just`/`make` thin facade over existing scripts |
| `control-plane-contribution-contract.md` | Safe nginx allowlist and control-plane rules |

## Expected sibling Stage 6 pages

| Page | Purpose |
|---|---|
| `suggestion-corpus-registry.md` | YAML registry + CI for historical suggestions |
| `website-frontmatter-ci-contract.md` | Schema and link checks for publishable pages |
| `n8n-workflow-catalog.md` | Community contribution path for n8n recipes |
| `observability-contribution-contract.md` | Grafana/Prometheus dashboard and alert contribution rules |
| `backup-restore-community-drill.md` | Recurring reliability drill using existing backup/restore commands |
| `airgap-docs-mirror.md` | Offline/static docs pack for LAN and disconnected operators |
| `deprecation-notice-framework.md` | Breaking-change and deprecation communication pattern |

## Expected sibling Stage 7 pages

| Page | Purpose |
|---|---|
| `helper-api-contribution-contract.md` | Evolve helper/`/status/full` without breaking the dashboard |
| `tier2-idle-autostop-policy.md` | Opt-in idle timeout for heavy on-demand services |
| `battery-power-operator-signals.md` | Laptop battery widgets and energy-aware recommendations |
| `local-resource-history.md` | Local-only CPU/memory trend snapshots for operators |
| `service-dependency-map.md` | Declared dependencies for safe Tier 2 start ordering |
| `dashboard-accessibility-mobile.md` | A11y and touch-first acceptance baseline for the control plane |
| `ai-pipeline-contribution-contract.md` | Community path for MCP gateway and LangGraph supervisor **code** changes |

## Expected sibling Stage 8 pages

| Page | Purpose |
|---|---|
| `smart-startup-optimization.md` | Tier-aware quick-start planner without a new orchestrator |
| `secret-rotation-credential-hygiene.md` | Day-to-day secret lifecycle using `generate-secrets` and playbooks |
| `compose-override-contribution-contract.md` | Safe community path for local Compose customizations |
| `image-update-channel-policy.md` | Pin, check, update, and rollback with clear operator channels |
| `rag-knowledge-contribution-contract.md` | Community docs and corpora via MinIO/Tika/Qdrant/Open WebUI |
| `release-canary-community-program.md` | Lightweight pre-release testing using GitHub + existing smoke tools |
| `cross-service-e2e-scenario-catalog.md` | Named scenarios that wrap `chain-smoke`, helper checks, and playbooks |

## Expected sibling Stage 9 pages

| Page | Purpose |
|---|---|
| `privacy-preserving-usage-analytics.md` | Local-only usage patterns and recommendations |
| `ollama-model-catalog-contribution.md` | Community path for recommending local models |
| `affine-collaboration-contribution-contract.md` | Safe community recipes around AFFiNE |
| `pihole-dns-hygiene-contribution.md` | LAN DNS / blocklist hygiene (distinct from Tailscale bridge) |
| `offsite-backup-rclone-contract.md` | Optional remote backup lane over existing `backup` |
| `dashboard-feature-flag-experiments.md` | Env-driven UI experiments |
| `dashboard-release-highlights-contract.md` | Optional “What is new” bullets on the LAN dashboard |

## Expected sibling Stage 10 pages

| Page | Purpose |
|---|---|
| `open-webui-contribution-contract.md` | Safe community path for Open WebUI config, init, and tool wiring |
| `document-pipeline-contribution-contract.md` | Tika + MinIO + processor contribution rules |
| `data-plane-hygiene-contract.md` | Volume and corpus hygiene distinct from ILM |
| `tls-certificate-lifecycle-contract.md` | Local TLS renew/replace without a public CA product |
| `disk-pressure-volume-ops-contract.md` | Host disk pressure distinct from Qdrant RAM |
| `gpu-acceleration-contribution-contract.md` | Optional GPU lanes for Ollama / Open WebUI |
| `qm-llm-bridge-contribution-contract.md` | QM / local LLM bridge rules |

## Expected sibling Stage 11 pages

| Page | Purpose |
|---|---|
| `tailscale-lan-bridge-contract.md` | Optional Tailscale path distinct from Pi-hole DNS |
| `host-cron-maintenance-contract.md` | Cron install/remove without a second supervisor |
| `browserless-automation-contribution-contract.md` | Playwright/browserless contribution rules |
| `workflow-operator-contribution-contract.md` | Workflow Operator product lane |
| `autonomous-write-guard-policy.md` | Operator write-guard postures and env flags |
| `container-log-retention-contract.md` | Compose logging max-size / retention |
| `privileged-host-ops-contract.md` | Narrow sudoers / privileged host ops |

## Expected sibling Stage 12 pages

| Page | Purpose |
|---|---|
| `access-mode-and-firewall-contract.md` | Secure / public / lock access modes |
| `nginx-edge-routing-contract.md` | Edge vhost and proxy contribution rules |
| `env-schema-contribution-contract.md` | `.env` / `env.example` contribution rules |
| `diagnostics-and-triage-contract.md` | Doctor / diagnose evidence paths |
| `dashboard-announcements-contract.md` | Announcement surface contribution rules |
| `lan-dns-client-onboarding-contract.md` | Client/router DNS onboarding |
| `host-port-binding-contract.md` | Host port conflict and bind rules |

## Expected sibling Stage 13 pages

| Page | Purpose |
|---|---|
| `open-webui-audio-stt-contract.md` | Speech-to-text config and repair helpers |
| `open-webui-websearch-contract.md` | Optional web-search loader privacy rules |
| `pdf-operator-day2-contract.md` | PDF status / test / logs / reset toolkit |
| `ip-allowlist-day2-contract.md` | Whitelist list/add/remove day-to-day ops |
| `fixture-and-contract-test-contribution.md` | Fixture and schema validator contribution |
| `compose-healthcheck-contribution-contract.md` | Honest Compose healthcheck design |
| `host-cleanup-and-prune-contract.md` | Safe cleanup without surprise data loss |

## Expected sibling Stage 14 pages

| Page | Purpose |
|---|---|
| `cli-subcommand-contribution-contract.md` | Safe community path for extending `tu-vm.sh` |
| `changelog-release-notes-contribution-contract.md` | Human + automation path for release communication |
| `rollout-gates-proof-store-contract.md` | Pre/post-release proof-store quality gates |
| `n8n-mcp-sidecar-contribution-contract.md` | Enrichment sidecar rules distinct from workflow catalogs |
| `openwebui-minio-sync-day2-contract.md` | Operator contract for upload/TXT sync hygiene |
| `seed-chat-context-contribution-contract.md` | Community path for assistant context bootstraps |
| `pdf-loader-switch-day2-contract.md` | Tika / PyMuPDF toggle rules for day-to-day ops |

## Expected sibling Stage 15 pages

| Page | Purpose |
|---|---|
| `safe-update-contribution-contract.md` | Extend pin maps and check/apply/rollback without a second updater |
| `n8n-node-types-extraction-contract.md` | Regenerate gateway node-types JSON from local n8n |
| `open-webui-init-firstboot-contract.md` | Idempotent first-boot patching distinct from day-2 loader toggles |
| `langgraph-supervisor-smoke-contract.md` | Day-2 trust-path smoke without a parallel QA platform |
| `mcp-gateway-ops-contribution-contract.md` | Auth-preserving gateway ops and tool routing contributions |
| `docs-link-ci-contribution-contract.md` | Lychee workflow and exclude hygiene for community docs |
| `minio-bucket-lifecycle-contract.md` | Bucket naming, retention, and corpus hygiene |

## Expected sibling Stage 16 pages

| Page | Purpose |
|---|---|
| `daily-checkup-contribution-contract.md` | Scheduled Tier-aware health/update status without a monitoring SaaS |
| `pre-push-check-contribution-contract.md` | Fast local contributor gate wrapping shared scripts |
| `smoke-test-contribution-contract.md` | Static default + optional Tier-1 `--live` probes |
| `ci-workflow-contribution-contract.md` | Primary Actions gate that calls `scripts/` |
| `github-community-automation-contract.md` | Stale, issue forms, and triage without a local queue |
| `codeowners-review-routing-contract.md` | Path ownership and review routing |
| `dependabot-actions-maintenance-contract.md` | Weekly Actions bumps distinct from image CVE lanes |

## Expected sibling Stage 17 pages

| Page | Purpose |
|---|---|
| `weekly-stack-update-contribution-contract.md` | Cron-friendly full-stack update lane distinct from daily checkup |
| `check-config-contribution-contract.md` | Secret-safe preflight for compose/env/allowlist |
| `helper-contract-check-contribution-contract.md` | Live helper JSON probes when `ai_helper_index` is up |
| `pre-commit-hooks-contribution-contract.md` | Optional local hooks wrapping shared syntax gates |
| `release-drafter-contribution-contract.md` | Label-driven draft releases without a second changelog bot |
| `security-reporting-contribution-contract.md` | Private advisory-first vulnerability path |
| `changelog-refresh-contribution-contract.md` | Local Unreleased section helper distinct from Release Drafter |

## Expected sibling Stage 18 pages

| Page | Purpose |
|---|---|
| `compose-ipam-address-registry.md` | Unique static IPv4 allocation on `172.20.0.0/16` |
| `compose-resource-budget-contract.md` | Energy-aware CPU/memory limits for community Compose changes |
| `mcp-tool-sandbox-contribution-contract.md` | Safe community path for Playwright, filesystem, fetch, and memory |
| `beginner-quickstart-contribution-contract.md` | Portable-default onboarding without silent full-stack starts |
| `local-backup-restore-contribution-contract.md` | `tu-vm.sh backup` / `restore` format, rotation, and secret-safe archives |
| `helper-control-auth-contract.md` | `CONTROL_TOKEN`, header-first auth, and unauthenticated 401 behavior |
| `container-hardening-baseline-contract.md` | cap_drop / no-new-privileges / docker.sock review for Compose PRs |

## Expected sibling Stage 19 pages

| Page | Purpose |
|---|---|
| `tika-xml-config-contribution-contract.md` | Parsers, OCR, and timeouts in bind-mounted Tika XML |
| `prometheus-exporter-opt-in-contract.md` | Exporters stay off default start / energy budget |
| `compose-native-profiles-contract.md` | Align Compose `profiles:` with `tu-vm.sh` tier arrays |
| `grafana-dashboard-as-code-contract.md` | Provisioned JSON dashboards beside the datasource file |
| `nginx-login-rate-limit-contract.md` | Apply unused `login` zone to verified auth locations |
| `affine-backup-volume-coverage-contract.md` | Include AFFiNE volumes in the existing backup loop |
| `mcp-fetch-cidr-deny-contract.md` | Block Fetch from `172.20.0.0/16` and RFC1918/link-local |

## Expected sibling Stage 20 pages

| Page | Purpose |
|---|---|
| `tika-minio-processor-python-contribution-contract.md` | Watch/retry/status changes stay in the existing Alpine worker |
| `nginx-stub-status-exporter-contract.md` | Internal stub_status only, paired with opt-in nginx-exporter |
| `affine-redis-durability-contract.md` | Named volume + explicit AOF/RDB; do not share platform Redis |
| `ipv6-dual-stack-policy-contract.md` | IPv4-first; dual-stack is all-or-nothing |
| `systemd-user-unit-install-contract.md` | Optional oneshot `--user` unit; not a second supervisor |
| `wsl2-contributor-path-contract.md` | Windows contributors use WSL2 + the same bash scripts |
| `n8n-webhook-login-zone-split-contract.md` | Split locations so login can use `zone=login` without breaking webhooks |

## Expected sibling Stage 21 pages

| Page | Purpose |
|---|---|
| `nginx-upstream-dns-contract.md` | Prefer Compose service names with an explicit resolver |
| `platform-redis-durability-contract.md` | Make `redis_data` + AOF/RDB an explicit policy for `ai_redis` |
| `helper-uploader-module-contribution-contract.md` | Split `uploader.py` into importable modules |
| `multi-arch-image-policy-contract.md` | Digest pins that work on amd64 and arm64 |
| `podman-rootless-contributor-path-contract.md` | Optional Docker-compatible runtime lane |
| `apparmor-seccomp-profile-contract.md` | Optional LSM profiles on top of existing limits |
| `restic-borg-backup-backend-contract.md` | Optional backend behind `tu-vm.sh backup` / `restore` |

## Expected sibling Stage 22 pages

| Page | Purpose |
|---|---|
| `helper-index-image-bake-contract.md` | Bake apk/pip into `helper/Dockerfile`; keep the bind-mount |
| `postgres-wal-pitr-policy-contract.md` | Name dump-plus-volume as default; opt-in WAL behind `tu-vm.sh` |
| `image-provenance-cosign-contract.md` | Verify digest pins without replacing Trivy or safe-update |
| `compose-secrets-contribution-contract.md` | Optional `secrets:` / `*_FILE`; `.env` stays the clone path |
| `qdrant-snapshot-compaction-contract.md` | Official snapshot API plus volume tar; no second vector DB |
| `logging-driver-journald-contract.md` | json-file default; opt-in journald without Loki |
| `helper-compose-watch-contract.md` | Bind-mount first; optional `develop.watch` |

## Expected sibling Stage 23 pages

| Page | Purpose |
|---|---|
| `nginx-compose-configs-contract.md` | Shared TLS/header snippets; optional Compose `configs:` |
| `minio-object-versioning-ilm-contract.md` | Opt-in object history via existing `mc` |
| `read-only-rootfs-proxy-contract.md` | `read_only` + tmpfs for Nginx, not LSM |
| `postgres-statement-timeout-pooling-contract.md` | Real `-c` flags; optional PgBouncer later |
| `qdrant-hnsw-quantization-contract.md` | Fit RAG in the 1G limit without a second vector DB |
| `host-timezone-ntp-contract.md` | One `TU_VM_TZ`; host clock; no time container |
| `inter-service-network-isolation-contract.md` | Role bridges beyond a single `ai_network` |

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues (suggestion form) | Local voting DB / community API |
| Docs website | Static framework after Stage 3 gates (Starlight default) | Custom SSR community portal |
| Control plane | Existing Nginx dashboard + helper | Rebuilding ops UI as a SPA prerequisite |
| Nginx worker knobs | `nginx.conf` or one include; delete unused env | An Nginx control plane or vhost templating |
| Redis users | Official `--aclfile` on top of `requirepass` | Redis Cluster, Redis Stack, ACL UIs |
| Object SSE | MinIO SSE-S3 / `mc encrypt` | Vault, KES HA, a second object store |
| Host knobs | `sysctl.d` + opt-in `tu-vm.sh` | Privileged sysctl sidecars, `tuned` |
| Start gating | Compose `service_healthy` | `wait-for-it` or a custom orchestrator |
| Archive crypto | `age` wrap of existing tar | Making restic the default to fix a README claim |
| Probe intervals | Compose literals or interpolated 180s defaults | Decorative `HEALTH_CHECK_*` keys |
| Image CVEs / pins | Stage 4 Trivy + Stage 15 safe-update | Treating env honesty as supply-chain |

## Navigation for a future docs site

Map this folder to a docs section such as `Community`:

1. How to submit → status board → decision log → implemented showcase
2. Day-to-day tools → env honesty / Redis ACL / MinIO SSE
3. Host sysctl → depends_on health → backup wrap → probe intervals
4. Quality gates → merge playbook

When a static framework is adopted, **move or mount** these pages into the docs content root; do not maintain two editable copies.

Extend `stage-merge-playbook.md` through **Stage 24** when reconciling hubs so sibling pages from PRs #27–#49 are not lost.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../website-community-pages.md`](../website-community-pages.md) — lifecycle vocabulary
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
