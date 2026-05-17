#!/usr/bin/env bash
# backup.sh — dump the Perspectiv PostgreSQL database to ./backups/
#
# Usage:
#     ./scripts/backup.sh              # writes backups/perspectiv-YYYYMMDD-HHMMSS.dump
#     ./scripts/backup.sh /mnt/remote  # writes to a different directory
#
# Intended to be run from cron on the deployment host:
#     # Daily at 02:30, keep last 14 days
#     30 2 * * * cd /opt/perspectiv-deploy && ./scripts/backup.sh && \
#                find ./backups -name '*.dump' -mtime +14 -delete

set -euo pipefail

DEST_DIR="${1:-$(cd "$(dirname "$0")/.."; pwd)/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="${DEST_DIR}/perspectiv-${STAMP}.dump"

mkdir -p "${DEST_DIR}"

# Run pg_dump inside the postgres container so we don't need psql on
# the host. -F c = custom format (compressed, parallelizable restore).
docker compose exec -T postgres pg_dump \
    -U "${POSTGRES_USER:-perspectiv_user}" \
    -d "${POSTGRES_DB:-perspectiv}" \
    -F c \
    --no-owner --no-acl \
    > "${FILE}"

SIZE_MB=$(du -m "${FILE}" | cut -f1)
echo "[OK] Wrote ${FILE} (${SIZE_MB} MB)"
