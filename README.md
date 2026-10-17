# 🏡 Servidor Doméstico Soberano — Guia Definitivo do Zero ao "Quit the Cloud"

> Um guia prático, testado em batalha e de baixo custo para montar um servidor doméstico com **Raspberry Pi 5 + NVMe**, bloquear anúncios na casa inteira (**Pi-hole**), ter sua própria nuvem de arquivos e fotos sem pagar mensalidades (**Nextcloud**), e operar um **assistente pessoal autônomo com IA no WhatsApp** (**OpenClaw**).

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
│   │ 🛡️ REDE & SEGURANÇA                                                                  │   │
│   │ • Pi-hole v6 (DNS Server + Bloqueio de Anúncios e Telemetria em toda a casa)         │   │
│   │ • Tailscale (VPN Mesh Privada: acesso remoto seguro de qualquer lugar sem abrir porta) │   │
│   └──────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ ☁️ ARMAZENAMENTO & QUIT THE CLOUD (HDD Externo USB 3.0)                               │   │
│   │ • Nextcloud (Nuvem Soberana: Fotos, Documentos, Acervo pessoal e WebDAV)             │   │
│   │ • Samba Server (Compartilhamento nativo com macOS Finder e Windows Explorer)         │   │
│   │ • Rotina de Desduplicação e Unificação Fotográfica Canônica (Ano/Mês)                │   │
│   └──────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ 🤖 IA PESSOAL & APLICAÇÕES DOCKER                                                    │   │
│   │ • OpenClaw (Assistente pessoal autônomo conectado diretamente ao WhatsApp)           │   │
│   │ • Vaultwarden (Cofre de senhas e cartões criptografado com suporte ao Bitwarden)     │   │
│   │ • Rachadinha (Divisor de contas e despesas compartilhadas estilo Splitwise)          │   │
│   │ • MiniDLNA (Servidor de mídia para streaming na Smart TV / Projetor)                 │   │
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

---

## 💾 2. Instalação do Sistema Operacional (Headless)

Você não precisa de monitor, teclado ou mouse conectados ao Raspberry Pi para configurá-lo:

1. Baixe o [Raspberry Pi Imager](https://www.raspberrypi.com/software/);
2. Conecte o SSD NVMe (ou cartão de setup inicial) no seu computador;
3. Escolha o SO: **Raspberry Pi OS (64-bit) Lite** (sem interface gráfica pesada);
4. Clique na engrenagem ⚙️ (Configurações Avançadas) e preencha:
   * **Hostname:** `raspd`
   * **Usuário e Senha:** escolha suas credenciais;
   * **Ativar SSH:** Autenticação por chave pública (ou senha);
   * **Configurar Wi-Fi:** (se não for usar cabo de rede Gigabit).
5. Grave o disco, insira no Raspberry Pi e ligue na tomada.

---

## ⚡ 3. Primeiro Boot & Hardening do Sistema

Acesse o servidor pelo terminal do seu computador:

```bash
ssh raspd@raspd.local
# (ou pelo IP atribuído pelo roteador, ex: ssh raspd@192.168.15.17)
```

### A. Atualização e Ferramentas Básicas:
```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl wget git htop tmux ufw rsync
```

### B. Proteção de Memória (Swapfile no NVMe):
Para evitar travamentos de falta de memória (OOM) sob carga pesada do Nextcloud ou Docker:
```bash
# Desativar swap padrão pequeno
sudo dphys-swapfile swapoff || true
sudo systemctl disable dphys-swapfile || true

# Criar swapfile de 4GB rápido no NVMe
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Persistir no /etc/fstab
echo '/swapfile none swap sw,pri=10 0 0' | sudo tee -a /etc/fstab
```

### C. Acesso Remoto Soberano com Tailscale (Sem abrir portas no roteador):
O Tailscale cria uma rede VPN Mesh criptografada (WireGuard). Você acessa o seu servidor doméstico do trabalho, do 4G na rua ou em viagens sem precisar abrir portas nem configurar IP dinâmico:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-exit-node
```

---

## 🛡️ 4. Bloqueador de Anúncios na Casa Inteira (Pi-hole v6)

O Pi-hole atua como o servidor DNS da sua casa, bloqueando propagandas, rastreadores e anúncios em todos os aparelhos (Smart TVs, celulares, notebooks) antes mesmo de serem carregados:

```bash
curl -sSL https://install.pi-hole.net | bash
```
* Configure o IP estático do Raspberry Pi;
* No seu roteador de internet (Vivo, Claro, etc.), mude o **DNS Primário** para o IP do seu Raspberry Pi (`192.168.15.17`). A partir desse instante, a rede inteira navega limpa.
* Acesse o painel de controle pelo navegador: `http://raspd.local/admin`.

---

## ☁️ 5. Fazendo o "Quit das Clouds" (Nuvem Própria com Nextcloud)

Para substituir Google Drive, Dropbox e Google Fotos:

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

### Padrão de Organização Fotográfica Canônica:
Para nunca mais perder fotos e se livrar de duplicatas espalhadas:
* Estruture as fotos obrigatoriamente por **Ano e Mês** com base na data EXIF real da foto:  
  `Fotos/Anuais/AAAA/MM/` (ex: `Fotos/Anuais/2026/04/`).
* Use **links simbólicos (symlinks)** para criar álbuns virtuais sem duplicar o espaço no disco (ex: `Fotos/Por_Colecao/Viagem_Paris`).

---

## 🤖 6. Seu Próprio Assistente de IA Pessoal no WhatsApp (OpenClaw)

O **OpenClaw** é o motor que transforma o seu servidor num assistente pessoal autônomo conectado diretamente ao seu WhatsApp:

1. **Instale o Node.js 24 LTS e o OpenClaw:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
   sudo apt install -y nodejs
   sudo npm install -g openclaw@latest
   ```

2. **Inicie o setup guiado:**
   ```bash
   openclaw onboard
   ```
   * Escolha o provedor de IA (Google Gemini 3.8 Flash, Anthropic Claude ou OpenAI);
   * Conecte o canal do WhatsApp escaneando o QR code pelo app no celular;
   * O assistente ganha vida e passa a responder comandos de voz, textos, gerenciar arquivos no servidor e enviar lembretes!

---

## 🐳 7. Suíte de Micro-Serviços Úteis (Docker Compose)

Todas as nossas aplicações do dia a dia rodam isoladas em contêineres leves:

* **⚖️ Rachadinha (`porta 3008`):** Divisor de contas estilo Splitwise para casais e repúblicas, com suporte a multi-moedas e comando por voz no WhatsApp.
* **🔐 Vaultwarden (`porta 3009`):** Servidor Bitwarden em Rust consumindo meros 25MB de RAM com criptografia ponta a ponta e app no celular.
* **🥐 Mon Carnet Français (`porta 3010`):** Caderno de imersão linguística para vocabulário de telas e expressões diárias.
* **🏃‍♂️ Ritmo & Sono (`porta 3012`):** Visualizador descomplicado de treinos físicos e qualidade do sono.

---

## 🔄 8. Estratégia de Redundância e Backup 3-2-1

Servidor soberano não pode ter ponto único de falha:
1. **Snapshots Locais Diários:** Todo dia às 03:30, um script compacta bancos de dados e segredos para o HD externo;
2. **Cold Storage em HDs Externos Portáteis:** Espelhamento periódico via `rsync` para 2 ou 3 HDs externos formatados em APFS ou ext4;
3. **Plano de Desastre:** Com o guia `docs/disaster-recovery.md`, uma máquina inteira do zero é restabelecida em menos de 30 minutos.

---

## 📄 Licença & Filosofia

Este projeto é software livre sob a licença **MIT**. Acreditamos na descentralização da internet, no direito ao anonimato, na presença física no mundo real e na tecnologia como ferramenta de emancipação humana, não de vigilância.
