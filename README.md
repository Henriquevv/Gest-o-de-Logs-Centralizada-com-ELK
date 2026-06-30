# Gestão de Logs Centralizada com ELK — Trabalho de SO

Ambiente Docker reproduzível para demonstrar centralização de logs com:

- Elasticsearch: armazenamento e busca dos eventos
- Logstash: recebimento, parsing e normalização
- Kibana: visualização e dashboards
- Filebeat: agente coletor
- Nginx: serviço de exemplo que gera logs HTTP
- `sample-logs/auth.log`: logs Linux/SSH simulados para auditoria

A ideia da apresentação é clara: em produção, Filebeat rodaria em várias máquinas; neste laboratório, um único host Linux simula servidor central e cliente gerador de logs usando containers separados.

## Requisitos

- Linux, WSL2 ou VM Linux
- Docker Engine
- Docker Compose
- 4 GB RAM mínimo; 8 GB recomendado
- `vm.max_map_count >= 262144`

Verificação:

```bash
docker --version
docker compose version
sysctl vm.max_map_count
```

Se precisar ajustar no Linux:

```bash
sudo sysctl -w vm.max_map_count=262144
```

## Subir do zero

```bash
git clone <repo-do-github-classroom>
cd so-elk-centralized-logs
cp .env.example .env
./scripts/setup.sh
```

Acessos:

```txt
Kibana:        http://localhost:5601
Elasticsearch: http://localhost:9200
Nginx demo:    http://localhost:8080
```

## Gerar logs para demonstração

```bash
./scripts/generate_logs.sh
```

Isso faz duas coisas:

1. gera requisições HTTP no Nginx: `/`, `/login`, `/admin-falso`, `/erro-500`, rota inexistente;
2. adiciona eventos SSH/sudo simulados em `sample-logs/auth.log`.

## Verificar se está funcionando

```bash
./scripts/verify.sh
```

O resultado esperado é:

- containers rodando;
- Elasticsearch respondendo;
- Kibana respondendo;
- índice `so-logs-YYYY.MM.dd` criado;
- eventos retornando na busca do Elasticsearch.

## Criar Data View no Kibana

No Kibana:

1. Menu lateral → Stack Management
2. Kibana → Data Views
3. Create data view
4. Name: `SO Logs`
5. Index pattern: `so-logs-*`
6. Timestamp field: `@timestamp`
7. Save

Depois use Discover para filtrar eventos.

## Consultas úteis no Kibana

HTTP:

```txt
fields.log_type: "nginx_access"
```

Erros HTTP:

```txt
fields.log_type: "nginx_access" and response >= 400
```

Autenticação Linux/SSH:

```txt
fields.log_type: "simulated_auth"
```

Falhas de senha:

```txt
message: "Failed password"
```

Acesso negado no Nginx:

```txt
request: "/admin-falso"
```

## Backup

```bash
./scripts/backup.sh
```

Os backups ficam em `backups/` e não entram no git.

## Restore em outra máquina

```bash
cp .env.example .env
./scripts/restore.sh backups/so-elk-backup-YYYYmmdd-HHMMSS.tar.gz
```

## Parar e limpar

Parar sem apagar dados:

```bash
docker compose down
```

Apagar containers e volumes:

```bash
docker compose down -v
```

## Estrutura

```txt
.
├── docker-compose.yml
├── .env.example
├── filebeat/filebeat.yml
├── logstash/pipeline/logstash.conf
├── nginx/default.conf
├── sample-logs/auth.log
└── scripts/
    ├── setup.sh
    ├── generate_logs.sh
    ├── verify.sh
    ├── backup.sh
    └── restore.sh
```

## Pontos para explicar na apresentação

- Filebeat representa o agente coletor instalado nas máquinas clientes.
- Logstash recebe eventos na porta 5044 e extrai campos importantes.
- Elasticsearch centraliza e indexa os logs.
- Kibana permite auditoria visual e busca rápida.
- Nginx e `auth.log` simulam fontes reais de logs do Linux.
- Docker Compose garante reprodutibilidade: o professor ou outro integrante consegue subir o mesmo laboratório em outra máquina.
