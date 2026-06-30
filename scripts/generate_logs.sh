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

PORT="${NGINX_PORT:-8080}"
BASE="http://localhost:${PORT}"

echo "Gerando acessos HTTP no Nginx..."
for path in / /login /admin-falso /rota-inexistente /erro-500 /login /admin-falso; do
  curl -s -o /dev/null -w "%{http_code} %{url_effective}\n" "$BASE$path" || true
done

cat >> sample-logs/auth.log <<'EOF'
Jun 30 09:10:01 notebook-demo sshd[1301]: Failed password for invalid user oracle from 10.10.0.15 port 60001 ssh2
Jun 30 09:10:03 notebook-demo sshd[1302]: Failed password for invalid user postgres from 10.10.0.15 port 60002 ssh2
Jun 30 09:10:05 notebook-demo sshd[1303]: Failed password for invalid user test from 10.10.0.15 port 60003 ssh2
Jun 30 09:11:20 notebook-demo sshd[1304]: Accepted password for henrique from 192.168.56.1 port 60004 ssh2
Jun 30 09:12:09 notebook-demo sudo: henrique : TTY=pts/1 ; PWD=/home/henrique/so-elk-centralized-logs ; USER=root ; COMMAND=/usr/bin/docker ps
EOF

echo "Logs simulados adicionados em sample-logs/auth.log"
echo "Aguarde alguns segundos e rode ./scripts/verify.sh"
