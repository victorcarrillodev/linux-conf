#!/bin/bash

#? Salir inmediatamente si un comando falla
set -e

echo "🚀 Iniciando la configuración del sistema..."

# =========================================================
# PASO 0: PREVENCIÓN DE ERRORES (Aniquilación de repos viejos)
# =========================================================
echo "🧹 Limpiando conflictos previos de repositorios..."

# Docker: Limpieza total
sudo rm -f /etc/apt/keyrings/docker.gpg
sudo rm -f /etc/apt/keyrings/docker.asc
sudo rm -f /etc/apt/sources.list.d/docker*.list
sudo rm -f /etc/apt/sources.list.d/docker*.sources

# VS Code: Táctica de "Tierra Arrasada" Total (Busca contenido en cualquier extensión)
sudo sh -c 'grep -rl "packages.microsoft.com" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f'
sudo rm -f /usr/share/keyrings/microsoft.gpg
sudo rm -f /usr/share/keyrings/packages.microsoft.gpg
sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg

# Antigravity: Limpieza
sudo rm -f /etc/apt/keyrings/antigravity-repo-key.gpg
sudo rm -f /etc/apt/sources.list.d/antigravity.list
sudo rm -f /etc/apt/sources.list.d/antigravity.sources

#? Actualización del sistema
echo "📦 Actualizando repositorios y paquetes..."
sudo apt update && sudo apt upgrade -y

#? Herramientas esenciales y de red
echo "🛠️ Instalando utilidades base..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    unzip

#? Navegadores y multimedia
echo "🔥 Purgando Firefox..."
sudo umount /var/snap/firefox/common/host-hunspell || true
sudo snap remove --purge firefox || true
sudo apt purge -y firefox || true
sudo apt autoremove -y
rm -rf ~/.mozilla
rm -rf ~/snap/firefox   

echo "🌐 Instalando navegadores y herramientas multimedia..."
curl -fsS https://dl.brave.com/install.sh | sh

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb   
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm -f google-chrome-stable_current_amd64.deb # Limpiamos el .deb residual

echo "🖌️ instalando wallpapers y variety para personalización"
sudo apt install -y variety
git clone https://github.com/victorcarrillodev/wallpapers.git ~/

#?
echo "👨‍💻 Instalando herramientas de desarrollo, Docker y utilidades de seguridad..."

#? Node js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 24
node -v 
npm -v 

#? pnpm
npx pnpm@latest-10 dlx @pnpm/exe@latest-10 setup

#? bun
curl -fsSL https://bun.com/install | bash

#? Docker
echo "🐳 Configurando repositorio de Docker..."
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
echo "🐳 Instalando Docker Oficial..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Instalación de Visual Studio Code
echo "📝 Configurando repositorio de VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

echo "📝 Configurando repositorio de Antigravity..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

sudo apt update
echo "📝 Instalando VS Code y Antigravity..."
sudo apt install -y code antigravity

#? flutter 
echo "🚀 Instalando dependencias de Flutter..."
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# 5. Configuración de Terminal (Zsh + Oh My Zsh + Powerlevel10k + Banners)
echo "💻 Configurando la terminal Zsh y herramientas visuales..."
sudo apt install -y zsh fonts-font-awesome figlet toilet lolcat

# Instalar Oh My Zsh en modo desatendido
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Descargar fuentes MesloLGS NF
echo "🔤 Descargando fuentes MesloLGS NF..."
mkdir -p ~/.local/share/fonts
URL_FONTS="https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/MesloLGS%20NF"
curl -sL -o ~/.local/share/fonts/MesloLGS\ NF\ Regular.ttf "$URL_FONTS/MesloLGS%20NF%20Regular.ttf"
curl -sL -o ~/.local/share/fonts/MesloLGS\ NF\ Bold.ttf "$URL_FONTS/MesloLGS%20NF%20Bold.ttf"
curl -sL -o ~/.local/share/fonts/MesloLGS\ NF\ Italic.ttf "$URL_FONTS/MesloLGS%20NF%20Italic.ttf"
curl -sL -o ~/.local/share/fonts/MesloLGS\ NF\ Bold\ Italic.ttf "$URL_FONTS/MesloLGS%20NF%20Bold%20Italic.ttf"
fc-cache -fv

# Clonar Powerlevel10k y plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Configurar .zshrc (Tema y plugins)
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose python)/' ~/.zshrc

# ==========================================
# 🎨 MAGIA DEL BANNER ASCII AQUI (ARREGLO ESTRUCTURAL REAL)
# ==========================================
echo "🎨 Configurando el banner maestro en la cima del archivo..."

cat << 'EOF_OUTER' > /tmp/banner_zshrc.sh
# ====================================================
# Banner de inicio (Ejecutado ANTES del Instant Prompt)
echo ""
paste -d '  ' <(
  (
    toilet -f ivrit -F border -w 90 '</> Victor Carrillo'
    toilet -f pagga -w 90 "master linux dev pro >>"
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
# ====================================================

EOF_OUTER

# Unir banner al principio del .zshrc
cat /tmp/banner_zshrc.sh ~/.zshrc > /tmp/new_zshrc && mv /tmp/new_zshrc ~/.zshrc

# Limpiamos el archivo temporal
rm -f /tmp/banner_zshrc.sh

# Cambiar shell por defecto
echo "🔄 Cambiando la shell por defecto a Zsh..."
sudo chsh -s $(which zsh) $USER

# ==========================================
# 6. LIMPIEZA FINAL Y OPTIMIZACIÓN DE ESPACIO
# ==========================================
echo "🧹 Ejecutando limpieza profunda de paquetes residuales (.deb y huérfanos)..."
sudo apt autoremove -y
sudo apt autoclean -y
sudo apt clean

echo "--------------------------------------------------------"
echo "✅ ¡Instalación y limpieza completadas con éxito, Comandante!"
echo "⚠️ NOTA IMPORTANTE: "
echo "  1. Configura la fuente de tu terminal actual a 'MesloLGS NF'."
echo "  2. Cierra esta sesión y vuelve a entrar para que Docker y Zsh apliquen."
echo "--------------------------------------------------------"