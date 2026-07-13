#!/usr/bin/env python3
"""Seed richer demo data for Kibana dashboard screenshots.

The normal Filebeat/Logstash path is exercised by scripts/generate_logs.sh.
This script adds a deterministic 30-day sample directly to Elasticsearch so the
presentation dashboard has enough volume and HTTP/status variety to be readable.
"""

from __future__ import annotations

import json
import os
import random
import subprocess
from datetime import datetime, timedelta, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError

ES_URL = f"http://localhost:{os.environ.get('ELASTICSEARCH_PORT', '9200')}"
INDEX = os.environ.get("DEMO_INDEX", "so-logs-demo-rich")
SEED = int(os.environ.get("DEMO_SEED", "42"))

random.seed(SEED)

STATUS_CODES = [200, 200, 200, 201, 301, 302, 400, 401, 403, 404, 404, 429, 500, 502, 503]
PATHS = [
    "/",
    "/login",
    "/admin",
    "/api/users",
    "/api/orders",
    "/health",
    "/robots.txt",
    "/wp-admin",
    "/phpmyadmin",
    "/download/report.pdf",
]
USERS = ["root", "admin", "oracle", "postgres", "deploy", "henrique", "teste", "www-data"]
SERVICES = ["systemd", "cron", "kernel", "docker", "nginx", "filebeat", "logstash"]
LEVELS = ["INFO", "WARN", "ERROR", "CRITICAL"]


def request(method: str, path: str, body: str | None = None, content_type: str = "application/json") -> bytes:
    data = body.encode() if body is not None else None
    req = Request(f"{ES_URL}{path}", data=data, method=method, headers={"Content-Type": content_type})
    try:
        with urlopen(req, timeout=60) as response:
            return response.read()
    except HTTPError as exc:
        if exc.code == 404 and method == "DELETE":
            return b"{}"
        raise


def build_actions() -> list[dict]:
    actions: list[dict] = []
    base = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0) - timedelta(days=27)

    for bucket in range(56):  # 28 days, one bucket every 12h
        ts = base + timedelta(hours=12 * bucket)

        for _ in range(random.randint(4, 9)):
            code = random.choice(STATUS_CODES)
            path = random.choice(PATHS)
            ip = f"172.20.0.{random.randint(2, 250)}"
            actions.append({"index": {"_index": INDEX}})
            actions.append(
                {
                    "@timestamp": (ts + timedelta(minutes=random.randint(0, 590))).isoformat(),
                    "message": f'{ip} - - [{ts:%d/%b/%Y:%H:%M:%S} +0000] "GET {path} HTTP/1.1" {code} {random.randint(20, 5000)} "-" "demo-rich"',
                    "fields": {"log_type": "nginx_access", "project": "so-elk-centralized-logs"},
                    "event": {"dataset": "nginx.access"},
                    "http": {"response": {"status_code": code}},
                    "url": {"path": path},
                    "source_ip": ip,
                }
            )

        for _ in range(random.randint(2, 6)):
            user = random.choice(USERS)
            ip = f"10.10.{random.randint(0, 4)}.{random.randint(2, 254)}"
            failed = random.random() < 0.75
            invalid = "invalid user " if failed and random.random() < 0.5 else ""
            status = "Failed" if failed else "Accepted"
            message = f"{ts:%b %d %H:%M:%S} notebook-demo sshd[{random.randint(1000, 9999)}]: {status} password for {invalid}{user} from {ip} port {random.randint(50000, 65000)} ssh2"
            actions.append({"index": {"_index": INDEX}})
            actions.append(
                {
                    "@timestamp": (ts + timedelta(minutes=random.randint(0, 590))).isoformat(),
                    "message": message,
                    "fields": {"log_type": "simulated_auth", "project": "so-elk-centralized-logs"},
                    "event": {"dataset": "linux.auth", "outcome": "failure" if failed else "success"},
                    "user": user,
                    "source_ip": ip,
                }
            )

        for _ in range(random.randint(1, 4)):
            service = random.choice(SERVICES)
            level = random.choice(LEVELS)
            actions.append({"index": {"_index": INDEX}})
            actions.append(
                {
                    "@timestamp": (ts + timedelta(minutes=random.randint(0, 590))).isoformat(),
                    "message": f"{ts:%b %d %H:%M:%S} notebook-demo {service}[{random.randint(100, 9999)}]: {level}: simulated operational event",
                    "fields": {"log_type": "simulated_syslog", "project": "so-elk-centralized-logs"},
                    "event": {"dataset": "linux.syslog"},
                    "service": service,
                    "log_level": level,
                }
            )

        for _ in range(random.randint(1, 3)):
            level = random.choice(LEVELS)
            code = random.choice(STATUS_CODES)
            route = random.choice(PATHS)
            actions.append({"index": {"_index": INDEX}})
            actions.append(
                {
                    "@timestamp": (ts + timedelta(minutes=random.randint(0, 590))).isoformat(),
                    "message": json.dumps(
                        {
                            "level": level,
                            "service": "api-demo",
                            "route": route,
                            "status": code,
                            "latency_ms": random.randint(10, 900),
                            "message": "simulated application event",
                        }
                    ),
                    "fields": {"log_type": "simulated_app", "project": "so-elk-centralized-logs"},
                    "event": {"dataset": "app.api"},
                    "app": {"level": level, "service": "api-demo", "route": route, "status": code},
                }
            )

    return actions


def main() -> None:
    request("DELETE", f"/{INDEX}")
    actions = build_actions()
    payload = "\n".join(json.dumps(action) for action in actions) + "\n"
    result = json.loads(request("POST", "/_bulk", payload, "application/x-ndjson"))
    if result.get("errors"):
        raise SystemExit(json.dumps(result)[:2000])

    request("POST", f"/{INDEX}/_refresh")
    count = json.loads(request("GET", f"/{INDEX}/_count"))["count"]
    print(f"Demo dashboard index criado: {INDEX}")
    print(f"Eventos indexados: {count}")
    print("O índice entra no Data View so-logs-* e enriquece os gráficos do Kibana.")


if __name__ == "__main__":
    main()
