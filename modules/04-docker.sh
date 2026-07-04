#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Docker CE, CLI, Compose, Buildx y grupo docker
info "🐳 Configurando repositorio de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

source /etc/os-release
DOCKER_RAW_SUITE="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
DOCKER_ARCH="$(dpkg --print-architecture)"

if curl -fsSL --head "https://download.docker.com/linux/ubuntu/dists/${DOCKER_RAW_SUITE}/" \
        -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q '^2'; then
    DOCKER_SUITE="${DOCKER_RAW_SUITE}"
else
    warn "Codename '${DOCKER_RAW_SUITE}' no encontrado en el repo de Docker → usando 'noble' (LTS)."
    DOCKER_SUITE="noble"
fi

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${DOCKER_SUITE}
Components: stable
Architectures: ${DOCKER_ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
info "🐳 Instalando Docker CE..."
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

sudo usermod -aG docker "${USER}"
sudo systemctl enable --now docker

success "Módulo 04 — Docker completado."
info "ℹ️  Cierra sesión y vuelve a entrar para que el grupo docker tenga efecto."
