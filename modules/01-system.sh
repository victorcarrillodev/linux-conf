#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Limpieza de repositorios, actualización del sistema y herramientas base
info "🧹 Limpiando conflictos previos de repositorios..."

sudo rm -f \
    /etc/apt/keyrings/docker.gpg \
    /etc/apt/keyrings/docker.asc \
    /etc/apt/sources.list.d/docker*.list \
    /etc/apt/sources.list.d/docker*.sources

sudo sh -c 'grep -rl "packages.microsoft.com" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f'
sudo rm -f \
    /usr/share/keyrings/microsoft.gpg \
    /usr/share/keyrings/packages.microsoft.gpg \
    /etc/apt/trusted.gpg.d/microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg

sudo rm -f \
    /etc/apt/keyrings/antigravity-repo-key.gpg \
    /etc/apt/sources.list.d/antigravity.list \
    /etc/apt/sources.list.d/antigravity.sources

info "📦 Actualizando repositorios y paquetes..."
sudo apt update && sudo env DEBIAN_FRONTEND=noninteractive apt upgrade -y

info "🛠️ Instalando utilidades base..."
sudo env DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    wget \
    git \
    build-essential \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa

success "Módulo 01 — Sistema base completado."
