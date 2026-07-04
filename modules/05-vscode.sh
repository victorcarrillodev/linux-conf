#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Visual Studio Code y Antigravity
info "📝 Configurando repositorio de VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null \
    <<< "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"

info "📝 Configurando repositorio de Antigravity..."
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL -o /etc/apt/keyrings/antigravity-repo-key.gpg \
    https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg

sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null \
    <<< "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main"

sudo apt update
info "📝 Instalando VS Code y Antigravity..."
sudo apt install -y code antigravity

success "Módulo 05 — VS Code y Antigravity completado."
