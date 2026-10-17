#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/nextcloud-daily-scan.sh
# Rotina diária de varredura e indexação de alterações físicas no Acervo do Nextcloud
# Executada via cron às 04:00 da manhã
# ==============================================================================

LOG_FILE="/home/raspd/dev/raspd/scripts/nextcloud-scan.log"
echo "[$(date)] ======================================================" >> "$LOG_FILE"
echo "[$(date)] Iniciando varredura diária do Nextcloud (files:scan)..." >> "$LOG_FILE"

# Roda o scan no caminho do Acervo
sudo /snap/bin/nextcloud.occ files:scan --path="raspd/files" >> "$LOG_FILE" 2>&1
status=$?

if [[ $status -eq 0 ]]; then
  echo "[$(date)] ✓ Varredura diária concluída com sucesso!" >> "$LOG_FILE"
else
  echo "[$(date)] ⚠ Aviso: files:scan retornou código $status." >> "$LOG_FILE"
fi
echo "[$(date)] ======================================================" >> "$LOG_FILE"
