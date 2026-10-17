#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/setup-openclaw.sh
# Instalação automatizada e idempotente do OpenClaw no Raspberry Pi (raspd)
# Modo: Nativo (Node.js 24 LTS + systemd user service + chave SSH GitHub)
# ==============================================================================

TARGET_HOST="${1:-raspd}"

echo "======================================================"
echo " 🤖 Provisionando OpenClaw em: $TARGET_HOST"
echo "======================================================"

ssh -o BatchMode=yes "$TARGET_HOST" bash << 'REMOTE_SCRIPT'
set -euo pipefail

echo "▶ 1. Verificando Node.js e runtime..."
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d 'v')" -lt 24 ]]; then
  echo "  - Instalando Node.js 24 LTS via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
echo "  ✓ Node.js $(node -v) e npm $(npm -v) prontos."

echo "▶ 2. Verificando instalação global do OpenClaw..."
if ! command -v openclaw >/dev/null 2>&1; then
  echo "  - Instalando OpenClaw via npm global..."
  sudo npm install -g openclaw
fi
echo "  ✓ OpenClaw $(openclaw --version) instalado."

echo "▶ 3. Configurando chave SSH dedicada para o GitHub..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [[ ! -f ~/.ssh/id_openclaw ]]; then
  echo "  - Gerando nova chave Ed25519 (~/.ssh/id_openclaw)..."
  ssh-keygen -t ed25519 -C "openclaw@raspd" -f ~/.ssh/id_openclaw -N ""
else
  echo "  ✓ Chave SSH existente em ~/.ssh/id_openclaw."
fi

# Configurar alias github.com no ~/.ssh/config se ainda não estiver presente
if ! grep -q "IdentityFile ~/.ssh/id_openclaw" ~/.ssh/config 2>/dev/null; then
  cat << 'EOF' >> ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_openclaw
  StrictHostKeyChecking accept-new
EOF
  chmod 600 ~/.ssh/config
  echo "  ✓ ~/.ssh/config configurado para autenticar no GitHub via id_openclaw."
fi

echo "▶ 4. Inicializando diretórios base do OpenClaw..."
if [[ ! -f ~/.openclaw/openclaw.json ]]; then
  openclaw setup --baseline
else
  echo "  ✓ Configuração base existente em ~/.openclaw/openclaw.json."
fi

echo "▶ 5. Criando diretório de backup persistente no HDD de 3.6TB..."
sudo mkdir -p /mnt/toshiba/backups/openclaw
sudo chown -R $(id -u):$(id -g) /mnt/toshiba/backups/openclaw

echo "▶ 6. Garantindo limite de memória no serviço systemd do OpenClaw (768 MB)..."
OPENCLAW_SERVICE="$HOME/.config/systemd/user/openclaw-gateway.service"
if [[ -f "$OPENCLAW_SERVICE" ]]; then
  sed -i -E 's/--max-old-space-size=[0-9]+/--max-old-space-size=768/g' "$OPENCLAW_SERVICE"
  systemctl --user daemon-reload
  echo "  ✓ openclaw-gateway.service ajustado para max-old-space-size=768."
fi

echo ""
echo "======================================================"
echo " 🔑 Chave Pública SSH do OpenClaw para o GitHub:"
echo "======================================================"
cat ~/.ssh/id_openclaw.pub
echo "======================================================"
echo ""
echo "Instruções:"
echo "1. Copie a chave acima e adicione no GitHub (https://github.com/settings/keys) ou nos Deploy Keys do seu repositório."
echo "2. Para testar o acesso: ssh raspd 'ssh -T git@github.com'"
echo "3. Para iniciar o assistente interativo: ssh raspd -t 'openclaw configure' ou 'openclaw onboard'"
echo "4. Para habilitar o gateway como serviço permanente de segundo plano: ssh raspd 'openclaw daemon install'"
echo "======================================================"
REMOTE_SCRIPT
