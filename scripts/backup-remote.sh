#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/backup-remote.sh
# Automação de backup remoto para Pi-hole v6, Nextcloud Snap e OpenClaw em 'raspd'
# Salva cópia local no HDD de 3.6TB (/mnt/toshiba/backups) e sincroniza via rsync.
# ==============================================================================

TARGET_HOST="raspd"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DEFAULT_LOCAL_DEST="$HOME/backups/raspd"
LOCAL_DEST=""
INCLUDE_FTL_DB=false
SKIP_PULL=false
SKIP_NEXTCLOUD=false
SKIP_PIHOLE=false
SKIP_OPENCLAW=false
SKIP_SERVICES=false
REMOTE_RETENTION=5

usage() {
  cat <<EOF
Uso: $(basename "$0") [opções]

Opções:
  -t, --target HOST          Hostname ou alias SSH de destino (padrão: raspd)
  -d, --dest DIR             Diretório local para armazenar o backup (padrão: $DEFAULT_LOCAL_DEST/<TIMESTAMP>)
  --include-ftl-db           Incluir histórico de queries do Pi-hole (~400MB)
  --skip-pull                Apenas gerar backup remoto em /mnt/toshiba/backups/ sem transferir
  --skip-nextcloud           Não executar backup do Nextcloud
  --skip-pihole              Não executar backup do Pi-hole
  --skip-openclaw            Não executar backup do OpenClaw
  --skip-services            Não executar backup dos serviços Docker (/home/raspd/dev/*/data)
  --retention NUM            Quantidade de backups a manter no Raspberry Pi (padrão: 5)
  -h, --help                 Exibir esta ajuda
EOF
  exit 0
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET_HOST="$2"; shift 2 ;;
    -d|--dest) LOCAL_DEST="$2"; shift 2 ;;
    --include-ftl-db) INCLUDE_FTL_DB=true; shift ;;
    --skip-pull) SKIP_PULL=true; shift ;;
    --skip-nextcloud) SKIP_NEXTCLOUD=true; shift ;;
    --skip-pihole) SKIP_PIHOLE=true; shift ;;
    --skip-openclaw) SKIP_OPENCLAW=true; shift ;;
    --skip-services) SKIP_SERVICES=true; shift ;;
    --retention) REMOTE_RETENTION="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Opção desconhecida: $1" >&2; usage ;;
  esac
done

if [[ -z "$LOCAL_DEST" ]]; then
  LOCAL_DEST="$DEFAULT_LOCAL_DEST/$TIMESTAMP"
fi

echo "======================================================"
echo " Início do Backup de $TARGET_HOST — $TIMESTAMP"
echo "======================================================"
echo "Destino remoto: /mnt/toshiba/backups/$TIMESTAMP"
if [[ "$SKIP_PULL" == false ]]; then
  echo "Destino local:  $LOCAL_DEST"
fi
echo ""

# 1. Preparar diretório remoto no Raspberry Pi
echo "📁 [1/7] Preparando diretório de backup no Raspberry Pi..."
ssh -o BatchMode=yes "$TARGET_HOST" bash -c "'
  sudo mkdir -p /mnt/toshiba/backups/$TIMESTAMP
  sudo chown -R \$(id -u):\$(id -g) /mnt/toshiba/backups/$TIMESTAMP
'"

# 2. Backup do Pi-hole v6
if [[ "$SKIP_PIHOLE" == false ]]; then
  echo "🛡️  [2/7] Executando snapshot do Pi-hole v6..."
  ssh -o BatchMode=yes "$TARGET_HOST" bash -c "'
    REMOTE_DIR=\"/mnt/toshiba/backups/$TIMESTAMP\"
    EXCLUDE_ARG=\"\"
    if [[ \"$INCLUDE_FTL_DB\" != \"true\" ]]; then
      EXCLUDE_ARG=\"--exclude=pihole-FTL.db*\"
    fi

    echo \"  - Compactando /etc/pihole...\"
    sudo tar \$EXCLUDE_ARG -czf \"\$REMOTE_DIR/pihole-backup-$TIMESTAMP.tar.gz\" -C /etc pihole \$(test -d /etc/dnsmasq.d && echo -n \"dnsmasq.d\" || true)
    sudo chown \$(id -u):\$(id -g) \"\$REMOTE_DIR/pihole-backup-$TIMESTAMP.tar.gz\"
    ls -lh \"\$REMOTE_DIR/pihole-backup-$TIMESTAMP.tar.gz\"
  '"
else
  echo "⏩ [2/7] Backup do Pi-hole ignorado (--skip-pihole)."
fi

# 3. Backup do Nextcloud Snap
if [[ "$SKIP_NEXTCLOUD" == false ]]; then
  echo "☁️  [3/7] Executando export do Nextcloud (banco, config, apps e dados)..."
  ssh -o BatchMode=yes "$TARGET_HOST" bash -c "'
    REMOTE_DIR=\"/mnt/toshiba/backups/$TIMESTAMP\"
    echo \"  - Executando nextcloud.export...\"
    sudo /snap/bin/nextcloud.export -abcd
    
    # Localizar o diretório exportado mais recente
    EXPORT_DIR=\$(sudo ls -td /var/snap/nextcloud/common/backups/* | head -n 1)
    if [[ -d \"\$EXPORT_DIR\" ]]; then
      echo \"  - Compactando \$EXPORT_DIR para o HDD externo...\"
      sudo tar -czf \"\$REMOTE_DIR/nextcloud-backup-$TIMESTAMP.tar.gz\" -C \"\$EXPORT_DIR\" .
      sudo chown \$(id -u):\$(id -g) \"\$REMOTE_DIR/nextcloud-backup-$TIMESTAMP.tar.gz\"
      sudo rm -rf \"\$EXPORT_DIR\"
      ls -lh \"\$REMOTE_DIR/nextcloud-backup-$TIMESTAMP.tar.gz\"
    else
      echo \"ERRO: Diretório de export do Nextcloud não encontrado!\" >&2
      exit 1
    fi
  '"
else
  echo "⏩ [3/7] Backup do Nextcloud ignorado (--skip-nextcloud)."
fi

# 4. Backup do OpenClaw
if [[ "$SKIP_OPENCLAW" == false ]]; then
  echo "🤖 [4/7] Executando snapshot do OpenClaw (configurações, sessões e workspace)..."
  ssh -o BatchMode=yes "$TARGET_HOST" bash -c "'
    REMOTE_DIR=\"/mnt/toshiba/backups/$TIMESTAMP\"
    if command -v openclaw >/dev/null 2>&1 && [[ -d ~/.openclaw ]]; then
      echo \"  - Executando openclaw backup create...\"
      openclaw backup create --verify --output \"\$REMOTE_DIR\"
      sudo mkdir -p /mnt/toshiba/backups/openclaw
      sudo cp -f \"\$REMOTE_DIR\"/*openclaw-backup*.tar.gz /mnt/toshiba/backups/openclaw/ 2>/dev/null || true
      sudo chown -R \$(id -u):\$(id -g) /mnt/toshiba/backups/openclaw
      ls -lh \"\$REMOTE_DIR\"/*openclaw-backup*.tar.gz 2>/dev/null || true
    else
      echo \"  - OpenClaw não instalado ou não inicializado. Ignorando.\"
    fi
  '"
else
  echo "⏩ [4/7] Backup do OpenClaw ignorado (--skip-openclaw)."
fi

# 5. Backup dos Serviços Docker (Filminhos Kanban e dados de apps)
if [[ "$SKIP_SERVICES" == false ]]; then
  echo "🐳 [5/7] Executando snapshot dos serviços Docker (Filminhos Kanban / volumes)..."
  ssh -o BatchMode=yes "$TARGET_HOST" bash -c "'
    REMOTE_DIR=\"/mnt/toshiba/backups/$TIMESTAMP\"
    SERVICES_DIR=\"/home/raspd/dev\"
    if [[ -d \"\$SERVICES_DIR\" ]]; then
      echo \"  - Compactando dados de /home/raspd/dev/*/data...\"
      sudo tar -czf \"\$REMOTE_DIR/services-backup-$TIMESTAMP.tar.gz\" \
        --exclude=\"node_modules\" \
        --exclude=\".git\" \
        -C \"\$SERVICES_DIR\" \$(cd \"\$SERVICES_DIR\" && ls -d */data 2>/dev/null || true)
      sudo chown \$(id -u):\$(id -g) \"\$REMOTE_DIR/services-backup-$TIMESTAMP.tar.gz\"
      
      # Cópia direta do board para a pasta persistente do serviço no HDD externo
      sudo mkdir -p /mnt/toshiba/backups/services/filminhos-kanban
      if [[ -f \"/home/raspd/dev/filminhos-kanban/data/board.json\" ]]; then
        sudo cp -f /home/raspd/dev/filminhos-kanban/data/board.json /mnt/toshiba/backups/services/filminhos-kanban/board.json
        sudo chown -R \$(id -u):\$(id -g) /mnt/toshiba/backups/services
      fi
      ls -lh \"\$REMOTE_DIR/services-backup-$TIMESTAMP.tar.gz\" 2>/dev/null || true
    fi
  '"
else
  echo "⏩ [5/7] Backup dos Serviços ignorado (--skip-services)."
fi

# 6. Gerar manifesto e aplicar retenção no host remoto
echo "📝 [6/7] Gerando manifesto e aplicando política de retenção..."
ssh -o BatchMode=yes "$TARGET_HOST" "bash -s -- $TIMESTAMP $TARGET_HOST $REMOTE_RETENTION" << 'REMOTE_MANIFEST'
  set -euo pipefail
  TIMESTAMP="$1"
  TARGET_HOST="$2"
  REMOTE_RETENTION="$3"
  REMOTE_DIR="/mnt/toshiba/backups/$TIMESTAMP"
  cd "$REMOTE_DIR"
  sha256sum *.tar.gz > SHA256SUMS 2>/dev/null || true

  P_VER="$(set +o pipefail; sudo pihole -v 2>/dev/null | head -n 1 | tr -d '\r\n')"
  NC_VER="$(snap list nextcloud 2>/dev/null | awk 'NR==2 {print $2}')"
  OC_VER="$(openclaw --version 2>/dev/null | tr -d '\r\n')"
  NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat <<MANIFEST > manifest.json
{
  "timestamp": "$TIMESTAMP",
  "host": "$TARGET_HOST",
  "pihole_version": "$P_VER",
  "nextcloud_version": "$NC_VER",
  "openclaw_version": "$OC_VER",
  "created_at": "$NOW"
}
MANIFEST

  # Retenção remota: manter apenas os N mais recentes
  cd /mnt/toshiba/backups
  COUNT=0
  for d in $(ls -td 20* 2>/dev/null); do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -gt "$REMOTE_RETENTION" ]; then
      echo "  - Removendo backup antigo expirado: $d"
      sudo rm -rf "$d"
    fi
  done
REMOTE_MANIFEST

# 7. Sincronizar para o Mac se solicitado
if [[ "$SKIP_PULL" == false ]]; then
  echo "🚀 [7/7] Sincronizando backup para o Mac via rsync..."
  mkdir -p "$LOCAL_DEST"
  rsync -avz --progress "$TARGET_HOST:/mnt/toshiba/backups/$TIMESTAMP/" "$LOCAL_DEST/"
  
  echo ""
  echo "Verificando integridade local (SHA256):"
  if command -v shasum >/dev/null 2>&1; then
    (cd "$LOCAL_DEST" && shasum -c SHA256SUMS 2>/dev/null || true)
  fi
fi

echo ""
echo "======================================================"
echo " 🎉 Backup concluído com sucesso!"
echo "======================================================"
if [[ "$SKIP_PULL" == false ]]; then
  echo "Arquivos salvos em: $LOCAL_DEST"
  ls -lh "$LOCAL_DEST"
fi
