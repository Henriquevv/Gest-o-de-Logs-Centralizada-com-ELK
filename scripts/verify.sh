#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  while IFS='=' read -r key value; do
    [[ -z "${key}" || "${key}" =~ ^# ]] && continue
    export "${key}=${value}"
  done < .env
fi

ES="http://localhost:${ELASTICSEARCH_PORT:-9200}"
KIBANA="http://localhost:${KIBANA_PORT:-5601}"
NGINX="http://localhost:${NGINX_PORT:-8080}"

echo "== Containers =="
docker compose ps

echo
echo "== Endpoints =="
curl -fsS "$ES" >/dev/null && echo "Elasticsearch OK: $ES"
curl -fsS "$KIBANA/api/status" >/dev/null && echo "Kibana OK: $KIBANA"
curl -fsS "$NGINX" >/dev/null && echo "Nginx OK: $NGINX"

echo
echo "== Índices SO =="
curl -fsS "$ES/_cat/indices/so-logs-*?v" || true

echo
echo "== Amostra de eventos =="
curl -fsS "$ES/so-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"size":5,"sort":[{"@timestamp":"desc"}],"query":{"match_all":{}}}'
