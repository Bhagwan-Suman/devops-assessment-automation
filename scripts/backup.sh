#!/usr/bin/env bash
# Creates a timestamped, compressed dump of the local Postgres database.
# Usage: ./scripts/backup.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT_DIR/.env" ]] && set -a && source "$ROOT_DIR/.env" && set +a

CONTAINER="${DB_CONTAINER:-hotel_db}"
DB_USER="${POSTGRES_USER:-hotel_app}"
DB_NAME="${POSTGRES_DB:-hotel}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

sha256() {  # writes a relative path so the checksum still works if the folder moves
  (cd "$(dirname "$1")" && if command -v sha256sum >/dev/null; then sha256sum "$(basename "$1")"; \
   else shasum -a 256 "$(basename "$1")"; fi)
}

# 1. is the database actually up?
if ! docker exec "$CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
  echo "ERROR: database in container '$CONTAINER' is not ready. Run: docker compose up -d" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# 2. dump in custom format (-Fc): compressed, and pg_restore can restore it selectively
log "Backing up '$DB_NAME' -> $BACKUP_FILE"
if ! docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" \
      --format=custom --no-owner --no-privileges > "$BACKUP_FILE"; then
  rm -f "$BACKUP_FILE"
  echo "ERROR: pg_dump failed, partial file removed." >&2
  exit 1
fi

# 3. a backup you never checked is just a hope - make sure the file is readable
if [[ ! -s "$BACKUP_FILE" ]] || \
   ! docker exec -i "$CONTAINER" pg_restore --list < "$BACKUP_FILE" >/dev/null; then
  echo "ERROR: backup file is empty or corrupt: $BACKUP_FILE" >&2
  exit 1
fi

sha256 "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
ln -sfn "$(basename "$BACKUP_FILE")" "$BACKUP_DIR/latest.dump"

# 4. housekeeping
find "$BACKUP_DIR" -name "${DB_NAME}_*.dump*" -type f -mtime +"$RETENTION_DAYS" -delete

log "Done. Size: $(du -h "$BACKUP_FILE" | cut -f1)"
log "Checksum: $BACKUP_FILE.sha256"
