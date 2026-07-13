# Checklist de Fechamento — Trabalho de SO ELK

Data da revisão: 2026-07-12

## Veredito

**Pode fechar nesse formato.**

O projeto atende ao tema porque entrega:

- servidor Linux hospedando a stack via Docker Compose;
- Elasticsearch, Logstash e Kibana;
- Filebeat como agente coletor;
- logs de autenticação Linux/SSH simulados;
- logs HTTP via Nginx, equivalente ao exemplo Apache para auditoria;
- dashboard Kibana exportado;
- scripts de setup, geração de logs e verificação;
- documentação de arquitetura e reprodução.

O ponto sensível é só um: **outras máquinas da rede**. A defesa correta é dizer que o laboratório simula essa separação com containers, e que em produção o Filebeat seria instalado nas máquinas reais.

Se alguém tentar vender isso como “várias máquinas físicas”, aí vira lorota barata. Não façam isso.

---

## Evidência real da revisão

Comandos rodados em 2026-07-12:

```bash
sysctl vm.max_map_count
docker --version
docker compose version
./scripts/setup.sh
./scripts/generate_logs.sh
sleep 25
./scripts/verify.sh
```

Resultado observado:

```txt
vm.max_map_count = 1048576
Docker version 29.1.3
Docker Compose version v5.1.0
Elasticsearch OK
Kibana OK
Logstash OK
Nginx OK
```

Containers verificados:

```txt
so-elasticsearch  Up / healthy  :9200
so-logstash       Up            :5044
so-kibana         Up            :5601
so-filebeat       Up
so-nginx-demo     Up            :8081
```

Índices encontrados:

```txt
so-logs-2026.07.12  docs.count=12
so-logs-2026.06.30  docs.count=27
```

Total retornado pela busca:

```txt
39 eventos
```

Eventos recentes incluem:

- `nginx_access`;
- `simulated_auth`;
- `simulated_syslog`;
- `simulated_app`;
- falhas SSH com `Failed password`;
- usuários como `oracle`, `postgres`, `test`;
- evento de login aceito;
- evento `sudo`;
- logs HTTP gerados pelo Nginx;
- logs de sistema e aplicação/API simulados.

---

## O que já está bom

### 1. Implementação técnica

Arquivos principais existem e estão coerentes:

```txt
docker-compose.yml
.env.example
filebeat/filebeat.yml
logstash/pipeline/logstash.conf
nginx/default.conf
sample-logs/auth.log
scripts/setup.sh
scripts/generate_logs.sh
scripts/verify.sh
scripts/backup.sh
scripts/restore.sh
```

### 2. Dashboard

Export versionado:

```txt
dashboards/kibana-dashboard.ndjson
```

Dashboard esperado:

```txt
Dashboard - Gestão de Logs Centralizada com ELK
```

Visualizações esperadas:

- tipos de logs coletados;
- status HTTP do Nginx;
- falhas SSH simuladas por usuário;
- volume de logs por tempo.

### 3. Documentação

Documentos existentes:

```txt
README.md
docs/arquitetura.md
docs/plano-apresentacao.md
docs/checklist-fechamento.md
```

Nota no Obsidian:

```txt
1. Faculdade/Disciplinas/Sistemas Operacionais/Trabalho - Gestão de Logs Centralizada com ELK.md
```

### 4. Repositório

Repo remoto atual:

```txt
https://github.com/Henriquevv/Gest-o-de-Logs-Centralizada-com-ELK
```

Atenção: se o professor exigiu **GitHub Classroom**, confirmem se esse repo é exatamente o da tarefa ou se precisa copiar/submeter lá. Esse detalhe burocrático derruba trabalho bom por besteira besta.

---

## O que falta para ficar redondo

### Obrigatório antes da entrega

- [ ] Confirmar link correto do GitHub Classroom/Google Classroom.
- [ ] Colocar nomes dos integrantes na entrega.
- [ ] Anexar arquivos que não estejam no repo, se houver.
- [ ] Tirar prints finais da demo.
- [ ] Garantir que o dashboard importado abre no Kibana.
- [ ] Treinar a explicação da simulação com containers.

### Prints recomendados

Salvar em `docs/screenshots/` ou anexar na entrega:

1. `docker compose ps` com containers rodando.
2. Kibana Discover com:
   ```txt
   fields.log_type: "nginx_access"
   ```
3. Kibana Discover com:
   ```txt
   message: "Failed password"
   ```
4. Dashboard completo.
5. Índice/data view `so-logs-*`.
6. Terminal mostrando `./scripts/verify.sh`.

### Melhoria opcional, se sobrar tempo

- Testar clone limpo em outra máquina ou VM:

```bash
git clone https://github.com/Henriquevv/Gest-o-de-Logs-Centralizada-com-ELK.git
cd Gest-o-de-Logs-Centralizada-com-ELK
cp .env.example .env
./scripts/setup.sh
./scripts/generate_logs.sh
sleep 20
./scripts/verify.sh
```

Isso seria o melhor argumento para “funciona em diferentes cenários”.

---

## Riscos e respostas prontas

### Risco: professor cobrar “outras máquinas reais”

Resposta:

> O projeto simula máquinas separadas com containers em uma rede Docker para manter o laboratório reproduzível. Em uma implantação real, o Filebeat seria instalado em cada máquina Linux cliente e apontaria para o Logstash central.

### Risco: professor cobrar Apache especificamente

Resposta:

> O enunciado cita Apache como exemplo de serviço web gerador de logs. Usamos Nginx porque ele gera logs HTTP equivalentes para auditoria: IP, rota, método, horário e status code. A arquitetura seria a mesma com Apache, mudando apenas o caminho do arquivo de log.

### Risco: professor achar que Docker abstrai demais SO

Resposta:

> O Docker foi usado como mecanismo de empacotamento e reprodução. Os conceitos de SO continuam presentes: arquivos de log, processos/serviços, rede, permissões, portas, coleta de eventos e auditoria.

### Risco: demo quebrar ao vivo

Plano B:

1. Mostrar `./scripts/verify.sh` rodado antes.
2. Mostrar prints salvos.
3. Mostrar `dashboards/kibana-dashboard.ndjson` no repo.
4. Explicar o fluxo técnico pelo diagrama.

Demo ao vivo é legal; depender só dela é coragem burra.

---

## Recomendação final

Fechem assim:

1. Entrega técnica no repo.
2. Prints finais.
3. Plano de apresentação em `docs/plano-apresentacao.md`.
4. Defesa honesta da simulação por containers.
5. Se der tempo, teste em clone limpo.

Com isso, o trabalho fica apresentável e defensável. Não é “só subi ELK”; é uma demo de auditoria de logs com reprodutibilidade e roteiro claro.
