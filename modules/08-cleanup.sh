#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en ${BASH_SOURCE[0]}:${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# MODULE_DESC: Limpieza de paquetes y autodestrucción del repositorio
info "🧹 Limpieza profunda de paquetes residuales..."
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

echo ""
echo "--------------------------------------------------------"
success "¡Instalación y limpieza completadas con éxito, Comandante!"
warn "NOTA:"
echo "  1️⃣  Fuentes instaladas: 'MesloLGS NF' (p10k) y 'CascadiaCode NF'."
echo "  2️⃣  Selecciona 'MesloLGS NF' en tu terminal para íconos correctos."
echo "  3️⃣  Cierra sesión y vuelve a entrar (Docker, NVM y Zsh)."
echo "  4️⃣  Ejecuta 'p10k configure' en Zsh para personalizar el prompt."
echo "  5️⃣  LibreOffice Fresh + VLC + MPV listos."
echo "--------------------------------------------------------"

# --- Autolimpieza: eliminar script y repo ---
info "🗑️  Autolimpieza: eliminando repositorio..."
(
    sleep 1
    rm -rf "${SCRIPT_DIR}/.git"
    rm -rf "${SCRIPT_DIR}"
    echo "✅ Carpeta ${SCRIPT_DIR} eliminada. ¡Todo limpio!"
) &

echo ""
success "Setup completo. Esta ventana puede cerrarse. ¡Hasta la próxima!"
