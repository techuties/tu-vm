# AGENTS.md

## Cursor Cloud specific instructions

### Overview

TU-VM is a Docker Compose-based private AI platform. There is no application source code to compile; all services run as pre-built Docker containers orchestrated by `docker-compose.yml`. The two custom Python components are:

- `helper/uploader.py` — Flask helper API for the landing page dashboard (runs inside `python:3-alpine` container)
- `tika-minio-processor/` — Python document processing service (built from its own `Dockerfile`)

### Starting services

- **Tier 1 (always-on core):** `sudo docker compose up -d postgres redis open-webui pihole nginx helper_index`
- **Tier 2 (on-demand):** start individually, e.g. `sudo docker compose up -d ollama`
- The main control script `./tu-vm.sh start` automates Tier 1 startup plus SSL cert generation and `.env` creation, but requires Docker socket access and may invoke host-level operations (cron, rclone) that are unnecessary in a cloud agent context.

### Prerequisites for services to start

1. `.env` must exist (copy from `env.example`, then generate secrets with `./tu-vm.sh generate-secrets` or manually).
2. SSL certificates must exist at `ssl/nginx.crt` and `ssl/nginx.key` (generate with `openssl` — see `generate_ssl_certificates()` in `tu-vm.sh`).
3. `nginx/dynamic/control_allowlist.conf` must exist (Nginx will fail to start without it). A minimal valid file: `allow 127.0.0.1;\ndeny all;`.

### Docker-in-Docker gotchas (cloud agent environment)

- Docker daemon needs `fuse-overlayfs` storage driver and `iptables-legacy`.
- Use `sudo docker compose ...` (the ubuntu user may not be in the docker group by default).
- Port 53 must be free for Pi-hole; port 80/443 for Nginx.
- Open WebUI takes ~60-120s to become healthy on first boot (pip installs, DB migrations).

### Linting

- **Bash scripts:** `bash -n <script>` for syntax; no shellcheck config in repo.
- **Python:** `python3 -m py_compile <file>` for syntax validation.
- **Docker Compose:** `sudo docker compose config --quiet` to validate `docker-compose.yml`.

### Testing

No automated test suite exists. Validation is done by:
1. Checking container health: `sudo docker compose ps`
2. Hitting API endpoints: `curl -sk https://127.0.0.1/status/full -H "Host: tu.local"`
3. Individual status endpoints: `/status/oweb`, `/status/pihole`, `/status/ollama`, `/status/minio`, etc.

### Key files

- `docker-compose.yml` — service definitions
- `env.example` — environment variable template
- `tu-vm.sh` — main control script (see `README.md` for all commands)
- `nginx/conf.d/default.conf` — Nginx virtual host config
- `nginx/html/index.html` — landing page dashboard
- `helper/uploader.py` — Flask helper API
