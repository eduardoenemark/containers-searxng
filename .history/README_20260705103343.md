# 🔍 SearXNG — Serviço Dedicado de Busca Privada

**Versão:** 2026.06.27  
**Engines configurados:** 55+  
**Autor:** Eduardo Vieira (Hefesto)  
**Porta padrão:** 8888  

---

## 📋 Visão Geral

SearXNG é um metaprocessador de privacidade que agrega resultados de mais de 70 mecanismos de busca. Esta configuração foi otimizada para uso privado com 55 engines ativos cobrindo:

- 🔎 **Buscas gerais:** Google, Bing, DuckDuckGo, Yahoo, Brave, Yandex, Baidu, Mojeek, Qwant, etc.
- 📱 **Redes sociais:** Reddit, HackerNews, StackOverflow, Boardreader
- 🎓 **Acadêmico:** Wikipedia, ArXiv, PubMed, OpenAlex, Semantic Scholar
- 💻 **Código:** GitHub, GitLab, SourceHut
- 📰 **Notícias:** Reuters, ResultHunter, Anna's Archive
- 🛠️ **Ferramentas:** WolframAlpha, Crossref, HuggingFace
- 🎬 **Vídeos:** YouTube, PeerTube, Odysee, Dailymotion, Vimeo
- 🖼️ **Imagens:** Google, Bing, DuckDuckGo Images
- 📰 **Notícias:** Google News, Bing News, DuckDuckGo News
- 🎵 **Música:** SoundCloud, Deezer, Radio Browser

---

## 🚀 Deploy Rápido

### Opção 1: Deploy Automatizado (Recomendado)

```bash
# Clonar ou copiar o projeto
cd /home/mxlinux/projects/searxng-8888

# Tornar script executável
chmod +x scripts/deploy.sh

# Executar deploy completo
./scripts/deploy.sh
```

### Opção 2: Deploy Manual

```bash
# Clonar ou copiar o projeto
cd /home/mxlinux/projects/searxng-8888

# Iniciar com Docker Compose
docker compose up -d --pull always

# Aguardar inicialização
sleep 10

# Verificar status
docker compose ps
```

---

## 📁 Estrutura do Projeto

```
searxng-8888/
├── docker-compose.yml      # Orquestração Docker (searxng + valkey)
├── .env                    # Variáveis de ambiente
├── config/
│   └── settings.yml        # Configuração completa do SearXNG (55 engines)
├── scripts/
│   └── deploy.sh           # Script de deploy automatizado
└── README.md               # Este arquivo
```

---

## ⚙️ Configuração

### Variáveis de Ambiente (.env)

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `SEARXNG_PORT` | 8888 | Porta do serviço |
| `SEARXNG_BIND` | 127.0.0.1 | Endereço de bind (use `[::]` ou `0.0.0.0` para externo) |
| `SEARXNG_SECRET` | gerado | Chave de criptografia (gerar com `openssl rand -hex 32`) |
| `SEARXNG_LANG` | pt-BR | Idioma padrão |
| `SEARXNG_AUTOCOMPLETE` | google | Backend de autocomplete |
| `SEARXNG_METHOD` | POST | Método de busca (POST = mais seguro) |

### Gerar Secret Key Segura

```bash
openssl rand -hex 32
```

Substituir no `.env`:

```env
SEARXNG_SECRET="<seu-novo-secret-key>"
```

---

## 🔧 Comandos Úteis

### Gerenciamento do Serviço

```bash
# Iniciar
docker compose up -d

# Parar
docker compose down

# Reiniciar
docker compose restart

# Logs ao vivo
docker compose logs -f

# Logs recentes
docker compose logs --tail=50

# Atualizar imagem
docker compose pull && docker compose up -d

# Verificar status
docker compose ps

# Executar comando no container
docker compose exec searxng bash
```

### Gerenciamento de Dados

```bash
# Backup de configurações
cp config/settings.yml config/settings.yml.backup

# Backup do banco Valkey
docker cp searxng-valkey:/data/dump.rdb ./backup-valkey.rdb

# Restaurar backup
docker compose down
docker cp ./backup-valkey.rdb searxng-valkey:/data/dump.rdb
docker compose up -d
```

---

## 🌐 Acesso e Uso

### URLs de Acesso

- **Interface principal:** http://localhost:8888
- **Stats dos engines:** http://localhost:8888/stats
- **Preferências:** http://localhost:8888/preferences
- **Sobre:** http://localhost:8888/info/en/about

### API JSON

```bash
# Busca geral
curl "http://localhost:8888/search?q=teste+python&format=json"

# Busca com categorias específicas
curl -X POST "http://localhost:8888/search" -d "q=teste+python&format=json&categories%3Ageneral=on"

# Busca com engine específico
curl -X POST "http://localhost:8888/search" -d "q=teste+python&format=json&engines=google"
```

### Integração com OpenClaw

Configurar no `openclaw.json`:

```json
{
  "tools": {
    "web": {
      "search": {
        "provider": "searxng",
        "enabled": true
      }
    }
  }
}
```

Ou via variável de ambiente:

```bash
export SEARXNG_BASE_URL="http://localhost:8888"
```

---

## 🛡️ Segurança

### Recomendações para Produção

1. **Trocar o SEARXNG_SECRET** por um valor gerado aleatoriamente
2. **Configurar firewall** para liberar apenas a porta necessária
3. **Usar HTTPS** com reverse proxy (nginx, caddy, etc.)
4. **Restringir IP** se necessário via `SEARXNG_BIND`
5. **Atualizar regularmente:** `docker compose pull && docker compose up -d`

### Exemplo com Nginx + HTTPS

```nginx
server {
    listen 443 ssl;
    server_name search.seuservidor.com;
    
    ssl_certificate /etc/letsencrypt/live/search.seuservidor.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/search.seuservidor.com/privkey.pem;
    
    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 🐛 Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker compose logs searxng

# Verificar configurações
docker compose config

# Recriar containers
docker compose down --remove-orphans
docker compose up -d
```

### Erro "unhealthy"

O health check pode falhar se `curl` não estiver disponível dentro do container. O serviço funciona normalmente mesmo com esse alerta. Para resolver:

```bash
# Opção 1: Usar healthcheck alternativo (já configurado no docker-compose.yml)
# A imagem mais recente usa python3 para o healthcheck

# Opção 2: Ignorar o status unhealthy (não afeta funcionamento)
docker compose ps  # Verificar se container está "Up"
```

### Engines retornando 0 resultados

1. Verificar conectividade com a internet
2. Verificar logs de erros específicos:
   ```bash
   docker compose logs --tail=100 searxng | grep -i error
   ```
3. Alguns engines podem estar suspensos temporariamente (timeout de 24h após erro)

### Atualizar SearXNG

```bash
# Script automatizado
./scripts/deploy.sh update

# Manual
docker compose pull
docker compose up -d --remove-orphans
```

---

## 📊 Engines Configurados (55)

### Buscas Gerais (15)
Google, Bing, DuckDuckGo, Yahoo, Brave, Yandex, Baidu, Baidu Images, Baidu Kaifa, Mojeek, Qwant, Searxng, Yep, Privacywall, SepiaSearch

### Redes Sociais e Fóruns (4)
Reddit, HackerNews, StackOverflow, Boardreader

### Acadêmico e Científico (10)
Wikipedia, Wikibooks, Wikiquote, Wikisource, Wikivoyage, Wiktionary, PubMed, ArXiv, OpenAlex, Semantic Scholar

### Código e Desenvolvimento (3)
GitHub, GitLab, SourceHut

### Notícias e Mídia (3)
Reuters, ResultHunter, Anna's Archive

### Ferramentas e Utilitários (4)
WolframAlpha, DuckDuckGo Definitions, Crossref, HuggingFace

### Vídeos (5)
PeerTube, Odysee, Dailymotion, YouTube, Vimeo

### Imagens (3)
Google Images, Bing Images, DuckDuckGo Images

### Notícias (3)
Google News, Bing News, DuckDuckGo News

### Música e Áudio (3)
SoundCloud, Deezer, Radio Browser

### Pesquisa Geral Adicional (2)
Dogpile, Ecosia

---

## 📝 Histórico de Configuração

- **2026-04-03:** SearXNG identificado como solução multi-busca
- **2026-05-28:** Primeira configuração com Docker Compose (porta 8890)
- **2026-06-27:** Reconfiguração completa após reboot da VM
  - Migrado para porta 8888
  - 55 engines ativados
  - Yandex e Baidu adicionados
  - Startpage desabilitado (bug na versão 2026.6.22)
  - OpenClaw configurado com provider searxng

---

## 🔗 Referências

- **SearXNG Oficial:** https://github.com/searxng/searxng
- **Documentação:** https://docs.searxng.org/
- **Instâncias Públicas:** https://searx.space/
- **OpenClaw Docs:** https://docs.openclaw.ai

---

## 📞 Suporte

Para problemas ou dúvidas, consultar:
- Logs: `docker compose logs searxng`
- Status: `docker compose ps`
- Config: `config/settings.yml`

---

**Última atualização:** 2026-06-27  
**Deploy por:** Hefesto 🔨
