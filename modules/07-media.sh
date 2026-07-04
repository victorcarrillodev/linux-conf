#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: LibreOffice, codecs multimedia, VLC y MPV
info "📄 Instalando LibreOffice..."
if ! dpkg-query -W -f='${Status}' libreoffice-fresh 2>/dev/null | grep -q 'install ok installed'; then
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt update
    sudo apt install -y \
        libreoffice-fresh \
        libreoffice-fresh-es \
        libreoffice-style-sukapura
    success "LibreOffice instalado correctamente."
else
    warn "LibreOffice ya está instalado, omitiendo."
fi

info "🎬 Instalando codecs y soporte multimedia..."
sudo add-apt-repository -y -n multiverse
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
    | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ubuntu-restricted-extras \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-vaapi
success "Codecs multimedia instalados."

info "🎵 Instalando reproductores multimedia..."
sudo apt install -y \
    vlc \
    mpv
success "Reproductores VLC y MPV instalados."

success "Módulo 07 — Ofimática y multimedia completado."
