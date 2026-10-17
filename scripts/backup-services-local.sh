#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/backup-services-local.sh
# Snapshot diário local dos volumes/dados de serviços em raspd para o HDD externo
# Executado via cron local diariamente às 03:30
# ==============================================================================

BACKUP_ROOT="/mnt/toshiba/backups/services"
TODAY="$(date +%Y%m%d)"
mkdir -p "$BACKUP_ROOT"

# 1. Filminhos Kanban
KANBAN_DATA="/home/raspd/dev/filminhos-kanban/data/board.json"
KANBAN_DEST="$BACKUP_ROOT/filminhos-kanban"
if [[ -f "$KANBAN_DATA" ]]; then
  mkdir -p "$KANBAN_DEST"
  cp -f "$KANBAN_DATA" "$KANBAN_DEST/board.json"
  cp -f "$KANBAN_DATA" "$KANBAN_DEST/board-$TODAY.json"
  find "$KANBAN_DEST" -name "board-*.json" -mtime +14 -delete 2>/dev/null || true
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup do Kanban realizado com sucesso."
fi

# 2. Checklist Viagem
CHECKLIST_DATA="/home/raspd/dev/checklist-viagem/data/trips.json"
CHECKLIST_DEST="$BACKUP_ROOT/checklist-viagem"
if [[ -f "$CHECKLIST_DATA" ]]; then
  mkdir -p "$CHECKLIST_DEST"
  cp -f "$CHECKLIST_DATA" "$CHECKLIST_DEST/trips.json"
  cp -f "$CHECKLIST_DATA" "$CHECKLIST_DEST/trips-$TODAY.json"
  find "$CHECKLIST_DEST" -name "trips-*.json" -mtime +14 -delete 2>/dev/null || true
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup do Checklist Viagem realizado com sucesso."
fi

# 3. Racha Contas
RACHA_DATA="/home/raspd/dev/racha-contas/data/racha.json"
RACHA_DEST="$BACKUP_ROOT/racha-contas"
if [[ -f "$RACHA_DATA" ]]; then
  mkdir -p "$RACHA_DEST"
  cp -f "$RACHA_DATA" "$RACHA_DEST/racha.json"
  cp -f "$RACHA_DATA" "$RACHA_DEST/racha-$TODAY.json"
  find "$RACHA_DEST" -name "racha-*.json" -mtime +14 -delete 2>/dev/null || true
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup do Racha Contas realizado com sucesso."
fi

# 4. Mon Carnet Français
CARNET_DATA="/home/raspd/dev/caderno-frances/data/cards.json"
CARNET_DEST="$BACKUP_ROOT/caderno-frances"
if [[ -f "$CARNET_DATA" ]]; then
  mkdir -p "$CARNET_DEST"
  cp -f "$CARNET_DATA" "$CARNET_DEST/cards.json"
  cp -f "$CARNET_DATA" "$CARNET_DEST/cards-$TODAY.json"
  find "$CARNET_DEST" -name "cards-*.json" -mtime +14 -delete 2>/dev/null || true
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup do Caderno de Francês realizado com sucesso."
fi

# 5. Vaultwarden (Cofre de Senhas e Cartões)
VAULT_DATA="/home/raspd/dev/vaultwarden/data"
VAULT_DEST="$BACKUP_ROOT/vaultwarden"
if [[ -d "$VAULT_DATA" ]]; then
  mkdir -p "$VAULT_DEST"
  # Criar snapshot tar.gz compactado dos dados cifrados (db.sqlite3, chaves rsa e anexos)
  tar -czf "$VAULT_DEST/vaultwarden-$TODAY.tar.gz" -C "$VAULT_DATA" .
  # Cópia do último estado
  cp -f "$VAULT_DEST/vaultwarden-$TODAY.tar.gz" "$VAULT_DEST/vaultwarden-latest.tar.gz"
  # Reter últimos 30 dias de snapshots do cofre
  find "$VAULT_DEST" -name "vaultwarden-*.tar.gz" -mtime +30 -delete 2>/dev/null || true
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backup do Vaultwarden realizado com sucesso em $VAULT_DEST/vaultwarden-latest.tar.gz"
fi

sudo chown -R 1000:1000 "$BACKUP_ROOT" 2>/dev/null || true
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Todos os backups locais de serviços concluídos com sucesso!"
