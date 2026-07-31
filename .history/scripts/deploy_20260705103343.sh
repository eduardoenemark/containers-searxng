# #!/bin/bash
# # SearXNG — Script de Deploy para Servidor Dedicado
# # Versão: 2026.06.27
# #
# # Uso:
# #   chmod +x scripts/deploy.sh
# #   ./scripts/deploy.sh          # Deploy completo
# #   ./scripts/deploy.sh --update # Atualizar versão

# set -e

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# echo "🔨 SearXNG Deploy Script"
# echo "========================"
# echo "Projeto: $PROJECT_DIR"
# echo ""

# # Verificar se é root ou tem sudo
# if [ "$EUID" -ne 0 ]; then
#     echo "⚠️  Este script precisa de sudo para instalar dependências."
#     echo "   Executando com sudo..."
#     echo "kali" | sudo -S "$0" "$@"
#     exit $?
# fi

# # Função de log
# log() {
#     echo "📦 [$(date '+%Y-%m-%d %H:%M:%S')] $1"
# }

# # Verificar requisitos
# check_requirements() {
#     log "Verificando requisitos..."
    
#     if ! command -v docker &> /dev/null; then
#         log "Instalando Docker..."
#         curl -fsSL https://get.docker.com | sh
#         usermod -aG docker $(whoami)
#     fi
    
#     if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
#         log "Docker Compose plugin não encontrado..."
#         if command -v docker &> /dev/null; then
#             log "Usando 'docker compose' (plugin integrado)..."
#         else
#             log "Instalando Docker Compose..."
#             curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#             chmod +x /usr/local/bin/docker-compose
#         fi
#     fi
    
#     log "✅ Requisitos atendidos"
# }

# # Configurar firewall
# setup_firewall() {
#     local PORT="${1:-8888}"
    
#     log "Configurando firewall para porta $PORT..."
    
#     if command -v ufw &> /dev/null; then
#         ufw allow ${PORT}/tcp 2>/dev/null || true
#         log "✅ UFW configurado (porta $PORT)"
#     elif command -v firewall-cmd &> /dev/null; then
#         firewall-cmd --permanent --add-port=${PORT}/tcp 2>/dev/null || true
#         firewall-cmd --reload 2>/dev/null || true
#         log "✅ firewalld configurado (porta $PORT)"
#     else
#         log "⚠️  Nenhum firewall detectado. Considere configurar manualmente."
#     fi
# }

# # Gerar secret key segura
# generate_secret() {
#     if [ -z "$SEARXNG_SECRET" ]; then
#         SEARXNG_SECRET=$(openssl rand -hex 32)
#         log "🔐 Secret key gerada: $SEARXNG_SECRET"
#     fi
# }

# # Deploy do serviço
# deploy() {
#     local MODE="${1:-production}"
    
#     cd "$PROJECT_DIR"
    
#     log "Preparando ambiente..."
    
#     # Verificar se .env existe
#     if [ ! -f .env ]; then
#         cp .env.example .env 2>/dev/null || true
#     fi
    
#     # Gerar secret key se não existir
#     generate_secret
    
#     log "Iniciando containers Docker..."
#     docker compose up -d --pull always
    
#     log "Aguardando inicialização..."
#     sleep 10
    
#     # Verificar status
#     if docker compose ps | grep -q "healthy"; then
#         log "✅ SearXNG está saudável!"
#     else
#         log "⚠️  Verificando logs..."
#         docker compose logs --tail=20 searxng
#     fi
    
#     log ""
#     log "🎉 Deploy concluído!"
#     log "📍 Acesso: http://localhost:$SEARXNG_PORT"
#     log "📊 Stats: http://localhost:$SEARXNG_PORT/stats"
#     log "⚙️  Preferences: http://localhost:$SEARXNG_PORT/preferences"
#     log ""
#     log "🔧 Comandos úteis:"
#     log "   docker compose logs -f          # Logs ao vivo"
#     log "   docker compose down             # Parar serviço"
#     log "   docker compose restart          # Reiniciar"
#     log "   docker compose pull && up -d    # Atualizar"
# }

# # Atualização
# update() {
#     cd "$PROJECT_DIR"
    
#     log "Atualizando SearXNG..."
#     docker compose pull
#     docker compose up -d --remove-orphans
    
#     log "✅ Atualização concluída!"
# }

# # Status
# status() {
#     cd "$PROJECT_DIR"
#     docker compose ps
# }

# # Main
# case "${1:-deploy}" in
#     deploy)
#         check_requirements
#         setup_firewall 8888
#         deploy "production"
#         ;;
#     update)
#         update
#         ;;
#     status)
#         status
#         ;;
#     stop)
#         cd "$PROJECT_DIR"
#         docker compose down
#         log "⏹️  Serviço parado"
#         ;;
#     start)
#         cd "$PROJECT_DIR"
#         docker compose up -d
#         log "▶️  Serviço iniciado"
#         ;;
#     logs)
#         cd "$PROJECT_DIR"
#         docker compose logs -f
#         ;;
#     *)
#         echo "Uso: $0 {deploy|update|status|stop|start|logs}"
#         exit 1
#         ;;
# esac
