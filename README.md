# Gestão de Logs Centralizada com ELK — Trabalho de SO

Ambiente Docker reproduzível para demonstrar centralização de logs com:

- Elasticsearch: armazenamento e busca dos eventos
- Logstash: recebimento, parsing e normalização
- Kibana: visualização e dashboards
- Filebeat: agente coletor
- Nginx: serviço de exemplo que gera logs HTTP
- `sample-logs/auth.log`: logs Linux/SSH simulados para auditoria

A ideia da apresentação é clara: em produção, Filebeat rodaria em várias máquinas; neste laboratório, um único host Linux simula servidor central e cliente gerador de logs usando containers separados.

## Como o projeto atende ao tema proposto

Tema proposto:

> Instalar e configurar um servidor Linux para hospedar a stack ELK (Elasticsearch, Logstash/Fluentd e Kibana). O grupo deve configurar agentes, como Filebeat, em outras máquinas da rede para enviar logs de sistema, como acessos SSH e logs do Apache, e criar dashboards interativos para auditoria de segurança do Sistema Operacional.

Este projeto implementa essa proposta em um laboratório Docker reproduzível. Em produção, os componentes poderiam estar distribuídos entre várias máquinas; aqui, containers separados simulam a arquitetura completa em um único host Linux.

### Mapeamento do tema para a implementação

| Parte do tema | Onde está implementado |
|---|---|
| Servidor Linux | Host que executa este projeto com Docker Compose |
| Elasticsearch | Serviço `elasticsearch` em `docker-compose.yml` |
| Logstash | Serviço `logstash` em `docker-compose.yml` e pipeline em `logstash/pipeline/logstash.conf` |
| Kibana | Serviço `kibana` em `docker-compose.yml`, acessível pela porta `5601` |
| Filebeat | Serviço `filebeat` em `docker-compose.yml` e configuração em `filebeat/filebeat.yml` |
| Logs SSH/autenticação | Arquivo `sample-logs/auth.log`, simulando `/var/log/auth.log` |
| Logs Apache/serviço web | Nginx como equivalente de serviço web, configurado em `nginx/default.conf` |
| Envio de logs | Filebeat envia eventos para Logstash em `logstash:5044` |
| Centralização dos logs | Logstash envia os eventos para Elasticsearch no índice `so-logs-*` |
| Dashboards interativos | Exportados em `dashboards/kibana-dashboard.ndjson` |
| Auditoria de segurança | Gráficos e filtros para falhas SSH, status HTTP, tipos de log e volume temporal |

### Servidor Linux e Docker Compose

O servidor Linux hospeda toda a infraestrutura central de logs. Em vez de instalar Elasticsearch, Logstash, Kibana, Filebeat e Nginx manualmente no sistema operacional, o projeto usa Docker Compose para deixar a instalação reproduzível.

Arquivo principal:

```txt
docker-compose.yml
```

Isso permite subir o ambiente em outra máquina Linux com poucos comandos:

```bash
cp .env.example .env
./scripts/setup.sh
```

### Elasticsearch

O Elasticsearch é o banco de busca da solução. Ele armazena e indexa os logs recebidos do Logstash.

No `docker-compose.yml`, ele aparece como:

```yaml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION:-8.15.3}
  ports:
    - "${ELASTICSEARCH_PORT:-9200}:9200"
```

Os eventos são gravados em índices no formato:

```txt
so-logs-YYYY.MM.dd
```

Exemplo:

```txt
so-logs-2026.06.30
```

### Logstash

O Logstash recebe os eventos enviados pelo Filebeat pela porta `5044`, interpreta as mensagens e envia os dados estruturados para o Elasticsearch.

Configuração:

```txt
logstash/pipeline/logstash.conf
```

Entrada Beats:

```conf
input {
  beats {
    port => 5044
  }
}
```

O pipeline trata dois tipos principais de log:

- `nginx_access`: logs HTTP do Nginx;
- `simulated_auth`: logs simulados de autenticação Linux/SSH.

Para logs HTTP, o Logstash usa o padrão `COMBINEDAPACHELOG`, compatível com o formato comum de logs Apache/Nginx:

```conf
if [fields][log_type] == "nginx_access" {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}
```

Para logs de autenticação, ele extrai informações de falhas SSH, login aceito e uso de `sudo`:

```conf
else if [fields][log_type] == "simulated_auth" {
  grok {
    match => {
      "message" => [
        "... Failed password ...",
        "... Accepted password ...",
        "... sudo ..."
      ]
    }
  }
}
```

Com isso, uma linha bruta de log passa a ter campos úteis como:

```txt
user
source_ip
source_port
event.dataset
http.response.status_code
url.original
```

### Kibana

O Kibana é a interface web usada para consultar e visualizar os logs.

No `docker-compose.yml`:

```yaml
kibana:
  image: docker.elastic.co/kibana/kibana:${STACK_VERSION:-8.15.3}
  ports:
    - "${KIBANA_PORT:-5601}:5601"
```

O Data View usado no Kibana é:

```txt
so-logs-*
```

Campo de tempo:

```txt
@timestamp
```

O dashboard exportado está em:

```txt
dashboards/kibana-dashboard.ndjson
```

### Filebeat como agente coletor

O Filebeat representa o agente de coleta de logs. Em um ambiente real, ele ficaria instalado nas máquinas clientes da rede. Neste laboratório, ele roda em container e lê logs de volumes compartilhados.

Configuração:

```txt
filebeat/filebeat.yml
```

Coleta de logs HTTP:

```yaml
- type: filestream
  id: nginx-access
  paths:
    - /var/log/nginx/access.log
  fields:
    log_type: nginx_access
```

Coleta de logs de autenticação simulados:

```yaml
- type: filestream
  id: simulated-auth
  paths:
    - /sample-logs/auth.log
  fields:
    log_type: simulated_auth
```

Envio para o Logstash:

```yaml
output.logstash:
  hosts: ["logstash:5044"]
```

### Simulação de outras máquinas da rede

O tema pede agentes em outras máquinas da rede. Neste laboratório, essa arquitetura é simulada com containers separados na mesma rede Docker.

Rede Docker:

```yaml
networks:
  elk:
    driver: bridge
```

Interpretação da arquitetura:

- o container `nginx` simula um servidor web gerador de logs;
- o arquivo `sample-logs/auth.log` simula logs de autenticação de um servidor Linux;
- o container `filebeat` simula o agente coletor instalado em uma máquina cliente;
- o container `logstash` simula o servidor central de recebimento/processamento;
- o container `elasticsearch` centraliza os dados;
- o container `kibana` fornece a interface de auditoria.

Em produção, bastaria instalar Filebeat nas máquinas reais e apontar a saída para o endereço do Logstash central.

### Logs de sistema e serviço web

O projeto usa duas fontes principais de log.

#### Logs SSH/autenticação Linux

Arquivo:

```txt
sample-logs/auth.log
```

Esse arquivo simula o `/var/log/auth.log` de um Linux real, contendo eventos como:

- falhas de senha SSH;
- login aceito;
- uso de `sudo`.

#### Logs HTTP de serviço web

O tema cita Apache como exemplo. O projeto usa Nginx, que gera logs HTTP equivalentes para fins de auditoria.

Configuração:

```txt
nginx/default.conf
```

Arquivo de log coletado:

```txt
/var/log/nginx/access.log
```

O script de demonstração gera acessos para rotas como:

```txt
/
/login
/admin-falso
/rota-inexistente
/erro-500
```

Assim aparecem status HTTP como:

```txt
200
403
404
500
```

### Dashboards interativos e auditoria

O dashboard criado no Kibana permite auditar eventos importantes do sistema operacional e do serviço web.

Dashboard:

```txt
Dashboard - Gestão de Logs Centralizada com ELK
```

Arquivo exportado:

```txt
dashboards/kibana-dashboard.ndjson
```

Visualizações incluídas:

1. **Tipos de logs coletados**  
   Mostra a proporção entre `nginx_access` e `simulated_auth`.

2. **Status HTTP do Nginx**  
   Mostra respostas HTTP como `200`, `403`, `404` e `500`.

3. **Falhas SSH simuladas por usuário**  
   Usa o filtro:

   ```txt
   message: "Failed password"
   ```

   Isso permite identificar usuários atacados, como `root`, `admin`, `oracle`, `postgres` e `test`.

4. **Volume de logs por tempo**  
   Mostra a chegada dos eventos ao longo do tempo.

Essas visualizações ajudam na auditoria porque permitem identificar:

- tentativas de login inválidas;
- usuários alvo de falhas SSH;
- possíveis IPs suspeitos;
- acessos HTTP negados;
- rotas inexistentes;
- erros internos;
- aumento de volume de eventos.

### Resumo para apresentação

O projeto implementa uma infraestrutura de gestão centralizada de logs usando Elastic Stack. O servidor Linux hospeda Elasticsearch, Logstash, Kibana, Filebeat e Nginx via Docker Compose. O Filebeat coleta logs HTTP do Nginx e logs simulados de autenticação Linux, equivalentes ao `/var/log/auth.log`, e envia para o Logstash. O Logstash processa os eventos com filtros Grok, extrai campos como usuário, IP, status HTTP e tipo de evento, e envia tudo para o Elasticsearch no índice `so-logs-*`. No Kibana, foram criados dashboards interativos para auditoria, permitindo visualizar falhas SSH, acessos HTTP, erros, acessos negados e volume de eventos ao longo do tempo. Em produção, o Filebeat ficaria instalado em várias máquinas da rede; neste laboratório, essa arquitetura foi simulada com containers separados em uma rede Docker.

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

## Importar dashboard pronto

O dashboard exportado do Kibana está versionado em:

```txt
dashboards/kibana-dashboard.ndjson
```

Para importar em outra máquina:

1. Abra o Kibana.
2. Vá em **Stack Management → Saved Objects**.
3. Clique em **Import**.
4. Selecione `dashboards/kibana-dashboard.ndjson`.
5. Confirme a importação.

O arquivo inclui o Data View `so-logs-*` e o dashboard **Dashboard - Gestão de Logs Centralizada com ELK**.

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
