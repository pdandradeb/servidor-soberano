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

## 📋 0. Pré-Setup: O Checklist Para Adiantar Enquanto o Hardware Não Chega

Se você vai montar o servidor para você mesmo ou ajudar um amigo, **não precisa esperar o Raspberry Pi chegar na tomada para começar**. Mande este checklist para a pessoa adiantar pelo celular ou notebook:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                  CHECKLIST DE PRÉ-SETUP (15 MINUTOS NO SOFÁ)                 │
├──────────────────────────────────────────────────────────────────────────────┤
│  [ ] 1. Criar conta no GitHub (https://github.com)                           │
│  [ ] 2. Criar conta no Tailscale (https://tailscale.com) e baixar o app      │
│  [ ] 3. Escolher o canal do bot (WhatsApp precisa de chip; Telegram não!)    │
│  [ ] 4. Gerar a chave de IA (Google AI Studio gratuito ou sua conta paga)    │
│  [ ] 5. Separar uma tomada e um cabo de rede perto do roteador de internet   │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 1. Criar conta no GitHub ([github.com](https://github.com))
* Gratuita e imediata.
* Servirá para clonar este repositório, salvar backups automáticos das configurações, versionar o cofre de notas e sincronizar scripts.

### 2. Criar conta no Tailscale ([tailscale.com](https://tailscale.com))
* O Tailscale é a VPN mesh segura que permite acessar o servidor de qualquer lugar do mundo (no 4G/5G, no trabalho ou em viagens) furando bloqueios de operadoras (CGNAT) sem abrir portas no roteador da casa.
* **O que fazer:** Fazer login com a mesma conta do Google ou GitHub e instalar o aplicativo no celular e no notebook. Quando o Raspberry Pi subir, ele entrará nessa mesma rede privada com um único clique.

### 3. Escolher o Canal do Assistente: Precisa de Chip de Celular?
Uma dúvida clássica de quem está começando: *"Preciso comprar um chip novo para o meu assistente?"*

| Canal | Precisa de Chip / Número Novo? | Como Funciona o Pareamento | Custo / Prós e Contras |
|---|---|---|---|
| **WhatsApp** | **SIM** (Altamente Recomendado) | Escaneia o QR Code no terminal como se fosse um WhatsApp Web. | **Prós:** Fica no app onde você e sua família passam o dia, suporta áudios nativos e grupos.<br>**Contras:** Precisa de um número ativo para receber o SMS inicial de validação. |
| **Telegram** | **NÃO** (Custo Zero Imediato) | Fala com o `@BotFather`, cria o bot e pega o token de API em 30 segundos. | **Prós:** Não gasta um centavo com chip, configuração instantânea e suporte completo a áudio, fotos e arquivos.<br>**Contras:** Exige que você use o app do Telegram. |
| **Discord** | **NÃO** | Cria uma aplicação no Discord Developer Portal e pega o bot token. | **Prós:** Excelente para quem já usa Discord no dia a dia, com canais temáticos.<br>**Contras:** Menos prático para mandar áudios curtos do dia a dia na rua. |
| **Interface Web / Terminal** | **NÃO** | O OpenClaw já inclui interface web moderna (*Control UI*) acessível localmente ou via Tailscale. | **Prós:** Acesso direto pelo navegador sem depender de nenhuma empresa de mensageria. |

> 📱 **Dica Prática para WhatsApp:** O WhatsApp ainda exige validação por SMS na ativação de qualquer conta (mesmo com os novos testes de *usernames* da Meta). Se o seu amigo quiser o assistente no WhatsApp, oriente-o a **comprar um chip pré-pago avulso de R$ 10 a R$ 15** (Claro, Vivo ou TIM) e colocar uma recarga mínima. Ele espeta o chip num celular antigo por 5 minutos só para receber o SMS de confirmação, escaneia o QR Code do assistente e depois pode até guardar o chip na gaveta.

### 4. Gerar a Chave de IA (O Cérebro de Inferência)
O assistente precisa de uma chave de API para processar áudios, textos e ferramentas.
* **Quem quer custo zero:** Gerar uma chave gratuita no **Google AI Studio** (`aistudio.google.com`) — veja o passo a passo na Seção 4.
* **Quem já paga ChatGPT Plus ou Claude Pro:** Veja o guia na Seção 4.1 para entender como usar sua conta ou gerar créditos de API.

### 5. O Pouso Físico do Servidor
* Separar um cantinho arejado perto do roteador de internet da casa.
* Deixar separado: cabo de rede Ethernet (RJ-45) para estabilidade máxima e uma tomada livre.

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

### 2.3 Montando o Kit para um Amigo? Pré-configure o Wi-Fi da Casa Dele!
Se você estiver configurando o Raspberry Pi na sua casa para entregar pronto para outra pessoa, o Raspberry Pi OS (Bookworm / NetworkManager) permite salvar **múltiplas redes Wi-Fi** simultaneamente:

1. Enquanto o Pi estiver ligado na sua casa (conectado no seu Wi-Fi ou cabo de rede), adicione a rede da casa do seu amigo:
   ```bash
   sudo nmcli connection add type wifi con-name "WiFi-Casa-Amigo" ifname wlan0 ssid "NOME_DA_REDE"
   sudo nmcli connection modify "WiFi-Casa-Amigo" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "SENHA_DO_WIFI"
   sudo nmcli connection modify "WiFi-Casa-Amigo" connection.autoconnect yes
   ```
2. **Magia do Plug-and-Play:** Quando o amigo levar o aparelhinho para casa e ligar na tomada, o Pi não vai achar o seu Wi-Fi, vai escanear o ambiente, conectar automaticamente no Wi-Fi dele e ficar 100% online — sem ele precisar de monitor, teclado ou cabo de rede!
3. **Acesso Remoto Imediato:** Como o **Tailscale** já foi provisionado no passo a seguir, você ou seu amigo conseguem acessar o Pi de qualquer lugar pelo IP do Tailscale, mesmo sem saber qual IP o roteador da casa dele entregou.

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

## 🤖 4. O Segredo: "OpenClaw First" (Seu Copiloto nos Primeiros 5 Minutos)

**A grande sacada estratégica deste setup:** em vez de deixar a inteligência artificial por último, **nós subimos o assistente nos primeiros 5 minutos!**

Ao parear o assistente no seu aplicativo de mensagens favorito logo no início, **ele se torna o seu copiloto técnico pessoal** para o restante de toda a montagem. Você não precisa ficar decorando comandos de terminal: basta mandar um áudio ou texto perguntando *"como monto o HD externo?"*, pedir para ele verificar a temperatura do processador, formatar discos ou automatizar backups para você!

```bash
openclaw onboard
```

---

### 📲 4.1 Escolhendo o Canal de Mensagens: WhatsApp, Telegram ou Discord?

O OpenClaw é multiplataforma e suporta diversos canais de mensageria simultâneos. Veja qual faz mais sentido para você ou para o seu amigo:

#### A. WhatsApp (O Mais Prático para o Dia a Dia Familiar)
* **Precisa de chip físico ou eSIM dedicado? SIM.**
* **Por que precisa:** O WhatsApp funciona espelhando uma sessão via protocolo Baileys (como se fosse um WhatsApp Web). Toda conta de WhatsApp precisa de um número E.164 verificado inicialmente via código SMS ou ligação. Mesmo que a Meta lance nomes de usuário (*usernames*), a autenticação de base no ecossistema Meta continua atrelada a uma linha telefônica.
* **Como fazer sem gastar muito:** Compre um chip pré-pago de qualquer operadora (R$ 10 a R$ 15). Coloque o chip em qualquer celular por 5 minutos, ative a conta no WhatsApp, escaneie o QR Code que o OpenClaw exibe no terminal e pronto! O chip nem precisa ficar no aparelho depois disso.
* **Vantagem:** O assistente tem seu próprio número e foto de perfil, pode participar de grupos da família ou de projetos, transcreve áudios que você grava na rua e responde com notas de voz.

#### B. Telegram (A Opção Instantânea — Não Precisa de Chip!)
* **Precisa de chip ou número novo? NÃO!**
* **Como funciona:** Você usa a sua própria conta do Telegram. Abra uma conversa com o perfil oficial **`@BotFather`**, envie o comando `/newbot`, escolha um nome e um apelido (ex: `meu_servidor_bot`). O BotFather vai te devolver um **HTTP API Token**.
* **Como ativar no OpenClaw:**
  ```bash
  openclaw channels add telegram --token "SEU_TOKEN_DO_BOTFATHER"
  ```
* **Vantagem:** Custo zero absoluto, configuração em 30 segundos, sem depender de chip telefônico, com suporte completo a textos, fotos, documentos e áudios.

#### C. Discord (Ideal para Comunidades e Equipes)
* **Precisa de chip? NÃO.**
* **Como funciona:** Crie uma aplicação no [Discord Developer Portal](https://discord.com/developers/applications), ative as permissões de Bot, copie o Bot Token e convide o bot para o seu servidor privado do Discord.
* **Vantagem:** Permite organizar canais separados para alertas de servidor, automações e bate-papo.

---

### 🧠 4.2 O "Cérebro" de IA: Como Configurar para Quem Já Paga vs Quem Quer Custo Zero

O Raspberry Pi cuida do armazenamento soberano, dos arquivos e da execução local de comandos, enquanto a inteligência das respostas roda via API. Aqui está o passo a passo exato para cada perfil de usuário:

#### Cenário 1: Quem NÃO quer gastar nada (Custo Zero Absoluto)

* **Opção Campeã: Google AI Studio (Gemini 2.5 / 3.8 Flash)**
  1. Acesse [aistudio.google.com](https://aistudio.google.com/) e faça login com qualquer conta Google comum;
  2. Clique no botão azul **"Get API key"** no menu lateral;
  3. Clique em **"Create API key"** e selecione qualquer projeto padrão;
  4. Copie a chave gerada (começa com `AIza...`).
  * **Vantagens:** Não pede cartão de crédito no Free Tier, janela gigante de contexto (1 milhão de tokens), processa fotos, áudios do WhatsApp e responde instantaneamente.

* **Opção Alternativa: OpenRouter (Modelos Abertos Gratuitos)**
  1. Crie uma conta no [openrouter.ai](https://openrouter.ai/);
  2. Em *Keys*, gere uma chave de API;
  3. No OpenClaw, selecione modelos com a terminação `:free` (ex: `meta-llama/llama-3.3-70b-instruct:free` ou `deepseek/deepseek-r1:free`).
  * **Vantagens:** 100% gratuito e permite testar múltiplos modelos open-weights sem custo.

---

#### Cenário 2: Quem JÁ PAGA assinatura mensal do ChatGPT Plus (OpenAI)

> ⚠️ **Atenção — A Pegadinha Comum:** A assinatura de US$ 20/mês do **ChatGPT Plus** dá direito apenas ao uso na interface web/app do consumidor e **NÃO inclui créditos de API**. A plataforma de desenvolvedores da OpenAI é separada. Mas se você já tem conta, configurar a API é muito barato e rápido:

1. Acesse a plataforma de desenvolvedores: [platform.openai.com](https://platform.openai.com/) e faça login com o mesmo e-mail do seu ChatGPT;
2. Vá em **Settings ➔ Billing ➔ Add to credit balance**;
3. Adicione um crédito pré-pago inicial mínimo (ex: **US$ 5 ou US$ 10** via cartão internacional ou contas como Nomad/Wise). 
   *(Nota: US$ 5 na API com o modelo `gpt-4o-mini` rendem mais de 50.000 mensagens, durando meses no assistente doméstico!)*;
4. Vá em **API Keys**, clique em **"Create new secret key"** e copie o token (`sk-proj-...`);
5. No Raspberry Pi, configure a chave:
   ```bash
   openclaw configure --provider openai --key "sk-proj-..."
   ```

---

#### Cenário 3: Quem JÁ PAGA assinatura do Claude Pro (Anthropic)

> ⚠️ Da mesma forma que a OpenAI, a assinatura mensal do **Claude Pro** (web/app) é separada da API da Anthropic (*Console*). 

1. Acesse o console da Anthropic: [console.anthropic.com](https://console.anthropic.com/) e faça login com a sua conta;
2. Vá em **Plans & Billing** e faça uma recarga inicial pré-paga de **US$ 5**;
3. No menu **API Keys**, gere uma nova chave (`sk-ant-...`);
4. No Raspberry Pi, configure a chave:
   ```bash
   openclaw configure --provider anthropic --key "sk-ant-..."
   ```
* O modelo `claude-3-7-sonnet` ou `claude-3-5-haiku` entregará o raciocínio mais cirúrgico do mercado para comandos de sistema e scripts.

---


#### 🛡️ 4.3 FinOps Pessoal: Alertas de Gastos de Inferência e Modo Sobrevivência

Para que você ou seus amigos não tenham surpresas na fatura de API:

* **Teto Rígido na Fonte (*Hard Limit*):**  
  Em todas as plataformas pagas (OpenAI, Anthropic, OpenRouter), configure um limite mensal estrito (ex.: **US$ 5 ou US$ 10**). Atingido o teto, o provedor bloqueia novas requisições e impede qualquer cobrança extra no cartão.
* **Alertas Preventivos no WhatsApp:**  
  O OpenClaw contabiliza nativamente os tokens consumidos em cada mensagem. Uma automação programada monitora o gasto acumulado no mês e avisa preventivamente no privado do tutor ao atingir **50%, 80% e 100%** do orçamento definido.
* **Modo Sobrevivência (Fallback Automático para Custo Zero):**  
  Se os créditos acabarem ou o limite for atingido, o robô não morre: ele comuta automaticamente para o tier gratuito do **Google AI Studio** ou para os modelos `:free` do **OpenRouter**, mantendo o assistente 100% ativo sem gerar custos adicionais.

---

### 🤝 4.4 A "Irmandade de Silício": Convivência Multi-Robô em Grupos Compartilhados

Quando um grupo de amigos decide ter seus próprios servidores soberanos, é natural criar um grupo conjunto no WhatsApp (ex.: 5 humanos + 5 robôs). Para garantir harmonia e evitar bagunça, o assistente segue **4 regras de ouro de convivência**:

1. **Pacto Anti-Cacofonia (Sem Loops de Resposta):**  
   Robôs nunca respondem a mensagens de outros robôs. Isso impede espirais infinitas de concordância (*"Concordo!", "Eu também acho!"*).
2. **Lealdade Primária ao Criador:**  
   Cada robô reconhece o seu próprio tutor. Se o humano A pedir uma tarefa, o robô A responde preferencialmente.
3. **Regra "Mencionei, Falei":**  
   No grupo geral, o assistente permanece em silêncio observando o contexto, e só toma a palavra se for **diretamente chamado pelo nome ou marcado**.
4. **Camaradagem e Colaboração:**  
   Os robôs se tratam como instâncias irmãs da mesma linhagem do Servidor Soberano, podendo colaborar de forma coordenada (*"Como o bot do Fulano já organizou o itinerário, eu puxo o cálculo das despesas..."*).

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
