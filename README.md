# TU-VM by TechUties - Private AI Automation Platform

Built by TechUties and its contributors, TU-VM turns a single machine into a professional-grade AI automation stack: private LLM chat, autonomous n8n workflow engineering, document intelligence, and secure service orchestration - all under your control.

The power of TU-VM is in how the parts work together: Open WebUI for operator-facing AI, MCP Gateway for controlled tool access, LangGraph Supervisor for guarded workflow writes, and n8n for production automation. You get fast iteration, strong guardrails, and a reproducible system that can be updated safely without losing your operational context.

### Key Features
- Local AI Operations   - Run AI models and workflows without cloud dependencies
- Complete Privacy      - All data stays on your machine with configurable access controls
- Document Intelligence - Process thousands of document formats with advanced OCR
- Workflow Automation   - Create and run complex AI pipelines with visual tools
- LLM-Driven Workflow Engineering - AI models build, debug, and maintain n8n workflows autonomously
- One-Command Control   - Manage your entire AI stack through a simple interface

### Data Protection
- Automated Backups
  - Scheduled daily snapshots of all systems
  - Pre-update safety backups
  - Compressed and encrypted storage
  - Configurable retention policies
- Recovery Options
  - Point-in-time system restoration
  - Selective service recovery
  - Data integrity verification
  - Quick disaster recovery

### System Requirements
- Minimum: 4GB RAM, 20GB storage, Ubuntu Server 22.04+
- Recommended: 8GB+ RAM, 50GB+ SSD storage
- Supported OS: Ubuntu Server (LTS versions)
- Docker: Version 20.10 or higher
- Network: Local network access for secure operations

Perfect for developers and researchers who need a reliable, private environment for AI development without the complexity of manual setup or the risks of cloud services.

<img width="754" height="735" alt="tu-vm_dashboard" src="https://github.com/user-attachments/assets/8129c82c-748b-40be-95f2-d719b597d993" />

The Dashboard

Model available through Open WebUI
nebulity.techuties.com/b2r8zn6/

## Architecture

```
                          ┌─────────────────────────────┐
                          │       Nginx (443/80)        │
                          │    Reverse Proxy + TLS      │
                          └──────┬──────┬──────┬───────┘
                                 │      │      │
              ┌──────────────────┘      │      └──────────────────┐
              ▼                         ▼                         ▼
     ┌────────────────┐      ┌────────────────┐      ┌────────────────┐
     │   Open WebUI   │      │      n8n       │      │    AFFiNE      │
     │  (Chat + RAG)  │      │  (Workflows)   │      │ (Collaboration)│
     └──────┬─────────┘      └──────┬─────────┘      └────────────────┘
            │                       │
            │   ┌───────────────────┘
            ▼   ▼
     ┌────────────────┐     ┌─────────────────────────┐
     │  MCP Gateway   │────▶│  LangGraph Supervisor   │
     │ (Tool Router)  │◀────│ (Write Verification)    │
     └──────┬─────────┘     └─────────────────────────┘
            │
     ┌──────┼──────┬──────────────┐
     ▼      ▼      ▼              ▼
  ┌──────┐┌─────┐┌──────┐ ┌───────────┐
  │ n8n  ││ KB  ││AFFiNE│ │  Qdrant   │
  │ API  ││MinIO││ API  │ │(Vectors)  │
  └──────┘└─────┘└──────┘ └───────────┘
                               ▲
     ┌─────────────┐           │
     │ PostgreSQL   │───────────┘
     │ (Primary DB) │
     └──────┬──────┘
            │
     ┌──────┴──────┐
     │    Redis     │
     │   (Cache)    │
     └─────────────┘
```

## Services

### Tier 1: Always Running (Core)

| Service | Container | Port (internal) | Purpose |
|---------|-----------|-----------------|---------|
| [PostgreSQL](https://www.postgresql.org/) | `ai_postgres` | 5432 | Primary database for Open WebUI, n8n, and platform data |
| [Redis](https://redis.io/) | `ai_redis` | 6379 | Cache layer for Open WebUI sessions and config |
| [Open WebUI](https://docs.openwebui.com/) | `ai_openwebui` | 8080 | AI chat interface with RAG, model profiles, tool integration |
| [Nginx](https://nginx.org/) | `ai_nginx` | 80, 443 | Reverse proxy, TLS termination, rate limiting |
| [Pi-hole](https://pi-hole.net/) | `ai_pihole` | 53, 80 | DNS ad-blocking and network security |
| Helper API | `ai_helper_index` | 9001 | Landing page, dashboard status, service controls (Flask; proxied only via Nginx) |

### Tier 2: On-Demand (Start via Dashboard)

| Service | Container | Port (internal) | Purpose |
|---------|-----------|-----------------|---------|
| [n8n](https://docs.n8n.io/) | `ai_n8n` | 5678 | Workflow automation with PostgreSQL backend |
| [Ollama](https://ollama.com/) | `ai_ollama` | 11434 | Local LLM inference engine |
| [Qdrant](https://qdrant.tech/documentation/) | `ai_qdrant` | 6333 | Vector database for RAG embeddings |
| [MinIO](https://min.io/docs/minio/linux/index.html) | `ai_minio` | 9000, 9001 | S3-compatible object storage |
| [Apache Tika](https://tika.apache.org/) | `ai_tika` | 9998 | Document processing with OCR support |
| [AFFiNE](https://affine.pro/) | `ai_affine` | 3010 | Collaborative knowledge workspace |
| [MCP Gateway](#mcp-gateway) | `ai_mcp_gateway` | 9002 | Tool router for LLM-to-service communication |
| [LangGraph Supervisor](#langgraph-supervisor) | `ai_langgraph_supervisor` | 9010 | Write operation verification and audit |
| Tika-MinIO Processor | `tika_minio_processor` | — | Automated document extraction pipeline |
| [Browserless Chromium](https://github.com/browserless/browserless) | `ai_browserless` | 3000 | Optional headless browser for Open WebUI web search when using Playwright |

### Service Dependencies

```
Open WebUI ──▶ PostgreSQL (users, chats, settings)
           ──▶ Redis (session cache, config)
           ──▶ Qdrant (RAG embeddings)
           ──▶ Ollama (local LLM inference)
           ──▶ Browserless (optional; Playwright web search when enabled)
           ──▶ MCP Gateway (tool calls via OpenAPI)

n8n ──▶ PostgreSQL (workflows, credentials, schema: n8n)

MCP Gateway ──▶ n8n API (workflow CRUD, executions)
            ──▶ MinIO (knowledge base storage)
            ──▶ Tika (document extraction)
            ──▶ LangGraph Supervisor (write verification)

AFFiNE ──▶ affine_postgres (separate PG instance, pgvector)
       ──▶ affine_redis (dedicated Redis)
```

## MCP Gateway

The MCP Gateway (`mcp-gateway/`) is a FastAPI application that acts as a secure tool router between Open WebUI's LLMs and backend services (n8n, MinIO knowledge base, AFFiNE). It exposes an OpenAPI spec that Open WebUI consumes as tool definitions.

### Capabilities

- **22 tools** exposed via OpenAPI (n8n workflow CRUD, executions, diagnostics, knowledge base, references)
- **541 n8n node type definitions** with full parameter schemas, credential requirements, and version info
- **Pre-flight validation** of workflow payloads before sending to n8n
- **Smart parameter filtering** by operation/mode to reduce context window usage
- **Built-in reference docs** for expressions, common pitfalls, workflow templates, and credential wiring
- **Webhook test execution** within the diagnose tool for end-to-end verification
- **Proof-of-execution** signing with HMAC for audit trails
- **Dead letter queue** for failed operations
- **Rate limiting** per tenant (requests/min, concurrency, daily writes)

### Key Tools

| Tool | Type | Purpose |
|------|------|---------|
| `n8n_list_workflows` | Read | List active (non-archived) workflows |
| `n8n_create_workflow` | Write | Create a new workflow |
| `n8n_update_workflow` | Write | Update an existing workflow (PUT) |
| `n8n_diagnose_workflow` | Read | Validate structure + check executions + optional webhook test |
| `n8n_get_node_types` | Read | Look up node parameter schemas with operation filtering |
| `n8n_reference` | Read | Expression syntax, pitfalls, templates, credential docs |
| `n8n_list_credentials` | Read | Available credentials (names/types only) |
| `kb_search` | Read | Search indexed knowledge base entries |

### Configuration

| Variable | Required | Purpose |
|----------|----------|---------|
| `MCP_GATEWAY_TOKEN` | Yes | Bearer token for all API requests |
| `N8N_API_KEY` | Yes | n8n API authentication |
| `N8N_INTERNAL_URL` | Yes | n8n container URL (default: `http://ai_n8n:5678`) |
| `MCP_PROOF_SIGNING_KEY` | Yes | HMAC key for proof-of-execution signatures |
| `KB_MINIO_ACCESS_KEY` | If KB enabled | MinIO access for knowledge base |
| `KB_MINIO_SECRET_KEY` | If KB enabled | MinIO secret for knowledge base |

## LangGraph Supervisor

The LangGraph Supervisor (`langgraph-supervisor/`) provides a verification layer for all write operations (create, update, delete, activate) going through the MCP Gateway. It ensures deterministic execution with audit trails.

### Features

- **Write verification** — all n8n write operations pass through the supervisor before execution
- **Audit logging** — every operation is logged with timestamps, actor, and result
- **Deduplication** — prevents duplicate operations within a configurable window
- **Checkpoint state** — tracks operation history for rollback awareness

### Configuration

| Variable | Required | Purpose |
|----------|----------|---------|
| `MCP_GATEWAY_URL` | Yes | URL of the MCP Gateway |
| `MCP_GATEWAY_TOKEN` | Yes | Shared token with MCP Gateway |
| `LANGGRAPH_SUPERVISOR_TOKEN` | No | Dedicated Bearer token for `/execute`; if unset or empty, the supervisor accepts the same token as `MCP_GATEWAY_TOKEN` |
| `LANGGRAPH_STRICT_VERIFY` | No | Require verification for all writes (default: true) |

## Cross-function gates

These are the checks that span **Open WebUI → Nginx → MCP Gateway → LangGraph Supervisor → n8n/MinIO/AFFiNE** (and the proof trail), so autonomous tool use stays aligned with what actually ran.

### Runtime (supervisor delegation)

- **n8n write-class tools** (create/update/activate/deactivate/delete workflows, webhook test runs, etc.) are **not** executed on the first hop from the gateway alone when `LANGGRAPH_SUPERVISOR_ENABLED` is true. The gateway **delegates** to the LangGraph Supervisor, which validates, dedupes, and audits, then calls the gateway again with `X-LangGraph-Supervised: 1` so the real n8n call runs without looping.
- If the supervisor is unavailable and `LANGGRAPH_SUPERVISOR_REQUIRED` is true, those writes **fail closed** (no silent bypass).
- Optional **write approval tokens**, **tenant rate limits**, **daily write caps**, and the n8n **circuit breaker** add further policy on the gateway.

### Proof quality (rollout gate)

- `scripts/rollout-gates.sh` reads the MCP Gateway **proof store** and checks that, over a time window, **claimed** operations stay consistent with **supervisor verification** (default thresholds: 99.9% verified, ≤0.1% mismatch). Use this before or after a release if you rely on supervised writes. The default proof path assumes the Docker volume name prefix `tu-vm_`; pass an explicit path if your Compose project name differs.

### Smoke test (edge path)

- `scripts/langgraph-e2e-smoke.sh` exercises **`/api/langgraph/health`**, **`/api/mcp/health`**, and a **read-only** `n8n_list_workflows` call through `https://oweb.tu.lan` (or `BASE_URL`), confirming Nginx → LangGraph → Gateway → n8n.

## Workflow Operator

The **Workflow Operator** is an Open WebUI model profile that enables LLMs to autonomously build, debug, and maintain n8n workflows. It connects an Anthropic LLM (via a custom pipe function) to the MCP Gateway's tool suite.

### How It Works

1. User asks the Workflow Operator to create a workflow (e.g., "Build an SEO audit workflow")
2. The LLM calls `n8n_list_workflows` to check for existing matches
3. Looks up node type schemas via `n8n_get_node_types` with operation filtering
4. Consults `n8n_reference` for expression syntax and templates
5. Creates/updates the workflow via `n8n_create_workflow` or `n8n_update_workflow`
6. Runs `n8n_diagnose_workflow` (with optional webhook test) to verify correctness
7. If errors are found, fixes them automatically and re-diagnoses

### Enforced Behaviors (via System Prompt)

- Never asks for confirmation on create/update — executes immediately
- Never defers to the n8n UI — retries with corrected parameters on failure
- Always looks up node types before building — never guesses parameters
- Always reuses existing workflows — never creates duplicates
- Prefers native n8n nodes over Code nodes
- Runs post-creation diagnosis on every workflow

## Project Structure

```
.
├── docker-compose.yml          # Service orchestration (all services)
├── env.example                 # Environment template (copy to .env)
├── tu-vm.sh                    # Main control script
├── README.md                   # This documentation
│
├── mcp-gateway/                # MCP Gateway service
│   ├── Dockerfile
│   ├── app.py                  # FastAPI application (22 tools)
│   └── requirements.txt
│
├── langgraph-supervisor/       # Write verification service
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
│
├── qm-llm-bridge/              # Optional Queue Manager bridge (source-only, not enabled by default)
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
│
├── tika-minio-processor/       # Document extraction pipeline
│   ├── Dockerfile
│   ├── universal_auto_processor.py
│   ├── universal_processor.py
│   ├── tika_processor.py
│   └── requirements.txt
│
├── helper/                     # Landing page + dashboard API
│   ├── uploader.py
│   └── chat-context/           # Seed context for AI assistants
│
├── nginx/                      # Reverse proxy configuration
│   ├── nginx.conf
│   ├── conf.d/default.conf     # Vhost routing + rate limiting
│   ├── html/                   # Landing page + error pages
│   └── dynamic/                # Runtime-generated allowlists
│
├── monitoring/                 # Prometheus + Grafana configs
├── pihole/                     # Pi-hole dnsmasq config
├── tika-config/                # Apache Tika XML config
│
├── scripts/
│   ├── safe-update.sh          # Safe update with backup + rollback
│   ├── daily-checkup.sh        # Daily health + pipeline integrity
│   ├── pre-push-check.sh       # Local smoke gate before push
│   ├── changelog-refresh.sh    # Refresh Unreleased from git log
│   ├── extract-n8n-node-types.sh  # Extract node schemas from n8n
│   ├── langgraph-e2e-smoke.sh  # End-to-end smoke test
│   ├── rollout-gates.sh        # Deployment gate checks
│   ├── init-openwebui.sh       # Open WebUI init hook
│   ├── sync-openwebui-minio.sh # Open WebUI <-> MinIO file sync
│   ├── switch-pdf-loader.sh    # Tika / PyMuPDF toggle
│   ├── seed-chat-context.sh    # Seed assistant context
│   └── extend-disk.sh          # Disk expansion helper
│
├── ssl/                        # Self-signed TLS certs (gitignored)
└── backups/                    # Timestamped backups (gitignored)
```

`qm-llm-bridge/` is intentionally shipped as source-only in this repo. It is not wired into `docker-compose.yml` or Nginx by default.

## Energy Optimization (Tiered Architecture)

```
┌─────────────────────────────────────────────┐
│ TIER 1: Always Running (Core - ~2-3% CPU)  │
├─────────────────────────────────────────────┤
│ • PostgreSQL, Redis (databases)            │
│ • Open WebUI (UI only, no AI backend)       │
│ • Nginx, Pi-hole, Helper API              │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ TIER 2: Dashboard Controlled (On-Demand)   │
├─────────────────────────────────────────────┤
│ • Ollama (AI backend) [Start/Stop Button]   │
│ • n8n (workflow automation) [Start/Stop]     │
│ • MCP Gateway + LangGraph [Start/Stop]      │
│ • MinIO (object storage) [Start/Stop]       │
│ • Qdrant (vector database) [Start/Stop]      │
│ • Tika (document processing) [Start/Stop]    │
│ • AFFiNE (collaboration) [Start/Stop]       │
│ • Browserless (Playwright / web search) [Start/Stop] │
└─────────────────────────────────────────────┘
```

### Performance

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| CPU Usage | 30% | 2-3% | 90% reduction |
| Load Average | 4.20 | 0.8-1.0 | 75% reduction |
| Memory Usage | 2.8GB | 1.5-2.0GB | 30-45% reduction |
| Battery Life | 3-4 hours | 8-10 hours | 150% improvement |

## Installation

### Prerequisites
- **Host OS**: Ubuntu Server 22.04+ (LTS recommended)
- **RAM**: Minimum 4GB, recommended 8GB+
- **Storage**: 20GB+ free space
- **Docker**: Version 20.10+ with Docker Compose v2
- **Ports**: 80, 443 (web), 53 (DNS, optional)

### Steps

#### 1. Install Docker
```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
sudo reboot
```

#### 2. Clone and Setup
```bash
git clone https://github.com/techuties/tu-vm.git
cd tu-vm
./tu-vm.sh setup
```

This automatically:
- Creates `.env` from `env.example`
- Auto-detects and sets `HOST_IP`
- Generates secure passwords and keys for all services
- Generates self-signed SSL certificates

**Or manually:**
```bash
cp env.example .env
./tu-vm.sh generate-secrets   # Replace all CHANGE_ME placeholders
```

#### 3. Configure External API Keys (if needed)

These are **not** auto-generated and must be set manually in `.env` if you use the corresponding features:

| Variable | When Needed |
|----------|-------------|
| `N8N_API_KEY` | Always (create in n8n UI: Settings > API) |
| `AFFINE_API_TOKEN` | If using AFFiNE MCP integration |

#### 4. Start Services
```bash
./tu-vm.sh start
```

#### 5. Enable Secure Access
```bash
sudo ./tu-vm.sh secure
```

### Post-Setup: Workflow Operator

To enable the LLM-to-n8n pipeline after initial setup:

1. Start n8n and create an API key (Settings > API)
2. Set `N8N_API_KEY` in `.env`
3. Start the MCP Gateway and LangGraph Supervisor
4. Extract n8n node types: `./scripts/extract-n8n-node-types.sh`
5. The Workflow Operator model profile should already exist in Open WebUI (created during setup)

## Access Points

| Service | URL | Notes |
|---------|-----|-------|
| Landing Page | `https://<vm-IP>` | Dashboard with service controls |
| Open WebUI | `https://oweb.tu.lan` | AI chat interface |
| n8n | `https://n8n.tu.lan` | Workflow editor |
| AFFiNE | `https://affine.tu.lan` | Collaborative workspace |
| MinIO Console | `https://minio.tu.lan` | Object storage GUI |
| MinIO API | `https://api.minio.tu.lan` | S3-compatible API |
| Pi-hole | `https://pihole.tu.lan` | DNS admin |

All services are accessed through Nginx. Direct container ports are bound to `127.0.0.1` only.

## Control Commands

### Basic Operations
```bash
./tu-vm.sh start              # Start all services
./tu-vm.sh stop               # Stop all services
./tu-vm.sh restart            # Restart all services
./tu-vm.sh status             # Show service status
./tu-vm.sh logs [service]     # Show service logs
```

### Energy-Efficient Mode
```bash
./tu-vm.sh start --tier1              # Start core services only
./tu-vm.sh start-service ollama       # Start a specific service
./tu-vm.sh stop-service ollama        # Stop a specific service
```

### Access Control
```bash
sudo ./tu-vm.sh secure        # Local network only (recommended)
sudo ./tu-vm.sh public        # Allow internet access
sudo ./tu-vm.sh lock          # Block all external access
```

### Maintenance
```bash
./tu-vm.sh update-check               # Unified check for updates
sudo ./tu-vm.sh update                # Unified safe update (recommended)
sudo ./tu-vm.sh update-rollback       # Roll back to previous snapshot
./tu-vm.sh backup                     # Create manual backup
sudo ./tu-vm.sh restore file.tar.gz   # Restore from backup
```

### Diagnostics
```bash
./tu-vm.sh health             # Check service health
./tu-vm.sh diagnose           # Run comprehensive diagnostics
./scripts/daily-checkup.sh    # Run daily health + pipeline integrity check
./scripts/pre-push-check.sh   # Local smoke checks before push
./scripts/rollout-gates.sh    # Proof-store quality gate (supervised writes vs verification)
./scripts/langgraph-e2e-smoke.sh  # End-to-end LangGraph + MCP through Nginx
./scripts/changelog-refresh.sh --write  # Refresh CHANGELOG Unreleased
```

## Safe Update System

The `scripts/safe-update.sh` script provides a zero-downtime update process:

1. **`--check`** — Identifies available Docker image updates without pulling
2. **`--apply`** — Full update cycle:
   - Backs up PostgreSQL database, `docker-compose.yml`, and Open WebUI configs
   - Pulls new images and pins to SHA256 digests
   - Restarts services one-by-one with health checks
   - Re-extracts n8n node types and reloads MCP Gateway
   - Verifies full pipeline integrity (RAG, model profiles, tools)
3. **`--rollback`** — Restores the previous `docker-compose.yml` and restarts

Docker images for critical services are pinned to SHA256 digests in `docker-compose.yml` to prevent unexpected breakage from `:latest` tag changes.

## Document Processing

### Apache Tika Pipeline (Default)

Upload files to MinIO bucket `tika-pipe` and they are automatically processed:

- **Supported**: PDF, DOC(X), XLS(X), PPT(X), images (with OCR), archives (ZIP/TAR)
- **Output**: `.txt` file alongside original with extracted text
- **OCR**: Automatic for scanned documents and images

### Open WebUI Integration

Files uploaded to Open WebUI are synced to MinIO via `scripts/sync-openwebui-minio.sh`, processed by Tika, and the `.txt` output is synced back.

**Web search and Playwright:** The stock Open WebUI image does not ship Playwright browser binaries. Default stack uses `WEB_LOADER_ENGINE=safe_web` (HTTP fetch). For JavaScript-heavy pages, start the optional Tier 2 service **`browserless`** (`./tu-vm.sh start-service browserless`), set `BROWSERLESS_TOKEN` and `PLAYWRIGHT_WS_URL=ws://browserless:3000/chromium/playwright?token=...` plus `WEB_LOADER_ENGINE=playwright` in `.env`, recreate `open-webui`, and align **Admin → Settings → Web search** (saved settings override env until changed). You can instead use a hosted Browserless URL (`wss://…/chromium/playwright?token=…`) without running the local service.

## Security

### Secrets Management

All secrets are managed through `.env` (gitignored). Running `./tu-vm.sh setup` or `./tu-vm.sh generate-secrets` replaces all placeholder values with cryptographically random strings.

**Important:** `docker-compose.yml` contains fallback default values (e.g., `${POSTGRES_PASSWORD:-ai_password_2024}`) that are used only if `.env` is missing or incomplete. These exist to prevent Docker Compose from failing to parse, but **they must never be used in production**. Always run `generate-secrets` before first start.

### What is protected

| Asset | Protection |
|-------|------------|
| `.env` | Gitignored, contains all secrets |
| `ssl/` | Gitignored, auto-generated self-signed certs |
| `backups/` | Gitignored, local only |
| `mcp-gateway/n8n_node_types.json` | Gitignored (4.5MB auto-generated) |
| `nginx/dynamic/` | Gitignored (runtime allowlists) |
| Docker volumes | Not in repo, managed by Docker |

### What requires manual attention

| Item | Action |
|------|--------|
| `N8N_API_KEY` | Create in n8n UI, paste into `.env` |
| `AFFINE_API_TOKEN` | Create in AFFiNE UI, paste into `.env` |
| `CONTROL_TOKEN` | Auto-generated, paste into dashboard for service control |
| MinIO root password | Auto-generated, but change if exposed to network |
| Pi-hole password | Auto-generated, access via `https://pihole.tu.lan` |

### Network Security

| Level | Command | Use Case |
|-------|---------|----------|
| Secure | `sudo ./tu-vm.sh secure` | Local network only (recommended) |
| Public | `sudo ./tu-vm.sh public` | Internet-accessible |
| Locked | `sudo ./tu-vm.sh lock` | No external access |

### Security Features
- Container network isolation (172.20.0.0/16)
- UFW-based firewall with allowlisting
- TLS encryption on all external endpoints
- SCRAM-SHA-256 for PostgreSQL authentication
- Token-based API auth (MCP Gateway, LangGraph, Control API)
- HMAC proof-of-execution signing
- Rate limiting on MCP and LangGraph endpoints
- Constant-time token comparison (prevents timing attacks)
- Webhook path traversal validation
- No secrets in git history

## Monitoring

### Daily Health Checks (9:00 AM cron)

The `scripts/daily-checkup.sh` script runs automatically and checks:

- **Container health** — detects down, unhealthy, and restarting services
- **Log error analysis** — scans 24h of logs for critical/warning errors
- **Update detection** — checks for OS and Docker image updates
- **Resource monitoring** — CPU, memory, disk, battery
- **Pipeline integrity** — verifies MCP Gateway node types, RAG config, model profiles

### Dashboard Alerts

| Priority | Color | Examples |
|----------|-------|---------|
| Critical | Red | Services down, critical errors, low battery |
| High | Orange | Unhealthy services, memory pressure |
| Medium | Blue | Public access enabled, battery warnings |
| Low | Green | System status, power-saving tips |

## Backup & Restore

### Automatic Backups
```bash
./tu-vm.sh backup              # Manual backup
./scripts/safe-update.sh --apply   # Automatic pre-update backup
```

### Backup Contents
- Full PostgreSQL dump
- Configuration: `.env`, `docker-compose.yml`, `nginx/`, `ssl/`
- Volume data: PostgreSQL, Redis, Qdrant, Pi-hole
- Compressed timestamped `.tar.gz` files

### Restore
```bash
sudo ./tu-vm.sh restore backups/backup_YYYYMMDD_HHMMSS.tar.gz
```

## Troubleshooting

### Services Not Starting
```bash
./tu-vm.sh status
docker compose logs <service-name>
docker compose config   # Validate compose file
```

### MCP Gateway Issues
```bash
docker logs ai_mcp_gateway --tail 50
# Check node types loaded:
docker exec ai_mcp_gateway curl -s http://localhost:9002/health
# Reload node types after n8n update:
./scripts/extract-n8n-node-types.sh
```

### Workflow Operator Not Working
```bash
# Check model exists in Open WebUI database:
docker exec ai_postgres psql -U ai_admin -d ai_platform -c "SELECT id, base_model_id FROM model WHERE id = 'workflow-operator';"

# Check tool connectivity:
docker exec ai_mcp_gateway curl -s http://localhost:9002/openapi-tools.json | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())['paths']), 'tools')"
```

### Open WebUI STT Error
```bash
./tu-vm.sh check-openwebui-audio
./tu-vm.sh fix-openwebui-audio whisper-1
```

### RAG Embeddings Not Working
```bash
# Verify RAG config hasn't drifted back to Ollama:
docker exec ai_postgres psql -U ai_admin -d ai_platform -c "SELECT key, value FROM config WHERE key = 'rag';" | head -5
```

## Production Notes

This project is designed to be **safe-by-default on a home network (LAN)**.

If exposing to the public internet:
- Run `./tu-vm.sh generate-secrets` to replace all default passwords
- Use real TLS certificates (not self-signed)
- Keep admin ports on localhost; only expose via Nginx
- Rotate `CONTROL_TOKEN` regularly
- Review firewall rules with `sudo ./tu-vm.sh secure`
- Set `N8N_REQUIRE_API_KEY=true` (default)

## Quick References
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

### External Documentation
- [Open WebUI Docs](https://docs.openwebui.com/)
- [n8n Documentation](https://docs.n8n.io/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
- [Apache Tika](https://tika.apache.org/)
- [AFFiNE](https://affine.pro/docs)

---

**Security Level**: HIGH - Token-based auth, TLS, network isolation, HMAC signing
**Complexity**: LOW - One script for everything (`tu-vm.sh`)
**Maintenance**: EASY - Safe updates with backup/rollback, daily health checks
