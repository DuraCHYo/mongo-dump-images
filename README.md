# mongo_dump_images

Docker-образы с `mongodump` для MongoDB 7.x и 8.x.

## Образы

Оба образа публикуются в один пакет GHCR с тегами по линии MongoDB:

| Образ | Теги |
| --- | --- |
| MongoDB 7.x | `ghcr.io/durachyo/mongo-dump-images:7.x-<version>`, `ghcr.io/durachyo/mongo-dump-images:7.x` |
| MongoDB 8.x | `ghcr.io/durachyo/mongo-dump-images:8.x-<version>`, `ghcr.io/durachyo/mongo-dump-images:8.x`, `ghcr.io/durachyo/mongo-dump-images:latest` |

Например, для тега `v1.2.3` будут собраны:

- `ghcr.io/durachyo/mongo-dump-images:7.x-1.2.3` и `7.x`
- `ghcr.io/durachyo/mongo-dump-images:8.x-1.2.3`, `8.x` и `latest`

## Релиз

Релиз запускается пушем git-тега:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Workflow `.github/workflows/release.yaml` собирает оба образа параллельно
(матрица `7.x` и `8.x`) и пушит их в GHCR. Теги `7.x` / `8.x` / `latest`
перезаписываются при каждом релизе, версионные теги неизменны.

## Локальная сборка

```bash
docker build -t mongo-dump:7.x ./7.x
docker build -t mongo-dump:8.x ./8.x
```

## Использование

```bash
docker run --rm \
  -e MONGO_HOST=mongo \
  -e PASS_DB=secret \
  -e MONGO_BACKUP_RETENTION_COUNT=7 \
  -v "$PWD/backups:/tmp/backup" \
  ghcr.io/durachyo/mongo-dump-images:8.x
```
