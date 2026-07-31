#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory where the script is located (assumed to be project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Creating required directories..."
mkdir -p ./data/searxng-data 2>/dev/null || true
mkdir -p ./data/valkey-data 2>/dev/null || true

echo "📝 Checking environment configuration (.env)..."
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating default configuration..."
    cat > .env << 'EOF'
# Porta do serviço (padrão: 8888)
SEARXNG_PORT=8888

# Endereço de bind (recomendado: 127.0.0.1 para acesso local)
# Para acesso externo: [::] ou 0.0.0.0
SEARXNG_BIND=127.0.0.1

# Secret key para criptografia de sessões (gerar nova em produção!)
# Gerar com: openssl rand -hex 32
SEARXNG_SECRET="searxng"

# Idioma padrão das buscas
SEARXNG_LANG=pt-BR

# Autocomplete backend (google, bing, duckduckgo)
SEARXNG_AUTOCOMPLETE=google

# Habilitar métricas (opcional)
SEARXNG_METRICS=false

# Proxy de imagens (false = não usar proxy)
SEARXNG_IMAGE_PROXY=false

# Método de busca (POST = mais seguro, GET = mais amigável)
SEARXNG_METHOD=POST

# Safe search (0=off, 1=moderate, 2=strict)
SEARXNG_SAFE_SEARCH=0

# Máximo de páginas nos resultados (0 = ilimitado)
SEARXNG_MAX_PAGE=0
EOF
    echo "✅ Default .env created. Edit it to change the port or add secrets."
fi

echo "🚀 Starting SearXNG with podman Compose..."
podman-compose up --remove-orphans

# Safely extract port for display
SEARXNG_PORT_VAL=$(grep -E '^SEARXNG_PORT=' .env | cut -d'=' -f2 2>/dev/null || true)
[ -z "$SEARXNG_PORT_VAL" ] && SEARXNG_PORT_VAL=8888

echo ""
echo "✅ Deployment complete!"
echo "🌐 SearXNG is running at: http://localhost:${SEARXNG_PORT_VAL}"
echo "📊 Live logs: podman compose logs -f searxng"
echo "⏹️  Stop & remove volumes: podman compose down -v"
