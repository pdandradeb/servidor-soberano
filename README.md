# 🏡 Servidor Doméstico Soberano — Guia Definitivo do Zero ao "Quit the Cloud"

> Um guia prático, testado em batalha e de baixo custo para montar um servidor doméstico com **Raspberry Pi 5 + NVMe**, subir o seu **assistente de IA pessoal no WhatsApp** logo no início para ser seu copiloto, bloquear anúncios na casa inteira (**Pi-hole**) e ter sua própria nuvem de arquivos e fotos sem pagar mensalidades (**Nextcloud**).

---

## 🧭 Visão Geral da Arquitetura

```
                              ┌────────────────────────────────────────────────┐
                              │            Sua Casa / Dispositivos             │
                              │   MacBook, Celulares (iOS/Android), Smart TV   │
                              └──────────────────────┬─────────────────────────┘
                                                     │
                                                     ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│                                SERVIDOR DOMÉSTICO (raspd)                                    │
│                              Raspberry Pi 5 + SSD NVMe M.2                                   │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ 🤖 1. SEU COPILOTO DE IA (OpenClaw no WhatsApp)                                      │   │
│   │ • Assistente autônomo rodando localmente, pronto para ajudar no resto da montagem    │   │
│   │ • Responde por áudio e texto, executa scripts, lembra de tarefas e monitora o Pi     │   │
│   └──────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ 🛡️ 2. REDE, SEGURANÇA & ACESSO REMOTO                                                │   │
│   │ • Pi-hole v6 (DNS Server + Bloqueio de Anúncios e Telemetria em toda a casa)         │   │
│   │ • Tailscale (VPN Mesh Privada: acesso remoto de qualquer lugar sem abrir portas)     │   │
│   └──────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ ☁️ 3. ARMAZENAMENTO & QUIT THE CLOUD (HDD Externo USB 3.0)                               │   │
│   │ • Nextcloud (Nuvem Soberana: Fotos, Documentos, Acervo pessoal e WebDAV)             │   │
│   │ • Unificação Fotográfica Canônica por Ano/Mês (sem duplicatas)                       │   │
│   │ • Samba Server (Acesso nativo pelo Finder do Mac e Explorer do Windows)              │   │
│   └──────────────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛒 1. Lista de Materiais & Hardware Recomendado

Para montar um servidor silencioso, de baixíssimo consumo elétrico (~5W a 12W) e com durabilidade de anos, **evite cartões microSD para o sistema operacional**. O uso de SSD NVMe é o segredo da estabilidade:

| Componente | Especificação Recomendada | Por que é importante? |
|---|---|---|
| **Placa-Mãe** | **Raspberry Pi 5 (4GB ou 8GB)** | Desempenho 3x superior ao Pi 4 e barramento PCIe nativo para NVMe. |
| **Alimentação** | **Fonte Oficial Raspberry Pi 27W USB-C PD** | **Crítica:** o Pi 5 precisa de 5A para alimentar as portas USB e o NVMe sem sofrer *undervoltage*. |
| **Cooler** | **Active Cooler Oficial Raspberry Pi** | Dissipador de alumínio com ventoinha PWM inteligente (silencioso e mantém em ~50°C). |
| **Armazenamento SO** | **SSD M.2 NVMe (256GB a 1TB)** | Vida útil industrial (cartões SD queimam com escrita de banco de dados). |
| **Adaptador PCIe** | **Geekworm X1001** ou **Pimoroni NVMe Base** | Placa adaptadora que conecta o SSD M.2 diretamente ao barramento PCIe do Pi 5. |
| **Gabinete** | **Argon NEO 5 M.2 NVMe** ou **Argon ONE V3** | Gabinete de alumínio com dissipação passiva integrada e slot para o SSD. |
| **Armazenamento Massa** | **HD Externo 2.5" USB 3.0 (2TB a 4TB)** | Para acervo de fotos, vídeos, filmes e documentos (ex: Toshiba Canvio / Seagate). |
| **Proteção Elétrica** | **Filtro de Linha DPS (iClamper Energia 5)** | Protege a fonte e o filesystem contra picos de tensão e oscilações da rede. |
| **Cartão MicroSD** | **SanDisk Extreme 64GB/128GB** | Para gravação inicial do SO pelo Imager e recuperação do sistema. |

> 🔗 **Onde Comprar Cada Componente:** Veja links diretos testados (The Pi Hut, MakerHero, AliExpress, Amazon, Mercado Livre) no [**Guia Completo de Hardware Soberano (docs/hardware-soberano.md)**](docs/hardware-soberano.md).

---

## 💾 2. Instalação Headless do Sistema Operacional (Windows, Mac ou Linux)

Você não precisa de monitor, teclado ou mouse conectados ao Raspberry Pi para configurá-lo. Todo o processo pode ser feito diretamente do seu computador de uso diário.

> 🪟 **Usa Windows 10 ou 11?** Veja o nosso [**Guia Completo para Windows e WSL2**](docs/setup-windows-e-wsl.md) com comandos prontos para PowerShell, atalhos do Windows Terminal e dicas de rede.

### 2.1 Gravando o disco pelo Windows ou Mac
1. Baixe o **Raspberry Pi Imager** ([site oficial](https://www.raspberrypi.com/software/) ou no Windows via terminal: `winget install RaspberryPi.RaspberryPiImager`);
2. Conecte o SSD NVMe (via case USB-C) ou o cartão de memória no seu PC;
3. No Imager, selecione:
   * **Dispositivo:** Raspberry Pi 5 (ou Pi 4);
   * **Sistema Operacional:** **Raspberry Pi OS (64-bit) Lite** (sem interface gráfica para máxima estabilidade e performance);
   * **Armazenamento:** Escolha o disco conectado.
4. Clique em **Próximo** e selecione **Editar Configurações** (ou pressione `Ctrl + Shift + X`):
   * **Hostname:** `raspd` (ou o nome que preferir para a sua máquina);
   * **Usuário e Senha:** crie seu usuário (ex: `raspd`) e senha mestra;
   * **Ativar SSH:** Marque para permitir login por senha (ou adicione sua chave SSH pública);
   * **Configurar Wi-Fi:** preencha nome da rede e senha (se não for usar cabo de rede conectado ao roteador).
5. Clique em **Gravar**, insira o disco gravado no Raspberry Pi e ligue na tomada.

### 2.2 Conectando via SSH
Aguarde cerca de 60 segundos após ligar o Pi para o boot completar. Abra o terminal do seu computador (**PowerShell** ou **Windows Terminal** no Windows, ou **Terminal** no Mac/Linux):

```bash
ssh raspd@raspd.local
```
*(Digite a senha cadastrada no Imager e pronto: você já está dentro do seu servidor).*

> 💡 **Não tem Raspberry Pi físico agora?** Você pode rodar todo este ecossistema soberano em um ambiente de testes diretamente no seu Windows através do **WSL2 (Windows Subsystem for Linux)**. Consulte a [Seção 4 do Guia Windows e WSL2](docs/setup-windows-e-wsl.md#parte-4-alternativa--rodando-no-wsl2-sem-raspberry-pi-físico).

---

## 🚀 3. O Script Mestre: Bootstrap All-in-One (Instale Tudo de Uma Vez)

Em vez de perder horas instalando dependência por dependência, disponibilizamos um instalador mestre completo neste repositório. Ele funciona como um *Brew bundle* / instalador completo que provisiona a máquina inteira com um único comando:

```bash
curl -fsSL https://raw.githubusercontent.com/pdandradeb/servidor-soberano/main/scripts/bootstrap.sh | bash
```

### 📦 O que o script instala e configura automaticamente:
* **Ferramentas CLI essenciais:** `git`, `curl`, `wget`, `htop`, `tmux`, `ufw`, `rsync`, `jq`, `poppler-utils`, `build-essential`;
* **Swapfile de 16 GB no NVMe:** Buffer de proteção contra travamentos de falta de memória (OOM) mesmo sob cargas pesadas de Docker e indexação;
* **Tailscale (VPN Mesh):** Acesso remoto seguro de qualquer lugar sem abrir portas no roteador;
* **Docker & Docker Compose:** Motor de contêineres oficial;
* **Node.js 24 LTS & npm:** Runtime moderno para serviços e assistente;
* **OpenClaw:** O motor do seu agente de IA pessoal.

---

## 🤖 4. O Segredo: "OpenClaw First" (Seu Copiloto no WhatsApp nos Primeiros 5 Minutos)

**A grande sacada estratégica deste setup:** em vez de deixar a inteligência artificial por último, **nós subimos o assistente nos primeiros 5 minutos!**

Ao escanear o QR Code no WhatsApp logo no início, **o assistente passa a ser o seu copiloto técnico pessoal** para todo o restante da jornada. A partir daí, você não precisa ficar decorando comandos de terminal: você pode mandar áudio no WhatsApp perguntando *"como monto o HD externo?"*, pedir para ele verificar a temperatura do Pi, formatar discos ou automatizar serviços para você!

```bash
openclaw onboard
```

1. Escolha o modelo de IA que preferir (Google Gemini 3.8 Flash, Anthropic Claude ou OpenAI);
2. Conecte o canal do **WhatsApp** escaneando o QR code diretamente com a câmera do seu celular;
3. Pronto! O assistente já está ativo no seu WhatsApp. Você pode mandar áudios, tirar dúvidas de terminal, pedir para ele verificar a temperatura do Raspberry Pi ou ajudar a montar os próximos passos!

---

## 🛡️ 5. Bloqueador de Anúncios na Casa Inteira (Pi-hole v6)

O Pi-hole atua como o servidor DNS da sua casa, bloqueando anúncios, telemetrias e rastreadores em todos os aparelhos (Smart TVs, celulares, notebooks) antes mesmo de serem carregados:

```bash
curl -sSL https://install.pi-hole.net | bash
```
* Configure o IP estático do Raspberry Pi;
* No seu roteador de internet (Vivo, Claro, etc.), mude o **DNS Primário** para o IP do seu Raspberry Pi (`192.168.15.17`). A partir desse instante, a rede inteira navega limpa.
* Acesse o painel pelo navegador: `http://raspd.local/admin`.

---

## ☁️ 6. Fazendo o "Quit das Clouds" (Nuvem Própria com Nextcloud)

Para substituir Google Drive, Dropbox e Google Fotos definitivamente:

```bash
# 1. Instalar Nextcloud via Snap
sudo apt install -y snapd
sudo snap install nextcloud

# 2. Ajustar portas para conviver em harmonia com o Pi-hole
sudo snap set nextcloud ports.http=8080
sudo snap set nextcloud ports.https=8443
sudo snap connect nextcloud:removable-media

# 3. Montar seu HD externo de 4TB no /etc/fstab
sudo mkdir -p /mnt/toshiba
# Adicione a linha correspondente ao UUID no /etc/fstab e monte:
sudo mount -a
```

### 💾 6.1 Conectando HDs Externos para Backup & Acervo de Massa
Se você for conectar HDs externos USB (2TB, 4TB ou mais) para ser o grande cofre da casa:

1. **Alimentação Elétrica Crítica:**
   * No **Raspberry Pi 5**, use obrigatoriamente a **fonte oficial de 27W USB-PD** (ela entrega 5A para aguentar o pico de partida dos discos mecânicos sem sofrer *undervoltage*).
   * No **Raspberry Pi 4** ou ao ligar mais de 1 disco USB, use um **Hub USB 3.0 energizado com tomada própria**.
2. **Montagem Persistente com Proteção (`/etc/fstab`):**
   * Descubra o UUID da partição com `sudo blkid`.
   * Configure no `/etc/fstab` usando a flag `nofail` (ex: `UUID=... /mnt/dados ext4 defaults,nofail 0 2`). Com o `nofail`, mesmo se alguém chutar o cabo do HD na tomada, o Raspberry Pi liga normalmente sem travar o boot.
3. **Compartilhamento no Windows Explorer (Samba):**
   * Com o serviço Samba ativo, o HD externo aparece nativamente na rede do Windows: basta digitar `\\raspd.local\dados` no Explorer ou mapear como unidade `Z:` para arrastar arquivos direto do seu PC!
   *(Veja o passo a passo completo no [Guia de HDs e Armazenamento](docs/setup-windows-e-wsl.md#parte-3-conectando-hds-externos-para-backup--acervo)).*

### 📸 Padrão de Organização Fotográfica Canônica:
Para nunca mais perder fotos e se livrar de duplicatas espalhadas:
* Estruture as fotos obrigatoriamente por **Ano e Mês** com base na data EXIF real da foto:  
  `Fotos/Anuais/AAAA/MM/` (ex: `Fotos/Anuais/2026/04/`).
* Use **links simbólicos (symlinks)** para criar álbuns virtuais sem duplicar o espaço no disco (ex: `Fotos/Por_Colecao/Viagem_Paris`).

---

## 🔄 7. Estratégia de Redundância e Backup 3-2-1

Servidor soberano não pode ter ponto único de falha:
1. **Snapshots Locais Diários:** O script `scripts/backup-services-local.sh` roda diariamente às 03:30 compactando bancos de dados e configurações para o HD externo;
2. **Cold Storage em HDs Externos Portáteis:** Espelhamento periódico via `rsync` para 2 ou 3 HDs externos formatados em APFS ou ext4;
3. **Plano de Desastre:** Com o guia [`docs/disaster-recovery.md`](docs/disaster-recovery.md), uma máquina inteira do zero é restabelecida em menos de 30 minutos.

---

## 📁 Scripts Inclusos neste Repositório

Todos os scripts operacionais estão na pasta [`scripts/`](scripts/):
* [`bootstrap.sh`](scripts/bootstrap.sh) — Instalador master all-in-one de todos os softwares;
* [`setup-system-tuning.sh`](scripts/setup-system-tuning.sh) — Ajuste de swap no NVMe e modo headless;
* [`setup-openclaw.sh`](scripts/setup-openclaw.sh) — Provisionamento automatizado do assistente;
* [`backup-remote.sh`](scripts/backup-remote.sh) — Backup completo do Pi para máquina remota;
* [`backup-services-local.sh`](scripts/backup-services-local.sh) — Snapshot diário local dos serviços para o HDD externo;
* [`nextcloud-daily-scan.sh`](scripts/nextcloud-daily-scan.sh) — Varredura e indexação periódica de arquivos.

---

## 📄 Licença & Filosofia

Este projeto é software livre sob a licença **MIT**. Acreditamos na descentralização da internet, no direito ao anonimato, na presença física no mundo real e na tecnologia como ferramenta de emancipação humana, não de vigilância.
