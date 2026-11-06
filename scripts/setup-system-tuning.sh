#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/setup-system-tuning.sh
# Tuning de estabilidade, swap e contenção de memória para Raspberry Pi 5 (2 GB RAM)
# Previne congelamentos por memory pressure, esgotamento de zram e resets de watchdog.
# ==============================================================================

TARGET_HOST="${1:-raspd}"

echo "======================================================"
echo " 🛡️  Aplicando System Tuning & Estabilização em: $TARGET_HOST"
echo "======================================================"

ssh -o BatchMode=yes "$TARGET_HOST" bash << 'REMOTE_SCRIPT'
set -euo pipefail

echo "▶ 1. Configurando Swapfile de 16 GB no SSD NVMe (Buffer de Transbordamento)..."
if [[ ! -f /swapfile16 ]] && [[ ! -f /swapfile ]]; then
  echo "  - Alocando 16 GB em /swapfile16..."
  sudo fallocate -l 16G /swapfile16 || sudo dd if=/dev/zero of=/swapfile16 bs=1M count=16384
  sudo chmod 600 /swapfile16
  sudo mkswap /swapfile16
fi

TARGET_SWAP="/swapfile16"
[[ -f /swapfile ]] && TARGET_SWAP="/swapfile"

# Ativa swapfile com prioridade menor que a do zram (pri=10) se ainda não estiver ativo
if ! swapon --show | grep -q "$TARGET_SWAP"; then
  echo "  - Ativando $TARGET_SWAP com prioridade 10..."
  sudo swapon -p 10 "$TARGET_SWAP"
fi

# Persistência no /etc/fstab
if ! grep -q "$TARGET_SWAP" /etc/fstab; then
  echo "  - Registrando $TARGET_SWAP no /etc/fstab..."
  echo "$TARGET_SWAP none swap sw,pri=10 0 0" | sudo tee -a /etc/fstab
fi
echo "  ✓ Swap configurado:"
swapon --show

echo "▶ 2. Relaxando timeout do Hardware Watchdog do systemd para 5 minutos..."
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/99-watchdog-relax.conf > /dev/null << 'EOF'
[Manager]
RuntimeWatchdogSec=5m
RebootWatchdogSec=5m
EOF
sudo systemctl daemon-reexec
echo "  ✓ Watchdog atualizado:"
systemctl show -p RuntimeWatchdogUSec -p RebootWatchdogUSec

echo "▶ 3. Desativando interface gráfica de desktop (Modo Headless puro)..."
if [[ "$(systemctl get-default)" != "multi-user.target" ]]; then
  sudo systemctl set-default multi-user.target
  sudo systemctl stop lightdm 2>/dev/null || true
  echo "  ✓ Modo headless definido como padrão (multi-user.target)."
else
  echo "  ✓ Sistema já configurado em modo headless (multi-user.target)."
fi

echo "▶ 4. Habilitando journald persistente (/var/log/journal)..."
sudo sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sudo sed -i 's/Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
echo "  ✓ Journald configurado para armazenamento persistente."

echo "▶ 5. Ajustando limite de memória do serviço OpenClaw (768 MB)..."
OPENCLAW_SERVICE="$HOME/.config/systemd/user/openclaw-gateway.service"
if [[ -f "$OPENCLAW_SERVICE" ]]; then
  sed -i -E 's/--max-old-space-size=[0-9]+/--max-old-space-size=768/g' "$OPENCLAW_SERVICE"
  systemctl --user daemon-reload
  echo "  ✓ openclaw-gateway.service ajustado com --max-old-space-size=768."
fi

REMOTE_SCRIPT

echo ""
echo "======================================================"
echo " ✅ Estabilização e Tuning aplicados com sucesso em $TARGET_HOST!"
echo "======================================================"
