# Plano de Apresentação — Gestão de Logs Centralizada com ELK

> Duração sugerida: 10 a 15 minutos.
> Objetivo: mostrar que o projeto atende ao tema, funciona de verdade e tem relação clara com Sistemas Operacionais.

## Veredito

Dá para fechar o trabalho nesse formato: **Docker Compose + Filebeat + Logstash + Elasticsearch + Kibana + Nginx + logs SSH simulados**.

A única defesa obrigatória é explicar bem a simulação:

> Em produção, o Filebeat ficaria instalado em várias máquinas Linux da rede. Para fins de laboratório, usamos containers separados no mesmo host para reproduzir a mesma arquitetura lógica: coleta, processamento, armazenamento e visualização.

Não diga que são várias máquinas físicas. Diga que é **laboratório reproduzível em um host Linux**. Isso é honesto e tecnicamente defensável.

---

## 1. Abertura — problema

**Quem fala:** integrante 1  
**Tempo:** 1 minuto

Falar:

> O problema tratado é a dificuldade de auditar logs quando cada máquina mantém seus eventos localmente. Em um ambiente com vários servidores, procurar falhas de login, erros HTTP ou eventos suspeitos manualmente em `/var/log` é lento e pouco confiável.

Pontos-chave:

- logs ficam espalhados;
- auditoria manual é ruim;
- centralização facilita busca, correlação e visualização.

---

## 2. Relação com Sistemas Operacionais

**Quem fala:** integrante 2  
**Tempo:** 2 minutos

Falar:

> O projeto se relaciona com Sistemas Operacionais porque trabalha com arquivos de log, processos, permissões, rede e auditoria de segurança em Linux.

Citar:

- arquivos: `/var/log/auth.log`, logs Nginx/Apache;
- processos/serviços: Filebeat, Logstash, Elasticsearch, Kibana, Nginx;
- permissões: agente precisa ler logs do sistema;
- rede: Filebeat envia eventos para Logstash pela porta `5044`;
- auditoria: falhas SSH, status HTTP, usuários, IPs e volume de eventos.

Frase boa:

> Não é só uma ferramenta de dashboard; é uma forma de observar eventos gerados pelo sistema operacional e por serviços em execução.

---

## 3. Arquitetura da solução

**Quem fala:** integrante 3  
**Tempo:** 2 minutos

Mostrar `docs/arquitetura.md` ou o diagrama do README.

Fluxo:

```txt
Nginx / auth.log -> Filebeat -> Logstash -> Elasticsearch -> Kibana
```

Explicar cada parte:

| Componente | Função |
|---|---|
| Nginx | Gera logs HTTP de exemplo |
| `sample-logs/auth.log` | Simula logs Linux/SSH |
| Filebeat | Coleta arquivos de log |
| Logstash | Recebe, interpreta e normaliza eventos |
| Elasticsearch | Armazena e indexa os logs |
| Kibana | Exibe buscas e dashboards |

Falar:

> O Docker Compose não é o foco do trabalho; ele foi usado para garantir reprodutibilidade. O foco é a arquitetura de logs centralizados.

---

## 4. Implementação técnica

**Quem fala:** integrante 4  
**Tempo:** 2 minutos

Mostrar rapidamente os arquivos do repositório:

```txt
docker-compose.yml
filebeat/filebeat.yml
logstash/pipeline/logstash.conf
nginx/default.conf
sample-logs/auth.log
scripts/generate_logs.sh
scripts/verify.sh
dashboards/kibana-dashboard.ndjson
```

Explicar:

- `docker-compose.yml`: sobe a stack completa;
- `filebeat.yml`: define quais logs serão coletados;
- `logstash.conf`: extrai campos com Grok;
- `generate_logs.sh`: gera eventos HTTP e SSH/sudo simulados;
- `verify.sh`: prova que containers, endpoints, índice e eventos existem;
- `kibana-dashboard.ndjson`: export do dashboard.

Frase boa:

> O projeto não depende de configuração manual escondida no servidor. O repositório contém a infraestrutura e os scripts necessários para reproduzir a demonstração.

---

## 5. Demonstração ao vivo

**Quem opera:** integrante mais calmo do grupo — sem herói nervoso no teclado.  
**Tempo:** 3 a 5 minutos

### 5.1 Mostrar containers rodando

```bash
docker compose ps
```

O professor deve ver:

- `so-elasticsearch`
- `so-logstash`
- `so-kibana`
- `so-filebeat`
- `so-nginx-demo`

### 5.2 Gerar logs

```bash
./scripts/generate_logs.sh
```

Isso gera:

- acessos HTTP `200`, `403`, `404`, `500`;
- falhas SSH simuladas;
- login aceito;
- evento `sudo`.

### 5.3 Verificar pelo terminal

```bash
sleep 20
./scripts/verify.sh
```

Mostrar:

- Elasticsearch OK;
- Kibana OK;
- Nginx OK;
- índice `so-logs-*`;
- eventos retornando no Elasticsearch.

### 5.4 Mostrar Kibana

Abrir:

```txt
http://localhost:5601
```

ou, neste servidor:

```txt
http://192.168.1.200:5601
```

Mostrar no dashboard:

1. tipos de logs coletados;
2. status HTTP do Nginx;
3. falhas SSH simuladas por usuário;
4. volume de logs por tempo.

Filtros úteis no Discover:

```txt
fields.log_type: "nginx_access"
```

```txt
message: "Failed password"
```

```txt
http.response.status_code >= 400
```

---

## 6. Trade-offs e limitações

**Quem fala:** integrante 1 ou 2  
**Tempo:** 1 a 2 minutos

Falar sem medo:

| Decisão | Vantagem | Limitação |
|---|---|---|
| Docker Compose | Reproduzível e fácil de demonstrar | Simula várias máquinas em um host |
| Nginx no lugar de Apache | Logs HTTP equivalentes | Não é Apache literalmente |
| SSH/auth simulado | Demo controlada e repetível | Não usa falha SSH real ao vivo |
| ELK | Poderoso para busca e dashboards | Consome bastante RAM |
| Logstash | Parsing forte com Grok | Mais pesado que alternativas como Fluentd |

Frase boa:

> A limitação principal é que o laboratório compacta a arquitetura em um único host. Mesmo assim, o fluxo técnico é o mesmo de uma implantação real: agentes coletam logs e enviam para um servidor central.

---

## 7. Fechamento

**Quem fala:** integrante final  
**Tempo:** 1 minuto

Falar:

> O projeto atende ao objetivo de centralizar logs de sistema e serviço web, processar os eventos, armazená-los em um índice pesquisável e apresentar dashboards úteis para auditoria de segurança. A solução é reproduzível, documentada e pode ser adaptada para máquinas reais instalando Filebeat nos clientes.

Resumo em uma frase:

> Saímos de logs espalhados em arquivos locais para uma visão centralizada e auditável no Kibana.

---

## Perguntas prováveis do professor

### Por que Docker se o tema fala servidor Linux?

> Porque o Docker roda sobre o servidor Linux e permite empacotar os serviços de forma reproduzível. A stack continua hospedada no Linux; só evitamos instalação manual serviço por serviço.

### O trabalho pediu outras máquinas. Vocês usaram?

> Usamos containers separados para simular as máquinas e componentes. Em produção, o mesmo `filebeat.yml` seria instalado nas máquinas reais apontando para o Logstash central.

### Por que Nginx e não Apache?

> O tema cita Apache como exemplo de serviço web que gera logs HTTP. Usamos Nginx porque gera logs equivalentes para auditoria: método, rota, IP, status HTTP e horário.

### Como vocês detectam tentativa de ataque?

> Pelo filtro `message: "Failed password"`, extraindo campos como usuário e IP de origem. No dashboard, isso aparece como falhas SSH por usuário.

### O que o Logstash faz exatamente?

> Ele recebe logs brutos do Filebeat e usa filtros Grok para transformar texto em campos estruturados, como `user`, `source_ip`, `http.response.status_code` e `event.dataset`.

### Qual seria a evolução real do projeto?

> Instalar Filebeat em duas ou mais máquinas reais, adicionar TLS/autenticação entre Filebeat e Logstash, coletar `/var/log/syslog`, configurar retenção de índices e criar alertas para brute force.

---

## Divisão sugerida entre integrantes

Se forem 4 pessoas:

1. Problema + SO
2. Arquitetura
3. Implementação técnica
4. Demo + conclusão

Se forem 3 pessoas:

1. Problema + SO
2. Arquitetura + implementação
3. Demo + trade-offs + conclusão

Se forem 2 pessoas:

1. Contexto + arquitetura + conceitos de SO
2. Implementação + demo + trade-offs

---

## Checklist antes de apresentar

- [ ] Repositório GitHub Classroom correto entregue.
- [ ] Todos os integrantes listados no Google Classroom.
- [ ] `docker compose ps` funcionando.
- [ ] `./scripts/generate_logs.sh` funcionando.
- [ ] `./scripts/verify.sh` retornando eventos.
- [ ] Kibana abre.
- [ ] Dashboard importado.
- [ ] Prints salvos em `docs/screenshots/` ou anexados.
- [ ] Alguém do grupo testou clone limpo ou, no mínimo, leu o README e rodou a stack.
- [ ] Apresentador sabe explicar a frase: “containers simulam máquinas separadas”.
