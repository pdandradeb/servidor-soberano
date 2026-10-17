#!/usr/bin/env bash
# ==============================================================================
# servidor-soberano - scripts/bootstrap.sh
# Script Mestre All-in-One de Instalação e Provisionamento do Servidor Soberano
# Instala todos os softwares essenciais de uma só vez (Debian / Raspberry Pi OS)
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/pdandradeb/servidor-soberano/main/scripts/bootstrap.sh | bash
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_err()   { echo -e "${RED}[ERRO]${NC} $1" >&2; }

echo -e "${GREEN}
  ======================================================
     🏡 SERVIDOR SOBERANO — INSTALAÇÃO MASTER ALL-IN-ONE
  ======================================================
${NC}"

# 1. Verificar privilégios sudo
if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
  log_err "Este script requer privilégios de administrador (sudo)."
  exit 1
fi
SUDO=""
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
fi

# 2. Atualização de Pacotes do Sistema Operacional
log_info "1/7. Atualizando listas de pacotes do sistema (apt update)..."
$SUDO apt-get update -y
$SUDO apt-get full-upgrade -y

# 3. Instalação do Pacote Base de Ferramentas CLI
log_info "2/7. Instalando pacote mestre de utilitários e ferramentas CLI..."
PACKAGES=(
  curl
  wget
  git
  htop
  tmux
  ufw
  rsync
  jq
  build-essential
  ca-certificates
  gnupg
  lsb-release
  poppler-utils
)

$SUDO apt-get install -y "${PACKAGES[@]}"
log_ok "Pacote base de ferramentas instalado com sucesso!"

# 4. Swap de 4GB no NVMe & Tuning de Sistema (Proteção contra OOM)
log_info "3/7. Configurando Swapfile de 4 GB no NVMe e tuning do sistema..."
if ! grep -q '/swapfile' /etc/fstab 2>/dev/null; then
  log_info "Criando swapfile de 4GB rápido no NVMe..."
  $SUDO dphys-swapfile swapoff 2>/dev/null || true
  $SUDO systemctl disable dphys-swapfile 2>/dev/null || true
  $SUDO fallocate -l 4G /swapfile 2>/dev/null || $SUDO dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
  $SUDO chmod 600 /swapfile
  $SUDO mkswap /swapfile
  $SUDO swapon /swapfile
  echo '/swapfile none swap sw,pri=10 0 0' | $SUDO tee -a /etc/fstab
  log_ok "Swapfile de 4GB ativado e persistido no fstab!"
else
  log_ok "Swapfile já configurado no sistema."
fi

# 5. Tailscale (VPN Mesh Privada)
log_info "4/7. Instalando Tailscale (VPN Mesh segura)..."
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
  log_ok "Tailscale instalado! Inicie com: sudo tailscale up --advertise-exit-node"
else
  log_ok "Tailscale já instalado."
fi

# 6. Docker & Docker Compose Plugin Oficial
log_info "5/7. Instalando Docker Engine & Docker Compose..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  # Adicionar usuário ao grupo docker
  CURRENT_USER="${SUDO_USER:-$USER}"
  if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    $SUDO usermod -aG docker "$CURRENT_USER" || true
    log_ok "Usuário $CURRENT_USER adicionado ao grupo docker."
  fi
  log_ok "Docker instalado com sucesso!"
else
  log_ok "Docker já instalado."
fi

# 7. Node.js 24 LTS & OpenClaw (O Assistente de IA no Início!)
log_info "6/7. Instalando Node.js 24 LTS e OpenClaw (Seu Agente de IA)..."
if ! command -v node &>/dev/null || [ "$(node -v | cut -d'.' -f1)" != "v24" ]; then
  curl -fsSL https://deb.nodesource.com/setup_24.x | $SUDO -E bash -
  $SUDO apt-get install -y nodejs
  log_ok "Node.js $(node -v) e npm $(npm -v) instalados!"
fi

if ! command -v openclaw &>/dev/null; then
  log_info "Instalando OpenClaw globalmente..."
  $SUDO npm install -g openclaw@latest
  log_ok "OpenClaw instalado com sucesso!"
else
  log_ok "OpenClaw já instalado ($(openclaw --version 2>/dev/null || echo 'ativo'))."
fi

# 6.1 Copiar Templates do Copiloto Soberano para o OpenClaw Workspace
WORKSPACE_DIR="/home/${CURRENT_USER}/.openclaw/workspace"
if [ -d "${WORKSPACE_DIR}" ] && [ ! -f "${WORKSPACE_DIR}/BOOTSTRAP.md" ]; then
  log_info "Configurando templates de Copiloto Soberano no workspace do OpenClaw..."
  cp -n "$(dirname "$0")/../templates/openclaw/"* "${WORKSPACE_DIR}/" 2>/dev/null || true
fi


# 8. Python uv & Typst (Opcionais de Alta Performance)
log_info "7/7. Instalando ferramentas complementares (uv e typst)..."
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh || true
fi

echo -e "${GREEN}
  ======================================================
     ✨ BOOTSTRAP MASTER CONCLUÍDO COM SUCESSO!
  ======================================================
${NC}
Todos os softwares fundamentais estão instalados:
  ✔ Pacotes base (git, tmux, htop, rsync, ufw, poppler)
  ✔ Swap de 4 GB no NVMe (estabilidade absoluta)
  ✔ Tailscale (acesso remoto seguro de qualquer lugar)
  ✔ Docker & Docker Compose
  ✔ Node.js 24 LTS
  ✔ OpenClaw (Seu assistente de IA)

👉 PRÓXIMO PASSO IMEDIATO:
   Execute o onboarding do OpenClaw para conectar seu WhatsApp e IA:
   $ openclaw onboard

Ele será seu copiloto para configurar o Pi-hole, montar o disco do Nextcloud e gerenciar o servidor!
"
