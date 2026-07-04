#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: NVM, Node.js 24, pnpm, Bun, PostgreSQL, Flutter, AI CLIs y Tailscale
info "📦 Instalando NVM y Node.js 24..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"

nvm install 24
nvm use 24
nvm alias default 24
node -v
npm -v

info "📦 Instalando pnpm..."
npm install -g pnpm
pnpm --version

info "🍞 Instalando Bun..."
curl -fsSL https://bun.sh/install | bash

info "🐘 Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
success "PostgreSQL instalado y servicio activado."

info "📱 Instalando Flutter SDK y dependencias..."
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
sudo snap install flutter --classic
success "Flutter SDK instalado. Ejecuta 'flutter doctor' para verificar."

info "🤖 Instalando AI CLIs (Gemini, Claude Code, Codex, OpenCode)..."
npm install -g @google/gemini-cli
npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex
npm install -g opencode-ai

info "🧠 Instalando Hermes Agent (Nous Research)..."
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

info "🔗 Instalando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

info "💡 NOTA: Los PATHs de NVM, pnpm, Bun y los AI CLIs se agregarán"
info "       a ~/.zshrc cuando ejecutes el módulo 06 (Terminal / Oh My Zsh)."

success "Módulo 03 — Herramientas de desarrollo completado."
