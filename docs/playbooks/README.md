# TU-VM playbooks

Concise recipes for operators. Full command references remain in `README.md` and `./tu-vm.sh help`.

Quick anchors for links from the landing dashboard:

<a id="playbook-safe-update"></a>

## Safe stack update

1. `./tu-vm.sh backup` (or ensure recent backups exist).
2. `./tu-vm.sh update-check` then `./tu-vm.sh update` for the supported full-stack flow.
3. `./scripts/smoke-test.sh --live` after tier 1 is healthy (HTTPS via nginx).

<a id="playbook-recovery"></a>

## Recovery after a bad change

1. `./tu-vm.sh update-rollback` if an update snapshot exists; otherwise restore from `backups/` per README.
2. `./tu-vm.sh diagnose` for compose and endpoint visibility.
3. `./scripts/check-config.sh --strict` once `.env` and TLS paths are restored.

<a id="playbook-pihole-tailscale"></a>

## Pi-hole on LAN plus Tailscale

1. Set `PIHOLE_DNS_BIND_ADDR=0.0.0.0` in `.env` when DNS must answer on tailnet and LAN (see comments in `env.example`).
2. `./tu-vm.sh sync-dns` after `HOST_IP` / `TAILSCALE_IP` / `DNS_RECORD_IP` are correct.
3. `./tu-vm.sh dns-clients` for client/router hints.

<a id="playbook-mcp-smoke"></a>

## MCP and automation smoke

1. Ensure tier 1 is up and optional Tier-2 MCP images are built if you use them.
2. `./tu-vm.sh chain-smoke` exercises Open WebUI → MCP → n8n where configured.
3. `./scripts/helper-contract-check.sh` when `helper_index` is running validates helper JSON and unauthenticated control **401** behavior.
