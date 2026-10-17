# 🔄 Guia de Recuperação de Desastres e Reconstrução do Servidor (`raspd`)

Este documento serve como plano de reconstrução passo a passo do Raspberry Pi (`raspd`) a partir do zero (após troca de SD card/NVMe, formatação ou falha catastrófica de hardware).

---

## 📋 Pré-requisitos para Reconstrução

1. Raspberry Pi 5 com Debian 13 (trixie) instalado e usuário `raspd` criado.
2. Acesso à rede local e Tailscale instalado (`curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up`).
3. HD Externo de 3.6TB conectado e montado em `/mnt/toshiba` via `/etc/fstab`.
4. Arquivo de backup mais recente gerado pelo `scripts/backup-remote.sh` ou snapshots em `/mnt/toshiba/backups/`.

---

## 🛠️ Passo a Passo de Reconstrução

### 1. Estabilização e Tuning de Sistema (Swap NVMe, Watchdog e Headless)

Antes de restaurar serviços pesados, configure a proteção de memória e contenção de hardware no Raspberry Pi 5 (2 GB RAM) para evitar congelamentos e resets de watchdog:

```bash
# Executar no Pi:
./scripts/setup-system-tuning.sh raspd
```

O script aplica automaticamente:
- **Swapfile de 4 GB no NVMe** (prioridade 10) como buffer de transbordamento para o `zram` (prioridade 100).
- **Relaxamento do Watchdog do Systemd para 5 minutos** (`RuntimeWatchdogSec=5m`).
- **Modo Headless puro** (`multi-user.target`, desativando LightDM e economizando ~200 MB de RAM).
- **Journald com armazenamento persistente** em `/var/log/journal`.
- **IP Forwarding para Tailscale Exit Node**: `/etc/sysctl.d/99-tailscale.conf` com `net.ipv4.ip_forward = 1` e `net.ipv6.conf.all.forwarding = 1` (`sudo tailscale up --advertise-exit-node`).

---

### 2. Configurar Ponto de Montagem do HD Externo (`/mnt/toshiba`)

No Raspberry Pi:

```bash
sudo mkdir -p /mnt/toshiba
sudo blkid /dev/sda1 # Obter UUID do disco Toshiba
# Adicionar no /etc/fstab para montagem automática:
# UUID=74deb556-47ad-4117-96ae-4ad08ef2a0d6 /mnt/toshiba ext4 defaults,noatime 0 2
sudo mount -a
```

---

### 3. Restaurar o Pi-hole v6 (Portas 53, 80 e 443)

1. Instalar o Pi-hole nativo:
   ```bash
   curl -sSL https://install.pi-hole.net | bash
   ```
2. Parar o serviço e restaurar a configuração:
   ```bash
   sudo systemctl stop pihole-FTL
   sudo tar -xzf /mnt/toshiba/backups/<TIMESTAMP>/pihole-backup-*.tar.gz -C /etc
   sudo chown -R pihole:pihole /etc/pihole
   sudo systemctl start pihole-FTL
   pihole status
   ```

---

### 4. Restaurar o Nextcloud Snap (Portas 8080 e 8443)

1. Instalar o pacote snap:
   ```bash
   sudo apt install -y snapd
   sudo snap install core20
   sudo snap install nextcloud
   ```
2. Ajustar as portas para conviver com o Pi-hole (Nextcloud na porta 8080/8443):
   ```bash
   sudo snap set nextcloud ports.http=8080
   sudo snap set nextcloud ports.https=8443
   ```
3. Conectar o Nextcloud ao armazenamento externo:
   ```bash
   sudo snap connect nextcloud:removable-media
   ```
4. Conectar o bind mount do Acervo do Toshiba:
   ```bash
   # /etc/fstab:
   # /mnt/toshiba/cloud /mnt/toshiba/nextcloud-data/raspd/files none bind 0 0
   sudo mount -a
   ```
5. **Segurança de Usuários**: O cadastro público de novos usuários é mantido **desativado** por padrão (somente administradores podem criar contas).
6. Restaurar o backup de banco e apps:
   ```bash
   mkdir -p /tmp/nc-restore
   tar -xzf /mnt/toshiba/backups/<TIMESTAMP>/nextcloud-backup-*.tar.gz -C /tmp/nc-restore
   sudo /snap/bin/nextcloud.import /tmp/nc-restore
   rm -rf /tmp/nc-restore
   ```

---

### 5. Restaurar Todas as Aplicações Docker

O código-fonte completo e os `docker-compose.yml` de todas as aplicações estão versionados neste repositório em [`apps/`](../apps/):

#### A. Filminhos Kanban (Porta 3005)
```bash
mkdir -p /home/raspd/dev/filminhos-kanban/data
cp -r /home/raspd/dev/raspd/apps/filminhos-kanban/* /home/raspd/dev/filminhos-kanban/
cp /mnt/toshiba/backups/services/filminhos-kanban/board.json /home/raspd/dev/filminhos-kanban/data/board.json
cd /home/raspd/dev/filminhos-kanban && docker compose up -d --build
curl -i http://localhost:3005/health
```

#### B. Checklist Viagem (Porta 3006)
```bash
mkdir -p /home/raspd/dev/checklist-viagem/data
cp -r /home/raspd/dev/raspd/apps/checklist-viagem/* /home/raspd/dev/checklist-viagem/
cp /mnt/toshiba/backups/services/checklist-viagem/trips.json /home/raspd/dev/checklist-viagem/data/trips.json
cd /home/raspd/dev/checklist-viagem && docker compose up -d --build
curl -i http://localhost:3006/health
```

#### C. Gmail Cleaner (Porta 3007)
```bash
mkdir -p /home/raspd/dev/gmail-cleaner/data
cp -r /home/raspd/dev/raspd/apps/gmail-cleaner/* /home/raspd/dev/gmail-cleaner/
cd /home/raspd/dev/gmail-cleaner && docker compose up -d --build
curl -i http://localhost:3007/health
```

#### D. Racha Contas (Splitwise Soberano — Porta 3008)
```bash
mkdir -p /home/raspd/dev/racha-contas/data
cp -r /home/raspd/dev/raspd/apps/racha-contas/* /home/raspd/dev/racha-contas/
cp /mnt/toshiba/backups/services/racha-contas/racha.json /home/raspd/dev/racha-contas/data/racha.json
cd /home/raspd/dev/racha-contas && docker compose up -d --build
curl -i http://localhost:3008/health
```

#### E. Vaultwarden (Cofre de Senhas e Cartões — Porta 3009)
```bash
mkdir -p /home/raspd/dev/vaultwarden/data
cp -r /home/raspd/dev/raspd/apps/vaultwarden/* /home/raspd/dev/vaultwarden/
# Restaurar o snapshot tar.gz do cofre
tar -xzf /mnt/toshiba/backups/services/vaultwarden/vaultwarden-latest.tar.gz -C /home/raspd/dev/vaultwarden/data/
# Subir com SIGNUPS_ALLOWED=false
cd /home/raspd/dev/vaultwarden && docker compose up -d
# Reativar HTTPS com Tailscale Serve na porta 8443
sudo tailscale serve --bg --https=8443 3009
curl -sL https://raspd.tail4c5fc9.ts.net:8443/ | grep -o "<title[^<]*"
```

#### F. Mon Carnet Français (Porta 3010)
```bash
mkdir -p /home/raspd/dev/caderno-frances/data
cp -r /home/raspd/dev/raspd/apps/caderno-frances/* /home/raspd/dev/caderno-frances/
cp /mnt/toshiba/backups/services/caderno-frances/cards.json /home/raspd/dev/caderno-frances/data/cards.json
cd /home/raspd/dev/caderno-frances && docker compose up -d --build
curl -i http://localhost:3010/health
```

#### G. MiniDLNA (Streaming TV — Porta 8200)
```bash
mkdir -p /home/raspd/dev/minidlna
cp -r /home/raspd/dev/raspd/apps/minidlna/* /home/raspd/dev/minidlna/
cd /home/raspd/dev/minidlna && docker compose up -d --build
curl -s http://localhost:8200/
```

---

### 6. Restaurar Automações de Cron e Rotinas Diárias

Restabelecer os agendamentos no `crontab -e` do usuário `raspd`:

```cron
# Backup diário de serviços para o Toshiba às 03:30
30 3 * * * /home/raspd/dev/raspd/scripts/backup-services-local.sh >> /home/raspd/dev/raspd/scripts/backup-services.log 2>&1

# Sincronização diária do Nextcloud com o Acervo às 04:00
0 4 * * * /home/raspd/dev/raspd/scripts/nextcloud-daily-scan.sh
```

---

### 7. Restaurar o OpenClaw e Automações do Gateway

1. Executar o provisionamento do OpenClaw:
   ```bash
   ./scripts/setup-openclaw.sh raspd
   ```
2. Restaurar workspace, configs e histórico:
   ```bash
   sudo tar -xzf /mnt/toshiba/backups/<TIMESTAMP>/openclaw-backup-*.tar.gz -C /
   systemctl --user restart openclaw-gateway
   ```
3. Automações Ativas do Gateway:
   - `lembrete-remedio-21h`: Diariamente às 21:00.
   - `lembrete-enel-dia-25`: Todo dia 25 às 12:00 no grupo WhatsApp *filminhos-e-coisinhas*.
