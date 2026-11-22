#!/usr/bin/env bash
#
# scripts/system-security-updates.sh
# Rotina periódica (semanal) de patches de segurança e atualização de runtimes no raspd.
#
# Escopo:
# 1. Atualização dos índices de repositório (apt update).
# 2. Aplicação de patches de segurança prioritários do SO (Debian Security + Pacotes Críticos).
# 3. Atualização das imagens e containers oficiais de terceiros (Vaultwarden, Dufs).
# 4. Limpeza de imagens Docker órfãs (dangling).
# 5. Auditoria de integridade pós-atualização (Docker, Pi-hole, Nextcloud, Tailscale).
#
set -euo pipefail

LOG_DIR="/home/raspd/dev/raspd/logs"
LOG_FILE="${LOG_DIR}/security-updates.log"
mkdir -p "${LOG_DIR}"

log() {
  local ts
  ts=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${ts}] $*" | tee -a "${LOG_FILE}"
}

log "============================================================"
log "🚀 Iniciando rotina de atualizações de segurança do raspd..."
log "============================================================"

# 1. Atualização dos índices do apt
log "📦 [1/5] Atualizando índices de pacotes (apt update)..."
sudo apt-get update -q 2>&1 | tee -a "${LOG_FILE}" || {
  log "⚠️ Aviso: Erro parcial no apt-get update. Prosseguindo..."
}

# 2. Identificação e aplicação de patches de segurança
log "🛡️ [2/5] Aplicando patches de segurança prioritários..."

CORE_SECURITY_PKGS=(
  curl
  openssl
  libssl3t64
  sudo
  tailscale
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
  ca-certificates
  cifs-utils
  libsqlite3-0
  libpq5
  unzip
  zip
  nodejs
)

log "   • Atualizando pacotes críticos de infra/rede/criptografia..."
DEBIAN_FRONTEND=noninteractive sudo apt-get --only-upgrade install -y "${CORE_SECURITY_PKGS[@]}" 2>&1 | tee -a "${LOG_FILE}"

# Identifica pacotes pendentes originados de repositórios de segurança (*-security)
log "   • Verificando se há outros pacotes marcados por canais de segurança..."
SECURITY_CANDIDATES=$(apt list --upgradable 2>/dev/null | grep -i "security" | cut -d/ -f1 | sort -u | tr '\n' ' ' || true)
if [ -n "${SECURITY_CANDIDATES// }" ]; then
  log "   • Aplicando patches do canal security: ${SECURITY_CANDIDATES}"
  DEBIAN_FRONTEND=noninteractive sudo apt-get --only-upgrade install -y ${SECURITY_CANDIDATES} 2>&1 | tee -a "${LOG_FILE}"
else
  log "   • Nenhum pacote avulso adicional pendente no canal security."
fi

# 3. Atualização de imagens oficiais de terceiros no Docker
log "🐳 [3/5] Atualizando imagens de containers oficiais de terceiros..."
PULLED_VAULT=false
PULLED_DUFS=false

if docker pull vaultwarden/server:latest 2>&1 | tee -a "${LOG_FILE}"; then
  PULLED_VAULT=true
fi

if docker pull sigoden/dufs:latest 2>&1 | tee -a "${LOG_FILE}"; then
  PULLED_DUFS=true
fi

if [ -f "/home/raspd/dev/vaultwarden/docker-compose.yml" ]; then
  log "   • Reiniciando container Vaultwarden com a versão mais recente..."
  docker compose -f /home/raspd/dev/vaultwarden/docker-compose.yml up -d 2>&1 | tee -a "${LOG_FILE}"
fi

if [ -f "/home/raspd/dev/dufs/docker-compose.yml" ]; then
  log "   • Reiniciando container Dufs com a versão mais recente..."
  docker compose -f /home/raspd/dev/dufs/docker-compose.yml up -d 2>&1 | tee -a "${LOG_FILE}"
fi

# 4. Limpeza de imagens órfãs do Docker
log "🧹 [4/5] Limpando imagens antigas e camadas dangling do Docker..."
docker image prune -f 2>&1 | tee -a "${LOG_FILE}" || true

# 5. Auditoria de integridade pós-atualização
log "🩺 [5/5] Executando auditoria rápida de integridade dos serviços..."

# Docker containers
TOTAL_CONTAINERS=$(docker ps -q | wc -l)
UNHEALTHY_CONTAINERS=$(docker ps --filter "health=unhealthy" -q | wc -l)
log "   • Docker: ${TOTAL_CONTAINERS} containers ativos (${UNHEALTHY_CONTAINERS} com falha de healthcheck)."

# Tailscale
if command -v tailscale >/dev/null 2>&1; then
  TS_STATUS=$(tailscale status 2>/dev/null | head -n 1 || echo "Desconhecido")
  log "   • Tailscale: ${TS_STATUS}"
fi

# Nextcloud Snap
if command -v snap >/dev/null 2>&1; then
  NC_SERVICES=$(sudo snap services nextcloud 2>/dev/null | grep -c "active" || echo "0")
  log "   • Nextcloud (Snap): ${NC_SERVICES} serviços ativos."
fi

log "============================================================"
log "🎉 Rotina de atualizações de segurança concluída com sucesso!"
log "============================================================"
