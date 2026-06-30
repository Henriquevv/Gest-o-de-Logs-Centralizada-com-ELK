#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="backups/so-elk-backup-${STAMP}.tar.gz"

docker compose stop elasticsearch filebeat >/dev/null

docker run --rm \
  -v so-elk-centralized-logs_elasticsearch_data:/data/elasticsearch:ro \
  -v so-elk-centralized-logs_filebeat_data:/data/filebeat:ro \
  -v so-elk-centralized-logs_nginx_logs:/data/nginx_logs:ro \
  -v "$ROOT_DIR/backups:/backup" \
  alpine:3.20 \
  tar czf "/backup/$(basename "$ARCHIVE")" -C /data .

docker compose start elasticsearch filebeat >/dev/null

echo "Backup criado: $ARCHIVE"
