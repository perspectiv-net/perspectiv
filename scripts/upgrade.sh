#!/usr/bin/env bash
# upgrade.sh — pull the latest Perspectiv image, run migrations, restart.
#
# Usage:
#     ./scripts/upgrade.sh              # upgrade to whatever PERSPECTIV_VERSION points to
#     ./scripts/upgrade.sh v1.2.0       # pin to a specific version
#
# Takes a safety backup first, pulls the new image, runs any startup
# migrations inside db_manager.init_database, then restarts the app.
# Rolling back is as simple as flipping PERSPECTIV_VERSION in .env and
# running this again.

set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-}"
if [[ -n "${TARGET}" ]]; then
    # Update .env in place with the new version tag
    if grep -q '^PERSPECTIV_VERSION=' .env; then
        sed -i.bak "s/^PERSPECTIV_VERSION=.*/PERSPECTIV_VERSION=${TARGET}/" .env
    else
        echo "PERSPECTIV_VERSION=${TARGET}" >> .env
    fi
    echo "[OK] .env updated — PERSPECTIV_VERSION=${TARGET}"
fi

echo "[1/4] Taking pre-upgrade backup…"
./scripts/backup.sh

echo "[2/4] Pulling latest image…"
docker compose pull perspectiv

echo "[3/4] Recreating container with new image…"
# --no-deps so we only restart perspectiv, not postgres/traefik.
docker compose up -d --no-deps perspectiv

echo "[4/4] Waiting for health-check…"
for i in {1..30}; do
    if docker compose ps perspectiv | grep -q "healthy"; then
        echo "[OK] Upgrade complete — app is healthy."
        exit 0
    fi
    sleep 2
done

echo "[WARN] App did not report healthy within 60s; check logs:"
echo "       docker compose logs -f perspectiv"
exit 1
