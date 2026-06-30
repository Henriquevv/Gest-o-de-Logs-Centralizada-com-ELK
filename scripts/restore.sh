#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 backups/so-elk-backup-YYYYmmdd-HHMMSS.tar.gz" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
ARCHIVE="$1"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Arquivo não encontrado: $ARCHIVE" >&2
  exit 1
fi

docker compose down >/dev/null

docker volume create so-elk-centralized-logs_elasticsearch_data >/dev/null
docker volume create so-elk-centralized-logs_filebeat_data >/dev/null
docker volume create so-elk-centralized-logs_nginx_logs >/dev/null

docker run --rm \
  -v so-elk-centralized-logs_elasticsearch_data:/data/elasticsearch \
  -v so-elk-centralized-logs_filebeat_data:/data/filebeat \
  -v so-elk-centralized-logs_nginx_logs:/data/nginx_logs \
  -v "$ROOT_DIR:/restore:ro" \
  alpine:3.20 \
  sh -c "cd /data && tar xzf /restore/$ARCHIVE"

docker compose up -d

echo "Restore aplicado a partir de: $ARCHIVE"
