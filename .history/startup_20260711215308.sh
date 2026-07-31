#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory where the script is located (assumed to be project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Creating required directories..."
mkdir -p ./data/searxng-data 2>/dev/null || true
mkdir -p ./data/valkey-data 2>/dev/null || true

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
