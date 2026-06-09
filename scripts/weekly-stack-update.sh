#!/usr/bin/env bash
# Weekly full-stack update for cron (non-interactive).
# Runs: tu-vm.sh update (backup, OS packages, image pull, compose recreate, health gates).
#
# Requires root. Either:
#   - run this script from root's crontab, or
#   - allow passwordless sudo for tu-vm.sh update (see scripts/tu-vm-update.sudoers.example).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$ROOT_DIR/logs/weekly-update.log"
LOCK_FILE="/tmp/tu-vm-weekly-update.lock"
TU_VM="$ROOT_DIR/tu-vm.sh"

mkdir -p "$ROOT_DIR/logs"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [weekly-update] $*"
    echo "$msg" >> "$LOG_FILE"
    echo "$msg"
}

exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "Skipped: another weekly update is already running"
    exit 0
fi

cd "$ROOT_DIR"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
    log "ERROR: .env missing at $ROOT_DIR/.env — aborting (will not recreate secrets from env.example)"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    log "ERROR: Docker is not reachable"
    exit 1
fi

log "Starting scheduled full-stack update"

run_update() {
    if [[ $EUID -eq 0 ]]; then
        "$TU_VM" update
        return
    fi
    if sudo -n "$TU_VM" update; then
        return
    fi
    log "ERROR: need root privileges. Install scripts/tu-vm-update.sudoers.example or schedule this job in root's crontab."
    exit 1
}

if run_update >> "$LOG_FILE" 2>&1; then
    log "Scheduled update finished successfully"
else
    ec=$?
    log "ERROR: scheduled update failed (exit $ec). See $LOG_FILE and $ROOT_DIR/tu-vm.log"
    exit "$ec"
fi
