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
for path in / /login /admin-falso /rota-inexistente /erro-500 /login /admin-falso /wp-admin /phpmyadmin /robots.txt /api/users; do
  curl -s -o /dev/null -w "%{http_code} %{url_effective}\n" "$BASE$path" || true
done

cat >> sample-logs/auth.log <<'EOF'
Jun 30 09:10:01 notebook-demo sshd[1301]: Failed password for invalid user oracle from 10.10.0.15 port 60001 ssh2
Jun 30 09:10:03 notebook-demo sshd[1302]: Failed password for invalid user postgres from 10.10.0.15 port 60002 ssh2
Jun 30 09:10:05 notebook-demo sshd[1303]: Failed password for invalid user test from 10.10.0.15 port 60003 ssh2
Jun 30 09:11:20 notebook-demo sshd[1304]: Accepted password for henrique from 192.168.56.1 port 60004 ssh2
Jun 30 09:12:09 notebook-demo sudo: henrique : TTY=pts/1 ; PWD=/home/henrique/so-elk-centralized-logs ; USER=root ; COMMAND=/usr/bin/docker ps
EOF

cat >> sample-logs/syslog.log <<'EOF'
Jul 12 15:40:01 notebook-demo systemd[1]: Started nginx.service - Web Server.
Jul 12 15:40:12 notebook-demo systemd[1]: Started filebeat.service - Filebeat agent.
Jul 12 15:41:08 notebook-demo kernel: [12345.678901] WARNING: high memory usage detected by elasticsearch
Jul 12 15:41:44 notebook-demo systemd[1]: logstash.service: Consumed 2.314s CPU time.
Jul 12 15:42:03 notebook-demo cron[2401]: INFO: backup job finished successfully
Jul 12 15:42:25 notebook-demo systemd[1]: Failed to start fake-backup.service - Simulated failing service.
Jul 12 15:43:10 notebook-demo kernel: [12377.123456] WARNING: possible disk latency spike on /dev/sda
EOF

cat >> sample-logs/app.log <<'EOF'
{"level":"INFO","service":"api-gateway","route":"/api/login","status":200,"latency_ms":42,"client_ip":"172.16.0.10","message":"login page loaded"}
{"level":"WARN","service":"api-gateway","route":"/api/admin","status":403,"latency_ms":31,"client_ip":"203.0.113.10","message":"admin route denied"}
{"level":"ERROR","service":"orders-api","route":"/api/orders","status":500,"latency_ms":310,"client_ip":"172.16.0.22","message":"database timeout simulated"}
{"level":"INFO","service":"orders-api","route":"/api/orders","status":201,"latency_ms":88,"client_ip":"172.16.0.22","message":"order created"}
{"level":"WARN","service":"api-gateway","route":"/api/wp-admin","status":404,"latency_ms":19,"client_ip":"198.51.100.77","message":"suspicious route scan"}
EOF

echo "Logs simulados adicionados em sample-logs/auth.log"
echo "Logs extras adicionados em sample-logs/syslog.log e sample-logs/app.log"
echo "Aguarde alguns segundos e rode ./scripts/verify.sh"
