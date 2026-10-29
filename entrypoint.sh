#!/bin/bash
set -e
shopt -s nullglob

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT_TCP_PORT="${MONGO_PORT_TCP_PORT:-27017}"
MONGO_DB="${MONGO_DB:-}"
MONGO_COLLECTION="${MONGO_COLLECTION:-}"
EXCLUDE_SYSTEM_DBS="${EXCLUDE_SYSTEM_DBS:-true}"
BACKUP_DIR="/tmp/backup"
SYSTEM_DBS=(admin local config)

is_system_db() {
    local name="$1" sys
    for sys in "${SYSTEM_DBS[@]}"; do
        [ "$name" = "$sys" ] && return 0
    done
    return 1
}

MONGO_USER="${USER_DB:-RootAdmin}"
if [ -n "$MONGO_COLLECTION" ] && [ -z "$MONGO_DB" ]; then
    echo "ERROR: MONGO_COLLECTION задан без MONGO_DB." >&2
    exit 1
fi

URI="mongodb://${MONGO_HOST}:${MONGO_PORT_TCP_PORT}"
AUTH_ARGS=()
if [ -n "$PASS_DB" ]; then
    AUTH_ARGS=(--username "$MONGO_USER" --password "$PASS_DB" --authenticationDatabase admin)
fi

DUMP_ARGS=(--uri="$URI" "${AUTH_ARGS[@]}")
if [ -n "$MONGO_DB" ]; then
    DUMP_ARGS+=(--db="$MONGO_DB")
fi
if [ -n "$MONGO_COLLECTION" ]; then
    DUMP_ARGS+=(--collection="$MONGO_COLLECTION")
fi

echo "Starting mongodump for host ${MONGO_HOST}:${MONGO_PORT_TCP_PORT}..."
if [ -n "$MONGO_COLLECTION" ]; then
    echo "Target: database '${MONGO_DB}', collection '${MONGO_COLLECTION}'"
elif [ -n "$MONGO_DB" ]; then
    echo "Target: database '${MONGO_DB}'"
else
    echo "Target: all databases"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP_DIR="$BACKUP_DIR/backup_${TIMESTAMP}"
mkdir -p "$CURRENT_BACKUP_DIR"

mongodump "${DUMP_ARGS[@]}" --out="$CURRENT_BACKUP_DIR"

echo "Mongodump completed successfully."

EXCLUDE_ACTIVE=false
if [ "$EXCLUDE_SYSTEM_DBS" = "true" ] && ! is_system_db "$MONGO_DB"; then
    EXCLUDE_ACTIVE=true
fi

user_dbs=()
for db_path in "$CURRENT_BACKUP_DIR"/*/; do
    db_name=$(basename "$db_path")
    if is_system_db "$db_name"; then
        if [ "$EXCLUDE_ACTIVE" = "true" ]; then
            echo "Excluding system database: $db_name"
            rm -rf "${CURRENT_BACKUP_DIR:?}/$db_name"
        fi
    else
        user_dbs+=("$db_name")
    fi
done

if [ "$EXCLUDE_ACTIVE" = "true" ] && [ ${#user_dbs[@]} -eq 0 ]; then
    echo "ERROR: после дампа не осталось ни одной пользовательской базы." >&2
    echo "Скорее всего у пользователя '${MONGO_USER}' нет прав listDatabases/readAnyDatabase," >&2
    echo "и mongodump сохранил только системные базы. Укажите MONGO_DB явно." >&2
    exit 1
fi

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
