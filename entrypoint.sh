#!/bin/bash
set -e

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT_TCP_PORT="${MONGO_PORT_TCP_PORT:-27017}"
BACKUP_DIR="/tmp/backup"

if [ -n "$PASS_DB" ] && [ -n "$USER_DB" ]; then
    URI="mongodb://${USER_DB}:${PASS_DB}@${MONGO_HOST}:${MONGO_PORT_TCP_PORT}/?authSource=admin"
elif [ -n "$PASS_DB" ]; then
    URI="mongodb://admin:${PASS_DB}@${MONGO_HOST}:${MONGO_PORT_TCP_PORT}/?authSource=admin"
else
    URI="mongodb://${MONGO_HOST}:${MONGO_PORT_TCP_PORT}"
fi

echo "Starting mongodump for host ${MONGO_HOST}:${MONGO_PORT_TCP_PORT}..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP_DIR="$BACKUP_DIR/backup_${TIMESTAMP}"
mkdir -p "$CURRENT_BACKUP_DIR"

mongodump --uri="$URI" --out="$CURRENT_BACKUP_DIR"

echo "Mongodump completed successfully."

if [ -n "$MONGO_BACKUP_RETENTION_COUNT" ] && [ "$MONGO_BACKUP_RETENTION_COUNT" -gt 0 ]; then
    echo "Applying retention policy: keeping last $MONGO_BACKUP_RETENTION_COUNT backups..."

    cd "$BACKUP_DIR"
    ls -dt backup_* 2>/dev/null | tail -n +$((MONGO_BACKUP_RETENTION_COUNT + 1)) | while read -r old_backup; do
        if [ -n "$old_backup" ]; then
            echo "Removing old backup: $old_backup"
            rm -rf "$old_backup"
        fi
    done
fi

echo "Backup process finished."
