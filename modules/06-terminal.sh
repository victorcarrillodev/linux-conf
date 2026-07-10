#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Zsh, Oh My Zsh, Powerlevel10k, fuentes, banner y shell por defecto
info "💻 Configurando Zsh y herramientas visuales..."
sudo -S -p '' apt install -y zsh fonts-font-awesome figlet toilet lolcat

# --- Oh My Zsh ---
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    env CHSH=no RUNZSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    warn "Oh My Zsh ya instalado, omitiendo."
fi

# --- Fuentes ---
FONT_DIR="${HOME}/.local/share/fonts"
mkdir -p "${FONT_DIR}"
NERD_FONTS_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# CascadiaCode Nerd Font (en nerd-fonts se distribuye como "CaskaydiaCove Nerd Font")
info "🔤 Descargando CascadiaCode Nerd Font..."
CASCADIA_TMP="$(mktemp /tmp/cascadia-XXXXXX.tar.xz)"
if curl -fsSL --retry 3 --retry-delay 2 -o "${CASCADIA_TMP}" "${NERD_FONTS_BASE}/CascadiaCode.tar.xz"; then
    tar -xJf "${CASCADIA_TMP}" -C "${FONT_DIR}" 2>/dev/null
    CASCADIA_COUNT="$(find "${FONT_DIR}" -maxdepth 1 -iname "CaskaydiaCove*" 2>/dev/null | wc -l)"
    success "CascadiaCode (Caskaydia Cove NF): ${CASCADIA_COUNT} archivos instalados."
else
    warn "No se pudo descargar CascadiaCode. Verifica conexión."
fi
rm -f "${CASCADIA_TMP}"

# MesloLGS NF (necesaria para Powerlevel10k)
# Fuente canonical de p10k: repo romkatv/powerlevel10k-media
MESLO_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"

declare -A MESLO_FONTS=(
    ["MesloLGS NF Regular.ttf"]="${MESLO_BASE}/MesloLGS%20NF%20Regular.ttf"
    ["MesloLGS NF Bold.ttf"]="${MESLO_BASE}/MesloLGS%20NF%20Bold.ttf"
    ["MesloLGS NF Italic.ttf"]="${MESLO_BASE}/MesloLGS%20NF%20Italic.ttf"
    ["MesloLGS NF Bold Italic.ttf"]="${MESLO_BASE}/MesloLGS%20NF%20Bold%20Italic.ttf"
)

MESLO_ERRORS=0
for FONT_NAME in "${!MESLO_FONTS[@]}"; do
    FONT_URL="${MESLO_FONTS[${FONT_NAME}]}"
    DEST="${FONT_DIR}/${FONT_NAME}"
    if curl -fsSL --retry 3 --retry-delay 2 -o "${DEST}" "${FONT_URL}"; then
        echo "  ✔ ${FONT_NAME}"
    else
        warn "No se pudo descargar: ${FONT_NAME}"
        (( MESLO_ERRORS++ )) || true
    fi
done

if (( MESLO_ERRORS == 0 )); then
    success "MesloLGS NF: 4 archivos instalados correctamente."
else
    warn "MesloLGS NF: ${MESLO_ERRORS} archivo(s) fallaron. Verifica conexión."
fi

fc-cache -fv
success "Caché de fuentes actualizada."

# --- Wave Terminal ---
info "🌊 Instalando Wave Terminal..."
if ! command -v wave &>/dev/null; then
    # El nombre del paquete cambia según versión/arquitectura, así que lo
    # resolvemos dinámicamente desde la API de releases de GitHub.
    case "$(uname -m)" in
        x86_64)  WAVE_ARCH="amd64" ;;
        aarch64) WAVE_ARCH="arm64" ;;
        *)       WAVE_ARCH="amd64" ;;
    esac
    WAVE_API="https://api.github.com/repos/wavetermdev/waveterm/releases/latest"
    ASSET_URL="$(curl -fsSL "${WAVE_API}" \
        | grep -oE "https://[^\"]*waveterm-linux-${WAVE_ARCH}-[^\"]*\.deb" \
        | head -1)"
    if [ -n "${ASSET_URL}" ]; then
        WAVE_DEB="$(mktemp /tmp/waveterm-XXXXXX.deb)"
        if curl -fsSL --retry 3 --retry-delay 2 -o "${WAVE_DEB}" "${ASSET_URL}"; then
            sudo -S -p '' env DEBIAN_FRONTEND=noninteractive apt install -y "${WAVE_DEB}"
            success "Wave Terminal instalado."
        else
            warn "No se pudo descargar Wave Terminal. Verifica conexión."
        fi
        rm -f "${WAVE_DEB}"
    else
        warn "No se encontró un paquete .deb para la arquitectura ${WAVE_ARCH}. Omitiendo Wave Terminal."
    fi
else
    warn "Wave Terminal ya instalado, omitiendo."
fi

# --- Powerlevel10k y Plugins ---
ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"

[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ] && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM}/themes/powerlevel10k"

[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ] && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ] && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

# --- Configurar .zshrc: tema y plugins ---
# Powerlevel10k (con fallback si ~/.zshrc no trae el tema por defecto)
if grep -q 'ZSH_THEME="robbyrussell"' ~/.zshrc; then
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    success "Tema cambiado a Powerlevel10k."
elif ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc; then
    sed -i '1i ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
    warn "No se encontró ZSH_THEME en ~/.zshrc; se insertó Powerlevel10k al inicio."
fi

# Plugins (con fallback si la línea no es la estándar 'plugins=(git)')
if ! grep -q 'web-search' ~/.zshrc 2>/dev/null; then
    if grep -Eq '^plugins=\(' ~/.zshrc 2>/dev/null; then
        sed -i -E 's/^plugins=\((.*)\)$/plugins=(\1 web-search)/' ~/.zshrc
    else
        printf '\nplugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search docker docker-compose python)\n' >> ~/.zshrc
    fi
    success "Plugin web-search añadido a ~/.zshrc."
else
    success "Plugins verificados en ~/.zshrc."
fi

# --- Control de Instant Prompt de Powerlevel10k ---
# Para evitar advertencias y que el banner siempre se muestre sin 'saltos',
# forzamos `POWERLEVEL9K_INSTANT_PROMPT=off` (desactiva instant prompt).
if grep -q 'POWERLEVEL9K_INSTANT_PROMPT' "${HOME}/.zshrc" 2>/dev/null; then
    sed -i 's/^.*POWERLEVEL9K_INSTANT_PROMPT=.*$/typeset -g POWERLEVEL9K_INSTANT_PROMPT=off/' "${HOME}/.zshrc"
    success "POWERLEVEL9K_INSTANT_PROMPT actualizado a 'off' en ~/.zshrc"
else
    sed -i '1i typeset -g POWERLEVEL9K_INSTANT_PROMPT=off' "${HOME}/.zshrc"
    success "Se añadió POWERLEVEL9K_INSTANT_PROMPT=off a ~/.zshrc"
fi

info "🔧 Asegurando PATH para Bash y Zsh..."
for rc_file in "${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    ensure_path_entry "${HOME}/.local/bin" "${rc_file}" "# >>> linux-conf PATH ${HOME}/.local/bin >>>"
    ensure_path_entry "${HOME}/.cargo/bin" "${rc_file}" "# >>> linux-conf PATH ${HOME}/.cargo/bin >>>"
    ensure_path_entry "${HOME}/.bun/bin" "${rc_file}" "# >>> linux-conf PATH ${HOME}/.bun/bin >>>"
    ensure_path_entry "${HOME}/.local/share/pnpm" "${rc_file}" "# >>> linux-conf PATH ${HOME}/.local/share/pnpm >>>"
done

# --- Agregar PATHs de NVM, pnpm y Bun a .zshrc (bloques multi-línea reales) ---
# NOTA: se usan heredocs con delimitador entrecomillado para que los saltos de
# línea y las barras invertidas (\.) se conserven literales en el archivo.
NVM_BLOCK="$(cat <<'NVM_EOF'
# ------ NVM INIT ------
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"
# ------ END NVM INIT ------
NVM_EOF
)"
append_zshrc_block "# ------ NVM INIT ------" "${NVM_BLOCK}"

PNPM_BLOCK="$(cat <<'PNPM_EOF'
# ------ PNPM PATH ------
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":${PATH}:" in
  *":${PNPM_HOME}:"*) ;;
  *) export PATH="${PNPM_HOME}:${PATH}" ;;
esac
# ------ END PNPM PATH ------
PNPM_EOF
)"
append_zshrc_block "# ------ PNPM PATH ------" "${PNPM_BLOCK}"

BUN_BLOCK="$(cat <<'BUN_EOF'
# ------ BUN PATH ------
export BUN_INSTALL="${HOME}/.bun"
export PATH="${BUN_INSTALL}/bin:${PATH}"
# ------ END BUN PATH ------
BUN_EOF
)"
append_zshrc_block "# ------ BUN PATH ------" "${BUN_BLOCK}"

# --- Banner ---
BANNER_MARKER="# === BANNER VICTOR CARRILLO ==="
if ! grep -qF "${BANNER_MARKER}" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'ZSHRC_BANNER'

# === BANNER VICTOR CARRILLO ===
echo ""
paste -d '  ' <(
  (
    toilet -f ivrit  -F border -w 90 '</> Victor Carrillo'
    toilet -f pagga  -w 90 "master linux dev pro >>"
    toilet -f emboss -w 90 "illuminati"
  ) | awk '{ printf "%-85s\n", $0 }'
) <(cat << 'EOF_INNER'
           \' /\ \'
             / _\
       \    /_|__\   /
       \   /_|__|_\  /
          /_ ( °)- \
         /__ __|_ __\
        /__|______|__\
       /_|_____|____|_\
EOF_INNER
) | /usr/games/lolcat
echo ""
# === FIN BANNER ===
ZSHRC_BANNER
    success "Banner añadido a ~/.zshrc"
else
    warn "Banner ya presente en ~/.zshrc, omitiendo."
fi

# --- Cambiar shell a Zsh ---
info "🔄 Cambiando shell por defecto a Zsh..."
ZSH_PATH="$(command -v zsh)"
if ! grep -qxF "${ZSH_PATH}" /etc/shells 2>/dev/null; then
    echo "${ZSH_PATH}" | sudo -S -p '' tee -a /etc/shells > /dev/null
fi
sudo -S -p '' chsh -s "${ZSH_PATH}" "${USER}"

success "Módulo 06 — Terminal completado."
