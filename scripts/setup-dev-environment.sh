#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# scripts/setup-dev-environment.sh
# Provisionamento idempotente de ferramentas de desenvolvimento e Skills no raspd
# (Debian 13 trixie aarch64 / Raspberry Pi 5)
# ==============================================================================

TARGET_HOST="${1:-raspd}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================================"
echo " 🛠️  Provisionando ferramentas e Skills em: $TARGET_HOST"
echo "======================================================"

ssh -o BatchMode=yes "$TARGET_HOST" bash << 'REMOTE_SCRIPT'
set -euo pipefail

echo "▶ 1. Instalando pacotes base via APT..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  poppler-utils \
  lazygit \
  gh \
  postgresql-client \
  tmux \
  rsync \
  curl \
  jq \
  ca-certificates \
  xz-utils

echo "▶ 2. Verificando Docker Engine & Compose..."
if ! command -v docker >/dev/null 2>&1; then
  echo "  - Instalando Docker via script oficial..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker raspd
  sudo systemctl enable --now docker
else
  echo "  ✓ Docker $(docker --version | cut -d, -f1) já instalado."
fi

echo "▶ 3. Verificando Typst (compilador de PDFs)..."
if ! command -v typst >/dev/null 2>&1; then
  echo "  - Baixando binário oficial ARM64 do Typst..."
  curl -fsSL "https://github.com/typst/typst/releases/download/v0.15.1/typst-aarch64-unknown-linux-musl.tar.xz" | tar -xJf - -C /tmp
  sudo mv /tmp/typst-aarch64-unknown-linux-musl/typst /usr/local/bin/typst
  sudo chmod +x /usr/local/bin/typst
  rm -rf /tmp/typst-aarch64-unknown-linux-musl
fi
echo "  ✓ $(typst --version) pronto."

echo "▶ 4. Verificando yt-dlp..."
if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "  - Instalando standalone binary do yt-dlp..."
  sudo curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64 -o /usr/local/bin/yt-dlp
  sudo chmod +x /usr/local/bin/yt-dlp
fi
echo "  ✓ yt-dlp $(yt-dlp --version) pronto."

echo "▶ 5. Verificando uv (Python fast runtime & package manager)..."
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv
  sudo ln -sf "$HOME/.local/bin/uvx" /usr/local/bin/uvx
fi
echo "  ✓ $(uv --version) pronto."

echo "▶ 6. Verificando nvm..."
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
echo "  ✓ nvm pronto."

echo "▶ 7. Verificando OpenCode CLI..."
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/install | bash
  sudo ln -sf "$HOME/.opencode/bin/opencode" /usr/local/bin/opencode
fi
echo "  ✓ opencode $(opencode --version) pronto."

echo "▶ 8. Sincronizando credenciais do Gemini para o OpenCode..."
python3 -c '
import sqlite3, json, os

db_path = "/home/raspd/.openclaw/state/openclaw.sqlite"
if not os.path.exists(db_path):
    print("  ⚠ openclaw.sqlite não encontrado, pulando injeção de chave.")
    exit(0)

con = sqlite3.connect(db_path)
cur = con.cursor()
row = cur.execute("SELECT value_json FROM config_machine_state WHERE state_key = \"authProfiles.store\"").fetchone()
if not row:
    print("  ⚠ authProfiles.store não encontrado.")
    exit(0)

data = json.loads(row[0])
google_key = None
for prof_id, prof in data.get("profiles", {}).items():
    if prof.get("provider") == "google":
        google_key = prof.get("key")
        break

if google_key:
    os.makedirs("/home/raspd/.local/share/opencode", exist_ok=True)
    os.makedirs("/home/raspd/.config/opencode", exist_ok=True)

    auth_path = "/home/raspd/.local/share/opencode/auth.json"
    with open(auth_path, "w") as f:
        json.dump({"google": {"type": "api", "key": google_key}}, f, indent=2)
    os.chmod(auth_path, 0o600)

    cfg_path = "/home/raspd/.config/opencode/opencode.jsonc"
    with open(cfg_path, "w") as f:
        f.write("{\n  \"$schema\": \"https://opencode.ai/config.json\",\n  \"model\": \"google/gemini-3.8-flash\"\n}\n")

    print("  ✓ Chave Gemini e modelo google/gemini-3.8-flash configurados no OpenCode.")
'

echo "▶ 9. Habilitando skill de coding-agent no OpenClaw..."
openclaw config set skills.entries.coding-agent.enabled true >/dev/null 2>&1 || true

echo "▶ 10. Clonando ou atualizando repositório raspd no Raspberry Pi..."
mkdir -p "$HOME/dev"
if [[ ! -d "$HOME/dev/raspd/.git" ]]; then
  git clone git@github.com:pdandradeb/raspd.git "$HOME/dev/raspd"
else
  (cd "$HOME/dev/raspd" && git pull --ff-only) || true
fi

echo "▶ 11. Criando symlink permanente de ~/.openclaw/workspace/skills -> ~/dev/raspd/skills..."
mkdir -p "$HOME/.openclaw/workspace"
rm -rf "$HOME/.openclaw/workspace/skills"
ln -sfn "$HOME/dev/raspd/skills" "$HOME/.openclaw/workspace/skills"

REMOTE_SCRIPT

echo ""
echo "======================================================"
echo " ✅ Ambiente e Skills configurados com sucesso em $TARGET_HOST!"
echo "======================================================"
