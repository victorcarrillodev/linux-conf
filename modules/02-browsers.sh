#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Purga Firefox, instala Brave, Chrome, Variety y wallpapers
info "🔥 Purgando Firefox..."
sudo umount /var/snap/firefox/common/host-hunspell 2>/dev/null || true
sudo snap remove --purge firefox 2>/dev/null || true
sudo apt purge -y firefox 2>/dev/null || true
sudo apt autoremove -y
rm -rf ~/.mozilla 2>/dev/null || true
rm -rf ~/snap/firefox 2>/dev/null || true

info "🦁 Instalando Brave Nightly..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg \
    https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg arch=amd64] https://brave-browser-apt-nightly.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-nightly.list > /dev/null
sudo apt update
sudo apt install -y brave-browser-nightly

info "🌐 Instalando Google Chrome Dev..."
CHROME_DEB="$(mktemp /tmp/google-chrome-XXXXXX.deb)"
wget -q -O "${CHROME_DEB}" https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb
sudo apt install -y "${CHROME_DEB}"
rm -f "${CHROME_DEB}"

info "🖌️ Instalando Variety y Wallpapers..."
sudo apt install -y variety
if [ ! -d "${HOME}/wallpapers" ]; then
    git clone --depth=1 https://github.com/victorcarrillodev/wallpapers.git "${HOME}/wallpapers"
else
    warn "Wallpapers ya clonados, omitiendo."
fi

success "Módulo 02 — Navegadores completado."
