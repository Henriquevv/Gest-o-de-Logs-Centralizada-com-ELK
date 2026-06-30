#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Criado .env a partir de .env.example"
fi

while IFS='=' read -r key value; do
  [[ -z "${key}" || "${key}" =~ ^# ]] && continue
  export "${key}=${value}"
done < .env

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker não encontrado. Instale Docker Engine antes de continuar." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose não encontrado." >&2
  exit 1
fi

MAX_MAP_COUNT="$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)"
if [[ "$MAX_MAP_COUNT" -lt 262144 ]]; then
  echo "vm.max_map_count está baixo ($MAX_MAP_COUNT). Ajuste com:" >&2
  echo "sudo sysctl -w vm.max_map_count=262144" >&2
  exit 1
fi

docker compose config >/dev/null
echo "Configuração Docker válida. Subindo stack..."
docker compose up -d

wait_for_http() {
  local name="$1"
  local url="$2"
  echo "Aguardando ${name} responder..."
  for i in {1..60}; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "${name} OK"
      return 0
    fi
    sleep 5
  done
  echo "${name} não respondeu no tempo esperado: ${url}" >&2
  docker compose ps
  return 1
}

wait_for_tcp() {
  local name="$1"
  local host="$2"
  local port="$3"
  echo "Aguardando ${name} aceitar conexão..."
  for i in {1..60}; do
    if timeout 2 bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
      echo "${name} OK"
      return 0
    fi
    sleep 5
  done
  echo "${name} não aceitou conexão no tempo esperado: ${host}:${port}" >&2
  docker compose ps
  return 1
}

wait_for_http "Elasticsearch" "http://localhost:${ELASTICSEARCH_PORT:-9200}"
wait_for_http "Kibana" "http://localhost:${KIBANA_PORT:-5601}/api/status"
wait_for_tcp "Logstash" "localhost" "5044"

echo "Stack iniciada. Rode: ./scripts/generate_logs.sh && sleep 20 && ./scripts/verify.sh"
