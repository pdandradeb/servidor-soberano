# 🛠️ Guia de Hardware Soberano — Montando o Servidor Doméstico (raspd)

Documento de referência para aquisição e montagem da infraestrutura de hardware soberano (Raspberry Pi 5 + NVMe + Armazenamento Externo + Energia).

---

## 📋 Lista de Materiais (Bill of Materials - BOM)

### 1. Placa-Mãe & Processamento
* **Componente:** **Raspberry Pi 5 Model B (4GB ou 8GB)**
* **Por que:** Desempenho 2-3x superior ao Pi 4, PCIe 2.0/3.0 nativo para NVMe de altíssima velocidade, 4x Cortex-A76 @ 2.4GHz com suporte a virtualização Docker e compilação ágil.
* **Onde Comprar no Brasil:**
  * **MakerHero** (antiga FilipeFlop, revendedora oficial): `makerhero.com`
  * **RoboCore** (revendedora autorizada oficial): `robocore.net`
  * **Baú da Eletrônica**: `baudaeletronica.com.br`
  * **Mercado Livre**: Lojas oficiais / revendedores autorizados com entrega Full.

---

### 2. Alimentação Elétrica (Crítico)
* **Componente:** **Fonte Oficial Raspberry Pi 27W USB-C (5.1V / 5A com Power Delivery)**
* **Por que:** O Raspberry Pi 5 exige negociar 5A via protocolo PD para liberar a potência total de 1.6A nas portas USB e alimentação estável do barramento PCIe do SSD NVMe sem sofrer undervoltage (*throttling*). Fontes comuns de celular de 15W/18W causam instabilidade no boot com NVMe.
* **Onde Comprar no Brasil:**
  * **MakerHero**: Geralmente vendida avulsa ou no *Kit Raspberry Pi Basic*.
  * **RoboCore**: Pronta-entrega com certificação e tomada padrão BR (ABNT NBR 14136).
  * **Mercado Livre / Amazon Brasil**.

---

### 3. Arrefecimento Térmico
* **Componente:** **Raspberry Pi Active Cooler Oficial**
* **Por que:** O SoC BCM2712 do Pi 5 dissipa calor considerável sob carga de containers Docker. O Active Cooler oficial é de alumínio maciço, possui ventoinha blower controlada por PWM nativo no conector JST do Pi (só liga quando necessário e opera silencioso) e pads térmicos dedicados para SoC, PMIC e chip de rede.
* **Onde Comprar no Brasil:**
  * **MakerHero** / **RoboCore** / **Amazon Brasil**.

---

### 4. Armazenamento Primário (SO & Bancos de Dados)
* **Componente:** **SSD M.2 NVMe (256GB a 1TB)**
* **Modelos Recomendados:**
  * *Kingston NV2 / NV3 (PCIe 4.0 NVMe M.2 2280)*
  * *Western Digital WD Blue SN580 / SN570 (M.2 2280)*
  * *Crucial P3 Plus (M.2 2280)*
  * *(Ou padrão OEM M.2 2230/2242 como SK hynix BC501 / Kioxia / Samsung PM991)*
* **Por que:** Cartões microSD corrompem com facilidade sob escrita contínua de bancos de dados (Nextcloud, Docker, Pi-hole, logs). O NVMe entrega 400 a 800 MB/s de taxa real de transferência e vida útil incomparável.
* **Onde Comprar no Brasil:**
  * **KaBuM!**, **Pichau**, **TerabyteShop**, **Amazon Brasil**, **Mercado Livre**.

---

### 5. Adaptador PCIe para M.2 NVMe (HAT / Base)
* **Componentes Recomendados:**
  * **Geekworm X1001** (HAT superior compacto M.2 Key-M) ou **Geekworm X1002**;
  * **Pimoroni NVMe Base** (montagem na parte inferior do Pi, excelente perfil baixo);
  * **Waveshare PCIe to M.2 HAT+**.
* **Onde Comprar no Brasil:**
  * **Amazon Brasil** (Compra internacional com frete Prime e impostos inclusos / Remessa Conforme, sem surpresa);
  * **Mercado Livre** (Vendedores com estoque no Brasil);
  * **AliExpress** (Lojas oficiais Geekworm / Waveshare via Remessa Conforme).

---

### 6. Case / Gabinete de Proteção
* **Componentes Recomendados:**
  * **Argon NEO 5 M.2 NVMe PCIe Case**: Corpo em liga de alumínio que atua como dissipador passivo e já acomoda a placa adaptadora NVMe na base;
  * **Argon ONE V3 M.2 NVMe Case**: Gabinete completo com botão liga/desliga scriptado, gestão de cabos traseira e slot M.2 NVMe integrado;
  * **Case Oficial Raspberry Pi 5** (para quem usa HAT NVMe inferior ou microSD).
* **Onde Comprar no Brasil:**
  * **Amazon Brasil**;
  * **Mercado Livre**;
  * **AliExpress** (Argon40 Official Store).

---

### 7. Armazenamento em Massa & Soberania de Dados (Acervo Pessoal)
* **Componente:** **HD Externo 2.5" USB 3.0 (2TB a 4TB)**
* **Modelos Testados e Recomendados:**
  * *Toshiba Canvio Basics / Advance (2TB a 4TB)* (excelente relação custo-benefício e baixo consumo na porta USB);
  * *Seagate Expansion (2TB a 4TB)*;
  * *Western Digital Elements / My Passport (2TB a 4TB)*.
* **Onde Comprar no Brasil:**
  * **Amazon Brasil**, **KaBuM!**, **Mercado Livre**.

---

### 8. Proteção Elétrica & Infraestrutura de Rede
* **Cabo de Rede:** Cabo Ethernet Cat6 (1 Gbps) conectado diretamente ao roteador principal.
* **Proteção Elétrica:** Filtro de linha com DPS de qualidade (ex: **Clamper Energia 5** ou **Energia 8**) ou Mini Nobreak DC 12V/5V (Intelbras) para evitar desligamentos abruptos em oscilações de energia.
