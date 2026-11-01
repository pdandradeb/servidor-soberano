# 🪟 Guia do Servidor Soberano no Windows & WSL2

> Este guia foi feito especialmente para quem usa **Windows 10 ou Windows 11** no computador pessoal e quer montar seu próprio **Servidor Doméstico com Raspberry Pi** (ou rodar um laboratório soberano diretamente dentro do Windows via WSL2).

---

## 🧭 O Fluxo Estratégico ("OpenClaw First")

A ideia central deste projeto é a simplicidade radical:
1. **Gravar o sistema no disco pelo Windows** com SSH e rede pré-configurados (sem precisar ligar monitor ou teclado no Raspberry Pi).
2. **Conectar via SSH pelo Windows Terminal / PowerShell** e rodar o instalador do **OpenClaw** nos primeiros 5 minutos.
3. **Escanear o QR Code no WhatsApp**: a partir desse momento, o seu **assistente pessoal de IA acorda no WhatsApp** e se torna seu copiloto técnico em tempo real para executar, monitorar e explicar o restante das instalações (Pi-hole, Nextcloud, Docker, etc.).

---

## 🛠️ Parte 1: Preparando o Raspberry Pi a partir do Windows

Você não precisa de nenhum software complicado. O próprio Windows 10/11 já vem com cliente SSH e ferramentas modernas.

### 1.1 Gravação com o Raspberry Pi Imager
1. No Windows, abra o **PowerShell** ou Terminal e instale o gravador oficial:
   ```powershell
   winget install RaspberryPi.RaspberryPiImager
   ```
   *(Ou baixe direto pelo site oficial: [raspberrypi.com/software](https://www.raspberrypi.com/software/))*
2. Conecte o SSD NVMe (via case USB-C) ou o cartão microSD no seu PC Windows.
3. No Raspberry Pi Imager:
   * **Dispositivo:** Escolha **Raspberry Pi 5** (ou Pi 4);
   * **Sistema Operacional:** Escolha **Raspberry Pi OS (64-bit) Lite** (sem interface gráfica para máxima performance);
   * **Armazenamento:** Selecione o seu SSD / cartão.
4. Clique em **Próximo** e selecione **Editar Configurações** (ou pressione `Ctrl + Shift + X`):
   * **Nome do host (Hostname):** `raspd` (ou o nome que preferir);
   * **Nome de usuário e senha:** defina seu usuário (ex: `raspd`) e uma senha forte;
   * **Configurar Wi-Fi:** preencha SSID e senha (se não for usar cabo de rede Gigabit conectado direto no roteador);
   * **Ativar SSH:** Marque **"Permitir autenticação por senha"** ou insira sua chave pública.
5. Grave o disco, insira no Raspberry Pi e ligue na tomada.

---

### 1.2 Conectando ao Raspberry Pi pelo PowerShell
Aguarde cerca de 60 segundos após ligar o Raspberry Pi na tomada para o sistema inicializar.

1. No Windows, abra o **PowerShell** ou **Windows Terminal** e conecte diretamente:
   ```powershell
   ssh raspd@raspd.local
   ```
2. Digite `yes` para aceitar a chave do servidor e insira a senha que você configurou no Imager.

> **💡 Dica se `raspd.local` não responder no Windows:**
> Em algumas redes Windows, o mDNS (*Bonjour*) pode demorar para resolver o nome. Se isso acontecer:
> * Verifique o IP do Raspberry Pi no painel do seu roteador (ou use o app *Fing* no celular);
> * Conecte diretamente pelo IP: `ssh raspd@192.168.15.X`.

---

### 1.3 (Opcional, mas Recomendado) Chave SSH sem Senha no Windows
Para entrar no seu servidor instantaneamente sem precisar digitar senha toda vez:

1. No **PowerShell** do seu Windows, gere uma chave moderna (se ainda não tiver):
   ```powershell
   ssh-keygen -t ed25519
   ```
   *(Basta pressionar Enter para salvar no caminho padrão).*
2. Copie a chave para o Raspberry Pi:
   ```powershell
   type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh raspd@raspd.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```
3. Pronto! O próximo `ssh raspd@raspd.local` entrará direto sem pedir senha.

---

## 🤖 Parte 2: Acorde o Copiloto (OpenClaw no WhatsApp)

Assim que você estiver logado no terminal do Raspberry Pi, a primeira ação deve ser subir o assistente de IA:

```bash
curl -fsSL https://raw.githubusercontent.com/pdandradeb/servidor-soberano/main/scripts/bootstrap.sh | bash
```

Esse comando instala automaticamente o Node.js 24 LTS, Docker, ferramentas essenciais e o OpenClaw.

Em seguida, execute:
```bash
openclaw onboard
```

1. Escolha seu provedor de inteligência artificial (Google Gemini 3.8 Flash, Anthropic Claude ou OpenAI);
2. Selecione o canal **WhatsApp**;
3. O terminal exibirá um **QR Code**: abra o WhatsApp no seu smartphone, vá em **Aparelhos Conectados ➔ Conectar Aparelho** e aponte a câmera para a tela do Windows Terminal!
4. **Pronto!** O assistente já está ativo no seu WhatsApp. A partir daqui você pode mandar áudio ou texto para ele executar comandos, checar a temperatura do Pi ou continuar o setup da sua nuvem.

---

## 💾 Parte 3: Conectando HDs Externos para Backup & Acervo

Se você pretende conectar HDs externos USB (de 2TB, 4TB ou mais) para fotos, filmes, backups do Time Machine ou Nextcloud:

### ⚡ 3.1 Atenção Crítica à Alimentação Elétrica
* HDs mecânicos USB de 2.5" puxam picos altos de corrente elétrica na inicialização dos discos.
* **No Raspberry Pi 5:** Use obrigatoriamente a **Fonte Oficial Raspberry Pi 27W USB-C PD**. Ela fornece 5A a 5.1V, garantindo corrente suficiente para as portas USB 3.0 sem travar o sistema.
* **No Raspberry Pi 4 ou com mais de 1 HD:** Use um **Hub USB 3.0 com fonte de tomada própria** (*powered USB hub*) para alimentar os HDs externamente e poupar o barramento do Pi.

### 3.2 Formatação do HD (Qual sistema de arquivos escolher?)
* **`ext4` (Recomendado para Soberania Máxima):** Nativo do Linux, suporta permissões completas de arquivos, links simbólicos e não fragmenta. É o melhor para Nextcloud e Docker.
* **`exFAT` (Se você precisa plugar o HD fisicamente no Windows às vezes):** Compatível com Windows e Linux. Para habilitar no Pi: `sudo apt install -y exfat-fuse exfatprogs`.
* **`NTFS`:** Funciona no Linux com o driver `ntfs-3g`, mas pode ser mais lento sob alta carga de I/O contínuo.

### 3.3 Montagem Automática no Linux (`/etc/fstab`)
Para o HD nunca mudar de nome e montar sempre na mesma pasta a cada reinicialização:

1. Conecte o HD na porta USB 3.0 (azul) do Raspberry Pi;
2. Descubra o **UUID** único da partição:
   ```bash
   sudo blkid
   ```
   *(Identifique a linha do seu disco, por exemplo: `/dev/sda1: UUID="a1b2c3d4-..." TYPE="ext4"`)*.
3. Crie a pasta de montagem no servidor:
   ```bash
   sudo mkdir -p /mnt/dados
   sudo chown -R $USER:$USER /mnt/dados
   ```
4. Adicione ao arquivo `/etc/fstab` com proteção contra travamento de boot:
   ```bash
   sudo nano /etc/fstab
   ```
   Insira a linha no final (substituindo pelo seu UUID e tipo de filesystem):
   ```fstab
   UUID=seu-uuid-aqui  /mnt/dados  ext4  defaults,nofail,noatime  0  2
   ```
   *(O parâmetro `nofail` é crucial: se o HD estiver desligado ou desconectado na hora do boot, o Raspberry Pi liga normalmente sem travar o sistema).*
5. Teste a montagem sem reiniciar:
   ```bash
   sudo mount -a
   df -h /mnt/dados
   ```

### 3.4 Acessando o HD do Raspberry Pi pelo Windows Explorer (Samba)
Para ver o HD do seu servidor no Windows Explorer como se fosse uma pasta do seu PC:

1. No Raspberry Pi, instale o Samba:
   ```bash
   sudo apt install -y samba
   ```
2. Configure o compartilhamento no arquivo `/etc/samba/smb.conf`:
   ```ini
   [Dados]
      path = /mnt/dados
      read only = no
      browsable = yes
      create mask = 0775
      directory mask = 0775
      valid users = raspd
   ```
3. Crie a senha de rede Samba:
   ```bash
   sudo smbpasswd -a raspd
   sudo systemctl restart smbd
   ```
4. No seu computador Windows:
   * Abra o **Windows Explorer** (`Win + E`);
   * Na barra de endereços, digite: `\\raspd.local\Dados` (ou pelo IP: `\\192.168.15.X\Dados`);
   * Digite seu usuário e senha e marque "Lembrar minhas credenciais".
   * Se quiser fixar uma letra (como `Z:`), clique com o botão direito na pasta e selecione **"Mapear unidade de rede..."**.

---

## 🐧 Parte 4: Alternativa — Rodando no WSL2 (Sem Raspberry Pi Físico)

Se algum amigo quiser experimentar a soberania de dados ou rodar o OpenClaw **diretamente no computador Windows**, sem precisar comprar uma placa Raspberry Pi agora, é possível fazer tudo dentro do **WSL2 (Windows Subsystem for Linux)**.

### 4.1 Instalando o WSL2 no Windows
1. Abra o **PowerShell como Administrador** e execute:
   ```powershell
   wsl --install -d Ubuntu
   ```
2. Reinicie o computador se for solicitado.
3. Ao abrir o terminal do Ubuntu, defina seu usuário e senha.

### 4.2 Otimizando a Rede do WSL2 no Windows 11 (Modo Mirrored)
Por padrão, o WSL2 cria uma máquina virtual com NAT próprio. No Windows 11 (build recente), você pode ativar o modo **mirrored**, que faz o WSL2 compartilhar o mesmo IP e portas do seu Windows na sua rede local!

1. No Windows, crie ou edite o arquivo `C:\Users\SeuUsuario\.wslconfig`:
   ```ini
   [wsl2]
   networkingMode=mirrored
   memory=4GB
   processors=4
   ```
2. No PowerShell, reinicie o WSL:
   ```powershell
   wsl --shutdown
   ```

### 4.3 Instalando o OpenClaw no WSL2
Dentro do terminal Ubuntu do WSL2, basta rodar:
```bash
curl -fsSL https://raw.githubusercontent.com/pdandradeb/servidor-soberano/main/scripts/bootstrap.sh | bash
openclaw onboard
```
Escaneie o QR Code no WhatsApp e pronto! O seu assistente pessoal estará rodando dentro do seu PC Windows.

### 4.4 Conectando HDs USB Físicos no WSL2 (via usbipd-win)
Para que o Linux do WSL consiga enxergar um pendrive ou HD USB conectado na porta do seu computador:

1. No Windows (PowerShell como Admin), instale o utilitário oficial da Microsoft:
   ```powershell
   winget install dorssel.usbipd-win
   ```
2. Liste os dispositivos USB conectados:
   ```powershell
   usbipd list
   ```
3. Compartilhe e anexe o disco ao WSL:
   ```powershell
   # Substitua pelo BUSID do seu disco (ex: 2-3)
   usbipd bind --busid 2-3
   usbipd attach --wsl --busid 2-3
   ```
4. Dentro do WSL2, o disco aparecerá em `lsblk` e pode ser montado normalmente com `sudo mount /dev/sdX /mnt/dados`.

---

## 🚀 Resumo do Checklist para Amigos com Windows

| Etapa | Onde faz? | O que usar? | Resultado |
|---|---|---|---|
| **1. Gravar Disco** | Windows | Raspberry Pi Imager | SO Lite + SSH + Wi-Fi configurados |
| **2. Conectar** | Windows | PowerShell / Windows Terminal | `ssh raspd@raspd.local` sem monitor |
| **3. Acordar IA** | Terminal Pi | `bootstrap.sh` + `openclaw onboard` | Copiloto no WhatsApp pronto para guiar o resto |
| **4. Nuvem & DNS** | WhatsApp / Pi | Pi-hole + Nextcloud | Rede protegida e nuvem de arquivos ativa |
| **5. Armazenamento** | Pi + Windows | Samba (`\\raspd.local\Dados`) | HD de 4TB visível nativamente no Windows Explorer |
