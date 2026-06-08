#!/usr/bin/env bash

# ==============================================================================
# Configuración de entorno seguro
# -e  → salir si un comando falla
# -u  → tratar variables sin definir como error
# -o pipefail → detectar fallos dentro de pipes
# ==============================================================================
set -euo pipefail

# Trap para mostrar el paso exacto donde falló el script
trap 'echo "❌ Error en la línea ${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

# ==============================================================================
# CONSTANTES Y COLORES
# ==============================================================================
readonly BOLD='\033[1m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}ℹ️  $*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠️  $*${RESET}"; }

# ==============================================================================
# HELPER: Inyección idempotente en ~/.zshrc
# Uso: append_zshrc_block "MARKER" $'bloque\nde texto'
# Solo escribe si el MARKER no existe ya en el archivo.
# ==============================================================================
append_zshrc_block() {
    local marker="$1"
    local block="$2"
    if ! grep -qF "${marker}" "${HOME}/.zshrc" 2>/dev/null; then
        printf '\n%s\n' "${block}" >> "${HOME}/.zshrc"
        success "Bloque '${marker}' añadido a ~/.zshrc"
    else
        warn "Bloque '${marker}' ya presente en ~/.zshrc, omitiendo."
    fi
}

info "🚀 Iniciando la configuración del sistema..."

# ==============================================================================
# PASO 0: PREVENCIÓN DE ERRORES (Limpieza de repos y keyrings viejos)
# ==============================================================================
info "🧹 Limpiando conflictos previos de repositorios..."

# Docker
sudo rm -f \
    /etc/apt/keyrings/docker.gpg \
    /etc/apt/keyrings/docker.asc \
    /etc/apt/sources.list.d/docker*.list \
    /etc/apt/sources.list.d/docker*.sources

# VS Code (busca por contenido en cualquier extensión de archivo)
sudo sh -c 'grep -rl "packages.microsoft.com" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f'
sudo rm -f \
    /usr/share/keyrings/microsoft.gpg \
    /usr/share/keyrings/packages.microsoft.gpg \
    /etc/apt/trusted.gpg.d/microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg

# Antigravity
sudo rm -f \
    /etc/apt/keyrings/antigravity-repo-key.gpg \
    /etc/apt/sources.list.d/antigravity.list \
    /etc/apt/sources.list.d/antigravity.sources

# ==============================================================================
# PASO 1: ACTUALIZACIÓN DEL SISTEMA
# ==============================================================================
info "📦 Actualizando repositorios y paquetes..."
sudo apt update && sudo apt upgrade -y

# ==============================================================================
# PASO 2: HERRAMIENTAS ESENCIALES
# ==============================================================================
info "🛠️ Instalando utilidades base..."
sudo apt install -y \
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

# ==============================================================================
# PASO 3: NAVEGADORES
# ==============================================================================
info "🔥 Purgando Firefox..."
sudo umount /var/snap/firefox/common/host-hunspell 2>/dev/null || true
sudo snap remove --purge firefox 2>/dev/null || true
sudo apt purge -y firefox 2>/dev/null || true
sudo apt autoremove -y
rm -rf ~/.mozilla 2>/dev/null || true
rm -rf ~/snap/firefox 2>/dev/null || true

info "🦁 Instalando Brave Browser..."
curl -fsS https://dl.brave.com/install.sh | sh

info "🌐 Instalando Google Chrome..."
CHROME_DEB="$(mktemp /tmp/google-chrome-XXXXXX.deb)"
wget -q -O "${CHROME_DEB}" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y "${CHROME_DEB}"
rm -f "${CHROME_DEB}"

info "🖌️ Instalando Variety y Wallpapers..."
sudo apt install -y variety
if [ ! -d "${HOME}/wallpapers" ]; then
    git clone --depth=1 https://github.com/victorcarrillodev/wallpapers.git "${HOME}/wallpapers"
else
    warn "Wallpapers ya clonados, omitiendo."
fi

# ==============================================================================
# PASO 4: HERRAMIENTAS DE DESARROLLO
# ==============================================================================
info "👨‍💻 Instalando herramientas de desarrollo..."

# --- Node.js via NVM ---
info "📦 Instalando NVM y Node.js 24..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Cargar NVM en el entorno actual del script de instalación
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"

nvm install 24
nvm use 24
nvm alias default 24
node -v
npm -v

# -----------------------------------------------------------------------
# CRÍTICO: El instalador de NVM escribe en ~/.bashrc y ~/.bash_profile,
# pero NO en ~/.zshrc. Sin este bloque, 'nvm', 'node' y 'npm' no se
# encontrarán al abrir una nueva terminal Zsh.
# -----------------------------------------------------------------------
NVM_BLOCK='# ------ NVM INIT ------
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # Carga nvm
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # Autocomplete
# ------ END NVM INIT ------'
append_zshrc_block "# ------ NVM INIT ------" "${NVM_BLOCK}"

# --- pnpm ---
info "📦 Instalando pnpm..."
npm install -g pnpm
pnpm --version

# -----------------------------------------------------------------------
# CRÍTICO: pnpm puede instalar paquetes globales en su propio home.
# Sin este PATH en .zshrc, los binarios de pnpm global no se encontrarán.
# -----------------------------------------------------------------------
PNPM_BLOCK='# ------ PNPM PATH ------
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":${PATH}:" in
  *":${PNPM_HOME}:"*) ;;
  *) export PATH="${PNPM_HOME}:${PATH}" ;;
esac
# ------ END PNPM PATH ------'
append_zshrc_block "# ------ PNPM PATH ------" "${PNPM_BLOCK}"

# --- Bun ---
info "🍞 Instalando Bun..."
curl -fsSL https://bun.sh/install | bash

# -----------------------------------------------------------------------
# CRÍTICO: El instalador de Bun escribe en ~/.bashrc y ~/.profile,
# pero NO en ~/.zshrc. Sin este bloque, 'bun' no se encontrará en Zsh.
# -----------------------------------------------------------------------
BUN_BLOCK='# ------ BUN PATH ------
export BUN_INSTALL="${HOME}/.bun"
export PATH="${BUN_INSTALL}/bin:${PATH}"
# ------ END BUN PATH ------'
append_zshrc_block "# ------ BUN PATH ------" "${BUN_BLOCK}"

# --- Docker ---
info "🐳 Configurando repositorio de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# shellcheck source=/etc/os-release
source /etc/os-release
DOCKER_RAW_SUITE="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
DOCKER_ARCH="$(dpkg --print-architecture)"

# Ubuntu 25+ (no-LTS) puede no tener repo propio en Docker todavía.
# Verificamos si el codename existe; si no, caemos en noble (último LTS estable).
if curl -fsSL --head "https://download.docker.com/linux/ubuntu/dists/${DOCKER_RAW_SUITE}/" \
        -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q '^2'; then
    DOCKER_SUITE="${DOCKER_RAW_SUITE}"
else
    warn "Codename '${DOCKER_RAW_SUITE}' no encontrado en el repo de Docker → usando 'noble' (LTS) como fallback."
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

# Añadir usuario al grupo docker (evita usar sudo en cada comando docker)
sudo usermod -aG docker "${USER}"

# --- Visual Studio Code ---
info "📝 Configurando repositorio de VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null \
    <<< "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"

# --- Antigravity ---
info "📝 Configurando repositorio de Antigravity..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null \
    <<< "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main"

sudo apt update
info "📝 Instalando VS Code y Antigravity..."
sudo apt install -y code antigravity

# ==============================================================================
# PASO 5: TERMINAL (Zsh + Oh My Zsh + Powerlevel10k + Fuentes + Banner)
# ==============================================================================
info "💻 Configurando Zsh y herramientas visuales..."
sudo apt install -y zsh fonts-font-awesome figlet toilet lolcat

# --- Oh My Zsh (idempotente) ---
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    env CHSH=no RUNZSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    warn "Oh My Zsh ya instalado, omitiendo."
fi

# Directorio de fuentes del usuario (creado una sola vez para ambas familias)
FONT_DIR="${HOME}/.local/share/fonts"
mkdir -p "${FONT_DIR}"

# El script siempre sabe dónde está, independientemente desde dónde se ejecute
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===========================================================
# FUENTE 1: Cascadia Code (archivos locales ya descargados)
# ===========================================================
info "🔤 Instalando fuentes Cascadia Code desde archivos locales..."
CASCADIA_TTF_DIR="${SCRIPT_DIR}/CascadiaCode/ttf"

if [ ! -d "${CASCADIA_TTF_DIR}" ]; then
    echo "❌ No se encontró la carpeta de fuentes: ${CASCADIA_TTF_DIR}" >&2
    exit 1
fi

# Copiar raíz + subcarpeta static/ (todos los pesos y variantes)
CASCADIA_COUNT=0
while IFS= read -r -d '' ttf_file; do
    cp "${ttf_file}" "${FONT_DIR}/"
    (( CASCADIA_COUNT++ )) || true
done < <(find "${CASCADIA_TTF_DIR}" -name "*.ttf" -print0)

success "Cascadia Code: ${CASCADIA_COUNT} archivos instalados."

# Eliminar la carpeta local ya que no se necesita más
info "🗑️  Eliminando carpeta CascadiaCode..."
rm -rf "${SCRIPT_DIR}/CascadiaCode"
success "Carpeta CascadiaCode eliminada."

# ===========================================================
# FUENTE 2: MesloLGS NF (descarga desde GitHub)
# Necesaria para Powerlevel10k — muestra íconos y glyphs en el prompt
# ===========================================================
info "🔤 Descargando fuentes MesloLGS NF (requeridas por Powerlevel10k)..."
MESLO_BASE="https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF"

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
    warn "MesloLGS NF: ${MESLO_ERRORS} archivo(s) fallaron. Verifica conexión a internet."
fi

# Actualizar caché de fuentes una sola vez al terminar ambas instalaciones
info "🔄 Actualizando caché de fuentes del sistema..."
fc-cache -fv
success "Caché de fuentes actualizada. Ambas familias disponibles."

# --- Powerlevel10k y Plugins (idempotente) ---
ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"

if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM}/themes/powerlevel10k"
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# --- Configurar .zshrc (Tema y plugins) ---
# Verificamos antes del sed para no fallar si la línea ya fue cambiada en ejecuciones previas
if grep -q 'ZSH_THEME="robbyrussell"' ~/.zshrc; then
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
fi
if grep -q 'plugins=(git)' ~/.zshrc; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose python)/' ~/.zshrc
fi

# --- Banner ASCII ---
# IMPORTANTE: El banner va AL FINAL del .zshrc, nunca al principio.
# Powerlevel10k tiene "Instant Prompt" que requiere ejecutarse antes de cualquier
# output. Si el banner va antes, p10k muestra advertencias de permisos en cada
# apertura de terminal.
#
# Usamos `cat >> .zshrc` con heredoc en vez de variable de bash porque el
# banner contiene comillas simples (en el ASCII art del ojo) que romperían
# una asignación con '...' y no pueden escaparse dentro de ella.
info "🎨 Configurando banner maestro al final de ~/.zshrc..."

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
    success "Banner con ojo illuminati añadido a ~/.zshrc"
else
    warn "Banner ya presente en ~/.zshrc, omitiendo."
fi

# --- Cambiar shell por defecto ---
info "🔄 Cambiando shell por defecto a Zsh..."
ZSH_PATH="$(command -v zsh)"
sudo chsh -s "${ZSH_PATH}" "${USER}"

# ==============================================================================
# PASO 5.5: OFIMÁTICA Y MULTIMEDIA
# ==============================================================================

# --- LibreOffice ---
info "📄 Instalando LibreOffice (suite ofimática completa)..."
# dpkg-query es más fiable que 'dpkg -l' para verificar si un paquete está instalado
if ! dpkg-query -W -f='${Status}' libreoffice-fresh 2>/dev/null | grep -q 'install ok installed'; then
    # Agregar PPA oficial para la versión más reciente (Fresh)
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

# --- Codecs multimedia (paquetes restringidos de Ubuntu) ---
info "🎬 Instalando codecs y soporte multimedia ampliado..."
# ubuntu-restricted-extras incluye ttf-mscorefonts-installer que muestra una
# pantalla interactiva de EULA. Pre-aceptamos vía debconf para que el script
# no quede colgado esperando input del usuario.
sudo add-apt-repository -y multiverse
# shellcheck disable=SC2016
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

# --- Reproductores de video/audio ---
info "🎵 Instalando reproductores multimedia..."
sudo apt install -y \
    vlc \
    mpv
success "Reproductores VLC y MPV instalados."


# ==============================================================================
# PASO 6: LIMPIEZA FINAL
# ==============================================================================
info "🧹 Limpieza profunda de paquetes residuales..."
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

# ==============================================================================
# FIN
# ==============================================================================
echo ""
echo "--------------------------------------------------------"
success "¡Instalación y limpieza completadas con éxito, Comandante!"
warn "NOTA IMPORTANTE:"
echo "  1️⃣  Fuentes instaladas: 'MesloLGS NF' (para p10k) y 'CascadiaCode NF' / 'CascadiaMono NF'."
echo "  2️⃣  En tu terminal, selecciona 'MesloLGS NF' para que Powerlevel10k muestre íconos correctamente."
echo "  3️⃣  Cierra sesión y vuelve a entrar para que Docker, NVM y Zsh apliquen."
echo "  4️⃣  Ejecuta 'p10k configure' en Zsh para personalizar el prompt."
echo "  5️⃣  LibreOffice Fresh instalado desde PPA oficial (versión más reciente)."
echo "  6️⃣  Multimedia: VLC y MPV listos para usar."
echo "--------------------------------------------------------"

# ==============================================================================
# AUTOLIMPIEZA: Eliminar el script y la carpeta del repositorio
# Esto se ejecuta AL FINAL, después de que todo fue exitoso.
# Usamos un subshell para poder borrar el script mientras está corriendo.
# ==============================================================================
info "🗑️  Autolimpieza: eliminando script e instalador..."
# SCRIPT_DIR ya está definido arriba (línea ~261), lo reutilizamos aquí
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
REPO_DIR="${SCRIPT_DIR}"

# Programar la eliminación en background para que bash pueda terminar primero
# (sleep 1 da tiempo al intérprete de terminar de leer el script antes de borrarlo)
(
    sleep 1
    rm -f "${SCRIPT_PATH}"
    rm -rf "${REPO_DIR}/.git"
    rmdir --ignore-fail-on-non-empty "${REPO_DIR}" 2>/dev/null || rm -rf "${REPO_DIR}"
    echo "✅ Carpeta ${REPO_DIR} eliminada. ¡Todo limpio, Comandante!"
) &

echo ""
success "Setup completo. Esta ventana puede cerrarse. ¡Hasta la próxima!"