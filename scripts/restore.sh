#!/usr/bin/env bash
# restore.sh — restore a pg_dump backup into the running stack.
#
# Usage:
#     ./scripts/restore.sh ./backups/perspectiv-20260421-023000.dump
#
# Works for both backups taken by scripts/backup.sh AND pg_dump files
# produced on an external host (e.g. production → lab migration).
# Handles TimescaleDB hypertables via the pre/post restore hooks.
#
# WARNING: this DROPs and RECREATEs the target database. Take a fresh
# backup before running against a live deployment.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <path-to-dump>" >&2
    exit 2
fi

DUMP="$1"
if [[ ! -f "${DUMP}" ]]; then
    echo "error: dump file not found: ${DUMP}" >&2
    exit 1
fi

DB="${POSTGRES_DB:-perspectiv}"
USER="${POSTGRES_USER:-perspectiv_user}"

# Resolve DUMP to an absolute path, then make it readable inside the
# postgres container. We mount ./backups into /backups in compose, so
# we'll use that mount.
DUMP_ABS="$(readlink -f "${DUMP}")"
DEPLOY_DIR="$(cd "$(dirname "$0")/.."; pwd)"
if [[ "${DUMP_ABS}" == "${DEPLOY_DIR}/backups/"* ]]; then
    # Already inside the bind-mount — translate to container path.
    DUMP_IN_CONTAINER="/backups/$(basename "${DUMP_ABS}")"
else
    # Copy into the bind-mount so the container can see it.
    echo "[i] Copying ${DUMP_ABS} into ./backups for container access…"
    cp "${DUMP_ABS}" "${DEPLOY_DIR}/backups/"
    DUMP_IN_CONTAINER="/backups/$(basename "${DUMP_ABS}")"
fi

echo "About to DROP database '${DB}' and restore from ${DUMP}."
echo "(In-container path: ${DUMP_IN_CONTAINER})"
read -r -p "Type 'RESTORE' to confirm: " confirm
[[ "${confirm}" == "RESTORE" ]] || { echo "aborted."; exit 1; }

# ── Stop the app so there are no live connections ─────────────────────
docker compose stop perspectiv

# ── Drop and recreate the target database ─────────────────────────────
docker compose exec -T postgres psql -U "${USER}" -d postgres -c \
    "DROP DATABASE IF EXISTS \"${DB}\";"
docker compose exec -T postgres psql -U "${USER}" -d postgres -c \
    "CREATE DATABASE \"${DB}\";"

# ── TimescaleDB pre-restore hook ───────────────────────────────────────
# The timescaledb extension needs to be present before pg_restore runs,
# and the pre_restore() function puts the extension into a mode where
# a dump containing hypertable metadata can be loaded cleanly. Without
# this, hypertables in the dump end up as plain tables with broken
# chunk relationships.
docker compose exec -T postgres psql -U "${USER}" -d "${DB}" -c \
    "CREATE EXTENSION IF NOT EXISTS timescaledb;"
docker compose exec -T postgres psql -U "${USER}" -d "${DB}" -c \
    "SELECT timescaledb_pre_restore();"

# ── Restore ────────────────────────────────────────────────────────────
# --if-exists + --clean cleanly drops any objects that pre_restore may
# have flagged. --no-owner/--no-acl handles the user/role delta between
# prod and lab. Errors are reported but don't abort because many "already
# exists" notices appear on TimescaleDB's internal schemas.
docker compose exec -T postgres pg_restore \
    -U "${USER}" -d "${DB}" \
    --no-owner --no-acl \
    "${DUMP_IN_CONTAINER}" || true

# ── TimescaleDB post-restore hook ──────────────────────────────────────
# Re-enables hypertable enforcement and reconstructs the catalog. Safe
# to run even on a restore with no hypertables.
docker compose exec -T postgres psql -U "${USER}" -d "${DB}" -c \
    "SELECT timescaledb_post_restore();"

# ── Start the app back up ──────────────────────────────────────────────
docker compose start perspectiv

echo "[OK] Restore complete. App is back online."
echo "[i] Tail the logs to confirm: docker compose logs -f perspectiv"
