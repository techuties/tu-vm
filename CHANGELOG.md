# Changelog

## SB/V0.1

This release focuses on security-by-default, clearer onboarding, and a better operator experience. Key themes: HTTPS-only access via Nginx, a new landing page at `tu.local`, explicit DNS handoff for Pi‑hole, safer defaults for services, and improved scripts with logging and health checks.

Highlights
- Landing page at `https://tu.local` with live service status. Links to Open WebUI, n8n, and Pi‑hole. Health endpoint exposed at `/health`.
- Hostnames standardized: `oweb.tu.local` (Open WebUI), `n8n.tu.local` (n8n), `pihole.tu.local` (Pi‑hole), `ollama.tu.local` (Ollama API). HTTP automatically redirects to HTTPS.
- Ollama and n8n are no longer exposed directly on host ports; traffic goes through Nginx with TLS. Qdrant remains internal by default.
- Scripts now write timestamped logs to the `logs/` directory and include richer diagnostics and health checks.

What changed
- Documentation (README)
  - Reworked prerequisites and workstation mapping with clearer steps and DNS flushing notes.
  - Updated access URLs to the new subdomains and clarified internal-only ports.
  - Added guidance for first-time n8n setup and Ollama usage via TLS.

- Compose and service defaults (`docker-compose.yml`)
  - Removed host port publishes for Ollama and n8n to enforce access via Nginx (`ollama.tu.local`, `n8n.tu.local`).
  - Qdrant left internal; add an authenticated proxy if external access is required.
  - n8n now uses schema `n8n` in Postgres and inherits base DB settings from environment variables for consistency.
  - Pi‑hole DNS upstreams set to independent providers by default (`1.1.1.1` and `9.9.9.9`), and `ServerIP` derives from `HOST_IP`.
  - Nginx mounts `nginx/html` to serve the new landing page.

- Nginx configuration (`nginx/conf.d/default.conf` and `nginx/nginx.conf`)
  - Introduced separate virtual hosts: `oweb.tu.local`, `n8n.tu.local`, `ollama.tu.local`, and `pihole.tu.local` with HTTP→HTTPS redirects.
  - Added a landing host on `tu.local` that serves `index.html` and proxies internal health endpoints for status badges.
  - Tuned proxy settings for long-lived Ollama connections (streaming/SSE) and reduced overly long timeouts elsewhere.
  - Tightened security headers, including a `Permissions-Policy` header.

- New landing page (`nginx/html/index.html`)
  - Minimal, modern dashboard listing services with live health badges pulling from same-origin endpoints.
  - Quick links to resources and a contributor credit section.

- Operational scripts (`scripts/*.sh`, `scripts/scripts.md`)
  - `start.sh` and `update.sh` now create timestamped logs under `logs/`, standardize hostnames, and ensure the Postgres `n8n` schema exists at startup.
  - `update.sh` tests key endpoints after updates, and `scripts.md` documents HTTPS-only access policy and troubleshooting commands.
  - `cleanup.sh` logs actions and removes an unused compose invocation.

Operator impact
- Access everything via HTTPS and the new subdomains; direct container ports for n8n and Ollama are closed by default.
- Use the landing page at `https://tu.local` to verify health quickly.
- Check `logs/start_*.log`, `logs/update_*.log`, and `logs/cleanup_*.log` for detailed run history and diagnostics.
