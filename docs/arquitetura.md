# Arquitetura da demonstração

```txt
+-------------------------- Host Linux / Notebook --------------------------+
|                                                                          |
|  +-------------+       +------------+       +-------------------------+   |
|  | Nginx demo  | logs  | Filebeat   | beats | Logstash                |   |
|  | :8080       +------>+ agente     +------>+ parsing/normalização    |   |
|  +-------------+       +-----+------+ :5044 +------------+------------+   |
|                              ^                           |                |
|  +--------------------+      |                           v                |
|  | sample auth.log    +------+                  +-------------------+     |
|  | SSH/sudo simulado  |                         | Elasticsearch     |     |
|  +--------------------+                         | índice so-logs-*  |     |
|                                                 +---------+---------+     |
|                                                           |               |
|                                                           v               |
|                                                 +-------------------+     |
|                                                 | Kibana :5601      |     |
|                                                 | dashboards        |     |
|                                                 +-------------------+     |
|                                                                          |
+--------------------------------------------------------------------------+
```

Em ambiente real, o bloco `Filebeat` ficaria em cada máquina cliente. No laboratório, ele roda em container e lê fontes de log locais compartilhadas por volume.
