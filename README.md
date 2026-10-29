# mongo_dump_images

Docker-образ с `mongodump` для резервного копирования MongoDB.

Образ собирается из `debian:bookworm-slim` и официального репозитория
MongoDB 8.0: в него устанавливается пакет `mongodb-database-tools`
(включает `mongodump`, `mongorestore`, `mongoexport` и другие утилиты).

`mongodump` из состава Database Tools 8.0 обратно совместим, поэтому один
образ подходит для MongoDB 8.0 и более ранних поддерживаемых версий
(7.0, 6.0, 5.0, 4.4).

## Образ

Образ публикуется в GHCR:

| Тег | Описание |
| --- | --- |
| `ghcr.io/durachyo/mongo-dump-images:<version>` | Версия релиза, например `1.2.3` |
| `ghcr.io/durachyo/mongo-dump-images:latest` | Последний релиз |

Версионный тег неизменен, `latest` перезаписывается при каждом релизе.

## Релиз

Релиз запускается пушем git-тега:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Workflow `.github/workflows/release.yaml` собирает образ из `Dockerfile`
в корне репозитория и пушит его в GHCR с тегами `1.2.3` и `latest`.

## Локальная сборка

```bash
docker build -t mongo-dump:local .
```

## Использование

```bash
docker run --rm \
  -e MONGO_HOST=mongo \
  -e PASS_DB=secret \
  -e MONGO_BACKUP_RETENTION_COUNT=7 \
  -v "$PWD/backups:/tmp/backup" \
  ghcr.io/durachyo/mongo-dump-images:latest
```

Каждый запуск создаёт каталог `/tmp/backup/backup_<YYYYmmdd_HHMMSS>`,
поэтому его нужно монтировать как volume, чтобы бэкапы сохранялись между
запусками.

### Переменные окружения

| Переменная | По умолчанию | Описание |
| --- | --- | --- |
| `MONGO_HOST` | `localhost` | Хост MongoDB |
| `MONGO_PORT_TCP_PORT` | `27017` | Порт MongoDB |
| `USER_DB` | `RootAdmin` | Имя пользователя для аутентификации |
| `PASS_DB` | — | Пароль; если не задан — подключение без аутентификации |
| `MONGO_DB` | — | База данных для бэкапа; если не задана — дампятся все доступные базы |
| `MONGO_COLLECTION` | — | Коллекция для бэкапа; требует `MONGO_DB` |
| `EXCLUDE_SYSTEM_DBS` | `true` | Удалять из бэкапа системные базы `admin`, `local`, `config` |
| `MONGO_BACKUP_RETENTION_COUNT` | — | Сколько последних бэкапов хранить; `0` или пустое значение отключает очистку |

Аутентификация выполняется с `authSource=admin`. Если не задан ни один из
`USER_DB` / `PASS_DB`, подключение идёт без аутентификации.

Если `MONGO_DB` не задан, `mongodump` пытается сдампить все базы. Это
работает только при наличии прав `listDatabases` (роли `backup` или
`readAnyDatabase`). Без них mongodump может сохранить только базу
аутентификации (`admin`) — поэтому для бэкапа конкретной базы её лучше
указывать явно.

### Бэкап одной базы или коллекции

```bash
docker run --rm \
  -e MONGO_HOST=mongo \
  -e USER_DB=backup \
  -e PASS_DB=secret \
  -e MONGO_DB=mydb \
  -e MONGO_COLLECTION=users \
  -v "$PWD/backups:/tmp/backup" \
  ghcr.io/durachyo/mongo-dump-images:latest
```
