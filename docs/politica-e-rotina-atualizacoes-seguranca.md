# Política e Rotina de Atualizações de Segurança - raspd

Documento de referência para a manutenção contínua de segurança, patches de sistema operacional, runtime de containers e atualização do OpenClaw no servidor doméstico soberano (`raspd`).

---

## 1. Escopo de Atualizações & Componentes Críticos

O servidor `raspd` opera em camadas de segurança independentes:

1. **Sistema Operacional Base (Debian Trixie arm64 / Raspberry Pi OS):**
   - Pacotes de segurança prioritários: `openssh-server`, `tailscale`, `curl`, `openssl`, `libssl3t64`, `sudo`, `bind9-libs`, `bubblewrap`, `cifs-utils`, `ca-certificates`, `libsqlite3-0`, `libpq5`, `nodejs`.
   - Política: Aplicação de atualizações apenas para canais de segurança (`*-security` e `--only-upgrade`), evitando quebras de bibliotecas core fora de janelas planejadas.

2. **Container Engine & Runtimes (Docker / containerd):**
   - Pacotes: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`.
   - Política: Manter versões estáveis com patches de isolamento e cgroups.

3. **Aplicações em Containers (Docker):**
   - Imagens oficiais de terceiros: `vaultwarden/server:latest` (cofre de senhas), `sigoden/dufs:latest`.
   - Imagem base de micro-apps próprios: `node:22-alpine` (linha Active LTS).
   - Política: Pull periódico de imagens oficiais com reinício gracioso; rebuild de micro-apps locais quando a base LTS for atualizada.

4. **Nextcloud (Snap):**
   - Canal: `latest/stable` (Snap autocontido).
   - Política: Mantém atualizações automáticas gerenciadas pelo snapd (incluindo o runtime PHP embutido).
   - Comando de rollback em emergências: `sudo snap revert nextcloud`.

5. **OpenClaw Gateway:**
   - Política: Atualizações coordenadas via mecanismo nativo (`gateway update.run` ou comando `/update` no chat do owner).
   - Proibição estrita: Nunca rodar `npm install -g openclaw` manual no terminal para evitar interrupções súbitas de conexão.

---

## 2. Rotina Contínua Automatizada (Audit & Patches)

Para garantir que o ambiente permaneça blindado sem depender de incidentes pontuais:

* **Script Oficial:** `/home/raspd/dev/raspd/scripts/system-security-updates.sh`
* **Log de Execução:** `/home/raspd/dev/raspd/logs/security-updates.log`
* **Frequência:** **Semanal** (todo domingo às 04:30 da manhã via crontab).
* **Entrada no Crontab:**
  ```cron
  30 4 * * 0 /home/raspd/dev/raspd/scripts/system-security-updates.sh >> /home/raspd/dev/raspd/logs/security-updates.log 2>&1
  ```
* **Passos da Rotina:**
  1. `sudo apt-get update -q` (atualização dos índices).
  2. `sudo apt-get --only-upgrade install -y <pacotes_criticos>` + varredura e upgrade dos pacotes pendentes do canal `*-security`.
  3. `docker pull` das imagens oficiais de terceiros (`vaultwarden/server:latest`, `sigoden/dufs:latest`) e recriação suave dos containers (`docker compose up -d`).
  4. Limpeza de imagens Docker órfãs/dangling (`docker image prune -f`).
  5. Auditoria pós-execução de integridade dos containers Docker, rede Tailscale e Nextcloud Snap.

---

## 3. Histórico de Execuções

* **2026-11-22:**
  - Patches de segurança aplicados no SO: 70 pacotes atualizados, incluindo `openssl` (3.5.9), `libssl3t64`, `curl` (8.14.1), `sudo` (1.9.16), `tailscale` (1.104.7), `docker-ce` (29.10.0), `containerd.io` (2.4.2), `docker-compose-plugin` (5.8.0), `docker-buildx-plugin` (0.39.1), `nodejs` (24.22.3), `apt` (3.0.4), `liblzma5`, `zlib1g`, `libexpat1`, `libnss3`.
  - Imagem Docker `vaultwarden/server:latest` atualizada e container reiniciado com sucesso.
  - Imagens órfãs limpas (423.5 MB liberados).
  - Auditoria: 21 containers ativos e saudáveis (0 falhas de healthcheck), Tailscale operacional, Nextcloud Snap 100% ativo.
  - Rotina automatizada agendada para periodicidade semanal aos domingos às 04:30.

* **2026-10-22:**
  - Patches de segurança aplicados: `containerd.io` (2.4.2), `docker-ce` (29.9.2), `bind9-libs` (9.20.30), `bubblewrap` (0.12.0), `bash` (5.2.37-2+b10).
  - Imagens Docker atualizadas: `vaultwarden/server:latest`, `sigoden/dufs:latest`, `node:22-alpine`.
  - Nextcloud Snap verificado: versão `34.0.5snap3` ativa com PHP corrigido.
  - OpenClaw verificado: Versão `2026.9.7` pronta para transição para `2026.10.5`.
