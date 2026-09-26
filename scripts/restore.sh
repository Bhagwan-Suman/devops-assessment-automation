#!/usr/bin/env bash
# Restores a dump into a FRESH database and compares it with the source.
# Usage: ./scripts/restore.sh [path/to/file.dump]   (default: backups/latest.dump)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT_DIR/.env" ]] && set -a && source "$ROOT_DIR/.env" && set +a

CONTAINER="${DB_CONTAINER:-hotel_db}"
DB_USER="${POSTGRES_USER:-hotel_app}"
SOURCE_DB="${POSTGRES_DB:-hotel}"
TARGET_DB="${RESTORE_DB:-hotel_restore}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
BACKUP_FILE="${1:-$BACKUP_DIR/latest.dump}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
psql_c() { docker exec "$CONTAINER" psql -U "$DB_USER" -d "$1" -v ON_ERROR_STOP=1 -tAc "$2"; }

if [[ "$TARGET_DB" == "$SOURCE_DB" ]]; then
  echo "ERROR: refusing to restore over the source database '$SOURCE_DB'." >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERROR: backup file not found: $BACKUP_FILE (run ./scripts/backup.sh first)" >&2
  exit 1
fi

# checksum check, if we have one
REAL_FILE="$(cd "$(dirname "$BACKUP_FILE")" && pwd)/$(readlink "$BACKUP_FILE" 2>/dev/null || basename "$BACKUP_FILE")"
if [[ -f "$REAL_FILE.sha256" ]]; then
  log "Verifying checksum"
  (cd "$(dirname "$REAL_FILE")" && \
    { sha256sum -c "$(basename "$REAL_FILE").sha256" 2>/dev/null || \
      shasum -a 256 -c "$(basename "$REAL_FILE").sha256"; }) >/dev/null \
    || { echo "ERROR: checksum mismatch - backup may be corrupt." >&2; exit 1; }
fi

log "Creating fresh database '$TARGET_DB'"
psql_c postgres "DROP DATABASE IF EXISTS $TARGET_DB WITH (FORCE);" >/dev/null 2>&1
psql_c postgres "CREATE DATABASE $TARGET_DB;" >/dev/null

log "Restoring $(basename "$REAL_FILE")"
docker exec -i "$CONTAINER" pg_restore -U "$DB_USER" -d "$TARGET_DB" \
  --no-owner --no-privileges --exit-on-error < "$BACKUP_FILE"

log "Comparing source ($SOURCE_DB) vs restored ($TARGET_DB)"
FAILED=0
printf "%-18s %10s %10s  %s\n" "TABLE" "SOURCE" "RESTORED" "RESULT"
for table in hotel_bookings booking_events; do
  src=$(psql_c "$SOURCE_DB" "SELECT count(*) FROM $table;")
  dst=$(psql_c "$TARGET_DB" "SELECT count(*) FROM $table;")
  if [[ "$src" == "$dst" ]]; then result="OK"; else result="MISMATCH"; FAILED=1; fi
  printf "%-18s %10s %10s  %s\n" "$table" "$src" "$dst" "$result"
done

# row counts can match while data differs - compare a content fingerprint too
FP_SQL="SELECT md5(string_agg(id::text || amount::text || status, ',' ORDER BY id)) FROM hotel_bookings;"
if [[ "$(psql_c "$SOURCE_DB" "$FP_SQL")" == "$(psql_c "$TARGET_DB" "$FP_SQL")" ]]; then
  echo "Data fingerprint (hotel_bookings): OK"
else
  echo "Data fingerprint (hotel_bookings): MISMATCH"; FAILED=1
fi

if [[ "$FAILED" -ne 0 ]]; then
  echo "RESTORE VERIFICATION FAILED" >&2
  exit 1
fi
log "Restore verified successfully into '$TARGET_DB'"
